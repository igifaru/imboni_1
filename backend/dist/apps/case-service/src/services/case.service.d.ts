import { CreateCaseDto, UpdateCaseDto, CaseResponseDto } from '../dto/case.dto';
export declare class CaseService {
    private repository;
    constructor();
    /**
     * Create a new case
     */
    createCase(dto: CreateCaseDto, userId?: string): Promise<CaseResponseDto>;
    /**
     * Track case by reference
     */
    trackCase(caseReference: string): Promise<CaseResponseDto | null>;
    /**
     * Get case details
     */
    getCaseById(id: string): Promise<CaseResponseDto | null>;
    /**
     * Get cases assigned to leader
     */
    getLeaderCases(leaderId: string, page?: number, limit?: number): Promise<{
        cases: CaseResponseDto[];
        total: number;
        page: number;
        limit: number;
    }>;
    /**
     * Update case status (for leaders)
     */
    updateCase(caseId: string, dto: UpdateCaseDto, userId: string): Promise<CaseResponseDto>;
    /**
     * Create assignment to leader of administrative unit
     */
    private createAssignment;
    /**
     * Complete active assignment
     */
    private completeAssignment;
    /**
     * Get deadline hours based on urgency
     */
    private getDeadlineHours;
    /**
     * Get escalation alerts for leader
     */
    getEscalationAlerts(leaderId: string): Promise<CaseResponseDto[]>;
    /**
     * Get performance metrics for leader (Jurisdiction View)
     */
    getPerformanceMetrics(leaderId: string, filters?: {
        startDate?: Date;
        endDate?: Date;
        category?: string;
        locationId?: string;
    }): Promise<{
        totalCases: number;
        resolvedCases: number;
        pendingCases: number;
        escalatedCases: number;
        resolutionRate: number;
        avgResponseTimeHours: number;
        escalationRate: number;
        overdueCases: number;
        casesByCategory: Record<string, number>;
        weeklyTrends: {
            day: string;
            date: string;
            newCases: number;
            resolvedCases: number;
            activeCases: number;
        }[];
        subUnitBreakdown: {
            unitId: string;
            unitName: string;
            totalCases: number;
            resolutionRate: number;
            avgResponseTimeHours: number;
            escalationRate: number;
            status: string;
        }[];
    }>;
    /**
     * Transform entity to response DTO
     */
    private toResponseDto;
}
export declare const caseService: CaseService;
//# sourceMappingURL=case.service.d.ts.map