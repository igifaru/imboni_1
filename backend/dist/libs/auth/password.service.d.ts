/**
 * Hash a plain text password
 */
export declare function hashPassword(password: string): Promise<string>;
/**
 * Compare password with hash
 */
export declare function verifyPassword(password: string, hash: string): Promise<boolean>;
/**
 * Generate a random password
 */
export declare function generateRandomPassword(length?: number): string;
//# sourceMappingURL=password.service.d.ts.map