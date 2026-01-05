import { PrismaClient, UserRole, AdministrativeLevel } from '@prisma/client';
import { hash } from 'bcryptjs';
// @ts-ignore
import { getAllProvinces } from 'rwanda-geo';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Starting seed...');

    // 1. Create System Admin
    const adminEmail = 'admin@imboni.com';
    const adminPassword = await hash('admin123', 10);

    const admin = await prisma.user.upsert({
        where: { email: adminEmail },
        update: {},
        create: {
            email: adminEmail,
            name: 'System Administrator',
            phone: '0788888888', // Added for frontend login compatibility
            password: adminPassword,
            role: UserRole.ADMIN,
            status: 'ACTIVE',
        },
    });

    console.log(`✅ Admin user created: ${admin.email}`);

    // 2. Seed Provinces
    // rwanda-geo: getAllProvinces returns array of strings
    const provinces = getAllProvinces(); // Returns array of strings

    for (const province of provinces) {
        // rwanda-geo returns objects like { name: "Kigali", ... } or just strings in some versions.
        // Use 'as any' to avoid TS issues if types are missing/wrong.
        const provinceName = (province as any).name || province; // fallback if string

        // We need a unique code. Let's use name.toUpperCase()
        const code = String(provinceName).toUpperCase();

        await prisma.administrativeUnit.upsert({
            where: { code },
            update: {},
            create: {
                name: String(provinceName),
                level: AdministrativeLevel.PROVINCE,
                code: code,
            },
        });
    }

    console.log(`✅ ${provinces.length} Provinces seeded`);

    console.log('🌱 Seed completed.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        // Run PFTCV seeds
        const { seedPftcvData } = require('./seed-pftcv');
        await seedPftcvData();

        await prisma.$disconnect();
    });
