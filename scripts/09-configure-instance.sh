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

docker cp "$ROOT_DIR/scripts/02-configure-archivelog-fra.sql" "$CONTAINER_NAME:/tmp/configure-archivelog-fra.sql"
docker exec -i "$CONTAINER_NAME" bash -lc "sqlplus / as sysdba @/tmp/configure-archivelog-fra.sql"

echo "ARCHIVELOG y FRA configurados."
echo "Para Wallet/TDE revisa scripts/03-configure-wallet.sql y ejecútalo si tu Oracle XE soporta TDE."
