export type CaseCategory = 'JUSTICE' | 'HEALTH' | 'LAND' | 'INFRASTRUCTURE' | 'SECURITY' | 'SOCIAL' | 'EDUCATION' | 'OTHER';
export type CaseUrgency = 'NORMAL' | 'HIGH' | 'EMERGENCY';
export type CaseStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'ESCALATED' | 'CLOSED';
export type AdministrativeLevel = 'VILLAGE' | 'CELL' | 'SECTOR' | 'DISTRICT' | 'PROVINCE' | 'NATIONAL';
export interface CaseEntity {
    id: string;
    caseReference: string;
    category: CaseCategory;
    urgency: CaseUrgency;
    title: string;
    description: string;
    administrativeUnitId: string;
    currentLevel: AdministrativeLevel;
    status: CaseStatus;
    submittedAnonymously: boolean;
    submitterId: string | null;
    createdAt: Date;
    resolvedAt: Date | null;
}
/**
 * Generate unique case reference code
 * Format: IMB-XXXXXX-XX
 */
export declare function generateCaseReference(): string;
/**
 * Escalation path order
 */
export declare const ESCALATION_ORDER: AdministrativeLevel[];
/**
 * Get next escalation level
 */
export declare function getNextLevel(current: AdministrativeLevel): AdministrativeLevel | null;
/**
 * Check if case can be escalated
 */
export declare function canEscalate(status: CaseStatus, level: AdministrativeLevel): boolean;
//# sourceMappingURL=case.entity.d.ts.map