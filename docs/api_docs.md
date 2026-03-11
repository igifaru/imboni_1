# IMBONI — API Documentation

Base URL: `http://localhost:3000/api`

## Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login with phone + password |
| POST | `/auth/register` | Register new user |
| POST | `/auth/refresh` | Refresh JWT token |

## Governance
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/cases` | Submit a new case |
| GET | `/cases` | Get user's cases |
| GET | `/cases/:id` | Get case details |
| PATCH | `/cases/:id/status` | Update case status (leader) |
| POST | `/cases/:id/escalate` | Escalate case |

## Institutions
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/institutions` | List institutions |
| POST | `/institutions` | Register institution (admin) |
| GET | `/institutions/:id` | Institution details |
| GET | `/institutions/:id/branches` | List branches |
| POST | `/institutions/requests` | Submit citizen request |
| GET | `/institutions/my-requests` | Get own requests |
| PATCH | `/institutions/requests/:id/status` | Update request status |
