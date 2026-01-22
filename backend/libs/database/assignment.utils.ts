import { PrismaClient } from '@prisma/client';

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
}
