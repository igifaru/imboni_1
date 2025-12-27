/**
 * Prisma Service - Shared Database Client
 * Singleton instance for all services
 */
import { PrismaClient } from '@prisma/client';
export declare function getPrismaClient(): PrismaClient;
export declare function disconnectPrisma(): Promise<void>;
export declare const prisma: PrismaClient<import(".prisma/client").Prisma.PrismaClientOptions, never, import("@prisma/client/runtime/library").DefaultArgs>;
//# sourceMappingURL=prisma.service.d.ts.map