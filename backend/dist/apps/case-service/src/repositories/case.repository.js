"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.caseRepository = exports.CaseRepository = void 0;
/**
 * Case Repository - Database Operations
 */
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const case_entity_1 = require("../entities/case.entity");
const config_service_1 = require("../../../../libs/config/config.service");
class CaseRepository {
    /**
     * Create a new case
     */
    async create(dto, submitterId) {
        const caseReference = (0, case_entity_1.generateCaseReference)();
        // Calculate deadline based on urgency
        const deadlineHours = this.getDeadlineHours(dto.urgency);
        const deadlineAt = new Date();
        deadlineAt.setHours(deadlineAt.getHours() + deadlineHours);
        const newCase = await prisma_service_1.prisma.case.create({
            data: {
                caseReference,
                category: dto.category,
                urgency: dto.urgency,
                title: dto.title,
                description: dto.description,
                administrativeUnitId: dto.administrativeUnitId,
                currentLevel: 'VILLAGE', // Always starts at village level
                status: 'OPEN',
                submittedAnonymously: dto.submittedAnonymously,
                submitterId: dto.submittedAnonymously ? null : submitterId,
            },
        });
        return newCase;
    }
    /**
     * Find case by ID
     */
    async findById(id) {
        const result = await prisma_service_1.prisma.case.findUnique({
            where: { id },
        });
        return result;
    }
    /**
     * Find case by reference code (for tracking)
     */
    async findByReference(caseReference) {
        const result = await prisma_service_1.prisma.case.findUnique({
            where: { caseReference },
        });
        return result;
    }
    /**
     * Find cases assigned to a leader
     */
    async findByLeader(leaderId, page = 1, limit = 20) {
        const skip = (page - 1) * limit;
        const [cases, total] = await Promise.all([
            prisma_service_1.prisma.case.findMany({
                where: {
                    assignments: {
                        some: {
                            leaderId,
                            isActive: true,
                        },
                    },
                },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            prisma_service_1.prisma.case.count({
                where: {
                    assignments: {
                        some: {
                            leaderId,
                            isActive: true,
                        },
                    },
                },
            }),
        ]);
        return { cases: cases, total };
    }
    /**
     * Find cases by administrative unit
     */
    async findByUnit(unitId, page = 1, limit = 20) {
        const skip = (page - 1) * limit;
        const [cases, total] = await Promise.all([
            prisma_service_1.prisma.case.findMany({
                where: { administrativeUnitId: unitId },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            prisma_service_1.prisma.case.count({
                where: { administrativeUnitId: unitId },
            }),
        ]);
        return { cases: cases, total };
    }
    /**
     * Update case status
     */
    async updateStatus(id, status) {
        const result = await prisma_service_1.prisma.case.update({
            where: { id },
            data: {
                status: status,
                resolvedAt: status === 'RESOLVED' ? new Date() : undefined,
            },
        });
        return result;
    }
    /**
     * Escalate case to next level
     */
    async escalate(id, newLevel) {
        const result = await prisma_service_1.prisma.case.update({
            where: { id },
            data: {
                currentLevel: newLevel,
                status: 'ESCALATED',
            },
        });
        return result;
    }
    /**
     * Find cases with expired deadlines (for escalation service)
     */
    async findExpiredDeadlines() {
        const now = new Date();
        const results = await prisma_service_1.prisma.case.findMany({
            where: {
                status: { in: ['OPEN', 'IN_PROGRESS', 'ESCALATED'] },
                currentLevel: { not: 'NATIONAL' },
                assignments: {
                    some: {
                        isActive: true,
                        deadlineAt: { lte: now },
                        completedAt: null,
                    },
                },
            },
        });
        return results;
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
}
exports.CaseRepository = CaseRepository;
exports.caseRepository = new CaseRepository();
//# sourceMappingURL=case.repository.js.map