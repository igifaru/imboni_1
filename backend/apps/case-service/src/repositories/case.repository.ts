/**
 * Case Repository - Database Operations
 */
import { prisma } from '../../../../libs/database/prisma.service';
import { CaseEntity, generateCaseReference, AdministrativeLevel } from '../entities/case.entity';
import { CreateCaseDto } from '../dto/case.dto';
import { config } from '../../../../libs/config/config.service';

export class CaseRepository {
    /**
     * Create a new case
     */
    async create(dto: CreateCaseDto, submitterId?: string): Promise<CaseEntity> {
        const caseReference = generateCaseReference();

        // Calculate deadline based on urgency
        const deadlineHours = this.getDeadlineHours(dto.urgency);
        const deadlineAt = new Date();
        deadlineAt.setHours(deadlineAt.getHours() + deadlineHours);

        const newCase = await prisma.case.create({
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

        return newCase as unknown as CaseEntity;
    }

    /**
     * Find case by ID
     */
    async findById(id: string): Promise<CaseEntity | null> {
        const result = await prisma.case.findUnique({
            where: { id },
            include: { evidence: true, administrativeUnit: true },
        });
        return result as unknown as CaseEntity | null;
    }

    /**
     * Find case by reference code (for tracking)
     */
    async findByReference(caseReference: string): Promise<CaseEntity | null> {
        const result = await prisma.case.findUnique({
            where: { caseReference },
            include: { evidence: true },
        });
        return result as unknown as CaseEntity | null;
    }

    /**
     * Find cases assigned to a leader
     */
    async findByLeader(leaderId: string, page = 1, limit = 20): Promise<{ cases: CaseEntity[]; total: number }> {
        const skip = (page - 1) * limit;

        const [cases, total] = await Promise.all([
            prisma.case.findMany({
                where: {
                    assignments: {
                        some: {
                            leaderId,
                            isActive: true,
                        },
                    },
                },
                include: { evidence: true },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            prisma.case.count({
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

        return { cases: cases as unknown as CaseEntity[], total };
    }

    /**
     * Find cases by administrative unit
     */
    async findByUnit(unitId: string, page = 1, limit = 20): Promise<{ cases: CaseEntity[]; total: number }> {
        const skip = (page - 1) * limit;

        const [cases, total] = await Promise.all([
            prisma.case.findMany({
                where: { administrativeUnitId: unitId },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
            }),
            prisma.case.count({
                where: { administrativeUnitId: unitId },
            }),
        ]);

        return { cases: cases as unknown as CaseEntity[], total };
    }

    /**
     * Update case status
     */
    async updateStatus(id: string, status: string): Promise<CaseEntity> {
        const result = await prisma.case.update({
            where: { id },
            data: {
                status: status as any,
                resolvedAt: status === 'RESOLVED' ? new Date() : undefined,
            },
        });
        return result as unknown as CaseEntity;
    }

    /**
     * Escalate case to next level
     */
    async escalate(id: string, newLevel: AdministrativeLevel): Promise<CaseEntity> {
        const result = await prisma.case.update({
            where: { id },
            data: {
                currentLevel: newLevel,
                status: 'ESCALATED',
            },
        });
        return result as unknown as CaseEntity;
    }

    /**
     * Find cases with expired deadlines (for escalation service)
     */
    async findExpiredDeadlines(): Promise<CaseEntity[]> {
        const now = new Date();

        const results = await prisma.case.findMany({
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

        return results as unknown as CaseEntity[];
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
     * Find all cases (for Admin)
     */
    async findAll(page = 1, limit = 50, search?: string): Promise<{ cases: CaseEntity[]; total: number }> {
        const skip = (page - 1) * limit;
        const where: any = {};

        if (search) {
            where.OR = [
                { caseReference: { contains: search, mode: 'insensitive' } },
                { title: { contains: search, mode: 'insensitive' } },
            ];
        }

        const [cases, total] = await Promise.all([
            prisma.case.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: { assignments: true }, // Include assignments for context
            }),
            prisma.case.count({ where }),
        ]);

        return { cases: cases as unknown as CaseEntity[], total };
    }

    /**
     * Get global statistics (for Admin Dashboard)
     */
    async getGlobalStats(): Promise<any> {
        const [total, active, urgent, escalated, byStatus, byUrgency] = await Promise.all([
            prisma.case.count(),
            prisma.case.count({ where: { status: { in: ['OPEN', 'IN_PROGRESS', 'ESCALATED'] } } }),
            prisma.case.count({ where: { urgency: { in: ['HIGH', 'EMERGENCY'] }, status: { not: 'RESOLVED' } } }),
            prisma.case.count({ where: { status: 'ESCALATED' } }),
            prisma.case.groupBy({
                by: ['status'],
                _count: { status: true },
            }),
            prisma.case.groupBy({
                by: ['urgency'],
                _count: { urgency: true },
            }),
        ]);

        return {
            total,
            active,
            urgent,
            escalated,
            byStatus: byStatus.reduce((acc, curr) => ({ ...acc, [curr.status]: curr._count.status }), {}),
            byUrgency: byUrgency.reduce((acc, curr) => ({ ...acc, [curr.urgency]: curr._count.urgency }), {}),
        };
    }
}

export const caseRepository = new CaseRepository();
