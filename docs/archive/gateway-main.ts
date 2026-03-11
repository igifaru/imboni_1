import { config } from '@config/config.service';
import { authRoutes } from '@core/auth/auth.routes';
import { authMiddleware, optionalAuthMiddleware } from '@core/auth/auth.middleware';
import { userRoutes } from '@core/users/user.routes';
import { caseController } from '@modules/governance/controllers/case.controller';
import { communityController } from '@modules/governance/controllers/community.controller';
import { pftcvController } from '@modules/governance/controllers/pftcv.controller';
import { escalationScheduler } from '@modules/governance/schedulers/escalation.scheduler';
import { institutionRoutes } from '@modules/institutions/routes/institution.routes';
import { disconnectPrisma } from '@shared/database/prisma.service';
import { createServiceLogger } from '@shared/helpers/logging/logger.service';
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { adminRoutes } from './admin/admin.routes';
import { authRateLimiter, emergencyBypass, generalRateLimiter } from './rate-limit/rate-limit.middleware';

const logger = createServiceLogger('api-gateway');
const app = express();

// Security middleware
app.use(helmet({
    crossOriginResourcePolicy: false,
    crossOriginEmbedderPolicy: false,
}));
app.use(cors({
    origin: true,
    credentials: true,
}));
app.use(express.json({ limit: '10mb' }));

// General rate limiting
app.use(generalRateLimiter);

// Serve static files (uploads)
import path from 'path';
app.use('/uploads', cors({ origin: '*' }), express.static(path.join(process.cwd(), 'uploads')));

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'api-gateway',
        timestamp: new Date().toISOString(),
    });
});

// Auth & User routes
app.use('/api/auth', authRateLimiter, authRoutes);
app.use('/api/user', authMiddleware, userRoutes);

// Governance routes
app.use('/api/cases/track', optionalAuthMiddleware);
app.use('/api/cases', optionalAuthMiddleware, (req, res, next) => {
    if (req.method === 'POST') return emergencyBypass(req, res, next);
    next();
}, caseController);

app.use('/api/leader', authMiddleware);
app.use('/api/community', authMiddleware, communityController);
app.use('/api/projects', optionalAuthMiddleware, pftcvController);

// Institutions routes (NEW)
app.use('/api/institutions', optionalAuthMiddleware, institutionRoutes);

// Admin routes
app.use('/api/admin', authMiddleware, adminRoutes);

// Proxy to services (if running as gateway)
if (config.isProduction) {
    app.use('/api/cases', createProxyMiddleware({
        target: `http://case-service:${config.ports.caseService}`,
        pathRewrite: { '^/api/cases': '/cases' },
        changeOrigin: true,
    }));
}

// Error handlers
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({
        error: 'Internal server error',
        message: config.isDevelopment ? err.message : undefined,
    });
});

app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// Start server
const PORT = config.ports.apiGateway;
app.listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 IMBONI Backend running on port ${PORT}`);
    logger.info(`   Modular Architecture: Enabled`);

    // Start background schedulers
    escalationScheduler.start();
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    escalationScheduler.stop();
    await disconnectPrisma();
    process.exit(0);
});

export default app;
