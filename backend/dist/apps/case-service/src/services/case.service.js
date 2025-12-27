"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.caseService = exports.CaseService = void 0;
/**
 * Case Service - Business Logic
 */
const case_repository_1 = require("../repositories/case.repository");
const messaging_service_1 = require("../../../../libs/messaging/messaging.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const config_service_1 = require("../../../../libs/config/config.service");
const logger = (0, logger_service_1.createServiceLogger)('case-service');
class CaseService {
    repository;
    constructor() {
        this.repository = case_repository_1.caseRepository;
    }
    /**
     * Create a new case
     */
    async createCase(dto, userId) {
        logger.info('Creating new case', { category: dto.category, anonymous: dto.submittedAnonymously });
        // Create the case
        const newCase = await this.repository.create(dto, userId);
        // Create initial assignment to village leader
        await this.createAssignment(newCase);
        // Publish event for other services
        await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_CREATED, {
            caseId: newCase.id,
            caseReference: newCase.caseReference,
            category: newCase.category,
            urgency: newCase.urgency,
        });
        // Log audit event
        await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.AUDIT_LOG, {
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
    async trackCase(caseReference) {
        const foundCase = await this.repository.findByReference(caseReference);
        if (!foundCase) {
            return null;
        }
        return this.toResponseDto(foundCase);
    }
    /**
     * Get case details
     */
    async getCaseById(id) {
        const foundCase = await this.repository.findById(id);
        if (!foundCase) {
            return null;
        }
        return this.toResponseDto(foundCase);
    }
    /**
     * Get cases assigned to leader
     */
    async getLeaderCases(leaderId, page = 1, limit = 20) {
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
    async updateCase(caseId, dto, userId) {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) {
            throw new Error('Case not found');
        }
        // Update status if provided
        if (dto.status) {
            await this.repository.updateStatus(caseId, dto.status);
            // Log the action
            await prisma_service_1.prisma.caseAction.create({
                data: {
                    caseId,
                    performedBy: userId,
                    actionType: 'STATUS_UPDATE',
                    notes: dto.notes || `Status changed to ${dto.status}`,
                },
            });
            // Publish event
            await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_UPDATED, {
                caseId,
                status: dto.status,
                updatedBy: userId,
            });
            // If resolved, mark assignment as complete
            if (dto.status === 'RESOLVED') {
                await this.completeAssignment(caseId);
                await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_RESOLVED, { caseId });
            }
        }
        const updatedCase = await this.repository.findById(caseId);
        return this.toResponseDto(updatedCase);
    }
    /**
     * Create assignment to leader of administrative unit
     */
    async createAssignment(caseData) {
        // Find the leader for the administrative unit
        const leader = await prisma_service_1.prisma.leaderAssignment.findFirst({
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
        await prisma_service_1.prisma.caseAssignment.create({
            data: {
                caseId: caseData.id,
                administrativeUnitId: caseData.administrativeUnitId,
                leaderId: leader.userId,
                deadlineAt,
                isActive: true,
            },
        });
        // Send notification to leader
        await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.NOTIFICATION_SEND, {
            userId: leader.userId,
            caseId: caseData.id,
            channel: 'PUSH',
            message: `New case assigned: ${caseData.title}`,
        });
    }
    /**
     * Complete active assignment
     */
    async completeAssignment(caseId) {
        await prisma_service_1.prisma.caseAssignment.updateMany({
            where: { caseId, isActive: true },
            data: { completedAt: new Date(), isActive: false },
        });
    }
    /**
     * Get deadline hours based on urgency
     */
    getDeadlineHours(urgency) {
        switch (urgency) {
            case 'EMERGENCY':
                return config_service_1.config.escalation.emergencyHours;
            case 'HIGH':
                return config_service_1.config.escalation.highHours;
            default:
                return config_service_1.config.escalation.normalHours;
        }
    }
    /**
     * Get escalation alerts for leader
     */
    async getEscalationAlerts(leaderId) {
        // Find active assignments with approaching deadlines (< 24 hours)
        const now = new Date();
        const tomorrow = new Date();
        tomorrow.setHours(tomorrow.getHours() + 24);
        const assignments = await prisma_service_1.prisma.caseAssignment.findMany({
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
        return assignments.map(a => this.toResponseDto(a.case));
    }
    /**
     * Get performance metrics for leader
     */
    async getPerformanceMetrics(leaderId) {
        // Get all assignments for this leader (active and inactive)
        const assignments = await prisma_service_1.prisma.caseAssignment.findMany({
            where: { leaderId },
            include: { case: true },
        });
        const total = assignments.length;
        if (total === 0) {
            return {
                totalCases: 0,
                resolvedCases: 0,
                pendingCases: 0,
                escalatedCases: 0,
                resolutionRate: 0,
                avgResponseTimeHours: 0,
                casesByCategory: {},
            };
        }
        let resolved = 0;
        let escalated = 0;
        const byCategory = {};
        for (const a of assignments) {
            const c = a.case;
            if (c.status === 'RESOLVED')
                resolved++;
            if (c.status === 'ESCALATED')
                escalated++;
            byCategory[c.category] = (byCategory[c.category] || 0) + 1;
        }
        return {
            totalCases: total,
            resolvedCases: resolved,
            pendingCases: total - resolved,
            escalatedCases: escalated,
            resolutionRate: Math.round((resolved / total) * 100),
            avgResponseTimeHours: 4.5, // Mock for now, would need action logs
            casesByCategory: byCategory,
        };
    }
    /**
     * Transform entity to response DTO
     */
    toResponseDto(entity) {
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
exports.CaseService = CaseService;
exports.caseService = new CaseService();
//# sourceMappingURL=case.service.js.map