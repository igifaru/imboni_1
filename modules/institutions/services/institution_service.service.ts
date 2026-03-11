import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export const institutionServiceService = {
  getByInstitution: (institutionId: string) =>
    prisma.institutionService.findMany({ where: { institutionId, status: 'ACTIVE' } }),

  create: (data: any) =>
    prisma.institutionService.create({ data }),

  update: (id: string, data: any) =>
    prisma.institutionService.update({ where: { id }, data }),

  toggleStatus: async (id: string) => {
    const svc = await prisma.institutionService.findUnique({ where: { id } });
    const newStatus = svc?.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    return prisma.institutionService.update({ where: { id }, data: { status: newStatus } });
  },
};
