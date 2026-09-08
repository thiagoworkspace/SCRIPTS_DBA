============================================================
SCRIPT: Script para consultar o grupo, sequencia e status de um log file.
============================================================
SELECT GROUP#, SEQUENCE#, (BYTES/1024/1024/1024) GB, STATUS FROM  V$LOG;

#OBS: O STATUS "CURRENT" INDICA O LOG FILE QUE ESTÁ SENDO ESCRITO NESSE MOMENTO.
# Os que tem status inativo são os que já podem ser utilizados novamente.
#Podemos ter tbm o status active, em que ele ainda será necessario em um evento de instance recovery.
#Sequence# -> é a sequencia que o Oracle coloca em cada redo a cada log switch, quando esse redo for
a#arquivado , archived, esse número de sequencia tbm irá para o archive.

============================================================
SCRIPT: Script para listar a localização dos log files no disco
============================================================
SELECT GROUP#, SEQUENCE#, (BYTES/1024/1024) GB, STATUS FROM  V$LOG;

============================================================
SCRIPT: Script para força o log switch
============================================================
#COMANDO USADO PARA SINGLE INSTANCE
ALTER SYSTEM SWITCH LOGFILE;
#COMANDO USADO EM RAC, CASO QUEIRA ALTERAR O LOGFILE CURRENT DE TODAS AS INSTANCIAS.
ALTER SYSTEM SWITCH ALL LOGFILES;

============================================================
SCRIPT: Script para trazer detalhes dos redologs
============================================================
set lines 180
COL group# FORM 99999
COL thread# FORM 99999
COL grp_status FORM a10
COL member FORM a60
COL mem_status FORM a10
COL mbytes FORM 999999
SELECT
a.group#
,a.thread#
,a.status grp_status
,b.member member
,b.status mem_status
,a.bytes/1024/1024 mbytes
FROM v$log a,
v$logfile b
WHERE a.group# = b.group#
ORDER BY a.group#, b.member;

============================================================
SCRIPT: Script para adicionar novos grupos de redolog usando padrão OFA
============================================================
alter database add logfile group 4
('+DATA','+ARCH') SIZE 200M;

#( é importante que cada membro do novo grupo tenha o mesmo tamanho dos grupos existentes)

============================================================
SCRIPT: Script para consultar a frequência de log Switch
============================================================
set pages 999 lines 400
col Day form a10
col h0 format 999
col h1 format 999
col h2 format 999
col h3 format 999
col h4 format 999
col h5 format 999
col h6 format 999
col h7 format 999
col h8 format 999
col h9 format 999
col h10 format 999
col h11 format 999
col h12 format 999
col h13 format 999
col h14 format 999
col h15 format 999
col h16 format 999
col h17 format 999
col h18 format 999
col h19 format 999
col h20 format 999
col h21 format 999
col h22 format 999
col h23 format 999
	SELECT TRUNC (first_time) "Date", inst_id, TO_CHAR (first_time, 'Dy') "Day",
	COUNT (1) "Total",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '00', 1, 0)) "h0",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '01', 1, 0)) "h1",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '02', 1, 0)) "h2",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '03', 1, 0)) "h3",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '04', 1, 0)) "h4",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '05', 1, 0)) "h5",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '06', 1, 0)) "h6",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '07', 1, 0)) "h7",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '08', 1, 0)) "h8",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '09', 1, 0)) "h9",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '10', 1, 0)) "h10",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '11', 1, 0)) "h11",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '12', 1, 0)) "h12",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '13', 1, 0)) "h13",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '14', 1, 0)) "h14",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '15', 1, 0)) "h15",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '16', 1, 0)) "h16",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '17', 1, 0)) "h17",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '18', 1, 0)) "h18",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '19', 1, 0)) "h19",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '20', 1, 0)) "h20",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '21', 1, 0)) "h21",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '22', 1, 0)) "h22",
	SUM (DECODE (TO_CHAR (first_time, 'hh24'), '23', 1, 0)) "h23",
	ROUND (COUNT (1) / 24, 2) "Avg"
	FROM gv$log_history
	WHERE thread# = inst_id
	AND first_time > sysdate -7
	GROUP BY TRUNC (first_time), inst_id, TO_CHAR (first_time, 'Dy')
	ORDER BY 1,2;

