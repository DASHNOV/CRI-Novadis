# Architecture — CRI Novadis 2.0

## Monorepo

```
CRI_Novadis2.0/
├── frontend/               # Flutter app (web + Android)
├── backend/
│   ├── src/NovadisApi/     # API REST .NET 10
│   └── NovadisApi.Tests/   # Tests d'intégration
├── database/               # Scripts SQL manuels
├── docs/                   # Documentation technique
├── .github/workflows/      # CI/CD GitHub Actions
└── SECURITY.md
```

---

## Flux de données global

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                             │
│                                                             │
│  Riverpod Providers                                         │
│       │                                                     │
│  Drift (SQLite) ──── Offline cache                         │
│       │                                                     │
│  Dio (JWT interceptor + auto-refresh)                       │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTPS / JSON
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  ASP.NET Core API (.NET 10)                  │
│                                                             │
│  Middleware → Controllers → Services                        │
│                    │                                        │
│              EF Core (PostgreSQL / Npgsql)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Backend — `backend/src/NovadisApi/`

### Structure

```
NovadisApi/
├── Program.cs                     # Bootstrap
├── Controllers/                   # 10 contrôleurs
├── Models/                        # Entités EF Core
│   └── DTOs/                      # Objets de transfert
├── Services/
│   ├── Auth/                      # JwtService, AuthService, CodeGeneratorService
│   ├── Email/                     # EmailService (SMTP)
│   ├── Export/                    # XlsxExportService
│   ├── Storage/                   # LocalFileObjectStorage (MinIO-ready)
│   ├── Stats/                     # GlobalStatsService
│   └── Maintenance/               # DataRetentionService (purge RGPD)
├── Data/
│   ├── NovadisDbContext.cs
│   └── Migrations/
├── Middleware/                    # GlobalExceptionHandler
└── Attributes/                    # RoleAuthorizeAttribute
```

### Pipeline middleware (ordre d'exécution)

