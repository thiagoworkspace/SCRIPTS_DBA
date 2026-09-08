============================================================
SCRIPT: Script usado para consultar as tentativas de login com falha
ORIGEM: Notion (SCHEMAS / USERS)
============================================================
SET SERVEROUTPUT ON
EXEC DBMS_OUTPUT.PUT_LINE(SQLERRM(-904));

SELECT INSTANCE_NUMBER INUM,
       OS_USERNAME,
       USERNAME,
       USERHOST,
       TO_CHAR(EXTENDED_TIMESTAMP,'DD-MON-YYYY HH24:MI:SS') TIMESTAMP,
       ACTION_NAME,
       RETURNCODE,
       TERMINAL AS "MACHINE"
FROM
       DBA_AUDIT_SESSION
WHERE 
       EXTENDED_TIMESTAMP > (SYSDATE - 1) AND RETURNCODE > 0 and USERNAME
ORDER BY EXTENDED_TIMESTAMP desc;

============================================================
SCRIPT: Script usado para consultar o ultimo login/logoff de um usuario
ORIGEM: Notion (SCHEMAS / USERS)
============================================================
SELECT ACTION_NAME,  MAX(to_char(TIMESTAMP, 'hh24:mi:ss dd/mm/yy')) LAST_LOGIN, USERNAME FROM DBA_AUDIT_TRAIL  
WHERE ACTION_NAME IN ('LOGON', 'LOGOFF') AND USERNAME = '<username>' GROUP BY ACTION_NAME, USERNAME ORDER BY LAST_LOGIN DESC;

============================================================
SCRIPT: Comandos usados para habilitar auditoria a nivel de DDL e DML
============================================================
AUDIT TABLE BY nome_do_usuario BY ACCESS;

AUDIT INSERT TABLE BY nome_do_usuario BY ACCESS;
AUDIT UPDATE TABLE BY nome_do_usuario BY ACCESS;
AUDIT DELETE TABLE BY nome_do_usuario BY ACCESS;

============================================================
SCRIPT: Comandos usados para desabilitar a auditoria a nivel de DDL e DML
============================================================
NOAUDIT TABLE BY nome_do_usuario;

NOAUDIT INSERT TABLE BY nome_do_usuario;
NOAUDIT UPDATE TABLE BY nome_do_usuario;
NOAUDIT DELETE TABLE BY nome_do_usuario;

============================================================
SCRIPT: Query para pesquisar tudo que foi auditado
============================================================
SELECT
timestamp,
username,
userhost,
owner,
obj_name,
action_name,
sql_text
FROM dba_audit_trail
WHERE UPPER(USERNAME) = 'nome_do_usuario'
AND UPPER(USERHOST) = '<maquina>'
AND TIMESTAMP BETWEEN TO_DATE('24/08/2020 11:00:00','DD/MM/YYYY HH24:MI:SS') AND TO_DATE('24/08/2020 11:02:00','DD/MM/YYYY HH24:MI:SS')
ORDER BY timestamp desc;

============================================================
SCRIPT: Query para pesquisar tudo que foi auditado 2
============================================================
select syaud.current_user,
       syaud.spare1,
       syaud.ntimestamp#,
       syaud.userhost,
       aact.name,
       syaud.returncode,
       syaud.sqltext,
       syaud.comment$text
from sys.aud$ syaud inner join audit_actions aact on syaud.action# = aact.action 
where spare1 not in ('oracle', 'orarom', 'grid')
and aact.name not in ('LOGON', 'LOGOFF', 'LOGOFF BY CLEANUP');
/

SET SERVEROUTPUT ON
EXEC DBMS_OUTPUT.PUT_LINE(SQLERRM(-904));

============================================================
SCRIPT: Verificar todos os usuários auditados da database, assim como também o que está sendo auditado:
============================================================
select * from dba_stmt_audit_opts;

============================================================
SCRIPT: Tamanho da tabela de auditoria
============================================================
select segment_name table_name ,bytes/1024/1024 size_in_megabytes from dba_segments where segment_name in ('AUD$');

============================================================
SCRIPT: Habilitar auditoria de falha de logon
============================================================
--Ajustar o parâmetro no banco de dados (é necessario restart da base)
--Mas antes salvar o valor atual do parâmetro se tiver
 show parameter audit_trail;
alter system set audit_trail="db_extended" scopre=spfile;

--configurar auditoria
--falha de login:
audit session whenever not successful;

--qualquer login
audit session by access;

