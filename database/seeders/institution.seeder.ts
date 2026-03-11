import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding institution data...');

    // 1. Institution Types
    const bankType = await prisma.institutionType.upsert({
        where: { name: 'BANK' },
        update: {},
        create: {
            name: 'BANK',
            description: 'Financial institutions providing banking services'
        }
    });

    await prisma.institutionType.upsert({
        where: { name: 'GOVERNMENT' },
        update: {},
        create: {
            name: 'GOVERNMENT',
            description: 'Public government agencies'
        }
    });

    // 2. Example Institution: Equity Bank
    const equityBank = await prisma.institution.upsert({
        where: { email: 'info@equitybank.co.rw' },
        update: {},
        create: {
            name: 'Equity Bank',
            typeId: bankType.id,
            description: 'Self-proclaimed listening bank',
            email: 'info@equitybank.co.rw',
            phone: '+250788123456',
            website: 'https://equitybank.rw',
            hqLocation: 'Kigali, Rwanda',
            status: 'ACTIVE'
        }
    });

    // 3. Branches
    const kigaliMain = await prisma.institutionBranch.create({
        data: {
            institutionId: equityBank.id,
            branchName: 'Kigali Main Branch',
            province: 'Kigali City',
            district: 'Nyarugenge',
            sector: 'Nyarugenge',
            address: 'KN 4 St, Kigali',
            status: 'ACTIVE'
        }
    });

    // 4. Services
    await prisma.institutionService.createMany({
        data: [
            {
                institutionId: equityBank.id,
                serviceName: 'Loan Application',
                description: 'Apply for personal or business loans',
                processingDays: 7,
                status: 'ACTIVE'
            },
            {
                institutionId: equityBank.id,
                serviceName: 'ATM Complaint',
                description: 'Report issues with ATM withdrawals',
                processingDays: 2,
                status: 'ACTIVE'
            },
            {
                institutionId: equityBank.id,
                serviceName: 'Account Opening',
                description: 'Request to open a new bank account',
                processingDays: 1,
                status: 'ACTIVE'
            }
        ]
    });

    console.log('Seeding completed successfully.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
