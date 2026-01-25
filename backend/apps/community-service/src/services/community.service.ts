import { prisma } from '../../../../libs/database/prisma.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { CreateMessageDto } from '../dto/community.dto';
import { AdministrativeUnit, CaseCategory, ChannelType, ChannelRole, AdministrativeLevel } from '@prisma/client';
import locationData from '../data/locations.json';

const logger = createServiceLogger('community-service');

export class CommunityService {

    /**
     * Get channels for a user based on their enrollments
     */
    async getUserChannels(userId: string) {
        return prisma.communityChannel.findMany({
            where: {
                memberships: {
                    some: { userId }
                }
            },
            include: {
                _count: { select: { messages: true, memberships: true } },
                administrativeUnit: { select: { name: true, level: true } }
            },
            orderBy: [
                { administrativeUnit: { level: 'asc' } },
                { name: 'asc' }
            ]
        });
    }

    /**
     * Get messages for a channel with pagination
     */
    async getChannelMessages(channelId: string, limit = 50, cursor?: string) {
        return prisma.channelMessage.findMany({
            where: { channelId },
            take: limit,
            skip: cursor ? 1 : 0,
            cursor: cursor ? { id: cursor } : undefined,
            orderBy: { createdAt: 'desc' },
            include: {
                author: {
                    select: {
                        id: true,
                        name: true,
                        role: true,
                        profilePicture: true,
                    }
                },
                reactions: {
                    select: {
                        emoji: true,
                        userId: true,
                        user: {
                            select: {
                                id: true,
                                name: true,
                                profilePicture: true,
                                role: true
                            }
                        }
                    }
                },
                replyTo: {
                    select: {
                        id: true,
                        content: true,
                        author: {
                            select: {
                                id: true,
                                name: true
                            }
                        }
                    }
                }
            }
        });
    }

    /**
     * Post a message
     */
    async createMessage(dto: CreateMessageDto) {
        return prisma.channelMessage.create({
            data: {
                content: dto.content,
                channelId: dto.channelId,
                authorId: dto.authorId,
                isOfficial: dto.isOfficial || false,
                replyToId: dto.replyToId,
                attachments: (() => {
                    const atts = dto.attachments ?? [];
                    logger.info(`[CreateMessage] Creating msg for channel ${dto.channelId}. Attachments:`, JSON.stringify(atts));
                    return atts;
                })()
            },
            include: {
                author: {
                    select: { id: true, name: true, role: true, profilePicture: true }
                },
                replyTo: {
                    select: {
                        id: true,
                        content: true,
                        author: {
                            select: {
                                id: true,
                                name: true
                            }
                        }
                    }
                }
            }
        });
    }

    /**
     * Auto-enroll a user based on their location profile.
     * Uses HIERARCHICAL lookup to find the EXACT unit matching the user's full path,
     * then enrolls them in that unit and all its parents.
     */
    async enrollUserByProfile(userId: string, profile: any) {
        logger.info(`Enrolling user ${userId} based on profile hierarchy`);

        // Try to find the most specific unit (Village) by walking UP the tree
        // We search for a Village whose parent chain matches Cell -> Sector -> District -> Province
        const targetUnit = await this.findUnitByHierarchy(profile);

        if (targetUnit) {
            logger.info(`Found target unit: ${targetUnit.name} (${targetUnit.level})`);
            // Enroll in this unit and all its parents
            await this.enrollInLineage(userId, targetUnit.id);
        } else {
            logger.warn(`Could not find matching unit for profile: ${JSON.stringify(profile)}`);
        }
    }

    /**
     * Auto-enroll a leader based on their confirmed jurisdiction assignments.
     */
    async enrollLeaderByAssignment(userId: string) {
        logger.info(`Attempting to enroll leader ${userId} based on assignments`);

        const assignments = await prisma.leaderAssignment.findMany({
            where: { userId, isActive: true },
            include: { administrativeUnit: true }
        });

        if (assignments.length === 0) {
            logger.warn(`No active leader assignments found for ${userId}`);
            return;
        }

        for (const assignment of assignments) {
            logger.info(`Enrolling leader in jurisdiction: ${assignment.administrativeUnit.name}`);
            await this.enrollInLineage(userId, assignment.administrativeUnitId);
        }
    }

