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

mkdir -p "$ROOT_DIR/oracle-data" "$ROOT_DIR/backups" "$ROOT_DIR/logs" "$ROOT_DIR/wallet"

docker run -d \
  --name "$CONTAINER_NAME" \
  -p 1521:1521 \
  -e ORACLE_PASSWORD="$ORACLE_PASSWORD" \
  -v "$ROOT_DIR/oracle-data:/opt/oracle/oradata" \
  -v "$ROOT_DIR/backups:$BACKUP_DIR" \
  -v "$ROOT_DIR/logs:$LOG_DIR" \
  -v "$ROOT_DIR/wallet:$WALLET_DIR" \
  "$IMAGE_NAME"

echo "Contenedor iniciado: $CONTAINER_NAME"
echo "Revisa el arranque con: docker logs -f $CONTAINER_NAME"
