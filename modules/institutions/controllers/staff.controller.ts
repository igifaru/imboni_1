import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function getStaff(req: Request, res: Response): Promise<void> {
  const staff = await prisma.institutionStaff.findMany({
    where: { institutionId: req.params.institutionId },
    include: { user: { select: { id: true, name: true, phone: true } } },
  });
  res.json({ success: true, data: staff });
}

export async function assignStaff(req: Request, res: Response): Promise<void> {
  const { userId, institutionId, branchId, role } = req.body;
  const staff = await prisma.institutionStaff.create({
    data: { userId, institutionId, branchId, role },
  });
  res.status(201).json({ success: true, data: staff });
}
