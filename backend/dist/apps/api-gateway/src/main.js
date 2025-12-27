"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
const jwt_middleware_1 = require("./auth/jwt.middleware");
const rate_limit_middleware_1 = require("./rate-limit/rate-limit.middleware");
const logger = (0, logger_service_1.createServiceLogger)('api-gateway');
const app = (0, express_1.default)();
// Security middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
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
// Case routes - some require auth, some don't
app.use('/api/cases/track', jwt_middleware_1.optionalAuthMiddleware); // Track by reference - no auth needed
app.use('/api/cases', jwt_middleware_1.optionalAuthMiddleware, rate_limit_middleware_1.emergencyBypass);
// Leader dashboard routes - require auth
app.use('/api/leader', jwt_middleware_1.authMiddleware);
// Admin routes - require auth and admin role
app.use('/api/admin', jwt_middleware_1.authMiddleware);
// Proxy to services (if running as gateway)
if (config_service_1.config.isProduction) {
    // Case service proxy
    app.use('/api/cases', (0, http_proxy_middleware_1.createProxyMiddleware)({
        target: `http://case-service:${config_service_1.config.ports.caseService}`,
        pathRewrite: { '^/api/cases': '/cases' },
        changeOrigin: true,
    }));
}
// For development - inline route handling
if (config_service_1.config.isDevelopment) {
    // Import and mount case routes directly in dev mode
    app.use('/api/cases', async (req, res, next) => {
        // Forward to case service
        const axios = await Promise.resolve().then(() => __importStar(require('axios')));
        try {
            const response = await axios.default({
                method: req.method,
                url: `http://localhost:${config_service_1.config.ports.caseService}/cases${req.path}`,
                data: req.body,
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: req.headers.authorization || '',
                },
                params: req.query,
            });
            res.status(response.status).json(response.data);
        }
        catch (error) {
            if (error.response) {
                res.status(error.response.status).json(error.response.data);
            }
            else {
                next(error);
            }
        }
    });
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