import { Request, Response } from 'express';
import { userService } from './user.service';

export async function getAllUsers(req: Request, res: Response): Promise<void> {
  const { page = '1', limit = '20' } = req.query as Record<string, string>;
  const users = await userService.getAll(+page, +limit);
  res.json({ success: true, data: users });
}

export async function getUserById(req: Request, res: Response): Promise<void> {
  const user = await userService.getById(req.params.id);
  if (!user) { res.status(404).json({ success: false, error: 'User not found' }); return; }
  res.json({ success: true, data: user });
}

export async function updateUser(req: Request, res: Response): Promise<void> {
  const user = await userService.update(req.params.id, req.body);
  res.json({ success: true, data: user });
}

export async function deleteUser(req: Request, res: Response): Promise<void> {
  await userService.delete(req.params.id);
  res.json({ success: true, message: 'User deleted' });
}
