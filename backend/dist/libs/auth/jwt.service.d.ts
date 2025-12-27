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
export declare function generateToken(payload: TokenPayload): string;
/**
 * Verify and decode JWT token
 */
export declare function verifyToken(token: string): DecodedToken | null;
/**
 * Extract token from Authorization header
 */
export declare function extractToken(authHeader: string | undefined): string | null;
/**
 * Decode token without verification (for debugging)
 */
export declare function decodeToken(token: string): DecodedToken | null;
//# sourceMappingURL=jwt.service.d.ts.map