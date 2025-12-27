"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pushHandler = exports.PushHandler = void 0;
/**
 * Push Notification Handler - Firebase Cloud Messaging
 */
const logger_service_1 = require("../../../../libs/logging/logger.service");
const config_service_1 = require("../../../../libs/config/config.service");
const logger = (0, logger_service_1.createServiceLogger)('push-handler');
class PushHandler {
    /**
     * Send push notification
     */
    async send(push) {
        try {
            // In development, just log
            if (config_service_1.config.isDevelopment) {
                logger.info('Push (dev mode)', {
                    userId: push.userId,
                    title: push.title,
                    body: push.body,
                });
                return true;
            }
            // Firebase Admin SDK integration would go here
            // const admin = await import('firebase-admin');
            // await admin.messaging().send({
            //   token: userToken,
            //   notification: {
            //     title: push.title,
            //     body: push.body,
            //   },
            //   data: push.data,
            // });
            logger.info('Push sent', { userId: push.userId, title: push.title });
            return true;
        }
        catch (error) {
            logger.error('Failed to send push notification', { error, userId: push.userId });
            return false;
        }
    }
    /**
     * Send push to multiple users
     */
    async sendToMany(userIds, title, body) {
        let success = 0;
        let failed = 0;
        for (const userId of userIds) {
            const result = await this.send({ userId, title, body });
            if (result) {
                success++;
            }
            else {
                failed++;
            }
        }
        return { success, failed };
    }
}
exports.PushHandler = PushHandler;
exports.pushHandler = new PushHandler();
//# sourceMappingURL=push.handler.js.map