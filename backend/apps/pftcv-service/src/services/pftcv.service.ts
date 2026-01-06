/**
 * PFTCV Service - Business Logic
 * Ref: Type definitions validated
 */
import { prisma } from '../../../../libs/database/prisma.service';
import { publishEvent, CHANNELS } from '../../../../libs/messaging/messaging.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { DeliveryStatus, RiskLevel } from '@prisma/client';

const logger = createServiceLogger('pftcv-service');

interface ProjectFilters {
    page: number;
    limit: number;
    sector?: string;
    status?: string;
    riskLevel?: string;
    locationId?: string;
    locationName?: string;
    locationLevel?: string;
    search?: string;
}

interface VerificationInput {
    projectId: string;
    verifierId: string | null;
    isAnonymous: boolean;
    deliveryStatus: DeliveryStatus;
    completionPercent: number;
    qualityRating?: number;
    comment?: string;
    gpsLatitude?: number;
    gpsLongitude?: number;
}

interface FundReleaseInput {
    projectId: string;
    amount: number;
    releaseDate: Date;
    releaseRef?: string;
    description?: string;
}

export class PftcvService {
    /**
     * Get projects with filters and pagination
     */
    async getProjects(filters: ProjectFilters) {
        const { page, limit, sector, status, riskLevel, locationId, search } = filters;
        const skip = (page - 1) * limit;

        const where: any = {};
        if (sector) where.sector = sector;
        if (status) where.status = status;
        if (riskLevel) where.riskLevel = riskLevel;
        if (locationId) {
            const descendantIds = await this.getDescendantUnitIds(locationId);
            where.administrativeUnitId = { in: descendantIds };
        } else if (filters.locationName && filters.locationLevel) {
            // Find unit by name and level
            const unit = await prisma.administrativeUnit.findFirst({
                where: {
                    name: { equals: filters.locationName, mode: 'insensitive' },
                    level: filters.locationLevel as any
                }
            });

            if (unit) {
                const descendantIds = await this.getDescendantUnitIds(unit.id);
                where.administrativeUnitId = { in: descendantIds };
            } else {
                where.administrativeUnitId = 'INVALID_LOC_ID';
            }
        }

        if (search) {
            where.OR = [
                { name: { contains: search, mode: 'insensitive' } },
                { projectCode: { contains: search, mode: 'insensitive' } },
                { description: { contains: search, mode: 'insensitive' } }
            ];
        }

        const [projects, total] = await Promise.all([
            prisma.project.findMany({
                where,
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    administrativeUnit: { select: { id: true, name: true, level: true } },
                    fundReleases: { select: { amount: true } },
                    _count: { select: { verifications: true } }
                }
            }),
            prisma.project.count({ where })
        ]);

