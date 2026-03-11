import { Request, Response } from 'express';
import { userService } from '@core/users/user.service';

export async function listUsers(req: Request, res: Response): Promise<void> {
  const { page = '1', limit = '20' } = req.query as Record<string, string>;
  const users = await userService.getAll(+page, +limit);
  res.json({ success: true, data: users });
}

export async function suspendUser(req: Request, res: Response): Promise<void> {
  res.json({ success: true, message: `User ${req.params.id} suspended` });
}
