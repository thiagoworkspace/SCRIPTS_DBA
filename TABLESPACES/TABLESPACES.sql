============================================================
SCRIPT: Consultar as tablespaces do banco
============================================================
SELECT TABLESPACE_NAME, STATUS FROM DBA_TABLESPACES;

============================================================
SCRIPT: Consultar as tablespaces e seus datafiles
============================================================
SET LINES 200
COLUMN FILE_NAME FORMAT A80
COLUMN TABLESPACE_NAME FORMAT A20
SELECT FILE_ID, 
       FILE_NAME, 
       TABLESPACE_NAME, 
       BYTES/1024/1024/1024 SIZE_GB, 
       STATUS
FROM DBA_DATA_FILES 
ORDER BY TABLESPACE_NAME;

============================================================
SCRIPT: Consultar a tablespace temp e seus datafiles
============================================================
COLUMN TABLESPACE_NAME FORMAT A10
COLUMN FILE_NAME FORMAT A50
SELECT TABLESPACE_NAME,
		   FILE_NAME
FROM DBA_TEMP_FILES;

============================================================
SCRIPT: Script para criação de uma tablespace
============================================================
CREATE TABLESPACE <TBS_NAME> 
       DATAFILE 'DIR/<NAME_TS_01.dbf' SIZE 1G AUTOEXTEND ON NEXT 32M MAXSIZE UNLIMITED,
									'DIR/<NAME_TS_01.dbf' SIZE 1G AUTOEXTEND ON NEXT 32M MAXSIZE UNLIMITED #CASO PRECISE POR MAIS DE UM DBF
			 EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO LOGGING;

    OBS → O valor do parametro UNLIMITED varia do tamanho dos datablocks.. por exemplo se o banco foi criado definindo para os datablocks tamanho de 8kbs o valor máximo de unlimited será de 32GB.

============================================================
SCRIPT: Adicionando mais datafiles a um tbs.
============================================================
ALTER TABLESPACE <TBS_NAME> ADD DATAFILE 'DIR/<NOVO_DBF>.dbf'
SIZE 1G AUTOEXTEND ON NEXT 32M
MAXSIZE UNLIMITED;

============================================================
SCRIPT: Dropar uma tablespace junto com seus datafiles e constraints
============================================================
DROP TABLESPACE <TS_NAME> INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;

