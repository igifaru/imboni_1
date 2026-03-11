/**
 * Notification Service - Main Entry Point
 * 
 * Handles multi-channel notifications (SMS, Email, Push)
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '@config/config.service';
import { createServiceLogger } from '@shared/helpers/logging/logger.service';
import { prisma, disconnectPrisma } from '@shared/database/prisma.service';
import { subscribeToChannel, CHANNELS, disconnectMessaging } from '../../../libs/messaging/messaging.service';
import { smsHandler } from './sms/sms.handler';
import { emailHandler } from './email/email.handler';
import { pushHandler } from './push/push.handler';

const logger = createServiceLogger('notification-service');
const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

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
    await subscribeToChannel(CHANNELS.NOTIFICATION_SEND, async (data: any) => {
        logger.info('Received notification request', data);

        try {
            const { userId, caseId, channel, message } = data;

            // Get user contact info
            const user = await prisma.user.findUnique({
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
                        sent = await smsHandler.send({ to: user.phone, message });
                    }
                    break;

                case 'EMAIL':
                    if (user.email) {
                        sent = await emailHandler.send({
                            to: user.email,
                            subject: 'Imboni Notification',
                            body: message,
                        });
                    }
                    break;

                case 'PUSH':
                    sent = await pushHandler.send({
                        userId,
                        title: 'Imboni',
                        body: message,
                        data: caseId ? { caseId } : undefined,
                    });
                    break;
            }

            // Record notification in database
            await prisma.notification.create({
                data: {
                    userId,
                    caseId,
                    channel,
                    message,
                    sentAt: sent ? new Date() : null,
                },
            });

            logger.info('Notification processed', { userId, channel, sent });
        } catch (error) {
            logger.error('Failed to process notification', error);
        }
    });

    logger.info('Event subscription ready');
}

// Start server
const PORT = config.ports.notificationService;

app.listen(PORT, async () => {
    logger.info(`📨 Notification Service running on port ${PORT}`);
    await setupEventSubscription();
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('Shutting down...');
    await disconnectMessaging();
    await disconnectPrisma();
    process.exit(0);
});

export default app;
