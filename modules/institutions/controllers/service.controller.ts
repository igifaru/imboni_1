import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function getServices(req: Request, res: Response): Promise<void> {
  const services = await prisma.institutionService.findMany({
    where: { institutionId: req.params.institutionId },
  });
  res.json({ success: true, data: services });
}

export async function addService(req: Request, res: Response): Promise<void> {
  const service = await prisma.institutionService.create({ data: req.body });
  res.status(201).json({ success: true, data: service });
}
