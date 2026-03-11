# IMBONI — Citizen–Institution Interaction Platform

> **Imboni** means *"the one who sees"* in Kinyarwanda.  
> A platform enabling citizens to interact transparently with governance and public institutions.

---

## Project Structure

```
imboni/
├── api/                        # API layer
│   └── gateway/
│       └── main.ts             # Express gateway entry point (port 3000)
│
├── config/
│   └── config.service.ts       # Centralised configuration (env vars)
│
├── core/                       # Shared cross-cutting concerns
│   ├── admin/
│   │   └── admin.routes.ts     # Admin API routes (system-level)
│   ├── audit_logs/
│   │   └── audit-logger.ts     # Audit logging service
│   ├── auth/
│   │   ├── auth.routes.ts      # Authentication endpoints
│   │   ├── jwt.middleware.ts   # JWT guard middleware
│   │   ├── jwt.service.ts      # Token creation / verification
│   │   └── password.service.ts # Bcrypt hashing
│   ├── notifications/
│   │   ├── email/              # Email handler (SMTP)
│   │   ├── push/               # Firebase push notifications
│   │   ├── sms/                # Africa's Talking SMS
│   │   └── messaging.service.ts
│   └── users/
│       └── user.routes.ts      # User management endpoints
│
├── modules/                    # Domain feature modules (isolated)
│   ├── governance/             # Civic / governance module
│   │   ├── controllers/        # case, community, pftcv controllers
│   │   ├── dto/                # case.dto, community.dto
│   │   ├── entities/           # case.entity
│   │   ├── repositories/       # case.repository, assignment.utils
│   │   ├── rules/              # escalation.rules
│   │   ├── schedulers/         # escalation.scheduler
│   │   └── services/           # case, community, pftcv, escalation-engine
│   │
│   ├── institutions/           # Institutions module (banks, insurance, etc.)
│   │   ├── controllers/        # institution.controller
│   │   ├── dto/                # institution.dto
│   │   ├── repositories/       # institution.repository
│   │   ├── routes/             # institution.routes
│   │   └── services/           # institution.service
│   │
│   └── banks/                  # Legacy bank module (being migrated)
│       ├── controllers/        # bank.controller
│       └── services/           # bank.service
│
├── shared/                     # Utilities shared across all modules
│   ├── database/
│   │   └── prisma.service.ts   # Singleton Prisma client
│   ├── helpers/
│   │   └── logging/
│   │       └── logger.service.ts
│   └── middleware/
│       ├── rate-limit.middleware.ts
│       └── upload.middleware.ts
│
├── database/                   # Database layer
│   ├── data/                   # Static reference data (JSON)
│   ├── migrations/             # Prisma migration history
│   ├── seeders/                # Seed scripts
│   └── schema.prisma           # Single source of truth for DB schema
│
├── docker/                     # Container configuration
│   ├── docker-compose.yml
│   ├── api-gateway.Dockerfile
│   └── pftcv-service.Dockerfile
│
├── scripts/                    # One-off utility / debug scripts
│
├── docs/                       # Documentation & legacy archives
│   ├── archive/                # Old microservice entry-points (reference only)
│   └── BACKEND_README.md
│
├── frontend/                   # Flutter mobile + web app
│   └── lib/
│       ├── admin/              # Admin dashboard screens
│       ├── citizen/            # Citizen-facing screens
│       ├── institutions/       # Institution module (models, service, screens)
│       ├── bank/               # Legacy bank module
│       ├── leader/             # Leader dashboard
│       └── shared/             # Shared widgets, services, theme
│
├── .env                        # Environment variables (not committed)
├── .env.example                # Environment template
├── package.json                # Root npm scripts
└── tsconfig.json               # TypeScript config with path aliases
```

---

## Architecture Principles

| Principle | Description |
|-----------|-------------|
| **Modular Domain** | Each sector (governance, institutions) is a self-contained module |
| **Isolation** | Modules never import from each other — only from `core/` and `shared/` |
| **Single Auth** | One JWT-based auth system in `core/auth/` serves all modules |
| **Database-driven** | No static mocks — everything reads from PostgreSQL via Prisma |
| **Single Gateway** | All traffic enters via `api/gateway/main.ts` on port 3000 |

---

## Getting Started

### Prerequisites
- Node.js 20+
- PostgreSQL 14+
- Flutter 3.x

### Backend
```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your database credentials

# Run migrations
npx prisma migrate dev

# Seed initial data
npx ts-node -r tsconfig-paths/register database/seeders/seed.ts

# Start development server
npm run dev
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

---

## API Endpoints (base: `http://localhost:3000/api`)

| Module | Base Path | Description |
|--------|-----------|-------------|
| Auth | `/auth` | Login, register, refresh token |
| Users | `/users` | User management |
| Cases | `/cases` | Governance case submission & tracking |
| Community | `/community` | Community channels & discussions |
| PFTCV | `/projects` | Public fund transparency |
| Institutions | `/institutions` | Institution registration & citizen requests |
| Banks (legacy) | `/banks` | Legacy bank module |
| Admin | `/admin` | System administration |

---

## Path Aliases (tsconfig)

| Alias | Points to |
|-------|-----------|
| `@core/*` | `core/*` |
| `@modules/*` | `modules/*` |
| `@shared/*` | `shared/*` |
| `@config/*` | `config/*` |
| `@api/*` | `api/*` |
| `@database/*` | `database/*` |
