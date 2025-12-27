"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logAudit = logAudit;
exports.getAuditTrail = getAuditTrail;
exports.getAuditsByUser = getAuditsByUser;
exports.getAuditSummary = getAuditSummary;
/**
 * Audit Logger - Append-Only Implementation
 *
 * ⚠️ CRITICAL: No DELETE operations allowed. Ever.
 */
const prisma_service_1 = require("../../../libs/database/prisma.service");
const logger_service_1 = require("../../../libs/logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('audit-logger');
/**
 * Log an audit entry (APPEND-ONLY)
 */
async function logAudit(entry) {
    try {
        const record = await prisma_service_1.prisma.auditLog.create({
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
    }
    catch (error) {
        logger.error('Failed to log audit', { error, entry });
        throw error;
    }
}
/**
 * Get audit trail for an entity
 */
async function getAuditTrail(entityType, entityId, limit = 100) {
    return prisma_service_1.prisma.auditLog.findMany({
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
async function getAuditsByUser(userId, limit = 100) {
    return prisma_service_1.prisma.auditLog.findMany({
        where: { performedBy: userId },
        orderBy: { timestamp: 'desc' },
        take: limit,
    });
}
/**
 * Get system-wide audit summary
 */
async function getAuditSummary(startDate, endDate) {
    const logs = await prisma_service_1.prisma.auditLog.groupBy({
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
//# sourceMappingURL=audit-logger.js.map