/**
 * General API rate limiter
 */
export declare const generalRateLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * Strict rate limiter for auth endpoints
 */
export declare const authRateLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * Case submission rate limiter
 */
export declare const caseSubmissionRateLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * Emergency case bypass - no rate limit
 */
export declare const emergencyBypass: (req: any, res: any, next: any) => any;
//# sourceMappingURL=rate-limit.middleware.d.ts.map