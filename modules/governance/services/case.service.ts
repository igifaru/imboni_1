/**
 * Case Service - Business Logic
 */
import { caseRepository, CaseRepository } from '../repositories/case.repository';
import { CreateCaseDto, UpdateCaseDto, CitizenUpdateCaseDto, CaseResponseDto } from '../dto/case.dto';
import { CaseEntity } from '../entities/case.entity';
import { publishEvent, CHANNELS } from '../../../../libs/messaging/messaging.service';
import { createServiceLogger } from '@shared/helpers/logging/logger.service';
import { prisma } from '@shared/database/prisma.service';
import { findNearestLeader, getAncestorAtLevel } from '../../../../libs/database/assignment.utils';
import { getNextEscalationLevel } from '../../../escalation-service/src/rules/escalation.rules';
import { config } from '@config/config.service';
import { AdministrativeLevel, CaseStatus } from '@prisma/client';

const logger = createServiceLogger('case-service');

// Professionalization: Pre-load static hierarchy once
// Professionalization: Pre-load static hierarchy once
import rwandaAdminData from '../../../api-gateway/src/data/rwanda-admin.json';
const ADMIN_JSON = rwandaAdminData;

/**
 * Province name mapping: Kinyarwanda -> data.json keys
 */
const provinceMapping: Record<string, string> = {
    'Kigali': 'Kigali',
    'City of Kigali': 'Kigali',
    'Kigali City': 'Kigali',
    'Amajyaruguru': 'North',
    'Northern Province': 'North',
    'Amajyepfo': 'South',
    'Southern Province': 'South',
    'Iburasirazuba': 'East',
    'Eastern Province': 'East',
    'Iburengerazuba': 'West',
    'Western Province': 'West',
};

/**
 * Find the unit's path in the database to traverse JSON
 */
async function getUnitFullPath(unitId: string): Promise<any[]> {
    const path: any[] = [];
    let currId: string | null = unitId;
    while (currId) {
        const u: any = await prisma.administrativeUnit.findUnique({ where: { id: currId } });
        if (!u) break;
        path.unshift(u);
        currId = u.parentId;
    }
    return path;
}

/**
 * Navigate through Rwanda Admin JSON using the unit path
 */
function getDataAtUnitPath(path: any[], data: any) {
    let current = data;
    for (const unit of path) {
        let nameToFind = unit.name;
        if (unit.level === AdministrativeLevel.PROVINCE) {
            nameToFind = provinceMapping[unit.name] || unit.name;
        }

        if (Array.isArray(current)) {
            const found = current.find(item => item.name === nameToFind);
            if (!found) return null;
            current = found;
        } else if (current && typeof current === 'object') {
            current = current[nameToFind];
        } else {
            return null;
        }
    }
    return current;
}

/**
 * Extract names of children from the administrative data structure
 */
function getChildrenFromJson(path: any[], data: any): string[] {
    const container = getDataAtUnitPath(path, data);
    if (!container) return [];

    // The JSON structure:
    // Province/District level: objects where keys are child names
    // Sector level: objects where keys are cell names
    // Cell level: objects/arrays for villages

    if (Array.isArray(container)) {
        return container.map(c => typeof c === 'string' ? c : c.name).filter(Boolean);
    }

    if (container && typeof container === 'object') {
        return Object.keys(container);
    }

    return [];
}

/**
 * Build the full location path by traversing parent chain
 * Returns: "Province → District → Sector → Cell → Village"
 */
async function buildLocationPath(unitId: string): Promise<string> {
    const parts: string[] = [];
    let currentId: string | null = unitId;

    while (currentId) {
        const unit: { id: string; name: string; parentId: string | null; level: string } | null = await prisma.administrativeUnit.findUnique({
            where: { id: currentId },
            select: { id: true, name: true, parentId: true, level: true }
        });

        if (!unit) break;

        // Format: "Level (Name)" similar to escalation path logic
        const levelDisplay = unit.level.charAt(0).toUpperCase() + unit.level.slice(1).toLowerCase();
        parts.push(`${levelDisplay} (${unit.name})`);

        // Stop at National level to avoid redundancy or if we just want up to District/Province
        if (unit.level === 'NATIONAL') break;

        currentId = unit.parentId;
    }

    return parts.join(' → ');
}

/**
 * Build custom escalation path: Village (Name) -> Cell (Name) -> ... -> CurrentLevel (Name)
 */
async function buildEscalationPath(originUnitId: string, currentLevel: string): Promise<string> {
    const parts: string[] = [];
    let currentId: string | null = originUnitId;

    // 1. Traverse up from Origin
    // We want Bottom-Up: Village -> Cell -> Sector ...
    // So we push to array and join with ->

    // We need to stop when we reach the `currentLevel`? 
    // Or do we show the full history up to current?
    // User wants: village(name) -> cell(name) -> sector(current)

    // Map of Levels to Order for comparison

    while (currentId) {
        const unit: { id: string; name: string; parentId: string | null; level: string } | null = await prisma.administrativeUnit.findUnique({
            where: { id: currentId },
            select: { id: true, name: true, parentId: true, level: true }
        });

        if (!unit) break;

        // Format: "Level (Name)"
        // Convert Level to Title Case for better display? Or use as is.
        // User said: "village( village name)" -> lowercase/titlecase
        const levelDisplay = unit.level.charAt(0).toUpperCase() + unit.level.slice(1).toLowerCase();
        parts.push(`${levelDisplay} (${unit.name})`);

        // If we reached the current level of the case, stops?
        // Actually, originUnitId is the bottom. We keep going up until we hit the case's current level.
        if (unit.level === currentLevel) {
            break;
        }

        // Safety break for top
        if (unit.level === 'NATIONAL') break;

        currentId = unit.parentId;
    }

    return parts.join(' → ');
}

export class CaseService {
    private repository: CaseRepository;

    constructor() {
        this.repository = caseRepository;
    }

