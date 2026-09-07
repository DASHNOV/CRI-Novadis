# Incidents résolus — Novadis CRI 2.0

> Journal des bugs complexes et erreurs de logique résolus.
> **À consulter avant toute nouvelle correction** (cf. `CLAUDE.md`).
> Style télégraphique, entrée la plus récente en haut.

## Format d'une entrée

```
## [AAAA-MM-JJ] Titre court du problème
- **Symptôme** : ce qui était observé (erreur, comportement).
- **Cause** : la vraie cause racine identifiée.
- **Correctif** : ce qui a été changé (fichiers / logique).
- **Prévention** : règle à suivre pour éviter la régression.
```

---

<!-- Ajouter les incidents résolus ci-dessous, du plus récent au plus ancien. -->

## [2026-09-07] Migrations écrites à la main, invisibles pour EF — base neuve inexploitable

- **Symptôme** : aucun en production, et c'est ce qui rend le défaut redoutable. Au déploiement, l'API journalisait `Applying pending database migrations...` puis `Database migrations applied successfully` — sur un travail **nul**. La colonne `Priority` restait en base malgré une migration censée la supprimer. `dotnet ef migrations list` ne renvoyait qu'`InitialCreate`, alors que `Data/Migrations/` contenait trois fichiers.
- **Cause** : `20260624000000_AddUserSavedSignature.cs` et `20260730121446_RemoveCriServicePriority.cs` avaient été écrits **à la main**, sans fichier `.Designer.cs`. Or EF Core découvre les migrations par l'attribut `[Migration("…")]`, généré précisément dans ce fichier. Sans lui, une classe qui hérite de `Migration` n'est pas une migration : EF ne l'a jamais vue, jamais exécutée, et signalait un succès parce qu'il n'avait effectivement rien à faire. Indice visible dès la lecture du répertoire : `20260624000000` se termine par six zéros, là où la CLI produit un horodatage réel (`20260527092951`). Deux écarts opposés en découlaient — en production `SavedSignature` avait été ajoutée directement en base et `Priority` jamais supprimée ; sur une **base neuve**, `InitialCreate` crée `Priority` et ignore `SavedSignature`, donc `PUT /api/users/me/signature` échouait. Un environnement provisionné à neuf, ou une reprise après sinistre, produisait une base cassée — le scénario le plus coûteux possible.
- **Correctif** : suppression des deux fichiers inertes, puis migration `20260907144312_SyncSchemaWithModel` **générée par la CLI**, donc pourvue de son `.Designer.cs` et de son attribut. Son SQL est idempotent (`ADD COLUMN IF NOT EXISTS`, `DROP INDEX IF EXISTS`, `DROP COLUMN IF EXISTS`) afin de couvrir d'un même code la production et une base neuve, et purge la ligne d'historique orpheline laissée par l'ancienne migration manuelle. Le tout dans une transaction. Écarté volontairement : les 21 `AlterColumn` `timestamptz → timestamp` que le scaffolding proposait, conséquence de `Npgsql.EnableLegacyTimestampBehavior` (`Program.cs:23`) actif au design-time ; les appliquer réécrirait toutes les colonnes de dates et ferait perdre l'information de fuseau, pour un écart antérieur et sans effet à l'exécution.
- **Prévention** : **ne jamais écrire un fichier de migration à la main.** Toujours passer par `dotnet ef migrations add`, qui génère le `.Designer.cs` porteur de `[Migration]` et met à jour le snapshot. Un fichier de migration sans `.Designer.cs` jumeau est du code mort qui ne s'exécutera jamais. Contrôle avant tout déploiement touchant au backend : `dotnet ef migrations list` doit afficher **autant d'entrées que de fichiers** dans `Data/Migrations/` — un écart signale des migrations fantômes. Corollaire : un message « migrations applied successfully » ne prouve rien ; ce qui prouve, c'est l'état du schéma après coup. Enfin, toute modification passée directement en base doit être régularisée par une vraie migration idempotente, jamais par un `INSERT` dans `__EFMigrationsHistory` seul.