    /**
     * Finds the most specific administrative unit matching the user's profile hierarchy.
     * Uses a scoring system and optimized eager loading to handle data inconsistencies efficiently.
     */
    private async findUnitByHierarchy(profile: any): Promise<AdministrativeUnit | null> {
        const { village, cell, sector, district, province } = profile;
        const THRESHOLD = -100;

        logger.info(`[findUnitByHierarchy] Searching for profile: ${JSON.stringify(profile)}`);

        // Helper to find best candidate with ID check and Suffix Cleaning
        const findBestCandidate = async (level: string, val: string) => {
            if (!val) return null;
            const originalName = val.trim();

            // 1. Try generic search (ID or Name)
            let candidates = await this.searchUnits(level, originalName);

            // 2. If no candidates, try cleaning suffixes (e.g. "Ubumwe Village" -> "Ubumwe")
            if (candidates.length === 0) {
                const cleaned = this.stripSuffixes(originalName);
                if (cleaned !== originalName) {
                    logger.info(`[findUnitByHierarchy] Retrying with cleaned name: '${cleaned}'`);
                    candidates = await this.searchUnits(level, cleaned);
                }
            }

            logger.info(`[findUnitByHierarchy] Found ${candidates.length} candidates for ${level}='${originalName}'`);

            let bestUnit = null;
            let maxScore = -999;

            for (const unit of candidates) {
                const lineage: AdministrativeUnit[] = [];
                let current: any = unit;
                while (current) {
                    lineage.push(current as AdministrativeUnit);
                    current = current.parent;
                }

                const score = this.calculateMatchScore(lineage, profile);
                logger.debug(`[findUnitByHierarchy] Candidate ${unit.name} (${unit.id}) Score: ${score}`);

                if (score > maxScore) {
                    maxScore = score;
                    bestUnit = unit;
                }
            }

            if (bestUnit && maxScore >= THRESHOLD) {
                logger.info(`[findUnitByHierarchy] Selected ${bestUnit.name} for ${level}`);
                return bestUnit as AdministrativeUnit;
            }
            return null;
        };

        // Priority: Village > Cell > Sector > District > Province

        if (village) {
            const match = await findBestCandidate('VILLAGE', village);
            if (match) return match;

            // --- JIT SEEDING attempt if Village missing ---
            logger.warn(`[findUnitByHierarchy] Village '${village}' not found or matched. Attempting JIT Seeding...`);
            const seeded = await this.seedUnitFromProfile(profile);
            if (seeded) {
                logger.info(`[findUnitByHierarchy] JIT Seeding SUCCESS. Created/Found: ${seeded.name}`);
                return seeded;
            }
        }

        if (cell) {
            const match = await findBestCandidate('CELL', cell);
            if (match) return match;
        }

        if (sector) {
            const match = await findBestCandidate('SECTOR', sector);
            if (match) return match;
        }

        if (district) {
            const match = await findBestCandidate('DISTRICT', district);
            if (match) return match;
        }

        if (province) {
            const provinces = await prisma.administrativeUnit.findMany({
                where: { name: { equals: province, mode: 'insensitive' }, level: 'PROVINCE' }
            });
            if (provinces.length > 0) return provinces[0];
        }

        return null;
    }

