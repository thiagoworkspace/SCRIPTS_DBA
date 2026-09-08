============================================================
SCRIPT: Start using the DBCA, first we need to export our IP machine
============================================================
export DISPLAY=IP_MACHINE:0.0

============================================================
SCRIPT: After that, we can run the dbca command to call the application
============================================================
dbca

============================================================
SCRIPT: Criando um novo CDB usando SILENT MODE do DBCA
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
--Primeiro passo é criar um arquivo .sh e editar com os seguintes parametros
vi CrCDBTEST.sh

$ORACLE_HOME/bin/dbca -silent -createDatabase -
templateName General_Purpose.dbc -gdbname <CDBTEST> -sid 
<CDBTEST> -createAsContainerDatabase true -numberOfPDBs 0 -
useLocalUndoForPDBs true -responseFile NO_VALUE -totalMemory 
1800 -sysPassword <password> -systemPassword <password> -
pdbAdminPassword <password> -emConfiguration DBEXPRESS -
dbsnmpPassword <password> -emExpressPort 5502 -enableArchive 
true -recoveryAreaDestination 
/u01/app/oracle/fast_recovery_area -recoveryAreaSize 15000 -
datafileDestination /u01/app/oracle/oradata

--Alterar o recover area destinatiion e o file destination para DATA e RECO se necessario
-recoveryAreaDestination +RECO -datafileDestination +DATA

--Rodar o arquivo .sh

./CrCDBTEST.sh
--Apos a edição do arquivo, conceder permissão de execução
chmod 755 CrCDBTEST.sh

--Após a conclusão, verificar a nova entrada no arquivo oratab
cat /etc/oratab

-- Conectar ao novo banco
. oraenv
ORACLE_SID = [orclcdb] ? CDBTEST
The Oracle base remains unchanged with value /u01/app/oracle
[oracle@edvmr1p0 DBMod_CreateDB]$ sqlplus / as sysdba
SQL*Plus: Release 19.0.0.0.0 - Production on Mon Oct 26 
18:01:44 2020
Version 19.3.0.0.0
Copyright (c) 1982, 2019, Oracle. All rights reserved.
Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 -
Production
Version 19.3.0.0.0
SQL> select cdb from v$database;
CDB
---
YES
SQL>

--Verify that the datafiles are in the correct directory

SQL> COL NAME FORMAT A200
SQL> SET LINESIZE 200
SQL> SELECT NAME FROM V$DATAFILE ORDER BY 1;

NAME
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
+DATA/CDBTESTE/86B637B62FE07A65E053F706E80A27CA/DATAFILE/sysaux.317.1222792255
+DATA/CDBTESTE/86B637B62FE07A65E053F706E80A27CA/DATAFILE/system.316.1222792255
+DATA/CDBTESTE/86B637B62FE07A65E053F706E80A27CA/DATAFILE/undotbs1.318.1222792255
+DATA/CDBTESTE/DATAFILE/sysaux.308.1222791739
+DATA/CDBTESTE/DATAFILE/system.307.1222791683
+DATA/CDBTESTE/DATAFILE/undotbs1.309.1222791775
+DATA/CDBTESTE/DATAFILE/users.310.1222791775

7 rows selected.

--Verify that the tablespaces are created

SQL> COL TABLESPACE_NAME FORMAT A20
SQL> COL CONTENTS FORMAT A20
SQL> SELECT TABLESPACE_NAME, CONTENTS FROM DBA_TABLESPACES;

TABLESPACE_NAME      CONTENTS
-------------------- --------------------
SYSTEM               PERMANENT
SYSAUX               PERMANENT
UNDOTBS1             UNDO
TEMP                 TEMPORARY
USERS                PERMANENT

SQL>

--Verify that the port for EM Express is set correctly
SQL> SELECT DBMS_XDB_CONFIG.GETHTTPSPORT() FROM DUAL;

DBMS_XDB_CONFIG.GETHTTPSPORT()
------------------------------
                          5502

SQL>

============================================================
SCRIPT: Criando um novo CDB via SQL CREATE DATABASE.
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
--1) Create a CDB using CREATE DATABASE COMMAND, first we need to create a .sql file with all sql commands necessary
--obs: save this file in the home/oracle expecific folder for scripts;
cd /home/oracle/scripts (or bin)

--1) Before starting the instance, create an initialization parameter file with the parameters:
cd $ORACLE_HOME/dbs
vi initCDBDEV.ora
CREATE DATABASE <DB_NAME>
USER SYS IDENTIFIED BY <PASSWD>
USER SYSTEM IDENTIFIED BY <PASSWD>
EXTENT MANAGEMENT LOCAL
DEFAULT TEMPORARY TABLESPACE TEMP
DEFAULT TABLESPACE USERS
UNDO TABLESPACE UNDOTBS1
ENABLE PLUGGABLE DATABASE;

