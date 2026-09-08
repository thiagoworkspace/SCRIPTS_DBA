#Verificar o ORATAB
vi /etc/oratab

#Conectar ao usuário oracle
su - oraclee

#Para se conectar ao sqlplus como sys e/ou com outro usuário

sqlplus / as sysdba

sqlplus sys@banco (de um servidor com o client oracle)

sqlplus user/senha

sqlplus 'user/senha' (caso a senha tenha caracter especial)

sqlplus user/'senha' (caso a senha tenha caracter especial)

sqlplus user/senha@banco as sysdba (de um servidor com o client oracle, caso a senha tenha caracter especial)

o barra ( / ) indica uma conexao local

#Comandos para start/stop de um banco ou uma instancia (em caso de single instance/RAC) via SQLPLUS
startup ( start na instancia, aloca a SGA starta os processos background, mounted, open)
shutdown ( database close, database dismount, instance shut down

--variações
startup nomount -> ( start na instancia, aloca a SGA starta os processos background acessando o spfile )
startup mount -> ( start na instancia, aloca a SGA starta os processos background, mounted, mas o banco nao esta disponivel para usuario apenas para dbas )
startup pfile=<dir> (start na instância usando um PFILE diferente)
shutdown immediate -> ( desliga o banco )
shutdown abort -> ( forca o desligamento do banco de uma vez só )

obs → Se foi utilizado o comando startup nomount para dar continuidade basta apenas rodar o comando “ALTER DATABASE MOUNT;” em seguida podemos rodar o “ALTER DATABASE OPEN;” liberando o banco para acessos externos ;

--RAC
srvctl stop database -d <database_name> -o immediate
srvctl start database -d <database_name>
srvctl status database -d <database_name>

#Script para consultar a versão do banco de dados
select * from v$version;

#Script para coletar o TFA

-Conectar com o user ORACLE e setar o ORAENV

su - oracle
. oraenv
> oracle_sid
-Executar o comando abaixo para gerar o diagnostico do TFA
tfactl diagcollect -database DDFE -from "2022-09-12 09:00:00" -to "2022-09-16 17:00:00"

#Script para consultar o RECYCLEBIN (Lixeira) do ORACLE e Purge
SELECT OWNER, OBJECT_NAME, OPERATION, DROPTIME FROM dba_recyclebin 
ORDER BY 4 DESC;
/
SELECT OWNER, COUNT(*) FROM dba_recyclebin
GROUP BY OWNER;

PURGE dba_recyclebin;

#Query para consultar o uptime do banco
SELECT host_name, instance_name,
TO_CHAR(startup_time, 'DD-MM-YYYY HH24:MI:SS') startup_time,
FLOOR(sysdate-startup_time) days
FROM sys.v_$instance;

############################################################
# SCRIPTS MIGRADOS DO NOTION EM 2026-08-16
############################################################

============================================================
SCRIPT: Comando ORAENV e  setar as variáveis de ambiente oracle de um jeito mais facil
============================================================
. oraenv
> ORACLE_SID

obs → o oraenv é um utilitario que ao passar o nome da instancia ja “seta” automaticamente as variaveis de ambiente necessarias

============================================================
SCRIPT: Comandos para gerenciar o Listener
============================================================
lsnrctl status
lsnrctl start
lsnrctl stop
obs → para startar o listener e necessario que as variaveis de ambiente ja sejam setadas

============================================================
SCRIPT: Parametro para definir a instancia primaria e secundaria, valor default é nao tem valor
============================================================
SHOW PARAMETER ACTIVE_INSTANCE_COUNT

============================================================
SCRIPT: Script para rodar o lsinventory do Opatch
============================================================
#Conectar com o user ORACLE e setar o ORAENV
su - oracle
. oraenv
> oracle_sid
#Acessar o diretorio do Opatch
cd $ORACLE_HOME/OPatch
#Rodar o comando abaixo para gerar um arquivo com as informações
./opatch lsinventory -detail > /tmp/lsinv202YMMDD_detail.txt

============================================================
SCRIPT: Comando shell para mostrar como esta o status do RAC
============================================================
#com o user ORACLE, primeiro setar o . ORAENV
./rac_status.sh

============================================================
SCRIPT: Passo a Passo para limpar o diretório /u01 quanto estiver cheio.
============================================================
#Podem ser excluidos os arquivos no diretorio /trace (.trc e .trm) e no /alert (.xml)
#tbm pode ser executado o comando purge para excluir os arquivos TFA gerados automaticamente
#executado com o comando root
tgactl purge -older 90d -force

============================================================
SCRIPT: Comandos GRID (single instance)
============================================================
# rodar com user grid
su - grid
#mostra todos os recursos que estão online
crsctl status res -t

#rodar com user root

#status do cluster
$GRID_HOME/bin/crsctl stat res -t
--ou
/u01/app/21.0.0.0/grid/bin/crsctl stat res -t
#parar os serviços
$GRID_HOME/bin/crsctl stop has
--ou
/u01/app/21.0.0.0/grid/bin/crsctl stop has
#para startar 
$GRID_HOME/bin/crsctl start has
--ou
/u01/app/21.0.0.0/grid/bin/crsctl start has
# Por padrão os serviços do grid sobem sozinhos quando startamos a maquina novamente (junto com o listener)

============================================================
SCRIPT: Comando para listar as configs de um db (rac)-
============================================================
srvctl config database -d <database_name>

============================================================
SCRIPT: Comando para alterar o SPFILE atual por um PFILE modificado
============================================================
srvctl modify database -d <database_name> -spfile <dir>
# é necessario fazer o restar do banco

============================================================
SCRIPT: Criação e uso de logs de erro para operações DML
============================================================
-- Link do artigo:
https://www.profissionaloracle.com.br/2023/12/19/dbms_errlog-criacao-e-uso-de-logs-de-erro-para-operacoes-dml/?utm_source=linkedin&utm_medium=social&utm_campaign=ReviveOldPost

--Passo a Passo para criar e usar logs de erro para operações DML:
-- 1. Criar uma tabela de log de erro usando a função DBMS_ERROLOG.CREATE_LOG.
-- Passar como parametros os nomes da tabela alvo do DML e a tabela de error de logs
 BEGIN
 DBMS_ERRLOG.CREATE_ERROR_LOG(
	  dml_table_name => 'TABLE DE ORIGEM',
    err_log_table_name => 'ERR_TABLE DE DESTINO'
    );
  END;
  /
  
 -- 2. Executar as instruções DML usando a cláusula LOG ERROS, que recebe como parametro
 -- o nome da tabela de erro, a tag da operação e o limite de rejeição;
 -- Essa cláusula faz com que a operação DML continue a executar mesmo que ocorram erros
 -- e que as linhas que falharam sejam registradas na tabela de log de erro.
 -- o Limite de rejeição é o numero maximo de erros que a operação pode torelar antes
 -- de ser abortada. Se o limite for omitido ou zero nao terar limite de erros
 -- Quando o limite for atingido, a operação será desfeita e nenhum registro será inserido
 -- na tabela de log.
  INSERT INTO <TABLE_DE_ORIGEM> VALUES (1, 'x', 'x', 'x')
 LOG ERRORS INTO <err_table> ('op1') REJECT LIMIT 10;
 
 -- 3. query para consultar a tabela de erro usando comandos SQL, para verificar as linhas que
 -- Falharam, os codigos e as mensagens de erros, e as tags das operações.

SELECT * FROM err_clientes;

-- Resultado: exibe os registros da tabela de log de erro
ORA_ERR_NUMBER$ ORA_ERR_MESG$                          ORA_ERR_ROWID$ ORA_ERR_OPTYP$ ORA_ERR_TAG$ ID NOME   EMAIL            TELEFONE
--------------- -------------------------------------- -------------- -------------- ------------ -- ------ ---------------- ------------
1               ORA-00001: unique constraint (SYS_C00  AAABWMAAAACgCw0 I              op1          1  Daniel daniel@gmail.com 44-4444-4444
1400            ORA-01400: cannot insert NULL into ("  AAABWMAAAACgCw1 I              op1          4        elisa@gmail.com  55-5555-5555
12899           ORA-12899: value too large for column  AAABWMAAAACgCw2 I              op1          5  Fabio  fabio@gmail.com  66-6666-666666

============================================================
SCRIPT: Comando SHOW CON_NAME
============================================================
SQL> SHOW CON_NAME

CON_NAME
------------------------------
CDB$ROOT
SQL>

============================================================
SCRIPT: Query para consultar informações de CPU, Memoria, Sockets do servidor
============================================================
set pagesize 299
set lines 299
select STAT_NAME,to_char(VALUE) as VALUE ,COMMENTS from v$osstat where 
stat_name IN ('NUM_CPUS','NUM_CPU_CORES','NUM_CPU_SOCKETS')
union
select STAT_NAME,ROUND((VALUE/1024/1024/1024),2) || ' GB' ,COMMENTS from v$osstat where 
stat_name IN ('PHYSICAL_MEMORY_BYTES');

============================================================
SCRIPT: Passo a Passo para atualizar o Opatch + aplicar patches
============================================================
# OBS: Caso esteja em um ambiente clusterizado, com mais de um node, deve seguir os passos abaixo para cada node - rowlling.

# 1 - Com o Paatch number em mãos pesquisar o patch, fazer o download do mesmo no site do suporte Oracle na aba "Patches & Updates"
# Filtrar pelo Patch number + A versão da plataform ex Linux x86-64, selecionar o patch e
# na proxima tela baixar o "read me" fazer o download do patch.

# 2 - Com o patch baixado, subir o .zip no diretorio /temp (ou em algum outro diretorio usado para patches) do servido (com o usuario root).

# 3 - Mudar a permissão do arquivo para oracle e descompactar o arquivo.
 chown oracle:oinstall <nome_patch>.zip
 unzip <nome_patch>.zip
 
# 4 - De volta no "readme" aberto no navegador, verificar qual versão do Opatch é necessario para aplicação do Patch.
# 5 - Verificar no servidor o Opatch atual e comparar com o pedido no read me. 
# Para isso com o usuario oracle, setar um oraenv do dbhome que irá receber o patch. 
# Fazer um cd para o diretorio ORACLE_HOME 
 cd $ORACLE_HOME/OPatch
 
# 6 - Rodar o comando abaixo e comparar com o readme
 ./opatch version
 
# OBS: Caso a versão esteja diferente da recomendada, 
#deve-se acessar o link abaixo para baixar a versão pedida do Opatch 
# (SELECIONAR O PATCH E A PLATAFORMA CORRETA), 
# caso contrario pular os passos até a etapa de bkp dos binarios
# no link abaixo, apontar o a "Release" desejada + a plataforma ex Linux x86-64
https://updates.oracle.com/download/6880880.html

# Caso precise ser atualizado o OPatch seguir os passos abaixo:
# 7 - subir o .zip no diretorio /temp do servido (com o usuario root) 
# e mudar as permissões para oracle:oinstall
	# 7.1 - (com o usuario oracle) Entrar no diretorio ORACLE_HOME e fazer um bkp da pasta OPatch/ 
	# (pode ser feito dentro do proprio ORACLE_HOME)
	cd $ORACLE_HOME/
	mv OPatch/ OPatch_bkp/
	# 7.2 - Ainda dentro do oracle_home, descompactar o .zip do novo OPatch
	unzip -oq /tmp/p6880880<versao>Linux-x86-64.zip
	# 7.3 - Entrar no novo diretorio do OPatch e rodar novamente a versão para confirmar.
	./opatch version
	
# Com o Opatch atualizado, seguir com a aplicação do Patch.

# 1 - Fazer o backup dos binários (db_home) que será aplicado o patch
	# 1.1 - Criar uma pasta de bkp em algum diretorio de bkp do servidor e dar permissão de oracle:oinstall
	# 1.2 - Entrar no diretorio /u01/app/oracle/product/<versao_oracle>, exemplo
	cd /u01/app/oracle/product/11.2.0/
	
	# 1.3 - rodar o comando abaixo para fazer um bkp zipado do dbhome desejado
	tar -pcvf /BACKUP4/<diretorio_bkp>/nome_bkp.tar <dbhome_desejado>/

# 2 - Fazer um bkp de todos os bancos que compõem o dbhome (verificar se os bancos estão em archivemode on para ser feito o bkp online).
# 3 - Parar (stop) os bancos
# OBS: caso esteja em um ambiente não-grid, será necessário parar o LISTENER também.

# 4 - Entrar o no diretorio do patch descompactado e rodar o comando abaixo para verificar se não há mais requisitos para fazer antes do patch
$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -phBaseDir .

# 5 - Caso não tenha mais nenhum pré-requisito, rodar o comando abaixo para aplicar o patch. Pode levar alguns minutos
$ORACLE_HOME/OPatch/opatch apply

# 6 - Após a conclusão da aplicação, rodar o comando abaixo para validar o novo patch
$ORACLE_HOME/OPatch/opatch lsinventory | grep <patch_number>
$ORACLE_HOME/OPatch/opatch lspatches

# 7 - Subir novamente as instancias.

============================================================
SCRIPT: Query para listar os parâmetros de configuração
============================================================
SELECT NAME, ISSES_MODIFIABLE, ISSYS_MODIFIABLE, ISPDB_MODIFIABLE FROM V$PARAMETER;

============================================================
SCRIPT: Query para listar os caminhos dos alert logs, trace e incidents.
============================================================
SELECT * FROM gV$DIAG_INFO;

============================================================
SCRIPT: ORACLE Flashback
============================================================
--OBS: Para que o flashback funcione, a tabela nao deve ter sofrido nenhum tipo de alteração
-- a nivel de DDL

--Query para consultar o SCN atual
SELECT current_scn FROM v$database;

--Query para habilitar o row movement (se necessario)
ALTER TABLE schema.tabela disable ROW MOVEMENT;

-- Comando para efetuar o flashback utilizando a data desejada.
FLASHBACK TABLE schema.tabela TO TIMESTAMP TO_TIMESTAMP('14/08/2024 16:28:00', 'DD/MM/YYYY HH24:MI:SS');

-- Comando para efeutar o flashback utilizando o SCN
FLASHBACK TABLE schema.tabela TO SCN (<scn>);

============================================================
SCRIPT: DBSAT
============================================================
--1) Logar no servidor com o usuario ORACLE
	--2) oraenv (na instancia desejada)
	--3) Acessar o diretorio /home/oracle/ACS/dbsat/
	--4) Executar o script abaixo, no final será criado um arquivo .json
			./dbsat collect -n SYSTEM <instancia_collect>
	-- OBS: Vai ser solicitado a senha do system.
	
	--5) Executar o script abaixo, no final será criado 4 arquivos .html, .json, .txt, .xlsx
			./dbsat report -a -n <instancia_collect>
			
	--6) Baixar o arquivo .html contendo todas as analises coletadas.

