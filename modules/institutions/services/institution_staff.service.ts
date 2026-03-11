import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export const institutionStaffService = {
  getByInstitution: (institutionId: string) =>
    prisma.institutionStaff.findMany({
      where: { institutionId, active: true },
      include: { user: { select: { id: true, name: true, phone: true, role: true } } },
    }),

  assign: (data: { userId: string; institutionId: string; branchId?: string; role: string }) =>
    prisma.institutionStaff.create({ data: data as any }),

  deactivate: (id: string) =>
    prisma.institutionStaff.update({ where: { id }, data: { active: false } }),
};
