"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
exports.roleMiddleware = roleMiddleware;
exports.optionalAuthMiddleware = optionalAuthMiddleware;
const jwt_service_1 = require("../../../../libs/auth/jwt.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('auth-middleware');
/**
 * Middleware to verify JWT token
 */
function authMiddleware(req, res, next) {
    const token = (0, jwt_service_1.extractToken)(req.headers.authorization);
    if (!token) {
        res.status(401).json({ error: 'No token provided' });
        return;
    }
    const decoded = (0, jwt_service_1.verifyToken)(token);
    if (!decoded) {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
    }
    req.user = decoded;
    next();
}
/**
 * Middleware to check if user has required role
 */
function roleMiddleware(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            res.status(401).json({ error: 'Authentication required' });
            return;
        }
        if (!allowedRoles.includes(req.user.role)) {
            res.status(403).json({ error: 'Insufficient permissions' });
            return;
        }
        next();
    };
}
/**
 * Optional auth - doesn't fail if no token
 */
function optionalAuthMiddleware(req, res, next) {
    const token = (0, jwt_service_1.extractToken)(req.headers.authorization);
    if (token) {
        const decoded = (0, jwt_service_1.verifyToken)(token);
        if (decoded) {
            req.user = decoded;
        }
    }
    next();
}
//# sourceMappingURL=jwt.middleware.js.map