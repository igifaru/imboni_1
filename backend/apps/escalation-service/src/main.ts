/**
 * Escalation Service - Main Entry Point
 * 
 * Handles automatic, non-blockable escalation of cases
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '../../../libs/config/config.service';
import { createServiceLogger } from '../../../libs/logging/logger.service';
import { disconnectPrisma } from '../../../libs/database/prisma.service';
import { disconnectMessaging } from '../../../libs/messaging/messaging.service';
import { escalationScheduler } from './schedulers/escalation.scheduler';

const logger = createServiceLogger('escalation-service');
const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'escalation-service',
        schedulerActive: true,
        timestamp: new Date().toISOString(),
    });
});

// Manual trigger endpoint (for testing)
app.post('/trigger', async (req, res) => {
    if (!config.isDevelopment) {
        return res.status(403).json({ error: 'Only available in development' });
    }

    try {
        await escalationScheduler.checkAndEscalate();
        res.json({ success: true, message: 'Escalation check triggered' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to trigger escalation' });
    }
});

// Start server
const PORT = config.ports.escalationService;

app.listen(PORT, () => {
    logger.info(`⏰ Escalation Service running on port ${PORT}`);

    // Start the scheduler
    escalationScheduler.start();
    logger.info('Non-blockable escalation enforcement active');
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    escalationScheduler.stop();
    await disconnectMessaging();
    await disconnectPrisma();
    process.exit(0);
});

export default app;
