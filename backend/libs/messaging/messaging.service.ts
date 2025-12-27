/**
 * Message Broker Service - RabbitMQ/Redis Pub-Sub
 */
import Redis from 'ioredis';
import { createServiceLogger } from '../logging/logger.service';

const logger = createServiceLogger('messaging');

let redisPublisher: Redis | null = null;
let redisSubscriber: Redis | null = null;

export function getRedisClient(): Redis {
    if (!redisPublisher) {
        redisPublisher = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
        redisPublisher.on('connect', () => logger.info('Redis publisher connected'));
        redisPublisher.on('error', (err) => logger.error('Redis publisher error', err));
    }
    return redisPublisher;
}

export function getRedisSubscriber(): Redis {
    if (!redisSubscriber) {
        redisSubscriber = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
        redisSubscriber.on('connect', () => logger.info('Redis subscriber connected'));
        redisSubscriber.on('error', (err) => logger.error('Redis subscriber error', err));
    }
    return redisSubscriber;
}

// Event channels
export const CHANNELS = {
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
export async function publishEvent(channel: string, data: object): Promise<void> {
    const client = getRedisClient();
    await client.publish(channel, JSON.stringify(data));
    logger.debug(`Published to ${channel}`, { data });
}

/**
 * Subscribe to channel
 */
export async function subscribeToChannel(
    channel: string,
    handler: (data: object) => void
): Promise<void> {
    const subscriber = getRedisSubscriber();
    await subscriber.subscribe(channel);

    subscriber.on('message', (ch, message) => {
        if (ch === channel) {
            try {
                const data = JSON.parse(message);
                handler(data);
            } catch (err) {
                logger.error(`Failed to parse message from ${channel}`, err);
            }
        }
    });

    logger.info(`Subscribed to ${channel}`);
}

/**
 * Cleanup connections
 */
export async function disconnectMessaging(): Promise<void> {
    if (redisPublisher) {
        await redisPublisher.quit();
        redisPublisher = null;
    }
    if (redisSubscriber) {
        await redisSubscriber.quit();
        redisSubscriber = null;
    }
}
