import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function listServices(req: Request, res: Response): Promise<void> {
  const services = await prisma.institutionService.findMany({ where: { institutionId: req.params.id } });
  res.json({ success: true, data: services });
}