============================================================
SCRIPT: Passo a passo para correção de STARTUP UPGRADE com erro ORA-39701
============================================================
--Durante alguma atividade que seja para subir uma instancia em modo STARTUP UPGRADE em um ambiente GRID (com mais de 2 nodes)
--Caso retorne o erro abaixo, seguir os passos para correção.

SQL> Startup upgrade
ORACLE instance started.
Total System Global Area 1.3262E+11 bytes
Fixed Size                  2304584 bytes
Variable Size            2.2481E+10 bytes
Database Buffers         1.1006E+11 bytes
Redo Buffers               74080256 bytes
Database mounted.
ORA-01092: ORACLE instance terminated. Disconnection forced
ORA-39701: database must be mounted EXCLUSIVE for UPGRADE or DOWNGRADE
Process ID: 29206
Session ID: 2002 Serial number: 3

--

============================================================
SCRIPT: Passo  a passo para fechar/abrir os PDBS
============================================================
--Comando para verificar os pdbs
show pdbs;

--Comando para fechar todos os PDBs OBS
--OBS- CASO QUEIRA SOMENTE UM PDB, TROCAR O ALL PELO NOME DO PDB
ALTER PLUGGABLE DATABASE ALL CLOSE;

--Comando para abrir todos os PDBs
--OBS- CASO QUEIRA SOMENTE UM PDB, TROCAR O ALL PELO NOME DO PDB
ALTER PLUGGABLE DATABASE ALL OPEN;

