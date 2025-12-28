"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * API Gateway - Main Entry Point
 *
 * Central entry point for all API requests.
 * Handles authentication, rate limiting, and route proxying.
 */
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const http_proxy_middleware_1 = require("http-proxy-middleware");
const config_service_1 = require("../../../libs/config/config.service");
const logger_service_1 = require("../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../libs/database/prisma.service");
const auth_routes_1 = require("./auth/auth.routes");
const user_routes_1 = require("./user/user.routes");
const jwt_middleware_1 = require("./auth/jwt.middleware");
const rate_limit_middleware_1 = require("./rate-limit/rate-limit.middleware");
const logger = (0, logger_service_1.createServiceLogger)('api-gateway');
const app = (0, express_1.default)();
// Security middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: true, // Reflect request origin to support credentials with strict CORS
    credentials: true,
}));
app.use(express_1.default.json({ limit: '10mb' }));
// General rate limiting
app.use(rate_limit_middleware_1.generalRateLimiter);
// Health check (no auth)
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'api-gateway',
        timestamp: new Date().toISOString(),
    });
});
// Auth routes (with stricter rate limiting)
app.use('/api/auth', rate_limit_middleware_1.authRateLimiter, auth_routes_1.authRoutes);
// User routes (require auth)
app.use('/api/user', jwt_middleware_1.authMiddleware, user_routes_1.userRoutes);
// Case routes - some require auth, some don't
app.use('/api/cases/track', jwt_middleware_1.optionalAuthMiddleware); // Track by reference - no auth needed
app.use('/api/cases', jwt_middleware_1.optionalAuthMiddleware);
// Applying rate limiting ONLY to case submission (POST)
// Read-only routes (Metrics, Track, Search) should not share the 5-cases-per-hour limit
const case_controller_1 = require("../../case-service/src/controllers/case.controller");
app.use('/api/cases', (req, res, next) => {
    if (req.method === 'POST') {
        return (0, rate_limit_middleware_1.emergencyBypass)(req, res, next);
    }
    next();
}, case_controller_1.caseController);
// Leader dashboard routes - require auth
app.use('/api/leader', jwt_middleware_1.authMiddleware);
// Admin routes - require auth
const admin_routes_1 = require("./admin/admin.routes");
app.use('/api/admin', jwt_middleware_1.authMiddleware, admin_routes_1.adminRoutes);
// Proxy to services (if running as gateway) - only for production with separate microservices
if (config_service_1.config.isProduction) {
    // Case service proxy (override the inline mount above for true microservice mode if needed)
    app.use('/api/cases', (0, http_proxy_middleware_1.createProxyMiddleware)({
        target: `http://case-service:${config_service_1.config.ports.caseService}`,
        pathRewrite: { '^/api/cases': '/cases' },
        changeOrigin: true,
    }));
}
// Error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({
        error: 'Internal server error',
        message: config_service_1.config.isDevelopment ? err.message : undefined,
    });
});
// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});
// Start server
const PORT = config_service_1.config.ports.apiGateway;
app.listen(PORT, () => {
    logger.info(`🚀 API Gateway running on port ${PORT}`);
    logger.info(`   Environment: ${config_service_1.config.nodeEnv}`);
});
// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await (0, prisma_service_1.disconnectPrisma)();
    process.exit(0);
});
exports.default = app;
//# sourceMappingURL=main.js.map