============================================================
SCRIPT: Script para consultar o tempo (previsão) do fim do backup do rman
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
SET LINES 200
SET PAGES 100

COLUMN INST_ID FORMAT 99
COLUMN SID FORMAT 99999
COLUMN SERIAL# FORMAT 99999
COLUMN START_TIME FORMAT A19
COLUMN PCT_DONE FORMAT A8
COLUMN ETA FORMAT A19
COLUMN ELAPSED_MIN FORMAT 999999
COLUMN REMAIN_MIN FORMAT 999999
COLUMN OPNAME FORMAT A50

SELECT
    sl.inst_id,
    sl.sid,
    s.serial#,
    TO_CHAR(sl.start_time,'DD/MM/YYYY HH24:MI:SS') AS start_time,
    ROUND(sl.elapsed_seconds/60) AS elapsed_min,
    ROUND(sl.time_remaining/60) AS remain_min,
    TO_CHAR(ROUND((sl.sofar/sl.totalwork)*100,2),'990.00')||'%' AS pct_done,
    TO_CHAR(SYSDATE + (sl.time_remaining/86400),'DD/MM/YYYY HH24:MI:SS') AS eta,
    sl.opname
FROM gv$session_longops sl
JOIN gv$session s
     ON sl.sid = s.sid
     AND sl.inst_id = s.inst_id
WHERE sl.totalwork > 0
AND sl.sofar < sl.totalwork
AND UPPER(sl.opname) LIKE 'RMAN%'
AND sl.opname LIKE '%BACKUP%'
AND sl.opname NOT LIKE '%ARCHIVELOG%'
AND sl.opname NOT LIKE '%FULL%'
ORDER BY sl.start_time;

