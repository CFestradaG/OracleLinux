# Proyecto Integral: Backups Seguros en Oracle Database XE

Este proyecto documenta y prepara una solución de respaldos para Oracle Database XE con enfoque empresarial: automatización, seguridad, retención, mantenimiento y validación de restauración.

El PDF del proyecto solicita una solución que incluya:

- Modo `ARCHIVELOG`.
- Uso de `Flash Recovery Area (FRA)`.
- Política de retención de 7 días.
- `Software Keystore / Wallet` para cifrado.
- Backupsets cifrados con `AES128`.
- Script profesional de `RMAN`.
- Automatización desde sistema operativo.
- Logs y alerta ante fallos.
- Prueba de restauración con `RESTORE VALIDATE`.

> Estado actual: este repositorio ya tiene la base Docker para levantar Oracle XE y ahora agrega los scripts necesarios para abordar la rúbrica técnica del proyecto.

---

## 1. Estructura del repositorio

```text
.
├── Dockerfile
├── build-and-push.sh
├── README.md
├── scripts/
│   ├── env.example
│   ├── 01-run-oracle.sh
│   ├── 02-configure-archivelog-fra.sql
│   ├── 03-configure-wallet.sql
│   ├── 04-backup_full.rman
│   ├── 05-run-backup.sh
│   ├── 06-restore-validate.rman
│   ├── 07-run-restore-validate.sh
│   ├── 08-cron.example
│   └── 09-configure-instance.sh
└── .gitignore
```

Carpetas generadas en ejecución:

- `oracle-data/`: archivos de datos de Oracle.
- `backups/`: backupsets generados por RMAN.
- `logs/`: logs de ejecución.
- `wallet/`: archivos del keystore/wallet.

Estas carpetas no se suben a Git porque contienen datos pesados o sensibles.

---

## 2. Requisitos previos

- Docker instalado y en ejecución.
- Imagen Oracle XE construida o descargada.
- Permisos para ejecutar scripts Bash.
- Conocimiento básico de `sqlplus` y `rman`.

Usuario Docker Hub usado en este proyecto:

```bash
cestrda
```

Imagen esperada:

```bash
cestrda/oracle-xe-custom:latest
```

---

## 3. Construir y publicar la imagen Docker

El archivo `Dockerfile` extiende la imagen `gvenzl/oracle-xe` y define una base para Oracle XE.

Para construir y subir la imagen:

```bash
docker login
./build-and-push.sh cestrda/oracle-xe-custom latest Oracle123456
```

Validación:

```bash
docker images | grep cestrda/oracle-xe-custom
docker pull cestrda/oracle-xe-custom:latest
```

Explicación para defender:

- Docker permite entregar un ambiente reproducible.
- La imagen contiene Oracle XE listo para ejecutar.
- GitHub conserva el código fuente; Docker Hub conserva el artefacto ejecutable.

---

## 4. Configuración inicial

Copiar el archivo de variables:

```bash
cp scripts/env.example .env
```

Editar `.env` si se necesitan otros valores:

```bash
CONTAINER_NAME=oracle-xe-backup-lab
IMAGE_NAME=cestrda/oracle-xe-custom:latest
HOST_PORT=1522
CONTAINER_PORT=1521
ORACLE_PASSWORD=Oracle123456
TDE_WALLET_PASSWORD=Wallet123456
```

Importante:

- `.env` no debe subirse a Git.
- En una empresa, las contraseñas se manejan con un secreto seguro, no dentro del repositorio.

---

## 5. Levantar Oracle XE

Ejecutar:

```bash
chmod +x scripts/*.sh
./scripts/01-run-oracle.sh
```

Verificar arranque:

```bash
docker logs -f oracle-xe-backup-lab
```

Conectarse como administrador:

```bash
docker exec -it oracle-xe-backup-lab sqlplus sys/Oracle123456@localhost:1521/XE as sysdba
```

Si te conectas desde tu Mac usando un cliente externo, usa el puerto definido en `.env`:

```text
localhost:1522/XE
```

Consultas de validación:

```sql
SELECT banner FROM v$version;
SELECT name, log_mode FROM v$database;
SHOW CON_NAME;
SHOW PDBS;
```