--Comando para salvar o estado de todos os PDBs
--OBS- Caso queira somente um pdb, trocar o all pelo nome do pdb
ALTER PLUGGABLE DATABASE ALL SAVE STATE;

============================================================
SCRIPT: Comando para verificar os SAVED STATES dos PDBS
============================================================
SQL> COL CON_NAME FORMAT A20
SQL> SELECT CON_ID, CON_NAME, STATE FROM DBA_PDB_SAVED_STATES;

    CON_ID CON_NAME             STATE
---------- -------------------- --------------
         3 PDB01                OPEN
         7 PDB02                OPEN

SQL>

--OBS SE NAO RETORNAR NENHUMA LINHA INDICA QUE NAO EXISTE SAVED STATE PARA OS PDBS

============================================================
SCRIPT: comando para consultar a localização do spfile
ORIGEM: Notion (SPFILE / PFILE)
============================================================
show parameter spfile

obs → esse comando pode ser executado tanto no sqlplus quanto no Oracle Developer

============================================================
SCRIPT: Comando usado para criar um pfile de um spfile
ORIGEM: Notion (SPFILE / PFILE)
============================================================
create pfile='<dir/init.ora>' from spfile='dir/spfileorcl.ora';

obs → caso quiséssemos ver os valores dos parametros listados no SPFILE sem precisar criar o PFILE para isso, podemos usar os comandos abaixo para mostrar mais detalhes dos valores de cada parametro.

