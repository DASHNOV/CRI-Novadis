# Procédure de restauration — CRI Novadis

> Document destiné à **toute personne devant remettre le service en état**, y compris
> sans connaissance préalable du projet.
> Dernière vérification réelle de la restauration : **2026-09-07** (39 CRI, 12 utilisateurs, zéro erreur).

**Lisez la section « Avant de commencer » en entier avant de taper la moindre commande.**
Une restauration mal engagée détruit les données qui restaient récupérables.

---

## Repères

| Élément | Valeur |
|---|---|
| Serveur | hostname interne `srv-cri-novadis`, dossier `/opt/cri-novadis` |
| Conteneurs | `cri-novadis-api-1`, `cri-novadis-db-1` |
| Base | `cri_novadis`, utilisateur `cri_user` |
| Sauvegardes locales | `/opt/cri-novadis/backups` — 14 jours |
| Sauvegardes hors site | Backblaze B2, bucket `cri-novadis-backups` — 90 jours |
| Dépôt | `github.com/DASHNOV/CRI-Novadis3.0`, branche **`main`** = production |
| API publique | `https://api.cri-novadis.tech` (via tunnel Cloudflare) |

Chaque sauvegarde quotidienne (3 h du matin) produit deux fichiers horodatés :

- `db_AAAAMMJJ_HHMMSS.sql.gz` — dump PostgreSQL complet
- `export-storage_AAAAMMJJ_HHMMSS.tar.gz` — PDF et XLSX exportés par les utilisateurs

---

## Avant de commencer

### 1. Ce qu'il faut avoir sous la main

| Élément | Où le trouver |
|---|---|
| Accès SSH au serveur | Clé personnelle, ou celle du dépôt (`secrets.VPS_SSH_KEY`) |
| Identifiants Backblaze B2 | **Gestionnaire de mots de passe partagé** |
| Contenu du fichier `.env` | **Gestionnaire de mots de passe partagé** |
| Accès au dépôt GitHub | Compte de l'organisation DASHNOV |
| Accès Cloudflare | Compte de l'organisation, pour le tunnel |

### 2. ⚠️ Le point qui fait échouer une reprise

Le fichier `/opt/cri-novadis/.env` contient le mot de passe PostgreSQL, la clé JWT et
les identifiants OAuth2 Microsoft Graph. **Il n'est ni dans le dépôt, ni dans les
sauvegardes.** S'il disparaît avec le serveur et qu'aucune copie n'existe ailleurs :

- la base peut être restaurée, mais avec un nouveau mot de passe ;
- la clé JWT peut être régénérée, au prix de la déconnexion de tous les utilisateurs ;
- **les identifiants Graph API ne peuvent pas être devinés.** Sans eux, l'envoi des codes
  OTP échoue, et *plus personne ne peut se connecter à l'application* — même avec une base
  parfaitement restaurée. Il faut alors recréer un secret client dans Entra ID (Azure AD),
  ce qui suppose d'avoir les droits sur le tenant.

**Si vous lisez ceci et que ces valeurs ne sont dans aucun gestionnaire de mots de passe,
arrêtez-vous et mettez-les-y maintenant.** C'est l'affaire de cinq minutes tant que le
serveur fonctionne, et d'un projet entier lorsqu'il ne fonctionne plus.
La liste des variables attendues est dans `.env.production.example`.

### 3. Règle absolue

**Avant toute restauration, sauvegardez l'état actuel**, même s'il paraît corrompu.
Une base abîmée contient souvent plus de données récupérables que la sauvegarde de la nuit.

```bash
cd /opt/cri-novadis && sudo ./backup-server.sh
```

Si le script échoue parce que la base est inaccessible, faites au moins une copie brute :

```bash
sudo cp -a /opt/cri-novadis /opt/cri-novadis.avant-restauration
```

---

## Scénario A — Le serveur fonctionne, les données sont perdues ou corrompues

Cas typique : suppression accidentelle, corruption applicative, retour arrière souhaité.

### A1. Sauvegarder l'état actuel

```bash
cd /opt/cri-novadis && sudo ./backup-server.sh
```

### A2. Choisir la sauvegarde à restaurer

```bash
ls -lh /opt/cri-novadis/backups/db_*.sql.gz
```

Prenez la plus récente **antérieure à l'incident**. Si les sauvegardes locales sont elles
aussi touchées, récupérez-la depuis Backblaze :

```bash
sudo rclone ls offsite:cri-novadis-backups
sudo rclone copy offsite:cri-novadis-backups/db_AAAAMMJJ_HHMMSS.sql.gz /opt/cri-novadis/backups/
```

### A3. Arrêter l'API

