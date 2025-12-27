export interface AuditEntry {
    entityType: string;
    entityId: string;
    action: string;
    performedBy?: string;
    oldValue?: object;
    newValue?: object;
    ipAddress?: string;
    userAgent?: string;
}
/**
 * Log an audit entry (APPEND-ONLY)
 */
export declare function logAudit(entry: AuditEntry): Promise<string>;
/**
 * Get audit trail for an entity
 */
export declare function getAuditTrail(entityType: string, entityId: string, limit?: number): Promise<({
    performer: {
        email: string | null;
        role: import(".prisma/client").$Enums.UserRole;
        id: string;
    } | null;
} & {
    timestamp: Date;
    id: string;
    entityType: string;
    entityId: string;
    action: string;
    oldValue: import("@prisma/client/runtime/library").JsonValue | null;
    newValue: import("@prisma/client/runtime/library").JsonValue | null;
    performedBy: string | null;
})[]>;
/**
 * Get all audits by a user
 */
export declare function getAuditsByUser(userId: string, limit?: number): Promise<{
    timestamp: Date;
    id: string;
    entityType: string;
    entityId: string;
    action: string;
    oldValue: import("@prisma/client/runtime/library").JsonValue | null;
    newValue: import("@prisma/client/runtime/library").JsonValue | null;
    performedBy: string | null;
}[]>;
/**
 * Get system-wide audit summary
 */
export declare function getAuditSummary(startDate: Date, endDate: Date): Promise<{
    action: string;
    count: number;
}[]>;
//# sourceMappingURL=audit-logger.d.ts.map