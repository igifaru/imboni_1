import { Request, Response, NextFunction } from 'express';
import { Permission } from '@config/permissions';
import { roleService } from './role.service';

export function requirePermission(permission: Permission) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = (req as any).user;
    if (!user) { res.status(401).json({ error: 'Unauthorized' }); return; }
    if (!roleService.hasPermission(user.role, permission)) {
      res.status(403).json({ error: 'Forbidden: insufficient permissions' }); return;
    }
    next();
  };
}