Indispensable : elle écrit en continu, et PostgreSQL refuse de supprimer une base ayant
des connexions actives.

```bash
cd /opt/cri-novadis
docker compose stop api
```

### A4. Recréer la base et restaurer

```bash
docker exec cri-novadis-db-1 psql -U cri_user -d postgres -c 'DROP DATABASE "cri_novadis";'
docker exec cri-novadis-db-1 psql -U cri_user -d postgres -c 'CREATE DATABASE "cri_novadis" OWNER cri_user;'

docker cp /opt/cri-novadis/backups/db_AAAAMMJJ_HHMMSS.sql.gz cri-novadis-db-1:/tmp/dump.sql.gz
docker exec cri-novadis-db-1 sh -c \
  'gunzip -c /tmp/dump.sql.gz | psql -U cri_user -d cri_novadis -v ON_ERROR_STOP=1'
```

`ON_ERROR_STOP=1` est essentiel : sans lui, `psql` poursuit après une erreur et produit une
restauration partielle qui *paraît* réussie.

### A5. Restaurer les documents exportés

À faire seulement s'ils sont également perdus.

```bash
cd /opt/cri-novadis
sudo tar xzf backups/export-storage_AAAAMMJJ_HHMMSS.tar.gz
sudo chown -R 1654:1654 export-storage
```

Le `chown` n'est pas optionnel — voir « Pièges connus ».

### A6. Redémarrer et vérifier

```bash
docker compose start api
docker compose ps
```

Passez ensuite à la section « Vérifications finales ».

---

## Scénario B — Le serveur est perdu

Cas typique : panne matérielle, incident hébergeur, serveur supprimé.

### B1. Préparer une machine neuve

Debian ou Ubuntu, **2 Gio de RAM minimum**, Docker et le plugin Compose installés.
Récupérez le nom d'hôte et l'adresse IP : ils devront être reportés dans Cloudflare (B7).

```bash
curl -fsSL https://get.docker.com | sh
curl https://rclone.org/install.sh | sudo bash
```

### B2. Récupérer les sauvegardes depuis Backblaze

Configurez rclone avec les identifiants B2 du gestionnaire de mots de passe :

```bash
rclone config          # remote nommé "offsite", type "b2"
rclone ls offsite:cri-novadis-backups
```

Puis récupérez la sauvegarde la plus récente :

```bash
sudo mkdir -p /opt/cri-novadis/backups
sudo rclone copy offsite:cri-novadis-backups /opt/cri-novadis/backups \
  --include "db_*.sql.gz" --include "export-storage_*.tar.gz" --max-age 48h --progress
```

**Copiez aussi la configuration rclone pour root**, sinon la sauvegarde automatique
échouera en silence une fois le service rétabli :

```bash
sudo mkdir -p /root/.config/rclone
sudo cp ~/.config/rclone/rclone.conf /root/.config/rclone/rclone.conf
sudo chmod 600 /root/.config/rclone/rclone.conf
```

### B3. Reconstituer l'arborescence

```bash
cd /opt/cri-novadis
sudo mkdir -p logs uploads export-storage
sudo chown -R 1654:1654 logs uploads export-storage
```

### B4. Récupérer la configuration depuis le dépôt

```bash
git clone --branch main https://github.com/DASHNOV/CRI-Novadis3.0.git /tmp/cri
sudo cp /tmp/cri/docker-compose.yml /opt/cri-novadis/
sudo cp /tmp/cri/scripts/backup-server.sh /opt/cri-novadis/
sudo chmod +x /opt/cri-novadis/backup-server.sh
```

### B5. Recréer le fichier `.env`

À partir du gestionnaire de mots de passe, en suivant `.env.production.example` :

```bash
sudo nano /opt/cri-novadis/.env
sudo chmod 600 /opt/cri-novadis/.env
```

**Aucune variable ne doit manquer.** Une valeur `EMAIL_*` absente laisse l'API démarrer
normalement mais empêche toute connexion utilisateur.

### B6. Construire l'image et démarrer

Le plus simple est de laisser GitHub Actions le faire : lancez le workflow
**Deploy API to Production** manuellement (`Actions` → `Run workflow` sur `main`), après
avoir mis à jour le secret `VPS_HOST` avec l'adresse de la nouvelle machine.

À défaut, construction directe sur le serveur :

```bash
cd /tmp/cri/backend/src/NovadisApi
sudo docker build -t cri-novadis-api:latest .
cd /opt/cri-novadis && sudo docker compose up -d
```

Au premier démarrage, l'API applique automatiquement les migrations sur une base vide.
Restaurez ensuite les données par le **scénario A, étapes A4 et A5**.

### B7. Rétablir l'accès public