---

## 6. Configurar ARCHIVELOG y FRA

El PDF exige:

- `ARCHIVELOG`.
- `Flash Recovery Area (FRA)`.

Script:

```text
scripts/02-configure-archivelog-fra.sql
```

Ejecución:

```bash
./scripts/09-configure-instance.sh
```

Qué hace:

```sql
ALTER SYSTEM SET db_recovery_file_dest_size = 10G SCOPE=BOTH;
ALTER SYSTEM SET db_recovery_file_dest = '/opt/oracle/oradata/fast_recovery_area' SCOPE=BOTH;
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ARCHIVE LOG LIST;
```

Explicación para defender:

- `ARCHIVELOG` permite recuperación punto en el tiempo.
- Sin `ARCHIVELOG`, Oracle solo puede recuperar hasta el último backup frío o consistente.
- `FRA` centraliza archivos de recuperación: archive logs, controlfile autobackups y otros archivos administrados por Oracle.

Validación:

```sql
SELECT name, log_mode FROM v$database;
SHOW PARAMETER db_recovery_file_dest;
SHOW PARAMETER db_recovery_file_dest_size;
ARCHIVE LOG LIST;
```

Resultado esperado:

```text
Database log mode              Archive Mode
```

---

## 7. Configurar Wallet / Software Keystore

El PDF exige uso de `Software Keystore (Wallet)` y cifrado `AES128`.

Scripts:

```text
scripts/03-configure-wallet.sql
scripts/03-run-wallet.sh
```

Ejecución recomendada:

```bash
./scripts/03-run-wallet.sh
```

Qué intenta configurar:

```sql
ALTER SYSTEM SET wallet_root = '/opt/oracle/admin/XE/wallet' SCOPE=SPFILE;
ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE=BOTH;

ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '/opt/oracle/admin/XE/wallet/tde'
  IDENTIFIED BY "Wallet123456";

ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
  IDENTIFIED BY "Wallet123456" CONTAINER=ALL;

ADMINISTER KEY MANAGEMENT SET KEY
  IDENTIFIED BY "Wallet123456" WITH BACKUP CONTAINER=ALL;
```

Validación:

```sql
SELECT wrl_type, wrl_parameter, status, wallet_type
FROM v$encryption_wallet;
```

Resultado esperado:

```text
STATUS = OPEN
WALLET_TYPE = PASSWORD
```

Nota técnica importante:

- Algunas ediciones o imágenes de Oracle XE pueden limitar funcionalidades TDE.
- Si el entorno no permite TDE, se debe documentar como limitación de edición/imagen y demostrar el procedimiento preparado.
- Para fines de rúbrica, el punto defendible es explicar el flujo: crear keystore, abrir wallet, generar master key y usar cifrado RMAN `AES128`.

---

## 8. Script RMAN profesional

Script principal:

```text
scripts/04-backup_full.rman
```

Contenido clave:

```rman
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO COMPRESSED BACKUPSET;
CONFIGURE ENCRYPTION ALGORITHM 'AES128';
CONFIGURE ENCRYPTION FOR DATABASE ON;

RUN {
  SQL "ALTER SYSTEM ARCHIVE LOG CURRENT";

  CROSSCHECK BACKUP;
  CROSSCHECK ARCHIVELOG ALL;
  DELETE NOPROMPT EXPIRED BACKUP;
  DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;

  BACKUP AS COMPRESSED BACKUPSET
    DATABASE PLUS ARCHIVELOG
    FORMAT '/opt/oracle/backups/full_%d_%T_%U.bkp'
    TAG 'FULL_ENCRYPTED_BACKUP';

  BACKUP CURRENT CONTROLFILE
    FORMAT '/opt/oracle/backups/controlfile_%d_%T_%U.bkp'
    TAG 'CONTROLFILE_BACKUP';

  DELETE NOPROMPT OBSOLETE;
}
```

Qué cumple:

- Respaldo integral de base de datos.
- Incluye archive logs.
- Incluye controlfile.
- Usa compresión.
- Usa cifrado `AES128`.
- Define retención de 7 días.
- Limpia respaldos expirados y obsoletos.
- Genera backupsets identificables por `TAG`.

