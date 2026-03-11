import { Request, Response } from 'express';

/** Placeholder: notification history and preferences controller */
export async function getNotifications(req: Request, res: Response): Promise<void> {
  res.json({ success: true, data: [], message: 'Notification history coming soon' });
}

export async function markAsRead(req: Request, res: Response): Promise<void> {
  res.json({ success: true, message: 'Marked as read' });
}
