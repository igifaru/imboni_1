"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CHANNELS = void 0;
exports.getRedisClient = getRedisClient;
exports.getRedisSubscriber = getRedisSubscriber;
exports.publishEvent = publishEvent;
exports.subscribeToChannel = subscribeToChannel;
exports.disconnectMessaging = disconnectMessaging;
/**
 * Message Broker Service - RabbitMQ/Redis Pub-Sub
 */
const ioredis_1 = __importDefault(require("ioredis"));
const logger_service_1 = require("../logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('messaging');
let redisPublisher = null;
let redisSubscriber = null;
function getRedisClient() {
    if (!redisPublisher) {
        redisPublisher = new ioredis_1.default(process.env.REDIS_URL || 'redis://localhost:6379');
        redisPublisher.on('connect', () => logger.info('Redis publisher connected'));
        redisPublisher.on('error', (err) => logger.error('Redis publisher error', err));
    }
    return redisPublisher;
}
function getRedisSubscriber() {
    if (!redisSubscriber) {
        redisSubscriber = new ioredis_1.default(process.env.REDIS_URL || 'redis://localhost:6379');
        redisSubscriber.on('connect', () => logger.info('Redis subscriber connected'));
        redisSubscriber.on('error', (err) => logger.error('Redis subscriber error', err));
    }
    return redisSubscriber;
}
// Event channels
exports.CHANNELS = {
    CASE_CREATED: 'case:created',
    CASE_UPDATED: 'case:updated',
    CASE_ESCALATED: 'case:escalated',
    CASE_RESOLVED: 'case:resolved',
    NOTIFICATION_SEND: 'notification:send',
    AUDIT_LOG: 'audit:log',
};
/**
 * Publish event to channel
 */
async function publishEvent(channel, data) {
    const client = getRedisClient();
    await client.publish(channel, JSON.stringify(data));
    logger.debug(`Published to ${channel}`, { data });
}
/**
 * Subscribe to channel
 */
async function subscribeToChannel(channel, handler) {
    const subscriber = getRedisSubscriber();
    await subscriber.subscribe(channel);
    subscriber.on('message', (ch, message) => {
        if (ch === channel) {
            try {
                const data = JSON.parse(message);
                handler(data);
            }
            catch (err) {
                logger.error(`Failed to parse message from ${channel}`, err);
            }
        }
    });
    logger.info(`Subscribed to ${channel}`);
}
/**
 * Cleanup connections
 */
async function disconnectMessaging() {
    if (redisPublisher) {
        await redisPublisher.quit();
        redisPublisher = null;
    }
    if (redisSubscriber) {
        await redisSubscriber.quit();
        redisSubscriber = null;
    }
}
//# sourceMappingURL=messaging.service.js.map