import { Response } from 'express';

export const respond = {
  ok:      (res: Response, data: any, meta?: any) => res.json({ success: true, data, ...(meta && { meta }) }),
  created: (res: Response, data: any)             => res.status(201).json({ success: true, data }),
  noContent:(res: Response)                       => res.status(204).send(),
  badRequest:(res: Response, error: string)       => res.status(400).json({ success: false, error }),
  unauthorized:(res: Response, msg = 'Unauthorized') => res.status(401).json({ success: false, error: msg }),
  forbidden: (res: Response, msg = 'Forbidden')   => res.status(403).json({ success: false, error: msg }),
  notFound:  (res: Response, msg = 'Not found')   => res.status(404).json({ success: false, error: msg }),
  serverError:(res: Response, err: any)           => res.status(500).json({ success: false, error: err?.message ?? 'Server error' }),
};
