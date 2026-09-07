# Backup serveur (DB + export-storage)

`backup-server.sh` sauvegarde chaque jour :
- un dump compressé de la base Postgres (`pg_dump` via le conteneur `cri-novadis-db-1`),
- une archive `tar.gz` du dossier `export-storage` (PDF/XLSX exportés),
- puis **copie le tout hors du VPS** via `rclone` (cf. « Copie hors site » plus bas).

Rétention : 14 jours en local, purge automatique des sauvegardes plus anciennes.

Le dump est écrit sous un nom temporaire `.part` et renommé seulement s'il dépasse
10 Ko : un `pg_dump` interrompu ne laisse donc jamais d'archive tronquée qui passerait
la rétention et partirait hors site.

## Installation sur le VPS

```bash
# Copier le script sur le serveur (depuis la machine de dev)
scp scripts/backup-server.sh remy@srv-cri-novadis:/opt/cri-novadis/backup-server.sh

# Sur le serveur
ssh remy@srv-cri-novadis
chmod +x /opt/cri-novadis/backup-server.sh

# Test manuel
sudo /opt/cri-novadis/backup-server.sh
```

## Planification (cron)

```bash
sudo crontab -e
```

Ajouter (backup tous les jours à 3h du matin) :

```
0 3 * * * /opt/cri-novadis/backup-server.sh >> /opt/cri-novadis/backups/backup.log 2>&1
```

## Copie hors site (obligatoire)

Une sauvegarde stockée sur la machine qu'elle protège n'en est pas une : une panne du VPS
(disque, incident hébergeur, suppression accidentelle du serveur) emporte les données **et**
leurs sauvegardes. Le script copie donc `backups/` vers un stockage objet externe.

Tant que `rclone` n'est pas configuré, le script **continue de fonctionner** mais affiche un
avertissement sur `stderr` — visible dans `backup.log` et dans le mail de cron.

### Configuration sur le VPS

```bash
# 1. Installer rclone
curl https://rclone.org/install.sh | sudo bash

# 2. Créer le remote (nom attendu : "offsite")
#    Choisir "s3" puis le fournisseur (Scaleway / OVH / Backblaze B2…)
rclone config

# 3. Vérifier
rclone listremotes                       # doit afficher "offsite:"
rclone ls offsite:cri-novadis-backups    # doit répondre sans erreur
```

Le remote et le bucket sont surchargeables sans modifier le script :

```bash
OFFSITE_REMOTE=autre-remote OFFSITE_BUCKET=autre-bucket ./backup-server.sh
```

### Règles à respecter

- **Clé d'accès restreinte** : droits limités au seul bucket, en écriture. Si le VPS est
  compromis, l'attaquant ne doit pas pouvoir effacer l'historique des sauvegardes.
- **Identifiants hors dépôt** : ils vivent dans `~/.config/rclone/rclone.conf` sur le serveur.
- **Cycle de vie côté bucket** : rétention 90 jours, suppression automatique au-delà
  (la rétention locale de 14 jours ne s'applique qu'au VPS).

## Vérifier que la sauvegarde est restaurable

Une sauvegarde jamais restaurée est une hypothèse, pas une garantie. À refaire après
toute modification du script, et au moins une fois par trimestre — **à partir de la copie
hors site**, pas de la copie locale.

### 1. Relever les compteurs de référence en production

```bash
docker exec cri-novadis-db-1 sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
  SELECT (SELECT count(*) FROM \"CRIForms\")          AS cris,
         (SELECT count(*) FROM \"Users\")             AS users,
         (SELECT count(*) FROM \"CRIPhotos\")         AS photos,
         (SELECT count(*) FROM \"ExportedDocuments\") AS documents;"'
```

### 2. Restaurer dans une base jetable

Le conteneur de test doit utiliser **les mêmes nom d'utilisateur et nom de base que la
production** : le dump contient des `ALTER ... OWNER TO cri_user`, qui échouent si le rôle
n'existe pas. `ON_ERROR_STOP=1` est indispensable — sans lui, `psql` poursuit après une
erreur et produit une restauration partielle qui *paraît* réussie.

Pas de `-p` : on n'accède au conteneur que par `docker exec`. Publier un port exposerait une
base avec le mot de passe `test` — inacceptable sur un serveur joignable depuis Internet.
`--memory=256m` borne le test, largement suffisant pour un dump de quelques centaines de Ko.

```bash
docker run -d --name pg-restore-test \
  --memory=256m \
  -e POSTGRES_USER=cri_user \
  -e POSTGRES_DB=cri_novadis \
  -e POSTGRES_PASSWORD=test \
  postgres:16-alpine

docker exec pg-restore-test pg_isready -U cri_user   # attendre "accepting connections"
```

La décompression se fait **dans le conteneur** plutôt que sur l'hôte : `postgres:16-alpine`
embarque `gzip`, ce qui évite de dépendre d'un `gunzip` côté hôte (absent de PowerShell) et
rend la procédure identique sous Windows et sous Linux.

```bash
docker cp db_<horodatage>.sql.gz pg-restore-test:/tmp/dump.sql.gz
docker exec pg-restore-test sh -c \
  "gunzip -c /tmp/dump.sql.gz | psql -U cri_user -d cri_novadis -v ON_ERROR_STOP=1"
```

### 3. Comparer

```bash
docker exec pg-restore-test psql -U cri_user -d cri_novadis -c "
  SELECT (SELECT count(*) FROM \"CRIForms\")          AS cris,
         (SELECT count(*) FROM \"Users\")             AS users,
         (SELECT count(*) FROM \"CRIPhotos\")         AS photos,
         (SELECT count(*) FROM \"ExportedDocuments\") AS documents;"
```

Les quatre compteurs doivent correspondre à ceux de l'étape 1.

### 4. Vérifier l'archive des exports et nettoyer

```bash
docker cp export-storage_<horodatage>.tar.gz pg-restore-test:/tmp/exports.tar.gz
docker exec pg-restore-test sh -c "tar tzf /tmp/exports.tar.gz | wc -l"    # nombre de fichiers
docker exec pg-restore-test sh -c "tar tzf /tmp/exports.tar.gz | head -20" # arborescence plausible
docker rm -f pg-restore-test
```

> **Où exécuter le test** — sur le VPS, c'est le plus simple : les archives y sont déjà et les
> compteurs de production se relèvent sur la même machine. Le conteneur de test étant plafonné
> à 256 Mo et le dump pesant quelques centaines de Ko, l'empreinte reste négligeable devant
> celle de l'API.
>
> Le faire depuis un autre poste reste préférable **le jour où l'on valide la copie hors site** :
> c'est le seul moyen de vérifier que les archives sont exploitables sans le VPS. Utiliser alors
> `scp` depuis l'adresse réelle du serveur (cf. `docs/deployment.md`), le hostname interne
> `srv-cri-novadis` n'étant pas résolvable hors du serveur.