## [2026-09-07] Gel complet du VPS — hôte injoignable, conteneurs non redémarrés

> ⚠️ **Date et symptôme observé à confirmer** (entrée rédigée a posteriori lors de l'audit du
> 2026-09-07 ; l'incident lui-même n'avait pas été journalisé). La cause ci-dessous est
> l'explication mécanique la plus plausible au vu du code, **pas** une cause racine confirmée
> par des métriques de l'incident.

- **Symptôme** : VPS entièrement injoignable (API, SSH), sans redémarrage automatique des conteneurs malgré `restart: always`. Reprise uniquement après redémarrage matériel côté hébergeur.
- **Cause (hypothèse)** : `docker-compose.yml` ne fixait **aucune limite de ressources** sur le service `api`. Or `XlsxExportService.GeneratePeriodAsync` (`range=year`, profil Admin) charge l'année courante **et** l'année précédente en entités complètes — `Data` JSON + signatures base64 incluses —, construit un `XLWorkbook`, y insère des images ScottPlot, sérialise dans un `MemoryStream`, puis en tire un `byte[]` : plusieurs copies intégrales de la charge coexistent en mémoire. Sans plafond, un dépassement ne tue pas le conteneur, il consomme la mémoire de l'**hôte** — d'où un gel de la machine plutôt qu'un simple échec de requête. Le swap actif aggrave le tableau : la machine rame sans jamais déclencher l'OOM killer.
- **Correctif** : `mem_limit: 1g` + `memswap_limit: 1g` (swap désactivé) + `cpus: 1.5` sur `api`, `mem_limit: 768m` + `shm_size: 256m` sur `db`. Ajout d'un `healthcheck` sur `api` (`curl` sur `/api/health/live`, installé dans l'étape runtime du `Dockerfile`) pour que Docker redémarre une API bloquée mais encore vivante. Réduction de l'empreinte de l'export elle-même prévue en phase 4 du plan de remédiation (agrégations SQL, projection sans signatures).
- **Prévention** : **tout service conteneurisé en production doit avoir un `mem_limit` explicite**, avec `memswap_limit` de même valeur. Sans plafond, un incident applicatif devient un incident machine, et le `restart: always` ne sert à rien puisque Docker lui-même est privé de ressources. Corollaire : tout traitement chargeant un jeu de données non borné en mémoire (export, statistiques, rapport) doit être borné côté requête (pagination, projection) **et** côté conteneur.

## [2026-09-07] Panne API non détectée — signalée par les utilisateurs, pas par le monitoring

> ⚠️ **Date et durée à confirmer** (entrée rédigée a posteriori lors de l'audit du 2026-09-07).

- **Symptôme** : API indisponible pendant une durée non mesurée ; la panne a été remontée par les techniciens sur le terrain, aucune alerte n'ayant été émise.
- **Cause** : la sonde de *readiness* `GET /api/health` — qui teste la connectivité base, la latence (seuil 500 ms), l'espace disque (seuil 1 Go) et la mémoire du processus, et renvoie `503` en cas de problème — n'était **consommée par personne** : aucune configuration de monitoring dans le dépôt, aucune alerte. Le seul contrôle automatisé était le smoke test de `deploy-api.yml`, qui interroge `/api/health/live` : celui-ci renvoie `200` tant que le processus .NET répond, **même base de données injoignable**. Aucun `healthcheck` Docker n'existait non plus sur le service `api`, donc une API bloquée mais vivante n'était jamais redémarrée.
- **Correctif** : `healthcheck` Docker sur `api` (voir entrée ci-dessus). Mise en place du monitoring externe et extension du smoke test à la sonde de readiness prévues en phase 3 du plan de remédiation.
- **Prévention** : **une sonde n'est utile que si quelque chose la lit**. Distinguer systématiquement *liveness* (le processus répond — sonde de redémarrage) et *readiness* (les dépendances répondent — sonde d'alerte), et ne jamais brancher une alerte de disponibilité sur la seule liveness. Même règle pour les tâches planifiées : une sauvegarde ou un job cron qui cesse silencieusement doit lever une alerte par absence de signal (heartbeat), pas être découvert au moment où l'on en a besoin.

