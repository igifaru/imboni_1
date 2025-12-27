"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Escalation Service - Main Entry Point
 *
 * Handles automatic, non-blockable escalation of cases
 */
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const config_service_1 = require("../../../libs/config/config.service");
const logger_service_1 = require("../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../libs/database/prisma.service");
const messaging_service_1 = require("../../../libs/messaging/messaging.service");
const escalation_scheduler_1 = require("./schedulers/escalation.scheduler");
const logger = (0, logger_service_1.createServiceLogger)('escalation-service');
const app = (0, express_1.default)();
// Middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)());
app.use(express_1.default.json());
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
    if (!config_service_1.config.isDevelopment) {
        return res.status(403).json({ error: 'Only available in development' });
    }
    try {
        await escalation_scheduler_1.escalationScheduler.checkAndEscalate();
        res.json({ success: true, message: 'Escalation check triggered' });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to trigger escalation' });
    }
});
// Start server
const PORT = config_service_1.config.ports.escalationService;
app.listen(PORT, () => {
    logger.info(`⏰ Escalation Service running on port ${PORT}`);
    // Start the scheduler
    escalation_scheduler_1.escalationScheduler.start();
    logger.info('Non-blockable escalation enforcement active');
});
// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    escalation_scheduler_1.escalationScheduler.stop();
    await (0, messaging_service_1.disconnectMessaging)();
    await (0, prisma_service_1.disconnectPrisma)();
    process.exit(0);
});
exports.default = app;
//# sourceMappingURL=main.js.map