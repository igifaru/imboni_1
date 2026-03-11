import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function listStaff(req: Request, res: Response): Promise<void> {
  const staff = await prisma.institutionStaff.findMany({ where: { institutionId: req.params.id }, include: { user: true } });
  res.json({ success: true, data: staff });
}