    /**
     * Create a new case
     */
    async createCase(dto: CreateCaseDto, userId?: string): Promise<CaseResponseDto> {
        logger.info('Creating new case', { category: dto.category, anonymous: dto.submittedAnonymously });

        // Resolve administrativeUnitId - it may be a path string like "Kigali_Nyarugenge_Gitega_Akabahizi_Rurama"
        let resolvedUnitId = dto.administrativeUnitId;

        // Check if it's a path string (contains underscores) vs a real CUID
        if (dto.administrativeUnitId.includes('_')) {
            const parts = dto.administrativeUnitId.split('_');
            const villageName = parts[parts.length - 1]; // Last part is village name

            // Try to find the village unit by name
            let villageUnit = await prisma.administrativeUnit.findFirst({
                where: {
                    name: villageName,
                    level: 'VILLAGE'
                }
            });

            if (villageUnit) {
                resolvedUnitId = villageUnit.id;
                logger.info('Resolved location path to unit ID', { path: dto.administrativeUnitId, unitId: resolvedUnitId });
            } else {
                // Auto-create the village unit if it doesn't exist
                // Build a code from the path for uniqueness
                const code = parts.join('-').toUpperCase().replace(/\s+/g, '');

                villageUnit = await prisma.administrativeUnit.create({
                    data: {
                        name: villageName,
                        level: 'VILLAGE',
                        code: code.substring(0, 50), // Limit to 50 chars
                    }
                });

                resolvedUnitId = villageUnit.id;
                logger.info('Created new village unit', { villageName, unitId: resolvedUnitId });
            }
        }

        // Create the case with resolved unit ID
        const modifiedDto = { ...dto, administrativeUnitId: resolvedUnitId };
        const newCase = await this.repository.create(modifiedDto, userId);

        // Create initial assignment to village leader
        await this.createAssignment(newCase);

        // Publish event for other services
        await publishEvent(CHANNELS.CASE_CREATED, {
            caseId: newCase.id,
            caseReference: newCase.caseReference,
            category: newCase.category,
            urgency: newCase.urgency,
        });

        // Log audit event
        await publishEvent(CHANNELS.AUDIT_LOG, {
            entityType: 'Case',
            entityId: newCase.id,
            action: 'CREATE',
            performedBy: userId || 'ANONYMOUS',
        });

        logger.info('Case created successfully', { caseReference: newCase.caseReference });

        return await this.toResponseDto(newCase);
    }

    /**
     * Track case by reference
     */
    async trackCase(caseReference: string): Promise<CaseResponseDto | null> {
        const foundCase = await this.repository.findByReference(caseReference);

        if (!foundCase) {
            return null;
        }

        return this.toResponseDtoWithPath(foundCase);
    }

    /**
     * Get case details
     */
    async getCaseById(id: string): Promise<CaseResponseDto | null> {
        const foundCase = await this.repository.findById(id);

        if (!foundCase) {
            return null;
        }

        return this.toResponseDtoWithPath(foundCase);
    }

