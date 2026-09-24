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
└── Authorization/                 # Capabilities (capacités + matrice rôle → capacités)
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

- Origines autorisées : liste exacte `Cors:AllowedOrigins` ; en dev seulement, `localhost:*` + `192.168.*` + `10.*`
- Pas de joker `*.vercel.app` (retiré, étape 2.3) : une preview à autoriser s'ajoute explicitement à la liste
- Headers exposés : `Token-Expired`, `Content-Disposition`, `X-Total-Count`, `X-Page`, `X-Page-Size`, `X-Total-Pages`

### Rate limiting

| Cible | Limite dev | Limite prod |
|-------|-----------|-------------|
| Global | 100 req/min / IP | 100 req/min / IP |
| Endpoints auth | 20 req/min / IP | 5 req/min / IP |

Désactivé en environnement `Test`.

### Verrouillage OTP (`AuthService.GetLockoutAsync`)

- ≥ `Auth:MaxFailedAttempts` (5) codes erronés sur `Auth:LockoutDurationMinutes` (30 min), toutes demandes de code confondues → **429** sur `/login` et `/verify`, même avec un code correct
- Par e-mail, pas par IP (indépendant du rate limiting) — un tiers peut verrouiller un compte : compromis assumé
- Connexion réussie → `FailedAttempts = 0` sur les tentatives de l'e-mail

### Contrôleurs

| Contrôleur | Préfixe route | Autorisation (capacité) |
|-----------|---------------|-------------|
| `AuthController` | `api/auth` | Public (login/verify) |
| `CRIController` | `api/cri` | Authentifié ; écritures → `CriCreate` ; lecture d'autrui → `CriReadAll` ; brouillon / suppression d'autrui → `CriManageAny` |
| `GlobalStatsController` | `api/global` | `GlobalStats` |
| `PersonalStatsController` | `api/personal` | `PersonalStats` |
| `ExportController` | `api/export` | Authentifié ; portée « global » → `ExportAll` |
| `ExportedDocumentsController` | `api/exported-documents` | Authentifié ; docs d'autrui : lecture → `DocumentsReadAll`, gestion → `DocumentsManageAny` |
| `SitesController` | `api/sites` | Authentifié ; `POST /import` → `SystemAdmin` |
| `SiteSummaryController` | `api/sites` | Authentifié |
| `UsersController` | `api/users` | Authentifié (`technicians`, `me`, `me/signature`) |
| `HealthController` | `api/health` | `SystemAdmin` (sauf `/live` et `/ready`, publics) |

- Une policy ASP.NET par capacité, générée depuis `Authorization/Capabilities.cs` (`RolesByCapability`) — seule source de vérité.
- Contrôle inline (propriété) : `User.HasCapability(Capabilities.X)`.

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
│   ├── history/                   # Historique (perso + global) — carte CRI partagée : widgets/cri_card.dart
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
- `RichMarkdownField.controller` (optionnel) : contrôleur fourni par le parent pour injecter du texte (modèles). Sans lui, le champ garde son contrôleur interne (dispose côté widget).

### Modèle « Maintenance préventive » (CRI Service)

