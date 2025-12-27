"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Audit Service - Main Entry Point
 *
 * Maintains immutable audit trail for all system operations.
 * ⚠️ No DELETE operations allowed.
 */
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const config_service_1 = require("../../../libs/config/config.service");
const logger_service_1 = require("../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../libs/database/prisma.service");
const messaging_service_1 = require("../../../libs/messaging/messaging.service");
const audit_logger_1 = require("./audit-logger");
const logger = (0, logger_service_1.createServiceLogger)('audit-service');
const app = (0, express_1.default)();
// Middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'audit-service',
        immutableLogs: true,
        timestamp: new Date().toISOString(),
    });
});
// Get audit trail for entity
app.get('/audit/:entityType/:entityId', async (req, res) => {
    try {
        const { entityType, entityId } = req.params;
        const limit = parseInt(req.query.limit) || 100;
        const trail = await (0, audit_logger_1.getAuditTrail)(entityType, entityId, limit);
        res.json({ success: true, data: trail });
    }
    catch (error) {
        logger.error('Failed to get audit trail', error);
        res.status(500).json({ error: 'Failed to get audit trail' });
    }
});
// Get audits by user
app.get('/audit/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const limit = parseInt(req.query.limit) || 100;
        const audits = await (0, audit_logger_1.getAuditsByUser)(userId, limit);
        res.json({ success: true, data: audits });
    }
    catch (error) {
        logger.error('Failed to get user audits', error);
        res.status(500).json({ error: 'Failed to get user audits' });
    }
});
// Get audit summary
app.get('/audit/summary', async (req, res) => {
    try {
        const startDate = new Date(req.query.start || Date.now() - 30 * 24 * 60 * 60 * 1000);
        const endDate = new Date(req.query.end || Date.now());
        const summary = await (0, audit_logger_1.getAuditSummary)(startDate, endDate);
        res.json({ success: true, data: summary });
    }
    catch (error) {
        logger.error('Failed to get audit summary', error);
        res.status(500).json({ error: 'Failed to get audit summary' });
    }
});
// Subscribe to audit events
async function setupEventSubscription() {
    await (0, messaging_service_1.subscribeToChannel)(messaging_service_1.CHANNELS.AUDIT_LOG, async (data) => {
        try {
            await (0, audit_logger_1.logAudit)(data);
        }
        catch (error) {
            logger.error('Failed to process audit event', error);
        }
    });
    logger.info('Audit event subscription ready');
}
// Start server
const PORT = config_service_1.config.ports.auditService;
app.listen(PORT, async () => {
    logger.info(`📝 Audit Service running on port ${PORT}`);
    logger.info('   Maintaining immutable audit trail (no deletions allowed)');
    await setupEventSubscription();
});
// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await (0, messaging_service_1.disconnectMessaging)();
    await (0, prisma_service_1.disconnectPrisma)();
    process.exit(0);
});
exports.default = app;
//# sourceMappingURL=main.js.map