============================================================
SCRIPT: comando usado para consultar os valores setados para SGA
ORIGEM: Notion (SPFILE / PFILE)
============================================================
show parameter sga;

============================================================
SCRIPT: comando usado para consultar os valores setados para PGA
ORIGEM: Notion (SPFILE / PFILE)
============================================================
show parameter pga;

============================================================
SCRIPT: comando usado para consultar detalhes da undotbs
ORIGEM: Notion (SPFILE / PFILE)
============================================================
show parameter undo;

============================================================
SCRIPT: Comando usado para listar os parametros do Oracle
ORIGEM: Notion (SPFILE / PFILE)
============================================================
#AS COLUNAS MODIFIABLE INDICAM SE AQUELE PARAMETRO É ALTERADO ONLINE OU SE PRECISA REINICIAR
SELECT * FROM V$PARAMETER;

============================================================
SCRIPT: Passo a Passo para correção de sequence com valor errado.
ORIGEM: Notion (SEQUENCE)
============================================================
--Antes de fazer qualquer alteração é preciso saber qual schema-tabela-coluna a sequence esta vinculada
-- Caso nao esteja descrito na coluna "DATA DEFAULT" da descrição da tabela
-- Deve perguntar ao desenvolvedor ou administrador de dados que gerencia as estruturas dos objetos

