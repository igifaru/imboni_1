"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.emailHandler = exports.EmailHandler = void 0;
/**
 * Email Handler - SMTP Integration
 */
const nodemailer_1 = __importDefault(require("nodemailer"));
const logger_service_1 = require("../../../../libs/logging/logger.service");
const config_service_1 = require("../../../../libs/config/config.service");
const logger = (0, logger_service_1.createServiceLogger)('email-handler');
class EmailHandler {
    transporter = null;
    constructor() {
        if (config_service_1.config.email.host && config_service_1.config.email.user) {
            this.transporter = nodemailer_1.default.createTransport({
                host: config_service_1.config.email.host,
                port: config_service_1.config.email.port,
                secure: config_service_1.config.email.port === 465,
                auth: {
                    user: config_service_1.config.email.user,
                    pass: config_service_1.config.email.password,
                },
            });
        }
    }
    /**
     * Send email
     */
    async send(email) {
        try {
            // In development, just log
            if (config_service_1.config.isDevelopment || !this.transporter) {
                logger.info('Email (dev mode)', {
                    to: email.to,
                    subject: email.subject,
                });
                return true;
            }
            await this.transporter.sendMail({
                from: config_service_1.config.email.from,
                to: email.to,
                subject: email.subject,
                text: email.body,
                html: email.html,
            });
            logger.info('Email sent', { to: email.to, subject: email.subject });
            return true;
        }
        catch (error) {
            logger.error('Failed to send email', { error, to: email.to });
            return false;
        }
    }
    /**
     * Send case notification email
     */
    async sendCaseNotification(to, caseReference, status, message) {
        return this.send({
            to,
            subject: `Imboni Case Update: ${caseReference}`,
            body: message,
            html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #00A86B;">Imboni - Case Update</h2>
          <p><strong>Case Reference:</strong> ${caseReference}</p>
          <p><strong>Status:</strong> ${status}</p>
          <hr style="border: 1px solid #eee;" />
          <p>${message}</p>
          <hr style="border: 1px solid #eee;" />
          <p style="color: #666; font-size: 12px;">
            This is an automated message from the Imboni Civic Governance Platform.
          </p>
        </div>
      `,
        });
    }
}
exports.EmailHandler = EmailHandler;
exports.emailHandler = new EmailHandler();
//# sourceMappingURL=email.handler.js.map