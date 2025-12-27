export declare const config: {
    nodeEnv: string;
    isDevelopment: boolean;
    isProduction: boolean;
    databaseUrl: string;
    jwt: {
        secret: string;
        expiresIn: string;
    };
    ports: {
        apiGateway: number;
        caseService: number;
        escalationService: number;
        notificationService: number;
        auditService: number;
        integrationService: number;
    };
    redis: {
        url: string;
    };
    rabbitmq: {
        url: string;
    };
    sms: {
        apiKey: string;
        username: string;
        senderId: string;
    };
    email: {
        host: string;
        port: number;
        user: string;
        password: string;
        from: string;
    };
    escalation: {
        normalHours: number;
        highHours: number;
        emergencyHours: number;
    };
};
export declare function validateConfig(): void;
//# sourceMappingURL=config.service.d.ts.map