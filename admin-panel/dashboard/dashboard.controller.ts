import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function getDashboardStats(_req: Request, res: Response): Promise<void> {
  const [users, cases, institutions] = await Promise.all([
    prisma.user.count(),
    prisma.case.count(),
    prisma.institution.count(),
  ]);
  res.json({ success: true, data: { users, cases, institutions } });
}
