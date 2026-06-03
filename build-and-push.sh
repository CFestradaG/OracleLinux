#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <docker-hub-usuario/repo> <tag> [ORACLE_PASSWORD]"
  echo "Ejemplo: $0 tuusuario/oracle-xe-custom latest Oracle123456"
  exit 1
fi

IMAGE_NAME="$1"
TAG="$2"
ORACLE_PASSWORD="${3:-Oracle123456}"

# Construir la imagen localmente
docker build \
  --build-arg ORACLE_PASSWORD="$ORACLE_PASSWORD" \
  -t "$IMAGE_NAME:$TAG" \
  .

# Subirla a Docker Hub
docker push "$IMAGE_NAME:$TAG"

echo "Imagen construida y subida: $IMAGE_NAME:$TAG"