Explicación para defender:

- `DATABASE PLUS ARCHIVELOG` respalda datos y logs necesarios para recuperación.
- `CONTROLFILE AUTOBACKUP ON` protege la metadata crítica de RMAN.
- `CROSSCHECK` sincroniza el catálogo RMAN con archivos reales del disco.
- `DELETE EXPIRED` limpia referencias inválidas.
- `DELETE OBSOLETE` aplica la política de retención de 7 días.

---

## 9. Ejecutar backup automatizado

Script:

```text
scripts/05-run-backup.sh
```

Ejecución:

```bash
./scripts/05-run-backup.sh
```

Qué hace:

- Copia el script RMAN al contenedor.
- Ejecuta `rman`.
- Genera logs con timestamp.
- Devuelve error si falla.
- Guarda evidencia en `logs/`.

Validaciones:

```bash
ls -lh backups/
ls -lh logs/
grep -i "finished backup" logs/rman_backup_*.log
grep -i "error\\|failed\\|ora-" logs/rman_backup_*.log
```

---

## 10. Automatización con cron

Archivo de ejemplo:

```text
scripts/08-cron.example
```

Contenido:

```cron
0 23 * * * cd /Volumes/Respaldo1/OracleLinux && /bin/bash scripts/05-run-backup.sh >> logs/cron_backup.log 2>&1
```

Instalación:

```bash
crontab -e
```

Pegar la línea del ejemplo.

Explicación para defender:

- La automatización elimina dependencia manual.
- Los logs permiten auditoría.
- Si el script falla, retorna código diferente de cero y queda registrado en logs.

Mejora opcional para alerta:

- Enviar correo con `mail`.
- Integrar webhook de Teams/Slack.
- Usar monitoreo del sistema para revisar el log y alertar si aparece `ORA-`, `RMAN-` o `ERROR`.

---

## 11. Prueba de restauración: RESTORE VALIDATE

El PDF pide evidencia de restauración exitosa.

Script RMAN:

```text
scripts/06-restore-validate.rman
```

Ejecución:

```bash
./scripts/07-run-restore-validate.sh
```

Qué hace:

```rman
RESTORE DATABASE VALIDATE;
RESTORE ARCHIVELOG ALL VALIDATE;
LIST BACKUP SUMMARY;
```

Explicación para defender:

- `RESTORE VALIDATE` no sobrescribe la base.
- RMAN lee los backupsets y verifica que son restaurables.
- Es una prueba segura para demostrar recuperabilidad sin destruir el ambiente.

Validación esperada en logs:

```text
Finished restore
validation complete
```

---

## 12. Matriz de cumplimiento contra rúbrica

| Criterio | Puntos | Evidencia en este proyecto | Estado |
|---|---:|---|---|
| Cifrado y Wallet | 3 | `scripts/03-configure-wallet.sql`, `CONFIGURE ENCRYPTION ALGORITHM 'AES128'` | Preparado; depende de soporte TDE en la imagen |
| Lógica RMAN y Multitenant | 3 | `scripts/04-backup_full.rman`, `DATABASE PLUS ARCHIVELOG`, `SHOW PDBS` | Preparado |
| Mantenimiento y FRA | 3 | `scripts/02-configure-archivelog-fra.sql`, `CROSSCHECK`, `DELETE OBSOLETE` | Preparado |
| Automatización y Alertas | 3 | `scripts/05-run-backup.sh`, `scripts/08-cron.example`, logs con timestamp | Preparado |
| Documentación y Restore Validate | 3 | `README.md`, `scripts/06-restore-validate.rman`, `scripts/07-run-restore-validate.sh` | Preparado |

---

## 13. Orden recomendado para la demostración

1. Mostrar el PDF y explicar los 5 criterios de la rúbrica.
2. Mostrar GitHub con:
   - `Dockerfile`
   - `scripts/`
   - `README.md`
3. Levantar Oracle XE:

   ```bash
   ./scripts/01-run-oracle.sh
   ```

4. Validar base:

   ```sql
   SELECT name, log_mode FROM v$database;
   SHOW PDBS;
   ```

