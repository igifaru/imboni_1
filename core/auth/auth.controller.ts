import { Request, Response } from 'express';
import { authService } from './auth.service';

export async function login(req: Request, res: Response): Promise<void> {
  try {
    const { phone, password } = req.body;
    const result = await authService.login(phone, password);
    res.json({ success: true, data: result });
  } catch (err: any) {
    res.status(401).json({ success: false, error: err.message });
  }
}

export async function register(req: Request, res: Response): Promise<void> {
  try {
    const user = await authService.register(req.body);
    res.status(201).json({ success: true, data: user });
  } catch (err: any) {
    res.status(400).json({ success: false, error: err.message });
  }
}
