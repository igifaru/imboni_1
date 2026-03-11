/**
 * Escalation Engine - Core Logic
 * 
 * CRITICAL: No leader can block or override system escalation
 */
import { AdministrativeLevel, CaseUrgency } from '@prisma/client';

export const ESCALATION_DEADLINES: Record<CaseUrgency, number> = {
    NORMAL: 48,      // 2 days
    HIGH: 24,        // 1 day  
    EMERGENCY: 4,    // 4 hours
};

export const ESCALATION_PATH: AdministrativeLevel[] = [
    'VILLAGE',
    'CELL',
    'SECTOR',
    'DISTRICT',
    'PROVINCE',
    'NATIONAL',
];

export function getNextLevel(current: AdministrativeLevel): AdministrativeLevel | null {
    const index = ESCALATION_PATH.indexOf(current);
    if (index === -1 || index === ESCALATION_PATH.length - 1) return null;
    return ESCALATION_PATH[index + 1];
}

export function calculateDeadline(urgency: CaseUrgency, start: Date = new Date()): Date {
    const hours = ESCALATION_DEADLINES[urgency];
    const deadline = new Date(start);
    deadline.setHours(deadline.getHours() + hours);
    return deadline;
}

export function shouldEscalate(deadline: Date): boolean {
    return new Date() >= deadline;
}
