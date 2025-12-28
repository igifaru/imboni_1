/**
 * Case Service - Business Logic
 */
import { caseRepository, CaseRepository } from '../repositories/case.repository';
import { CreateCaseDto, UpdateCaseDto, CaseResponseDto } from '../dto/case.dto';
import { CaseEntity, getNextLevel, canEscalate } from '../entities/case.entity';
import { publishEvent, CHANNELS } from '../../../../libs/messaging/messaging.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { prisma } from '../../../../libs/database/prisma.service';
import { config } from '../../../../libs/config/config.service';

const logger = createServiceLogger('case-service');

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

        // Create the case
        const newCase = await this.repository.create(dto, userId);

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

        return this.toResponseDto(newCase);
    }

    /**
     * Track case by reference
     */
    async trackCase(caseReference: string): Promise<CaseResponseDto | null> {
        const foundCase = await this.repository.findByReference(caseReference);

        if (!foundCase) {
            return null;
        }

        return this.toResponseDto(foundCase);
    }

    /**
     * Get case details
     */
    async getCaseById(id: string): Promise<CaseResponseDto | null> {
        const foundCase = await this.repository.findById(id);

        if (!foundCase) {
            return null;
        }

        return this.toResponseDto(foundCase);
    }

    /**
     * Get cases assigned to leader
     */
    async getLeaderCases(leaderId: string, page = 1, limit = 20) {
        const result = await this.repository.findByLeader(leaderId, page, limit);

        return {
            cases: result.cases.map((c) => this.toResponseDto(c)),
            total: result.total,
            page,
            limit,
        };
    }

    /**
     * Update case status (for leaders)
     */
    async updateCase(caseId: string, dto: UpdateCaseDto, userId: string): Promise<CaseResponseDto> {
        const existingCase = await this.repository.findById(caseId);

        if (!existingCase) {
            throw new Error('Case not found');
        }

        // Update status if provided
        if (dto.status) {
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
            if (dto.status === 'RESOLVED') {
                await this.completeAssignment(caseId);
                await publishEvent(CHANNELS.CASE_RESOLVED, { caseId });
            }
        }

        const updatedCase = await this.repository.findById(caseId);
        return this.toResponseDto(updatedCase!);
    }

    /**
     * Create assignment to leader of administrative unit
     */
    private async createAssignment(caseData: CaseEntity): Promise<void> {
        // Find the leader for the administrative unit
        const leader = await prisma.leaderAssignment.findFirst({
            where: {
                administrativeUnitId: caseData.administrativeUnitId,
                isActive: true,
            },
        });

        if (!leader) {
            logger.warn('No leader found for unit', { unitId: caseData.administrativeUnitId });
            return;
        }

        // Calculate deadline
        const deadlineHours = this.getDeadlineHours(caseData.urgency);
        const deadlineAt = new Date();
        deadlineAt.setHours(deadlineAt.getHours() + deadlineHours);

        await prisma.caseAssignment.create({
            data: {
                caseId: caseData.id,
                administrativeUnitId: caseData.administrativeUnitId,
                leaderId: leader.userId,
                deadlineAt,
                isActive: true,
            },
        });

        // Send notification to leader
        await publishEvent(CHANNELS.NOTIFICATION_SEND, {
            userId: leader.userId,
            caseId: caseData.id,
            channel: 'PUSH',
            message: `New case assigned: ${caseData.title}`,
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
     * Get deadline hours based on urgency
     */
    private getDeadlineHours(urgency: string): number {
        switch (urgency) {
            case 'EMERGENCY':
                return config.escalation.emergencyHours;
            case 'HIGH':
                return config.escalation.highHours;
            default:
                return config.escalation.normalHours;
        }
    }

    /**
     * Get escalation alerts for leader
     */
    async getEscalationAlerts(leaderId: string): Promise<CaseResponseDto[]> {
        // Find active assignments with approaching deadlines (< 24 hours)
        const now = new Date();
        const tomorrow = new Date();
        tomorrow.setHours(tomorrow.getHours() + 24);

        const assignments = await prisma.caseAssignment.findMany({
            where: {
                leaderId,
                isActive: true,
                deadlineAt: {
                    lte: tomorrow, // Deadline is before tomorrow (so it's today or past due)
                },
            },
            include: {
                case: true,
            },
            orderBy: {
                deadlineAt: 'asc',
            },
        });

        return assignments.map(a => this.toResponseDto(a.case as unknown as CaseEntity));
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

        if (!leadership) {
            // Return empty structure if no leadership assignment found
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

        const myUnit = leadership.administrativeUnit;
        const subUnits = myUnit.children;
        const relevantUnitIds = [myUnit.id, ...subUnits.map(u => u.id)];

        // Build Where Clause
        const whereClause: any = {
            administrativeUnitId: { in: relevantUnitIds }
        };

        if (filters?.locationId && filters.locationId !== 'All Locations') {
            // If a specific location is selected, override the general scope
            // Assuming locationId is one of the valid unit IDs 
            // (In real app, we should verify specific location is within scope, but for now we trust the ID if it's in list)
            if (relevantUnitIds.includes(filters.locationId)) {
                whereClause.administrativeUnitId = filters.locationId;
            }
        }

        if (filters?.category && filters.category !== 'All Categories') {
            whereClause.category = filters.category;
        }

        if (filters?.startDate || filters?.endDate) {
            whereClause.createdAt = {};
            if (filters.startDate) whereClause.createdAt.gte = filters.startDate;
            if (filters.endDate) whereClause.createdAt.lte = filters.endDate;
        }

        // 2. Fetch all cases in this jurisdiction scope (My Unit + Direct Children) filtered
        const cases = await prisma.case.findMany({
            where: whereClause,
            include: {
                assignments: {
                    where: { isActive: true }
                }
            }
        });

        const total = cases.length;

        // Initialize trends
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

        // Initialize empty breakdown if no cases, but we should list units
        if (total === 0) {
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
                subUnitBreakdown: subUnits.map(u => ({
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
            return weeklyTrends.findIndex(t => t.date === dateString);
        };

        // Helper to calc single unit stats
        const calcUnitStats = (unitCases: typeof cases) => {
            let uResolved = 0;
            let uEscalated = 0;
            let uResponseTime = 0;
            let uTimeCount = 0;

            unitCases.forEach(c => {
                if (c.status === 'RESOLVED') {
                    uResolved++;
                    if (c.resolvedAt) {
                        const diff = (new Date(c.resolvedAt).getTime() - new Date(c.createdAt).getTime()) / 60000;
                        uResponseTime += diff;
                        uTimeCount++;
                    }
                }
                if (c.status === 'ESCALATED') uEscalated++;
            });

            return {
                total: unitCases.length,
                resolved: uResolved,
                escalated: uEscalated,
                resolutionRate: unitCases.length > 0 ? (uResolved / unitCases.length) * 100 : 0,
                escalationRate: unitCases.length > 0 ? (uEscalated / unitCases.length) * 100 : 0,
                avgTime: uTimeCount > 0 ? (uResponseTime / uTimeCount / 60) : 0
            };
        };

        // 3. Process Cases
        for (const c of cases) {
            // Global Stats
            if (c.status === 'RESOLVED') {
                resolved++;
                if (c.resolvedAt) {
                    const diffMins = (new Date(c.resolvedAt).getTime() - new Date(c.createdAt).getTime()) / 60000;
                    totalResponseTimeMinutes += diffMins;
                    casesWithResponseTime++;

                    const idx = getTrendIndex(new Date(c.resolvedAt));
                    if (idx !== -1) weeklyTrends[idx].resolvedCases++;
                }
            } else if (c.status === 'ESCALATED') {
                escalated++;
            }

            // Check Overdue (using active assignment deadline)
            if (c.status !== 'RESOLVED' && c.assignments.length > 0) {
                if (new Date(c.assignments[0].deadlineAt) < now) {
                    overdue++;
                }
            }

            byCategory[c.category] = (byCategory[c.category] || 0) + 1;

            const idx = getTrendIndex(new Date(c.createdAt));
            if (idx !== -1) weeklyTrends[idx].newCases++;
        }

        // Active cases trend
        weeklyTrends.forEach(t => {
            t.activeCases = Math.max(0, t.newCases - t.resolvedCases);
        });

        // 4. Build Regional Breakdown
        const subUnitBreakdown = subUnits.map(unit => {
            const unitCases = cases.filter(c => c.administrativeUnitId === unit.id);
            const stats = calcUnitStats(unitCases);

            // Determine status based on resolution rate
            let status = 'On Track';
            if (stats.resolutionRate < 50) status = 'Behind';
            else if (stats.resolutionRate < 80) status = 'At Risk';

            return {
                unitName: unit.name,
                totalCases: stats.total,
                resolutionRate: Math.round(stats.resolutionRate),
                avgResponseTimeHours: Number(stats.avgTime.toFixed(1)),
                escalationRate: Number(stats.escalationRate.toFixed(1)),
                status
            };
        });

        return {
            totalCases: total,
            resolvedCases: resolved,
            pendingCases: total - resolved,
            escalatedCases: escalated,
            resolutionRate: Math.round((resolved / total) * 100),
            avgResponseTimeHours: casesWithResponseTime > 0
                ? Number((totalResponseTimeMinutes / casesWithResponseTime / 60).toFixed(1))
                : 0,
            escalationRate: Number(((escalated / total) * 100).toFixed(1)),
            overdueCases: overdue,
            casesByCategory: byCategory,
            weeklyTrends,
            subUnitBreakdown
        };
    }

    /**
     * Transform entity to response DTO
     */
    private toResponseDto(entity: CaseEntity): CaseResponseDto {
        return {
            id: entity.id,
            caseReference: entity.caseReference,
            category: entity.category,
            urgency: entity.urgency,
            title: entity.title,
            description: entity.description,
            currentLevel: entity.currentLevel,
            status: entity.status,
            createdAt: entity.createdAt.toISOString(),
            resolvedAt: entity.resolvedAt?.toISOString() || null,
            deadline: null, // Will be populated from assignment
            daysRemaining: null,
        };
    }
}

export const caseService = new CaseService();
