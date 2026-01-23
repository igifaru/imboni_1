/**
 * Rate Limiting Middleware
 */
import rateLimit from 'express-rate-limit';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const logger = createServiceLogger('rate-limit');

/**
 * General API rate limiter
 */
export const generalRateLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // Reduced to 1 minute for faster resets
    max: 1000, // Increased for development
    message: {
        error: 'Too many requests, please try again later',
        retryAfter: '1 minute',
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
        logger.warn('Rate limit exceeded', { ip: req.ip, path: req.path });
        res.status(429).json(options.message);
    },
});

/**
 * Strict rate limiter for auth endpoints
 */
export const authRateLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // Reduced to 1 minute
    max: 100, // Increased to 100 attempts per minute
    message: {
        error: 'Too many authentication attempts, please try again later',
        retryAfter: '1 minute',
    },
    standardHeaders: true,
    legacyHeaders: false,
});

/**
 * Case submission rate limiter
 */
export const caseSubmissionRateLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 100, // Increased to 100 to allow multiple evidence uploads
    message: {
        error: 'Case submission limit reached, please try again later',
        retryAfter: '1 hour',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        // Use user ID if authenticated, otherwise IP
        return (req as any).user?.userId || req.ip || 'unknown';
    },
});

/**
 * Emergency case bypass - no rate limit
 */
export const emergencyBypass = (req: any, res: any, next: any) => {
    // Emergency cases bypass rate limiting
    if (req.body?.urgency === 'EMERGENCY') {
        return next();
    }
    return caseSubmissionRateLimiter(req, res, next);
};
