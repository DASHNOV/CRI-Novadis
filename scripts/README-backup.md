# Backup serveur (DB + export-storage)

`backup-server.sh` sauvegarde chaque jour :
- un dump compressé de la base Postgres (`pg_dump` via le conteneur `cri-novadis-db-1`),
- une archive `tar.gz` du dossier `export-storage` (PDF/XLSX exportés).

Rétention : 14 jours en local, purge automatique des sauvegardes plus anciennes.

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

## Important : copie hors du serveur

Ce script protège contre une perte de fichiers/DB **sur le conteneur ou le dossier**, mais pas contre une panne du VPS lui-même (disque, suppression accidentelle du serveur). Les fichiers dans `backups/` doivent être régulièrement copiés **ailleurs** :

- `rsync`/`scp` vers un autre serveur ou une machine de dev, ou
- un stockage objet externe (S3/OVH/Scaleway), via `rclone` par exemple.

Exemple simple avec `rsync` (à ajouter en fin de script ou en second cron), si un second hôte est disponible :

```bash
rsync -az /opt/cri-novadis/backups/ user@autre-serveur:/backups/cri-novadis/
```

À mettre en place dès qu'une destination hors-site est disponible — sans ça, les backups restent vulnérables au même risque que les données qu'ils protègent.
