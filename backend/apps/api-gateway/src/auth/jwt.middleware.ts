/**
 * JWT Authentication Middleware
 */
import { Request, Response, NextFunction } from 'express';
import { verifyToken, extractToken, DecodedToken } from '../../../../libs/auth/jwt.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const logger = createServiceLogger('auth-middleware');

// Extend Express Request to include user
declare global {
    namespace Express {
        interface Request {
            user?: DecodedToken;
        }
    }
}

/**
 * Middleware to verify JWT token
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
    const token = extractToken(req.headers.authorization);

    if (!token) {
        res.status(401).json({ error: 'No token provided' });
        return;
    }

    const decoded = verifyToken(token);

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
export function roleMiddleware(...allowedRoles: string[]) {
    return (req: Request, res: Response, next: NextFunction): void => {
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
export function optionalAuthMiddleware(req: Request, res: Response, next: NextFunction): void {
    const token = extractToken(req.headers.authorization);

    if (token) {
        const decoded = verifyToken(token);
        if (decoded) {
            req.user = decoded;
        }
    }

    next();
}
