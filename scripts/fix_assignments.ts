
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Fixing assignments...');

    // 1. Get a user to be the leader
    const user = await prisma.user.findFirst();
    if (!user) {
        console.error('No users found in database!');
        return;
    }
    console.log(`Found user: ${user.email} (${user.id})`);

    // 2. Get all Administrative Units
    const units = await prisma.administrativeUnit.findMany();
    console.log(`Found ${units.length} administrative units.`);

    // 3. Assign user as leader to all units if not already assigned
    for (const unit of units) {
        const existingAssignment = await prisma.leaderAssignment.findFirst({
            where: {
                userId: user.id,
                administrativeUnitId: unit.id,
            }
        });

        if (!existingAssignment) {
            await prisma.leaderAssignment.create({
                data: {
                    userId: user.id,
                    administrativeUnitId: unit.id,
                    isActive: true,
                    positionTitle: 'Administrator',
                    startDate: new Date(),
                }
            });
            console.log(`Assigned user to unit ${unit.name}`);
        }
    }

    // 4. Find cases without assignments and assign them
    const cases = await prisma.case.findMany({
        include: { assignments: true }
    });

    for (const c of cases) {
        if (c.assignments.length === 0) {
            // Find the leader we just ensured exists
            const leader = await prisma.leaderAssignment.findFirst({
                where: {
                    administrativeUnitId: c.administrativeUnitId,
                    userId: user.id
                }
            });

            if (leader) {
                // Calculate deadline (default 24h)
                const deadline = new Date();
                deadline.setHours(deadline.getHours() + 24);

                await prisma.caseAssignment.create({
                    data: {
                        caseId: c.id,
                        administrativeUnitId: c.administrativeUnitId,
                        leaderId: user.id,
                        assignedAt: new Date(),
                        deadlineAt: deadline,
                        isActive: true
                    }
                });
                console.log(`Assigned Case ${c.caseReference} to user.`);
            }
        }
    }

    console.log('Done!');
}

main()
    .catch((e) => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
