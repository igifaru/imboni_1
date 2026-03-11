/**
 * Audit Logger - Append-Only Implementation
 * 
 * ⚠️ CRITICAL: No DELETE operations allowed. Ever.
 */
import { prisma } from '@shared/database/prisma.service';
import { createServiceLogger } from '@shared/helpers/logging/logger.service';

const logger = createServiceLogger('audit-logger');

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
export async function logAudit(entry: AuditEntry): Promise<string> {
    try {
        const record = await prisma.auditLog.create({
            data: {
                entityType: entry.entityType,
                entityId: entry.entityId,
                action: entry.action,
                performedBy: entry.performedBy,
                oldValue: entry.oldValue || undefined,
                newValue: entry.newValue || undefined,
            },
        });

        logger.debug('Audit logged', {
            entityType: entry.entityType,
            entityId: entry.entityId,
            action: entry.action,
        });

        return record.id;
    } catch (error) {
        logger.error('Failed to log audit', { error, entry });
        throw error;
    }
}

/**
 * Get audit trail for an entity
 */
export async function getAuditTrail(
    entityType: string,
    entityId: string,
    limit: number = 100
) {
    return prisma.auditLog.findMany({
        where: { entityType, entityId },
        orderBy: { timestamp: 'desc' },
        take: limit,
        include: {
            performer: {
                select: { id: true, role: true, email: true },
            },
        },
    });
}

/**
 * Get all audits by a user
 */
export async function getAuditsByUser(userId: string, limit: number = 100) {
    return prisma.auditLog.findMany({
        where: { performedBy: userId },
        orderBy: { timestamp: 'desc' },
        take: limit,
    });
}

/**
 * Get system-wide audit summary
 */
export async function getAuditSummary(startDate: Date, endDate: Date) {
    const logs = await prisma.auditLog.groupBy({
        by: ['action'],
        where: {
            timestamp: {
                gte: startDate,
                lte: endDate,
            },
        },
        _count: { action: true },
    });

    return logs.map((l) => ({
        action: l.action,
        count: l._count.action,
    }));
}
