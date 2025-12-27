export type AdministrativeLevel = 'VILLAGE' | 'CELL' | 'SECTOR' | 'DISTRICT' | 'PROVINCE' | 'NATIONAL';
export type CaseUrgency = 'NORMAL' | 'HIGH' | 'EMERGENCY';
/**
 * Escalation path following Rwanda's administrative hierarchy
 */
export declare const ESCALATION_PATH: AdministrativeLevel[];
/**
 * Deadline hours by urgency level
 */
export declare function getDeadlineHours(urgency: CaseUrgency): number;
/**
 * Get next level in escalation path
 * Returns null if already at NATIONAL level
 */
export declare function getNextEscalationLevel(current: AdministrativeLevel): AdministrativeLevel | null;
/**
 * Check if case is eligible for escalation
 */
export declare function isEligibleForEscalation(status: string, currentLevel: AdministrativeLevel): boolean;
/**
 * Check if deadline has expired
 */
export declare function isDeadlineExpired(deadline: Date, now?: Date): boolean;
/**
 * Calculate new deadline for escalated case
 */
export declare function calculateNewDeadline(urgency: CaseUrgency): Date;
/**
 * Emergency cases trigger parallel notifications to multiple levels
 */
export declare function getEmergencyNotificationLevels(): AdministrativeLevel[];
/**
 * Get level display name in Kinyarwanda
 */
export declare function getLevelDisplayName(level: AdministrativeLevel): string;
//# sourceMappingURL=escalation.rules.d.ts.map