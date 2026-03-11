import { Application } from 'express';
import authRoutes from '@core/auth/auth.routes';
import userRoutes from '@core/users/user.routes';
import governanceRoutes from '@modules/governance/routes/governance.routes';
import institutionRoutes from '@modules/institutions/routes/institution.routes';
import adminRoutes from '@core/admin/admin.routes';

export function registerRoutes(app: Application): void {
  app.get('/health', (_, res) => res.json({ status: 'ok', timestamp: new Date() }));
  app.use('/api/auth', authRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api', governanceRoutes);
  app.use('/api/institutions', institutionRoutes);
  app.use('/api/admin', adminRoutes);
}
