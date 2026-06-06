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

HOST_PORT="${HOST_PORT:-1522}"
CONTAINER_PORT="${CONTAINER_PORT:-1521}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "Ya existe un contenedor llamado $CONTAINER_NAME."
  echo "Si quieres recrearlo, ejecuta: docker rm -f $CONTAINER_NAME"
  exit 1
fi

docker run -d \
  --platform "$DOCKER_PLATFORM" \
  --name "$CONTAINER_NAME" \
  -p "$HOST_PORT:$CONTAINER_PORT" \
  -e ORACLE_PASSWORD="$ORACLE_PASSWORD" \
  -v "$ROOT_DIR/oracle-data:/opt/oracle/oradata" \
  -v "$ROOT_DIR/backups:$BACKUP_DIR" \
  -v "$ROOT_DIR/logs:$LOG_DIR" \
  -v "$ROOT_DIR/wallet:$WALLET_DIR" \
  "$IMAGE_NAME"

echo "Contenedor iniciado: $CONTAINER_NAME"
echo "Puerto local: $HOST_PORT -> puerto Oracle del contenedor: $CONTAINER_PORT"
echo "Revisa el arranque con: docker logs -f $CONTAINER_NAME"
