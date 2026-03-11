import { PrismaClient } from '@prisma/client';
import { JwtService } from './jwt.service';
import { PasswordService } from './password.service';
import { getPrismaClient } from '@config/database';

export class AuthService {
  private prisma: PrismaClient = getPrismaClient();

  async login(phone: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) throw new Error('Invalid credentials');
    const valid = await PasswordService.compare(password, user.password);
    if (!valid) throw new Error('Invalid credentials');
    const token = JwtService.sign({ userId: user.id, role: user.role });
    return { token, user };
  }

  async register(data: { name: string; phone: string; password: string; role?: string }) {
    const hashed = await PasswordService.hash(data.password);
    return this.prisma.user.create({
      data: { ...data, password: hashed },
    });
  }
}

export const authService = new AuthService();
