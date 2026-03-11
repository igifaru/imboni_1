/**
 * Institution Repository - Database Operations for Institutional Modular System
 */
import { InstitutionRole, RequestStatus } from '@prisma/client';
import { prisma } from '../../../shared/database/prisma.service';
import {
    AssignStaffDto,
    CreateBranchDto,
    CreateInstitutionDto,
    CreateRequestDto,
    CreateServiceDto
} from '../dto/institution.dto';

export class InstitutionRepository {
    // Institution Types
    async createType(data: { name: string; description?: string }) {
        return prisma.institutionType.create({ data });
    }

    async findAllTypes() {
        return prisma.institutionType.findMany({
            orderBy: { name: 'asc' }
        });
    }

    // Institutions
    async createInstitution(dto: CreateInstitutionDto) {
        return prisma.institution.create({
            data: {
                ...dto,
                status: 'ACTIVE'
            }
        });
    }

    async findInstitutions(typeId?: string) {
        return prisma.institution.findMany({
            where: typeId ? { typeId } : {},
            include: { type: true, _count: { select: { branches: true } } },
            orderBy: { name: 'asc' }
        });
    }

    async findInstitutionById(id: string) {
        return prisma.institution.findUnique({
            where: { id },
            include: { type: true, branches: true, services: true }
        });
    }

    // Branches
    async createBranch(dto: CreateBranchDto) {
        return prisma.institutionBranch.create({
            data: { ...dto, status: 'ACTIVE' }
        });
    }

    async findBranches(institutionId: string) {
        return prisma.institutionBranch.findMany({
            where: { institutionId },
            orderBy: { branchName: 'asc' }
        });
    }

    // Staff
    async assignStaff(dto: AssignStaffDto) {
        return prisma.institutionStaff.create({
            data: dto
        });
    }

    async findStaff(institutionId: string, branchId?: string) {
        return prisma.institutionStaff.findMany({
            where: { institutionId, branchId },
            include: { user: { select: { name: true, email: true, phone: true } } }
        });
    }

    // Services
    async createService(dto: CreateServiceDto) {
        return prisma.institutionService.create({
            data: { ...dto, status: 'ACTIVE' }
        });
    }

    async findServices(institutionId: string) {
        return prisma.institutionService.findMany({
            where: { institutionId, status: 'ACTIVE' },
            orderBy: { serviceName: 'asc' }
        });
    }

    // Requests
    async createRequest(citizenId: string, dto: CreateRequestDto) {
        return prisma.institutionRequest.create({
            data: {
                ...dto,
                citizenId,
                status: 'SUBMITTED',
                priority: dto.priority || 'NORMAL'
            }
        });
    }

    async findRequests(filters: { citizenId?: string; institutionId?: string; branchId?: string; status?: RequestStatus }) {
        return prisma.institutionRequest.findMany({
            where: filters,
            include: {
                citizen: { select: { name: true, phone: true } },
                institution: { select: { name: true } },
                branch: { select: { branchName: true } },
                service: { select: { serviceName: true } }
            },
            orderBy: { createdAt: 'desc' }
        });
    }

    async findRequestById(id: string) {
        return prisma.institutionRequest.findUnique({
            where: { id },
            include: {
                citizen: { select: { name: true, phone: true, email: true } },
                institution: true,
                branch: true,
                service: true,
                escalations: true
            }
        });
    }

    async updateRequestStatus(id: string, status: RequestStatus, notes?: string) {
        return prisma.institutionRequest.update({
            where: { id },
            data: {
                status,
                resolvedAt: status === 'RESOLVED' ? new Date() : undefined
            }
        });
    }

    // Escalation
    async escalateRequest(requestId: string, fromRole: InstitutionRole, toRole: InstitutionRole, reason: string) {
        return prisma.$transaction(async (tx) => {
            await tx.requestEscalation.create({
                data: { requestId, fromRole, toRole, reason }
            });

            return tx.institutionRequest.update({
                where: { id: requestId },
                data: { status: 'ESCALATED' }
            });
        });
    }
}

export const institutionRepository = new InstitutionRepository();