1. `GlobalExceptionHandler` — catch-all, retourne ProblemDetails
2. `ForwardedHeaders` — support Cloudflare / IIS proxy
3. Security headers — `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, HSTS (prod)
4. `SerilogRequestLogging` — log uniquement si >400ms ou erreur
5. Swagger — dev uniquement
6. `HttpsRedirection` — prod uniquement
7. CORS (`AllowMobileApp`)
8. `RateLimiter`
9. Authentication / Authorization
10. Controllers

### Configuration JWT

- Algorithme : HS256
- Validation : Issuer + Audience + NameIdentifier
- ClockSkew : 0 (expiration stricte)
- Header `Token-Expired` ajouté en cas de `SecurityTokenExpiredException`

### CORS (`AllowMobileApp`)

- Origines autorisées : domaines prod/dev + `localhost:*` + `192.168.*` + `10.*` + `*.vercel.app`
- Headers exposés : `Token-Expired`, `Content-Disposition`, `X-Total-Count`, `X-Page`, `X-Page-Size`, `X-Total-Pages`

### Rate limiting

| Cible | Limite dev | Limite prod |
|-------|-----------|-------------|
| Global | 100 req/min / IP | 100 req/min / IP |
| Endpoints auth | 20 req/min / IP | 5 req/min / IP |

Désactivé en environnement `Test`.

### Contrôleurs

| Contrôleur | Préfixe route | Rôle requis |
|-----------|---------------|-------------|
| `AuthController` | `api/auth` | Public (login/verify) |
| `CRIController` | `api/cri` | TechnicianOrAdmin |
| `GlobalStatsController` | `api/global` | Admin |
| `PersonalStatsController` | `api/personal` | TechnicianOrAdmin |
| `ExportController` | `api/export` | TechnicianOrAdmin |
| `ExportedDocumentsController` | `api/exported-documents` | TechnicianOrAdmin |
| `SitesController` | `api/sites` | TechnicianOrAdmin |
| `SiteSummaryController` | `api/sites` | TechnicianOrAdmin |
| `UsersController` | `api/users` | Admin |
| `HealthController` | `api/health` | Public |

### Services enregistrés (DI)

| Interface | Implémentation | Durée de vie |
|-----------|---------------|--------------|
| `IJwtService` | `JwtService` | Scoped |
| `IAuthService` | `AuthService` | Scoped |
| `ICodeGeneratorService` | `CodeGeneratorService` | Scoped |
| `IEmailService` | `EmailService` | Scoped |
| `IGlobalStatsService` | `GlobalStatsService` | Scoped |
| `ISiteSummaryService` | `SiteSummaryService` | Scoped |
| `IXlsxExportService` | `XlsxExportService` | Scoped |
| `IObjectStorageService` | `LocalFileObjectStorage` | Singleton |
| `DataRetentionService` | — | HostedService |

### Logging (Serilog)

- Console : template compact
- Fichier info : rotation quotidienne, 50 MB max, 30 jours de rétention
- Fichier erreurs : fichier séparé, 90 jours de rétention
- Niveau minimum : Information (Microsoft.AspNetCore à Warning)

---

## Base de données

### Tables (EF Core DbSets)

| DbSet | Table | Description |
|-------|-------|-------------|
| `Users` | AspNetUsers | Techniciens et admins |
| `CRIForms` | CRIForms | Formulaires d'intervention |
| `CRIPhotos` | CRIPhotos | Photos liées aux CRI |
| `Sites` | Sites | Référentiel sites NovaDIS |
| `ClientsNormalises` | Clients | Référentiel clients normalisés |
| `AuthAttempts` | AuthAttempts | Tentatives OTP |
| `UserTokens` | UserTokens | Refresh tokens JWT |
| `MagicLinks` | MagicLinks | Magic links (préparation phase 2) |
| `ExportedDocuments` | ExportedDocuments | Historique exports PDF/XLSX |
| `AuditLogs` | AuditLogs | Piste d'audit |

### Relations clés

| Relation | OnDelete |
|----------|----------|
| `CRIForm.TechnicianId → User` | Restrict |
| `CRIForm.SiteID → Site` | SetNull |
| `CRIForm.ClientID → Client` | SetNull |
| `CRIPhoto.CRIFormId → CRIForm` | Cascade |
| `UserToken.UserId → User` | Cascade |
| `ExportedDocument.UserId → User` | Cascade |

### Champs principaux de `CRIForm`

- **Identité** : `Id` (Guid PK), `TechnicianId` (FK), `InterventionType` (Project/Service)
- **Statut** : `Status` (Draft → Submitted → Validated), `CreatedAt`, `UpdatedAt`, `SubmittedAt`
- **Timing** : `InterventionDate`, `HeureDebut`, `HeureFin`, `DureeMinutes`
- **Client** : `ClientName`, `ClientSite`, `ClientContact`, `ClientEmail`, `Ville`, `CodePostal`
- **Service** : `TicketNumber`, `ResolutionStatus`
- **Projet** : `ProjectName`, `ProjectNumber`, `ProjectPhase`, `ProjectStatus`
- **Média** : `TechnicianSignature` (Base64), `ClientSignature` (Base64), `Photos` (collection)

---

## Frontend — `frontend/lib/`

### Structure

```
lib/
├── main.dart                      # Bootstrap (ProviderScope, MaterialApp.router)
├── core/
│   ├── config/
│   │   ├── app_router.dart        # GoRouter — toutes les routes
│   │   └── api_config.dart        # Base URL (dart-define > .env > fallback IP)
│   ├── network/
│   │   ├── dio_provider.dart      # Dio singleton + intercepteur JWT
│   │   └── isolate_transformer.dart
│   ├── storage/                   # SharedPreferences + SecureStorage
│   ├── theme/                     # Design tokens, light/dark, Inter
│   ├── providers/                 # main_nav_provider
│   └── widgets/                   # responsive_scaffold, protected_route
├── data/
│   ├── models/                    # CriProjetModel, CriServiceModel, SiteModel
│   ├── local/                     # Tables Drift (SQLite)
│   └── repositories/              # cri_remote_repository, site_summary_repository
├── features/
│   ├── auth/                      # LoginScreen, OtpVerificationScreen
│   ├── home/                      # HomePage
│   ├── dashboard/                 # MainDashboard, SiteDashboard, TechnicianDashboard
│   ├── cri_form/                  # Saisie CRI (Projet + Service)
│   ├── history/                   # Historique (perso + global)
│   ├── documents/                 # Exports historique + sélection + PdfViewerPage (viewer in-app)
│   ├── export/                    # Logique PDF/XLSX + opener multi-plateforme (document_opener_*)
│   └── admin/                     # AdminScreen
├── screens/                       # RoleHomeScreen (routing par rôle)
├── models/                        # Stats DTOs
├── services/                      # stats_api_service
└── utils/                         # permissions.dart
```

### Page Documents — visibilité & aperçu

- **Visibilité** : `DocumentsPage` lit `serverDocumentsProvider` (→ `GET /exported-documents`). Admin (`userRoleProvider == 'Admin'`) voit tous les exports + colonne « Utilisateur » (nom/email technicien) ; recherche par technicien incluse.
- **Ouvrir vs Télécharger** (actions distinctes) :
  - **Tap / « Ouvrir »** = aperçu, pas de téléchargement forcé.
    - **PDF (toutes plateformes)** : affiché **in-app** dans `PdfViewerPage` (package `pdfx`, `PdfViewPinch` depuis bytes). Sur web, nécessite pdf.js dans `web/index.html` (ajouté via `dart run pdfx:install_web`, CDN jsDelivr).
    - **xlsx** : non prévisualisable → opener système (`open_filex`) en natif, téléchargement sur web (`document_opener_*`).
  - **« Télécharger »** : conserve le comportement historique (`deliverXlsx` : blob web / fichier natif).
- Imports conditionnels : `document_opener_stub|web|native.dart` (même pattern que `xlsx_export_downloader_*`).

### Éditeur riche « Travail Effectué » (Markdown)

- Champ `workDescription` (Projet) / `actionsPerformed` (Service) saisi via `RichMarkdownField` (`cri_form/widgets/rich_markdown_field.dart`).
  - Barre d'outils : gras `**`, italique `*`, puces `- `, titre `## ` ; bouton plein écran (onglets Édition / Aperçu via `MarkdownBody`).
  - Enveloppe un `FormBuilderTextField` (contrôleur partagé) → validation par étape inchangée. Stockage = **chaîne Markdown** dans le champ existant (rétrocompatible, aucun changement DB/API).