5. Configurar `ARCHIVELOG` y `FRA`:

   ```bash
   ./scripts/09-configure-instance.sh
   ```

6. Mostrar wallet:

   ```bash
   ./scripts/03-run-wallet.sh
   ```

7. Validar wallet:

   ```sql
   SELECT status, wallet_type FROM v$encryption_wallet;
   ```

8. Ejecutar backup:

   ```bash
   ./scripts/05-run-backup.sh
   ```

9. Mostrar evidencia:

   ```bash
   ls -lh backups/
   ls -lh logs/
   ```

10. Ejecutar validación:

   ```bash
   ./scripts/07-run-restore-validate.sh
   ```

11. Explicar la limpieza:

   ```rman
   CROSSCHECK BACKUP;
   DELETE NOPROMPT OBSOLETE;
   ```

---

## 14. Preguntas probables del ingeniero y respuestas

### ¿Por qué se usa ARCHIVELOG?

Porque permite recuperación punto en el tiempo. Sin `ARCHIVELOG`, si ocurre una falla después del último backup, se pierden los cambios posteriores.

### ¿Qué es FRA?

Es un área administrada por Oracle para guardar archivos de recuperación. Centraliza archive logs, backups y controlfiles, facilitando administración de espacio.

### ¿Por qué retención de 7 días?

Porque la rúbrica pide una ventana de recuperación de 7 días. RMAN la implementa con:

```rman
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
```

### ¿Qué hace CROSSCHECK?

Verifica si los backups registrados por RMAN todavía existen físicamente. Si no existen, los marca como `EXPIRED`.

### ¿Diferencia entre EXPIRED y OBSOLETE?

- `EXPIRED`: RMAN cree que existe, pero el archivo ya no está en disco.
- `OBSOLETE`: el backup existe, pero ya no es necesario según la política de retención.

### ¿Por qué cifrado AES128?

Porque protege los backupsets si alguien copia los archivos `.bkp`. Aunque el atacante tenga el archivo, no puede leerlo sin la llave.

### ¿Qué demuestra RESTORE VALIDATE?

Demuestra que RMAN puede leer y validar los backups sin restaurar físicamente la base. Es una prueba segura de recuperabilidad.

### ¿Qué pasa si Oracle XE no permite TDE?

Se documenta como limitación de edición/imagen. El proyecto conserva el procedimiento correcto de Wallet y RMAN encryption, y la defensa técnica explica que en una edición con soporte TDE se ejecuta igual.

---

## 15. Comandos rápidos de validación

Entrar al contenedor:

```bash
docker exec -it oracle-xe-backup-lab bash
```

Entrar a SQLPlus:

```bash
sqlplus / as sysdba
```

Validar modo archive:

```sql
ARCHIVE LOG LIST;
SELECT name, log_mode FROM v$database;
```

Validar FRA:

```sql
SHOW PARAMETER db_recovery_file_dest;
```

Validar wallet:

```sql
SELECT status, wallet_type FROM v$encryption_wallet;
```

Entrar a RMAN:

```bash
rman target /
```

Listar backups:

```rman
LIST BACKUP SUMMARY;
SHOW ALL;
```

---

## 16. Limitaciones conocidas

- Este repositorio prepara el proyecto y los scripts, pero la ejecución real depende de que Docker esté funcionando.
- TDE puede depender de la edición exacta de Oracle XE y de la imagen utilizada.
- Las contraseñas del ejemplo son didácticas; deben cambiarse antes de una entrega real.
- Los backups, logs y wallets no se versionan en Git por seguridad y tamaño.

---

## 17. Conclusión

El proyecto queda preparado para demostrar una solución integral de backups en Oracle XE:

- Base Oracle XE reproducible con Docker.
- Configuración `ARCHIVELOG` y `FRA`.
- Política de retención de 7 días.
- Wallet/TDE documentado.
- RMAN con compresión, cifrado, backup de base, archive logs y controlfile.
- Automatización por Bash y cron.
- Logs para auditoría.
- Validación de restauración con `RESTORE VALIDATE`.

La defensa principal es que no solo se genera un backup, sino que se cubre el ciclo completo: preparación, seguridad, ejecución, mantenimiento, automatización y validación de recuperación.
