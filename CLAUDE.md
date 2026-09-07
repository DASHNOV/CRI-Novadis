# Novadis CRI 2.0

## Stack
- **Frontend**: Flutter/Dart (web + mobile) — `frontend/`
- **Backend**: ASP.NET Core (.NET 10) — `backend/src/NovadisApi/`
- **DB**: PostgreSQL (Npgsql + EF Core), migrations manuelles
- **Auth**: Magic link OTP → JWT (access + refresh)

## Commandes

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d chrome          # web dev
flutter run -d <device_id>     # mobile
flutter build web              # production web
flutter build apk --release    # production Android
```

### Backend (.NET)
```bash
cd backend/src/NovadisApi
dotnet build
dotnet run                     # écoute http://0.0.0.0:5200
```

### Vercel Deploy (web)
```bash
./build_vercel.sh
```

## URLs
- API prod : `https://api.cri-novadis.tech/api`
- API locale : `http://192.168.70.114:5200/api`
- Swagger : racine de l'API (`/`)

## Documentation
- Architecture : `docs/architecture.md`
- Conventions : `docs/conventions.md`
- API : `docs/api-summary.md`
- Base de données (MCD/MLD) : `docs/database-mcd-mld.md`
- Incidents résolus : `docs/resolved-issues.md`
- Sécurité : `SECURITY.md`

## Config
- Frontend env : `frontend/.env` (API_URL)
- Backend env : `backend/src/NovadisApi/.env` (ConnectionStrings, Jwt, Email)
- Config cascade frontend : `--dart-define=API_URL` > `.env` > fallback IP

## Maintenance de la Documentation

### Règles post-tâche
- Après chaque tâche majeure ou modification d'architecture, mettre à jour systématiquement les fichiers dans `docs/` (`architecture.md`, `conventions.md`, `api-summary.md`) pour refléter l'état actuel.
- Utiliser un style télégraphique et des listes à puces pour ces mises à jour afin d'économiser les tokens.
- Après chaque résolution de bug complexe ou erreur de logique, documenter immédiatement l'incident dans `docs/resolved-issues.md`.

### Directive de priorité — Bugs & implémentations
- **Avant de proposer une solution à un bug ou une implémentation technique, consulter toujours `docs/resolved-issues.md`** pour vérifier si un problème similaire a déjà été traité.
- S'appuyer sur les règles de prévention déjà documentées pour éviter les régressions.

### Nettoyage & Contexte
- **[AUDIT_CLEAN]** : Quand je tape la commande `[AUDIT_CLEAN]`, tu dois scanner le projet à la recherche de fichiers orphelins ou inutilisés, me présenter un rapport, et me demander l'autorisation de les supprimer.
