/**
 * PFTCV Seed Data - Sample projects for testing
 */
import { prisma } from '../libs/database/prisma.service';

async function seedPftcvData() {
    console.log('🌱 Seeding PFTCV sample data...');

    // First, get some administrative units
    const units = await prisma.administrativeUnit.findMany({
        where: { level: { in: ['SECTOR', 'DISTRICT'] } },
        take: 10
    });

    if (units.length === 0) {
        console.log('⚠️ No administrative units found. Please seed base data first.');
        return;
    }

    const sampleProjects = [
        {
            name: 'Ikiraro cy\'Ibinyabiziga - Kinyababa',
            sector: 'ROADS' as const,
            description: 'Kubaka ikiraro gishya cy\'ibinyabiziga mu murenge wa Kinyababa',
            approvedBudget: 150000000,
            implementingAgency: 'RTDA',
            fundingSource: 'Burezhi bwa Leta',
            expectedOutputs: 'Ikiraro cy\'amamiro 50',
            status: 'IN_PROGRESS' as const,
        },
        {
            name: 'Amashuri Yibanze - Gasiza',
            sector: 'EDUCATION' as const,
            description: 'Kwagura amashuri yibanze mu kagari ka Gasiza',
            approvedBudget: 75000000,
            implementingAgency: 'MINEDUC',
            fundingSource: 'Burezhi bwa Leta',
            expectedOutputs: 'Amasomo 12 mashya, ubwiherero bubiri',
            status: 'IN_PROGRESS' as const,
        },
        {
            name: 'Ivuriro - Rutovu',
            sector: 'HEALTH' as const,
            description: 'Kubaka ivuriro rishya mu kagari ka Rutovu',
            approvedBudget: 200000000,
            implementingAgency: 'MINISANTE',
            fundingSource: 'World Bank',
            expectedOutputs: 'Ivuriro rifite ibyumba 20',
            status: 'PLANNED' as const,
        },
        {
            name: 'Amazi meza - Burera',
            sector: 'WATER' as const,
            description: 'Gutanga amazi meza mu karere ka Burera',
            approvedBudget: 300000000,
            implementingAgency: 'WASAC',
            fundingSource: 'African Development Bank',
            expectedOutputs: 'Kilometero 25 z\'amazi, pompe 100',
            status: 'IN_PROGRESS' as const,
        },
        {
            name: 'Gufasha Abahinzi - Northern Province',
            sector: 'AGRICULTURE' as const,
            description: 'Gufasha abahinzi mu ntara y\'amajyaruguru',
            approvedBudget: 50000000,
            implementingAgency: 'MINAGRI',
            fundingSource: 'EU Grant',
            expectedOutputs: 'Imbuto z\'umwaka, amashanyarazi, ubujyanama',
            status: 'COMPLETED' as const,
        },
    ];

    let created = 0;
    for (const project of sampleProjects) {
        // Pick a random unit
        const unit = units[created % units.length];
        const projectCode = `PRJ-${Date.now().toString(36).toUpperCase()}-${created}`;

        try {
            await (prisma as any).project.create({
                data: {
                    projectCode,
                    name: project.name,
                    sector: project.sector,
                    description: project.description,
                    administrativeUnitId: unit.id,
                    approvedBudget: project.approvedBudget,
                    implementingAgency: project.implementingAgency,
                    fundingSource: project.fundingSource,
                    expectedOutputs: project.expectedOutputs,
                    status: project.status,
                    riskLevel: 'NORMAL',
                    startDate: new Date('2025-01-01'),
                    endDate: new Date('2026-12-31'),
                }
            });
            created++;
            console.log(`✅ Created: ${project.name}`);
        } catch (e: any) {
            console.error(`❌ Failed to create ${project.name}:`, e.message);
        }
    }

    // Add some fund releases
    const projects = await (prisma as any).project.findMany({ take: 3 });
    for (const p of projects) {
        await (prisma as any).fundRelease.create({
            data: {
                projectId: p.id,
                amount: Math.round(p.approvedBudget * 0.3),
                releaseDate: new Date('2025-03-15'),
                releaseRef: `REL-${Date.now().toString(36).toUpperCase()}`,
                description: 'Igice cya 1 - Gutangira'
            }
        });
    }

    console.log(`🎉 Seeded ${created} PFTCV projects and fund releases!`);
}

seedPftcvData()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
