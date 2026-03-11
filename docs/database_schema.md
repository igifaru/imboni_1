# IMBONI — Database Schema Reference

## Core Models
- **User** — All system users (citizens, leaders, staff, admins)

## Governance Module
- **Case** — Citizen-submitted issues
- **CaseUpdate** — Status history per case
- **CaseEscalation** — Escalation records
- **Project** (PFTCV) — Public fund transparency projects

## Community Module
- **Channel** — Community discussion channels
- **ChannelMembership** — User–channel relationships
- **Message** — Channel messages

## Institutions Module
- **InstitutionType** — Category (Bank, Insurance, etc.)
- **Institution** — Registered institutions
- **InstitutionBranch** — Physical branches
- **InstitutionStaff** — Staff–user assignments
- **InstitutionService** — Services offered
- **InstitutionRequest** — Citizen requests to institutions
- **RequestEscalation** — Escalation records for requests

> Full schema: see `database/schema.prisma`
