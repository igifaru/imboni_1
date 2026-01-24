/**
 * API Gateway - Main Entry Point
 * 
 * Central entry point for all API requests.
 * Handles authentication, rate limiting, and route proxying.
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { config } from '../../../libs/config/config.service';
import { createServiceLogger } from '../../../libs/logging/logger.service';
import { disconnectPrisma } from '../../../libs/database/prisma.service';
import { authRoutes } from './auth/auth.routes';
import { userRoutes } from './user/user.routes';
import { authMiddleware, optionalAuthMiddleware } from './auth/jwt.middleware';
import { generalRateLimiter, authRateLimiter, emergencyBypass } from './rate-limit/rate-limit.middleware';

const logger = createServiceLogger('api-gateway');
const app = express();

// Security middleware
app.use(helmet({
    crossOriginResourcePolicy: false,
    crossOriginEmbedderPolicy: false,
}));
app.use(cors({
    origin: true, // Reflect request origin to support credentials with strict CORS
    credentials: true,
}));
app.use(express.json({ limit: '10mb' }));

// General rate limiting
app.use(generalRateLimiter);

// Serve static files (uploads)
import path from 'path';
app.use('/uploads', cors({ origin: '*' }), express.static(path.join(process.cwd(), 'uploads')));
app.use('/uploads/pftcv-evidence', cors({ origin: '*' }), express.static(path.join(process.cwd(), 'uploads/pftcv-evidence')));

// Health check (no auth)
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'api-gateway',
        timestamp: new Date().toISOString(),
    });
});

// Auth routes (with stricter rate limiting)
app.use('/api/auth', authRateLimiter, authRoutes);

// User routes (require auth)
app.use('/api/user', authMiddleware, userRoutes);

// Case routes - some require auth, some don't
app.use('/api/cases/track', optionalAuthMiddleware); // Track by reference - no auth needed
app.use('/api/cases', optionalAuthMiddleware);

// Applying rate limiting ONLY to case submission (POST)
// Read-only routes (Metrics, Track, Search) should not share the 5-cases-per-hour limit
import { caseController } from '../../case-service/src/controllers/case.controller';
app.use('/api/cases', (req, res, next) => {
    if (req.method === 'POST') {
        return emergencyBypass(req, res, next);
    }
    next();
}, caseController);

// Leader dashboard routes - require auth
app.use('/api/leader', authMiddleware);

// Admin routes - require auth
import { adminRoutes } from './admin/admin.routes';
app.use('/api/admin', authMiddleware, adminRoutes);

// Community routes - require auth
import { communityController } from '../../community-service/src/controllers/community.controller';
app.use('/api/community', authMiddleware, communityController);

// PFTCV routes - Public Fund Transparency & Citizen Verification
import { pftcvController } from '../../pftcv-service/src/controllers/pftcv.controller';
app.use('/api/projects', optionalAuthMiddleware, pftcvController);

// Proxy to services (if running as gateway) - only for production with separate microservices
if (config.isProduction) {
    // Case service proxy (override the inline mount above for true microservice mode if needed)
    app.use('/api/cases', createProxyMiddleware({
        target: `http://case-service:${config.ports.caseService}`,
        pathRewrite: { '^/api/cases': '/cases' },
        changeOrigin: true,
    }));
}

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({
        error: 'Internal server error',
        message: config.isDevelopment ? err.message : undefined,
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

// Escalation Scheduler
import { escalationScheduler } from '../../escalation-service/src/schedulers/escalation.scheduler';

// Start server
const PORT = config.ports.apiGateway;

app.listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 API Gateway running on port ${PORT}`);
    logger.info(`   Environment: ${config.nodeEnv}`);

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
