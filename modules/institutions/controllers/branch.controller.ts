import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function getBranches(req: Request, res: Response): Promise<void> {
  const branches = await prisma.institutionBranch.findMany({
    where: { institutionId: req.params.institutionId },
  });
  res.json({ success: true, data: branches });
}

export async function addBranch(req: Request, res: Response): Promise<void> {
  const branch = await prisma.institutionBranch.create({ data: req.body });
  res.status(201).json({ success: true, data: branch });
}

export async function updateBranch(req: Request, res: Response): Promise<void> {
  const branch = await prisma.institutionBranch.update({ where: { id: req.params.id }, data: req.body });
  res.json({ success: true, data: branch });
}
