-- Ejecutar conectado como SYSDBA.
-- Objetivo: preparar Software Keystore / Wallet para cifrado TDE.
-- Nota: si la edición exacta de Oracle XE no permite TDE, este script sirve
-- para demostrar el procedimiento esperado y se debe documentar la limitación.

WHENEVER SQLERROR EXIT SQL.SQLCODE

ALTER SYSTEM SET wallet_root = '/opt/oracle/admin/XE/wallet' SCOPE=SPFILE;
ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE=BOTH;

SHUTDOWN IMMEDIATE;
STARTUP;

ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '/opt/oracle/admin/XE/wallet/tde'
  IDENTIFIED BY "Wallet123456";

ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
  IDENTIFIED BY "Wallet123456" CONTAINER=ALL;

ADMINISTER KEY MANAGEMENT SET KEY
  IDENTIFIED BY "Wallet123456" WITH BACKUP CONTAINER=ALL;

SELECT wrl_type, wrl_parameter, status, wallet_type
FROM v$encryption_wallet;

EXIT;
