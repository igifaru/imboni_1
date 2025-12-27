export interface EmailMessage {
    to: string;
    subject: string;
    body: string;
    html?: string;
}
export declare class EmailHandler {
    private transporter;
    constructor();
    /**
     * Send email
     */
    send(email: EmailMessage): Promise<boolean>;
    /**
     * Send case notification email
     */
    sendCaseNotification(to: string, caseReference: string, status: string, message: string): Promise<boolean>;
}
export declare const emailHandler: EmailHandler;
//# sourceMappingURL=email.handler.d.ts.map