    /**
     * Get current user's cases
     */
    async getUserCases(userId: string, options: { limit?: number; offset?: number; status?: string }) {
        const { limit = 20, offset = 0, status } = options;

        // Build where clause
        const where: any = { submitterId: userId };
        if (status) {
            where.status = status;
        }

        const [cases, total] = await Promise.all([
            prisma.case.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                take: limit,
                skip: offset,
                include: { evidence: true, administrativeUnit: true },
            }),
            prisma.case.count({ where })
        ]);

        // Build location paths for all cases
        const caseDtos = await Promise.all(
            cases.map(async (c: any) => {
                return this.toResponseDtoWithPath(c);
            })
        );

        return {
            cases: caseDtos,
            total
        };
    }

    /**
     * Get cases assigned to leader
     */
    async getLeaderCases(leaderId: string, page = 1, limit = 20) {
        const result = await this.repository.findByLeader(leaderId, page, limit);

        const cases = await Promise.all(result.cases.map(async (c) => {
            // Find assignment for this leader
            const assignment = (c as any).assignments?.find((a: any) => a.leaderId === leaderId && a.isActive);
            const deadline = assignment?.deadlineAt ? assignment.deadlineAt.toISOString() : undefined;
            return this.toResponseDtoWithPath(c, deadline);
        }));

        return {
            cases,
            total: result.total,
            page,
            limit,
        };
    }

    /**
     * Get all cases in leader's jurisdiction with assignment info
     * This matches the dashboard stats by using the same jurisdiction-based query
     */
    async getJurisdictionCases(leaderId: string, options: { page: number; limit: number; status?: string }) {
        const { page, limit, status } = options;
        const skip = (page - 1) * limit;

        // 1. Get leader's jurisdiction (same logic as getPerformanceMetrics)
        const leadership = await prisma.leaderAssignment.findFirst({
            where: { userId: leaderId, isActive: true },
            include: { administrativeUnit: true }
        });

        const whereClause: any = {};

        if (leadership) {
            // Filter by jurisdiction using hierarchical code prefix
            whereClause.administrativeUnit = {
                code: { startsWith: leadership.administrativeUnit.code }
            };
        } else {
            // Check if user is ADMIN - they see all cases
            const user = await prisma.user.findUnique({ where: { id: leaderId } });
            if (user?.role !== 'ADMIN') {
                logger.warn('No jurisdiction for non-admin user', { leaderId });
                return { cases: [], total: 0, page, limit };
            }
            // Admin sees all cases - no filter
        }

        // Apply status filter if provided
        if (status && status !== 'All') {
            whereClause.status = status.toUpperCase().replace(' ', '_');
        }

        // 2. Fetch cases with assignments including leader info
        const [cases, total] = await Promise.all([
            prisma.case.findMany({
                where: whereClause,
                include: {
                    administrativeUnit: true,
                    evidence: true,
                    submitter: { select: { id: true, name: true } },
                    assignments: {
                        where: { isActive: true },
                        include: {
                            leader: { select: { id: true, name: true, phone: true } }
                        }
                    }
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit
            }),
            prisma.case.count({ where: whereClause })
        ]);

        // 3. Transform to response with assigned leader info and location paths
        const caseDtos = await Promise.all(
            cases.map(async (c: any) => {
                const activeAssignment = c.assignments?.[0];
                const deadline = activeAssignment?.deadlineAt?.toISOString();
                return this.toResponseDtoWithPath(c, deadline);
            })
        );

        logger.info('Jurisdiction cases fetched', {
            leaderId,
            total,
            jurisdictionCode: leadership?.administrativeUnit.code || 'NATIONAL'
        });

        return {
            cases: caseDtos,
            total,
            page,
            limit
        };
    }

    /**
     * Get all cases (Admin only)
     */
    async getAllCases(page = 1, limit = 50, search?: string, locationId?: string) {
        const result = await this.repository.findAll(page, limit, search, locationId);
        const cases = await Promise.all(result.cases.map(c => this.toResponseDtoWithPath(c)));
        return {
            cases,
            total: result.total,
            page,
            limit
        };
    }

    /**
     * Get global stats (Admin only)
     */
    async getGlobalStats() {
        return this.repository.getGlobalStats();
    }

    /**
     * Update case status (for leaders)
     */
    async escalateCase(caseId: string, reason: string, userId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) throw new Error('Case not found');

        // 1. Determine next level and target unit
        const nextLevel = getNextEscalationLevel(existingCase.currentLevel);
        if (!nextLevel) throw new Error('Cannot escalate: Already at maximum level');

        // Find the unit at the next level that is an ancestor of the origin unit
        const targetUnit = await getAncestorAtLevel(prisma, existingCase.administrativeUnitId, nextLevel);

        if (!targetUnit) {
            throw new Error(`Cannot escalate: No ancestor found at level ${nextLevel}`);
        }

        // 2. Validate current leader assignment (optional security check)
        // For now allowing any active leader of the current unit to escalate

        // 3. Deactivate current assignments
        await prisma.caseAssignment.updateMany({
            where: { caseId: caseId, isActive: true },
            data: { isActive: false, completedAt: new Date() } // Marked as completed at this level
        });

        // 4. Update Case Level (Keep administrativeUnitId as Origin)
        const updatedCase = await prisma.case.update({
            where: { id: caseId },
            data: {
                currentLevel: nextLevel,
                status: 'IN_PROGRESS',
            }
        });


        // 5. Create new Assignment for the Target Unit Leader
        const assignedLeader = await findNearestLeader(prisma, targetUnit.id);

        if (assignedLeader) {
            const now = new Date();
            const deadline = this.calculateDeadline(existingCase.urgency);

            // Deactivate any assignments the found leader might already have for this case 
            // (unlikely if strictly going up, but safe)

            await prisma.caseAssignment.create({
                data: {
                    caseId: caseId,
                    administrativeUnitId: assignedLeader.administrativeUnitId,
                    leaderId: assignedLeader.userId, // Link to the user
                    assignedAt: now,
                    deadlineAt: deadline,
                    escalationReason: reason,
                    isActive: true
                }
            });

            // Notify the new owner
            await publishEvent(CHANNELS.NOTIFICATION_SEND, {
                userId: assignedLeader.userId,
                caseId: caseId,
                channel: 'PUSH',
                message: `Case escalated to you: ${existingCase.title}`,
            });
        } else {
            logger.warn('Escalated case has no leader found in upstream hierarchy', {
                caseId,
                startParentId: targetUnit.id
            });
        }

        // 6. Log Event
        await prisma.escalationEvent.create({
            data: {
                caseId,
                fromLevel: existingCase.currentLevel,
                toLevel: nextLevel,
                triggerReason: 'MANUAL_ESCALATION',
                triggeredBy: userId
            }
        });

        return await this.toResponseDto(updatedCase as unknown as CaseEntity);
    }

    /**
     * Manual Case Assignment by Head/Peer
     */
    async assignCaseManually(caseId: string, targetLeaderId: string, deadline: Date, assignerId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) throw new Error('Case not found');

        // 1. Verify Target Leader has jurisdiction
        const targetAssignment = await prisma.leaderAssignment.findFirst({
            where: {
                userId: targetLeaderId,
                isActive: true
            },
            include: { administrativeUnit: true }
        });

        if (!targetAssignment) {
            throw new Error('Target leader is not active.');
        }

        // Get Case Unit
        const caseUnit = await prisma.administrativeUnit.findUnique({
            where: { id: existingCase.administrativeUnitId },
            select: { code: true }
        });

        if (!caseUnit) throw new Error('Case location invalid');

        // Check if case is within leader's jurisdiction
        // Case Code: 010101 (Village), Leader Code: 0101 (Sector) -> StartsWith? Yes.
        // Leader Code: 01 (Province) -> StartsWith? Yes.
        // Note: Leader Code could be longer if assigning DOWN? 
        // Usually we assign to someone who manages that area.
        // If I assign to a Village Leader (010101) a case in the Village (010101), it matches.

        // Allow if case code starts with leader code (Leader covers the area)
        // OR if leader code starts with case code (Leader is in a sub-unit? - Rare/Maybe disallowed)

        if (!caseUnit.code.startsWith(targetAssignment.administrativeUnit.code)) {
            throw new Error('Target leader does not have jurisdiction over this case.');
        }

        // Run in transaction to guarantee consistency
        await prisma.$transaction(async (tx) => {
            // 2. Deactivate previous assignments for this case (GLOBAL - ensure only one active leader)
            await tx.caseAssignment.updateMany({
                where: {
                    caseId,
                    isActive: true
                },
                data: { isActive: false, completedAt: new Date() }
            });

            // 3. Create New Assignment
            await tx.caseAssignment.create({
                data: {
                    caseId,
                    administrativeUnitId: targetAssignment.administrativeUnitId, // Use the Target Leader's Unit
                    leaderId: targetLeaderId,
                    assignedAt: new Date(),
                    deadlineAt: deadline,
                    isActive: true
                }
            });

            // 4. Log Action
            await tx.caseAction.create({
                data: {
                    caseId,
                    performedBy: assignerId,
                    actionType: 'ASSIGNMENT',
                    notes: `Manually assigned to specific leader. Deadline: ${deadline.toISOString()}`
                }
            });

            // 5. Ensure Case Status is IN_PROGRESS (if it was OPEN or ESCALATED)
            await tx.case.update({
                where: { id: caseId },
                data: {
                    status: 'IN_PROGRESS',
                }
            });

            logger.info('Transaction committed for assignment', {
                caseId,
                targetLeaderId,
                assignerId
            });
        });

        // 6. Notify Target (Outside transaction - best effort)
        await publishEvent(CHANNELS.NOTIFICATION_SEND, {
            userId: targetLeaderId,
            caseId,
            channel: 'PUSH',
            message: `New manual assignment: ${existingCase.title}`
        });

        const updated = await this.repository.findById(caseId);
        return await this.toResponseDto(updated!);
    }

    /**
     * Extend Deadline ("On Hold")
     * Max 2 extensions allowed per assignment.
     * Max 3 days per extension.
     */
    async extendDeadline(caseId: string, leaderId: string, days: number, reason: string): Promise<CaseResponseDto> {
        // 1. Validate inputs
        if (days < 1 || days > 3) {
            throw new Error('Extension cannot exceed 3 days.');
        }

        const caseData = await this.repository.findById(caseId);
        if (!caseData) throw new Error('Case not found');

        // 2. Find Active Assignment
        const activeAssignment = await prisma.caseAssignment.findFirst({
            where: {
                caseId,
                leaderId,
                isActive: true
            }
        });

        if (!activeAssignment) {
            throw new Error('You do not have an active assignment for this case.');
        }

        // 3. Validate Limit (Max 2 extensions)
        if (activeAssignment.extensionCount >= 2) {
            throw new Error('Maximum extension limit (2) reached for this assignment.');
        }

        // 4. Calculate New Deadline
        const newDeadline = new Date(activeAssignment.deadlineAt);
        newDeadline.setDate(newDeadline.getDate() + days);

        // 5. Update Assignment
        await prisma.caseAssignment.update({
            where: { id: activeAssignment.id },
            data: {
                deadlineAt: newDeadline,
                extensionCount: { increment: 1 },
                extensionReason: reason
            }
        });

        // 6. Log Action
        await prisma.caseAction.create({
            data: {
                caseId,
                performedBy: leaderId,
                actionType: 'STATUS_UPDATE',
                notes: `Deadline extended by ${days} days. Reason: "${reason}". Extension ${activeAssignment.extensionCount + 1}/2.`
            }
        });

        // 7. Re-fetch case to get fresh data with updated assignment
        const updatedCase = await this.repository.findById(caseId);
        return this.toResponseDto(updatedCase!);
    }

    async updateCase(caseId: string, dto: UpdateCaseDto, userId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);

        if (!existingCase) {
            throw new Error('Case not found');
        }

        // Update status if provided
        if (dto.status) {
            // Auto-Assignment Logic:
            // If moving to IN_PROGRESS from OPEN or ESCALATED, assign to the acting user
            if (dto.status === 'IN_PROGRESS' && (existingCase.status === 'OPEN' || existingCase.status === 'ESCALATED')) {
                logger.info('Auto-assigning case during status update', { caseId, userId });

                // 1. Deactivate existing active assignments if any
                await this.completeAssignment(caseId);

                // 2. Create new assignment for the acting leader
                const deadlineAt = this.calculateDeadline(existingCase.urgency);
                await prisma.caseAssignment.create({
                    data: {
                        caseId,
                        administrativeUnitId: existingCase.administrativeUnitId,
                        leaderId: userId,
                        deadlineAt,
                        isActive: true,
                    },
                });
            }

            await this.repository.updateStatus(caseId, dto.status);

            // Log the action
            await prisma.caseAction.create({
                data: {
                    caseId,
                    performedBy: userId,
                    actionType: 'STATUS_UPDATE',
                    notes: dto.notes || `Status changed to ${dto.status}`,
                },
            });

            // Publish event
            await publishEvent(CHANNELS.CASE_UPDATED, {
                caseId,
                status: dto.status,
                updatedBy: userId,
            });

            // If resolved, mark assignment as complete
            if (dto.status === 'RESOLVED' || dto.status === 'CLOSED') {
                await this.completeAssignment(caseId);
                if (dto.status === 'RESOLVED') {
                    await publishEvent(CHANNELS.CASE_RESOLVED, { caseId });
                }
            }
        }

        const updatedCase = await this.repository.findById(caseId);
        return await this.toResponseDto(updatedCase!);
    }

    /**
     * Review case (Accept/Reject/Info)
     */
    /**
     * Extend deadline for a case assignment
     */
    /**
     * Review case (Accept/Reject)
     */
    async reviewCase(caseId: string, action: 'ACCEPT' | 'REJECT' | 'REQUEST_INFO', userId: string, notes?: string): Promise<CaseResponseDto> {
        let status: 'IN_PROGRESS' | 'CLOSED' | 'OPEN' | undefined;

        if (action === 'ACCEPT') status = 'IN_PROGRESS';
        else if (action === 'REJECT') status = 'CLOSED';

        return this.updateCase(caseId, { status: status as any, notes }, userId);
    }



    /**
     * Resolve case
     */
    /**
     * Resolve case
     */
    async resolveCase(caseId: string, resolutionNotes: string, userId: string, attachmentId?: string): Promise<CaseResponseDto> {
        await prisma.$transaction(async (tx) => {
            // 1. Update Case Status to PENDING_CONFIRMATION (awaiting citizen confirmation)
            const updatedCase = await tx.case.update({
                where: { id: caseId },
                data: {
                    status: CaseStatus.PENDING_CONFIRMATION, // Changed from RESOLVED - awaits citizen confirmation
                }
            });

            // 2. Create CaseResolution record
            await tx.caseResolution.create({
                data: {
                    caseId,
                    notes: resolutionNotes,
                    resolvedBy: userId,
                    evidenceId: attachmentId,
                }
            });

            // 3. Log Action
            await tx.caseAction.create({
                data: {
                    caseId,
                    performedBy: userId,
                    actionType: 'RESOLUTION',
                    notes: `Leader marked resolved. Awaiting citizen confirmation. Notes: ${resolutionNotes}`,
                }
            });

            // Note: Assignment NOT completed yet - stays active until citizen confirms or disputes

            return updatedCase;
        });

        // Publish event (outside transaction)
        await publishEvent(CHANNELS.CASE_UPDATED, {
            caseId,
            status: 'PENDING_CONFIRMATION',
            updatedBy: userId,
        });
        await publishEvent(CHANNELS.CASE_RESOLVED, { caseId, status: 'PENDING_CONFIRMATION' });

        logger.info('Case marked as resolved, awaiting citizen confirmation', { caseId });

        // Return full DTO
        const finalCase = await this.repository.findById(caseId);
        return await this.toResponseDto(finalCase!);
    }

    /**
     * Create assignment to leader of administrative unit
     */
    private async createAssignment(caseData: CaseEntity): Promise<void> {
        const assignedLeader = await findNearestLeader(prisma, caseData.administrativeUnitId);

        if (!assignedLeader) {
            logger.warn('No leader found for unit or any parent in hierarchy', {
                initialUnitId: caseData.administrativeUnitId
            });
            // Consider assigning to a default system admin or leaving unassigned but flagged?
            // For now, return - system will show as unassigned but visible in jurisdiction
            return;
        }

        // Calculate deadline
        const deadlineAt = this.calculateDeadline(caseData.urgency);

        await prisma.caseAssignment.create({
            data: {
                caseId: caseData.id,
                administrativeUnitId: assignedLeader.administrativeUnitId, // Assign to the unit where the leader was found
                leaderId: assignedLeader.userId,
                deadlineAt,
                isActive: true,
            },
        });

        // Send notification to leader
        await publishEvent(CHANNELS.NOTIFICATION_SEND, {
            userId: assignedLeader.userId,
            caseId: caseData.id,
            channel: 'PUSH',
            message: `New case assigned: ${caseData.title}`,
        });

        logger.info('Case assigned via hierarchy fallback', {
            caseId: caseData.id,
            originalUnit: caseData.administrativeUnitId,
            assignedUnit: assignedLeader.administrativeUnitId,
            leaderId: assignedLeader.userId
        });
    }

    /**
     * Complete active assignment
     */
    private async completeAssignment(caseId: string): Promise<void> {
        await prisma.caseAssignment.updateMany({
            where: { caseId, isActive: true },
            data: { completedAt: new Date(), isActive: false },
        });
    }

    /**
     * Calculate deadline based on case urgency using config
     */
    calculateDeadline(urgency: string): Date {
        const now = new Date();
        let hours = config.escalation.normalHours;

        if (urgency === 'EMERGENCY') hours = config.escalation.emergencyHours;
        else if (urgency === 'HIGH') hours = config.escalation.highHours;

        return new Date(now.getTime() + hours * 60 * 60 * 1000);
    }

    /**
     * Get escalation alerts for leader
     */
    async getEscalationAlerts(leaderId: string): Promise<CaseResponseDto[]> {
        // Find active assignments with approaching deadlines (< 24 hours)
        const tomorrow = new Date();
        tomorrow.setHours(tomorrow.getHours() + 24);

        const assignments = await prisma.caseAssignment.findMany({
            where: {
                leaderId,
                isActive: true,
                deadlineAt: {
                    lte: tomorrow,
                },
            },
            include: {
                case: {
                    include: {
                        assignments: {
                            where: { isActive: true },
                            include: { leader: { select: { name: true, phone: true } } }
                        },
                        administrativeUnit: true,
                        evidence: true,
                        resolution: { include: { evidence: true } }
                    }
                },
            },
            orderBy: {
                deadlineAt: 'asc',
            },
        });

        return Promise.all(assignments.map(a => this.toResponseDto(a.case as unknown as CaseEntity)));
    }

    /**
     * Mark alerts as viewed for a leader
     */
    async markAlertsViewed(leaderId: string, caseIds?: string[]): Promise<void> {
        const whereClause: any = {
            leaderId,
            isActive: true,
            alertViewed: false
        };

        if (caseIds && caseIds.length > 0) {
            whereClause.caseId = { in: caseIds };
        }

        await (prisma.caseAssignment as any).updateMany({
            where: whereClause,
            data: { alertViewed: true }
        });

        logger.info('Alerts marked as viewed', { leaderId, caseIds });
    }

    /**
     * Get case history/actions
     */
    async getCaseHistory(caseId: string): Promise<any[]> {
        return prisma.caseAction.findMany({
            where: { caseId },
            orderBy: { createdAt: 'desc' },
        });
    }


    /**
     * Mark case as resolved (pending citizen confirmation)
     */
    async markResolved(caseId: string, resolution: string, userId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) throw new Error('Case not found');

        // Create resolution record
        await prisma.caseResolution.create({
            data: {
                caseId,
                notes: resolution,
                resolvedBy: userId,
            }
        });

        // Update status to PENDING_CONFIRMATION
        const updatedCase = await prisma.case.update({
            where: { id: caseId },
            data: { status: CaseStatus.PENDING_CONFIRMATION }
        });

        // Log action
        await prisma.caseAction.create({
            data: {
                caseId,
                performedBy: userId,
                actionType: 'RESOLUTION',
                notes: resolution,
            }
        });

        logger.info('Case marked resolved, awaiting citizen confirmation', { caseId });
        await publishEvent(CHANNELS.CASE_RESOLVED, { caseId, status: 'PENDING_CONFIRMATION' });

        return this.toResponseDto(updatedCase as unknown as CaseEntity);
    }

    /**
     * Citizen confirms case is fully resolved
     */
    async citizenConfirmResolution(caseId: string, userId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) throw new Error('Case not found');

        if ((existingCase.status as string) !== 'PENDING_CONFIRMATION') {
            throw new Error('Case is not pending confirmation');
        }

        // Verify it's the case submitter (if not anonymous)
        if (existingCase.submitterId && existingCase.submitterId !== userId) {
            throw new Error('Only the case submitter can confirm resolution');
        }

        // Complete assignments
        await prisma.caseAssignment.updateMany({
            where: { caseId, isActive: true },
            data: { isActive: false, completedAt: new Date() }
        });

        // Update to CLOSED
        const updatedCase = await prisma.case.update({
            where: { id: caseId },
            data: {
                status: 'CLOSED',
                resolvedAt: new Date()
            }
        });

        // Log action
        await prisma.caseAction.create({
            data: {
                caseId,
                performedBy: userId,
                actionType: 'STATUS_UPDATE',
                notes: 'Citizen confirmed resolution - case closed',
            }
        });

        logger.info('Citizen confirmed resolution, case closed', { caseId });
        await publishEvent(CHANNELS.CASE_RESOLVED, { caseId, status: 'CLOSED', confirmedBy: userId });

        return this.toResponseDto(updatedCase as unknown as CaseEntity);
    }

    /**
     * Citizen disputes resolution - escalate to next level
     */
    async citizenDisputeResolution(caseId: string, userId: string, disputeReason: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) throw new Error('Case not found');

        if ((existingCase.status as string) !== 'PENDING_CONFIRMATION') {
            throw new Error('Case is not pending confirmation');
        }

        // Verify it's the case submitter
        if (existingCase.submitterId && existingCase.submitterId !== userId) {
            throw new Error('Only the case submitter can dispute resolution');
        }

        // Escalate to next level with dispute reason
        const escalationReason = `Citizen disputed: ${disputeReason}`;

        logger.info('Citizen disputed resolution, escalating', { caseId, reason: disputeReason });

        // Use the escalateCase method with a system user flag
        return this.escalateCase(caseId, escalationReason, userId);
    }

    /**
     * Get performance metrics for leader (Jurisdiction View)
     */
    async getPerformanceMetrics(leaderId: string, filters?: { startDate?: Date, endDate?: Date, category?: string, locationId?: string }) {
        // 1. Get Leader's Unit and Direct Children (for Regional Breakdown)
        const leadership = await prisma.leaderAssignment.findFirst({
            where: { userId: leaderId, isActive: true },
            include: {
                administrativeUnit: {
                    include: { children: true }
                }
            }
        });

        logger.info('DEBUG getPerformanceMetrics', { leaderId, leadership: !!leadership });

        // Initialize trends early to be available in all return paths
        const weeklyTrends = Array(7).fill(0).map((_, i) => {
            const d = new Date();
            d.setDate(d.getDate() - (6 - i));
            return {
                day: d.toLocaleDateString('en-US', { weekday: 'short' }),
                date: d.toISOString().split('T')[0],
                newCases: 0,
                resolvedCases: 0,
                activeCases: 0
            };
        });

        let myUnit: any;
        let dbSubUnits: any[] = [];
        let rootCode = '';

        if (!leadership) {
            // Check if user is ADMIN - they get a virtual Default Assignment (National View)
            const user = await prisma.user.findUnique({ where: { id: leaderId } });

            logger.info('getPerformanceMetrics: Logic Check', {
                leaderId,
                hasAssignment: false,
                userFound: !!user,
                userRole: user?.role
            });

            if (user?.role === 'ADMIN') {
                logger.info('User is ADMIN with no assignment. Generating National View.', { leaderId });

                // Root is National
                myUnit = {
                    id: 'national_virtual',
                    name: 'National', // CHANGED "Rwanda" to "National" to match frontend expectations if any
                    level: 'NATIONAL',
                    code: '',
                    children: []
                };
                rootCode = ''; // Matches everything

                // If no specific location selected, show Provinces
                if (!filters?.locationId || filters.locationId === 'national_virtual') {
                    dbSubUnits = await prisma.administrativeUnit.findMany({
                        where: { level: 'PROVINCE' }
                    });
                    logger.info(`Fetched ${dbSubUnits.length} provinces for National View.`);
                }
            } else {
                logger.warn('No active leader assignment for user', { leaderId, role: user?.role });
                return {
                    totalCases: 0,
                    resolvedCases: 0,
                    pendingCases: 0,
                    escalatedCases: 0,
                    resolutionRate: 0,
                    avgResponseTimeHours: 0,
                    escalationRate: 0,
                    overdueCases: 0,
                    casesByCategory: {},
                    weeklyTrends,
                    subUnitBreakdown: []
                };
            }
        } else {
            myUnit = leadership.administrativeUnit;
            dbSubUnits = myUnit.children;
            rootCode = myUnit.code;
        }

        // Context Switching / Drill Down Logic
        if (filters?.locationId && filters.locationId !== 'All Locations' && filters.locationId !== myUnit.id) {
            // User requested specific unit. Verify it's within jurisdiction.
            const targetUnit = await prisma.administrativeUnit.findUnique({
                where: { id: filters.locationId },
                include: { children: true }
            });

            if (targetUnit) {
                // Security Check: Is targetUnit a descendant of rootUnit?
                // For National (rootCode=''), always true.
                if (rootCode === '' || targetUnit.code.startsWith(rootCode + ':')) {
                    logger.info(`Context Switch: Drilled down to ${targetUnit.name} (${targetUnit.level})`);
                    myUnit = targetUnit;
                    dbSubUnits = targetUnit.children;
                } else {
                    logger.warn(`Security Alert: User ${leaderId} tried to access ${targetUnit.name} outside jurisdiction.`);
                    // Fallback to root unit (do not switch)
                }
            }
        } else if (leadership && (!filters?.locationId || filters.locationId === myUnit.id)) {
            // If explicit root requested or default, ensure dbSubUnits are populated if not set above (Admin case handles its own)
            if (!dbSubUnits || dbSubUnits.length === 0) {
                // Reload root with children just in case (though leadership query included them)
                // Actually leadership query included children, so we are good.
            }
        }

        return this.calculateMetricsForUnit(myUnit, filters, dbSubUnits);
    }

    // Refactored core logic into helper to support Virtual Units
    async calculateMetricsForUnit(myUnit: any, filters: any, dbSubUnits: any[]) {
        // Initialize trends locally
        const weeklyTrends = Array(7).fill(0).map((_, i) => {
            const d = new Date();
            d.setDate(d.getDate() - (6 - i));
            return {
                day: d.toLocaleDateString('en-US', { weekday: 'short' }),
                date: d.toISOString().split('T')[0],
                newCases: 0,
                resolvedCases: 0,
                activeCases: 0
            };
        });

        // Use pre-loaded JSON
        const unitPath = myUnit.level === 'NATIONAL' ? [] : await getUnitFullPath(myUnit.id);
        const jsonChildrenNames = myUnit.level === 'NATIONAL'
            ? ['Northern Province', 'Southern Province', 'Eastern Province', 'Western Province', 'Kigali City']
            : getChildrenFromJson(unitPath, ADMIN_JSON);

        logger.info('DEBUG Hierarchy Info', {
            unitName: myUnit.name,
            unitCode: myUnit.code,
            unitLevel: myUnit.level
        });

        // Merge: Use DB children where they exist, and JSON children as fallbacks
        const subUnitsForBreakdown: Array<{ id: string, name: string }> = [];
        const dbNames = new Set(dbSubUnits.map(u => u.name));

        // Add DB units first
        subUnitsForBreakdown.push(...dbSubUnits.map(u => ({ id: u.id, name: u.name })));

        // Add JSON-only units as virtual units
        jsonChildrenNames.forEach(name => {
            if (!dbNames.has(name)) {
                subUnitsForBreakdown.push({ id: name, name });
            }
        });

        logger.info('DEBUG FINAL merged subunits', {
            count: subUnitsForBreakdown.length,
            names: subUnitsForBreakdown.map(s => s.name)
        });

        // For case filtering, we use hierarchical codes for subtree fetch
        const whereClause: any = {
            administrativeUnit: {
                code: { startsWith: myUnit.code }
            }
        };

        if (filters?.locationId && filters.locationId !== 'All Locations') {
            const selectedUnit = dbSubUnits.find(u => u.id === filters.locationId || u.name === filters.locationId);
            if (selectedUnit) {
                whereClause.administrativeUnit = { code: { startsWith: selectedUnit.code } };
            } else if (filters.locationId === myUnit.id) {
                whereClause.administrativeUnit = { code: { startsWith: myUnit.code } };
            } else {
                return {
                    totalCases: 0,
                    resolvedCases: 0,
                    pendingCases: 0,
                    escalatedCases: 0,
                    resolutionRate: 0,
                    avgResponseTimeHours: 0,
                    escalationRate: 0,
                    overdueCases: 0,
                    casesByCategory: {},
                    weeklyTrends,
                    subUnitBreakdown: subUnitsForBreakdown.map(u => ({
                        unitId: u.id,
                        unitName: u.name,
                        totalCases: 0,
                        resolutionRate: 0,
                        avgResponseTimeHours: 0,
                        escalationRate: 0,
                        status: 'On Track'
                    }))
                };
            }
        }

        if (filters?.category && filters.category !== 'All Categories') {
            let category = filters.category.toUpperCase();
            // Map common frontend labels to backend enum
            if (category === 'GENERAL') category = 'OTHER';

            // Validate against known enum values to prevent Prisma crash
            const validCategories = ['JUSTICE', 'HEALTH', 'LAND', 'INFRASTRUCTURE', 'SECURITY', 'SOCIAL', 'EDUCATION', 'OTHER'];
            if (validCategories.includes(category)) {
                whereClause.category = category as any;
            } else {
                // Fallback or ignore if invalid (safe default)
                logger.warn(`Invalid category filter: ${filters.category}, ignoring.`);
            }
        }

        if (filters?.startDate || filters?.endDate) {
            whereClause.createdAt = {};
            if (filters.startDate) whereClause.createdAt.gte = filters.startDate;
            if (filters.endDate) whereClause.createdAt.lte = filters.endDate;
        }

        const cases = await prisma.case.findMany({
            where: whereClause,
            include: {
                administrativeUnit: true,
                assignments: {
                    where: { isActive: true }
                },
                escalationEvents: true // NEW: Include to count escalated cases
            }
        });

        const total = cases.length;

        // DEBUG: Log fetched cases
        logger.info('[Metrics] Cases fetched', {
            total,
            whereClause: JSON.stringify(whereClause),
            sampleCases: cases.slice(0, 3).map(c => ({
                id: c.id,
                status: c.status,
                urgency: c.urgency,
                unitCode: c.administrativeUnit.code
            }))
        });

        if (total === 0) {
            logger.warn('[Metrics] No cases found - returning empty metrics');
            return {
                totalCases: 0,
                resolvedCases: 0,
                pendingCases: 0,
                escalatedCases: 0,
                urgentCases: 0,
                resolutionRate: 0,
                avgResponseTimeHours: 0,
                escalationRate: 0,
                overdueCases: 0,
                casesByCategory: {},
                weeklyTrends,
                subUnitBreakdown: subUnitsForBreakdown.map(u => ({
                    unitId: u.id,
                    unitName: u.name,
                    totalCases: 0,
                    resolutionRate: 0,
                    avgResponseTimeHours: 0,
                    escalationRate: 0,
                    status: 'On Track'
                }))
            };
        }

        let resolved = 0;
        let escalated = 0;
        let overdue = 0;
        let totalResponseTimeMinutes = 0;
        let casesWithResponseTime = 0;
        const byCategory: Record<string, number> = {};
        const now = new Date();

        const getTrendIndex = (date: Date) => {
            const dateString = date.toISOString().split('T')[0];
            return weeklyTrends.findIndex((t: any) => t.date === dateString);
        };

        const rollupMap = new Map<string, typeof cases>();
        const nameToIdMap = new Map<string, string>();

        subUnitsForBreakdown.forEach(u => {
            rollupMap.set(u.id, []);
            nameToIdMap.set(u.name.toUpperCase(), u.id);
            // Also map without "Province" suffix if needed? No, user screenshot matches
        });

        for (const c of cases) {
            const status = c.status as any;
            if (status === 'RESOLVED' || status === 'CLOSED' || status === 'PENDING_CONFIRMATION') {
                resolved++;
                if (c.resolvedAt) {
                    const diffMins = (new Date(c.resolvedAt).getTime() - new Date(c.createdAt).getTime()) / 60000;
                    totalResponseTimeMinutes += diffMins;
                    casesWithResponseTime++;
                    const idx = getTrendIndex(new Date(c.resolvedAt));
                    if (idx !== -1) weeklyTrends[idx].resolvedCases++;
                }
            }

            // FIX: Check if case has escalation events instead of status === 'ESCALATED'
            if (c.escalationEvents && c.escalationEvents.length > 0) {
                escalated++;
            }

            if (c.status !== 'RESOLVED' && c.assignments.length > 0) {
                if (new Date(c.assignments[0].deadlineAt) < now) overdue++;
            }
            byCategory[c.category] = (byCategory[c.category] || 0) + 1;
            const idx = getTrendIndex(new Date(c.createdAt));
            if (idx !== -1) weeklyTrends[idx].newCases++;

            const caseCode = c.administrativeUnit.code;

            // Fixed: Use robust check against actual sub-unit codes
            const directChild = dbSubUnits.find(u => caseCode === u.code || caseCode.startsWith(u.code + ':'));

            if (directChild) {
                rollupMap.get(directChild.id)?.push(c);
            } else {
                // Fallback for JSON or virtual units - try to match by name token
                const myCodeParts = myUnit.code ? myUnit.code.split(':').length : 0;
                const parts = caseCode.split(':');
                if (parts.length > myCodeParts) {
                    // e.g. "NORTHERN PROVINCE"
                    const childNameToken = parts[myCodeParts].replace(/_/g, ' ').toUpperCase();

                    if (nameToIdMap.has(childNameToken)) {
                        const id = nameToIdMap.get(childNameToken)!;
                        rollupMap.get(id)?.push(c);
                    }
                }
            }
        }

        weeklyTrends.forEach(t => {
            t.activeCases = Math.max(0, t.newCases - t.resolvedCases);
        });

        const subUnitBreakdown = subUnitsForBreakdown.map(unit => {
            const unitCases = rollupMap.get(unit.id) || [];

            // DEBUG LOGGING
            if (unitCases.length > 0) {
                logger.info(`[Metrics] Unit ${unit.name} has ${unitCases.length} cases.`);
            }

            let uResolved = 0;
            let uEscalated = 0;
            let uOpen = 0;
            let uActive = 0; // New: In Progress
            let uResponseTime = 0;
            let uTimeCount = 0;

            unitCases.forEach(c => {
                const status = c.status as any; // Cast to any to avoid stale type lint errors
                if (status === 'RESOLVED' || status === 'CLOSED' || status === 'PENDING_CONFIRMATION') {
                    uResolved++;
                    if (c.resolvedAt) {
                        const diff = (new Date(c.resolvedAt).getTime() - new Date(c.createdAt).getTime()) / 60000;
                        uResponseTime += diff;
                        uTimeCount++;
                    }
                }

                // FIX: Check escalation events instead of status
                if (c.escalationEvents && c.escalationEvents.length > 0) {
                    uEscalated++;
                } else if (status === 'IN_PROGRESS') {
                    uActive++;
                } else {
                    // OPEN, COMMUNITY, or others
                    uOpen++;
                }
            });

            const uTotal = unitCases.length;
            return {
                unitId: unit.id,
                unitName: unit.name,
                totalCases: uTotal,
                openCases: uOpen,
                activeCases: uActive, // New field
                resolvedCases: uResolved,
                escalatedCases: uEscalated,
                resolutionRate: uTotal > 0 ? (uResolved / uTotal) * 100 : 0,
                avgResponseTimeHours: uTimeCount > 0 ? (uResponseTime / uTimeCount / 60) : 0,
                escalationRate: uTotal > 0 ? (uEscalated / uTotal) * 100 : 0,
                status: 'On Track'
            };
        });

        logger.info(`[Metrics Debug] Returning ${subUnitBreakdown.length} sub-units breakdown.`);

        // Calculate top-level breakdown for the current unit
        let topActive = 0;
        let topOpen = 0;
        let topUrgent = 0; // New: Urgent (High/Emergency)

        logger.info('[Metrics] Starting top-level metrics calculation', { totalCases: cases.length });

        // We can iterate 'cases' (which are all cases in this jurisdiction filtered by date/category)
        cases.forEach(c => {
            const status = c.status as any;
            if (status === 'IN_PROGRESS') {
                topActive++;
            } else if (status !== 'RESOLVED' && status !== 'CLOSED' && status !== 'PENDING_CONFIRMATION' && status !== 'ESCALATED') {
                topOpen++;
            }
            // Check for urgency
            if (c.urgency === 'HIGH' || c.urgency === 'EMERGENCY') {
                // Only count unresolved urgent cases? Usually dashboard shows "Urgent (+24h)" which implies active urgent cases.
                // Assuming we want currently ACTIVE/OPEN urgent cases.
                if (status !== 'RESOLVED' && status !== 'CLOSED' && status !== 'PENDING_CONFIRMATION') {
                    topUrgent++;
                }
            }
        });

        logger.info('[Metrics] Final calculated metrics', {
            topActive,
            topOpen,
            topUrgent,
            totalCases: total,
            resolvedCases: resolved,
            escalatedCases: escalated
        });

        return {
            totalCases: total,
            resolvedCases: resolved,
            pendingCases: total - resolved,
            openCases: topOpen,
            activeCases: topActive,
            urgentCases: topUrgent, // New field exposed to frontend
            escalatedCases: escalated,
            resolutionRate: total > 0 ? (resolved / total) * 100 : 0,
            avgResponseTimeHours: casesWithResponseTime > 0 ? (totalResponseTimeMinutes / casesWithResponseTime) / 60 : 0,
            escalationRate: total > 0 ? (escalated / total) * 100 : 0,
            overdueCases: overdue,
            casesByCategory: byCategory,
            weeklyTrends,
            subUnitBreakdown,
            currentLevel: myUnit.level // Returning actual level for dynamic frontend headers
        };
    }

    /**
     * Add evidence to a case
     */
    async addEvidence(
        caseId: string,
        fileData: {
            fileName: string;
            fileSize: number;
            mimeType: string;
            path: string;
            url: string;
        },
        purpose: 'SUBMISSION' | 'RESOLUTION' = 'SUBMISSION',
        description?: string
    ) {
        // Determine evidence type
        let type: 'IMAGE' | 'VIDEO' | 'AUDIO' | 'DOCUMENT' = 'DOCUMENT';
        if (fileData.mimeType.startsWith('image/')) type = 'IMAGE';
        else if (fileData.mimeType.startsWith('video/')) type = 'VIDEO';
        else if (fileData.mimeType.startsWith('audio/')) type = 'AUDIO';

        const evidence = await prisma.evidence.create({
            data: {
                caseId,
                type,
                purpose,
                description,
                url: fileData.url,
                fileName: fileData.fileName,
                fileSize: fileData.fileSize,
                mimeType: fileData.mimeType,
            }
        });

        logger.info('Evidence added to case', { caseId, evidenceId: evidence.id, purpose, description });
        return evidence;
    }

    /**
     * Citizen updates their own case (title, description, urgency)
     * Restrictions: Only OPEN cases can be edited, only by the submitter
     */
    async citizenUpdateCase(caseId: string, dto: CitizenUpdateCaseDto, userId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);

        if (!existingCase) {
            throw new Error('Case not found');
        }

        // Verify ownership - only the submitter can edit
        if (existingCase.submitterId !== userId) {
            throw new Error('You can only edit your own cases');
        }

        // Verify status - only OPEN cases can be edited
        if (existingCase.status !== 'OPEN') {
            throw new Error('Only cases with OPEN status can be edited');
        }

        // Verify it's not anonymous (anonymous users can't edit without identity)
        if (existingCase.submittedAnonymously) {
            throw new Error('Anonymous cases cannot be edited');
        }

        // Build update data
        const updateData: any = {};
        if (dto.title) updateData.title = dto.title;
        if (dto.description) updateData.description = dto.description;
        if (dto.urgency) updateData.urgency = dto.urgency;

        // Only update if there's something to change
        if (Object.keys(updateData).length === 0) {
            throw new Error('No changes to apply');
        }

        // Update the case
        const updatedCase = await prisma.case.update({
            where: { id: caseId },
            data: updateData,
            include: { evidence: true, administrativeUnit: true }
        });

        // Log the action
        const changes = Object.keys(updateData).join(', ');
        await prisma.caseAction.create({
            data: {
                caseId,
                performedBy: userId,
                actionType: 'STATUS_UPDATE',
                notes: `Citizen edited case: ${changes}`,
            },
        });

        // Publish event
        await publishEvent(CHANNELS.CASE_UPDATED, {
            caseId,
            updatedBy: userId,
            changes: updateData,
        });

        logger.info('Citizen updated case', { caseId, changes });

        return await this.toResponseDto(updatedCase as unknown as CaseEntity);
    }

    /**
     * Transform entity to response DTO
     * @param locationPath Optional pre-computed location path
     */
    private async toResponseDto(entity: CaseEntity, deadline?: string, locationPath?: string): Promise<CaseResponseDto> {
        // Find active assignment if available
        // Find active assignment if available
        // Safety: Explicitly filter and sort in memory to guarantee correctness regardless of DB order
        const activeAssignments = (entity as any).assignments?.filter((a: any) => a.isActive) || [];

        // Sort Newest First (Desc)
        if (activeAssignments.length > 1) {
            activeAssignments.sort((a: any, b: any) => {
                const dA = new Date(a.assignedAt).getTime();
                const dB = new Date(b.assignedAt).getTime();
                return dB - dA;
            });
        }

        const activeAssignment = activeAssignments.length > 0 ? activeAssignments[0] : undefined;

        // Logging for debugging escalation issues
        if (entity.caseReference) {
            logger.info(`[Assignment Audit] Case ${entity.caseReference}`, {
                status: entity.status,
                level: entity.currentLevel,
                activeCount: activeAssignments.length,
                selectedLeader: activeAssignment?.leader?.name || 'NONE',
                deadline: activeAssignment?.deadlineAt?.toISOString() || 'NONE'
            });

            if (activeAssignments.length > 1) {
                logger.warn(`[Data Anomaly] Multiple active assignments for Case ${entity.caseReference}`);
            }
        }

        // Fetch resolved by name if resolved
        let resolvedByName: string | undefined;
        if ((entity as any).resolution && (entity as any).resolution.resolvedBy) {
            const resolver = await prisma.user.findUnique({
                where: { id: (entity as any).resolution.resolvedBy },
                select: { name: true }
            });
            resolvedByName = resolver?.name || undefined;
        }

        return {
            id: entity.id,
            caseReference: entity.caseReference,
            category: entity.category,
            urgency: entity.urgency,
            title: entity.title,
            description: entity.description,
            currentLevel: entity.currentLevel,
            locationName: (entity as any).administrativeUnit?.name || 'Unknown Location',
            locationPath: locationPath, // Full hierarchical path
            status: entity.status,
            submittedAnonymously: entity.submittedAnonymously,
            citizenName: entity.submittedAnonymously ? null : (entity as any).submitter?.name,
            createdAt: entity.createdAt.toISOString(),
            resolvedAt: entity.resolvedAt?.toISOString() || null,
            deadline: deadline || activeAssignment?.deadlineAt?.toISOString() || null,
            daysRemaining: null,
            administrativeUnitId: entity.administrativeUnitId,
            assignedLeaderId: activeAssignment?.leaderId,
            assignedLeaderName: activeAssignment?.leader?.name,
            assignedLeaderPhone: activeAssignment?.leader?.phone,
            extensionCount: activeAssignment?.extensionCount,
            evidence: entity.evidence?.map(e => ({
                id: e.id,
                type: e.type,
                purpose: (e as any).purpose,
                description: (e as any).description,
                url: e.url,
                fileName: e.fileName,
                mimeType: e.mimeType,
            })),
            administrativeUnit: (entity as any).administrativeUnit ? {
                id: (entity as any).administrativeUnit.id,
                name: (entity as any).administrativeUnit.name,
                code: (entity as any).administrativeUnit.code,
                level: (entity as any).administrativeUnit.level,
            } : undefined,
            resolution: (entity as any).resolution ? {
                notes: (entity as any).resolution.notes,
                resolvedBy: (entity as any).resolution.resolvedBy,
                resolvedByName: resolvedByName, // Injected name
                evidence: (entity as any).resolution.evidence ? {
                    id: (entity as any).resolution.evidence.id,
                    type: (entity as any).resolution.evidence.type,
                    url: (entity as any).resolution.evidence.url,
                    fileName: (entity as any).resolution.evidence.fileName,
                    mimeType: (entity as any).resolution.evidence.mimeType,
                } : undefined,
            } : undefined,
            isAlertViewed: activeAssignment?.alertViewed
        };
    }

    /**
     * Transform entity to response DTO with location path (async)
     */
    private async toResponseDtoWithPath(entity: CaseEntity, deadline?: string): Promise<CaseResponseDto> {
        const locationPath = entity.administrativeUnitId && entity.currentLevel
            ? await buildEscalationPath(entity.administrativeUnitId, entity.currentLevel)
            : entity.administrativeUnitId
                ? await buildLocationPath(entity.administrativeUnitId) // Fallback
                : undefined;

        return await this.toResponseDto(entity, deadline, locationPath);
    }
}

export const caseService = new CaseService();