        return {
            projects: projects.map((p: any) => ({
                ...p,
                totalReleased: p.fundReleases.reduce((sum: number, r: { amount: number }) => sum + r.amount, 0),
                verificationCount: p._count.verifications,
                fundReleases: undefined,
                _count: undefined
            })),
            total
        };
    }

    /**
     * Get single project with full details
     */
    async getProjectById(id: string) {
        const project = await prisma.project.findUnique({
            where: { id },
            include: {
                administrativeUnit: true,
                fundReleases: { orderBy: { releaseDate: 'desc' } },
                verifications: {
                    take: 10,
                    orderBy: { verifiedAt: 'desc' },
                    include: { evidence: true }
                }
            }
        });

        if (!project) return null;

        return {
            ...project,
            totalReleased: project.fundReleases.reduce((sum: number, r: { amount: number }) => sum + r.amount, 0),
            verificationCount: project.verifications.length
        };
    }

    /**
     * Submit citizen verification
     */
    async submitVerification(input: VerificationInput) {
        // Check for existing verification from same user (if not anonymous)
        if (input.verifierId) {
            const existing = await prisma.citizenVerification.findFirst({
                where: { projectId: input.projectId, verifierId: input.verifierId }
            });
            if (existing) throw new Error('Already verified');
        }

        const verification = await prisma.citizenVerification.create({
            data: {
                projectId: input.projectId,
                verifierId: input.verifierId,
                isAnonymous: input.isAnonymous,
                deliveryStatus: input.deliveryStatus,
                completionPercent: input.completionPercent,
                qualityRating: input.qualityRating,
                comment: input.comment,
                gpsLatitude: input.gpsLatitude,
                gpsLongitude: input.gpsLongitude
            }
        });

        // Update project risk score
        await this.updateProjectRisk(input.projectId);

        // Audit log
        await publishEvent(CHANNELS.AUDIT_LOG, {
            entityType: 'Project',
            entityId: input.projectId,
            action: 'CITIZEN_VERIFICATION',
            performedBy: input.verifierId || 'ANONYMOUS'
        });

        logger.info('Verification submitted', { projectId: input.projectId, status: input.deliveryStatus });
        return verification;
    }

    /**
     * Update citizen verification
     */
    async updateVerification(input: VerificationInput) {
        // Find existing verification
        const existing = await prisma.citizenVerification.findFirst({
            where: { projectId: input.projectId, verifierId: input.verifierId! }
        });

        if (!existing) throw new Error('Verification not found');

        const verification = await prisma.citizenVerification.update({
            where: { id: existing.id },
            data: {
                isAnonymous: input.isAnonymous,
                deliveryStatus: input.deliveryStatus,
                completionPercent: input.completionPercent,
                qualityRating: input.qualityRating,
                comment: input.comment,
                gpsLatitude: input.gpsLatitude,
                gpsLongitude: input.gpsLongitude,
                verifiedAt: new Date() // Update timestamp
            }
        });

        // Update project risk score
        await this.updateProjectRisk(input.projectId);

        logger.info('Verification updated', { projectId: input.projectId, status: input.deliveryStatus });
        return verification;
    }

    /**
     * Get verifications for a project
     */
    async getProjectVerifications(projectId: string) {
        return prisma.citizenVerification.findMany({
            where: { projectId },
            orderBy: { verifiedAt: 'desc' },
            include: { evidence: true }
        });
    }

    /**
     * Update project risk score based on verifications
     */
    async updateProjectRisk(projectId: string) {
        const verifications = await prisma.citizenVerification.findMany({
            where: { projectId }
        });

        if (verifications.length === 0) return;

        // Calculate risk score
        let riskScore = 0;
        let totalPercent = 0;

        for (const v of verifications) {
            totalPercent += v.completionPercent;

            // Add to risk if not delivered or partial
            if (v.deliveryStatus === 'NOT_DELIVERED') riskScore += 30;
            else if (v.deliveryStatus === 'PARTIALLY_DELIVERED') riskScore += 15;
            else if (v.deliveryStatus === 'NOT_STARTED') riskScore += 25;
        }

        // Normalize risk score (0-100)
        riskScore = Math.min(100, Math.round(riskScore / verifications.length));
        const verifiedPercentage = Math.round(totalPercent / verifications.length);

        // Determine risk level
        let riskLevel: RiskLevel = 'NORMAL';
        if (riskScore >= 50) riskLevel = 'HIGH_RISK';
        else if (riskScore >= 25) riskLevel = 'NEEDS_REVIEW';

        await prisma.project.update({
            where: { id: projectId },
            data: { riskScore, riskLevel, verifiedPercentage }
        });

        // Auto-escalate if high risk
        if (riskLevel === 'HIGH_RISK') {
            await this.triggerEscalation(projectId, riskScore);
        }

        logger.info('Project risk updated', { projectId, riskScore, riskLevel });
    }

    /**
     * Trigger escalation for high-risk project
     */
    private async triggerEscalation(projectId: string, riskScore: number) {
        const project = await prisma.project.findUnique({
            where: { id: projectId },
            include: { administrativeUnit: true }
        });

        if (!project) return;

        // Notify relevant authorities
        await publishEvent(CHANNELS.NOTIFICATION_SEND, {
            type: 'HIGH_RISK_PROJECT',
            projectId,
            projectName: project.name,
            riskScore,
            location: project.administrativeUnit?.name
        });

        // Audit log
        await publishEvent(CHANNELS.AUDIT_LOG, {
            entityType: 'Project',
            entityId: projectId,
            action: 'RISK_ESCALATION',
            performedBy: 'SYSTEM',
            newValue: { riskScore, riskLevel: 'HIGH_RISK' }
        });

        logger.warn('High-risk project escalated', { projectId, riskScore });
    }

    /**
     * Get dashboard statistics
     */
    async getStats(locationId?: string, locationName?: string, locationLevel?: string) {
        const where: any = {};

        if (locationId) {
            const descendantIds = await this.getDescendantUnitIds(locationId);
            where.administrativeUnitId = { in: descendantIds };
        } else if (locationName && locationLevel) {
            // Find unit by name and level
            const unit = await prisma.administrativeUnit.findFirst({
                where: {
                    name: { equals: locationName, mode: 'insensitive' },
                    level: locationLevel as any
                }
            });

            if (unit) {
                const descendantIds = await this.getDescendantUnitIds(unit.id);
                where.administrativeUnitId = { in: descendantIds };
            } else {
                where.administrativeUnitId = 'INVALID_LOC_ID';
            }
        }

        const [totalProjects, byStatus, byRisk, bySector, recentVerifications] = await Promise.all([
            prisma.project.count({ where }),
            prisma.project.groupBy({ by: ['status'], where, _count: true }),
            prisma.project.groupBy({ by: ['riskLevel'], where, _count: true }),
            prisma.project.groupBy({ by: ['sector'], where, _sum: { approvedBudget: true } }),
            prisma.citizenVerification.count({ where: { project: where } })
        ]);

        const totalBudget = await prisma.project.aggregate({ where, _sum: { approvedBudget: true } });
        const totalReleased = await prisma.fundRelease.aggregate({
            where: { project: where },
            _sum: { amount: true }
        });

        return {
            totalProjects,
            totalBudget: totalBudget._sum.approvedBudget || 0,
            totalReleased: totalReleased._sum.amount || 0,
            totalVerifications: recentVerifications,
            byStatus: byStatus.map((s: any) => ({ status: s.status, count: s._count })),
            byRisk: byRisk.map((r: any) => ({ riskLevel: r.riskLevel, count: r._count })),
            bySector: bySector.map((s: any) => ({ sector: s.sector, budget: s._sum.approvedBudget || 0 }))
        };
    }

    /**
     * Create a new project
     */
    async createProject(data: any) {
        const projectCode = `PRJ-${Date.now().toString(36).toUpperCase()}`;

        const project = await prisma.project.create({
            data: {
                projectCode,
                name: data.name,
                sector: data.sector,
                description: data.description,
                administrativeUnitId: data.administrativeUnitId,
                gpsLatitude: data.gpsLatitude,
                gpsLongitude: data.gpsLongitude,
                approvedBudget: data.approvedBudget,
                fundingSource: data.fundingSource,
                implementingAgency: data.implementingAgency,
                expectedOutputs: data.expectedOutputs,
                startDate: data.startDate ? new Date(data.startDate) : undefined,
                endDate: data.endDate ? new Date(data.endDate) : undefined,
                status: data.status || 'PLANNED'
            }
        });

        logger.info('Project created', { projectCode });
        return project;
    }

    /**
     * Add fund release to project
     */
    async addFundRelease(data: FundReleaseInput) {
        const release = await prisma.fundRelease.create({
            data: {
                projectId: data.projectId,
                amount: data.amount,
                releaseDate: data.releaseDate,
                releaseRef: data.releaseRef,
                description: data.description
            }
        });

        return release;
    }

    /**
     * Helper to get all descendant unit IDs (recursive)
     */
    private async getDescendantUnitIds(unitId: string): Promise<string[]> {
        // BFS or simple recursion
        const children = await prisma.administrativeUnit.findMany({
            where: { parentId: unitId },
            select: { id: true }
        });

        let ids = [unitId];
        for (const child of children) {
            const subIds = await this.getDescendantUnitIds(child.id);
            ids = [...ids, ...subIds];
        }
        return ids;
    }
}

export const pftcvService = new PftcvService();
