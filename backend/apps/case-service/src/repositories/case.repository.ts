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
        });
        return result as unknown as CaseEntity | null;
    }

    /**
     * Find case by reference code (for tracking)
     */
    async findByReference(caseReference: string): Promise<CaseEntity | null> {
        const result = await prisma.case.findUnique({
            where: { caseReference },
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
}

export const caseRepository = new CaseRepository();
