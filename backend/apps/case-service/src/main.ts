/**
 * Case Service - Main Entry Point
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '../../../libs/config/config.service';
import { createServiceLogger } from '../../../libs/logging/logger.service';
import { disconnectPrisma } from '../../../libs/database/prisma.service';
import { caseController } from './controllers/case.controller';

const logger = createServiceLogger('case-service');
const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'case-service',
        timestamp: new Date().toISOString(),
    });
});

// Routes
app.use('/cases', caseController);

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({
        error: 'Internal server error',
        message: config.isDevelopment ? err.message : undefined,
    });
});

// Start server
const PORT = config.ports.caseService;

app.listen(PORT, () => {
    logger.info(`📋 Case Service running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await disconnectPrisma();
    process.exit(0);
});

export default app;