============================================================
SCRIPT: Scripts shell para backup oracle RMAN full
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
#!/bin/sh# Backup Fisico Full (Level 0) do Banco de Dados incluindo os Archived Redologs
# Carregar variaveis de ambiente do usuario. ~/.bash_profile
# Verificar parametrosTERRO=0if ! [ "$1" ]; then  echo  echo "O nome da instance do Banco de Dados deve ser informado..."  TERRO=1else  if ! [ "$2" ]; then    echo    echo "O diretorio destino do backup deve ser informado..."    TERRO=1  fifi
if [ ${TERRO} -eq 1 ]; then  echo "Exemplo: $0 APP1 /BACKUP2"  echo  exit 1fi
# Declaracao de variaveis de trabalhoexport SIDDB=$1                                         # TNS Instance Producaoexport BKPDES=$2                                        # Diretorio destino do backup#export MAILFROM=infra.bd@sefaz.es.gov.br                # E-mail que envia as mensagens#export MAILTO=infra.bd@sefaz.es.gov.br                  # E-mail que recebe as mensagensexport SMTPSRV=                           # Endereco do servidor de SMTP#export SMTPUSR=                                        # Usuario do servidor de SMTP#export SMTPPWD=                                        # Senha do usuario do servidor SMTP
export HOSTNAME=`hostname |cut -f1 -d"."`
export BKPDIR=/home/oracle/backupexport BKPLOG=${BKPDIR}/log/${SIDDB}.full.`date +"%y%m%d%H%M"`.logexport NLS_DATE_FORMAT="dd/mm/yyyy hh24:mi:ss"
# Configurar ambiente Oracleexport ORACLE_SID=${SIDDB}ORAENV_ASK=NO. oraenv >/dev/null
export ORACLE_HOME=`awk -F: '{if ($1 == "'${SIDDB}'") {print $2; exit}}' /etc/oratab 2>/dev/null`export ORACLE_SID=${SIDDB}
{
echo "`date` ---------Inicio do Processo de Backup---------"echo "Script name: $0"echo 
# Verifica se o diretorio destino do backup existe no filesystemif ! [ -d ${BKPDES} ]; thenecho  echo "Caminho do diretorio destino do backup nao existe no filesystem -- ${BKPDES}. Encerrando processo..."exit 1fi
# Gerar arquivo de parametros do Backup Fisico Full (Level 0) do Banco de Dados incluindo os Archived Redologsecho "connect target /"                                                                                   > ${BKPDIR}/bin/full.$$.rcvecho "#connect catalog rman/rman"                                                                        >> ${BKPDIR}/bin/full.$$.rcvecho "allocate channel for maintenance type disk;"                                                       >> ${BKPDIR}/bin/full.$$.rcvecho "crosscheck archivelog all;"                                                                        >> ${BKPDIR}/bin/full.$$.rcvecho "delete noprompt expired archivelog all;"                                                           >> ${BKPDIR}/bin/full.$$.rcvecho "crosscheck backup;"                                                                                >> ${BKPDIR}/bin/full.$$.rcvecho "delete noprompt expired backup;"                                                                   >> ${BKPDIR}/bin/full.$$.rcv#echo "#delete noprompt obsolete;"                                                                         >> ${BKPDIR}/bin/full.$$.rcv#echo "delete obsolete device type disk;"                                                                 >> ${BKPDIR}/bin/full.$$.rcvecho "release channel;"                                                                                  >> ${BKPDIR}/bin/full.$$.rcvecho "sql 'alter system archive log current';"                                                           >> ${BKPDIR}/bin/full.$$.rcvecho "run"                                                                                               >> ${BKPDIR}/bin/full.$$.rcvecho "{"                                                                                                 >> ${BKPDIR}/bin/full.$$.rcvecho "  allocate channel c1 type disk;"                                                                  >> ${BKPDIR}/bin/full.$$.rcvecho "  allocate channel c2 type disk;"                                                                  >> ${BKPDIR}/bin/full.$$.rcvecho "  allocate channel c3 type disk;"                                                                  >> ${BKPDIR}/bin/full.$$.rcvecho "  allocate channel c4 type disk;"                                                                  >> ${BKPDIR}/bin/full.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/full.$$.rcv#echo "    incremental level=0"                                                                           >> ${BKPDIR}/bin/full.$$.rcv# Bancos que devem gerar o backup sem compressao via RMANif ! [ "${SIDDB}" = "DFE1" -o "${SIDDB}" = "DFE2" ]; thenecho "    as compressed backupset incremental level 0"                                                   >> ${BKPDIR}/bin/full.$$.rcvfiecho "    format '${BKPDES}/${SIDDB}_full_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/full.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/full.$$.rcvecho "      database"                                                                                    >> ${BKPDIR}/bin/full.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/full.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/full.$$.rcvecho "    as compressed backupset"                                                                       >> ${BKPDIR}/bin/full.$$.rcvecho "    format '${BKPDES}/${SIDDB}_arch_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/full.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/full.$$.rcvecho "      archivelog all"                                                                              >> ${BKPDIR}/bin/full.$$.rcvecho "      not backed up 1 times"                                                                       >> ${BKPDIR}/bin/full.$$.rcvecho "      delete input"                                                                                >> ${BKPDIR}/bin/full.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/full.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/full.$$.rcvecho "    format '${BKPDES}/${SIDDB}_ctrl_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/full.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/full.$$.rcvecho "      current controlfile"                                                                         >> ${BKPDIR}/bin/full.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/full.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/full.$$.rcvecho "    format '${BKPDES}/${SIDDB}_spfl_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/full.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/full.$$.rcvecho "      spfile"                                                                                      >> ${BKPDIR}/bin/full.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/full.$$.rcvecho "}"                                                                                                 >> ${BKPDIR}/bin/full.$$.rcv
# Gerar o Backup Fisico Full (Level 0) do Banco de Dados incluindo os Archived Redologs${ORACLE_HOME}/bin/rman cmdfile ${BKPDIR}/bin/full.$$.rcvRESULT=$?echo EXIT ${RESULT}
# Remover arquivos desnecessariosrm -f ${BKPDIR}/bin/full.$$.rcv
echo echo "`date` ----------Final do processo de backup----------"echo 
} >> ${BKPLOG}
# Verificar ocorrencia de errosERRO=0RESULT=`grep "RMAN-"  ${BKPLOG} |wc -l`RSCODE=`grep "EXIT 0" ${BKPLOG} |wc -l`[ ${RESULT} -ne 0 ] && ERRO=1[ ${RSCODE} -ne 1 ] && ERRO=1[ ${ERRO} -eq 0 ] && Resultado="SUCESSO"[ ${ERRO} -eq 1 ] && Resultado="FALHA"
#Remover arquivos de config do email
rm -rf /tmp/mailfull.txt
#Gerar arquivo de envio de email
     echo "To:" >> /tmp/mailfull.txt     echo "From:" >> /tmp/mailfull.txt     echo "Subject: ${Resultado} no Backup Fisico FULL do ${SIDDB}" >> /tmp/mailfull.txt     echo "Verificar o arquivo de log em /home/oracle/backup/log." >> /tmp/mailfull.txt