-- Com o nome da sequence em mãos e sabendo qual coluna esta vinculada, deve-se comparar seus valores
-- para saber qual o valor atual da coluna referenciada pela sequence, roda o script abaixo.

SELECT MAX(<coluna>) FROM schema.tabela;

-- Depois verificar o valor atual da sequence
-- Para isso ou pode ser executado o valor abaico ou ir via SQL Developer
-- na aba de sequences, selecionar a desejada, vai abrir uma nova tela com detalhes do objeto
-- procurar pela descrição last_number ou rodar o script abaixo

SELECT SCHEMA.SEQUENCE FROM DUAL;

-- O valor da coluna deve ser inferior ao da sequence 
-- Para saber qual vai ser o novo valor basta rodar 
SELECT MAX(<coluna> + 1) FROM schema.tabela;

-- Com isso, atualizar o objeto da sequence
--Caso na descrição da tabela no campo "DATA DEFAULT" estiver setado ja a sequence 
--rodar o comando abaixo.
ALTER TABLE schema.tabela
MODIFY(coluna GENERATED BY DEFAULT AS IDENTITY (START WITH novo_valor));

-- Caso não eteja na descrição default da tabela
--Rodar o comando de alteração direto no objeto sequence

ALTER SEQUENCE schema.sequence restart START WITH novo_valor;