    /**
     * Cross-checks profile against location.json data.
     * If valid, creates the missing hierarchy in DB.
     */
    private async seedUnitFromProfile(profile: any): Promise<AdministrativeUnit | null> {
        try {
            logger.info('[seedUnitFromProfile] Starting traversal for:', JSON.stringify(profile));

            // Traverse JSON
            const findKey = (obj: any, target: string, levelName: string) => {
                if (!obj) {
                    logger.warn(`[seedUnitFromProfile] ${levelName} object is null/undefined`);
                    return null;
                }
                const targetClean = this.stripSuffixes(target || '').toLowerCase();
                const key = Object.keys(obj).find(k => this.stripSuffixes(k).toLowerCase() === targetClean);
                if (!key) {
                    logger.warn(`[seedUnitFromProfile] Could not find ${levelName} key for '${target}' (clean: '${targetClean}') in keys: ${Object.keys(obj).slice(0, 5)}...`);
                } else {
                    logger.info(`[seedUnitFromProfile] Found ${levelName}: ${key}`);
                }
                return key;
            };

            const findInArray = (arr: string[], target: string, levelName: string) => {
                if (!arr) {
                    logger.warn(`[seedUnitFromProfile] ${levelName} array is null/undefined`);
                    return null;
                }
                const targetClean = this.stripSuffixes(target || '').toLowerCase();
                const val = arr.find(v => this.stripSuffixes(v).toLowerCase() === targetClean);
                if (!val) {
                    logger.warn(`[seedUnitFromProfile] Could not find ${levelName} value for '${target}' (clean: '${targetClean}') in array: ${arr.slice(0, 5)}...`);
                } else {
                    logger.info(`[seedUnitFromProfile] Found ${levelName}: ${val}`);
                }
                return val;
            }

            const provKey = findKey(locationData, profile.province, 'PROVINCE');
            if (!provKey) return null;
            const districtsObj = (locationData as any)[provKey];

            const distKey = findKey(districtsObj, profile.district, 'DISTRICT');
            if (!distKey) return null;
            const sectorsObj = districtsObj[distKey];

            const sectKey = findKey(sectorsObj, profile.sector, 'SECTOR');
            if (!sectKey) return null;
            const cellsObj = sectorsObj[sectKey];

            const cellKey = findKey(cellsObj, profile.cell, 'CELL');
            if (!cellKey) return null;
            const villagesArr = cellsObj[cellKey];

            const villName = findInArray(villagesArr, profile.village, 'VILLAGE');
            if (!villName) return null;

            // If we are here, the path is VALID. Let's create it.
            logger.info(`[seedUnitFromProfile] Valid path found in JSON: ${provKey} -> ${distKey} -> ${sectKey} -> ${cellKey} -> ${villName}`);

            const ensureUnit = async (name: string, level: AdministrativeLevel, parentId: string | null) => {
                const existing = await prisma.administrativeUnit.findFirst({
                    where: {
                        name: { equals: name, mode: 'insensitive' },
                        level,
                        parentId
                    }
                });
                if (existing) return existing;

                return prisma.administrativeUnit.create({
                    data: {
                        name: name, // Use proper casing from JSON if possible, but simple name is fine
                        level,
                        code: `${name.toUpperCase().replace(/\s+/g, '_')}_${level}_${Date.now().toString(36)}`,
                        parentId
                    }
                });
            };

            const provUnit = await ensureUnit(provKey, 'PROVINCE', null);
            const distUnit = await ensureUnit(distKey, 'DISTRICT', provUnit.id);
            const sectUnit = await ensureUnit(sectKey, 'SECTOR', distUnit.id);
            const cellUnit = await ensureUnit(cellKey, 'CELL', sectUnit.id);
            const villUnit = await ensureUnit(villName, 'VILLAGE', cellUnit.id);

            return villUnit;

        } catch (e) {
            logger.error('[seedUnitFromProfile] Error seeding:', e);
            return null;
        }
    }


    /**
     * Calculate a match score: +1 for match, -1 for mismatch
     */
    private calculateMatchScore(lineage: AdministrativeUnit[], profile: any): number {
        const lineageMap: Record<string, string> = {};
        for (const unit of lineage) {
            lineageMap[unit.level] = unit.name.toLowerCase();
        }

        let score = 0;

        // Helper to check level
        const checkLevel = (levelKey: string, profileVal: string) => {
            // If lineage has this level, we compare
            if (lineageMap[levelKey]) {
                let match = false;
                if (levelKey === 'PROVINCE') {
                    match = this.provinceMatches(lineageMap[levelKey], profileVal);
                } else {
                    match = this.fuzzyMatch(lineageMap[levelKey], profileVal);
                }
                const levelScore = match ? 1 : -1;
                logger.debug(`[calculateMatchScore] Level ${levelKey}: Profile '${profileVal}' vs Lineage '${lineageMap[levelKey]}' -> Match: ${match}, Score: ${levelScore}`);
                return levelScore;
            }
            logger.debug(`[calculateMatchScore] Level ${levelKey}: Not found in lineage. Score: 0`);
            return 0; // Neutral if level missing in lineage (shouldn't happen for parents)
        };

        if (profile.village) score += checkLevel('VILLAGE', profile.village);
        if (profile.cell) score += checkLevel('CELL', profile.cell);
        if (profile.sector) score += checkLevel('SECTOR', profile.sector);
        if (profile.district) score += checkLevel('DISTRICT', profile.district);
        if (profile.province) score += checkLevel('PROVINCE', profile.province);

        logger.debug(`[calculateMatchScore] Total score for lineage: ${score}`);
        return score;
    }



    private fuzzyMatch(dbName: string, profileName: string): boolean {
        const db = dbName.toLowerCase().trim();
        const prof = profileName.toLowerCase().trim();
        const cleanedProf = this.stripSuffixes(prof);
        // Exact match or contains
        return db === prof || db.includes(prof) || prof.includes(db) || db === cleanedProf || db.includes(cleanedProf) || cleanedProf.includes(db);
    }