sendmail -t < /tmp/mailfull.txt

============================================================
SCRIPT: Scripts shell para backup oracle RMAN incr
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
#!/bin/sh# Backup Fisico Diferencial Incremental (Level 1) do Banco de Dados
# Carregar variaveis de ambiente do usuario. ~/.bash_profile
# Verificar parametrosTERRO=0if ! [ "$1" ]; then  echo  echo "O nome da instance do Banco de Dados deve ser informado..."  TERRO=1else  if ! [ "$2" ]; then    echo    echo "O diretorio destino do backup deve ser informado..."    TERRO=1  fifi
if [ ${TERRO} -eq 1 ]; then  echo "Exemplo: $0 APP1 /BACKUP2"  echo  exit 1fi
# Declaracao de variaveis de trabalhoexport SIDDB=$1                                         # TNS Instance Producaoexport BKPDES=$2                                        # Diretorio destino do backup#export MAILFROM=Infra.BD@sefaz.es.gov.br                # E-mail que envia as mensagens#export MAILTO=Infra.BD@sefaz.es.gov.br                  # E-mail que recebe as mensagensexport SMTPSRV=                              # Endereco do servidor de SMTPexport SMTPUSR=                                         # Usuario do servidor de SMTPexport SMTPPWD=                                         # Senha do usuario do servidor SMTP
export HOSTNAME=`hostname |cut -f1 -d"."`
export BKPDIR=/home/oracle/backupexport BKPLOG=${BKPDIR}/log/${SIDDB}.incr.`date +"%y%m%d%H%M"`.logexport NLS_DATE_FORMAT="dd/mm/yyyy hh24:mi:ss"
# Configurar ambiente Oracleexport ORACLE_SID=${SIDDB}ORAENV_ASK=NO. oraenv >/dev/null
export ORACLE_HOME=`awk -F: '{if ($1 == "'${SIDDB}'") {print $2; exit}}' /etc/oratab 2>/dev/null`export ORACLE_SID=${SIDDB}
{
echo "`date` ---------Inicio do Processo de Backup---------"echo "Script name: $0"echo 
# Verifica se o diretorio destino do backup existe no filesystemif ! [ -d ${BKPDES} ]; thenecho  echo "Caminho do diretorio destino do backup nao existe no filesystem -- ${BKPDES}. Encerrando processo..."exit 1fi
# Gerar arquivo de parametros do Backup Fisico Diferencial Incremental (Level 1) do Banco de Dadosecho "connect target /"                                                                                   > ${BKPDIR}/bin/incr.$$.rcvecho "#connect catalog rman/rman"                                                                        >> ${BKPDIR}/bin/incr.$$.rcvecho "run"                                                                                               >> ${BKPDIR}/bin/incr.$$.rcvecho "{"                                                                                                 >> ${BKPDIR}/bin/incr.$$.rcvecho "  allocate channel c1 type disk;"                                                                  >> ${BKPDIR}/bin/incr.$$.rcvecho "  allocate channel c2 type disk;"                                                                  >> ${BKPDIR}/bin/incr.$$.rcvecho "  allocate channel c3 type disk;"                                                                  >> ${BKPDIR}/bin/incr.$$.rcvecho "  allocate channel c4 type disk;"                                                                  >> ${BKPDIR}/bin/incr.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/incr.$$.rcv#echo "    incremental level=1"                                                                           >> ${BKPDIR}/bin/incr.$$.rcv#if ! [ "${SIDDB}" = "DFE1" -o "${SIDDB}" = "DFE2" ]; thenecho "    as compressed backupset incremental level 1"                                                   >> ${BKPDIR}/bin/incr.$$.rcv#echo "    as compressed backupset"                                                                       >> ${BKPDIR}/bin/incr.$$.rcv#fiecho "    format '${BKPDES}/${SIDDB}_incr_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/incr.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/incr.$$.rcvecho "      database"                                                                                    >> ${BKPDIR}/bin/incr.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/incr.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/incr.$$.rcvecho "    format '${BKPDES}/${SIDDB}_ctrl_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/incr.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/incr.$$.rcvecho "      current controlfile"                                                                         >> ${BKPDIR}/bin/incr.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/incr.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/incr.$$.rcvecho "    format '${BKPDES}/${SIDDB}_spfl_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/incr.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/incr.$$.rcvecho "      spfile"                                                                                      >> ${BKPDIR}/bin/incr.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/incr.$$.rcvecho "}"                                                                                                 >> ${BKPDIR}/bin/incr.$$.rcv
# Gerar o Backup Fisico Diferencial Incremental (Level 1) do Banco de Dados${ORACLE_HOME}/bin/rman cmdfile ${BKPDIR}/bin/incr.$$.rcvRESULT=$?echo EXIT ${RESULT}
# Remover arquivos desnecessariosrm -f ${BKPDIR}/bin/incr.$$.rcv
echo echo "`date` ----------Final do processo de backup----------"echo 
} >> ${BKPLOG}
# Verificar ocorrencia de errosERRO=0RESULT=`grep "RMAN-"  ${BKPLOG} |wc -l`RSCODE=`grep "EXIT 0" ${BKPLOG} |wc -l`[ ${RESULT} -ne 0 ] && ERRO=1[ ${RSCODE} -ne 1 ] && ERRO=1[ ${ERRO} -eq 0 ] && Resultado="SUCESSO"[ ${ERRO} -eq 1 ] && Resultado="FALHA"
#Remover arquivos de config do email
rm -rf /tmp/mailincr.txt
#Gerar arquivo de envio de email
     echo "To:" >> /tmp/mailincr.txt     echo "From:" >> /tmp/mailincr.txt     echo "Subject: ${Resultado} no Backup Fisico Incremental do ${SIDDB}" >> /tmp/mailincr.txt     echo "Verificar o arquivo de log em /home/oracle/backup/log." >> /tmp/mailincr.txt