============================================================
SCRIPT: ps para listar todos os process background de uma instancia
ORIGEM: Notion (Como matar Oracle RMAN backup job)
============================================================
ps -ef | grep <instance>

============================================================
SCRIPT: Localização dos controlfiles
ORIGEM: Notion (CONTROLFILES)
============================================================
SET LINES 200
COLUMN NAME FORMAT A80
SELECT NAME FROM V$CONTROLFILE;

============================================================
SCRIPT: Ver a configuração dos controlfiles (parametro do spfile)
ORIGEM: Notion (CONTROLFILES)
============================================================
SHOW PARAMETER CONTROL_FILES;

============================================================
SCRIPT: Backup do controlfile
ORIGEM: Notion (CONTROLFILES)
============================================================
--BACKUP MANUAL
ALTER DATABASE BACKUP CONTROLFILE TO TRACE;

--BACKUP BINARIO
ALTER DATABASE BACKUP CONTROLFILE TO '/backup/control.bkp';

--BACKUP VIA RMAN
BACKUP CURRENT CONTROLFILE;

============================================================
SCRIPT: Adicionar um novo controlfile
ORIGEM: Notion (CONTROLFILES)
============================================================
--VER O ATUAL
SHOW PARAMETER CONTROL_FILES;

--COPIAR O CONTROLFILE (VIA BASH OU VIA ASM COM ASMCMD)
cp control01.ctr control03.ctr

--ALTERAR PARAMETROS
ALTER SYSTEM SET CONTROL_FILES=
'/u01/.../control01.ctl',
'/u02/.../control02.ctl',
'/u03/.../control03.ctl'
SCOPE=SPFILE;

--REINICIAR O BANCO

============================================================
SCRIPT: [bloco de código solto após seção CONTROLFILES - redundante com item 'Ver a configuração dos controlfiles']
ORIGEM: Notion (SOLTO)
============================================================
SHOW PARAMETER CONTROL_FILES;

============================================================
SCRIPT: [bloco de código solto após seção CONTROLFILES - consulta v$controlfile]
ORIGEM: Notion (SOLTO)
============================================================
select name from v$controlfile;

============================================================
SCRIPT: [bloco de código solto após seção CONTROLFILES - backup binario/trace do controlfile]
ORIGEM: Notion (SOLTO)
============================================================
#Backup do controlfile para um arquivo binario
ALTER DATABASE BACKUP CONTROLFILE TO '/dir/controlfile.bkp';

#Backup trace
ALTER DATABASE BACKUP CONTROLFILE TO TRACE;

============================================================
SCRIPT: [bloco de código solto após seção CONTROLFILES - backup trace arquivo texto]
ORIGEM: Notion (SOLTO)
============================================================
# arquivo texto
ALTER DATABASE BACKUP CONTROLFILE TO TRACE;

============================================================
SCRIPT: Criar um DIRETORIO ORACLE
ORIGEM: Notion (DICIONARIO DE DADOS / DATA DICTIONARY)
============================================================
CREATE OR REPLACE DIRECTORY <nome_alas> AS '<dir/*/>';

============================================================
SCRIPT: Verificar JOBs executadas
ORIGEM: Notion (JOBS)
============================================================
SELECT to_char(log_date, 'DD-MON-YY HH24:MM:SS') TIMESTAMP, job_name, status,
   SUBSTR(additional_info, 1, 40) ADDITIONAL_INFO
   FROM user_scheduler_job_run_details ORDER BY log_date;

