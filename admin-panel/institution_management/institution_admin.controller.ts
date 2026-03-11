import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function listInstitutions(_req: Request, res: Response): Promise<void> {
  const institutions = await prisma.institution.findMany({ include: { type: true, _count: { select: { branches: true } } } });
  res.json({ success: true, data: institutions });
}
