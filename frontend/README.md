# Imboni Frontend

National Civic Governance Platform - Frontend Applications

## Apps

| App | Description |
|-----|-------------|
| citizen_app | Mobile app for citizens to report and track cases |
| leader_dashboard | Dashboard for leaders to manage and resolve cases |

## Shared

Common components used across all apps:
- **theme/** - App theming (light/dark modes)
- **localization/** - Multi-language support (Kinyarwanda, English, French)
- **widgets/** - Reusable UI components

## Getting Started

```bash
# Citizen App
cd apps/citizen_app
flutter pub get
flutter run

# Leader Dashboard
cd apps/leader_dashboard
flutter pub get
flutter run
```

## Features

### Citizen App
- Submit cases (anonymous option available)
- Track case status
- Receive notifications
- Emergency reporting

### Leader Dashboard
- View assigned cases
- Escalation alerts
- Performance metrics
- Case resolution