============================================================
SCRIPT: Verificar JOBs em execução
ORIGEM: Notion (JOBS)
============================================================
SELECT OWNER, job_name, state FROM DBA_SCHEDULER_JOBS 
where job_name = '<job_name>';

============================================================
SCRIPT: Parar execução da JOB e desabilitar o agendamento de todo o banco.
ORIGEM: Notion (JOBS)
============================================================
BEGIN
    DBMS_SCHEDULER.DISABLE('"<jobname>"',true);
    DBMS_SCHEDULER.STOP_JOB('"<jobname>"');
END;

============================================================
SCRIPT: Executar JOB
ORIGEM: Notion (JOBS)
============================================================
Begin
  DBMS_SCHEDULER.RUN_JOB( 
    JOB_NAME            => '<JOB_NAME>', 
    USE_CURRENT_SESSION => FALSE); 
END;

============================================================
SCRIPT: Erro em executar job ORA-20001: comma-separated list (SOLUÇÃO)
ORIGEM: Notion (JOBS)
============================================================
Begin
  DBMS_SCHEDULER.RUN_JOB( 
    JOB_NAME            => '"CORPORATIVO CARGA AIDF"', 
    USE_CURRENT_SESSION => FALSE); 
END;

============================================================
SCRIPT: Copiar JOBs
ORIGEM: Notion (JOBS)
============================================================
DBMS_SCHEDULER.COPY_JOB
(
 old_job                       in varchar2,
 new_job                      in varchar2);

============================================================
SCRIPT: Apagar JOB
ORIGEM: Notion (JOBS)
============================================================
DBMS_SCHEDULER.DROP_JOB
(
 job_name                    in varchar2,
 force               in Boolean default false
);

============================================================
SCRIPT: Desabilitar JOB
ORIGEM: Notion (JOBS)
============================================================
exec dbms_scheduler.disable('"<schema>"."<job_name>"');

============================================================
SCRIPT: Parando a JOB com scheduler desativado
ORIGEM: Notion (JOBS)
============================================================
--Importante: Esse procedimento fará todas as JOBS da database serem interrompidas, portanto avise os responsáveis antes de realizar o processo.
--1 ) Dentro do user SYS do esquema
show parameter job_queue_processes; (anote o valor do job_queue_processes)

exec dbms_scheduler.set_scheduler_attribute('SCHEDULER_DISABLED', 'TRUE');

exec dbms_scheduler.stop_job(''SCHEMA'."JOB"',true);

alter system set job_queue_processes=0;
exec dbms_ijob.set_enabled(FALSE);

alter system flush shared_pool;

exec dbms_ijob.set_enabled(TRUE);
alter system set job_queue_processes=1000;
exec dbms_scheduler.set_scheduler_attribute('SCHEDULER_DISABLED', 'FALSE');

============================================================
SCRIPT: Correção para Jobs pulando agendamento
ORIGEM: Notion (JOBS)
============================================================
--Importante: Esse procedimento fará todas as JOBS da database serem interrompidas, portanto avise os responsáveis antes de realizar o processo.
--1) Execute os seguintes comandos em sequência:
--'''OBS: Execute os comandos no esquema SYS'''
exec dbms_scheduler.disable('MONDAY_WINDOW');
exec dbms_scheduler.disable('TUESDAY_WINDOW');
exec dbms_scheduler.disable('WEDNESDAY_WINDOW');
exec dbms_scheduler.disable('THURSDAY_WINDOW');
exec dbms_scheduler.disable('FRIDAY_WINDOW');
exec dbms_scheduler.disable('SATURDAY_WINDOW');
exec dbms_scheduler.disable('SUNDAY_WINDOW');

exec dbms_scheduler.set_scheduler_attribute('SCHEDULER_DISABLED', 'TRUE');

alter system set job_queue_processes=0;

exec dbms_ijob.set_enabled(FALSE);

alter system flush shared_pool;
alter system flush shared_pool;

exec dbms_ijob.set_enabled(TRUE);

alter system set job_queue_processes=1000;

exec dbms_scheduler.set_scheduler_attribute('SCHEDULER_DISABLED', 'FALSE');

