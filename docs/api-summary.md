# API Summary — CRI Novadis 2.0

**Base URL** : `/api`  
**Auth** : JWT Bearer — `Authorization: Bearer <access_token>`  
**Format réponse** :
```json
{ "success": true, "data": <T>, "message": "...", "errors": [] }
```
**Pagination** : headers `X-Total-Count`, `X-Page`, `X-Page-Size`, `X-Total-Pages`

---

## Auth — `POST /api/auth`

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| POST | `/login` | ❌ | Envoi OTP par email |
| POST | `/verify` | ❌ | Vérification OTP → retourne access + refresh token |
| POST | `/refresh` | ❌ | Renouvellement access token via refresh token |
| POST | `/verify-device` | ❌ | Auth via token d'appareil de confiance |
| POST | `/logout` | ✅ | Révocation du refresh token |
| GET | `/me` | ✅ | Utilisateur connecté (`UserDto`) |
| GET | `/dev/get-code/{email}` | ❌ | **[DEV ONLY]** Récupère l'OTP en clair |

### Corps de requête

**`POST /login`**
```json
{ "email": "string", "ipAddress": "string?", "deviceInfo": "string?" }
```

**`POST /verify`**
```json
{ "email": "string", "code": "string (6 chiffres)", "ipAddress": "string?", "deviceInfo": "string?" }
```

**`POST /refresh`**
```json
{ "refreshToken": "string", "ipAddress": "string?", "deviceInfo": "string?" }
```

**Réponse `/verify` et `/refresh`** (`AuthResponseDto`)
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "expiresAt": "DateTime",
  "user": { "id": "Guid", "email": "string", "firstName": "string", "lastName": "string", "role": "string", "isActive": true }
}
```

---

## CRI — `/api/cri`

Auth requise sur tous les endpoints. Admin voit tous les CRI, Technician voit uniquement les siens.

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/` | Liste paginée des CRI (`?page=1&pageSize=20`) |
| GET | `/{id}` | Détail d'un CRI avec photos |
| POST | `/` | Créer ou mettre à jour un CRI (upsert) |
| PUT | `/{id}` | Modifier un CRI existant |
| PATCH | `/{id}/signature` | Mettre à jour la signature client (propriétaire uniquement) |
| DELETE | `/{id}` | Supprimer un CRI |
| GET | `/clients/search?q=` | Autocomplete clients (min 2 chars) |
| GET | `/sites/search?q=&client=` | Autocomplete sites |
| POST | `/{id}/photos` | Upload photos (multipart/form-data, max 50 MB) |
| GET | `/{id}/photos/{photoId}` | Télécharger une photo (binaire) |
| DELETE | `/{id}/photos/{photoId}` | Supprimer une photo |

**`PATCH /{id}/signature`** — corps :
```json
{ "clientSignature": "base64_string_or_MANUAL_VALIDATION" }
```
> Valeur spéciale : `"MANUAL_VALIDATION"` → valide sans signature numérique.

---

## Stats globales — `/api/global` *(Admin uniquement)*

| Méthode | Route | Paramètres | Description |
|---------|-------|-----------|-------------|
| GET | `/stats` | `?period=30` (jours) | KPI globaux (compteurs, répartitions, moyennes) |
| GET | `/cris` | `?technicienId=&filter=&searchId=` | Tous les CRI enrichis avec infos technicien |
| GET | `/activity` | — | Activité par technicien (nb CRI 7j / 30j / total) |
| GET | `/activity-chart` | — | Activité quotidienne sur 7 jours |
| GET | `/technicians` | — | Liste des utilisateurs pour dropdown |
| GET | `/stats/by-site` | `?period=30` | Stats agrégées par site |
| GET | `/stats/by-technician` | `?period=30` | Stats agrégées par technicien |
| GET | `/stats/distribution` | `?period=30` | Crosstabs et évolution mensuelle |

**Réponse `/stats`** (`GlobalStatsDto`)
```json
{
  "totalCeMois": 0, "totalSignes": 0, "totalEnAttente": 0,
  "techniciensActifs": 0, "dureeMoyenneMinutes": 0.0,
  "totalProjets": 0, "totalServices": 0,
  "totalResolu": 0, "totalNonResolu": 0, "totalRecurrenceRequise": 0,
  "repartitionParVille": { "Paris": 5, "Lyon": 2 }
}
```

---

## Stats personnelles — `/api/personal`

Auth requise. Données du technicien connecté uniquement.

| Méthode | Route | Paramètres | Description |
|---------|-------|-----------|-------------|
| GET | `/stats` | — | KPI personnels |
| GET | `/cris` | `?filter=all\|pending\|signed\|in_progress` | CRI personnels filtrés |
| GET | `/recent` | — | 5 derniers CRI |
| GET | `/daily-stats` | `?year=2026` | Activité sur 365 jours (heatmap) |
| GET | `/monthly-stats` | — | Activité sur les 6 derniers mois |

**Réponse `/stats`** (`PersonalStatsDto`)
```json
{
  "criCeMois": 0, "criEnCours": 0, "criEnAttente": 0,
  "dureeMoyenneMinutes": 0.0,
  "totalResolu": 0, "totalNonResolu": 0, "totalRecurrenceRequise": 0
}
```

