
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Checking Evidence...');

    // Find the case by reference from the screenshot
    const caseRef = 'IMB-QG8BC2-UF';

    const c = await prisma.case.findUnique({
        where: { caseReference: caseRef },
        include: { evidence: true }
    });

    if (!c) {
        console.log(`Case ${caseRef} not found!`);
        return;
    }

    console.log(`Case: ${c.caseReference} (ID: ${c.id})`);
    console.log(`Evidence Count: ${c.evidence.length}`);
    if (c.evidence.length > 0) {
        c.evidence.forEach(e => {
            console.log(` - ${e.fileName} (${e.type}) URL: ${e.url}`);
        });
    } else {
        console.log('No evidence found in database.');
    }
}

main()
    .catch((e) => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
