============================================================
SCRIPT: Script para pegar o SPID de um SID.
ORIGEM: Notion (SCHEMAS / USERS)
============================================================
set lines 123 
col USERNAME for a15 
col OSUSER for a8 
col MACHINE for a15 
col PROGRAM for a20 
select b.spid, a.username, a.program , a.osuser ,a.machine, a.sid, a.serial#, 
a.status from gv$session a, gv$process b 
where addr=paddr(+) and sid=&sid;

============================================================
SCRIPT: Script para pegar o SID de um SPID.
ORIGEM: Notion (SCHEMAS / USERS)
============================================================
col sid format 999999 
col username format a20 
col osuser format a15 
select b.spid,a.sid, a.serial#,a.username, a.osuser 
from v$session a, v$process b 
where a.paddr= b.addr 
and b.spid='&spid' 
order by b.spid;

============================================================
SCRIPT: Encerrar imediatamente uma sessão em ambos os nós do banco (não necessariamente pegando o SQL_ID).
============================================================
BEGIN

   FOR x IN (SELECT *
              FROM v$session
              WHERE SQL_ID = '<SQL_ID>')
   LOOP
   
    EXECUTE IMMEDIATE 'alter system kill session ''' || x.sid || ',' || x.serial# || ',@1' || ''' immediate';
    --EXECUTE IMMEDIATE 'alter system kill session ''' || x.sid || ',' || x.serial# || ',@2' || ''' immediate';
   END LOOP;
 
 END;

/

BEGIN

   FOR x IN (
                select *
                from Gv$session
                where username is not null
									 and 
                   and status = 'KILLED'
                   and username not in ('SYS', 'SYSMAN', 'DBSNMP')
            )
   LOOP
   
    EXECUTE IMMEDIATE 'ALTER SYSTEM DISCONNECT SESSION '''||x.sid||','||x.serial#|| ',@' || x.INST_ID || ''' IMMEDIATE';
    
   END LOOP;
 
 END;
 
 
 /

============================================================
SCRIPT: query para monitorar a quantidade de processos executando por sessão ativa
============================================================
select username,program,MACHINE,prev_sql_id,count(1) as process
from gv$session
group by username,program,MACHINE,prev_sql_id
having count(1) > 5
order by 5 desc;

============================================================
SCRIPT: TODO HISTORICO DE SESSOES ABERTAS E O QUE ELAS FIZERAM
============================================================
SELECT SAMPLE_TIME,SESSION_ID,SESSION_SERIAL#,SQL_ID,SQL_OPNAME,PROGRAM,MACHINE FROM DBA_HIST_ACTIVE_SESS_HISTORY 
WHERE SAMPLE_TIME LIKE '01/12/2022 17:%'
ORDER BY SAMPLE_TIME ASC;

============================================================
SCRIPT: Script1 para listar e matar as sessões inativas
============================================================
select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||',' || '@'|| INST_ID || ''' IMMEDIATE;'
from Gv$session
where username is not null
   and status <> 'ACTIVE'
   and username not in ('SYS', 'SYSMAN', 'DBSNMP')
   and last_call_et > 1500

============================================================
SCRIPT: Script2 para listar e matar as sessões inativas
============================================================
SELECT 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||','||'@'||INST_ID||''' IMMEDIATE;' as "MataUsuariosConectados"
FROM GV$SESSION
WHERE USERNAME='<user>' AND STATUS='INACTIVE';

============================================================
SCRIPT: Passo a Passo para matar um processo via SO
============================================================
--Rodar o script para pegar o valor do PROCESS
--Process -> é uma coluna que se refere ao ID do processo a nivel de SO
select inst_id, sid, serial#, username, process
from Gv$session
where username is not null
   and username IN ('<schema>');

--Com o processo em mãos, acessar o servidor do banco, conectar com o user oracle
-- indicar o ORAENV e pesquisar o Process com o ps aux para confirmar
ps aux | grep <Process_number>

-- Rodar o comando kill 
kill -9 <process_number>