exec dbms_scheduler.enable('MONDAY_WINDOW');
exec dbms_scheduler.enable('TUESDAY_WINDOW');
exec dbms_scheduler.enable('WEDNESDAY_WINDOW');
exec dbms_scheduler.enable('THURSDAY_WINDOW');
exec dbms_scheduler.enable('FRIDAY_WINDOW');
exec dbms_scheduler.enable('SATURDAY_WINDOW');
exec dbms_scheduler.enable('SUNDAY_WINDOW');

--2) Logo em seguida tente executar a job manualmente com o seguinte comando:
--'''OBS: Execute o script no esquema que a JOB está criada.'''
BEGIN
DBMS_SCHEDULER.RUN_JOB(
JOB_NAME => '',
USE_CURRENT_SESSION => FALSE);
END;
/

--3) Verifique se o job rodou em:
select * from dba_scheduler_job_run_details where job_name='';

--4) Em último caso, se mesmo assim a job não tiver rodado:
--Crie a DDL do job:
--'''OBS: Execute o script no esquema que a JOB está criada.'''
--'''OBS: Mantenha o "PROCOBJ", altere apenas o nome do job no segundo parâmetro'''

select dbms_metadata.get_ddl('PROCOBJ', '') from dual;

ATENÇÃO: Após rodar a consulta, na linha da DDL onde tem o sys.dbms_scheduler.set_attribute verifique se as configurações do NLS estão para o Brasil,
se não estiver, será necessário realizar a alteração!

--Exemplo:

sys.dbms_scheduler.set_attribute('"MONITORAMENTO_JOB_2"','NLS_ENV','NLS_LANGUAGE=''BRAZILIAN PORTUGUESE'' NLS_TERRITORY=''BRAZIL'' NLS_CURRENCY=''R$'' NLS_ISO_CURRENCY=''BRAZIL'' NLS_NUMERIC_CHARACTERS='',.'' NLS_CALENDAR=''GREGORIAN'' NLS_DATE_FORMAT=''DD/MM/YYYY HH24:MI:SS'' NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE'' NLS_SORT=''WEST_EUROPEAN'' NLS_TIME_FORMAT=''HH24:MI:SSXFF'' NLS_TIMESTAMP_FORMAT=''DD/MM/YYYY HH24:MI:SSXFF'' NLS_TIME_TZ_FORMAT=''HH24:MI:SSXFF TZR'' NLS_TIMESTAMP_TZ_FORMAT=''DD/MM/YYYY HH24:MI:SSXFF TZR'' NLS_DUAL_CURRENCY=''Cr$'' NLS_COMP=''BINARY'' NLS_LENGTH_SEMANTICS=''BYTE'' NLS_NCHAR_CONV_EXCP=''FALSE''');

============================================================
SCRIPT: Verificar/Atribuir permissões do JAVA
ORIGEM: Notion (JAVA)
============================================================
--Para verificar todos os GRANTs do java atribuidos a um usuário / esquema
SELECT * FROM DBA_JAVA_POLICY WHERE GRANTEE = '<user_schema>';
   --substituir <user_schema> pelo nome do esquema / usuário

   SELECT * FROM SYS.dba_tab_privs
   WHERE OWNER = 'SYS'
   AND TABLE_NAME LIKE '%JAVA%'

--Para atribuir um GRANT de acesso do java a um diretorio:
exec dbms_java.grant_permission( '<user_schema>', 'SYS:java.io.FilePermission', '<dir_name>', 'read' )

   --I) substituir <user_schema> pelo nome do esquema / usuário
   --II) SYS:java.io.FilePermission é o tipo de permissão a ser atribuída
   --III) <dir_name> é o caminho completo do diretório
   --IV) read é a permissão de somente leitura, podendo ser também write para gravação e delete para exclusão

============================================================
SCRIPT: [texto solto no final do arquivo, após o link para a sub-página de instalação do Grid/ASM]
ORIGEM: Notion (SOLTO)
============================================================
ORA-00257: Erro de archiver. Conecte como SYSDBA só até ser resolvido.
