"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Notification Service - Main Entry Point
 *
 * Handles multi-channel notifications (SMS, Email, Push)
 */
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const config_service_1 = require("../../../libs/config/config.service");
const logger_service_1 = require("../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../libs/database/prisma.service");
const messaging_service_1 = require("../../../libs/messaging/messaging.service");
const sms_handler_1 = require("./sms/sms.handler");
const email_handler_1 = require("./email/email.handler");
const push_handler_1 = require("./push/push.handler");
const logger = (0, logger_service_1.createServiceLogger)('notification-service');
const app = (0, express_1.default)();
// Middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'notification-service',
        timestamp: new Date().toISOString(),
    });
});
// Subscribe to notification events
async function setupEventSubscription() {
    await (0, messaging_service_1.subscribeToChannel)(messaging_service_1.CHANNELS.NOTIFICATION_SEND, async (data) => {
        logger.info('Received notification request', data);
        try {
            const { userId, caseId, channel, message } = data;
            // Get user contact info
            const user = await prisma_service_1.prisma.user.findUnique({
                where: { id: userId },
                select: { phone: true, email: true },
            });
            if (!user) {
                logger.warn('User not found for notification', { userId });
                return;
            }
            // Send via appropriate channel
            let sent = false;
            switch (channel) {
                case 'SMS':
                    if (user.phone) {
                        sent = await sms_handler_1.smsHandler.send({ to: user.phone, message });
                    }
                    break;
                case 'EMAIL':
                    if (user.email) {
                        sent = await email_handler_1.emailHandler.send({
                            to: user.email,
                            subject: 'Imboni Notification',
                            body: message,
                        });
                    }
                    break;
                case 'PUSH':
                    sent = await push_handler_1.pushHandler.send({
                        userId,
                        title: 'Imboni',
                        body: message,
                        data: caseId ? { caseId } : undefined,
                    });
                    break;
            }
            // Record notification in database
            await prisma_service_1.prisma.notification.create({
                data: {
                    userId,
                    caseId,
                    channel,
                    message,
                    sentAt: sent ? new Date() : null,
                },
            });
            logger.info('Notification processed', { userId, channel, sent });
        }
        catch (error) {
            logger.error('Failed to process notification', error);
        }
    });
    logger.info('Event subscription ready');
}
// Start server
const PORT = config_service_1.config.ports.notificationService;
app.listen(PORT, async () => {
    logger.info(`📨 Notification Service running on port ${PORT}`);
    await setupEventSubscription();
});
// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await (0, messaging_service_1.disconnectMessaging)();
    await (0, prisma_service_1.disconnectPrisma)();
    process.exit(0);
});
exports.default = app;
//# sourceMappingURL=main.js.map