
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Debugging Data...');

    // 1. List Users
    const users = await prisma.user.findMany({
        include: {
            caseAssignments: true,
            leaderAssignments: true
        }
    });

    console.log(`Total Users: ${users.length}`);
    users.forEach(u => {
        console.log(`User: ${u.email || u.id} (ID: ${u.id})`);
        console.log(`  - Leader Assignments: ${u.leaderAssignments.map(la => la.administrativeUnitId).join(', ')}`);
        console.log(`  - Case Assignments: ${u.caseAssignments.length}`);
        if (u.caseAssignments.length > 0) {
            console.log(`    Case IDs: ${u.caseAssignments.map(ca => ca.caseId).join(', ')}`);
        }
    });

    // 2. List Cases
    const cases = await prisma.case.findMany({
        include: { assignments: true }
    });
    console.log(`\nTotal Cases: ${cases.length}`);
    cases.forEach(c => {
        console.log(`Case: ${c.caseReference} (${c.status})`);
        console.log(`  - Assignments: ${c.assignments.length}`);
    });
}

main()
    .catch((e) => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
