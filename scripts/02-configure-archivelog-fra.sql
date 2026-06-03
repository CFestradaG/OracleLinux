-- Ejecutar conectado como SYSDBA.
-- Objetivo: habilitar ARCHIVELOG, configurar FRA y definir retención de 7 días.

WHENEVER SQLERROR EXIT SQL.SQLCODE

ALTER SYSTEM SET db_recovery_file_dest_size = 10G SCOPE=BOTH;
ALTER SYSTEM SET db_recovery_file_dest = '/opt/oracle/oradata/fast_recovery_area' SCOPE=BOTH;

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

ARCHIVE LOG LIST;

EXIT;