---

## Sites — `/api/sites`

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| GET | `/search?q=` | ❌ | Recherche sites NovaDIS (min 2 chars, insensible accents/casse) |
| GET | `/` | ✅ | Liste paginée des sites (`?page=1&pageSize=50`) |
| POST | `/import` | ✅ Admin | Importe les sites depuis le CSV interne |
| GET | `/summary?siteName=` | ✅ | Résumé d'un site (historique, alertes, recommandations) |

**Réponse `/search`** (liste de `SiteDto`)
```json
[{ "numero": 1, "nomDuSite": "string", "adresse": "string?", "ville": "string?", "codePostal": "string?", "pays": "string?" }]
```

**Réponse `/summary`** (`SiteSummaryDto`)
```json
{
  "siteName": "string",
  "lastVisitStatus": "string",
  "recurrenceLast6Months": 0,
  "hasUrgentPendingTickets": false,
  "chronicityAlert": false,
  "chronicProblemDescription": "string?",
  "recommendations": ["string"],
  "timeline": [{ "date": "DateTime", "identifiedCause": "string", "replacedParts": "string", "technicianName": "string", "status": "string" }]
}
```

---

## Export — `/api/export`

Auth requise. Admin exporte tout, Technician exporte ses propres CRI.

| Méthode | Route | Paramètres | Description |
|---------|-------|-----------|-------------|
| GET | `/cri/{id}.xlsx` | — | Export XLSX d'un CRI (retourne fichier binaire) |
| GET | `/period.xlsx` | `?range=day\|week\|month\|year&date=2026-05-01` | Export XLSX par période |

---

## Documents exportés — `/api/exported-documents`

Visibilité : **Admin voit/ouvre tous les documents** (tous techniciens), le DTO renvoie alors `userName`/`userEmail`. Technicien : uniquement les siens (filtre `UserId`). Même règle sur `download`/`rename`/`delete`/`mark-shared` (bypass admin).

| Méthode | Route | Paramètres | Description |
|---------|-------|-----------|-------------|
| GET | `/` | `?fileType=&exportType=&skip=0&take=200` | Liste des exports (max 1000) |
| GET | `/{id}/download` | — | Binaire brut — sert à la fois au téléchargement et à l'aperçu client (voir front) |
| PATCH | `/{id}` | Body: `{ "filename": "string" }` | Renommer un export |
| POST | `/{id}/mark-shared` | — | Marquer comme partagé |
| DELETE | `/{id}` | — | Supprimer un export |
| POST | `/upload` | multipart: `file`, `criId?`, `exportType?` | Upload manuel d'un document (max 50 MB) |

---

## Utilisateurs — `/api/users`

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| GET | `/technicians` | ✅ | Liste des techniciens et admins actifs |

---

## Health — `/api/health`

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| GET | `/live` | ❌ | Liveness probe (toujours 200) |
| GET | `/` | ❌ | Health check complet DB (200 OK / 503 si KO) |
| GET | `/stats` | ❌ | Stats DB (nb users, CRI, photos, logs) |
| GET | `/users` | ❌ | Liste tous les utilisateurs |
| GET | `/test-write` | ❌ | Test d'écriture DB |

---

## Modèle CRI — champs principaux

| Champ | Type | Description |
|-------|------|-------------|
| `id` | Guid | Identifiant |
| `technicianId` | Guid | FK → User |
| `interventionType` | string | `"Project"` ou `"Service"` |
| `status` | string | `"Draft"` / `"Submitted"` / `"Validated"` |
| `interventionDate` | DateTime | Date de l'intervention |
| `heureDebut` / `heureFin` | TimeSpan? | Horaires |
| `dureeMinutes` | int? | Durée calculée |
| `clientName` | string | Nom du client |
| `clientSite` | string? | Nom du site client |
| `ville` / `codePostal` | string? | Localisation |
| `ticketNumber` | string? | Numéro de ticket (Service) |
| `resolutionStatus` | string? | `resolu` / `nonResolu` / `partiellementResolu` / `enAttente` |
| `projectName` / `projectNumber` | string? | Champs Projet |
| `projectPhase` | string? | `etude` / `realisation` / `maintenance` |
| `technicianSignature` | string? | Base64 |
| `clientSignature` | string? | Base64 ou `"MANUAL_VALIDATION"` |
| `data` | string? | JSON complet du formulaire Flutter (fallback) |
| `siteID` | int? | FK → Sites |
| `clientID` | Guid? | FK → Clients |

---

## Codes d'erreur HTTP

| Code | Signification |
|------|--------------|
| 400 | Corps de requête invalide ou validation échouée |
| 401 | Token absent, invalide ou expiré (`Token-Expired` header si expiré) |
| 403 | Accès refusé (rôle insuffisant ou ressource d'un autre utilisateur) |
| 404 | Ressource introuvable |
| 429 | Rate limit dépassé |
| 500 | Erreur interne (voir logs Serilog) |
| 503 | Service indisponible (DB inaccessible) |
