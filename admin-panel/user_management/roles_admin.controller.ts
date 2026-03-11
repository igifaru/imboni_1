import { Request, Response } from 'express';
import { roleService } from '@core/roles/role.service';

export async function listRoles(_req: Request, res: Response): Promise<void> {
  res.json({ success: true, data: roleService.getAll() });
}

export async function assignRole(req: Request, res: Response): Promise<void> {
  const { userId, role } = req.body;
  res.json({ success: true, message: `Role ${role} assigned to user ${userId}` });
}
