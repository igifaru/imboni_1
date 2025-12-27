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
    administrativeUnitId: z.string().cuid(),
    submittedAnonymously: z.boolean().default(false),
});

export const UpdateCaseSchema = z.object({
    status: z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'ESCALATED', 'CLOSED']).optional(),
    notes: z.string().max(2000).optional(),
});

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
    status: string;
    createdAt: string;
    resolvedAt: string | null;
    deadline: string | null;
    daysRemaining: number | null;
}

export interface CaseListResponseDto {
    cases: CaseResponseDto[];
    total: number;
    page: number;
    limit: number;
}
