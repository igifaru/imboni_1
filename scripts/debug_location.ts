
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkCaseLocation() {
    try {
        console.log('--- Checking Case Location Data ---');
        // Find the case shown in the screenshot or just the latest one
        const latestCase = await prisma.case.findFirst({
            orderBy: { createdAt: 'desc' },
            include: { administrativeUnit: true }
        });

        if (latestCase) {
            console.log(`Latest Case ID: ${latestCase.id}`);
            console.log(`Case Ref: ${latestCase.caseReference}`);
            console.log(`Title: ${latestCase.title}`);
            console.log(`Admin Unit ID: ${latestCase.administrativeUnitId}`);
            console.log(`Admin Unit:`, latestCase.administrativeUnit);

            if (!latestCase.administrativeUnit) {
                console.error('CRITICAL: Administrative Unit is NULL for this case!');

                // Try to find the unit manually to see if it exists
                if (latestCase.administrativeUnitId) {
                    const unit = await prisma.administrativeUnit.findUnique({
                        where: { id: latestCase.administrativeUnitId }
                    });
                    console.log('Manual Unit Lookup Result:', unit);
                }
            } else {
                console.log('SUCCESS: Case has a linked Administrative Unit.');
                console.log(`Location Name: ${latestCase.administrativeUnit.name}`);
            }
        } else {
            console.log('No cases found in database.');
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkCaseLocation();
