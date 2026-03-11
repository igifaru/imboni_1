import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export const branchService = {
  getByInstitution: (institutionId: string) =>
    prisma.institutionBranch.findMany({ where: { institutionId } }),

  create: (data: any) =>
    prisma.institutionBranch.create({ data }),

  update: (id: string, data: any) =>
    prisma.institutionBranch.update({ where: { id }, data }),

  delete: (id: string) =>
    prisma.institutionBranch.delete({ where: { id } }),
};
