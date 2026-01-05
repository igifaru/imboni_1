/**
 * PFTCV Service - Main Entry Point
 * Public Fund Transparency & Citizen Verification
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '../../../libs/config/config.service';
import { createServiceLogger } from '../../../libs/logging/logger.service';
import { disconnectPrisma } from '../../../libs/database/prisma.service';
import { pftcvController } from './controllers/pftcv.controller';

const logger = createServiceLogger('pftcv-service');
const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'pftcv-service',
        timestamp: new Date().toISOString(),
    });
});

// Routes
app.use('/projects', pftcvController);

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({
        error: 'Internal server error',
        message: config.isDevelopment ? err.message : undefined,
    });
});

// Start server - Use port 3008 for pftcv
const PORT = process.env.PFTCV_PORT || 3008;

app.listen(PORT, () => {
    logger.info(`🏛️ PFTCV Service running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await disconnectPrisma();
    process.exit(0);
});

export default app;
