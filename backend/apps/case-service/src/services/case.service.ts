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
     * Get performance metrics for leader
     */
    async getPerformanceMetrics(leaderId: string) {
        // Get all assignments for this leader
        const assignments = await prisma.caseAssignment.findMany({
            where: { leaderId },
            include: { case: true },
        });

        const total = assignments.length;

        // Initialize weekly trends (last 7 days)
        const weeklyTrends = Array(7).fill(0).map((_, i) => {
            const d = new Date();
            d.setDate(d.getDate() - (6 - i)); // 6 days ago to today
            return {
                day: d.toLocaleDateString('en-US', { weekday: 'short' }),
                date: d.toISOString().split('T')[0],
                newCases: 0,
                resolvedCases: 0,
                activeCases: 0
            };
        });

        if (total === 0) {
            return {
                totalCases: 0,
                resolvedCases: 0,
                pendingCases: 0,
                escalatedCases: 0,
                resolutionRate: 0,
                avgResponseTimeHours: 0,
                casesByCategory: {},
                weeklyTrends, // Return empty trends structure
            };
        }

        let resolved = 0;
        let escalated = 0;
        let totalResponseTimeMinutes = 0;
        let casesWithResponseTime = 0;
        const byCategory: Record<string, number> = {};

        // Helper to find trend index by date
        const getTrendIndex = (date: Date) => {
            const dateString = date.toISOString().split('T')[0];
            return weeklyTrends.findIndex(t => t.date === dateString);
        };

        for (const a of assignments) {
            const c = a.case as unknown as CaseEntity;

            // Count status
            if (c.status === 'RESOLVED') {
                resolved++;
                // Calculate response time if resolved
                if (c.resolvedAt) {
                    const created = new Date(c.createdAt);
                    const res = new Date(c.resolvedAt);
                    const diffMins = (res.getTime() - created.getTime()) / (1000 * 60);
                    totalResponseTimeMinutes += diffMins;
                    casesWithResponseTime++;
                }

                // Add to weekly trends (resolved count)
                if (c.resolvedAt) {
                    const idx = getTrendIndex(new Date(c.resolvedAt));
                    if (idx !== -1) weeklyTrends[idx].resolvedCases++;
                }
            }
            if (c.status === 'ESCALATED') escalated++;

            // Count category
            byCategory[c.category] = (byCategory[c.category] || 0) + 1;

            // Add to weekly trends (new cases count)
            const idx = getTrendIndex(new Date(c.createdAt));
            if (idx !== -1) weeklyTrends[idx].newCases++;
        }

        // Calculate active cases for each day (cumulative logic could be improved, but simple diff is okay for now)
        // For this simple version, activeCases will just be new - resolved for that day
        weeklyTrends.forEach(t => {
            t.activeCases = Math.max(0, t.newCases - t.resolvedCases);
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
            casesByCategory: byCategory,
            weeklyTrends,
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
