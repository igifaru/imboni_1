/**
 * Escalation Engine - Core Logic
 *
 * CRITICAL: No leader can block or override system escalation
 */
import { AdministrativeLevel, CaseUrgency } from '@prisma/client';
export declare const ESCALATION_DEADLINES: Record<CaseUrgency, number>;
export declare const ESCALATION_PATH: AdministrativeLevel[];
export declare function getNextLevel(current: AdministrativeLevel): AdministrativeLevel | null;
export declare function calculateDeadline(urgency: CaseUrgency, start?: Date): Date;
export declare function shouldEscalate(deadline: Date): boolean;
//# sourceMappingURL=escalation-engine.d.ts.map