- **Déclencheur** : bouton « Utiliser le modèle Maintenance préventive » affiché dans l'étape *Intervention* **uniquement si** `requestType == ServiceRequestType.maintenancePreventive`.
- **Données** : `cri_form/data/preventive_maintenance_template.dart` — en dur, aucun stockage DB/API.
  - Blocs : *Base commune* (toujours coché), *Contrôle d'accès — Amadeus8* (systèmes contrôle d'accès / intrusion / hypervision), *Vidéo* (système vidéo, choix QVMS | Ocularis | Milestone XProtect).
  - Pré-cochage automatique selon `cri.systemTypes` (saisis à l'étape *Demande*).
  - Lignes « mise à jour » = champ libre version/licence, accolé entre parenthèses.
- **UI** : `cri_form/widgets/preventive_template_sheet.dart` (bottom-sheet cases à cocher + aperçu `MarkdownBody`) → retourne le Markdown, `null` si annulé.
- **Insertion** : liste à puces (`- `) dans `actionsPerformed`. Champ déjà rempli → dialogue **Remplacer / Ajouter à la suite / Annuler**. Sync contrôleur + `FormBuilder.didChange` + `updateInterventionInfo` (jamais d'écrasement silencieux).

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
| `/home` | RoleHomeScreen (Technician → TechnicianMainScreen ; Admin / Supervisor → AdminMainScreen ; inconnu → « Rôle non pris en charge ») | Authentifié |
| `/dashboard` | MainDashboardPage (mode global si `GlobalStats`) | Authentifié |
| `/dashboard/site/:siteId` | SiteDashboardPage | `GlobalStats` |
| `/dashboard/technician/:techId` | TechnicianDashboardPage | `GlobalStats` |
| `/cri-form` | CriFormScreen (choix type) | `CriCreate` |
| `/cri/new/projet` | CriProjetFormPage | `CriCreate` |
| `/cri/new/service` | CriServiceFormPage | `CriCreate` |
| `/cri/edit/:id?type=` | CriProjetFormPage / CriServiceFormPage | `CriCreate` (+ propriété vérifiée par l'API) |
| `/cri/view/:id?type=` | Lecture seule (redirige vers edit) | `CriCreate` |
| `/history` | HistoryScreen | Authentifié |
| `/documents` | DocumentsPage | Authentifié |
| `/documents/selection` | CriSelectionPage | Authentifié |
| `/admin` | AdminScreen (paramètres, déconnexion) | Authentifié |

- Garde : `AppRouter.requiredPermission()` + `redirect` → `/home` si la permission manque. Filet d'UX : l'API reste seule garante.
- `AdminMainScreen` = espace de gestion commun Admin / Supervisor ; chaque onglet porte sa permission.

### Rôles

| Rôle | Accès |
|------|-------|
| `Technician` | Ses propres CRI (création, modification, suppression de brouillons), stats personnelles, ses exports |
| `Admin` | Tout : CRI de tous (modif. des brouillons, suppression), stats globales, dashboards, exports globaux, docs de tous, import sites, santé API |
| `Supervisor` | Lecture seule : CRI de tous, stats globales, dashboards, exports globaux, docs de tous (gère seulement les siens). Aucune écriture sur les CRI |

- Matrice détaillée : `docs/plan-role-superviseur.md` §4 ; code : `Authorization/Capabilities.cs` (back) et `core/constants/permissions.dart` (front), à garder identiques.
- Rôle inconnu en base : connexion refusée (`User.CanSignIn`), jamais traité comme technicien.
- Pas de gestion utilisateurs via l'API : comptes et rôles gérés en base (SQL).

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

Branches : `main` = **production** (seule à déployer), `dev` = développement (tests seulement).
Procédure d'exploitation complète : `docs/deployment.md`.

### Tests CI (`ci-tests.yml`)

- Déclencheurs : PR vers `main`/`dev`, push sur `dev`, et **appel par les deux workflows de déploiement** (`workflow_call`)
- Backend : `dotnet test` ; Frontend : `flutter analyze` + `flutter test` (Flutter épinglé 3.41.4)
- Sur `main`, un test en échec **bloque** le déploiement (`needs: tests`)

### Frontend (`deploy-vercel.yml`)

- Push sur `main` touchant `frontend/**` → tests → `vercel deploy --prod` → `https://cri-novadis.tech`

### Backend (`deploy-api.yml` + `scripts/deploy-remote.sh`)

- Push sur `main` touchant `backend/**`, `docker-compose.yml` ou le script ; ou lancement manuel
- Tests → image `cri-novadis-api:<sha>` → scp vers le serveur → `deploy-remote.sh` :
  1. mémorise l'image en service
  2. dump pré-déploiement `backups/db_predeploy_<date>_<sha7>.sql.gz` (**bloquant** : les migrations s'appliquent au démarrage)
  3. `docker load`, retag `:latest`, `docker compose up -d`
  4. attente `/api/health/ready` = 200 (150 s max)
  5. échec → journaux, retour sur l'image précédente, job en **échec**
- Conserve les 5 dernières images taguées ; `concurrency` : un seul déploiement à la fois
- ⚠️ Le retour arrière d'image ne défait pas une migration : restaurer le dump pré-déploiement si besoin
