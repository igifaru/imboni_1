import { getPrismaClient } from '@config/database';
import { CreateUserDto, UpdateUserDto } from './user.model';

const prisma = getPrismaClient();

export const userRepository = {
  findById:    (id: string)     => prisma.user.findUnique({ where: { id } }),
  findByPhone: (phone: string)  => prisma.user.findUnique({ where: { phone } }),
  findAll:     (skip = 0, take = 20) => prisma.user.findMany({ skip, take, orderBy: { createdAt: 'desc' } }),
  create:      (data: CreateUserDto) => prisma.user.create({ data: data as any }),
  update:      (id: string, data: UpdateUserDto) => prisma.user.update({ where: { id }, data }),
  delete:      (id: string)     => prisma.user.delete({ where: { id } }),
  count:       ()               => prisma.user.count(),
};
