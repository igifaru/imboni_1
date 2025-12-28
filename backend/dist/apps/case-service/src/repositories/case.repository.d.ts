import { CaseEntity, AdministrativeLevel } from '../entities/case.entity';
import { CreateCaseDto } from '../dto/case.dto';
export declare class CaseRepository {
    /**
     * Create a new case
     */
    create(dto: CreateCaseDto, submitterId?: string): Promise<CaseEntity>;
    /**
     * Find case by ID
     */
    findById(id: string): Promise<CaseEntity | null>;
    /**
     * Find case by reference code (for tracking)
     */
    findByReference(caseReference: string): Promise<CaseEntity | null>;
    /**
     * Find cases assigned to a leader
     */
    findByLeader(leaderId: string, page?: number, limit?: number): Promise<{
        cases: CaseEntity[];
        total: number;
    }>;
    /**
     * Find cases by administrative unit
     */
    findByUnit(unitId: string, page?: number, limit?: number): Promise<{
        cases: CaseEntity[];
        total: number;
    }>;
    /**
     * Update case status
     */
    updateStatus(id: string, status: string): Promise<CaseEntity>;
    /**
     * Escalate case to next level
     */
    escalate(id: string, newLevel: AdministrativeLevel): Promise<CaseEntity>;
    /**
     * Find cases with expired deadlines (for escalation service)
     */
    findExpiredDeadlines(): Promise<CaseEntity[]>;
    /**
     * Get deadline hours based on urgency
     */
    private getDeadlineHours;
    /**
     * Find all cases (for Admin)
     */
    findAll(page?: number, limit?: number, search?: string): Promise<{
        cases: CaseEntity[];
        total: number;
    }>;
    /**
     * Get global statistics (for Admin Dashboard)
     */
    getGlobalStats(): Promise<any>;
}
export declare const caseRepository: CaseRepository;
//# sourceMappingURL=case.repository.d.ts.map