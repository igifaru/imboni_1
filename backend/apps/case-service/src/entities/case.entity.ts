/**
 * Case Entity - Domain Model
 */
import { v4 as uuidv4 } from 'uuid';

export type CaseCategory =
    | 'JUSTICE'
    | 'HEALTH'
    | 'LAND'
    | 'INFRASTRUCTURE'
    | 'SECURITY'
    | 'SOCIAL'
    | 'EDUCATION'
    | 'OTHER';

export type CaseUrgency = 'NORMAL' | 'HIGH' | 'EMERGENCY';

export type CaseStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'ESCALATED' | 'CLOSED';

export type AdministrativeLevel =
    | 'VILLAGE'
    | 'CELL'
    | 'SECTOR'
    | 'DISTRICT'
    | 'PROVINCE'
    | 'NATIONAL';

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
    evidence?: EvidenceEntity[];
    administrativeUnit?: { id: string; name: string };
}

export interface EvidenceEntity {
    id: string;
    caseId: string;
    type: 'IMAGE' | 'VIDEO' | 'AUDIO' | 'DOCUMENT';
    url: string;
    fileName: string;
    fileSize: number;
    mimeType: string;
    createdAt: Date;
}

/**
 * Generate unique case reference code
 * Format: IMB-XXXXXX-XX
 */
export function generateCaseReference(): string {
    const timestamp = Date.now().toString(36).toUpperCase().slice(-6);
    const random = Math.random().toString(36).substring(2, 4).toUpperCase();
    return `IMB-${timestamp}-${random}`;
}

/**
 * Escalation path order
 */
export const ESCALATION_ORDER: AdministrativeLevel[] = [
    'VILLAGE',
    'CELL',
    'SECTOR',
    'DISTRICT',
    'PROVINCE',
    'NATIONAL',
];

/**
 * Get next escalation level
 */
export function getNextLevel(current: AdministrativeLevel): AdministrativeLevel | null {
    const index = ESCALATION_ORDER.indexOf(current);
    if (index === -1 || index >= ESCALATION_ORDER.length - 1) {
        return null;
    }
    return ESCALATION_ORDER[index + 1];
}

/**
 * Check if case can be escalated
 */
export function canEscalate(status: CaseStatus, level: AdministrativeLevel): boolean {
    return (
        status !== 'RESOLVED' &&
        status !== 'CLOSED' &&
        level !== 'NATIONAL'
    );
}