    private stripSuffixes(name: string): string {
        let cleaned = name;
        const suffixes = [' village', ' cell', ' sector', ' district', ' province', ' umudugudu', ' akagari', ' umurenge', ' akarere', ' intara'];
        for (const suffix of suffixes) {
            if (cleaned.toLowerCase().endsWith(suffix)) {
                cleaned = cleaned.substring(0, cleaned.length - suffix.length).trim();
            }
        }
        return cleaned;
    }

    private async searchUnits(level: string, val: string) {
        const name = val.trim();
        const isId = name.length > 20 && name.startsWith('c');

        logger.info(`[searchUnits] Searching ${level} for '${name}' (IsID: ${isId})`);

        const whereClause: any = { level: level as any };
        if (isId) {
            whereClause.OR = [
                { id: name },
                { name: { contains: name, mode: 'insensitive' } }
            ];
        } else {
            whereClause.name = { contains: name, mode: 'insensitive' };
        }

        return prisma.administrativeUnit.findMany({
            where: whereClause,
            include: {
                parent: {
                    include: {
                        parent: {
                            include: {
                                parent: {
                                    include: {
                                        parent: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        });
    }

    /**
     * Special matching for provinces to handle short names
     */
    private provinceMatches(dbProvince: string, profileProvince: string): boolean {
        const db = dbProvince.toLowerCase();
        const prof = profileProvince.toLowerCase();

        // Direct match
        if (db === prof) return true;

        // Short name mappings
        const mappings: Record<string, string[]> = {
            'northern province': ['north', 'northern'],
            'southern province': ['south', 'southern'],
            'eastern province': ['east', 'eastern'],
            'western province': ['west', 'western'],
            'kigali city': ['kigali', 'kigali city']
        };

        for (const [full, shorts] of Object.entries(mappings)) {
            if (db.includes(full) || full.includes(db)) {
                if (shorts.some(s => prof === s || prof.includes(s))) {
                    return true;
                }
            }
        }

        // Fallback: contains check
        return db.includes(prof) || prof.includes(db);
    }

    /**
     * Enrolls a user in a unit and all its parent units.
     */
    private async enrollInLineage(userId: string, unitId: string) {
        const lineage = await this.getUnitLineage(unitId);
        logger.info(`Enrolling user in ${lineage.length} units`);

        for (const unit of lineage) {
            const channel = await this.getOrCreateChannel(unit.id, null);
            await this.joinChannel(userId, channel.id, ChannelRole.MEMBER);
        }
    }

    /**
     * Join a specific category channel (e.g. Health, Justice) for a unit
     */
    async joinCategoryChannel(userId: string, unitId: string, category: CaseCategory) {
        const channel = await this.getOrCreateChannel(unitId, category);
        await this.joinChannel(userId, channel.id, ChannelRole.MEMBER);
        return channel;
    }

    /**
     * Helper to find or create a channel for a unit/category
     */
    private async getOrCreateChannel(unitId: string, category: CaseCategory | null) {
        const existing = await prisma.communityChannel.findFirst({
            where: {
                administrativeUnitId: unitId,
                category: category
            },
            include: { administrativeUnit: true }
        });

        if (existing) return existing;

        const unit = await prisma.administrativeUnit.findUnique({ where: { id: unitId } });
        if (!unit) throw new Error('Unit not found');

        const suffix = category ? this.formatCategory(category) : 'General';

        logger.info(`Creating ${suffix} Channel for ${unit.name} (${unit.level})`);

        return prisma.communityChannel.create({
            data: {
                administrativeUnitId: unitId,
                name: `${unit.name} - ${suffix}`,
                type: ChannelType.COMMUNITY,
                category: category
            },
            include: { administrativeUnit: true }
        });
    }

    private formatCategory(cat: string) {
        return cat.charAt(0) + cat.slice(1).toLowerCase().replace('_', ' ');
    }

    private async joinChannel(userId: string, channelId: string, role: ChannelRole) {
        try {
            await prisma.channelMembership.upsert({
                where: {
                    userId_channelId: { userId, channelId }
                },
                update: {},
                create: {
                    userId,
                    channelId,
                    role
                }
            });
        } catch (e) {
            logger.error(`Failed to join channel`, e);
        }
    }

    /**
     * Search members in a channel
     */
    async searchChannelMembers(channelId: string, query: string) {
        return prisma.channelMembership.findMany({
            where: {
                channelId,
                user: {
                    OR: [
                        { name: { contains: query, mode: 'insensitive' } },
                        { email: { contains: query, mode: 'insensitive' } }
                    ]
                }
            },
            take: 20,
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profilePicture: true,
                        role: true
                    }
                }
            }
        });
    }

    /**
     * Toggle a reaction on a message
     */
    async toggleReaction(userId: string, messageId: string, emoji: string) {
        // Check if reaction exists
        const existing = await prisma.messageReaction.findUnique({
            where: {
                userId_messageId_emoji: {
                    userId,
                    messageId,
                    emoji
                }
            }
        });

        if (existing) {
            // Remove reaction
            await prisma.messageReaction.delete({
                where: { id: existing.id }
            });
        } else {
            // Add reaction
            await prisma.messageReaction.create({
                data: {
                    userId,
                    messageId,
                    emoji
                }
            });
        }

        // Return updated message with all reactions specifically for UI updates
        return prisma.channelMessage.findUnique({
            where: { id: messageId },
            include: {
                author: {
                    select: { id: true, name: true, role: true, profilePicture: true }
                },
                reactions: {
                    select: {
                        emoji: true,
                        userId: true,
                        user: {
                            select: {
                                id: true,
                                name: true,
                                profilePicture: true,
                                role: true
                            }
                        }
                    }
                },
                replyTo: {
                    select: {
                        id: true,
                        content: true,
                        author: {
                            select: {
                                id: true,
                                name: true
                            }
                        }
                    }
                }
            }
        });
    }

    /**
     * Toggle pin status of a message
     */
    async togglePin(messageId: string) {
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) throw new Error('Message not found');

        return prisma.channelMessage.update({
            where: { id: messageId },
            data: { isPinned: !message.isPinned },
            include: {
                author: {
                    select: { id: true, name: true, role: true, profilePicture: true }
                },
                reactions: {
                    select: {
                        emoji: true,
                        userId: true,
                        user: {
                            select: {
                                id: true,
                                name: true,
                                profilePicture: true,
                                role: true
                            }
                        }
                    }
                },
                replyTo: {
                    select: {
                        id: true,
                        content: true,
                        author: {
                            select: {
                                id: true,
                                name: true
                            }
                        }
                    }
                }
            }
        });
    }

    /**
     * Update a message content
     */
    async updateMessage(messageId: string, content: string, attachments?: any[]) {
        logger.info(`[UpdateMessage] Updating msg ${messageId}. Attachments count: ${attachments?.length}`);
        return prisma.channelMessage.update({
            where: { id: messageId },
            data: {
                content,
                ...(attachments ? { attachments } : {})
            },
            include: {
                author: {
                    select: { id: true, name: true, role: true, profilePicture: true }
                },
                reactions: {
                    select: {
                        emoji: true,
                        userId: true,
                        user: {
                            select: {
                                id: true,
                                name: true,
                                profilePicture: true,
                                role: true
                            }
                        }
                    }
                },
                replyTo: {
                    select: {
                        id: true,
                        content: true,
                        author: {
                            select: {
                                id: true,
                                name: true
                            }
                        }
                    }
                }
            }
        });
    }

    /**
     * Delete a message
     */
    async deleteMessage(messageId: string) {
        return prisma.channelMessage.delete({
            where: { id: messageId }
        });
    }

    /**
     * Vote on a poll attachment
     */
    async voteOnPoll(userId: string, messageId: string, attachmentId: string, votes: number | number[]) {
        logger.info(`[VoteOnPoll] User ${userId} voting on msg ${messageId}, attachment ${attachmentId}, votes:`, votes);
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) throw new Error('Message not found');

        const attachments = message.attachments as any[];
        const attachmentIndex = attachments.findIndex((a: any) => a.id === attachmentId);

        if (attachmentIndex === -1) throw new Error('Attachment not found');

        const attachment = attachments[attachmentIndex];
        if (attachment.type !== 'poll') throw new Error('Attachment is not a poll');

        // Update metadata
        const metadata = attachment.metadata || {};
        const currentVotes = metadata.votes || {};

        // Update user vote
        if (Array.isArray(votes) && votes.length === 0) {
            delete currentVotes[userId];
        } else {
            currentVotes[userId] = votes;
        }

        metadata.votes = currentVotes;
        attachment.metadata = metadata;
        attachments[attachmentIndex] = attachment;

        logger.debug('[VoteOnPoll] Updated metadata:', JSON.stringify(metadata, null, 2));

        return this.updateMessage(messageId, message.content, JSON.parse(JSON.stringify(attachments)));
    }

    /**
     * Add entry to collaborative list attachment
     */
    /**
     * Edit an existing list entry (user can only edit their own)
     */
    async editListEntry(userId: string, messageId: string, attachmentId: string, entryIndex: number, entryData: any) {
        logger.info(`[EditListEntry] User ${userId} editing entry ${entryIndex} on msg ${messageId}`);
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) throw new Error('Message not found');

        const attachments = message.attachments as any[];
        const attachmentIndex = attachments.findIndex((a: any) => a.id === attachmentId);

        if (attachmentIndex === -1) throw new Error('Attachment not found');

        const attachment = attachments[attachmentIndex];
        const metadata = attachment.metadata || {};
        const entries = metadata.entries || [];

        if (entryIndex < 0 || entryIndex >= entries.length) {
            throw new Error('Entry not found');
        }

        // Validate Ownership
        if (entries[entryIndex].userId !== userId) {
            throw new Error('Unauthorized: Can only edit your own entry');
        }

        // Update Data
        entries[entryIndex].data = entryData;
        // Optionally update timestamp or add 'editedAt'
        entries[entryIndex].updatedAt = new Date().toISOString();

        metadata.entries = entries;
        attachment.metadata = metadata;
        attachments[attachmentIndex] = attachment;

        return this.updateMessage(messageId, message.content, JSON.parse(JSON.stringify(attachments)));
    }

    /**
     * Update List Structure (Title/Columns) - Creator Only
     */
    async updateCollaborativeList(userId: string, messageId: string, attachmentId: string, title: string, columns: string[]) {
        logger.info(`[UpdateList] User ${userId} updating list on msg ${messageId}`);
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) throw new Error('Message not found');

        // Only Message Author can update structure
        if (message.authorId !== userId) {
            throw new Error('Unauthorized: Only list creator can update structure');
        }

        const attachments = message.attachments as any[];
        const attachmentIndex = attachments.findIndex((a: any) => a.id === attachmentId);

        if (attachmentIndex === -1) throw new Error('Attachment not found');

        const attachment = attachments[attachmentIndex];
        const metadata = attachment.metadata || {};

        // Update Metadata
        if (title) metadata.title = title;
        if (columns) metadata.columns = columns;

        attachment.metadata = metadata;
        attachments[attachmentIndex] = attachment;

        return this.updateMessage(messageId, message.content, JSON.parse(JSON.stringify(attachments)));
    }