DB_NAME='CDBDEV'
AUDIT_FILE_DEST='/u01/app/oracle/admin/CDBDEV/adump'
DB_RECOVERY_FILE_DEST='+RECO'
DB_RECOVERY_FILE_DEST_SIZE=1500M
DIAGNOSTIC_DEST='/u01/app/oracle'
DB_CREATE_FILE_DEST='+DATA'
DISPATCHERS='(PROTOCOL=TCP) (SERVICE=CDBDEVXDB)'
COMPATIBLE='19.0.0.0'
ENABLE_PLUGGABLE_DATABASE=TRUE
#MAX_PDBS to limit the number of pdbs in he CDB if necessary

--2)Edit the ORATAB file adding the new instance:oracle_home for exemple:
CDBDEV:/u01/app/oracle/product/19.0.0/dbhome_1:N

--3)Create (if not exist) the AUDIT_FILE_DEST directory
mkdir -p /u01/app/oracle/admin/CDBDEV/adump

--4)Startup the instance in nomount mode, be sure that the sqlplus was started in the directory where init file is located
--If not, describe all the path in SPFILE parameter
STARTUP NOMOUNT PFILE='initCDBDEV.ora';

--5) Execute the script with the CREATE DATABASE command. This command will take approximately 2 minutes

SQL> @crCDBDEV.sql

Database created.

SQL>

--6) Execute catalog and catproc scripts. The first takes +- 3 minutes, the second takes +-30 minutes
SQL> @ORACLE_HOME/rdbms/admin/catalog.sql
SQL> @ORACLE_HOME/rdbms/admin/catproc.sql

--7) If you receive errors from the CREATE DATABASE command, use the shutdown abort correct the errors and start again

============================================================
SCRIPT: Deletar um banco de dados via dbca SILENT MODE
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
$ORACLE_HOME/bin/dbca -silent -deleteDatabase -sourceDB <db_name> -sid <sid_name> -sysPassword <password>

============================================================
SCRIPT: Criando um novo CDB com CREATE DATABASE (não levando em conta ASM)
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
-- 1) Criar um arquivo CreateCDB.sql e inserir o seguinte script
CREATE DATABASE <cdbname> 
USER SYS IDENTIFIED BY <password> 
USER SYSTEM IDENTIFIED BY <password>
 EXTENT MANAGEMENT LOCAL DEFAULT TEMPORARY TABLESPACE temp 
 DEFAULT TABLESPACE users 
 UNDO TABLESPACE undotbs1 
 ENABLE PLUGGABLE DATABASE;
 
 
 -- 2) setar o . oraenv com o nome da nova instancia e seu home (não necessariamente precisa existir para setar)
 -- ps: o ORACLE_HOME pode ser igual dos outros ja instalado, pegar no /etc/oratab
[oracle@oraclearch DBMod_CreateDB]$ . oraenv
ORACLE_SID = [orcl] ? CDBDEV
ORACLE_HOME = [/home/oracle] ? /u01/app/oracle/product/19.0.0/dbhome_1
The Oracle base remains unchanged with value /u01/app/oracle
[oracle@oraclearch DBMod_CreateDB]$

-- 3) Criar o parametro de inicialização (SPFILE) do modelo de template do proprio oracle
[oracle@oraclearch DBMod_CreateDB]$ cd $ORACLE_HOME/dbs
[oracle@oraclearch dbs]$ cp init.ora initCDBDEV.ora

-- editar o arquivo com as configs basicas abaixo:
db_name='CDBDEV'
memory_target=1G
processes = 150
audit_file_dest='/u01/app/oracle/admin/CDBDEV/adump'
audit_trail ='db'
db_block_size=8192
db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
db_recovery_file_dest_size=2G
diagnostic_dest='/u01/app/oracle'
dispatchers='(PROTOCOL=TCP) (SERVICE=CDBDEVXDB)'
open_cursors=300
remote_login_passwordfile='EXCLUSIVE'
undo_tablespace='UNDOTBS1'
control_files = ('/u02/oradata/ora_control01.ctl','/u01/app/oracle/fast_recovery_area/ora_control02.ctl')
compatible ='19.0.0.0'
DB_CREATE_FILE_DEST='/u02/oradata'
ENABLE_PLUGGABLE_DATABASE=true
	
	
-- 4) Verificar se os diretorios DB_CREATE_FILE_DEST, AUDIT_FILE_DEST, e o DB_RECOVERY_FILE_DEST
-- existem Usar o comando abaixo para criar caso não exista
$ mkdir -p /u01/app/oracle/admin/CDBDEV/adump
$ ls /u01/app/oracle/fast_recovery_area
CDBTEST ORCLCDB RCATCDB
$ ls /u01/app/oracle/oradata
ORCLCDB RACTCDB
 
 
 
-- 5) Subir a instancia no modo NOMOUNT.

$ sqlplus / AS SYSDBA
Connected to an idle instance.
SQL> STARTUP NOMOUNT
...
SQL>

-- 6) Executar o script sql com o CREATE DATABASE

SQL> @/home/oracle/labs/DBMod_CreateDB/CrCDBDEV.sql
Database created.
SQL>

