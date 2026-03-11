
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Assigning Admin and Test Leader to everything...');

    const targetEmails = ['admin@imboni.com', 'leader@test.com', 'mutoni@gmail.com', 'etienne@gmail.com'];
    const users = await prisma.user.findMany({
        where: { email: { in: targetEmails } }
    });

    if (users.length === 0) {
        console.log('No target users found.');
        return;
    }

    const units = await prisma.administrativeUnit.findMany();
    const cases = await prisma.case.findMany();

    for (const user of users) {
        console.log(`Processing user ${user.email}...`);

        // 1. Assign as Leader to ALL units
        for (const unit of units) {
            const existing = await prisma.leaderAssignment.findFirst({
                where: { userId: user.id, administrativeUnitId: unit.id }
            });

            if (!existing) {
                await prisma.leaderAssignment.create({
                    data: {
                        userId: user.id,
                        administrativeUnitId: unit.id,
                        isActive: true,
                        positionTitle: 'Universal Leader',
                        startDate: new Date(),
                    }
                });
            }
        }
        console.log(`  - Assigned to ${units.length} units.`);

        // 2. Assign ALL cases to this user
        for (const c of cases) {
            const existing = await prisma.caseAssignment.findFirst({
                where: { caseId: c.id, leaderId: user.id }
            });

            if (!existing) {
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
            }
        }
        console.log(`  - Assigned ${cases.length} cases.`);
    }

    console.log('Done!');
}

main()
    .catch((e) => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
