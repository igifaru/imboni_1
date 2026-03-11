import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function getCaseReport(_req: Request, res: Response): Promise<void> {
  const [total, resolved, escalated] = await Promise.all([
    prisma.case.count(),
    prisma.case.count({ where: { status: 'RESOLVED' } }),
    prisma.case.count({ where: { status: 'ESCALATED' } }),
  ]);
  res.json({ success: true, data: { total, resolved, escalated, pending: total - resolved } });
}

export async function getInstitutionReport(_req: Request, res: Response): Promise<void> {
  const requests = await prisma.institutionRequest.groupBy({ by: ['status'], _count: true });
  res.json({ success: true, data: requests });
}
