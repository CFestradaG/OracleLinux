#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
else
  echo "No existe .env. Copia scripts/env.example como .env y ajusta valores."
  exit 1
fi

mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/backups"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$ROOT_DIR/logs/rman_backup_$TIMESTAMP.log"

echo "Iniciando backup RMAN: $TIMESTAMP" | tee "$LOG_FILE"

if docker cp "$ROOT_DIR/scripts/04-backup_full.rman" "$CONTAINER_NAME:/tmp/backup_full.rman" \
  && docker exec "$CONTAINER_NAME" bash -lc "rman cmdfile=/tmp/backup_full.rman log=$LOG_DIR/rman_backup_$TIMESTAMP.log"; then
  docker cp "$CONTAINER_NAME:$LOG_DIR/rman_backup_$TIMESTAMP.log" "$LOG_FILE" >/dev/null 2>&1 || true
  echo "Backup finalizado correctamente. Log: $LOG_FILE"
else
  echo "ERROR: falló el backup RMAN. Revisar log: $LOG_FILE" | tee -a "$LOG_FILE"
  exit 1
fi
