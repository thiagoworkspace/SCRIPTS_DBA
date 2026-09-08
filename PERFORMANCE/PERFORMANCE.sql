============================================================
SCRIPT: Script para consultar queries que foram marcadas pelo AWR.
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
SELECT *
FROM DBA_HIST_COLORED_SQL;

============================================================
SCRIPT: ORACLE SQL TUNING ADVISOR
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
#passar o sql_id da query que queremos analisar + um nome para a tarefa

declare
task_nm varchar2(100);
begin
task_nm := dbms_sqltune.create_tuning_task(SQL_ID=> '<sql_id>',TASK_NAME => 'SQL_TUNNING_TASK_<sql_id>');
end;
/

#Rodar o tuning task
exec dbms_sqltune.execute_tuning_task (TASK_NAME => 'SQL_TUNNING_TASK_5t5mxfm0ph3n0');

#ou rodar via sqlplus
SQL > @create_tuning_task.sql;
Task_Name:
Informe o valor para sql_id:
Informe o valor para time_limit:

#Apos a conclusão, rodar o sql abaixo para listar as recomendações.
SET LONG 10000;
SET PAGESIZE 1000;
SET LINESIZE 200;
SELECT DBMS_SQLTUNE.report_tuning_task('SQL_TUNNING_TASK_<sql_id>') AS recommendations FROM dual;
SET PAGESIZE 24;

#comando para excluir a tarefa
execute dbms_sqltune.drop_tuning_task( 'SQL_TUNNING_TASK_5t5mxfm0ph3n0' );

/*
As Finding Sections que contêm as sentenças que ele encontrou como:

- Statistics Finding: Criação de estatisticas em uma tabela obsoleta que a consulta lê
- Index Finding: O que sugere a criação de index no campo que estava na clausula where
- SQL Profile Finding: Sugere habilitar o SQL Profile que ele criou que faz uso de um plano melhor
*/
#OBS -> Caso recomende criar um SQL Profile ou rodar a coleta de estatistica ir na
# aba propria de cada uma nessa documentação.

#Exemplo de saida
RECOMMENDATIONS
--------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
-------------------------------------------------------------------------------
Tuning Task Name   : SQL_TUNNING_TASK_5t5mxfm0ph3n0
Tuning Task Owner  : SYS
Workload Type      : Single SQL Statement
Scope              : COMPREHENSIVE
Time Limit(seconds): 1800
Completion Status  : COMPLETED
Started at         : 01/01/2021 17:22:25
Completed at       : 01/01/2021 17:22:54

-------------------------------------------------------------------------------
Schema Name: USERS
SQL ID     : 5t5mxfm0ph3n0
SQL Text   : SELECT   TR.NAME,
                                                                  TR.AGE,
                                                                  TR.CITY,
                                                                  TR.SIGN_DATE
                                                            FROM    USERS.CUSTOMERS TR
                                                            WHERE   
                                                                  TR.SIGN_DATE  = TO_DATE('30/12/2020','DD/MM/YYYY')

-------------------------------------------------------------------------------
FINDINGS SECTION (3 findings)
-------------------------------------------------------------------------------

