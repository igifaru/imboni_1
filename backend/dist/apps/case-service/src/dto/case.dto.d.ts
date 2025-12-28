/**
 * Case DTOs - Data Transfer Objects
 */
import { z } from 'zod';
export declare const CreateCaseSchema: z.ZodObject<{
    category: z.ZodEnum<["JUSTICE", "HEALTH", "LAND", "INFRASTRUCTURE", "SECURITY", "SOCIAL", "EDUCATION", "OTHER"]>;
    urgency: z.ZodDefault<z.ZodEnum<["NORMAL", "HIGH", "EMERGENCY"]>>;
    title: z.ZodString;
    description: z.ZodString;
    administrativeUnitId: z.ZodString;
    submittedAnonymously: z.ZodDefault<z.ZodBoolean>;
}, "strip", z.ZodTypeAny, {
    administrativeUnitId: string;
    category: "JUSTICE" | "HEALTH" | "LAND" | "INFRASTRUCTURE" | "SECURITY" | "SOCIAL" | "EDUCATION" | "OTHER";
    urgency: "EMERGENCY" | "NORMAL" | "HIGH";
    title: string;
    description: string;
    submittedAnonymously: boolean;
}, {
    administrativeUnitId: string;
    category: "JUSTICE" | "HEALTH" | "LAND" | "INFRASTRUCTURE" | "SECURITY" | "SOCIAL" | "EDUCATION" | "OTHER";
    title: string;
    description: string;
    urgency?: "EMERGENCY" | "NORMAL" | "HIGH" | undefined;
    submittedAnonymously?: boolean | undefined;
}>;
export declare const UpdateCaseSchema: z.ZodObject<{
    status: z.ZodOptional<z.ZodEnum<["OPEN", "IN_PROGRESS", "RESOLVED", "ESCALATED", "CLOSED"]>>;
    notes: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    status?: "OPEN" | "IN_PROGRESS" | "RESOLVED" | "ESCALATED" | "CLOSED" | undefined;
    notes?: string | undefined;
}, {
    status?: "OPEN" | "IN_PROGRESS" | "RESOLVED" | "ESCALATED" | "CLOSED" | undefined;
    notes?: string | undefined;
}>;
export declare const TrackCaseSchema: z.ZodObject<{
    caseReference: z.ZodString;
}, "strip", z.ZodTypeAny, {
    caseReference: string;
}, {
    caseReference: string;
}>;
export type CreateCaseDto = z.infer<typeof CreateCaseSchema>;
export type UpdateCaseDto = z.infer<typeof UpdateCaseSchema>;
export type TrackCaseDto = z.infer<typeof TrackCaseSchema>;
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
//# sourceMappingURL=case.dto.d.ts.map