## [2026-07-31] Export XLSX 500 — « Access to the path '/app/export-storage/<userId>' is denied »
- **Symptôme** : `GET /api/export/period.xlsx?...` → `500 Internal Server Error`, message front `Erreur lors de l'export: Exception: Serveur: Access to the path '/app/export-storage/<guid>' is denied.`. Concerne en réalité **tous** les exports (CRI + période), pas seulement le mensuel.
- **Cause** : conséquence directe du correctif précédent (montage `./export-storage:/app/export-storage`). Le dossier hôte créé automatiquement par Docker appartient à **root:root**, alors que le conteneur tourne en `USER app` (**UID/GID 1654**, images .NET 8+, cf. `Dockerfile:21`). Le `chown -R app:app /app` du Dockerfile a lieu **au build** — le bind-mount runtime écrase l'ownership. `LocalFileObjectStorage.UploadAsync` → `Directory.CreateDirectory("/app/export-storage/{userId}/{yyyy}/{MM}")` (clé construite par `ExportController.BuildObjectKey`) → `UnauthorizedAccessException`.
- **Correctif** : côté serveur `sudo chown -R 1654:1654 export-storage logs uploads` puis `docker compose up -d --force-recreate api`. Côté repo : `export-storage` ajouté au `mkdir` du `Dockerfile` (ownership correcte dans l'image, utile si passage à un volume nommé) + commentaire explicite sur les prérequis d'ownership dans `docker-compose.yml`.
- **Prévention** : tout **bind-mount** sur un conteneur non-root doit avoir son dossier hôte pré-créé et `chown` vers l'UID applicatif (1654 pour .NET) **avant** le premier `docker compose up` — un `chown` dans le Dockerfile ne protège que les chemins non montés. Alternative : volume Docker **nommé** (hérite de l'ownership du chemin dans l'image si le volume est vide), au prix d'un accès moins direct pour `backup-server.sh`.

## [2026-07-31] PDF/XLSX exportés introuvables au téléchargement (« Fichier introuvable dans le stockage »)
- **Symptôme** : dans « Mes Documents », certains documents (métadonnées visibles, taille/date OK) renvoient `Erreur à l'ouverture: Exception: Serveur: Fichier introuvable dans le stockage.` au clic/téléchargement (`ExportedDocumentsController.Download` → `FileNotFoundException` catché, `404`).
- **Cause** : `LocalFileObjectStorage` (`backend/src/NovadisApi/Services/Storage/LocalFileObjectStorage.cs`) écrit les binaires sur le filesystem du conteneur, sous `./export-storage` relatif à `ContentRootPath` (donc `/app/export-storage`). `docker-compose.yml` ne montait ce dossier dans **aucun volume** (seuls `./logs` et `./uploads` l'étaient) — contrairement à `postgres_data` (nommé, persistant). À chaque recréation du conteneur `api` (redeploy), `/app/export-storage` repart vide alors que les lignes `ExportedDocuments` en base (persistée, elle) survivent. Tout document uploadé **avant** le dernier redeploy devient irrécupérable ; ceux créés après refonctionnent normalement — ce qui explique le pattern observé (CRI récents de Xavier OK, CRI plus anciens de Rémy/Guillaume en erreur).
- **Correctif** : ajout du volume `./export-storage:/app/export-storage` dans `docker-compose.yml` (service `api`). Nécessite un redeploy (`docker compose up -d --force-recreate api`) sur le serveur pour prendre effet. **Les fichiers déjà perdus ne sont pas récupérables** — seuls les futurs exports seront persistés.
- **Prévention** : tout répertoire écrit par un service de stockage local (`IObjectStorageService`) et destiné à survivre aux redeploys **doit** être monté en volume Docker au même titre que la DB — vérifier systématiquement `docker-compose.yml` lors de l'ajout d'un nouveau chemin d'écriture disque côté backend.

## [2026-07-31] Caractères manquants/mal rendus dans les PDF (œ, —, accents étendus) + suppression du champ « priorité » CRI
- **Symptôme** : dans les PDF générés (`pdf_builder_common.dart`), certains glyphes (ex. « œ »/« Œ », tiret cadratin « — ») apparaissaient absents ou mal rendus. Log de test : `Helvetica has no Unicode support`.
- **Cause** : la police de base du package `pdf` (Helvetica) est limitée à Latin-1 et ne couvre pas Latin Extended-A / ponctuation étendue.
- **Correctif** : ajout des polices Lato (`frontend/assets/fonts/Lato-{Regular,Bold,Italic}.ttf`, déclarées dans `pubspec.yaml`) chargées via `_loadPdfTheme()` (`pdf_builder_common.dart`) et appliquées au `pw.Document(theme: pdfTheme)`, avec fallback silencieux vers Helvetica si le chargement échoue.
- **Changement fonctionnel associé (même commit)** : suppression complète du champ « priorité » du CRI (jugé non pertinent à l'usage) — modèle, DTOs, contrôleur, service de stats/export back ; widget `PriorityChip` et ses tests supprimés front ; migration EF `RemoveCriServicePriority` (`DROP COLUMN Priority` + son index), **irréversible en base sans rollback manuel** (`Down()` du migration recrée la colonne mais les données seront perdues).
- **Prévention** : pour tout ajout de texte contenant des caractères hors Latin-1 dans un PDF (ligatures, tirets typographiques, accents rares), vérifier que le thème `pdfTheme` (police Unicode) est bien appliqué au `pw.Document` — ne jamais utiliser `pw.Document()` sans thème pour du contenu utilisateur libre.

## [2026-07-21] Vulnérabilité Microsoft.Kiota.Abstractions 1.15.2 (CVE-2026-44503)
- **Symptôme** : `dotnet restore/test` émet `warning NU1903` — `Microsoft.Kiota.Abstractions 1.15.2` a une vulnérabilité de gravité élevée (GHSA-7j59-v9qr-6fq9).
- **Cause** : faille du `RedirectHandler` Kiota (< 1.22.0) — ne supprime pas les en-têtes sensibles (`Cookie`, `Proxy-Authorization`, en-têtes custom) lors d'une redirection cross-host/scheme → risque de fuite de cookies/credentials. Paquets Kiota tirés **en transitif** par `Microsoft.Graph 5.65.0` (utilisé par `EmailService` pour l'envoi de mails via Graph SendMail). Le SDK Graph, même en dernière 5.x (5.105.0 → Graph.Core 3.2.5), n'épingle encore que Kiota **1.21.1** < 1.22.0.
- **Correctif** : `backend/src/NovadisApi/NovadisApi.csproj` — bump `Microsoft.Graph` 5.65.0 → **5.105.0** (baseline Kiota 1.21.1 cohérente) + bloc de `PackageReference` directes épinglant **toute la famille Kiota à 1.22.2** (Abstractions, Authentication.Azure, Http.HttpClientLibrary, Serialization.{Json,Form,Text,Multipart}). Build 0 erreur, 47/47 tests OK, `NU1903` disparu.
- **Prévention** : pour neutraliser une vuln dans une dépendance **transitive**, ajouter une `PackageReference` directe vers la version patchée (override NuGet) — ne pas attendre que le paquet parent l'adopte. Épingler la **famille entière** en lockstep pour éviter les mismatch de version binaire. À retirer une fois que le SDK Graph montera nativement à Kiota ≥ 1.22.0.

## [2026-07-20] Lot d'évolutions CRI : logiciel « Autre », édition post-soumission, signature unique, nommage auto, validation email
- **Contexte** : 5 demandes fonctionnelles / vérifications de cohérence.
- **Logiciel « Autre » (CRI Projet)** : ajout du membre `autre` à `enum ProjetSoftware` + champ `customName` sur `SoftwareEntry` (`cri_projet_table.dart`). Saisie manuelle conditionnelle dans `_buildSoftwaresSection` (`cri_projet_form_page.dart`), validée (nom requis si « Autre » coché). Rendu PDF via `SoftwareEntry.displayName` (`pdf_builder_common.dart`). Aucun changement DB (transite par colonne JSON `Data`).
- **Édition d'un CRI soumis** : autorisée **au seul propriétaire**. Back : garde ajoutée dans `CRIController.UpdateCRI` — si `Status == "Submitted"`, refuser sauf propriétaire (pas de dérogation Admin) ; `UpdatedAt` sert de trace. Front : bouton « Modifier » dans `CriDetailsDialog` (`canEdit`/`onEdit`) affiché si propriétaire ; bannière d'avertissement dans les 2 form pages quand `!isDraft` ; `loadCri` fait désormais un **fallback serveur** (`CriRemoteRepository.fetchCriById`) car un CRI soumis peut ne pas exister en base locale.
- **Signature unique multi-techniciens** (option retenue : une seule signature suffit) : suppression du `SignaturePadWidget` par technicien dans la boucle ; un unique pad après la liste des noms (`cri_service_form_page.dart`, `cri_projet_form_page.dart`). Liste `technicianNames` conservée. PDF : noms empilés + une seule signature (`_buildSignatureBlock`). Back inchangé (déjà un seul `TechnicianSignature`).
- **Nommage auto numéro de commande** : si `ticketNumber`/`projectNumber` vide à la soumission → génération `CRI<AAAAMMJJ>_<acronymeSite><nomClient>` (`core/utils/cri_reference.dart`, acronyme dérivé du nom du site, mots vides ignorés). Appliqué dans les `submit()` des 2 contrôleurs, **sans écraser** une saisie manuelle.
- **Validation email** : regex durcie (TLD ≥ 2, pas de points consécutifs ni en bordure) alignée front (`form_validators.dart`) **et** back (`[RegularExpression]` sur `CRIForm.ClientEmail`, remplace `[EmailAddress]` trop permissif).
- **Prévention** :
  - Toute liste à choix fermés destinée à évoluer doit prévoir un membre `autre` + champ libre (pattern `ProjetInterventionType`).
  - Front et back doivent partager **la même** regex de validation (éviter la divergence `[EmailAddress]` .NET « loose » vs regex front).
  - `loadCri` ne doit jamais supposer la présence locale d'un CRI soumis — toujours prévoir le fallback serveur.
  - Ne jamais écraser une valeur saisie par l'utilisateur lors d'une génération automatique (garde `isNotEmpty`).

## [2026-07-16] CRI soumis hors-ligne invisible dans « Tous les CRI » / « Mes Documents »
- **Symptôme** : soumission d'un CRI sans réseau → message orange OK, CRI bien en base locale (visible à l'export, PDF exportable), mais **absent** de « Tous les CRI » (admin) et « Mes Documents » (technicien). Les listes n'affichaient que les CRI serveur de la dernière session en ligne.
- **Cause** : dans les deux écrans d'historique, la fusion des CRI locaux `pending` était placée **après** l'appel serveur dans le **même flux** — `global_history_screen` via un `Future.wait([getAllCRIsWithTechnician, getTechnicians, drafts, pending])`, `personal_history_screen` via `getPersonalCRIs` puis fusion. `getAllCRIsWithTechnician` / `getPersonalCRIs` lèvent une `DioException` hors-ligne (cf. `stats_api_service.dart`) → `Future.wait` rejette / le `try` part au `catch` **avant** la fusion locale, qui n'est donc jamais atteinte. La visibilité du local était de fait **conditionnée à la réussite de l'appel serveur**.
- **Correctif** :
  - `global_history_screen.dart` : charger les CRI locaux (drafts + pending) **toujours** en premier ; appel serveur rendu *best-effort* dans son propre `try/catch` (fallback = affichage local + snackbar « Hors ligne… »).
  - `personal_history_screen.dart` : même schéma — `getPersonalCRIs` best-effort, fusion locale indépendante du réseau.
- **Prévention** : **ne jamais placer une fusion/lecture de données locales derrière un appel réseau dans le même `Future.wait` ou le même `try`** — le local doit se charger indépendamment, le réseau être *best-effort*. Corollaire de la règle du 2026-07-10 : tout état `pending` local doit rester visible **même quand le serveur est injoignable**.
- **Note test (Flutter Web dev)** : tester hors-ligne en **coupant le backend** (`Ctrl+C` sur `dotnet run`), pas via DevTools « Offline » : en debug il n'y a pas de service worker, « Offline » bloque aussi le serveur de dev (`:60997`) → un F5 casse l'app (dino game / `ERR_INTERNET_DISCONNECTED`). Couper le backend laisse `:60997` up (F5 possible) et ne tombe que l'API (`:5200`). Export PDF hors-ligne = normal (rendu client depuis la base locale).

## [2026-07-16] Connexion impossible en local — requêtes `login` annulées à 10 s
- **Symptôme** : en dev web (Chrome), « Une erreur est survenue. Veuillez réessayer. » à la connexion. Onglet Network : requêtes `login` en `(canceled)` à ~10.01 s, `Preflight` en `(pending)`. Backend pourtant démarré.
- **Cause** : `frontend/.env` figeait `API_URL=http://192.168.200.214:5200/api`, mais le DHCP avait réattribué l'IP de la machine (passée à `192.168.200.202`). L'ancienne IP LAN était injoignable → timeout au bout du `connectTimeout` Dio (10 s, cf. `core/network/dio_provider.dart`) → requête annulée.
- **Correctif** : `frontend/.env` → `API_URL=http://localhost:5200/api` (backend sur la même machine). Nécessite un **redémarrage complet** de `flutter run` car `dotenv` charge le `.env` au démarrage (le hot reload ne suffit pas).
- **Prévention** : ne pas figer d'IP LAN dans `.env` pour le dev web — utiliser `localhost`, robuste face aux changements d'IP DHCP. L'IP LAN n'est nécessaire que pour tester sur un device mobile physique (à remettre ponctuellement dans ce cas). Devant un timeout à ~10 s pile sur `login`, suspecter d'abord une `API_URL` injoignable avant la logique applicative.

## [2026-07-10] CRI soumis sur site invisible dans « Tous les CRI » / « Mes Documents »
- **Symptôme** : soumission d'un CRI sur site client → message « enregistré avec succès », mais CRI absent de « Tous les CRI » et « Mes Documents ». Jamais reproduit au bureau.
- **Cause** : échec réseau (pare-feu site, portail captif, 4G faible) sur `POST /CRI` → `submit()` marquait le CRI `syncStatus: 'pending'` en local mais **retournait `true`** ; la page affichait un faux succès (branche `success` ignorait `errorMessage`). Aucun code ne relisait les CRI `pending` pour les repousser, et les listes lisaient uniquement le serveur.
- **Correctif** :
  - `services/sync_service.dart` (nouveau) : repousse les CRI `pending` non-brouillons au démarrage, au retour de connectivité (mobile) et avant chargement des listes.
  - Contrôleurs service/projet : message hors-ligne explicite ; pages formulaire : snackbar orange « enregistré sur l'appareil » au lieu du faux succès vert.
  - `personal_history_screen` + `global_history_screen` : fusion des CRI locaux `pending` (badge « Non synchronisé », dédup par id serveur).
- **Prévention** : jamais retourner « succès » à l'UI quand un push distant échoue silencieusement ; tout état `pending` local doit avoir un mécanisme de resynchronisation ET être visible dans l'UI.
