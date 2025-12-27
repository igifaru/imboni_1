"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TrackCaseSchema = exports.UpdateCaseSchema = exports.CreateCaseSchema = void 0;
/**
 * Case DTOs - Data Transfer Objects
 */
const zod_1 = require("zod");
// Validation schemas
exports.CreateCaseSchema = zod_1.z.object({
    category: zod_1.z.enum([
        'JUSTICE', 'HEALTH', 'LAND', 'INFRASTRUCTURE',
        'SECURITY', 'SOCIAL', 'EDUCATION', 'OTHER'
    ]),
    urgency: zod_1.z.enum(['NORMAL', 'HIGH', 'EMERGENCY']).default('NORMAL'),
    title: zod_1.z.string().min(5).max(200),
    description: zod_1.z.string().min(20).max(5000),
    administrativeUnitId: zod_1.z.string().cuid(),
    submittedAnonymously: zod_1.z.boolean().default(false),
});
exports.UpdateCaseSchema = zod_1.z.object({
    status: zod_1.z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'ESCALATED', 'CLOSED']).optional(),
    notes: zod_1.z.string().max(2000).optional(),
});
exports.TrackCaseSchema = zod_1.z.object({
    caseReference: zod_1.z.string().regex(/^IMB-[A-Z0-9]{6}-[A-Z0-9]{2}$/),
});
//# sourceMappingURL=case.dto.js.map