import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function listBranches(req: Request, res: Response): Promise<void> {
  const branches = await prisma.institutionBranch.findMany({ where: { institutionId: req.params.id } });
  res.json({ success: true, data: branches });
}
