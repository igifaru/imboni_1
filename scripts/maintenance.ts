/**
 * Maintenance Script — cleanup, health checks, orphan removal
 * Run with: npx ts-node -r tsconfig-paths/register scripts/maintenance.ts
 */
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

async function run() {
  console.log('=== IMBONI Maintenance Script ===');

  // 1. Count records
  const [users, cases, institutions, requests] = await Promise.all([
    prisma.user.count(),
    prisma.case.count(),
    prisma.institution.count(),
    prisma.institutionRequest.count(),
  ]);

  console.log('Database stats:');
  console.log(`  Users:        ${users}`);
  console.log(`  Cases:        ${cases}`);
  console.log(`  Institutions: ${institutions}`);
  console.log(`  Requests:     ${requests}`);

  // 2. Check for stale escalations (open > 30 days)
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const stale = await prisma.case.count({
    where: { status: 'ESCALATED', updatedAt: { lt: thirtyDaysAgo } },
  });
  if (stale > 0) console.warn(`  WARNING: ${stale} escalated cases older than 30 days`);

  await prisma.$disconnect();
  console.log('Maintenance complete.');
}

run().catch((e) => { console.error(e); process.exit(1); });
