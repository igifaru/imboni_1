/**
 * Bank Service - Business Logic for Bank Module
 */
import { BankCaseStatus, PrismaClient } from '@prisma/client';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const prisma = new PrismaClient();
const logger = createServiceLogger('bank-service');

export class BankService {
    /**
     * Get all banks
     */
    async getAllBanks(includeInactive = false) {
        return prisma.bank.findMany({
            where: includeInactive ? {} : { status: 'ACTIVE' },
            include: {
                _count: {
                    select: { branches: true }
                }
            },
            orderBy: { bankName: 'asc' }
        });
    }

    /**
     * Get bank by ID with branches and services
     */
    async getBankById(id: string) {
        return prisma.bank.findUnique({
            where: { id },
            include: {
                branches: true,
                services: true
            }
        });
    }

    /**
     * Register a new bank
     */
    async createBank(data: {
        bankName: string;
        bankCode: string;
        headOfficeLocation: string;
        contactEmail?: string;
        contactPhone?: string;
    }) {
        return prisma.bank.create({
            data: {
                ...data,
                status: 'ACTIVE'
            }
        });
    }

    /**
     * Update bank info
     */
    async updateBank(id: string, data: any) {
        return prisma.bank.update({
            where: { id },
            data
        });
    }

    /**
     * Branch Management
     */
    async createBranch(bankId: string, data: {
        branchName: string;
        district: string;
        sector: string;
        address: string;
        contactPhone?: string;
    }) {
        return prisma.bankBranch.create({
            data: {
                ...data,
                bankId,
                status: 'ACTIVE'
            }
        });
    }

    async getBranchesByBank(bankId: string) {
        return prisma.bankBranch.findMany({
            where: { bankId },
            orderBy: { branchName: 'asc' }
        });
    }

    /**
     * Bank Services
     */
    async addService(bankId: string, data: {
        serviceName: string;
        description?: string;
    }) {
        return prisma.bankService.create({
            data: {
                ...data,
                bankId,
                enabled: true
            }
        });
    }

    async toggleService(serviceId: string, enabled: boolean) {
        return prisma.bankService.update({
            where: { id: serviceId },
            data: { enabled }
        });
    }

    /**
     * Bank Cases (Complaints)
     */
    async submitBankCase(data: {
        bankId: string;
        branchId: string;
        serviceId: string;
        submitterId: string;
        description: string;
        evidenceUrl?: string;
    }) {
        // Generate a unique reference: BANK-YYYYMMDD-XXXX
        const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const randomStr = Math.random().toString(36).substring(2, 6).toUpperCase();
        const reference = `BANK-${dateStr}-${randomStr}`;

        return prisma.bankCase.create({
            data: {
                ...data,
                caseReference: reference,
                status: 'RECEIVED'
            }
        });
    }

    async getCasesBySubmitter(submitterId: string) {
        return prisma.bankCase.findMany({
            where: { submitterId },
            include: {
                bank: true,
                branch: true,
                service: true
            },
            orderBy: { createdAt: 'desc' }
        });
    }

    async getCasesByBranch(branchId: string) {
        return prisma.bankCase.findMany({
            where: { branchId },
            include: {
                submitter: {
                    select: { name: true, phone: true }
                },
                service: true
            },
            orderBy: { createdAt: 'desc' }
        });
    }

    async updateCaseStatus(caseId: string, status: BankCaseStatus, performedBy: string, notes?: string) {
        return prisma.$transaction(async (tx) => {
            const updatedCase = await tx.bankCase.update({
                where: { id: caseId },
                data: { status }
            });

            await tx.bankCaseUpdate.create({
                data: {
                    caseId,
                    performedBy,
                    action: status,
                    notes
                }
            });

            return updatedCase;
        });
    }

    async getCaseDetails(caseId: string) {
        return prisma.bankCase.findUnique({
            where: { id: caseId },
            include: {
                bank: true,
                branch: true,
                service: true,
                submitter: {
                    select: { name: true, phone: true, email: true }
                },
                updates: {
                    include: {
                        performer: {
                            select: { name: true, role: true }
                        }
                    },
                    orderBy: { createdAt: 'asc' }
                }
            }
        });
    }
}

export const bankService = new BankService();
