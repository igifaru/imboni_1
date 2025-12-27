"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Case Service - Main Entry Point
 */
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const config_service_1 = require("../../../libs/config/config.service");
const logger_service_1 = require("../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../libs/database/prisma.service");
const case_controller_1 = require("./controllers/case.controller");
const logger = (0, logger_service_1.createServiceLogger)('case-service');
const app = (0, express_1.default)();
// Middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'case-service',
        timestamp: new Date().toISOString(),
    });
});
// Routes
app.use('/cases', case_controller_1.caseController);
// Error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({
        error: 'Internal server error',
        message: config_service_1.config.isDevelopment ? err.message : undefined,
    });
});
// Start server
const PORT = config_service_1.config.ports.caseService;
app.listen(PORT, () => {
    logger.info(`📋 Case Service running on port ${PORT}`);
});
// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await (0, prisma_service_1.disconnectPrisma)();
    process.exit(0);
});
exports.default = app;
//# sourceMappingURL=main.js.map