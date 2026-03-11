import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function getCaseStats(_req: Request, res: Response): Promise<void> {
  const stats = await prisma.case.groupBy({ by: ['status'], _count: true });
  res.json({ success: true, data: stats });
}

export async function listAllCases(req: Request, res: Response): Promise<void> {
  const cases = await prisma.case.findMany({ take: 50, orderBy: { createdAt: 'desc' } });
  res.json({ success: true, data: cases });
}