sendmail -t < /tmp/mailincr.txt

============================================================
SCRIPT: Scripts shell para backup oracle RMAN arch
ORIGEM: Notion (ORACLE UTILITARIOS)
============================================================
# Backup Fisico de Archived Redologs
# Carregar variaveis de ambiente do usuario. ~/.bash_profile
# Verificar parametrosTERRO=0if ! [ "$1" ]; then  echo  echo "O nome da instance do Banco de Dados deve ser informado..."  TERRO=1else  if ! [ "$2" ]; then    echo    echo "O diretorio destino do backup deve ser informado..."    TERRO=1  fifi
if [ ${TERRO} -eq 1 ]; then  echo "Exemplo: $0 APP1 /BACKUP2"  echo  exit 1fi
# Declaracao de variaveis de trabalhoexport SIDDB=$1                                         # TNS Instance Producaoexport BKPDES=$2                                        # Diretorio destino do backup#export MAILFROM=Infra.BD@sefaz.es.gov.br                # E-mail que envia as mensagens#export MAILTO=Infra.BD@sefaz.es.gov.br                  # E-mail que recebe as mensagensexport SMTPSRV=                            # Endereco do servidor de SMTPexport SMTPUSR=                                         # Usuario do servidor de SMTPexport SMTPPWD=                                         # Senha do usuario do servidor SMTP
export HOSTNAME=`hostname |cut -f1 -d"."`
export BKPDIR=/home/oracle/backupexport BKPLOG=${BKPDIR}/log/${SIDDB}.arch.`date +"%y%m%d%H%M"`.log#export NLS_DATE_FORMAT="dd/mm/yyyy hh24:mi:ss"
######################################################################################export NLS_LANG=american#export NLS_DATE_FORMAT='DD-MON-YYYY HH24MISS'#export rmantrc=/BACKUP4/rman_trace/srdc_rman_debug_${SIDDB}.arch.`date +"%y%m%d%H%M"`.trc#export rmanlog=/BACKUP4/rman_trace/srdc_rman_output_${SIDDB}.arch.`date +"%y%m%d%H%M"`.log#####################################################################################

