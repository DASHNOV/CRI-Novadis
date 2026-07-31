#!/usr/bin/env bash
# Sauvegarde quotidienne de la base Postgres + des documents exportés (export-storage).
# À exécuter sur le VPS, dans le dossier contenant docker-compose.yml (/opt/cri-novadis).
# Usage : ./backup-server.sh
# Cron  : voir scripts/README-backup.md

set -euo pipefail

APP_DIR="/opt/cri-novadis"
BACKUP_DIR="$APP_DIR/backups"
DB_CONTAINER="cri-novadis-db-1"
RETENTION_DAYS=14
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "[$TIMESTAMP] Dump de la base Postgres..."
docker exec "$DB_CONTAINER" sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip > "$BACKUP_DIR/db_${TIMESTAMP}.sql.gz"

echo "[$TIMESTAMP] Archive de export-storage..."
tar czf "$BACKUP_DIR/export-storage_${TIMESTAMP}.tar.gz" -C "$APP_DIR" export-storage

echo "[$TIMESTAMP] Nettoyage des sauvegardes de plus de ${RETENTION_DAYS} jours..."
find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime "+${RETENTION_DAYS}" -delete
find "$BACKUP_DIR" -name "export-storage_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete

echo "[$TIMESTAMP] Terminé. Fichiers présents dans $BACKUP_DIR :"
ls -lh "$BACKUP_DIR" | tail -n +2
