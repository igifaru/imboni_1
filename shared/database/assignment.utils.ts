import { PrismaClient, AdministrativeLevel } from '@prisma/client';

/**
 * Find nearest active leader in hierarchy (recursive up)
 * Shared utility to avoid redundancy between CaseService and EscalationScheduler
 */
export async function findNearestLeader(
    prisma: PrismaClient | any, // Allow transaction client
    startUnitId: string
): Promise<{ userId: string, administrativeUnitId: string } | null> {
    let currentUnitId: string | null = startUnitId;

    while (currentUnitId) {
        // Find leader for current unit
        const leader = await prisma.leaderAssignment.findFirst({
            where: {
                administrativeUnitId: currentUnitId,
                isActive: true,
            },
        });

        if (leader) {
            return { userId: leader.userId, administrativeUnitId: currentUnitId };
        }

        // No leader found at this level, move to parent
        const unit: { parentId: string | null } | null = await prisma.administrativeUnit.findUnique({
            where: { id: currentUnitId },
            select: { parentId: true }
        });

        if (!unit || !unit.parentId) break;
        currentUnitId = unit.parentId;
    }

    return null;
    return null;
}

/**
 * Find ancestor unit at specific level
 * Used for escalation to determine target unit from origin
 */
export async function getAncestorAtLevel(
    prisma: PrismaClient | any,
    startUnitId: string,
    targetLevel: AdministrativeLevel
): Promise<{ id: string, parentId: string | null } | null> {
    let currentUnitId: string | null = startUnitId;

    while (currentUnitId) {
        const unit: { id: string; parentId: string | null; level: AdministrativeLevel } | null = await prisma.administrativeUnit.findUnique({
            where: { id: currentUnitId },
            select: { id: true, parentId: true, level: true }
        });

        if (!unit) return null;

        if (unit.level === targetLevel) {
            return unit;
        }

        currentUnitId = unit.parentId;
        if (!currentUnitId) break;
    }

    return null;
}
