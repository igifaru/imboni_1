/**
 * JWT Authentication Middleware
 */
import { Request, Response, NextFunction } from 'express';
import { DecodedToken } from '../../../../libs/auth/jwt.service';
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
export declare function authMiddleware(req: Request, res: Response, next: NextFunction): void;
/**
 * Middleware to check if user has required role
 */
export declare function roleMiddleware(...allowedRoles: string[]): (req: Request, res: Response, next: NextFunction) => void;
/**
 * Optional auth - doesn't fail if no token
 */
export declare function optionalAuthMiddleware(req: Request, res: Response, next: NextFunction): void;
//# sourceMappingURL=jwt.middleware.d.ts.map