    /**
     * Add entry to collaborative list attachment
     */
    async addListEntry(userId: string, messageId: string, attachmentId: string, entryData: any) {
        logger.info(`[AddListEntry] User ${userId} adding entry on msg ${messageId}, attachment ${attachmentId}, data:`, entryData);
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) throw new Error('Message not found');

        const attachments = message.attachments as any[];
        const attachmentIndex = attachments.findIndex((a: any) => a.id === attachmentId);

        if (attachmentIndex === -1) throw new Error('Attachment not found');

        const attachment = attachments[attachmentIndex];
        if (attachment.type !== 'collaborativeList') throw new Error('Attachment is not a list');

        // Update metadata
        const metadata = attachment.metadata || {};
        const entries = metadata.entries || [];

        // Check if user already added? Or allow multiple? Usually allow multiple for list.
        // Add timestamp and user info
        const user = await prisma.user.findUnique({ where: { id: userId } });

        entries.push({
            userId,
            userName: user?.name || 'Unknown',
            data: entryData,
            timestamp: new Date().toISOString()
        });

        metadata.entries = entries;
        attachment.metadata = metadata;
        attachments[attachmentIndex] = attachment;

        logger.debug('[AddListEntry] Updated attachment metadata:', JSON.stringify(metadata, null, 2));

        return this.updateMessage(messageId, message.content, JSON.parse(JSON.stringify(attachments)));
    }

    // Traverse up the tree
    private async getUnitLineage(unitId: string): Promise<AdministrativeUnit[]> {
        const line: AdministrativeUnit[] = [];
        let currentId: string | null = unitId;

        while (currentId) {
            const u: AdministrativeUnit | null = await prisma.administrativeUnit.findUnique({ where: { id: currentId } });
            if (!u) break;
            line.push(u);
            currentId = u.parentId;
        }
        return line;
    }
}

export const communityService = new CommunityService();
