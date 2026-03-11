# IMBONI — Architecture Overview

## Modular Domain Architecture

The system follows a strict **Modular Domain Architecture** where each sector of
citizen–institution interaction is a self-contained module.

### Layer Responsibilities

| Layer | Path | Purpose |
|-------|------|---------|
| Bootstrap | `app/` | App setup, server start, route registration |
| Config | `config/` | Environment, DB config, logger, permissions |
| Core | `core/` | Auth, Users, Roles, Notifications, Files, Audit |
| Modules | `modules/` | Domain features: governance, institutions, banks |
| Admin | `admin-panel/` | Admin-side controllers (dashboard, reporting) |
| Shared | `shared/` | Middleware, helpers, constants used across modules |
| Database | `database/` | Schema, migrations, seeders, reference data |
| API | `api/` | Gateway entry point and route barrel files |

### Key Principles
- Modules never import from each other
- All modules share `core/` and `shared/` only
- Single Prisma client via `shared/database/prisma.service.ts`
- Single JWT auth in `core/auth/`
