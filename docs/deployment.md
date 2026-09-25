# Déploiement et exploitation — CRI Novadis

> Où tourne l'application, comment elle y arrive, comment on sait qu'elle va bien,
> et en combien de temps on la remet sur pied. Pour la restauration pas à pas :
> [`disaster-recovery.md`](disaster-recovery.md).

---

## Topologie

```
Navigateur / APK
   │
   ├── https://cri-novadis.tech ──────────► Vercel (Flutter web, statique)
   │
   └── https://api.cri-novadis.tech ──────► Cloudflare (DNS, TLS, proxy)
                                              │  tunnel sortant, aucun port entrant
                                              ▼
                                     VPS Linux — /opt/cri-novadis
                                     ├─ cloudflared (service systemd)
                                     ├─ api  : cri-novadis-api:latest  127.0.0.1:5200
                                     └─ db   : postgres:16-alpine      (réseau Docker interne)
```

- **Un seul hôte de production** : un VPS Linux sous Docker Compose. Il n'existe pas de
  serveur Windows ni de service NSSM : toute mention contraire est obsolète.
- **Adresse** : secret GitHub `VPS_HOST` (et gestionnaire de mots de passe). Elle n'est
  volontairement pas écrite dans le dépôt : l'API n'est exposée que par le tunnel, et
  publier l'adresse d'origine permettrait de contourner Cloudflare.
- **Hébergeur** : à renseigner.
- **Dimensionnement** : 1 vCPU, 1,9 Gio de RAM (relevé du 2026-09-07). Les plafonds
  mémoire de `docker-compose.yml` en dépendent — ne pas changer de gabarit sans les revoir.
- **Accès** : SSH par clé uniquement (`VPS_USER` + `VPS_SSH_KEY`). Le port 5200 n'écoute
  que sur `127.0.0.1` ; seul `cloudflared` le joint.

### Contenu de `/opt/cri-novadis`

| Élément | Origine | Sauvegardé ? |
|---|---|---|
| `docker-compose.yml` | déposé par `deploy-api.yml` | dans le dépôt |
| `deploy-remote.sh` | déposé par `deploy-api.yml` | dans le dépôt |
| `backup-server.sh` | copié à la main (`scripts/`) | dans le dépôt |
| `.env` | créé à la main (`.env.production.example`) | **non — gestionnaire de mots de passe** |
| `backups/` | `backup-server.sh`, dumps pré-déploiement | copie hors site (B2) |
| `export-storage/` | PDF/XLSX exportés | archive quotidienne + B2 |
| `uploads/`, `logs/` | API | non |
| volume `postgres_data` | base | dump quotidien + B2 |

---

## Cloudflare

Tunnel **géré depuis le tableau de bord** (jeton), pas par un `config.yml` local : la
règle de routage vit chez Cloudflare. Détail, réinstallation et vérification :
[`infra/cloudflared/README.md`](../infra/cloudflared/README.md).

| Paramètre | Valeur attendue |
|---|---|
| Nom d'hôte public | `api.cri-novadis.tech` |
| Service | `http://localhost:5200` |
| Mode SSL/TLS de la zone | **Full (Strict)** (cf. `SECURITY.md`) |

---

## Déploiement

| Quoi | Déclencheur | Garde-fous |
|---|---|---|
| Web (Vercel) | push sur `main` touchant `frontend/**` | tests bloquants |
| API | push sur `main` touchant `backend/**`, `docker-compose.yml`, `scripts/deploy-remote.sh` ; ou *Run workflow* manuel | tests bloquants, dump pré-déploiement, attente de `/ready`, retour arrière automatique |

Flux : `fix/…` ou `feat/…` → `dev` (tests) → `main`, **une étape à la fois**, en laissant
chaque déploiement se terminer avant le suivant.

Déroulé côté serveur (`scripts/deploy-remote.sh`) : image en service mémorisée → dump
`backups/db_predeploy_<date>_<sha7>.sql.gz` → chargement de `cri-novadis-api:<sha>` →
redémarrage → attente de `/api/health/ready` (150 s) → en cas d'échec, retour sur l'image
précédente et workflow **en échec**. Les 5 dernières images taguées sont conservées.

### Carte des sites (une fois, après le déploiement de la phase 5 du dashboard)