============================================================
SCRIPT: Script usado em uma job para disconnect automático de sessões inativas com mais de 6h
============================================================
	BEGIN
	
	   FOR x IN (
	                select *
	                from gv$session
	                where username is not null
	                   and status = 'INACTIVE'
	                   and username not in ('SYS', 'SYSMAN', 'DBSNMP')
	                   and last_call_et > 21600
	            )
	   LOOP
	
	    EXECUTE IMMEDIATE 'ALTER SYSTEM DISCONNECT SESSION '''||x.sid||','||x.serial#||',' || '@'|| x.INST_ID || ''' IMMEDIATE';
	
	   END LOOP;
	
	 END;

============================================================
SCRIPT: Count da quantidade de processos ativos
============================================================
COL USERNAME FORMAT A15
COL USERNAME FORMAT A15
COL STATUS FORMAT A15
select username, status, count(1)
from gv$session
where status = 'INACTIVE'
group by username, status
order by 3 desc;

============================================================
SCRIPT: Script para consultar o historico das sessões ativas na memoria.
============================================================
SELECT TO_CHAR(SAMPLE_TIME, 'DD/MM/YYYY HH24:MI:SS'), -- DATA
       SESSION_ID, -- ID DA SESSÃO
       SESSION_SERIAL#, -- SERIAL DA SESSÃO
       SQL_ID,
       SQL_OPNAME, -- NOME DO COMANDO USADO
       SQL_PLAN_OPERATION -- NOME DA OPERAÇÃO DO PLANO DE EXECUÇÃO
FROM DBA_HIST_ACTIVE_SESS_HISTORY
WHERE TO_CHAR(SAMPLE_TIME, 'DD/MM/YYYY HH24:MI:SS') BETWEEN '<DATA_INICIAL>' AND '<DATA_FINAL>';

============================================================
SCRIPT: Script para consultar as sessões bloqueadas / bloqueadoras
============================================================
select 'SID ' || l1.sid ||' está bloqueando ' || l2.sid blocking
from v$lock l1, v$lock l2
where l1.block =1 and l2.request > 0
and l1.id1=l2.id1
and l1.id2=l2.id2;

============================================================
SCRIPT: Script 2 para consultar as sessões bloqueadas / bloqueadoras
============================================================
-- na coluna blocking_session mostra qual sessão está bloqueado aquela linha
select sid, 
       serial#, 
       status, 
       username, 
       osuser, 
       program, 
       blocking_session blocking, 
       event 
from gv$session 
where blocking_session is not null;

--

============================================================
SCRIPT: Script para consultar qual sessão iniciou todo o processo de bloqueio
============================================================
select waiting_session,holding_session from dba_waiters;

============================================================
SCRIPT: Script para obter a lista dos processos em execução
============================================================
select sid, serial#, 
       process, 
       name, 
       description
 from v$session join v$bgprocess using(paddr) ;

============================================================
SCRIPT: Lista das sessões ativas no banco
============================================================
set echo off 
set linesize 95 
set head on 
set feedback on 
col sid head "Sid" form 9999 trunc 
col serial# form 99999 trunc head "Ser#" 
col username form a8 trunc 
col osuser form a7 trunc 
col machine form a20 trunc head "Client|Machine" 
col program form a15 trunc head "Client|Program" 
col login form a11 
col "last call" form 9999999 trunc head "Last Call|In Secs" 
col status form a6 trunc
select sid,
      serial#,
      substr(username,1,10) username,
      substr(osuser,1,10) osuser, 
      substr(program||module,1,15) program,
      substr(machine,1,22) machine, 
      to_char(logon_time,'ddMon hh24:mi') login, 
      last_call_et "last call",status
from gv$session where status='ACTIVE' 
order by 1

============================================================
SCRIPT: Script para encontrar sessões gerando muito redo
============================================================
set lines 2000 
set pages 1000 
col sid for 99999 
col name for a09 
col username for a14 
col PROGRAM for a21 
col MODULE for a25 
select s.sid,sn.SERIAL#,n.name, round(value/1024/1024/1024,2) redo_gb, 
sn.username,sn.status,substr (sn.program,1,21) "program", sn.type, 
sn.module,sn.sql_id 
from v$sesstat s join v$statname n on n.statistic# = s.statistic# 
join v$session sn on sn.sid = s.sid 
where n.name like 'redo size' and s.value!=0
order by redo_gb desc;
