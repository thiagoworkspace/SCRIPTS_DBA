============================================================
SCRIPT: Script para criação de um novo objeto “directory”
============================================================
#OBS -> É NECESSARIO QUE O DIRETORIO A NIVEL DE SO SEJA CRIADO PRIMEIRO, O DIRETORIO PRECISA
#TER ACESSO ORACLE:OINSTALL

#CRIAR O OBJETO DIRECTORY
CREATE OR REPLACE DIRECTORY <name> AS '/DIR';

============================================================
SCRIPT: Script para conceder permissão de leitura/escrita do objeto a um determinado user
============================================================
GRANT READ, WRITE ON DIRECTORY <NAME> TO <USER>

============================================================
SCRIPT: Script para consultar detalhes dos objetos “directory” criados
============================================================
SELECT * FROM DBA_DIRECTORIES;
/
SELECT * FROM ALL_DIRECTORIES

============================================================
SCRIPT: Comando help para o expdp e impdp
============================================================
#O HELP É USADO FORA DO SQLPLUS, É EXECUTADO NO PROPRIO TERMINAL.
[oracle@oraclelinux ~]$ expdp help=y
[oracle@oraclelinux ~]$ impdp help=y

============================================================
SCRIPT: Comandos para exportar / importar tabelas via terminal linux
============================================================
expdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=table_names
impdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=table_names

============================================================
SCRIPT: Comando para importar tabela para um outro schema via terminal linux
============================================================
impdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=table_name
schemas=schema_original remap_schema=new_schema:table_name

============================================================
SCRIPT: Comando para importar tabelas para outra tablespace (somente em Datapump)
============================================================
impdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=table_name
schema=original_schema remap_schema=new_schema:table_name remap_tablespace=new_tbs:table_name

============================================================
SCRIPT: Comando para importar tabela para um nome diferente ou renomear uma tabela
============================================================
impdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=table_name
remap_table=schema.original_table_name:schema(new_schema).new_tb_name

============================================================
SCRIPT: Comando para importar somente os dados ou somente a estrutura
============================================================
impdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=tb_name
content=data_only
/
impdp directory=dir_name dumpfile=file.dmp logfile=file.log tables=tb_name
content=metadata_only

============================================================
SCRIPT: Comando para importar somente o schema e importar alterando o nome
============================================================
impdp directory=dir_name dumpfile=file.dmp logfile=file.log schema=schema_name
/
impdp directory=dir_name dumpfile=file.dmp logfile=file.log schema=original_sch_name
remap_schema=original_sch_name:new_sch_name

============================================================
SCRIPT: Comando para exportar uma tabela com filtro de linhas
============================================================
expdp directory=dir_name dumpfile=file.dmp logfile=file.log 
tables=schema.tb query=\"where condição\"

============================================================
SCRIPT: Comando para um full database export
============================================================
expdp directory=dir_name dumpfile=file.dmp logfile=file.log full=y

============================================================
SCRIPT: Comando para importar um database completo
============================================================
--On source
select name from v$tablespace;

--On target
select name from v$tablespace;

--Create missing tb on target
--Make sure target tb has enough free space
--Drop all non-oracle schemas (done during refresh)
--DROP USER <username> CASCADE;

impdp directory=dir_name dumpfile=file.dmp logfile=file.log full=y

============================================================
SCRIPT: Comandos para uma melhor performance no Data Pump
============================================================
--You can always use DIRECT=y parameter to perform faster exports and imports.
--You can also use PARALLEL parameter to start multiple export and import process
-- for faster performance
--Make sure to use %U with the dumpfile name so multiple dumpfiles can be read/write
-- Simultaneously

expdp directory=dir_name DIRECT=y dumpfile=file_%U.dmp logfile=file.log
schemas=sch_name parallel=4
/
impdp directory=dir_name DIRECT=y dumpfile=file_%U.dmp logfile=file.log
schemas=sch_name parallel=4

============================================================
SCRIPT: Trabalhar com arquivo PAR File no Data Pump
============================================================
--Data Pump jobs can be automated using PAR file.
--You basically create one par file which contains all the export or import
-- parameters and just call the par file at expdp utility
-- First you need to create a file with .par extention
-- Second, you need to edit this par file with Data pump parameters
vi exp.par

DIRECTORY=DIR_NAME
DUMPFILE=FILE_%U.dmp
LOGFILE=FILE.LOG
JOB_NAME=JOB
SCHEMAS=SCH_NAME
PARALLEL=4

--And it's very simple to call the above export PAR file.
expdp parfile=exp.par

============================================================
SCRIPT: Script para schedular no crontab Data Pump
============================================================
--Create a file which contains expdp script
vi daily_export.sh

export DATA=$(date +%m_%d_%y_%H_%M)
export ORACLE_SID=orcl
export ORACLE_HOME=dir_oracle_home

$ORACLE_HOME/bin/expdp username/password@sid directory=export_dir 
dumpfile=backup_$DATE.dmp logfile=backup_$DATE.log full=y

--Give permissions to execeute on above file
chmod 755 daily_export.sh

--Schedule export under crontab
crontab -e -u oracle

0020***/home/oracle/backup_script

============================================================
SCRIPT: Script para consultar o progresso de uma exportação DataPump
============================================================
--When you run a data pump export in the background and want to know the progress 
-- status, use below query to get the percentage(%) completion of the export process

SELECT SID, SERIAL#, USERNAME, CONTEXT, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE" FROM V$SESSION_LONGOPS
WHERE TOTALWORK !=0 AND SOFAR <> TOTALWORK;
/
SELECT SID, SERIAL#, USERNAME, OPNAME, CONTEXT, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE" FROM V$SESSION_LONGOPS
WHERE TOTALWORK !=0 AND SOFAR <> TOTALWORK AND OPNAME LIKE 'IMP%';

============================================================
SCRIPT: Script para consultar o status de uma exportação
============================================================
select * from dba_datapump_jobs

============================================================
SCRIPT: Parametros para remap
============================================================
REMAP_TABLE=[schema.]old_tablename[.partition]:new_tablename

REMAP_DATA=[schema.]tablename.column_name:[schema.]pkg.function

REMAP_TABLESPACE=source_tablespace:target_tablespace

REMAP_SCHEMA=source_schema:target_schema

REMAP_DATAFILE=source_datafile:target_datafile

============================================================
SCRIPT: Comando para interromper uma job datapump
============================================================
KILL_JOB

============================================================
SCRIPT: Parametros de Exclude e Include
============================================================
expdp hr DIRECTORY=dpump_dir1 DUMPFILE=hr_exclude.dmp EXCLUDE=VIEW,PACKAGE,FUNCTION
