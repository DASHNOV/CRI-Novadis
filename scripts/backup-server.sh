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

# Copie hors site (rclone). Le remote et le bucket sont surchargeables par
# variable d'environnement ; les identifiants restent dans ~/.config/rclone/rclone.conf
# sur le serveur, jamais dans le dépôt.
OFFSITE_REMOTE="${OFFSITE_REMOTE:-offsite}"
OFFSITE_BUCKET="${OFFSITE_BUCKET:-cri-novadis-backups}"

mkdir -p "$BACKUP_DIR"

echo "[$TIMESTAMP] Dump de la base Postgres..."
# Écriture sous un nom temporaire, renommé seulement si le dump aboutit : sans ça
# un pg_dump interrompu laisse un .sql.gz tronqué qui passe la rétention et part
# hors site, et l'on ne s'en aperçoit qu'au moment de restaurer.
DB_TMP="$BACKUP_DIR/.db_${TIMESTAMP}.sql.gz.part"
docker exec "$DB_CONTAINER" sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip > "$DB_TMP"

DB_SIZE=$(stat -c%s "$DB_TMP")
if [ "$DB_SIZE" -lt 10240 ]; then
  echo "[$TIMESTAMP] ERREUR : dump anormalement petit (${DB_SIZE} octets) — abandon." >&2
  rm -f "$DB_TMP"
  exit 1
fi
mv "$DB_TMP" "$BACKUP_DIR/db_${TIMESTAMP}.sql.gz"

echo "[$TIMESTAMP] Archive de export-storage..."
tar czf "$BACKUP_DIR/export-storage_${TIMESTAMP}.tar.gz" -C "$APP_DIR" export-storage

echo "[$TIMESTAMP] Nettoyage des sauvegardes de plus de ${RETENTION_DAYS} jours..."
find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime "+${RETENTION_DAYS}" -delete
find "$BACKUP_DIR" -name "export-storage_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete

echo "[$TIMESTAMP] Copie hors site..."
# Le bloc est conditionnel pour que le script reste fonctionnel tant que rclone
# n'est pas encore configuré sur le serveur (cf. scripts/README-backup.md).
# L'avertissement est volontairement bruyant : une sauvegarde restée locale
# n'est pas une sauvegarde.
if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q "^${OFFSITE_REMOTE}:$"; then
  rclone copy "$BACKUP_DIR" "${OFFSITE_REMOTE}:${OFFSITE_BUCKET}" \
    --include "db_*.sql.gz" \
    --include "export-storage_*.tar.gz" \
    --max-age 48h \
    --log-level INFO
  echo "[$TIMESTAMP] Copie hors site terminée vers ${OFFSITE_REMOTE}:${OFFSITE_BUCKET}"
else
  echo "[$TIMESTAMP] AVERTISSEMENT : remote rclone '${OFFSITE_REMOTE}' introuvable —" >&2
  echo "[$TIMESTAMP] les sauvegardes restent SUR LE VPS et ne survivront pas à sa perte." >&2
fi

echo "[$TIMESTAMP] Terminé. Fichiers présents dans $BACKUP_DIR :"
ls -lh "$BACKUP_DIR" | tail -n +2
