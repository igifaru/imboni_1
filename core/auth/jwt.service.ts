/**
 * JWT Service - Token Generation & Validation
 */
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

export interface TokenPayload {
    userId: string;
    role: string;
    email?: string;
    phone?: string;
}

export interface DecodedToken extends TokenPayload {
    iat: number;
    exp: number;
}

/**
 * Generate JWT token for authenticated user
 */
export function generateToken(payload: TokenPayload): string {
    return jwt.sign(payload, JWT_SECRET, {
        expiresIn: JWT_EXPIRES_IN as string,
    } as jwt.SignOptions);
}

/**
 * Verify and decode JWT token
 */
export function verifyToken(token: string): DecodedToken | null {
    try {
        return jwt.verify(token, JWT_SECRET) as DecodedToken;
    } catch (error) {
        return null;
    }
}

/**
 * Extract token from Authorization header
 */
export function extractToken(authHeader: string | undefined): string | null {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return null;
    }
    return authHeader.substring(7);
}

/**
 * Decode token without verification (for debugging)
 */
export function decodeToken(token: string): DecodedToken | null {
    try {
        return jwt.decode(token) as DecodedToken;
    } catch (error) {
        return null;
    }
}
