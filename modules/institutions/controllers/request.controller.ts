import { Request, Response } from 'express';
import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export async function submitRequest(req: Request, res: Response): Promise<void> {
  const citizenId = (req as any).user?.userId;
  const request = await prisma.institutionRequest.create({
    data: { ...req.body, citizenId },
  });
  res.status(201).json({ success: true, data: request });
}

export async function getMyRequests(req: Request, res: Response): Promise<void> {
  const citizenId = (req as any).user?.userId;
  const requests = await prisma.institutionRequest.findMany({
    where: { citizenId },
    include: { institution: true, branch: true, service: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ success: true, data: requests });
}

export async function updateRequestStatus(req: Request, res: Response): Promise<void> {
  const { status, notes } = req.body;
  const request = await prisma.institutionRequest.update({
    where: { id: req.params.id },
    data: { status, ...(status === 'RESOLVED' && { resolvedAt: new Date() }) },
  });
  res.json({ success: true, data: request });
}
