# Oracle XE Docker Project

Este repositorio contiene los archivos para crear, publicar y validar una imagen Docker con Oracle Database XE.

## Estructura del repositorio

- `Dockerfile` — Extiende la imagen oficial `gvenzl/oracle-xe` para crear una imagen personalizada.
- `build-and-push.sh` — Script que construye la imagen y la publica en Docker Hub.
- `README.md` — Documentación paso a paso.
- `.gitignore` — Archivos y carpetas a ignorar en Git.

## Objetivo

Crear una imagen Docker de Oracle XE, publicarla en Docker Hub y mantener evidencia del proyecto en GitHub.

## Requisitos

- Docker instalado y en ejecución.
- Cuenta en Docker Hub.
- Usuario de Docker Hub: `cestrda`.
- Cuenta de GitHub (opcional pero recomendado para documentación y evidencia).

## Paso 1: Iniciar sesión en Docker Hub

```bash
docker login
```

Si aún no estás autenticado, el comando pedirá usuario y contraseña.

## Paso 2: Construir la imagen Docker

Desde el directorio del proyecto:

```bash
cd /Volumes/Respaldo1/OracleLinux
./build-and-push.sh cestrda/oracle-xe-custom latest Oracle123456
```

Esto hará dos cosas:
- construye la imagen local `cestrda/oracle-xe-custom:latest`
- sube la imagen a Docker Hub

## Paso 3: Verificar la imagen local

```bash
docker images | grep cestrda/oracle-xe-custom
```

Deberías ver una línea similar a:

```text
cestrda/oracle-xe-custom   latest   ...
```

## Paso 4: Verificar la imagen en Docker Hub

Desde cualquier equipo o desde el mismo host:

```bash
docker pull cestrda/oracle-xe-custom:latest
```

Si el `pull` funciona, la imagen está correctamente publicada.

## Paso 5: Ejecutar el contenedor Oracle XE

```bash
docker run -d --name oracle-xe-custom -p 1521:1521 cestrda/oracle-xe-custom:latest
```

Si deseas verificar el startup en tiempo real:

```bash
docker logs -f oracle-xe-custom
```

## Paso 6: Conectarse a Oracle XE

```bash
docker exec -it oracle-xe-custom sqlplus sys/Oracle123456@localhost:1521/XE as sysdba
```

Dentro de SQL*Plus, ejecuta:

```sql
SELECT banner FROM v$version;
SELECT name FROM v$database;
SHOW USER;
```

## Demostración para el ingeniero

1. Mostrar el repositorio GitHub con los archivos:
   - `Dockerfile`
   - `build-and-push.sh`
   - `README.md`
2. Mostrar el repositorio Docker Hub `cestrda/oracle-xe-custom` con el tag `latest`.
3. Ejecutar el contenedor localmente:
   - `docker run -d --name oracle-xe-custom -p 1521:1521 cestrda/oracle-xe-custom:latest`
4. Conectarse y validar Oracle XE con SQL*Plus.

## Uso desde otra máquina

```bash
docker pull cestrda/oracle-xe-custom:latest

docker run -d --name oracle-xe-custom -p 1521:1521 cestrda/oracle-xe-custom:latest
```

## Cómo registrar el proyecto en GitHub

1. Crea un repositorio nuevo en GitHub.
2. Desde el directorio local del proyecto:

```bash
git init
git add Dockerfile build-and-push.sh README.md .gitignore
git commit -m "Agregar proyecto Oracle XE Docker"
git branch -M main
git remote add origin https://github.com/<tu-usuario>/<tu-repo>.git
git push -u origin main
```

3. En GitHub se guardará la evidencia del código, la configuración del Dockerfile y los scripts de build/push.

## Importante sobre Docker Hub vs GitHub

- Docker Hub almacena la imagen binaria: el contenedor listo para ejecutar.
- GitHub almacena el código fuente del proyecto: Dockerfile, scripts y documentación.
- La imagen Docker no guarda el historial de Git ni la información del repositorio.

## Recomendación

Mantén este repositorio en GitHub y usa Docker Hub para la imagen publicada. Así tendrás evidencia tanto del código como del artefacto de despliegue.
