# Plan — Rôle Superviseur (lecture seule) + autorisations par capacité

> Plan d'exécution à suivre étape par étape. Cocher chaque case une fois faite **et vérifiée**.
> Avant chaque étape : relire `docs/resolved-issues.md` (règle `CLAUDE.md`).
> Rédigé le 2026-09-24 — branche de travail : `feat/role-superviseur` (depuis `dev`).

---

## 1. Objectif

Ajouter un rôle **`Supervisor`** (affiché « Superviseur ») : il voit tout, il n'écrit rien sur les CRI.
En profiter pour remplacer les tests de rôle dispersés (`User.IsInRole("Admin")`, `role == 'Admin'`) par des **capacités** nommées, définies en un seul endroit côté back et côté front.

## 2. Décisions validées

| Sujet | Décision |
|---|---|
| Valeur technique | `Supervisor` (base + JWT), libellé UI « Superviseur » |
| Périmètre | **Tous les CRI** de tous les techniciens — pas de notion d'équipe, pas de changement de schéma |
| Création / modification / suppression de CRI | ❌ Interdit, y compris photos |
| Signature client (`PATCH /cri/{id}/signature`, `MANUAL_VALIDATION`) | ❌ Interdit (lecture stricte) |
| Exports PDF / XLSX | ✅ Portée globale (tous les techniciens) |
| Documents exportés | ✅ Voit ceux de tous · gère (renommer / supprimer / partager) **uniquement les siens** |
| Stats globales + dashboards (global, site, technicien) + résumé de site | ✅ |
| Stats personnelles (`/api/personal`) | ❌ (il n'a pas de CRI) |
| Import sites, santé API | ❌ (réservé Admin) |
| Supports | Web + mobile, sans brouillons ni synchro hors ligne |
| Création des comptes | SQL en base (pas d'écran de gestion) |
| Architecture | Refonte par capacités (back + front) |

## 3. Constats de départ (à ne pas oublier)

- ⚠️ **Policy `TechnicianOrAdmin` déclarée mais jamais appliquée** (`Program.cs:100`). `CRIController`, `ExportController`, `ExportedDocumentsController`, `SitesController`, `SiteSummaryController`, `UsersController` n'ont que `[Authorize]` → tout rôle authentifié peut aujourd'hui créer un CRI. `docs/architecture.md` (tableau des contrôleurs) est faux sur ce point.
- ⚠️ **Rôle inconnu = technicien**, des deux côtés : `UserRoleExtensions.FromString` (back) et `UserRole.fromString` (front, `orElse`). Un compte `Supervisor` créé avant la mise à jour du code serait traité en technicien → pourrait créer des CRI. **Aucun compte superviseur avant la fin de la phase 2.**
- Deux mécanismes d'autorisation coexistent : policies ASP.NET (`[Authorize(Roles/Policy)]`) et filtre maison `RoleAuthorizeAttribute`. Cible : policies uniquement.
- Signature client : déjà en « propriétaire strict » (`CRIController.cs:234`), pas de bypass admin.
- Routeur Flutter (`core/config/app_router.dart`) : **aucune garde par rôle**. La sécurité réelle est côté API ; le front ne fait que masquer.

## 4. Matrice cible des capacités

| Capacité | Technician | Admin | Supervisor | Utilisée par |
|---|:-:|:-:|:-:|---|
| `CriCreate` | ✅ | ✅ | ❌ | `POST /cri`, `POST /cri/{id}/photos` |
| `CriReadAll` | ❌ | ✅ | ✅ | `GET /cri`, `GET /cri/{id}`, `GET photo` (sinon : propriétaire) |
| `CriManageAny` | ❌ | ✅ | ❌ | `PUT` brouillon d'autrui, `DELETE /cri/{id}`, `DELETE photo` d'autrui |
| `PersonalStats` | ✅ | ✅ | ❌ | `/api/personal` |
| `GlobalStats` | ❌ | ✅ | ✅ | `/api/global`, dashboards |
| `ExportAll` | ❌ | ✅ | ✅ | `/api/export` portée « global » (sinon « personnel ») |
| `DocumentsReadAll` | ❌ | ✅ | ✅ | `GET /exported-documents`, `download` |
| `DocumentsManageAny` | ❌ | ✅ | ❌ | `rename` / `delete` / `mark-shared` des docs d'autrui |
| `SystemAdmin` | ❌ | ✅ | ❌ | `POST /sites/import`, `/api/health`, `/health/stats` |

Règles invariantes (inchangées) :
- Écrire sur un CRI exige `CriCreate` **et** (propriétaire **ou** `CriManageAny` pour un brouillon).
- CRI **soumis** : modifiable par son propriétaire seulement (pas de dérogation Admin).
- Signature client : propriétaire strict.

---

## 5. Étapes

### Phase 0 — Préparation
- [ ] `git checkout dev && git pull && git checkout -b feat/role-superviseur`
- [ ] Relire `docs/resolved-issues.md` (entrées rôles 2026-09-24 et CRI Input DTO phase 1.3).
- [ ] Lancer `dotnet test` + `flutter analyze` : état vert de référence.

### Phase 1 — Back : capacités, **sans changement de comportement** (Technician / Admin)
- [ ] `Models/UserRole.cs` : ajouter `Supervisor` à l'enum ; `FromString` → **`UserRole?`** (valeur inconnue = `null`, plus de repli silencieux sur Technician) ; `ToRoleString` / `Normalize` gèrent `Supervisor`.
- [ ] `JwtService` / `AuthService` : rôle inconnu → connexion refusée (message explicite + log warning), au lieu d'émettre un jeton.
- [ ] Nouveau `Authorization/Capabilities.cs` : constantes des capacités + table `RoleCapabilities` (matrice §4) — **seule source de vérité**.
- [ ] `Program.cs` : enregistrer une policy par capacité à partir de la table (boucle) ; supprimer `AdminOnly` / `TechnicianOrAdmin`.
- [ ] Extension `ClaimsPrincipal.HasCapability(string)` pour les contrôles inline (visibilité / propriété).
- [ ] Remplacer chaque contrôle (inventaire au 2026-09-24) :
  - `CRIController.cs` : l.60 → `CriReadAll` · l.108 → `CriReadAll` · l.130 (POST, CRI existant) → `CriManageAny` · l.196 → `CriManageAny` · l.258 (DELETE) → `CriManageAny` · l.329 (upload photo) → `CriManageAny` · l.393 (GET photo) → `CriReadAll` · l.419 (DELETE photo) → `CriManageAny`.
  - Attributs d'action : `[Authorize(Policy = CriCreate)]` sur `POST /cri`, `PUT /cri/{id}`, `PATCH signature`, `DELETE /cri/{id}`, `POST/DELETE photos`. **Comble le trou de la policy non appliquée.**
  - `ExportController.cs` l.54, 111, 120 → `ExportAll`. Renommer le paramètre `isAdmin` de `XlsxExportService` en `allTechnicians` (l.17, 18, 56, 238 et usages).
  - `ExportedDocumentsController.cs` l.67 → `DocumentsReadAll` (liste) ; l.128 (download) → `DocumentsReadAll` ; l.160, 180, 200 (rename / delete / mark-shared) → `DocumentsManageAny`.
  - `GlobalStatsController` → `[Authorize(Policy = GlobalStats)]` · `PersonalStatsController` → `PersonalStats` · `HealthController` l.41, 127 + `SitesController` l.94 → `SystemAdmin`.
- [ ] Supprimer `Attributes/RoleAuthorizeAttribute.cs` une fois plus référencé. Supprimer `User.IsAdmin()` / `IsTechnician()` si inutilisés.
- [ ] Tests d'intégration : pour chaque endpoint de la matrice, Technician et Admin → même code HTTP qu'avant. `dotnet test` vert.
- [ ] Commit : `Refactor(auth): autorisations par capacité`.

### Phase 2 — Back : activer `Supervisor`
- [ ] Ajouter la colonne Supervisor dans `RoleCapabilities` (matrice §4).
- [ ] `UsersController.GetTechnicians` : **exclure** Supervisor (la liste alimente le choix « Techniciens intervenants »). `GlobalStatsService.GetTechnicianActivityAsync` (l.131) : exclure Supervisor ; `GetTechniciansAsync` : vérifier l'usage (filtre dashboard) et exclure si besoin.
- [ ] Tests d'intégration Supervisor, un par ligne de la matrice :
  - 200 : `GET /cri`, `GET /cri/{id}` (CRI d'un autre), `GET photo`, `/api/global/*`, `/api/export/*` (portée global), `GET /exported-documents` (docs de tous), `download`, `/sites/*` en lecture, `/users/me`.
  - 403 : `POST /cri`, `PUT /cri/{id}`, `PATCH /cri/{id}/signature`, `DELETE /cri/{id}`, `POST/DELETE photos`, `/api/personal/*`, `POST /sites/import`, `/api/health`, `rename/delete/mark-shared` sur le doc d'un autre.
  - 200 : `rename/delete` sur **son propre** document exporté.
- [ ] Test : rôle inconnu en base → connexion refusée.
- [ ] Commit : `Feat(auth): rôle Supervisor en lecture seule`.

### Phase 3 — Front : permissions, **sans changement de comportement**
- [ ] `models/user_role.dart` : ajouter `supervisor` ; `fromString` → `UserRole?` (inconnu = `null` → écran « rôle non pris en charge » + déconnexion, jamais technicien par défaut).
- [ ] `core/constants/permissions.dart` : aligner `Permission` sur les capacités §4 (mêmes noms) ; `rolePermissions` = copie exacte de la matrice. Fusionner les deux classes `UserRole` (constantes String + enum) en une seule.
- [ ] Remplacer les tests de rôle par `permissionsProvider.hasPermission(...)` :
  - `features/documents/pages/documents_page.dart` l.37 (`isAdmin`) → `DocumentsReadAll` pour la colonne « Utilisateur » / recherche ; `DocumentsManageAny` **ou propriétaire** pour renommer / supprimer / partager.
  - `features/dashboard/pages/main_dashboard_page.dart` l.44 → `GlobalStats`.
  - `screens/admin/global_history_screen.dart` l.1044, 1067 → `CriManageAny`.
- [ ] Supprimer `core/widgets/protected_route.dart` (jamais utilisé) **ou** l'utiliser pour les gardes de routes de la phase 4 — choisir l'un, pas de code mort.
- [ ] `flutter analyze` propre, comportement Technician / Admin identique (recette rapide).
- [ ] Commit : `Refactor(front): permissions par capacité`.

### Phase 4 — Front : interface Superviseur
- [ ] `screens/role_home_screen.dart` : `UserRole.supervisor => SupervisorMainScreen()`.
- [ ] `screens/supervisor/supervisor_main_screen.dart` : reprend `AdminMainScreen` **sans** « Nouveau CRI ». Onglets : Vue Globale, Tous les CRI, Documents, Paramètres. Factoriser la liste d'onglets plutôt que dupliquer l'écran (cf. leçon de la carte CRI dupliquée).
- [ ] `GlobalHistoryScreen` réutilisé tel quel : `CriCard` sans poubelle (pas de `CriManageAny`) ; fiche détail `CriDetailsDialog` avec `canEdit` / `canDelete` / `canToggleSignature` = `false`.
- [ ] Masquer toute entrée vers `/cri-form`, `/cri/new/*`, `/cri/edit/*` (FAB, raccourcis d'accueil, dashboards).
- [ ] `app_router.dart` : garde `redirect` par permission sur `/cri-form`, `/cri/new/*`, `/cri/edit/*` (→ `CriCreate`), `/dashboard*` (→ `GlobalStats`). Filet d'UX, la sécurité reste l'API.
- [ ] Hors ligne : ne pas démarrer `SyncService` ni lire les brouillons locaux pour un superviseur (vérifier `pendingCriCountProvider` et les appels `syncPendingCris()`).
- [ ] Libellé du rôle « Superviseur » : `profile_screen.dart`, carte compte de `admin_screen.dart`, `technician_dashboard_page.dart` l.372.
- [ ] Commit : `Feat(front): espace Superviseur`.

### Phase 5 — Docs, compte de test, recette
- [ ] Docs :
  - `architecture.md` : tableau contrôleurs → policies réelles ; tableau « Rôles » → 3 rôles + renvoi à la matrice ; routes Flutter → garde par permission.
  - `api-summary.md` : colonne Auth par capacité ; section Rôles.
  - `conventions.md` : « jamais `IsInRole` / `role == '...'` ; toujours une capacité ».
  - `database-mcd-mld.md` : valeurs possibles de `Users.Role`.
  - `resolved-issues.md` : entrée « policy `TechnicianOrAdmin` jamais appliquée ».
- [ ] Déploiement API **puis** création du premier compte superviseur (jamais l'inverse, cf. §3) :
  ```bash
  docker exec -it cri-novadis-db-1 psql -U cri_user -d cri_novadis -c "UPDATE \"Users\" SET \"Role\" = 'Supervisor' WHERE \"Email\" = 'prenom.nom@exemple.fr';"
  ```
  Vérification :
  ```bash
  docker exec -it cri-novadis-db-1 psql -U cri_user -d cri_novadis -c "SELECT \"Role\", COUNT(*) FROM \"Users\" GROUP BY \"Role\";"
  ```
- [ ] Recette manuelle web + mobile avec un compte de chaque rôle (grille ci-dessous).
- [ ] PR `feat/role-superviseur` → `dev`.

## 6. Grille de recette manuelle

| Action | Technician | Admin | Supervisor |
|---|:-:|:-:|:-:|
| Onglet « Nouveau CRI » visible | ✅ | ✅ | ❌ |
| URL `/cri/new/service` saisie à la main | formulaire | formulaire | redirigé |
| « Tous les CRI » : voit les CRI des autres | ❌ | ✅ | ✅ |
| Poubelle sur un CRI d'autrui | ❌ | ✅ | ❌ |
| Fiche détail : Modifier / Supprimer / Signature | siens | selon règles | aucun bouton |
| Vue Globale + dashboard technicien / site | ❌ | ✅ | ✅ |
| Export XLSX période, portée | Mes CRI | Tous | Tous |
| Documents : voit ceux des autres | ❌ | ✅ | ✅ |
| Documents : renommer / supprimer celui d'un autre | ❌ | ✅ | ❌ |
| Absent de la liste « Techniciens intervenants » | — | — | ✅ |
| Mobile hors ligne : pas de badge « Non synchronisé » ni brouillon | — | — | ✅ |

## 7. Hors périmètre

- Périmètre par équipe / site (nécessiterait une table de liaison — à rouvrir si besoin).
- Écran de gestion des utilisateurs et des rôles.
- Validation manuelle de signature par le superviseur.