============================================================
SCRIPT: Script para consultar a recovery area usage
============================================================
select * from V$RECOVERY_AREA_USAGE;

============================================================
SCRIPT: Mostrar o valor atual do parâmetro  DB_RECOVERY_FILE_DEST_SIZE
============================================================
show parameter db_recovery_file_dest

============================================================
SCRIPT: Manutenção de REDOLOGS
============================================================
Assunto
MANUTENÇÃO REDOLOGS
Conteúdo
MANUTENÇÃO REDOLOGS

 

Em resumo, como boa prática, os redologs devem ser enviados a cada 15 minutos. Os envios podem ser vistos por exemplo em "/u01/app/oracle/diag/rdbms/sit/SIT1/trace/alert_SIT1.log"

Todos os scripts devem ser executado com o usuário no banco de dados em que se deseja realizar a manutenção (sqlplus ou mesmo atraves do client).

 

Comandos para identificação dos logfiles

select thread#,group#,status,bytes/1024/1024 from v$log;
select thread#,group#,status,bytes/1024/1024 from v$standby_log;

Servidor DR (S3A11102P1)

ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=MANUAL;

Servidor PRINCIPAL (EXADATA) - Em qualquer nó

Apagar logfile

alter database drop logfile group 11;
alter database drop logfile group 12;
alter database drop logfile group 13;
alter database drop logfile group 14;
alter database drop logfile group 15;
alter database drop logfile group 16;
alter database drop logfile group 17;
alter database drop logfile group 18;

alter database drop logfile group 21;
alter database drop logfile group 22;
alter database drop logfile group 23;
alter database drop logfile group 24;
alter database drop logfile group 25;
alter database drop logfile group 26;
alter database drop logfile group 27;
alter database drop logfile group 28;

Caso o logfile que se deseja apagar estiver como Active ou Current deverá executar o comando abaixo para que o sistema passe para a atividade para outro logfile.

alter system switch logfile;

Adicionar logfile

alter database add logfile THREAD 1 group 11 size 2048M;
alter database add logfile THREAD 1 group 12 size 2048M;
alter database add logfile THREAD 1 group 13 size 2048M;
alter database add logfile THREAD 1 group 14 size 2048M;
alter database add logfile THREAD 1 group 15 size 2048M;
alter database add logfile THREAD 1 group 16 size 2048M;
alter database add logfile THREAD 1 group 17 size 2048M;
alter database add logfile THREAD 1 group 18 size 2048M;

alter database add logfile THREAD 2 group 21 size 2048M;
alter database add logfile THREAD 2 group 22 size 2048M;
alter database add logfile THREAD 2 group 23 size 2048M;
alter database add logfile THREAD 2 group 24 size 2048M;
alter database add logfile THREAD 2 group 25 size 2048M;
alter database add logfile THREAD 2 group 26 size 2048M;
alter database add logfile THREAD 2 group 27 size 2048M;
alter database add logfile THREAD 2 group 28 size 2048M;

Apagar standby logfile

alter database drop standby logfile group 101;
alter database drop standby logfile group 102;
alter database drop standby logfile group 103;
alter database drop standby logfile group 104;
alter database drop standby logfile group 105;
alter database drop standby logfile group 106;
alter database drop standby logfile group 107;
alter database drop standby logfile group 108;

alter database drop standby logfile group 201;
alter database drop standby logfile group 202;
alter database drop standby logfile group 203;
alter database drop standby logfile group 204;
alter database drop standby logfile group 205;
alter database drop standby logfile group 206;
alter database drop standby logfile group 207;
alter database drop standby logfile group 208;

Adicionar standby logfile

alter database add standby logfile THREAD 1 group 101 size 2048M;
alter database add standby logfile THREAD 1 group 102 size 2048M;
alter database add standby logfile THREAD 1 group 103 size 2048M;
alter database add standby logfile THREAD 1 group 104 size 2048M;
alter database add standby logfile THREAD 1 group 105 size 2048M;
alter database add standby logfile THREAD 1 group 106 size 2048M;
alter database add standby logfile THREAD 1 group 107 size 2048M;
alter database add standby logfile THREAD 1 group 108 size 2048M;

