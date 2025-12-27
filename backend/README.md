# Imboni Backend

National Civic Governance Platform - Backend Services

## Architecture

Microservices architecture built with Node.js/NestJS following clean architecture principles.

## Services

| Service | Port | Description |
|---------|------|-------------|
| api-gateway | 3000 | Authentication, rate limiting, routing |
| case-service | 3001 | Case management, CRUD operations |
| escalation-service | 3002 | Automatic escalation logic |
| notification-service | 3003 | SMS, Email, Push notifications |
| audit-service | 3004 | Immutable audit logging |
| integration-service | 3005 | Government & NGO integrations |

## Getting Started

```bash
# Install dependencies
npm install

# Setup database
cd prisma && npx prisma migrate dev

# Start services
docker-compose up -d
```

## Core Design Principles

- **Time-bound governance**: Every case has a deadline
- **Non-blockable escalation**: System-enforced escalation
- **Anonymity by design**: Identity separated from case data
- **Immutable audit trail**: No deletions allowed
