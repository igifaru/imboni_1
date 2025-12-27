"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;
exports.getPrismaClient = getPrismaClient;
exports.disconnectPrisma = disconnectPrisma;
/**
 * Prisma Service - Shared Database Client
 * Singleton instance for all services
 */
const client_1 = require("@prisma/client");
let prismaInstance = null;
function getPrismaClient() {
    if (!prismaInstance) {
        prismaInstance = new client_1.PrismaClient({
            log: process.env.NODE_ENV === 'development'
                ? ['query', 'error', 'warn']
                : ['error'],
        });
    }
    return prismaInstance;
}
async function disconnectPrisma() {
    if (prismaInstance) {
        await prismaInstance.$disconnect();
        prismaInstance = null;
    }
}
exports.prisma = getPrismaClient();
//# sourceMappingURL=prisma.service.js.map