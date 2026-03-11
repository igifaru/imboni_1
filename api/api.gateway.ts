/**
 * API Gateway
 * Central barrel file — import from here in app/routes.ts
 * to keep route registration clean.
 */
export { default as authRoutes }        from './routes/auth.routes';
export { default as governanceRoutes }  from './routes/governance.routes';
export { default as institutionRoutes } from './routes/institution.routes';
