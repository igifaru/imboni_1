export interface PushMessage {
    userId: string;
    title: string;
    body: string;
    data?: Record<string, string>;
}
export declare class PushHandler {
    /**
     * Send push notification
     */
    send(push: PushMessage): Promise<boolean>;
    /**
     * Send push to multiple users
     */
    sendToMany(userIds: string[], title: string, body: string): Promise<{
        success: number;
        failed: number;
    }>;
}
export declare const pushHandler: PushHandler;
//# sourceMappingURL=push.handler.d.ts.map