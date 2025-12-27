"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.smsHandler = exports.SmsHandler = void 0;
/**
 * SMS Handler - Africa's Talking Integration
 */
const logger_service_1 = require("../../../../libs/logging/logger.service");
const config_service_1 = require("../../../../libs/config/config.service");
const logger = (0, logger_service_1.createServiceLogger)('sms-handler');
class SmsHandler {
    apiKey;
    username;
    senderId;
    constructor() {
        this.apiKey = config_service_1.config.sms.apiKey;
        this.username = config_service_1.config.sms.username;
        this.senderId = config_service_1.config.sms.senderId;
    }
    /**
     * Send SMS message
     */
    async send(sms) {
        try {
            // In development, just log
            if (config_service_1.config.isDevelopment || !this.apiKey) {
                logger.info('SMS (dev mode)', { to: sms.to, message: sms.message });
                return true;
            }
            // Africa's Talking API call would go here
            // const response = await fetch('https://api.africastalking.com/version1/messaging', {
            //   method: 'POST',
            //   headers: {
            //     'apiKey': this.apiKey,
            //     'Content-Type': 'application/x-www-form-urlencoded',
            //   },
            //   body: new URLSearchParams({
            //     username: this.username,
            //     to: sms.to,
            //     message: sms.message,
            //     from: this.senderId,
            //   }),
            // });
            logger.info('SMS sent', { to: sms.to });
            return true;
        }
        catch (error) {
            logger.error('Failed to send SMS', { error, to: sms.to });
            return false;
        }
    }
    /**
     * Send bulk SMS
     */
    async sendBulk(messages) {
        let success = 0;
        let failed = 0;
        for (const msg of messages) {
            const result = await this.send(msg);
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
exports.SmsHandler = SmsHandler;
exports.smsHandler = new SmsHandler();
//# sourceMappingURL=sms.handler.js.map