# Configurar ambiente Oracleexport ORACLE_SID=${SIDDB}ORAENV_ASK=NO. oraenv >/dev/null
export ORACLE_HOME=`awk -F: '{if ($1 == "'${SIDDB}'") {print $2; exit}}' /etc/oratab 2>/dev/null`export ORACLE_SID=${SIDDB}
{
echo "`date` ---------Inicio do Processo de Backup---------"echo "Script name: $0"echo 
# Verifica se o diretorio destino do backup existe no filesystemif ! [ -d ${BKPDES} ]; thenecho  echo "Caminho do diretorio destino do backup nao existe no filesystem -- ${BKPDES}. Encerrando processo..."exit 1fi
# Gerar arquivo de parametros do Backup Fisico Archived Redologsecho "connect target /"                                                                                   > ${BKPDIR}/bin/arch.$$.rcvecho "#connect catalog rman/rman"                                                                        >> ${BKPDIR}/bin/arch.$$.rcvecho "sql 'alter system archive log current';"                                                           >> ${BKPDIR}/bin/arch.$$.rcvecho "run"                                                                                               >> ${BKPDIR}/bin/arch.$$.rcvecho "{"                                                                                                 >> ${BKPDIR}/bin/arch.$$.rcvecho "  allocate channel c1 type disk;"                                                                  >> ${BKPDIR}/bin/arch.$$.rcvecho "  allocate channel c2 type disk;"                                                                  >> ${BKPDIR}/bin/arch.$$.rcvecho "  allocate channel c3 type disk;"                                                                  >> ${BKPDIR}/bin/arch.$$.rcvecho "  allocate channel c4 type disk;"                                                                  >> ${BKPDIR}/bin/arch.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/arch.$$.rcvecho "    as compressed backupset"                                                                       >> ${BKPDIR}/bin/arch.$$.rcvecho "    format '${BKPDES}/${SIDDB}_arch_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/arch.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/arch.$$.rcvecho "      archivelog all"                                                                              >> ${BKPDIR}/bin/arch.$$.rcvecho "      not backed up 1 times"                                                                       >> ${BKPDIR}/bin/arch.$$.rcvecho "      delete input"                                                                                >> ${BKPDIR}/bin/arch.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/arch.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/arch.$$.rcvecho "    format '${BKPDES}/${SIDDB}_ctrl_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/arch.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/arch.$$.rcvecho "      current controlfile"                                                                         >> ${BKPDIR}/bin/arch.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/arch.$$.rcvecho "  backup"                                                                                          >> ${BKPDIR}/bin/arch.$$.rcvecho "    format '${BKPDES}/${SIDDB}_spfl_%d_%s_%p_%D_%M_%Y_%t'"                                         >> ${BKPDIR}/bin/arch.$$.rcvecho "    ("                                                                                             >> ${BKPDIR}/bin/arch.$$.rcvecho "      spfile"                                                                                      >> ${BKPDIR}/bin/arch.$$.rcvecho "    );"                                                                                            >> ${BKPDIR}/bin/arch.$$.rcvecho "}"                                                                                                 >> ${BKPDIR}/bin/arch.$$.rcv
# Gerar o Backup Fisico dos Archived Redologs${ORACLE_HOME}/bin/rman cmdfile ${BKPDIR}/bin/arch.$$.rcv
######################################################################################${ORACLE_HOME}/bin/rman debug all trace=${rmantrc} log=${rmanlog} cmdfile ${BKPDIR}/bin/arch.$$.rcv#${ORACLE_HOME}/bin/rman debug all trace=${rmantrc} cmdfile ${BKPDIR}/bin/arch.$$.rcv#####################################################################################
RESULT=$?echo EXIT ${RESULT}
# Remover arquivos desnecessariosrm -f ${BKPDIR}/bin/arch.$$.rcv
echo echo "`date` ----------Final do processo de backup----------"echo 
} >> ${BKPLOG}
# Verificar ocorrencia de errosERRO=0#RESULT=`grep "RMAN-"  ${BKPLOG} |wc -l`
#####################################################################################RESULT=`grep "failure"  ${BKPLOG} |wc -l`#####################################################################################
RSCODE=`grep "EXIT 0" ${BKPLOG} |wc -l`[ ${RESULT} -ne 0 ] && ERRO=1[ ${RSCODE} -ne 1 ] && ERRO=1[ ${ERRO} -eq 0 ] && Resultado="SUCESSO"[ ${ERRO} -eq 1 ] && Resultado="FALHA"
#Remover arquivos de config do email
rm -rf /tmp/mailarch.txt
#Gerar arquivo de envio de email
     echo "To:" >> /tmp/mailarch.txt     echo "From:" >> /tmp/mailarch.txt     echo "Subject: ${Resultado} no Backup Fisico Archive Log do ${SIDDB}" >> /tmp/mailarch.txt     echo "Verificar o arquivo de log em /home/oracle/backup/log." >> /tmp/mailarch.txt
