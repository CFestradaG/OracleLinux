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

mkdir -p "$ROOT_DIR/logs"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$ROOT_DIR/logs/rman_restore_validate_$TIMESTAMP.log"

echo "Iniciando RESTORE VALIDATE: $TIMESTAMP" | tee "$LOG_FILE"

if docker cp "$ROOT_DIR/scripts/06-restore-validate.rman" "$CONTAINER_NAME:/tmp/restore_validate.rman" \
  && docker exec "$CONTAINER_NAME" bash -lc "rman cmdfile=/tmp/restore_validate.rman log=$LOG_DIR/rman_restore_validate_$TIMESTAMP.log"; then
  docker cp "$CONTAINER_NAME:$LOG_DIR/rman_restore_validate_$TIMESTAMP.log" "$LOG_FILE" >/dev/null 2>&1 || true
  echo "Restore validate finalizado correctamente. Log: $LOG_FILE"
else
  echo "ERROR: falló RESTORE VALIDATE. Revisar log: $LOG_FILE" | tee -a "$LOG_FILE"
  exit 1
fi
