/**
 * Institution DTOs
 */

export interface CreateInstitutionTypeDto {
    name: string;
    description?: string;
}

export interface CreateInstitutionDto {
    name: string;
    typeId: string;
    description?: string;
    email?: string;
    phone?: string;
    website?: string;
    hqLocation?: string;
}

export interface CreateBranchDto {
    institutionId: string;
    branchName: string;
    province: string;
    district: string;
    sector: string;
    address: string;
    managerId?: string;
}

export interface CreateServiceDto {
    institutionId: string;
    serviceName: string;
    description?: string;
    processingDays?: number;
}

export interface CreateRequestDto {
    institutionId: string;
    branchId: string;
    serviceId: string;
    title: string;
    description: string;
    priority?: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
}

export interface AssignStaffDto {
    userId: string;
    institutionId: string;
    branchId?: string;
    role: 'INSTITUTION_ADMIN' | 'BRANCH_MANAGER' | 'OFFICER';
}

export interface UpdateRequestStatusDto {
    status: 'RECEIVED' | 'UNDER_REVIEW' | 'INVESTIGATION' | 'RESOLVED' | 'ESCALATED' | 'REJECTED';
    notes?: string;
}
