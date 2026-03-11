import { getPrismaClient } from '@config/database';

const prisma = getPrismaClient();

export const requestService = {
  submit: (data: any) =>
    prisma.institutionRequest.create({ data }),

  getByUser: (citizenId: string) =>
    prisma.institutionRequest.findMany({
      where: { citizenId },
      include: { institution: true, branch: true, service: true },
      orderBy: { createdAt: 'desc' },
    }),

  getByInstitution: (institutionId: string) =>
    prisma.institutionRequest.findMany({
      where: { institutionId },
      include: { citizen: { select: { id: true, name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
    }),

  updateStatus: (id: string, status: string) =>
    prisma.institutionRequest.update({
      where: { id },
      data: { status, ...(status === 'RESOLVED' && { resolvedAt: new Date() }) },
    }),

  escalate: (data: { requestId: string; fromRole: string; toRole: string; reason: string; escalatedBy: string }) =>
    prisma.requestEscalation.create({ data }),
};
