"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = void 0;
exports.validateConfig = validateConfig;
/**
 * Configuration Service - Environment Variables
 */
const dotenv_1 = __importDefault(require("dotenv"));
// Load environment variables
dotenv_1.default.config();
exports.config = {
    // Environment
    nodeEnv: process.env.NODE_ENV || 'development',
    isDevelopment: process.env.NODE_ENV === 'development',
    isProduction: process.env.NODE_ENV === 'production',
    // Database
    databaseUrl: process.env.DATABASE_URL || '',
    // JWT
    jwt: {
        secret: process.env.JWT_SECRET || 'change-me',
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    },
    // Service Ports
    ports: {
        apiGateway: parseInt(process.env.API_GATEWAY_PORT || '3000'),
        caseService: parseInt(process.env.CASE_SERVICE_PORT || '3001'),
        escalationService: parseInt(process.env.ESCALATION_SERVICE_PORT || '3002'),
        notificationService: parseInt(process.env.NOTIFICATION_SERVICE_PORT || '3003'),
        auditService: parseInt(process.env.AUDIT_SERVICE_PORT || '3004'),
        integrationService: parseInt(process.env.INTEGRATION_SERVICE_PORT || '3005'),
    },
    // Redis
    redis: {
        url: process.env.REDIS_URL || 'redis://localhost:6379',
    },
    // RabbitMQ
    rabbitmq: {
        url: process.env.RABBITMQ_URL || 'amqp://localhost:5672',
    },
    // SMS
    sms: {
        apiKey: process.env.SMS_API_KEY || '',
        username: process.env.SMS_USERNAME || '',
        senderId: process.env.SMS_SENDER_ID || 'IMBONI',
    },
    // Email
    email: {
        host: process.env.SMTP_HOST || '',
        port: parseInt(process.env.SMTP_PORT || '587'),
        user: process.env.SMTP_USER || '',
        password: process.env.SMTP_PASSWORD || '',
        from: process.env.EMAIL_FROM || 'noreply@imboni.gov.rw',
    },
    // Escalation Deadlines (in hours)
    escalation: {
        normalHours: parseInt(process.env.ESCALATION_NORMAL_HOURS || '48'),
        highHours: parseInt(process.env.ESCALATION_HIGH_HOURS || '24'),
        emergencyHours: parseInt(process.env.ESCALATION_EMERGENCY_HOURS || '4'),
    },
};
function validateConfig() {
    const required = ['DATABASE_URL', 'JWT_SECRET'];
    const missing = required.filter((key) => !process.env[key]);
    if (missing.length > 0) {
        throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
    }
}
//# sourceMappingURL=config.service.js.map