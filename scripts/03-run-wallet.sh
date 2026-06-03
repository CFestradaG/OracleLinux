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

TMP_SQL="$(mktemp)"
sed "s/Wallet123456/${TDE_WALLET_PASSWORD//\//\\/}/g" \
  "$ROOT_DIR/scripts/03-configure-wallet.sql" > "$TMP_SQL"

docker cp "$TMP_SQL" "$CONTAINER_NAME:/tmp/configure-wallet.sql"
rm -f "$TMP_SQL"

docker exec -i "$CONTAINER_NAME" bash -lc "sqlplus / as sysdba @/tmp/configure-wallet.sql"

echo "Wallet/TDE configurado o se mostró la limitación del entorno."