--testar uma conexão com falha
connect notauser/notmypass

--Verificar log gerado - somente as 10 tentativas mais recentes (via SQL*Plus)
column USERHOST format a30

select * from ( select OS_USERNAME,USERNAME,USERHOST,TIMESTAMP,ACTION_NAME,RETURNCODE,INSTANCE_NUMBER from dba_audit_session  order by timestamp desc) where rownum <= 10;

--Desativar auditoria de conexão
noaudit session;

============================================================
SCRIPT: Gerenciamento automático de auditoria (AUD$)
============================================================
https://www.oracle.com/technetwork/pt/articles/database-performance/gerenciamento-automatico-auditoria-3002076-ptb.html

--Criando a tablespace e alterando o local da auditoria
create tablespace ORACLE_AUDITORIA
datafile '+DATA/<database_name>/datafile/aud_oracle_01.dbf' size 25G autoextend on next 32M maxsize unlimited
extent management LOCAL
autoallocate
segment space management AUTO
LOGGING;

--this moves table AUD$
BEGIN
DBMS_AUDIT_MGMT.set_audit_trail_location(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
audit_trail_location_value => 'ORACLE_AUDITORIA');
END;
/
--this moves table FGA_LOG$
BEGIN
DBMS_AUDIT_MGMT.set_audit_trail_location(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,--this moves table FGA_LOG$
audit_trail_location_value => 'ORACLE_AUDITORIA');
END

--Habilitando o Gerenciamento automático
Begin
DBMS_AUDIT_MGMT.INIT_CLEANUP(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
default_cleanup_interval => 720);
End;
/

--CREATE_PURGE_JOB
BEGIN
DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD
, audit_trail_purge_interval => 720 --intervalo de limpeza, em horas
, audit_trail_purge_name => 'JOB_Limpeza_Auditoria' --nome do job
,use_last_arch_timestamp => TRUE
);
END;
/

--Marcando registros a serem excluidos
CREATE OR REPLACE PROCEDURE AUDIT_DefineMarcacaoAudit
IS
BEGIN
DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
last_archive_time => SYSDATE - 45);

DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
last_archive_time => SYSDATE - 45);
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB(
job_name => 'JOB_MarcaExclusaoAudit', --nome do job
job_type => 'STORED_PROCEDURE',
job_action => 'AUDIT_DefineMarcacaoAudit',
repeat_interval => 'FREQ=MONTHLY;INTERVAL=1', -- uma vez ao mes
comments => 'Job que executa a procedure que marca ate que ponto a auditoria pode ser removida');

--Todo o job vem desabilitado por padrao no scheduler do 11.2, habilitando

DBMS_SCHEDULER.ENABLE(name => 'JOB_MarcaExclusaoAudit');

END;
/

--Alinhando JOBs
--ajusta data inicial comum e aninhada
DBMS_SCHEDULER.SET_ATTRIBUTE(
name => 'JOB_MARCAEXCLUSAOAUDIT',
attribute => 'start_date',
value => TO_TIMESTAMP('20/02/2021 18:00:00', 'DD/MM/YYYY HH24:MI:SS'));

DBMS_SCHEDULER.SET_ATTRIBUTE(
name => 'AUDSYS.JOB_LIMPEZA_AUDITORIA',
attribute => 'start_date',
value => TO_TIMESTAMP('20/02/2021 18:30:00', 'DD/MM/YYYY HH24:MI:SS'));

--Segundo sabado do mes
DBMS_SCHEDULER.SET_ATTRIBUTE(
name => 'JOB_MARCAEXCLUSAOAUDIT',
attribute => 'repeat_interval',
value => 'FREQ=MONTHLY; BYDAY=2SAT');

--Segundo sabado do mes
DBMS_SCHEDULER.SET_ATTRIBUTE(
name => 'AUDSYS.JOB_LIMPEZA_AUDITORIA',
attribute => 'repeat_interval',
value => 'FREQ=MONTHLY; BYDAY=2SAT');

END;
/

--Tabelas importantes
SELECT audit_trail, cleanup_time, delete_count FROM DBA_AUDIT_MGMT_CLEAN_EVENTS ORDER BY cleanup_time DESC;

SELECT * FROM DBA_AUDIT_MGMT_CLEANUP_JOBS;

SELECT * FROM DBA_AUDIT_MGMT_LAST_ARCH_TS;

SELECT * FROM DBA_AUDIT_MGMT_CONFIG_PARAMS;

