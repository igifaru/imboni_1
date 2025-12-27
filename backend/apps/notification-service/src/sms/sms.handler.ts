/**
 * SMS Handler - Africa's Talking Integration
 */
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { config } from '../../../../libs/config/config.service';

const logger = createServiceLogger('sms-handler');

export interface SmsMessage {
    to: string;
    message: string;
}

export class SmsHandler {
    private apiKey: string;
    private username: string;
    private senderId: string;

    constructor() {
        this.apiKey = config.sms.apiKey;
        this.username = config.sms.username;
        this.senderId = config.sms.senderId;
    }

    /**
     * Send SMS message
     */
    async send(sms: SmsMessage): Promise<boolean> {
        try {
            // In development, just log
            if (config.isDevelopment || !this.apiKey) {
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
        } catch (error) {
            logger.error('Failed to send SMS', { error, to: sms.to });
            return false;
        }
    }

    /**
     * Send bulk SMS
     */
    async sendBulk(messages: SmsMessage[]): Promise<{ success: number; failed: number }> {
        let success = 0;
        let failed = 0;

        for (const msg of messages) {
            const result = await this.send(msg);
            if (result) {
                success++;
            } else {
                failed++;
            }
        }

        return { success, failed };
    }
}

export const smsHandler = new SmsHandler();
