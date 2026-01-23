/**
 * Case DTOs - Data Transfer Objects
 */
import { z } from 'zod';

// Validation schemas
export const CreateCaseSchema = z.object({
    category: z.enum([
        'JUSTICE', 'HEALTH', 'LAND', 'INFRASTRUCTURE',
        'SECURITY', 'SOCIAL', 'EDUCATION', 'OTHER'
    ]),
    urgency: z.enum(['NORMAL', 'HIGH', 'EMERGENCY']).default('NORMAL'),
    title: z.string().min(5).max(200),
    description: z.string().min(20).max(5000),
    // Accept either CUID (real unit ID) or location path string (Province_District_Sector_Cell_Village)
    administrativeUnitId: z.string().min(1),
    submittedAnonymously: z.boolean().default(false),
});

export const UpdateCaseSchema = z.object({
    status: z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'ESCALATED', 'CLOSED']).optional(),
    notes: z.string().max(2000).optional(),
});

// Citizen-specific update schema (for editing their own cases)
export const CitizenUpdateCaseSchema = z.object({
    title: z.string().min(5).max(200).optional(),
    description: z.string().min(20).max(5000).optional(),
    urgency: z.enum(['NORMAL', 'HIGH', 'EMERGENCY']).optional(),
});

export type CitizenUpdateCaseDto = z.infer<typeof CitizenUpdateCaseSchema>;

export const TrackCaseSchema = z.object({
    caseReference: z.string().regex(/^IMB-[A-Z0-9]{6}-[A-Z0-9]{2}$/),
});

// Types
export type CreateCaseDto = z.infer<typeof CreateCaseSchema>;
export type UpdateCaseDto = z.infer<typeof UpdateCaseSchema>;
export type TrackCaseDto = z.infer<typeof TrackCaseSchema>;

// Response DTOs
export interface CaseResponseDto {
    id: string;
    caseReference: string;
    category: string;
    urgency: string;
    title: string;
    description: string;
    currentLevel: string;
    locationName: string;
    locationPath?: string; // Full hierarchical path: "Province → District → Sector → Cell → Village"
    status: string;
    submittedAnonymously: boolean;
    citizenName: string | null;
    createdAt: string;
    resolvedAt: string | null;
    deadline: string | null;
    daysRemaining: number | null;
    evidence?: {
        id: string;
        type: string;
        purpose: string;
        description?: string;
        url: string;
        fileName: string;
    }[];
    administrativeUnitId?: string;
    assignedLeaderId?: string;
    assignedLeaderName?: string;
    assignedLeaderPhone?: string;
    extensionCount?: number;
    administrativeUnit?: {
        id: string;
        name: string;
        code: string;
        level: string;
    };
    resolution?: {
        notes: string;
        resolvedBy: string;
        evidence?: {
            id: string;
            url: string;
            fileName: string;
            type: string;
            mimeType: string;
        };
    };
}

export interface CaseListResponseDto {
    cases: CaseResponseDto[];
    total: number;
    page: number;
    limit: number;
}
