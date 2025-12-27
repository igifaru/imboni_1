/**
 * Message Broker Service - RabbitMQ/Redis Pub-Sub
 */
import Redis from 'ioredis';
export declare function getRedisClient(): Redis;
export declare function getRedisSubscriber(): Redis;
export declare const CHANNELS: {
    CASE_CREATED: string;
    CASE_UPDATED: string;
    CASE_ESCALATED: string;
    CASE_RESOLVED: string;
    NOTIFICATION_SEND: string;
    AUDIT_LOG: string;
};
/**
 * Publish event to channel
 */
export declare function publishEvent(channel: string, data: object): Promise<void>;
/**
 * Subscribe to channel
 */
export declare function subscribeToChannel(channel: string, handler: (data: object) => void): Promise<void>;
/**
 * Cleanup connections
 */
export declare function disconnectMessaging(): Promise<void>;
//# sourceMappingURL=messaging.service.d.ts.map