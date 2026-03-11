/**
 * Audit Service - Main Entry Point
 * 
 * Maintains immutable audit trail for all system operations.
 * ⚠️ No DELETE operations allowed.
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '@config/config.service';
import { createServiceLogger } from '@shared/helpers/logging/logger.service';
import { disconnectPrisma } from '@shared/database/prisma.service';
import { subscribeToChannel, CHANNELS, disconnectMessaging } from '../../../libs/messaging/messaging.service';
import { logAudit, getAuditTrail, getAuditsByUser, getAuditSummary } from './audit-logger';

const logger = createServiceLogger('audit-service');
const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

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
        const limit = parseInt(req.query.limit as string) || 100;

        const trail = await getAuditTrail(entityType, entityId, limit);
        res.json({ success: true, data: trail });
    } catch (error) {
        logger.error('Failed to get audit trail', error);
        res.status(500).json({ error: 'Failed to get audit trail' });
    }
});

// Get audits by user
app.get('/audit/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const limit = parseInt(req.query.limit as string) || 100;

        const audits = await getAuditsByUser(userId, limit);
        res.json({ success: true, data: audits });
    } catch (error) {
        logger.error('Failed to get user audits', error);
        res.status(500).json({ error: 'Failed to get user audits' });
    }
});

// Get audit summary
app.get('/audit/summary', async (req, res) => {
    try {
        const startDate = new Date(req.query.start as string || Date.now() - 30 * 24 * 60 * 60 * 1000);
        const endDate = new Date(req.query.end as string || Date.now());

        const summary = await getAuditSummary(startDate, endDate);
        res.json({ success: true, data: summary });
    } catch (error) {
        logger.error('Failed to get audit summary', error);
        res.status(500).json({ error: 'Failed to get audit summary' });
    }
});

// Subscribe to audit events
async function setupEventSubscription() {
    await subscribeToChannel(CHANNELS.AUDIT_LOG, async (data: any) => {
        try {
            await logAudit(data);
        } catch (error) {
            logger.error('Failed to process audit event', error);
        }
    });

    logger.info('Audit event subscription ready');
}

// Start server
const PORT = config.ports.auditService;

app.listen(PORT, async () => {
    logger.info(`📝 Audit Service running on port ${PORT}`);
    logger.info('   Maintaining immutable audit trail (no deletions allowed)');
    await setupEventSubscription();
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await disconnectMessaging();
    await disconnectPrisma();
    process.exit(0);
});

export default app;
