export interface SmsMessage {
    to: string;
    message: string;
}
export declare class SmsHandler {
    private apiKey;
    private username;
    private senderId;
    constructor();
    /**
     * Send SMS message
     */
    send(sms: SmsMessage): Promise<boolean>;
    /**
     * Send bulk SMS
     */
    sendBulk(messages: SmsMessage[]): Promise<{
        success: number;
        failed: number;
    }>;
}
export declare const smsHandler: SmsHandler;
//# sourceMappingURL=sms.handler.d.ts.map