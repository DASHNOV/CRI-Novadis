# CRI Novadis 2.0

Application de gestion des **Comptes Rendus d'Intervention** (CRI) — web et mobile.

## Stack

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter/Dart (web + Android) |
| Backend | ASP.NET Core (.NET 10) |
| Base de données | PostgreSQL via Npgsql + EF Core |
| Auth | Magic link OTP → JWT (access + refresh) |
| CI/CD | GitHub Actions + Vercel + serveur Windows interne |

## Prérequis

- [Flutter](https://flutter.dev) stable (Dart ≥ 3.5)
- [.NET 10 SDK](https://dotnet.microsoft.com)
- PostgreSQL 16 (local ou distant ; `docker-compose` fournit `postgres:16-alpine`)
- Accès SMTP pour les magic links

## Installation

### Backend

```bash
cd backend/src/NovadisApi
cp .env.example .env          # remplir les variables
dotnet restore
dotnet run                     # écoute sur http://0.0.0.0:5200
```

Swagger disponible à la racine : `http://localhost:5200/`

### Frontend

```bash
cd frontend
cp .env.example .env           # définir API_URL
flutter pub get
flutter run -d chrome          # web
flutter run -d <device_id>     # mobile
```

### Variables d'environnement

**Backend** (`backend/src/NovadisApi/.env`) :
```
ConnectionStrings__DefaultConnection=Server=...
Jwt__Secret=...
Email__SmtpHost=...
Email__SmtpPort=...
Email__From=...
```

**Frontend** (`frontend/.env`) :
```
API_URL=https://api.cri-novadis.tech/api
```

Ordre de priorité frontend : `--dart-define=API_URL` > `.env` > IP fallback.

## Fonctionnalités

- **CRI Projet / Service** — saisie structurée avec photos et signature
- **Export** — XLSX et PDF par CRI ou par période
- **Historique** — consultation et filtrage des interventions passées
- **Tableaux de bord** — stats personnelles (technicien) et globales (admin)
- **Recherche** — clients et sites via import CSV
- **Rôles** — `Technician` (ses propres CRI) / `Admin` (tous les CRI + stats globales)
- **RGPD** — purge automatique des données selon rétention configurée

## Architecture

```
CRI_Novadis2.0/
├── backend/
│   ├── src/NovadisApi/          # API REST (.NET 10)
│   │   ├── Controllers/         # 10 contrôleurs (Auth, CRI, Stats, Export…)
│   │   ├── Models/              # Entités EF Core
│   │   ├── Services/            # Auth, Email, Export, Stats, Storage
│   │   └── Migrations/          # Migrations EF Core
│   └── NovadisApi.Tests/        # Tests d'intégration
├── frontend/
│   └── lib/
│       ├── core/                # Router, Dio, thème, storage
│       ├── data/                # Modèles, repos, cache Drift (SQLite)
│       └── features/            # auth, cri_form, history, dashboard, export…
├── docs/                        # Documentation technique
├── .github/workflows/           # CI/CD (tests, deploy API, deploy Vercel)
└── SECURITY.md
```

Voir [`docs/architecture.md`](docs/architecture.md) pour le schéma détaillé.

## URLs

| Environnement | URL |
|---------------|-----|
| API production | `https://api.cri-novadis.tech/api` |
| API locale | `http://192.168.70.114:5200/api` |
| Swagger | racine de l'API (`/`) |

## CI/CD

| Workflow | Déclencheur | Action |
|----------|-------------|--------|
| `ci-tests.yml` | push/PR sur `main`/`dev` | Tests backend (.NET) + frontend (Flutter) |
| `deploy-api.yml` | push sur `main` (backend ou `docker-compose.yml` modifié) | Build + déploiement de l'API sur le VPS |
| `deploy-vercel.yml` | push sur `main` (frontend modifié) | Build Flutter web + déploiement Vercel |

`main` est la branche de **production**, `dev` la branche de développement.
Flux nominal : `feature/xxx` → `dev` (tests) → `main` (tests + déploiement).

## Documentation

| Fichier | Contenu |
|---------|---------|
| [`docs/architecture.md`](docs/architecture.md) | Structure, flux de données, routes, rôles |
| [`docs/api-summary.md`](docs/api-summary.md) | Tous les endpoints avec méthode, auth et description |
| [`docs/conventions.md`](docs/conventions.md) | Conventions de code, nommage, Git |
| [`docs/resolved-issues.md`](docs/resolved-issues.md) | Bugs complexes résolus avec cause et prévention |
| [`SECURITY.md`](SECURITY.md) | Politique de sécurité |

## Build production

```bash
# Frontend web (Vercel)
./build_vercel.sh

# Frontend Android
cd frontend && flutter build apk --release

# Backend
cd backend/src/NovadisApi && dotnet publish -c Release
```