- Le VPS doit joindre `https://data.geopf.fr` en sortie (géocodage IGN, gratuit, sans clé, 50 req/s max par IP — un lot de 1 000 sites = 1 requête).
- Géocoder les sites existants : `POST /api/sites/geocode` (compte Admin). Lire le bilan `{ traites, localises, aVerifier, sansAdresse }` : il mesure la qualité des adresses du référentiel. Les nouveaux sites et les adresses modifiées sont ensuite géocodés à chaque import.
- Côté web, les tuiles Plan IGN viennent de `data.geopf.fr` (pas de CSP à adapter aujourd'hui) ; l'attribution « Plan IGN — Géoplateforme » est affichée sur la carte.

#### Fond Google Maps (optionnel — sans clé, la carte reste en Plan IGN)

1. Google Cloud Console : projet avec **compte de facturation** ; activer **Maps JavaScript API** (web) et **Maps SDK for Android**.
2. Créer une clé et la **restreindre** (elle est lisible dans le navigateur et l'APK) :
   - web : référents HTTP `https://cri-novadis.tech/*` (+ `http://localhost:*/*` pour le dev) ;
   - Android : nom de package `com.example.novadis_cri` + empreinte SHA-1 du certificat de signature ;
   - API autorisées : les deux ci-dessus uniquement.
3. Web (Vercel) : variable d'environnement `GOOGLE_MAPS_API_KEY` du projet, lue par `build_vercel.sh`.
4. APK : `flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=<clé>` — Gradle reporte la clé dans le manifeste (`com.google.android.geo.API_KEY`).
5. Dev web : `flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=<clé>`.

Le bouton **Itinéraire** ouvre `https://www.google.com/maps/dir/?api=1&destination=…` (application Google Maps sur mobile, onglet sur le web) : il ne consomme pas la clé et fonctionne aussi avec la carte IGN.

### Prérequis serveur (une fois)

L'utilisateur SSH du déploiement (`VPS_USER`) doit pouvoir lancer `docker` et **écrire
dans `backups/`**, sinon le dump pré-déploiement échoue et le déploiement est annulé —
sans rien modifier, mais sans rien déployer non plus :

```bash
sudo mkdir -p /opt/cri-novadis/backups
sudo chown "$VPS_USER" /opt/cri-novadis/backups   # root (cron) y écrit toujours
```

### Revenir à une version précédente à la main

```bash
cd /opt/cri-novadis
docker images cri-novadis-api                     # tags = SHA de commit
docker tag cri-novadis-api:<sha> cri-novadis-api:latest
docker compose up -d api
curl -s http://localhost:5200/api/health/ready    # → {"status":"ready",...}
```

⚠️ Changer d'image ne défait pas une migration de base. Si la version cible est
antérieure à une migration, restaurer aussi le dump pré-déploiement correspondant
(`disaster-recovery.md`, scénario A).

---

## Surveillance

Deux sondes, deux rôles — ne jamais alerter sur la seule liveness :

| Sonde | Répond 200 si… | Consommée par |
|---|---|---|
| `GET /api/health/live` | le processus répond (même base injoignable) | healthcheck Docker (redémarrage) |
| `GET /api/health/ready` | base joignable en < 5 s et disque > 1 Go | monitoring externe, déploiement |

### Moniteurs à configurer (UptimeRobot, offre gratuite)

| Moniteur | URL | Intervalle | Alerte |
|---|---|---|---|
| API vivante | `https://api.cri-novadis.tech/api/health/live` | 1 min | code ≠ 200 |
| API prête | `https://api.cri-novadis.tech/api/health/ready` | 5 min | code ≠ 200 |
| Web | `https://cri-novadis.tech` | 5 min | code ≠ 200 |

Alertes par e-mail **et** SMS ou application mobile : une panne nocturne signalée
uniquement par e-mail n'est lue qu'au matin.

### Sauvegarde

Heartbeat quotidien (healthchecks.io) : `BACKUP_HEARTBEAT_URL` dans `.env`. Une
sauvegarde qui échoue, **ou qui reste locale**, ou qui ne tourne plus du tout, alerte.
Procédure : [`scripts/README-backup.md`](../scripts/README-backup.md#alerte-par-heartbeat).

### Vérifier la surveillance elle-même

À faire après la mise en place, puis à chaque changement d'infrastructure :

```bash
docker compose -f /opt/cri-novadis/docker-compose.yml stop db
# → « API prête » passe en alerte en moins de 5 min ; « API vivante » reste verte
docker compose -f /opt/cri-novadis/docker-compose.yml start db
# → notification de rétablissement
```

---

## Objectifs de reprise

| Objectif | Valeur | D'où elle vient |
|---|---|---|
| **RPO** — données perdues au pire | **24 h** | sauvegarde quotidienne à 3 h ; plus un dump avant chaque déploiement. Les CRI saisis hors ligne restent sur les appareils et se resynchronisent. |
| **RTO** — perte totale du serveur | **4 h** | budget ci-dessous |

Budget du RTO (scénario B de `disaster-recovery.md`) :

| Étape | Durée visée |
|---|---|
| Commander et préparer un VPS (Docker, rclone) | 45 min |
| Récupérer les sauvegardes depuis B2, reconstituer `/opt/cri-novadis` | 30 min |
| Recréer `.env` depuis le gestionnaire de mots de passe | 15 min |
| Déployer l'API (workflow manuel après mise à jour de `VPS_HOST`) | 20 min |
| Restaurer base et exports | 30 min |
| Réinstaller le tunnel Cloudflare | 15 min |
| Vérifications finales, connexion réelle d'un utilisateur | 30 min |
| **Marge** | 55 min |

Conditions pour tenir 4 h — chacune est un point de rupture :

1. Les valeurs de `.env` **et** le jeton du tunnel sont dans le gestionnaire de mots de passe.
2. Les identifiants B2, GitHub (secrets) et Cloudflare sont accessibles à au moins deux personnes.
3. La restauration a été exercée depuis moins de trois mois (tableau en fin de
   `disaster-recovery.md`).
