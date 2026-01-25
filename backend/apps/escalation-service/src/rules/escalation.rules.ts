/**
 * Escalation Rules - Non-Blockable Business Logic
 * 
 * CRITICAL: No leader can block or override system escalation
 */
import { config } from '../../../../libs/config/config.service';

export type AdministrativeLevel =
    | 'VILLAGE'
    | 'CELL'
    | 'SECTOR'
    | 'DISTRICT'
    | 'PROVINCE'
    | 'NATIONAL';

export type CaseUrgency = 'NORMAL' | 'HIGH' | 'EMERGENCY';

/**
 * Escalation path following Rwanda's administrative hierarchy
 */
export const ESCALATION_PATH: AdministrativeLevel[] = [
    'VILLAGE',   // Umudugudu
    'CELL',      // Akagari
    'SECTOR',    // Umurenge
    'DISTRICT',  // Akarere
    'PROVINCE',  // Intara
    'NATIONAL',  // National level / Presidential Cabinet
];

/**
 * Deadline hours by urgency level
 */
export function getDeadlineHours(urgency: CaseUrgency): number {
    switch (urgency) {
        case 'EMERGENCY':
            return config.escalation.emergencyHours;
        case 'HIGH':
            return config.escalation.highHours;
        case 'NORMAL':
        default:
            return config.escalation.normalHours;
    }
}

/**
 * Get next level in escalation path
 * Returns null if already at NATIONAL level
 */
export function getNextEscalationLevel(current: AdministrativeLevel): AdministrativeLevel | null {
    const currentIndex = ESCALATION_PATH.indexOf(current);

    if (currentIndex === -1) {
        throw new Error(`Invalid administrative level: ${current}`);
    }

    if (currentIndex >= ESCALATION_PATH.length - 1) {
        return null; // Already at national level
    }

    return ESCALATION_PATH[currentIndex + 1];
}

/**
 * Check if case is eligible for escalation
 */
export function isEligibleForEscalation(
    status: string,
    currentLevel: AdministrativeLevel
): boolean {
    // Cannot escalate resolved or closed cases
    if (status === 'RESOLVED' || status === 'CLOSED') {
        return false;
    }

    // Cannot escalate beyond national level
    if (currentLevel === 'NATIONAL') {
        return false;
    }

    return true;
}

/**
 * Check if deadline has expired
 */
export function isDeadlineExpired(deadline: Date, now: Date = new Date()): boolean {
    return now >= deadline;
}

/**
 * Calculate new deadline for escalated case
 */
export function calculateNewDeadline(urgency: CaseUrgency): Date {
    const hours = getDeadlineHours(urgency);
    const now = new Date();
    // Use getTime() + milliseconds to ensure decimal hours are handled correctly
    // 1 hour = 3,600,000 milliseconds
    const deadlineTime = now.getTime() + (hours * 3600000);
    return new Date(deadlineTime);
}

/**
 * Emergency cases trigger parallel notifications to multiple levels
 */
export function getEmergencyNotificationLevels(): AdministrativeLevel[] {
    return ['SECTOR', 'DISTRICT'];
}

/**
 * Get level display name in Kinyarwanda
 */
export function getLevelDisplayName(level: AdministrativeLevel): string {
    const names: Record<AdministrativeLevel, string> = {
        VILLAGE: 'Umudugudu',
        CELL: 'Akagari',
        SECTOR: 'Umurenge',
        DISTRICT: 'Akarere',
        PROVINCE: 'Intara',
        NATIONAL: 'Urwego rw\'Igihugu',
    };
    return names[level];
}