alter database add standby logfile THREAD 2 group 201 size 2048M;
alter database add standby logfile THREAD 2 group 202 size 2048M;
alter database add standby logfile THREAD 2 group 203 size 2048M;
alter database add standby logfile THREAD 2 group 204 size 2048M;
alter database add standby logfile THREAD 2 group 205 size 2048M;
alter database add standby logfile THREAD 2 group 206 size 2048M;
alter database add standby logfile THREAD 2 group 207 size 2048M;
alter database add standby logfile THREAD 2 group 208 size 2048M;

Servidor DR (S3A11102P1)

 

alter database recover managed standby database cancel;

Apagar logfile

alter database clear logfile group 11;
alter database clear logfile group 12;
alter database clear logfile group 13;
alter database clear logfile group 14;
alter database clear logfile group 15;
alter database clear logfile group 16;
alter database clear logfile group 17;
alter database clear logfile group 18;

alter database clear logfile group 21;
alter database clear logfile group 22;
alter database clear logfile group 23;
alter database clear logfile group 24;
alter database clear logfile group 25;
alter database clear logfile group 26;
alter database clear logfile group 27;
alter database clear logfile group 28;

alter database drop logfile group 11;
alter database drop logfile group 12;
alter database drop logfile group 13;
alter database drop logfile group 14;
alter database drop logfile group 15;
alter database drop logfile group 16;
alter database drop logfile group 17;
alter database drop logfile group 18;

alter database drop logfile group 21;
alter database drop logfile group 22;
alter database drop logfile group 23;
alter database drop logfile group 24;
alter database drop logfile group 25;
alter database drop logfile group 26;
alter database drop logfile group 27;
alter database drop logfile group 28;

 

Adicionar logfile

alter database add logfile THREAD 1 group 11 size 2048M;
alter database add logfile THREAD 1 group 12 size 2048M;
alter database add logfile THREAD 1 group 13 size 2048M;
alter database add logfile THREAD 1 group 14 size 2048M;
alter database add logfile THREAD 1 group 15 size 2048M;
alter database add logfile THREAD 1 group 16 size 2048M;
alter database add logfile THREAD 1 group 17 size 2048M;
alter database add logfile THREAD 1 group 18 size 2048M;

alter database add logfile THREAD 2 group 21 size 2048M;
alter database add logfile THREAD 2 group 22 size 2048M;
alter database add logfile THREAD 2 group 23 size 2048M;
alter database add logfile THREAD 2 group 24 size 2048M;
alter database add logfile THREAD 2 group 25 size 2048M;
alter database add logfile THREAD 2 group 26 size 2048M;
alter database add logfile THREAD 2 group 27 size 2048M;
alter database add logfile THREAD 2 group 28 size 2048M;

 

Apagar standby logfile

alter database drop standby logfile group 101;
alter database drop standby logfile group 102;
alter database drop standby logfile group 103;
alter database drop standby logfile group 104;
alter database drop standby logfile group 105;
alter database drop standby logfile group 106;
alter database drop standby logfile group 107;
alter database drop standby logfile group 108;

alter database drop standby logfile group 201;
alter database drop standby logfile group 202;
alter database drop standby logfile group 203;
alter database drop standby logfile group 204;
alter database drop standby logfile group 205;
alter database drop standby logfile group 206;
alter database drop standby logfile group 207;
alter database drop standby logfile group 208;

 

Adicionar standby logfile

alter database add standby logfile THREAD 1 group 101 size 2048M;
alter database add standby logfile THREAD 1 group 102 size 2048M;
alter database add standby logfile THREAD 1 group 103 size 2048M;
alter database add standby logfile THREAD 1 group 104 size 2048M;
alter database add standby logfile THREAD 1 group 105 size 2048M;
alter database add standby logfile THREAD 1 group 106 size 2048M;
alter database add standby logfile THREAD 1 group 107 size 2048M;
alter database add standby logfile THREAD 1 group 108 size 2048M;

alter database add standby logfile THREAD 2 group 201 size 2048M;
alter database add standby logfile THREAD 2 group 202 size 2048M;
alter database add standby logfile THREAD 2 group 203 size 2048M;
alter database add standby logfile THREAD 2 group 204 size 2048M;
alter database add standby logfile THREAD 2 group 205 size 2048M;
alter database add standby logfile THREAD 2 group 206 size 2048M;
alter database add standby logfile THREAD 2 group 207 size 2048M;
alter database add standby logfile THREAD 2 group 208 size 2048M;

ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;

 

alter database recover managed standby database disconnect from session using current logfile;
