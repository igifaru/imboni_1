/**
 * Email Handler - SMTP Integration
 */
import nodemailer from 'nodemailer';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { config } from '../../../../libs/config/config.service';

const logger = createServiceLogger('email-handler');

export interface EmailMessage {
    to: string;
    subject: string;
    body: string;
    html?: string;
}

export class EmailHandler {
    private transporter: nodemailer.Transporter | null = null;

    constructor() {
        if (config.email.host && config.email.user) {
            this.transporter = nodemailer.createTransport({
                host: config.email.host,
                port: config.email.port,
                secure: config.email.port === 465,
                auth: {
                    user: config.email.user,
                    pass: config.email.password,
                },
            });
        }
    }

    /**
     * Send email
     */
    async send(email: EmailMessage): Promise<boolean> {
        try {
            // In development, just log
            if (config.isDevelopment || !this.transporter) {
                logger.info('Email (dev mode)', {
                    to: email.to,
                    subject: email.subject,
                });
                return true;
            }

            await this.transporter.sendMail({
                from: config.email.from,
                to: email.to,
                subject: email.subject,
                text: email.body,
                html: email.html,
            });

            logger.info('Email sent', { to: email.to, subject: email.subject });
            return true;
        } catch (error) {
            logger.error('Failed to send email', { error, to: email.to });
            return false;
        }
    }

    /**
     * Send case notification email
     */
    async sendCaseNotification(
        to: string,
        caseReference: string,
        status: string,
        message: string
    ): Promise<boolean> {
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

export const emailHandler = new EmailHandler();
