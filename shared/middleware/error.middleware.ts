import { Request, Response, NextFunction } from 'express';
import { logger } from '@config/logger';

export function errorMiddleware(
  err: Error, req: Request, res: Response, _next: NextFunction
): void {
  logger.error('Unhandled error', { message: err.message, stack: err.stack, path: req.path });
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { detail: err.message }),
  });
}
