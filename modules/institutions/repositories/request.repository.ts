import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export const requestRepository = {
  create: (data: any) =>
    prisma.institutionRequest.create({ data }),

  findByUser: (citizenId: string) =>
    prisma.institutionRequest.findMany({ where: { citizenId }, orderBy: { createdAt: 'desc' } }),

  findByInstitution: (institutionId: string) =>
    prisma.institutionRequest.findMany({ where: { institutionId }, orderBy: { createdAt: 'desc' } }),

  findById: (id: string) =>
    prisma.institutionRequest.findUnique({ where: { id } }),

  updateStatus: (id: string, status: string) =>
    prisma.institutionRequest.update({ where: { id }, data: { status } }),

  createEscalation: (data: any) =>
    prisma.requestEscalation.create({ data }),
};