Le tunnel Cloudflare pointe l'API publique vers `localhost:5200` du serveur. Il n'est pas
encore versionné dans le dépôt : reconfigurez-le depuis le tableau de bord Cloudflare
(*Zero Trust → Networks → Tunnels*) en faisant pointer `api.cri-novadis.tech` vers la
nouvelle machine, en mode **Full (Strict)**.

### B8. Rétablir la sauvegarde automatique

```bash
sudo crontab -e
```

Ajouter :

```
0 3 * * * /opt/cri-novadis/backup-server.sh >> /opt/cri-novadis/backups/backup.log 2>&1
```

Puis **tester dans les conditions exactes du cron**, ce qui n'est pas la même chose que
de le lancer depuis votre session :

```bash
sudo /opt/cri-novadis/backup-server.sh
```

La sortie doit se terminer par `Copie hors site terminée`.

---

## Vérifications finales

À dérouler dans l'ordre, quel que soit le scénario. Ne considérez le service rétabli
qu'une fois les cinq points validés.

**1. Les conteneurs sont sains**

```bash
docker compose -f /opt/cri-novadis/docker-compose.yml ps
```

`api` et `db` doivent afficher `Up ... (healthy)`.

**2. Les migrations sont à jour**

```bash
docker exec cri-novadis-db-1 psql -U cri_user -d cri_novadis -c 'SELECT * FROM "__EFMigrationsHistory";'
```

Le nombre de lignes doit correspondre au nombre de fichiers de migration dans
`backend/src/NovadisApi/Data/Migrations/` (hors `.Designer.cs` et le snapshot).
Un écart signale un problème de schéma — voir « Pièges connus ».

**3. Les données sont là**

```bash
docker exec cri-novadis-db-1 psql -U cri_user -d cri_novadis -c \
  'SELECT (SELECT count(*) FROM "CRIForms") AS cris, (SELECT count(*) FROM "Users") AS users;'
```

Comparez à ce que vous attendiez. Un nombre nul de CRI signifie que la restauration a échoué.

**4. L'API répond**

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5200/api/health/live   # → 200
curl -s http://localhost:5200/api/health/live
```

**5. Un utilisateur peut réellement se connecter**

C'est la seule vérification qui compte vraiment. Demandez un code de connexion depuis
l'application et vérifiez qu'il arrive par e-mail. Si le code n'arrive pas, les variables
`EMAIL_*` sont en cause.

---

## Pièges connus

Tous ont déjà provoqué un incident réel sur ce projet. Le détail est dans
[`resolved-issues.md`](resolved-issues.md).

**Les dossiers montés doivent appartenir à l'UID 1654.** Le conteneur tourne en
utilisateur non-root. Un `logs`, `uploads` ou `export-storage` appartenant à root fait
échouer toute écriture avec « Access to the path … is denied ». Le `chown` du Dockerfile
n'a aucun effet sur un montage.

```bash
sudo chown -R 1654:1654 /opt/cri-novadis/{logs,uploads,export-storage}
```

**« Migrations applied successfully » ne prouve rien.** Ce message apparaît même quand EF
n'a rien à faire. Vérifiez toujours l'état du schéma après coup (vérification 2).

**Un test de sauvegarde réussi sous votre compte ne prouve rien non plus.** Le cron
s'exécute en root, avec son propre environnement. Testez avec `sudo`.

**`psql` sans `ON_ERROR_STOP=1` poursuit après une erreur** et sort en code 0 sur une
restauration partielle. Utilisez toujours ce paramètre.

**Ne restaurez jamais dans une base sans avoir sauvegardé l'état courant.**

---

## Si la restauration échoue

1. Ne relancez pas la même commande en espérant un résultat différent — relisez le message d'erreur.
2. L'état d'avant reste disponible dans `/opt/cri-novadis.avant-restauration` ou dans la
   sauvegarde faite en A1.
3. Une sauvegarde plus ancienne reste utilisable : Backblaze en conserve 90 jours.
4. Les journaux applicatifs donnent la cause la plupart du temps :

```bash
docker compose -f /opt/cri-novadis/docker-compose.yml logs api --tail=100
```

---

## Entretien de cette procédure

Une procédure de reprise non testée est une hypothèse. **Déroulez le scénario A sur une
base jetable au moins une fois par trimestre** — la méthode est décrite dans
[`../scripts/README-backup.md`](../scripts/README-backup.md) — et mettez ce document à jour
à chaque changement d'infrastructure.

Notez ci-dessous la date de chaque exercice réel :

| Date | Scénario | Par | Résultat |
|---|---|---|---|
| 2026-09-07 | Restauration base sur conteneur jetable | Rémy | ✅ 39 CRI, 12 utilisateurs, zéro erreur |