SELECT DSJ.OWNER, DSJ.JOB_NAME, DSJ.JOB_TYPE, DSJ.JOB_ACTION, DSJ.START_DATE, DSJ.REPEAT_INTERVAL, DSJ.NEXT_RUN_DATE, DSJ.RUN_COUNT, DSJ.FAILURE_COUNT
FROM DBA_SCHEDULER_JOBS DSJ
WHERE JOB_NAME IN ('JOB_LIMPEZA_AUDITORIA', 'JOB_MARCAEXCLUSAOAUDIT');

============================================================
SCRIPT: Truncate na tabela sys.aud$
============================================================
truncate table sys.aud$;

BEGIN
DBMS_AUDIT_MGMT.init_cleanup(
audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL,
default_cleanup_interval => 12 /* hours */);
END;
/

============================================================
SCRIPT: Passo a Passo para ativar auditoria geral no banco
============================================================
-- Primeiro passo: setar um dos seguintes valores para o parametro AUDIT_TRAIL
-- none (ou false): Auditoria desativada.
-- OS: Os registros de auditoria são gravados na trilha de audi do sistem operacional
-- DB: Os registros de auditoria são gravados em uma tabela do dicionario de dados SYS.AUD$. Existem views que permitem ver o conteúdo dessa tabela
-- DB_EXTENDED: Igual ao DB, mas incluíndo as instruções SQL com variaveis bind que geram os registros de auditoria.
-- XML: Como o parâmetro OS, mas formatado com tags XML.
-- XML_EXTENDED: Como o parâmetro XML, mas com instruções SQL e variaveis bind.

-- Comando usado para altearar o parametro audit_trail
-- acessar o usuario oracle
su - oracle
-- setar o oraenv
. oraenv
--Via sqlplus ou sql developer, rodar o alter system abaixo.
ALTER SYSTEM SET AUDIT_TRAIL='DB_EXTENDED' SCOPE = SPFILE;

-- Ainda no SQLPLUS
SHUTDOWN IMMEDIATE OU srvctl stop database -d <NOME_DB> -o immediate
STARTUP OU srvctl start database -d <nome_db> 

-- Apos o reinicio do banco, verificar se o parametro audit_trail está ligado, verificar
-- na coluna value.
SHOW PARAMETER AUDIT_TRAIL;

-- Agora rodar os seguintes comandos para habilitar o que a auditoria vai auditar
AUDIT SELECT TABLE, UPDATE TABLE, INSERT TABLE, DELETE TABLE BY ACCESS;

--Em seguida definir a politica de auditoria para incluir o texto SQL completo.
AUDIT SELECT ANY TABLE BY ACCESS;

--Esse comando habilitará os selects em todas as tabelas, incluindo textos sql completos.

-- Verificar as configurações de auditoria
SELECT * FROM DBA_AUDIT_TRAIL WHERE ACTION_NAME = 'SELECT';
-- O comando anterior mostrará os registros de auditoria para os selects, incluindo texto SQL

============================================================
SCRIPT: Scripts uteis para consultar melhor a auditoria
============================================================
--Query universal para ver quem está gerando mais auditoria
SELECT
    USERID AS db_user_id,
    USERHOST,
    TERMINAL,
    COUNT(*) AS total_registros
FROM sys.aud$
GROUP BY USERID, USERHOST, TERMINAL
ORDER BY total_registros DESC;

/
--. Query universal para ver crescimento por ação
SELECT
    a.ACTION#,
    a.USERID AS db_user_id,
    act.NAME AS action_name,
    COUNT(*) AS total
FROM
    sys.aud$ a
    LEFT JOIN audit_actions act
        ON a.action# = act.action
GROUP BY
    a.ACTION#, a.USERID, act.NAME
ORDER BY
    total DESC;

/
--Ver os eventos mais recentes
SELECT
    SESSIONID,
    ENTRYID,
    USERID,
    ACTION#,
    NTIMESTAMP#
FROM sys.aud$
ORDER BY NTIMESTAMP# DESC
FETCH FIRST 50 ROWS ONLY;

--. Query mais importante:
SELECT
    USERID AS db_user_id,
    USERHOST,
    TERMINAL,
    COUNT(*) AS registros_2h
FROM sys.aud$
WHERE NTIMESTAMP# > SYSTIMESTAMP - INTERVAL '2' HOUR
GROUP BY USERID, USERHOST, TERMINAL
ORDER BY registros_2h DESC;
