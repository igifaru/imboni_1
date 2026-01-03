import { prisma } from '../../../../libs/database/prisma.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { CreateMessageDto } from '../dto/community.dto';
import { AdministrativeUnit, CaseCategory, ChannelType, ChannelRole } from '@prisma/client';

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
                replyToId: dto.replyToId
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
     * Starts from Village and walks up to verify the parent chain matches.
     */
    private async findUnitByHierarchy(profile: any): Promise<AdministrativeUnit | null> {
        const { village, cell, sector, district, province } = profile;

        // Priority: Village > Cell > Sector > District > Province
        // We try to find the most specific level first

        if (village) {
            // Find all villages with this name
            const villages = await prisma.administrativeUnit.findMany({
                where: { name: { equals: village, mode: 'insensitive' }, level: 'VILLAGE' }
            });

            // Filter to find the one whose parent chain matches
            for (const v of villages) {
                const lineage = await this.getUnitLineage(v.id);
                if (this.matchesProfile(lineage, profile)) {
                    return v;
                }
            }
        }

        // If no village match, try Cell
        if (cell) {
            const cells = await prisma.administrativeUnit.findMany({
                where: { name: { equals: cell, mode: 'insensitive' }, level: 'CELL' }
            });
            for (const c of cells) {
                const lineage = await this.getUnitLineage(c.id);
                if (this.matchesProfile(lineage, profile)) {
                    return c;
                }
            }
        }

        // If no cell match, try Sector
        if (sector) {
            const sectors = await prisma.administrativeUnit.findMany({
                where: { name: { equals: sector, mode: 'insensitive' }, level: 'SECTOR' }
            });
            for (const s of sectors) {
                const lineage = await this.getUnitLineage(s.id);
                if (this.matchesProfile(lineage, profile)) {
                    return s;
                }
            }
        }

        // If no sector match, try District
        if (district) {
            const districts = await prisma.administrativeUnit.findMany({
                where: { name: { equals: district, mode: 'insensitive' }, level: 'DISTRICT' }
            });
            for (const d of districts) {
                const lineage = await this.getUnitLineage(d.id);
                if (this.matchesProfile(lineage, profile)) {
                    return d;
                }
            }
        }

        // If no district match, try Province
        if (province) {
            const provinces = await prisma.administrativeUnit.findMany({
                where: { name: { equals: province, mode: 'insensitive' }, level: 'PROVINCE' }
            });
            if (provinces.length > 0) {
                return provinces[0]; // Provinces should be unique by name
            }
        }

        return null;
    }

    /**
     * Checks if the unit's lineage matches the user's profile.
     * Uses flexible matching for provinces (North matches Northern Province).
     */
    private matchesProfile(lineage: AdministrativeUnit[], profile: any): boolean {
        const lineageMap: Record<string, string> = {};
        for (const unit of lineage) {
            lineageMap[unit.level] = unit.name.toLowerCase();
        }

        // Check each profile field against the lineage
        // Cell matching (exact)
        if (profile.cell && lineageMap['CELL']) {
            if (!this.fuzzyMatch(lineageMap['CELL'], profile.cell)) {
                return false;
            }
        }
        // Sector matching (exact)
        if (profile.sector && lineageMap['SECTOR']) {
            if (!this.fuzzyMatch(lineageMap['SECTOR'], profile.sector)) {
                return false;
            }
        }
        // District matching (exact)
        if (profile.district && lineageMap['DISTRICT']) {
            if (!this.fuzzyMatch(lineageMap['DISTRICT'], profile.district)) {
                return false;
            }
        }
        // Province matching (flexible - "North" should match "Northern Province")
        if (profile.province && lineageMap['PROVINCE']) {
            if (!this.provinceMatches(lineageMap['PROVINCE'], profile.province)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Fuzzy match for names - handles minor variations
     */
    private fuzzyMatch(dbName: string, profileName: string): boolean {
        const db = dbName.toLowerCase().trim();
        const prof = profileName.toLowerCase().trim();
        // Exact match or contains
        return db === prof || db.includes(prof) || prof.includes(db);
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