- **Rendu** :
  - PDF : `pdf_builder_common._buildRichTextBlock` parse le Markdown (package `markdown`) → widgets `pw` (gras/italique/listes/titres), hauteur fixe + clip.
  - Écran (détails/historique) : `MarkdownBody` (`flutter_markdown`).
  - XLSX (backend) : `XlsxExportService.StripMarkdown` retire la syntaxe → texte brut.
- **Signature client** : `SignaturePadWidget.contextMarkdown` affiche le travail effectué (lecture seule, scrollable) dans la popup de signature, avant que le client signe.

### Intercepteur Dio (JWT auto-refresh)

**Request** : lecture du token → ajout header `Authorization: Bearer <token>`

**Error (401)** :
1. Lire le refresh token en storage
2. POST `/auth/refresh`
3. Sauvegarder les nouveaux tokens
4. Relancer la requête originale
5. Si refresh échoue : clear tokens → redirect `/login`

**Timeouts** : connect 10s / send 10s / receive 15s

**Transformer** : isolate JSON (natif) / synchrone (web)

### Cache local Drift (SQLite) — schéma v6

| Table | Colonnes clés | Statuts |
|-------|--------------|---------|
| `cri_service` | interventionDate, ticketNumber, resolutionStatus, photos, signatures, devisARealiser, facturable | syncStatus (pending/synced/failed), isDraft |
| `cri_projet` | interventionDate, projectName, projectNumber, projectPhase, softwares (JSON), photos, signatures | syncStatus, isDraft |
| `exported_document` | criId, filename, filePath, fileType, exportType, metadata (JSON) | — |

### Routes frontend (GoRouter)

| Path | Screen | Accès |
|------|--------|-------|
| `/login` | LoginScreen | Public |
| `/verify-otp` | OtpVerificationScreen | Public |
| `/home` | RoleHomeScreen | Authentifié |
| `/dashboard` | MainDashboardPage | Admin |
| `/dashboard/site/:siteId` | SiteDashboardPage | Admin |
| `/dashboard/technician/:techId` | TechnicianDashboardPage | Admin |
| `/cri-form` | CriFormScreen (choix type) | TechnicianOrAdmin |
| `/cri/new/projet` | CriProjetFormPage | TechnicianOrAdmin |
| `/cri/new/service` | CriServiceFormPage | TechnicianOrAdmin |
| `/cri/edit/:id?type=` | CriProjetFormPage / CriServiceFormPage | Propriétaire ou Admin |
| `/cri/view/:id?type=` | Lecture seule (redirige vers edit) | Propriétaire ou Admin |
| `/history` | HistoryScreen | TechnicianOrAdmin |
| `/documents` | DocumentsPage | TechnicianOrAdmin |
| `/documents/selection` | CriSelectionPage | TechnicianOrAdmin |
| `/admin` | AdminScreen | Admin |

### Rôles

| Rôle | Accès |
|------|-------|
| `Admin` | Tous les CRI, stats globales, gestion utilisateurs, tous les dashboards |
| `Technician` | Ses propres CRI uniquement, stats personnelles, dashboard perso |

---

## Flux d'authentification

```
1. Utilisateur saisit son email → POST /api/auth/login
2. API génère un code OTP → envoi par email (SMTP)
3. Utilisateur saisit le code → POST /api/auth/verify
4. API retourne access token (court) + refresh token (long)
5. Dio ajoute le token à chaque requête
6. Sur 401 : Dio appelle POST /api/auth/refresh automatiquement
7. Sur échec refresh : redirection /login
```

---

## Déploiement & CI/CD

### Frontend (Vercel)

- Trigger : push sur `dev`
- Build : `flutter build web`
- URL : `https://cri-novadis.tech`
- Workflow : `.github/workflows/deploy-vercel.yml`

### Backend (Serveur Windows interne)

- Trigger : push sur `dev` (modifications backend uniquement)
- Build : `dotnet publish -c Release`
- Déploiement :
  1. Arrêt service `NovadisApi`
  2. Copie des fichiers publiés (`.env` préservé)
  3. Redémarrage service
  4. Smoke test : GET `http://localhost:5200/api/health/live` → 200
- Workflow : `.github/workflows/deploy-api.yml`
- Credentials : clé SSH + username `Administrateur` (GitHub Secrets)

### Tests CI

- Trigger : push/PR sur `master` ou `dev`
- Backend : `dotnet test`
- Frontend : `flutter analyze` + `flutter test`
- Workflow : `.github/workflows/ci-tests.yml`
