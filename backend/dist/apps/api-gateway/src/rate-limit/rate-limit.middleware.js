"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.emergencyBypass = exports.caseSubmissionRateLimiter = exports.authRateLimiter = exports.generalRateLimiter = void 0;
/**
 * Rate Limiting Middleware
 */
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const logger_service_1 = require("../../../../libs/logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('rate-limit');
/**
 * General API rate limiter
 */
exports.generalRateLimiter = (0, express_rate_limit_1.default)({
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
exports.authRateLimiter = (0, express_rate_limit_1.default)({
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
exports.caseSubmissionRateLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5, // 5 cases per hour
    message: {
        error: 'Case submission limit reached, please try again later',
        retryAfter: '1 hour',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        // Use user ID if authenticated, otherwise IP
        return req.user?.userId || req.ip || 'unknown';
    },
});
/**
 * Emergency case bypass - no rate limit
 */
const emergencyBypass = (req, res, next) => {
    // Emergency cases bypass rate limiting
    if (req.body?.urgency === 'EMERGENCY') {
        return next();
    }
    return (0, exports.caseSubmissionRateLimiter)(req, res, next);
};
exports.emergencyBypass = emergencyBypass;
//# sourceMappingURL=rate-limit.middleware.js.map