============================================================
SCRIPT: Script para consultar o historico de crescimento de uma tablespace
============================================================
select * from (select (select name from v$tablespace t where t.ts# = tablespace_id) tablespace_name,
       rtime,
       round(tablespace_size*8192/1024/1024/1024, 4) tablespace_size,
       round(tablespace_maxsize*8192/1024/1024/1024, 4) tablespace_maxsize,
       round(tablespace_usedsize*8192/1024/1024/1024, 4) tablespace_usedsize
from dba_hist_tbspc_space_usage) where tablespace_name='UNDOTBS1' order by rtime desc;

============================================================
SCRIPT: Script para consultar o tamanho da tbs no momento
============================================================
select * from dba_tablespace_usage_metrics
where tablespace_name in ('<TBS1>', '<TBS2')
order by 1;

obs → 

- A coluna TABLESPACE_NAME mostra o nome da tablespace, por padrão o Mega utiliza a TSD_MEGA;
- A coluna USED_SPACE mostra qual é o espaço físico que a tablespace aloca;
- A coluna TABLESPACE_SIZE mostra qual é o tamanho limite que a tablespace pode atingir;
- A coluna USED_PERCENT mostra qual é o percentual de utilização de espaço.

  mais links para consulta de tbs ( link1 (https://eduardolegatti.blogspot.com/2013/01/monitorando-o-percentual-de-espaco.html) )

============================================================
SCRIPT: Script para consultar o tamanho de todos os tablespaces
============================================================
set linesize 130 #utilizar essa linha somente se for no SQLPLUS
set pagesize 500 #utilizar essa linha somente se for no SQLPLUS
select df.tablespace_name tablespace, df.total_space_mb total_space_mb,
(df.total_space_mb - fs.free_space_mb) used_space_mb, fs.free_space_mb free_space_mb,
round(100 * (fs.free_space / df.total_space),2) "livre_%"
from (select tablespace_name, sum(bytes) total_space,
      round(sum(bytes) / 1048576) total_space_mb
      from dba_data_files
      group by tablespace_name) df,
     (select tablespace_name, sum(bytes) free_space,
       round(sum(bytes) / 1048576) free_space_mb
       from dba_free_space
       group by tablespace_name) fs
where df.tablespace_name = fs.tablespace_name(+)
order by 5;

============================================================
SCRIPT: Consultar o tamanho total, livre e usado da tablespace (MELHORAR ESSA QUERY)
============================================================
select a.tablespace_name,
	   a.status,
	   b.tamanho,
	   c.livre,
	   b.tamanho - c.livre usado
from dba_tablespaces a, (select tablespace_name,
                         sum(bytes)/1024/1024 tamanho
						 from dba_data_files
						 group by tablespace_name) b,
						(select tablespace_name,
						 sum(bytes)/1024/1024 livre
						 from dba_free_space
						 group by tablespace_name
						 ) c
where a.tablespace_name = b.tablespace_name
and a.tablespace_name = c.tablespace_name;

============================================================
SCRIPT: Script para mover um segmento (tabela) para uma determinada tbs
============================================================
ALTER TABLE <TABLE_NAME> MOVE TABLESPACE <TBS_NAME>;

============================================================
SCRIPT: Scripts para consultar se a tabela está com HCC habilitada
============================================================
select owner, table_name,compression, compress_for
from dba_tables
where compression = 'ENABLE'
order by 1,2;

============================================================
SCRIPT: Script para consultar se existem table partitions com compress(HCC)
============================================================
SELECT partition_name, compression
FROM   user_tab_partitions
where compression <> 'ENABLE';

============================================================
SCRIPT: Script para aplicar a compressão (HCC) em tabelas a nivel de estrutura e dados
============================================================
ALTER TABLE <table_name> COMPRESS;
ALTER TABLE <table_name> MOVE COMPRESS;

============================================================
SCRIPT: Script para remover a compressão (HCC) de tabelas a nivel de estrutura e dados
============================================================
ALTER TABLE <table_name> NOCOMPRESS;
ALTER TABLE <table_name> MOVE NOCOMPRESS;

#Caso a tabela esteja particionada e subparticionada, usar as seguintes queries
#para que monta automaticamente o alter table move nocompress para eles

--HCC nivel de tabela 
SELECT OWNER,
       TABLE_NAME,
       COMPRESSION 
FROM DBA_TABLES 
WHERE OWNER LIKE 'U%' AND COMPRESSION <> 'DISABLED';

/
--HCC nivel de partição
SELECT TABLE_OWNER,
       TABLE_NAME, 
       PARTITION_NAME, 
       COMPRESSION, 
       COMPRESS_FOR, 
       TABLESPACE_NAME 
       FROM DBA_TAB_PARTITIONS
WHERE TABLE_OWNER LIKE 'U%'
AND COMPRESSION <> 'DISABLED';

/
--HCC nivel de subpartição
SELECT TABLE_OWNER, 
       TABLE_NAME,
       PARTITION_NAME, 
       SUBPARTITION_NAME,
       COMPRESSION, 
       COMPRESS_FOR, 
       TABLESPACE_NAME
FROM DBA_TAB_SUBPARTITIONS
WHERE TABLE_OWNER LIKE 'U%'
AND COMPRESSION <> 'DISABLED';

/

--Remover a Compressão de partições
SELECT 'ALTER TABLE ' || TABLE_OWNER || '.' || TABLE_NAME || ' MOVE PARTITION ' || PARTITION_NAME || ' NOCOMPRESS;'
FROM DBA_TAB_PARTITIONS
WHERE TABLE_OWNER LIKE 'U%' AND COMPRESSION <> 'DISABLED';

--CASO DE ERRO EM ALGUMA PARTIÇÃO E NÃO CONSEGUIR REALIZAR O NOCOMPRESS, UTILIZAR A VARIAÇÃO DA QUERY ABAIXO
SELECT 'ALTER TABLE ' || TABLE_OWNER || '.' || TABLE_NAME || ' NOCOMPRESS;'
FROM DBA_TAB_PARTITIONS
WHERE TABLE_OWNER LIKE 'U%' AND COMPRESSION <> 'DISABLED';

/

--Remover a Compressão de subpartições
SELECT 'ALTER TABLE ' || TABLE_OWNER || '.' || TABLE_NAME || ' MOVE SUBPARTITION ' || SUBPARTITION_NAME || ' NOCOMPRESS;'
FROM DBA_TAB_SUBPARTITIONS
WHERE TABLE_OWNER LIKE 'U%' AND COMPRESSION <> 'DISABLED';

============================================================
SCRIPT: Script para consultar qual tablespace uma determinada tabela pertence
============================================================
select t.table_name, t.tablespace_name as "TS Name For Table",
       i.index_name, i.tablespace_name as "TS Name For Indexes"
  from user_tables t
  join user_indexes i on i.table_name = t.table_name
 order by t.table_name, i.index_name;

============================================================
SCRIPT: Script para consultar o que está consumindo na tablespace SYSAUX
============================================================
SELECT * FROM 
(SELECT OWNER, SEGMENT_NAME || '~' || PARTITION_NAME SEGMENT_NAME, (BYTES/(1024*1024*1024)) SIZE_B
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME = 'SYSAUX' ORDER BY BLOCKS DESC) WHERE ROWNUM < 6;

============================================================
SCRIPT: Script para alterar o tablespace padrão de um user.
============================================================
alter user <username> default tablespace users;

============================================================
SCRIPT: Script para consultar o max_size de uma tablespace
============================================================
select tablespace_name, max_size 
from dba_tablespaces

============================================================
SCRIPT: Monitorar o consumo da tablespace TEMP
============================================================
select 
    a.tablespace_name tablespace, 
    ROUND(d.TEMP_TOTAL_GB, 2), 
    ROUND((sum (a.used_blocks * d.block_size) / 1024 / 1024/1024), 2) TEMP_USED_GB, 
    ROUND((d.TEMP_TOTAL_GB - sum (a.used_blocks * d.block_size) / 1024 / 1024/1024)) TEMP_FREE_GB 
from v$sort_segment a, 
( 
    select b.name, 
           c.block_size, 
           sum (c.bytes) / 1024 / 1024/1024 TEMP_TOTAL_GB 
    from v$tablespace b, v$tempfile c 
    where b.ts#= c.ts# 
    group by b.name, 
             c.block_size 
) d 
where a.tablespace_name = d.name 
group by a.tablespace_name, d.TEMP_TOTAL_GB;

============================================================
SCRIPT: Shell script para criacao automatica de dbfs via crontab
============================================================
WITH dfcalc AS (
    SELECT  tablespace_name,
            SUM(bytes) AS total_space,
            ROUND(SUM(bytes) / 1048576) AS total_space_mb,
            ROUND(SUM(maxbytes) / 1048576) AS maximo
    FROM dba_data_files
    GROUP BY tablespace_name
),

fscalc AS (
    SELECT  tablespace_name,
            SUM(bytes) AS free_space,
            ROUND(SUM(bytes) / 1048576) AS free_space_mb
    FROM dba_free_space
    GROUP BY tablespace_name
),

-- Captura o número do datafile extraindo padrões como _01.dbf, _7.dbf, _12.dbf etc.
maxdf AS (
    SELECT df.tablespace_name,
           df.file_name,
           TO_NUMBER(
               REGEXP_SUBSTR(df.file_name, '_([0-9]+)\.dbf', 1, 1, NULL, 1)
           ) AS file_number
    FROM dba_data_files df
),

-- Seleciona somente o MAIOR número de datafile por tablespace
max_by_tbs AS (
    SELECT tablespace_name,
           file_name,
           file_number,
           ROW_NUMBER() OVER (PARTITION BY tablespace_name ORDER BY file_number DESC) AS rn
    FROM maxdf
)

SELECT 
    d.tablespace_name,

    CASE 
        WHEN m.file_number + 1 < 10 THEN
            'ALTER TABLESPACE "' || d.tablespace_name || 
            '" ADD DATAFILE ''' ||
            REGEXP_REPLACE(m.file_name, '_([0-9]+)\.dbf', '_' ||
                           LPAD(m.file_number + 1, 2, '0') || '.dbf') ||
            ''' SIZE 1G AUTOEXTEND ON NEXT 32M MAXSIZE UNLIMITED'
        ELSE
            'ALTER TABLESPACE "' || d.tablespace_name ||
            '" ADD DATAFILE ''' ||
            REGEXP_REPLACE(m.file_name, '_([0-9]+)\.dbf', '_' ||
                           (m.file_number + 1) || '.dbf') ||
            ''' SIZE 1G AUTOEXTEND ON NEXT 32M MAXSIZE UNLIMITED'
    END AS comando_add_datafile

FROM dfcalc d
JOIN fscalc f ON d.tablespace_name = f.tablespace_name
JOIN max_by_tbs m ON d.tablespace_name = m.tablespace_name AND m.rn = 1

WHERE ((d.total_space_mb - f.free_space_mb) / d.maximo * 100) >= 82
AND d.tablespace_name NOT IN ('SAS_WORK_TS_IDX','SAS_WORK_TS','SAS_WORK_USR_TS')
AND d.tablespace_name LIKE '%_TS%'          -- ✔ filtro solicitado

ORDER BY d.tablespace_name;

============================================================
SCRIPT: Consultar tamanho e crescimento dos datafiles
============================================================
SET LINES 200
COLUMN FILE_NAME FORMAT A70
SELECT FILE_NAME, 
       BYTES/1024/1024/1024 SIZE_GB, 
       MAXBYTES/1024/1024/1024 MAX_GB, 
       AUTOEXTENSIBLE 
FROM DBA_DATA_FILES;

============================================================
SCRIPT: Verificar espaço livre dos datafiles
============================================================
SET LINES 200
SELECT 
    file_id,
    SUM(bytes)/1024/1024 free_mb
FROM dba_free_space
GROUP BY file_id;

============================================================
SCRIPT: Consulta de UNDOTBS
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
select s.username,
       ROUND(sum(ss.value) / 1024 / 1024 /1024,2) AS GB
from  v$sesstat ss
  join v$session s on s.sid = ss.sid
  join v$statname stat on stat.statistic# = ss.statistic#
where s.username IS NOT NULL
group by s.username
order by GB desc;

============================================================
SCRIPT: Consultando SQL_IDS e querys que usaram a UNDO.
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
SELECT A.BEGIN_TIME, 
        A.END_TIME, 
        A.INSTANCE_NUMBER, 
        A.TXNCOUNT, 
        A.MAXQUERYSQLID,
        B.SQL_TEXT
FROM DBA_HIST_UNDOSTAT A INNER JOIN V$SQL B ON A.MAXQUERYSQLID = B.SQL_ID
ORDER BY 1 desc;

============================================================
SCRIPT: Para consultar o parametro undo_retention
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
SHOW PARAMETER UNDO_RETENTION;

============================================================
SCRIPT: Para alterar o valor do undo_retention
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
ALTER SYSTEM SET UNDO_RETENTION=<NEW_VALOR> SCOPE=BOTH SID='*';

============================================================
SCRIPT: Para consultar o melhor valor da undo_retention
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
select to_char(begin_time, 'DD-MON-RR HH24:MI') 
begin_time,
to_char(end_time, 'DD-MON-RR HH24:MI') end_time, 
tuned_undoretention
from v$undostat order by end_time;

============================================================
SCRIPT: Para checar se o retention guarantee está habilitado
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
select RETENTION from dba_tablespaces where 
tablespace_name='UNDOTBS1';

============================================================
SCRIPT: Para habilitar o retention guarantee
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
alter tablespace UNDOTBS1 retention 
GUARANTEE

============================================================
SCRIPT: Para consultar os status EXPIRED, UNEXPIRED, ACTIVE da UNDO
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
select tablespace_name, status, sum(blocks) * 8192/1024/1024/1024 GB from dba_undo_extents group by tablespace_name, status
order by 1
;

============================================================
SCRIPT: The following command will give you the total space used, and the free space still available in the undo tablespace.
ORIGEM: Notion (MONITORAMENTO UNDO)
============================================================
select
  a.tablespace_name,
  sum(a.bytes)/(1024*1024) total_space_MB,
  round(b.free,2) Free_space_MB,
  round(b.free/(sum(a.bytes)/(1024*1024))* 100,2) percent_free
 from dba_data_files a,
  (select tablespace_name,sum(bytes)/(1024*1024) free  from dba_free_space
  group by tablespace_name) b
 where a.tablespace_name = b.tablespace_name(+)
  group by a.tablespace_name,b.free;

============================================================
SCRIPT: Passo a Passo parar criar um monitoramento de uso da TEMP
ORIGEM: Notion (MONITORAMENTO TEMP)
============================================================
# Criar um schema onde será armazenado as informações do monitoramento

CREATE USER "MON_TEMP" PROFILE "DEFAULT" IDENTIFIED BY "*******" DEFAULT TABLESPACE "USERS" TEMPORARY TABLESPACE "TEMP" QUOTA 5242880 K ON "USERS" ACCOUNT UNLOCK;
GRANT UNLIMITED TABLESPACE TO "MON_TEMP";
GRANT "CONNECT" TO "MON_TEMP";
GRANT "DBA" TO "MON_TEMP";

# Criando a tabela de monitoramento da temp

CREATE TABLE "MON_TEMP"."MONITORAMENTOTEMP" 
   (	"PERIODO" DATE, 
	"TABLESPACE" VARCHAR2(30 BYTE), 
	"TEMP_SIZEGB" NUMBER, 
	"SID_SERIAL" VARCHAR2(81 BYTE), 
	"USERNAME" VARCHAR2(128 BYTE), 
	"PROGRAM" VARCHAR2(48 BYTE), 
	"STATUS" VARCHAR2(8 BYTE), 
	"SQL_ID" VARCHAR2(13 BYTE), 
	"QUERY" VARCHAR2(1000 BYTE), 
	"TOTAL_TEMP_SIZE_USAGE_GB" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;

# Dentro do schema de monitoramento, criar uma job que executará uma procedure para inserir
# os dados na tabela
# Nome da JOB: PRC_MONITORAMENTO_TEMP
# Descrição: Monitoramento das querys que mais consomem a TEMP
# Classe da JOB: SYS.DEFAULT_JOB_CLASS
# Bloco PL/SQL
# Quando executar a JOB: 
	# Intervalo de repetição: FREQ=MINUTELY
	# Data inicial: data que a job foi startada
  # Data Final: null
--Apaga os registros com mais de 7 dias
delete from SUBAP.MonitoramentoTemp where periodo <= (sysdate-7);

--Insere dados de consumo da tablespace TEMP quando a query estiver consumindo mais de 10GB 
INSERT INTO MON_TEMP.monitoramentotemp (periodo, tablespace, temp_sizegb, total_temp_size_usage_gb, sid_serial, username, program, status, sql_id, query)
SELECT 
sysdate as periodo,
b.tablespace as tablespace,
ROUND(((b.blocks*p.value)/1024/1024/1024),2) AS temp_sizeGB,
(SELECT round((tablespace_size - free_space)/1024/1024/1024,2) FROM   dba_temp_free_space) as total_temp_size_usage_GB, 
a.sid||','||a.serial# AS sid_serial,
NVL(a.username, '(oracle)') AS username,
a.program as program,
a.status as status,
a.sql_id as SQL_ID,
c.sql_text as query
FROM gv$session a,
gv$sort_usage b,
gv$parameter p,
gv$sqlarea c
WHERE p.name = 'db_block_size'
AND a.saddr = b.session_addr
AND a.inst_id=b.inst_id
AND a.inst_id=p.inst_id
AND c.address= a.sql_address
AND c.hash_value = a.sql_hash_value
AND ((b.blocks*p.value)/1024/1024/1024) > 10;
stop_JOB

============================================================
SCRIPT: Consultar as colunas que possuem HCC
ORIGEM: Notion (DICIONARIO DE DADOS / DATA DICTIONARY)
============================================================
SELECT OWNER,
       TABLE_NAME,
       COMPRESSION 
FROM DBA_TABLES 
WHERE OWNER IN ( 
                 SELECT USERNAME 
                 FROM DBA_USERS 
                 WHERE USERNAME LIKE 'U\_%' ESCAPE '\' 
                ) 
AND COMPRESSION <> 'DISABLED';

/
