/**
 * Institution Service - Business Logic for the Institutional Modular System
 */
import { InstitutionRole, RequestStatus } from '@prisma/client';
import { createServiceLogger } from '../../../shared/helpers/logging/logger.service';
import {
    AssignStaffDto,
    CreateBranchDto,
    CreateInstitutionDto,
    CreateRequestDto,
    CreateServiceDto
} from '../dto/institution.dto';
import { institutionRepository } from '../repositories/institution.repository';

const logger = createServiceLogger('institution-service');

export class InstitutionService {
    // Management
    async registerInstitutionType(name: string, description?: string) {
        logger.info('Registering institution type', { name });
        return institutionRepository.createType({ name, description });
    }

    async getInstitutionTypes() {
        return institutionRepository.findAllTypes();
    }

    async registerInstitution(dto: CreateInstitutionDto) {
        logger.info('Registering institution', { name: dto.name });
        return institutionRepository.createInstitution(dto);
    }

    async getInstitutions(typeId?: string) {
        return institutionRepository.findInstitutions(typeId);
    }

    async getInstitutionDetails(id: string) {
        return institutionRepository.findInstitutionById(id);
    }

    // Branch & Services
    async addBranch(dto: CreateBranchDto) {
        return institutionRepository.createBranch(dto);
    }

    async getBranches(institutionId: string) {
        return institutionRepository.findBranches(institutionId);
    }

    async addService(dto: CreateServiceDto) {
        return institutionRepository.createService(dto);
    }

    async getServices(institutionId: string) {
        return institutionRepository.findServices(institutionId);
    }

    // Staff
    async assignStaffMember(dto: AssignStaffDto) {
        return institutionRepository.assignStaff(dto);
    }

    // Requests
    async submitRequest(citizenId: string, dto: CreateRequestDto) {
        logger.info('Citizen submitting institution request', { citizenId, institutionId: dto.institutionId });
        return institutionRepository.createRequest(citizenId, dto);
    }

    async getCitizenRequests(citizenId: string) {
        return institutionRepository.findRequests({ citizenId });
    }

    async getBranchRequests(branchId: string) {
        return institutionRepository.findRequests({ branchId });
    }

    async updateRequestStatus(id: string, status: RequestStatus, notes?: string) {
        logger.info('Updating request status', { requestId: id, status });
        return institutionRepository.updateRequestStatus(id, status, notes);
    }

    async escalateRequest(requestId: string, fromRole: InstitutionRole, toRole: InstitutionRole, reason: string) {
        logger.info('Escalating request', { requestId, fromRole, toRole });
        return institutionRepository.escalateRequest(requestId, fromRole, toRole, reason);
    }
}

export const institutionService = new InstitutionService();
