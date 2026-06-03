# Dockerfile para construir una imagen Oracle XE personalizada
# Esta imagen extiende la imagen oficial gvenzl/oracle-xe
# y permite empujarla a Docker Hub con un tag propio.

FROM gvenzl/oracle-xe

# Cambia la contraseña si quieres construir con otro valor.
ARG ORACLE_PASSWORD=Oracle123456
ENV ORACLE_PASSWORD=${ORACLE_PASSWORD}

# Puerto Oracle XE
EXPOSE 1521

# Healthcheck opcional para verificar que la DB está lista
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD echo "SELECT 1 FROM DUAL;" | sqlplus -s sys/${ORACLE_PASSWORD}@//localhost:1521/XE as sysdba | grep -q "1"
