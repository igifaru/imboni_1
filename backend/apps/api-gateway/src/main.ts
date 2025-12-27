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
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true,
}));
app.use(express.json({ limit: '10mb' }));

// General rate limiting
app.use(generalRateLimiter);

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
app.use('/api/cases', optionalAuthMiddleware, emergencyBypass);

// Leader dashboard routes - require auth
app.use('/api/leader', authMiddleware);

// Admin routes - require auth and admin role
app.use('/api/admin', authMiddleware);

// Proxy to services (if running as gateway)
if (config.isProduction) {
    // Case service proxy
    app.use('/api/cases', createProxyMiddleware({
        target: `http://case-service:${config.ports.caseService}`,
        pathRewrite: { '^/api/cases': '/cases' },
        changeOrigin: true,
    }));
}

// For development - inline route handling
if (config.isDevelopment) {
    // Import and mount case routes directly in dev mode
    app.use('/api/cases', async (req, res, next) => {
        // Forward to case service
        const axios = await import('axios');
        try {
            const response = await axios.default({
                method: req.method as any,
                url: `http://localhost:${config.ports.caseService}/cases${req.path}`,
                data: req.body,
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: req.headers.authorization || '',
                },
                params: req.query,
            });
            res.status(response.status).json(response.data);
        } catch (error: any) {
            if (error.response) {
                res.status(error.response.status).json(error.response.data);
            } else {
                next(error);
            }
        }
    });
}

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
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

// Start server
const PORT = config.ports.apiGateway;

app.listen(PORT, () => {
    logger.info(`🚀 API Gateway running on port ${PORT}`);
    logger.info(`   Environment: ${config.nodeEnv}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await disconnectPrisma();
    process.exit(0);
});

export default app;