1- Statistics Finding
---------------------
  Optimizer statistics for table "USERS"."CUSTOMERS" are stale.

  Recommendation
  --------------
  - Consider collecting optimizer statistics for this table and its indices.
    execute dbms_stats.gather_table_stats(ownname => 'USERS', tabname =>
            'CUSTOMERS', estimate_percent =>
            DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE
            AUTO', cascade => TRUE);

  Rationale
  ---------
    The optimizer requires up-to-date statistics for the table and its indices
    in order to select a good execution plan.

2- Index Finding (see explain plans section below)
--------------------------------------------------
  The execution plan of this statement can be improved by creating one or more
  indices.
 
  Recommendation (estimated benefit: 99.99%)
  ------------------------------------------
  - Consider running the Access Advisor to improve the physical schema design
    or creating the recommended index.
    create index USERS.IDX$$_17C0B0001 on
    USERS.CUSTOMERS("SIGN_DATE");
	
3- SQL Profile Finding (see explain plans section below)
--------------------------------------------------------
  A potentially better execution plan was found for this statement.

  Recommendation (estimated benefit: 68.27%)
  ------------------------------------------
  - Consider accepting the recommended SQL profile.
    execute dbms_sqltune.accept_sql_profile(task_name =>
            'SQL_TUNNING_TASK_5t5mxfm0ph3n0', task_owner => 'SYS', replace =>
            TRUE);

-------------------------------------------------------------------------------
EXPLAIN PLANS SECTION
-------------------------------------------------------------------------------

1- Original With Adjusted Cost
------------------------------
Plan hash value: 321555184

--------------------------------------------------------------------------------
| Id  | Operation            | Name             | Rows  | Bytes | Cost (%CPU)| T
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |                  |     6 |   330 |    19   (0)| 0
|   1 |  PX RDINATOR      |                  |       |       |            |
|   2 |   PX SEND QC (RANDOM)| :TQ10000         |     6 |   330 |    19   (0)| 0
|   3 |    PX BLOCK ITERATOR |                  |     6 |   330 |    19   (0)| 0
|*  4 |     TABLE ACCESS FULL| CUSTOMERS |     6 |   330 |    19   (0)| 0
--------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - filter("TR"."SIGN_DATE"=TO_DATE(' 2020-12-30 00:00:00', 'syyyy-mm-dd')

2- Using SQL Profile
--------------------
Plan hash value: 3378393080

--------------------------------------------------------------------------------
| Id  | Operation                           | Name               | Rows  | Bytes
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                    |     6 |   330
|   1 |  PARTITION RANGE SINGLE             |                    |     6 |   330
|   2 |   INLIST ITERATOR                   |                    |       |
|   3 |    TABLE ACCESS BY LOCAL INDEX ROWID| CUSTOMERS   |     6 |   330
|*  4 |     INDEX RANGE SCAN                | INX_CUSTOMERS_1 |     1 |
--------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("TR"."SIGN_DATE"=TO_DATE(' 2020-12-30 00:00:00', 'syyyy-mm-dd')
        

-------------------------------------------------------------------------------

PL/SQL procedure successfully completed

============================================================
SCRIPT: Script para listar as TOP queries com maior tempo de consumo (elapsed_time)
ORIGEM: Notion (SESSÃO DE USUARIO/PROCESSOS)
============================================================
--Elapsed Time é o tempo decorrido e total consumido para realizar as execuções das instruções SQL
Select
INST_ID,
module,
parsing_schema_name,
inst_id,
sql_id,
CHILD_NUMBER,
sql_plan_baseline,
sql_profile,
plan_hash_value,
sql_fulltext,
to_char(last_active_time,'DD/MM/YY HH24:MI:SS' ),executions, 
elapsed_time/executions/1000/1000,
rows_processed,sql_plan_baseline 
from gv$sql where last_active_time>sysdate-1/24 
and executions <> 0 order by elapsed_time/executions desc;

============================================================
SCRIPT: Comando usado para consultar o total de SGA usado
ORIGEM: Notion (SPFILE / PFILE)
============================================================
--Check the Usage of SGA
select round(used.bytes /1024/1024/1024 ,2) used_GB
, round(free.bytes /1024/1024/1024 ,2) free_GB
, round(tot.bytes /1024/1024/1024 ,2) total_GB
from (select sum(bytes) bytes
from v$sgastat
where name != 'free memory') used
, (select sum(bytes) bytes
from v$sgastat
where name = 'free memory') free
, (select sum(bytes) bytes
from v$sgastat) tot ;

============================================================
SCRIPT: Displays summary information about the system global area (SGA).
============================================================
SELECT * FROM GV$SGA;
#INST_ID INSTANCE
#NAME = SGA component group
#VALUE = Memory size (in bytes)
#CON_ID = The ID container to which the data pertains possible values include

============================================================
SCRIPT: Displays size information about the SGA, including the sizes of different SGA components, the granule size, and free memory.
============================================================
SELECT * FROM GV$SGAINFO;

#NAME = NAME OF THE SGA SIZE ITEM
#BYTES = SIZE OF THE ITEM (IN BYTES)
#REIZEABLE = INDICATES WHETHER THE ITEM IS RESIZEABLE (YES) OR NOT (NO)

============================================================
SCRIPT: Displays detailed information about the SGA.
============================================================
SELECT * FROM GV$SGASTAT;
#POOL = DESIGNATES THE POOL IN WHICH THE MEMORY IN NAME RESIDES:
				# IN - MEMORY POOL = MEMORY IS ALLOCATED FRO THE IN-MEMORY POOL
        # JAVA POOL = MEMORY IS ALLOCATED FROM THE JAVA POOL
        # LARGE POOL = MEMORY IS ALLOCATED FROM THE LARGE POOL
        # NUMA POOL = MEMORY IS ALLOCATED FROM THE NUMA POOL
				# SHARED POOL = MEMORY IS ALLOCATED FROM THE SHARED POOL
        # STREAMS POOL = MEMORY IS ALLOCATED FROM THE STREAMS POOL
# NAME = SGA COMPONENT NAME

============================================================
SCRIPT: Displays information about the dynamic SGA components. This view summarizes information based on all completed SGA resize operations since instance startup
============================================================
SELECT * FROM GV$SGA_DYNAMIC_COMPONENTS

============================================================
SCRIPT: Displays information about the amount of SGA memory available for future dynamic SGA resize operations.
============================================================
SELECT * FROM GV$SGA_DYNAMIC_FREE_MEMORY;

============================================================
SCRIPT: Comando usando para consultar o TOP SQL_ID consumo de PGA
============================================================
--Top sql_id's that consumed PGA: 
WITH PGA_USAGE AS (select SESSION_ID, 
                          SESSION_SERIAL#,
                          INSTANCE_NUMBER, 
                          SQL_ID, 
                          PGA_MAX_GB, 
                          PROGRAM, 
                          SAMPLE_TIME
                    from (select SESSION_ID, 
                                 SESSION_SERIAL#,
                                 instance_number, 
                                 sql_id, 
                                 max(pga_sum_mb) pga_max_GB, 
                                 PROGRAM, 
                                 sample_time 
                          from (select SESSION_ID,
                                       SESSION_SERIAL#,
                                       instance_number, 
                                       sample_time,
                                       sql_id, 
                                       round(sum(nvl(pga_allocated, 0))/1024/1024/1024) pga_sum_mb, 
                                       PROGRAM
                                 from dba_hist_active_sess_history
                                 where sample_time between '01/05/24 09:00:00' and SYSDATE
                                 group by instance_number, sample_time, sql_id, PROGRAM, SESSION_ID, SESSION_SERIAL#
                                 )
                                 group by instance_number, sql_id, PROGRAM, sample_time, SESSION_ID, SESSION_SERIAL#
                                 order by SAMPLE_TIME desc)
)

SELECT S.USERNAME, 
       P.SESSION_ID,
       P.SESSION_SERIAL#,
       P.INSTANCE_NUMBER, 
       P.SQL_ID, P.PGA_MAX_GB, 
       P.PROGRAM, 
       P.SAMPLE_TIME 
       FROM GV$SESSION S inner join PGA_USAGE  P ON S.SID = P.SESSION_ID
where rownum <= 10;

============================================================
SCRIPT: Script usado para  exibe objetos de banco de dados que estão armazenados em cache no cache da biblioteca. Os objetos incluem tabelas, índices, clusters, definições de sinônimos, procedimentos e pacotes PL/SQL e gatilhos.
============================================================
--This view displays database objects that are cached in the library cache. Objects include tables, indexes, clusters, synonym definitions, PL/SQL procedures and packages, and triggers.
--Quantidade de memória compartilhável no pool compartilhado consumida pelo objeto
--https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-DB_OBJECT_CACHE.html#GUID-5A9003C9-088A-4272-B508-BD2C3BA35729
select OWNER, NAME||' - '||TYPE object, SHARABLE_MEM / 1024/ 1024
from v$db_object_cache
where SHARABLE_MEM > 10000
and type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE') and owner not in ('SYS', 'DBSNMP')
order by SHARABLE_MEM desc;

============================================================
SCRIPT: Script para consultar uma nova metrica para PGA
============================================================
WITH
   MAX_PGA as
     (select round(value/1024/1024/1024,1) max_pga from v$pgastat where name='maximum PGA allocated'),
   MGA_CURR as
     (select round(value/1024/1024/1024,1) mga_curr from v$pgastat where name='MGA allocated (under PGA)'),
   MAX_UTIL as
     (select max_utilization as max_util from v$resource_limit where resource_name='processes'),
    pga_aggr_limit as 
        (select value/1024/1024/1024 as curr_pga_aggregate_limit from v$parameter where name like 'pga_aggregate_limit'),
    pga_aggr_target as 
        (select value/1024/1024/1024 as curr_pga_aggregate_target from v$parameter where name like 'pga_aggregate_target')
SELECT
   a.max_pga "Max PGA (GB)",
   b.mga_curr "Current MGA (GB)",
   c.max_util "Max # of processes",
   round(((a.max_pga - b.mga_curr) + (c.max_util * 5)/1024) * 1.1, 1) "New PGA_AGGREGATE_LIMIT (MB)",
   d.curr_pga_aggregate_limit,
   e.curr_pga_aggregate_target
FROM MAX_PGA a, MGA_CURR b, MAX_UTIL c, pga_aggr_limit d, pga_aggr_target e
WHERE 1 = 1;

============================================================
SCRIPT: Find which process is continue to consume more and more memory
============================================================
--ORACLE DOC https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=286494379343899&parent=EXTERNAL_SEARCH&sourceId=HOWTO&id=822527.1&_afrWindowMode=0&_adf.ctrl-state=s8g9hpynf_4
--Find which process is continue to consume more and more memory. This can be found by using the following query:
SELECT s.inst_id,
       s.username, 
       SUBSTR(s.sid,1,5) sid,
       s.serial#,
       p.spid, 
       to_char(logon_time, 'DD/MM/YYYY HH24:MI:SS'),
       SUBSTR(s.program,1,22) program , 
       s.process pid_remote,
       s.status,
       ROUND((pga_used_mem/1024/1024), 2) "Used GB",
       ROUND((pga_alloc_mem/1024/1024), 2) "Allocated GB",
       ROUND((pga_freeable_mem/1024/1024), 2) "Freeable GB",
       ROUND((pga_max_mem/1024/1024/1024),2 ) "Max GB"
FROM  Gv$session s,v$process p
WHERE p.addr=s.paddr and (s.username is not null and s.username not in ('DBSNMP', 'SYS', 'SYSRAC'))
ORDER BY pga_max_mem,logon_time;
/

-- To get more detailed information in which component is growing can view V$PROCESS_MEMORY be used.
SELECT pid, 
       category, 
       allocated "Allocated Bytes", 
       used "Used Bytes", 
       max_allocated "Max Allocated Bytes"
FROM   gv$process_memory
WHERE  pid = (SELECT pid
              FROM   gv$process
              WHERE  addr= (select paddr
                            FROM   gv$session
                            WHERE  sid = 12 and serial# = 4180 ));

============================================================
SCRIPT: Script para encontrar a memoria PGA total da instancia e a sessão que mais consumiu
============================================================
#https://www.dataplatform.gr/en/pos-mporoyme-na-lamvanoyme-email-kathe-fora-5-2/
set echo off
set pagesize 0
set feedback off
select 'Warning: Session''s Program Page Area (PGA) Memory on '|| (select instance_name from v1TP4Instance) || '@' ||(select host_name from v1TP4Instance)||' is too high!!!       ---> '  ||to_char(pga_sum_gb, '999g999g990d00', 'NLS_NUMERIC_CHARACTERS=,.')|| ' GB' as PGA_Response 
 FROM (select sum(pga_alloc_mem/1024/1024/1024) as pga_sum_gb from v$process)
where pga_sum_gb > 0.01; -- DONT FORGET TO SWITCH
SELECT 'Highest PGA Session: ' 
   || ' PGA:' || to_char(p.pga_alloc_mem/1024/1024/1024, '999g999g990d00', 'NLS_NUMERIC_CHARACTERS=,.')||' GB '
   || ' ---- LOGON: ' || to_char(h.LOGON_TIME,'YYYY/MM/DD HH:MI:SS') 
   || ' ---- SID: ' || h.SID
   || ' ---- SERIAL: ' || h.SERIAL#
   || ' ---- PROCESS: ' || p.SPID
   || ' ---- USERNAME: ' || u.username
   || ' ---- OSUSER: ' || h.osuser
   || ' ---- MACHINE: ' || h.machine
   || ' ---- PROGRAM: ' || h.program
   || ' ---- MODULE: ' || h.module
   || ' ----               SQL TEXT: ' || s.sql_text
   FROM
   gv$session h
LEFT JOIN gv$SQLAREA s ON h.sql_hash_value = s.hash_value and h.sql_ADDRESS = s.ADDRESS and h.inst_id = s.inst_id 
LEFT JOIN DBA_USERS u ON h.USER# = u.USER_ID
LEFT JOIN gv$process  p ON p.ADDR = h.PADDR and p.inst_id = h.inst_id 
WHERE  1=1
and (select sum(pga_alloc_mem/1024/1024/1024) as pga_sum_gb from v$process) > 0.01 -- DONT FORGET TO SWITCH
and rownum <=1
ORDER BY p.pga_alloc_mem DESC;
quit;
/

============================================================
SCRIPT: Parameter CPU
ORIGEM: Notion (ORACLE CPU)
============================================================
SHOW PARAMETER CPU;

============================================================
SCRIPT: For plotting CPU, we compute the deltas of "busy" and "idle" time and use "busy / (busy + idle)" to get a CPU utilization percentage (RETORNA A % DE CPU EM DETERMINADO TEMPO).
ORIGEM: Notion (ORACLE CPU)
============================================================
select 'OS Busy Time' series, to_char(snaptime, 'DD/MM/YYYY hh24:MI:SS') snap_time, round(busydelta / (busydelta + idledelta) * 100, 2) "CPU Use (%)"
from (
select s.begin_interval_time snaptime,
os1.value - lag(os1.value) over (order by s.snap_id) busydelta,
os2.value - lag(os2.value) over (order by s.snap_id) idledelta
from dba_hist_snapshot s, dba_hist_osstat os1, dba_hist_osstat os2
where
s.snap_id = os1.snap_id and s.snap_id = os2.snap_id
and s.instance_number = os1.instance_number and s.instance_number = os2.instance_number
and s.dbid = os1.dbid and s.dbid = os2.dbid
and s.instance_number = (select instance_number from v$instance)
and s.dbid = (select dbid from v$database)
and os1.stat_name = 'BUSY_TIME'
and os2.stat_name = 'IDLE_TIME')
ORDER BY SNAP_TIME ASC;

============================================================
SCRIPT: Consultar, CPU_ORACLE, CPU_OS
ORIGEM: Notion (ORACLE CPU)
============================================================
-- para single instance
SELECT 'CPU_ORACLE'          TYPE,
       ROUND(value / 100, 2) COST_PERCENT_CORE 
  FROM v$sysmetric
 WHERE metric_name = 'CPU Usage Per Sec'
   AND group_id = 2
 UNION
SELECT 'CPU_OS'                                             TYPE,
       ROUND((percent.busy * parameter.cpu_count) / 100, 2) COST_PERCENT_CORE
  FROM
    (SELECT value busy
       FROM v$sysmetric
      WHERE metric_name = 'Host CPU Utilization (%)'
        AND group_id=2) percent,
    (SELECT value cpu_count
       FROM v$parameter
      WHERE name = 'cpu_count') parameter;
      
    /

-- para RAC
SELECT inst_id instancia,
      'CPU_ORACLE'          TYPE,
       ROUND(value / 100, 2) COST_PERCENT_CORE 
  FROM gv$sysmetric
 WHERE metric_name = 'CPU Usage Per Sec'
   AND group_id = 2
 UNION
SELECT percent.instancia,
       'CPU_OS'                                             TYPE,
       ROUND((percent.busy * parameter.cpu_count) / 100, 2) COST_PERCENT_CORE
  FROM
    (SELECT INST_ID instancia, value busy
       FROM gv$sysmetric
      WHERE metric_name = 'Host CPU Utilization (%)'
        AND group_id=2) percent,
    (SELECT INST_ID instancia, value cpu_count
       FROM gv$parameter
      WHERE name = 'cpu_count') parameter;

============================================================
SCRIPT: Top 10 CPU consuming Session in Oracle
ORIGEM: Notion (ORACLE CPU)
============================================================
set linesize 200
column PROGRAM FORMAT A50
column CPUHours FORMAT A300
select rownum as rank, a.*
from (
SELECT v.sid,sess.Serial# ,program, ROUND(v.value / (100 * 60 * 60), 2) CPUHours
FROM v$statname s , v$sesstat v, v$session sess
WHERE s.name = 'CPU used by this session'
and sess.sid = v.sid
and v.statistic#=s.statistic#
and v.value>0
ORDER BY v.value DESC) a
where rownum < 11;

============================================================
SCRIPT: SQL Text top consuming CPU in Oracle (running)
ORIGEM: Notion (ORACLE CPU)
============================================================
select * from (
select p.spid "ospid",
(se.SID),q.sql_text,ss.serial#,ss.SQL_ID,ss.username,substr(ss.program,1,30) "program",
ss.module,ss.osuser,ss.MACHINE,ss.status,
se.VALUE/100 cpu_usage_sec,
round(((se.VALUE/100) / 60), 2) cpu_usage_min,
round(((se.VALUE/100) / 60 / 60), 2) cpu_usage_hour
from v$session ss,v$sesstat se,
v$statname sn,v$process p, v$sql q
where
se.STATISTIC# = sn.STATISTIC#
and NAME like '%CPU used by this session%'
and se.SID = ss.SID
and ss.username !='SYS'
and ss.status='ACTIVE'
and ss.username is not null
and ss.paddr=p.addr and value > 0
and rownum < 11
order by se.VALUE desc);

============================================================
SCRIPT: SQL Text top consuming CPU in Oracle not running
ORIGEM: Notion (ORACLE CPU)
============================================================
select * from (
select p.spid "ospid",
(se.SID),ss.serial#,ss.SQL_ID,ss.username,substr(ss.program,1,30) "program",
ss.module,ss.osuser,ss.MACHINE,ss.status,
se.VALUE/100 cpu_usage_sec,
round(((se.VALUE/100) / 60), 2) cpu_usage_min,
round(((se.VALUE/100) / 60 / 60), 2) cpu_usage_hour
from v$session ss,v$sesstat se,
v$statname sn,v$process p
where
se.STATISTIC# = sn.STATISTIC#
and NAME like '%CPU used by this session%'
and se.SID = ss.SID
and ss.username !='SYS'
and ss.status='INACTIVE'
and ss.username is not null
and ss.paddr=p.addr and value > 0
and rownum < 11
order by se.VALUE desc);

============================================================
SCRIPT: SQL id consuming more CPU in Oracle
ORIGEM: Notion (ORACLE CPU)
============================================================
col program form a30 heading "Program"
col cpu_usage_sec form 99990 heading "CPU in Seconds"
col MODULE for a18
col OSUSER for a10
col USERNAME for a15
col OSPID for a06 heading "OS PID"
col SID for 99999
col SERIAL# for 999999
col SQL_ID for a15
select * from (
select p.spid "ospid",
(se.SID),ss.serial#,ss.SQL_ID,ss.username,substr(ss.program,1,30) "program",
ss.module,ss.osuser,ss.MACHINE,ss.status,
se.VALUE/100 cpu_usage_sec
from v$session ss,v$sesstat se,
v$statname sn,v$process p
where
se.STATISTIC# = sn.STATISTIC#
and NAME like '%CPU used by this session%'
and se.SID = ss.SID
and ss.username !='SYS'
and ss.status='ACTIVE'
and ss.username is not null
and ss.paddr=p.addr and value > 0
order by se.VALUE desc);

============================================================
SCRIPT: SQL Text top consuming CPU in Oracle
ORIGEM: Notion (ORACLE CPU)
============================================================
col cpu_usage_sec form 99990 heading "CPU in Seconds"
select * from (
select
(se.SID),q.sql_text,ss.module,ss.status,se.VALUE/100 cpu_usage_sec
from v$session ss,v$sesstat se,
v$statname sn, v$process p, v$sql q
where
se.STATISTIC# = sn.STATISTIC#
AND ss.sql_address = q.address
AND ss.sql_hash_value = q.hash_value
and NAME like '%CPU used by this session%'
and se.SID = ss.SID
and ss.username !='SYS'
and ss.status='ACTIVE'
and ss.username is not null
and ss.paddr=p.addr and value > 0
order by se.VALUE desc);

============================================================
SCRIPT: SQL para encontrar sessões com maior consumo de CPU.
ORIGEM: Notion (ORACLE CPU)
============================================================
--Use below query to find the sessions using a lot of CPU for 1 node
select rownum as rank, a.* 
from ( 
SELECT 
       sess.username,
       sess.osuser,
       sess.sql_id,
       sess.prev_exec_start,
       sess.sid,
       sess.serial#, 
       program,
       sess.machine,
       sess.module,
       sess.status,
       round((v.value / (100 * 60 * 60)), 2) CPUHours,
       sess.type
FROM v$statname s , v$sesstat v, v$session sess 
WHERE s.name = 'CPU used by this session' 
and sess.sid = v.sid 
and v.statistic#=s.statistic# 
and v.value>0 
and username is not null
and username not in ('SYS', 'SYSRAC', 'DBSNMP')
ORDER BY v.value DESC) a 
where rownum < 11;

============================================================
SCRIPT: Comando usado para consultar a data da ultima coleta
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
select t.owner, t.table_name, t.last_analyzed from all_all_tables t
where t.owner like ('%<OWNER>')
Na coluna LAST_ANALYZED a data deve ser atual, se não for atual (maior do que 3 meses) acione o DBA responsável pela base para que possa realizar a coleta de estatísticas

============================================================
SCRIPT: Comando usado para consultar a data da ultima coleta (2)
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
--Na projeção da primeira consulta, deve-se observar a data de atualização das estatísticas das tabelas do seu ambiente:

SELECT TABLE_NAME, NUM_ROWS, BLOCKS, AVG_ROW_LEN, TO_CHAR(LAST_ANALYZED, 'DD/MM/YYYY HH24:MI:SS') FROM DBA_TABLES WHERE TABLE_NAME IN ('FAT_SUMARI_NOTA_FISCAL_DEST');
/

SELECT STAT.OWNER AS "Schema proprietário",
         STAT.TABLE_NAME AS "Nome do objeto",
         STAT.OBJECT_TYPE AS "Tipo do objeto",
         STAT.NUM_ROWS AS "Quant. de Linhas",
         TO_CHAR(STAT.LAST_ANALYZED, 'DD/MM/YYYY HH24:MI:SS') AS "Última coleta das estatísticas"
    FROM SYS.DBA_TAB_STATISTICS STAT
   WHERE STAT.OWNER =  'U_SAS' AND STAT.TABLE_NAME = 'FAT_SUMARI_NOTA_FISCAL_DEST'
ORDER BY LAST_ANALYZED;

============================================================
SCRIPT: Comando usado para listar as tabelas de um determinado schema/usuario ordenado pela data da ultima coleta.
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
SELECT OWNER, TABLE_NAME, LAST_ANALYZED FROM DBA_TABLES
WHERE OWNER = '<OWNER_NAME>' ORDER BY 3;

============================================================
SCRIPT: Comando usado para consultar estatistica
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
saber quando as estatísticas dos índices foram coletadas pela última vez:

SELECT STAT.OWNER AS "Schema proprietário",
         STAT. TABLE_NAME AS "Nome do objeto",
         STAT.OBJECT_TYPE AS "Tipo do objeto",
         STAT.NUM_ROWS AS "Quant. de Linhas",
         STAT.LAST_ANALYZED AS "Última coleta das estatísticas"
    FROM SYS.DBA_IND_STATISTICS STAT
   WHERE STAT.OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'DBSNMP')
ORDER BY LAST_ANALYZED;

Os campos projetados em ambas as consultas são:
"Schema proprietário": - campo que informa o esquema dono do objeto;
"Nome do objeto": - campo que informa o nome do objeto;
"Tipo do objeto": - informa o tipo do campo, no caso: tabela ou índice;
"Quant. de Linhas": - exibe a quantidade de registros do objeto;
"Última coleta das estatísticas": - data e hora da realização da última coleta (mais recente) das estatísticas do objeto em questão.

============================================================
SCRIPT: Comando para coletar estatísticas de todos os objetos(tabelas, indeces…) do banco.
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
EXEC DBMS_STATS.GATHER_DATABASE_STATS;
--OU
EXECT DBMS_STATS.GATHER_DATABASE_STATS(
														CASCADE=>TRUE, 
                                      METHOD_OPT=> 'FOR ALL COLUMNS SIZE AUTO);
														);

============================================================
SCRIPT: Comando para coletar estatística do dicionário de dados
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
EXEC DBMS_STATS.GATHER_DICTIONARY_STATS;

============================================================
SCRIPT: Comando usado para coletar estatística de todas as tabelas de um schema/usuario
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
	EXEC DBMS_STATS.GETHER_SCHEMA_STATS('<owner_name>',
															 ESTIMATE_PERCENT=>DBMS_STATS_AUTO_SAMPLE_SIZE,
																 GRANULARITY=>'GLOBAL AND PARTITION'
															); 

--OU

exec DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>'<OWNER_NAME>',estimate_percent=>dbms_stats.auto_sample_size);

============================================================
SCRIPT: Comando de cima porem com paralelismo
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('<owner_name>', ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE, GRANULARITY=>'GLOBAL AND PARTITION', DEGREE=>8)

============================================================
SCRIPT: Comando  para Coletar estatísticas básicas para uma tabela:
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => 'esquema',  -- Substitua pelo nome do esquema/proprietário da tabela
    tabname => 'tabela',   -- Substitua pelo nome da tabela
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    method_opt => 'FOR ALL COLUMNS SIZE AUTO'
  );
END;
/

============================================================
SCRIPT: Comando para Coletar estatísticas com amostragem aleatória de 10%:
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => 'esquema',
    tabname => 'tabela',
    estimate_percent => 10,
    method_opt => 'FOR ALL COLUMNS SIZE AUTO'
  );
END;
/

============================================================
SCRIPT: Comando para Coletar estatísticas com amostragem por bloco de 10%:
ORIGEM: Notion (COLETA DE ESTATISTICAS)
============================================================
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => 'esquema',
    tabname => 'tabela',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    method_opt => 'FOR ALL COLUMNS SIZE 1'
  );
END;
/

============================================================
SCRIPT: Rodar o comando abaixo para utilizar o SQL PROFILE recomendado pelo STA
ORIGEM: Notion (SQL PROFILE)
============================================================
execute dbms_sqltune.accept_sql_profile(task_name => '<profile_name>',
            task_owner => 'SYS', replace => TRUE);
            
            
 SQL > alter system flush shared_pool;
