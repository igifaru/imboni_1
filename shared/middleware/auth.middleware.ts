/**
 * Shared auth middleware — re-exports core JWT guard
 * Use this in shared/middleware for clean imports across modules.
 */
export { jwtMiddleware as authMiddleware } from '@core/auth/jwt.service';