if [ ${ERRO} -eq 1 ]; then
        sendmail -t < /tmp/mailarch.txtfi

============================================================
SCRIPT: Method 1
============================================================
--First, get the SID and SERIAL# from below query:
select b.sid, b.serial#, a.spid, b.client_info
from gv$process a, v$session b
where a.addr=b.paddr and client_info like 'rman%';

--or

SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
ROUND (SOFAR/TOTALWORK*100, 2) "% COMPLETE"
FROM GV$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%' AND OPNAME NOT LIKE '%aggregate%'
AND TOTALWORK! = 0 AND SOFAR <> TOTALWORK;

============================================================
SCRIPT: [bloco de código solto - continuação do Method 1, comando para matar a sessão do RMAN]
ORIGEM: Notion (SOLTO)
============================================================
--Use the following command to kill RMAN backup job:
alter system kill session '<sid>,<serial>' immediate;

============================================================
SCRIPT: Method 2
============================================================
--Directly kill RMAN job from OS level with the help of “kill -9”

kill -9 id

============================================================
SCRIPT: Grep para listar erros de RMAN em logs
============================================================
grep "EXIT 1" *.log

============================================================
SCRIPT: [bloco de código solto após seção CONTROLFILES - backup do controlfile via RMAN]
ORIGEM: Notion (SOLTO)
============================================================
# Via RMAN
rman target /
COPY CURRENT CONTROLFILE TO '/dir/controlfile.bkp';

============================================================
SCRIPT: Passos para se conectar ao prompt RMAN
============================================================
#Acessar o usuario oracle
#setar o SID no oraenv
#Rodar o comando rman target

rman target /

============================================================
SCRIPT: Para ver as configurações atuais do RMAN
============================================================
show all;

============================================================
SCRIPT: Mudando o valor de um parametro RMAN
============================================================
#Para mudar o valor de um parametro no rman basta

============================================================
SCRIPT: Comando para backup full do banco.
============================================================
BACKUP DATABASE;
--OR
BACKUP FULL DATABASE;

============================================================
SCRIPT: Comando para backp do controlfile e movelo para outro diretorio.
============================================================
--seguir o passo a baixo para caso for mover um controlfile de diretorio

--1 fazer o backup do controlfile atual e tambem do spfile
BACKUP CURRENT CONTROLFILE TAG 'TEXTO OPCIONAL';
BACKUP SPFILE;

--2 usar o alter abaixo para setar o novo caminho de um dos controlfiles.
ALTER SYSTEM SET CONTROL_FILES='+DATA/ORCL/CONTROLFILE/current.261.1220782843', '+RECO/ORCL/CONTROLFILE/current.256.1220782859' SCOPE=SPFILE;

--3 Fazer o shutdown da instancia e startar com nomount mode
shutdown immediate;
startup nomount;

--4 com o banco em nomount, fazer o RESTORE do controlfile
RESTORE CONTROLFILE FROM AUTOBACKUP;

--5 STARTAR O BANCO EM MOUNT MODE
ALTER DATABASE MOUNT;

--6 Controlfile está desatualizado, é necessário atualizar com recover database
RECOVER DATABASE

--7 Agora abrir o banco para uso
ALTER DATABASE OPEN RESETLOGS;

============================================================
SCRIPT: Comando para backup do spfile
============================================================
BACKUP SPFILE;