--OBS -> Se receber erros do CREATE DATABASE, use o comando shutdown abort.
-- Corrigir os errose restart
-- Checar o arquivo de inicialização

-- 7) Executar os scripts catalog e catproc.
SQL> @$ORACLE_HOME/rdbms/admin/catalog.sql
…
SQL> @$ORACLE_HOME/rdbms/admin/catproc.sql
...
SQL>

-- OBS -> O script catalog.sql leva em torno de 3 minutos para completar
-- enquanto o script catproc.sql leva em torno de 30 miinutos para completar

-- 8) Sair do sqlplus
SQL> EXIT
…
$

-- 9) Adicionar uma nova entrada no arquivo oratab com o seguinte passo

$ echo "CDBDEV:/u01/app/oracle/product/19.0.0/dbhome_1:N" >> /etc/oratab

-- 10) Verificar a nova entrada no arquivo oratab

$ cat /etc/oratab
…
#
orclcdb:/u01/app/oracle/product/19.3.0/dbhome_1:Y
CDBDEV:/u01/app/oracle/product/19.3.0/dbhome_1:N

-- 11) No proximo . oraenv agora não é mais necessario passar o ORACLE_HOME
-- visto que o ORACLE_SID já está adicionado no /et/oratab
$ . oraenv
ORACLE_SID = [CDBDEV] ? CDBDEV
The Oracle base remains unchanged with value /u01/app/oracle
$

-- 12) Verificar se o novo banco é um CDB
$ sqlplus / as sysdba
…
Version 19.3.0.0.0
SQL> select cdb from v$database;
CDB
---
YES
SQL

-- 13) Verificar se os datafiles estão no diretorio correto
SQL> set pagesize 100
SQL> column name format a130
SQL> select name from v$datafile order by 1;
NAME
--------------------------------------------------------------
------------------
/u01/app/oracle/oradata/CDBDEV/B29964A7B1066D26E0536310ED0A031
2/datafile/o1_mf_s
ysaux_hsgbrmkx_.dbf
/u01/app/oracle/oradata/CDBDEV/B29964A7B1066D26E0536310ED0A031
2/datafile/o1_mf_s
ystem_hsgbrgd1_.dbf
/u01/app/oracle/oradata/CDBDEV/B29964A7B1066D26E0536310ED0A031
2/datafile/o1_mf_u
sers_hsgbrp5k_.dbf
/u01/app/oracle/oradata/CDBDEV/datafile/o1_mf_sysaux_hsgbrlw5_
.dbf
/u01/app/oracle/oradata/CDBDEV/datafile/o1_mf_system_hsgbrfc8_
.dbf
/u01/app/oracle/oradata/CDBDEV/datafile/o1_mf_undotbs1_hsgbro6
7_.dbf
/u01/app/oracle/oradata/CDBDEV/datafile/o1_mf_users_hsgbroj3_.
dbf
7 rows selected.
SQL>

-- 14) Verificar se as tablespaces estão criadas para o CDB$ROOT

SQL> SELECT tablespace_name, contents FROM dba_tablespaces;
TABLESPACE_NAME CONTENTS
------------------------------ ---------------------
SYSTEM PERMANENT
SYSAUX PERMANENT
UNDOTBS1 UNDO
TEMP TEMPORARY
USERS PERMANENT
SQL>

-- 15) (optional) Verificar se a porta do EM Express está correta:
SQL> select dbms_xdb_config.gethttpsport() from dual;
DBMS_XDB_CONFIG.GETHTTPSPORT()
------------------------------
 0
SQL>

============================================================
SCRIPT: Comando para mudar de container (PDB) dentro do CDB
ORIGEM: Notion (ORACLE MULTITENANT)
============================================================
ALTER SESSION SET CONTAINER=PDB_NAME;

============================================================
SCRIPT: Comando para checar o container atual
ORIGEM: Notion (ORACLE MULTITENANT)
============================================================
SHOW CON_NAME

============================================================
SCRIPT: Comando para listar os PDBs
ORIGEM: Notion (ORACLE MULTITENANT)
============================================================
SHOW PDBS;

============================================================
SCRIPT: Install all the prerequisites
============================================================
yum install oracle-database-preinstall-19c

============================================================
SCRIPT: Define a password to the oracle user
============================================================
passwd oracle
> password_here

============================================================
SCRIPT: Create directory for installation files, change owner/group and give 775 permission
============================================================
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01 /u02
chmod -R 775 /u01 /u02

============================================================
SCRIPT: Access the oracle user
============================================================
su - oracle

============================================================
SCRIPT: Move the downloaded binaries to Oracle Linux directory dbhome_1 and unzip the files
============================================================
#move the binaries to this directory
cd /u01/app/oracle/product/19.0.0/dbhome_1

#run the unzip command
unzip -oq ....

============================================================
SCRIPT: Export graphic display and run the oracle installer
============================================================
export DISPLAY=IP_LOCAL_MACHINE:0.0

./runInstaller
