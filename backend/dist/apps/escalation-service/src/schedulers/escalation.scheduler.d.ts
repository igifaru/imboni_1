export declare class EscalationScheduler {
    private cronJob;
    /**
     * Start the scheduler
     */
    start(): void;
    /**
     * Stop the scheduler
     */
    stop(): void;
    /**
     * Check for expired deadlines and trigger escalations
     */
    checkAndEscalate(): Promise<void>;
    /**
     * Escalate a single case
     */
    private escalateCase;
    /**
     * Send parallel notifications for emergency cases
     */
    private sendEmergencyNotifications;
}
export declare const escalationScheduler: EscalationScheduler;
//# sourceMappingURL=escalation.scheduler.d.ts.map