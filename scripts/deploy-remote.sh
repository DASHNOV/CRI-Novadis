#!/usr/bin/env bash
# Déploiement de l'API sur le serveur, avec retour arrière automatique.
# Appelé par .github/workflows/deploy-api.yml après transfert de l'image.
#
# Usage : deploy-remote.sh <archive-image.tar> <tag>
#   <tag> : SHA du commit — l'image est chargée sous cri-novadis-api:<tag>,
#           puis retaguée :latest (le tag lu par docker-compose.yml).
#
# Déroulé :
#   1. mémorise l'image en service (cible du retour arrière) ;
#   2. dump de la base AVANT déploiement — l'API applique ses migrations au
#      démarrage, et un retour arrière d'image ne défait pas une migration ;
#   3. charge l'image, redémarre ;
#   4. attend /api/health/ready = 200 (base joignable, pas seulement processus vivant) ;
#   5. en cas d'échec : journaux, retour sur l'image précédente, sortie en erreur.
#
# Surchargeable pour les tests : APP_DIR, IMAGE_NAME, HEALTH_URL, READY_TIMEOUT, KEEP_IMAGES.

set -euo pipefail

# Pas d'apostrophe dans les messages ${x:?...} : bash les apparie d'une ligne à l'autre.
ARCHIVE="${1:?usage: deploy-remote.sh <archive.tar> <tag>}"
TAG="${2:?usage: deploy-remote.sh <archive.tar> <tag>}"

APP_DIR="${APP_DIR:-/opt/cri-novadis}"
IMAGE_NAME="${IMAGE_NAME:-cri-novadis-api}"
HEALTH_URL="${HEALTH_URL:-http://localhost:5200/api/health}"
READY_TIMEOUT="${READY_TIMEOUT:-150}"   # start_period 40 s + migrations
KEEP_IMAGES="${KEEP_IMAGES:-5}"         # images taguées conservées pour revenir en arrière
BACKUP_DIR="$APP_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log() { echo "[deploy $TIMESTAMP] $*"; }

cd "$APP_DIR"

wait_ready() {
  local deadline=$((SECONDS + READY_TIMEOUT))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if curl -fsS -m 5 -o /dev/null "$HEALTH_URL/ready"; then
      return 0
    fi
    sleep 5
  done
  return 1
}

# ── 1. Image en service ─────────────────────────────────────────────────────
PREV_CONTAINER=$(docker compose ps -q api 2>/dev/null || true)
PREV_IMAGE=""
if [ -n "$PREV_CONTAINER" ]; then
  PREV_IMAGE=$(docker inspect --format '{{.Image}}' "$PREV_CONTAINER")
  log "Image en service : $PREV_IMAGE"
else
  log "Aucune API en service (première installation) : ni dump ni retour arrière possibles."
fi

# ── 2. Dump pré-déploiement ─────────────────────────────────────────────────
# Nom en db_*.sql.gz : backup-server.sh le copie hors site et le purge à 14 jours.
# Bloquant : sans filet, on ne lance pas des migrations irréversibles.
if [ -n "$PREV_CONTAINER" ]; then
  mkdir -p "$BACKUP_DIR"
  DUMP="$BACKUP_DIR/db_predeploy_${TIMESTAMP}_${TAG:0:7}.sql.gz"
  trap 'rm -f "$DUMP.part"' EXIT   # pas de dump tronqué laissé derrière un échec
  log "Dump pré-déploiement → $DUMP"
  docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$DUMP.part"
  if [ "$(stat -c%s "$DUMP.part")" -lt 10240 ]; then
    rm -f "$DUMP.part"
    log "ÉCHEC : dump anormalement petit — déploiement annulé, rien n'a été modifié."
    exit 1
  fi
  mv "$DUMP.part" "$DUMP"
fi

# ── 3. Chargement et redémarrage ────────────────────────────────────────────
docker load -i "$ARCHIVE"
rm -f "$ARCHIVE"
docker image inspect "$IMAGE_NAME:$TAG" >/dev/null   # l'archive contenait-elle le bon tag ?
docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:latest"
docker compose up -d --remove-orphans

# ── 4. Vérification ─────────────────────────────────────────────────────────
log "Attente de $HEALTH_URL/ready (max ${READY_TIMEOUT} s)..."
if wait_ready; then
  log "Déploiement réussi : $IMAGE_NAME:$TAG en service, base joignable."
  # Élagage : garde les KEEP_IMAGES tags de commit les plus récents. Non bloquant.
  docker images "$IMAGE_NAME" --format '{{.Tag}}' \
    | grep -v -e '^latest$' -e '^<none>$' \
    | tail -n +"$((KEEP_IMAGES + 1))" \
    | while read -r old; do docker rmi "$IMAGE_NAME:$old" >/dev/null 2>&1 || true; done
  docker compose ps
  exit 0
fi

# ── 5. Retour arrière ───────────────────────────────────────────────────────
log "ÉCHEC : l'API n'est pas prête après ${READY_TIMEOUT} s. Derniers journaux :"
docker compose logs --tail=80 api || true

if [ -z "$PREV_IMAGE" ]; then
  log "Pas d'image précédente : aucun retour arrière possible."
  exit 1
fi

log "Retour arrière sur $PREV_IMAGE..."
docker tag "$PREV_IMAGE" "$IMAGE_NAME:latest"
docker compose up -d api
if wait_ready; then
  log "Retour arrière réussi : l'image précédente est de nouveau en service."
else
  log "Retour arrière ÉCHOUÉ : l'image précédente ne démarre pas non plus."
fi
log "⚠️  Une migration a pu s'appliquer avant l'échec : l'ancienne image tourne alors"
log "    sur un schéma plus récent. Si l'API reste en erreur, restaurer $DUMP"
log "    (docs/disaster-recovery.md, scénario A)."
exit 1
