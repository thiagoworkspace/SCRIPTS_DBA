============================================================
SCRIPT: Exemplo de script para criação de schema
============================================================
CREATE USER <nome_schema> PROFILE "DEFAULT" 
IDENTIFIED BY "<senha>" DEFAULT TABLESPACE "<tablespace>" 
TEMPORARY TABLESPACE "TEMP" QUOTA UNLIMITED ON "<tablespace>" 
QUOTA UNLIMITED ON "<tablespace_IDX>" ACCOUNT UNLOCK;
GRANT UNLIMITED TABLESPACE TO "<tablespace>";
GRANT "CONNECT" TO "<nome_schema>";
GRANT "DBA" TO "<nome_schema>";
GRANT CREATE TABLE TO "<nome_schema>";
GRANT CREATE SESSION TO "<nome_schema>";
GRANT "<rolex>" TO "<nome_schema>";
GRANT "<roley>" TO "<nome_schema>";
GRANT "<rolez>" TO "<nome_schema>";

============================================================
SCRIPT: Exemplo de criação de usuário
============================================================
CREATE USER "THIAGO" IDENTIFIED BY "********" ACCOUNT UNLOCK;
GRANT "DBA" TO "THIAGO";
GRANT "CONNECT" TO "THIAGO";
GRANT CREATE SESSION TO "THIAGO";

============================================================
SCRIPT: Dropar schema/users
============================================================
drop user <nome_schema> cascade;

============================================================
SCRIPT: Script force drop
============================================================
DECLARE
  open_count integer;
BEGIN
  -- prevent any further connections
  EXECUTE IMMEDIATE 'alter user @USERNAME account lock';
  --kill all sessions
  FOR session IN (SELECT sid, serial# 
                  FROM  v$session 
                  WHERE username = '@USERNAME')
  LOOP
    -- the most brutal way to kill a session
    EXECUTE IMMEDIATE 'alter system disconnect session ''' || session.sid || ',' || session.serial# || ''' immediate';
  END LOOP;
  -- killing is done in the background, so we need to wait a bit
  LOOP
    SELECT COUNT(*) 
      INTO open_count 
      FROM  v$session WHERE username = '@USERNAME';
    EXIT WHEN open_count = 0;
    dbms_lock.sleep(0.5);
  END LOOP;
  -- finally, it is safe to issue the drop statement
  EXECUTE IMMEDIATE 'drop user @USERNAME cascade';
END;

============================================================
SCRIPT: Script para consultar o tamanho de um schema
============================================================
select owner AS Schema, 
       sum(bytes/1024/1024/1024) AS size_in_GB
from dba_segments
where OWNER = '<schema_name>'
group by owner
order by owner desc;

============================================================
SCRIPT: Script para consultar o tamanho do schema, agrupado por seguimentos.
============================================================
select segment_type, sum(bytes)/1024/1024/1024 size_in_GB
from dba_segments
where OWNER = ''
group by segment_type;

============================================================
SCRIPT: Script para consultar o tamanho de um seguimento (tabela)
============================================================
select segment_name,segment_type, sum(bytes/1024/1024/1024) GB
 from dba_segments
 where segment_name IN ('DIM_PESSOA', 'FAT_COMPARATIVO')
group by segment_name,segment_type;

============================================================
SCRIPT: Script para consultar se um usuário esta bloqueado ou não
============================================================
SELECT username, account_status, created, lock_date, expiry_date
  FROM dba_users
 WHERE account_status != 'OPEN';

============================================================
SCRIPT: Query para checar as roles concedidas de um usuário.
============================================================
SELECT *
FROM DBA_ROLE_PRIVS
WHERE GRANTEE = '&USER';

============================================================
SCRIPT: Query para checar os privilegios super especiais concedidos a um usuario.
============================================================
/*VIEW ABAIXO PODEMOS VER OS PRIVILEGIOS SUPER ESPECIAIS 
DOS USUARIOS QUE RECEBERAM ALGUM SYSTEM PRIVILEGIO.
*/
SELECT * FROM V$PWFILE_USERS

============================================================
SCRIPT: Query para checar as os privilégios concedidos para um usuário
============================================================
SELECT *
FROM DBA_TAB_PRIVS
WHERE GRANTEE = '&USER'

============================================================
SCRIPT: Query para checar os privilégios dados a uma role concedida a um usuário
============================================================
SELECT * FROM DBA_TAB_PRIVS WHERE GRANTEE IN
(SELECT granted_role FROM DBA_ROLE_PRIVS WHERE GRANTEE = '&USER') order by 3;

============================================================
SCRIPT: Script para exibir todos os objetos pertencentes ao seu usuário.
============================================================
SELECT * FROM user_objects;

============================================================
SCRIPT: Script para exibir todos os objetos pertencentes a usuário e aos quais tem acesso.
============================================================
SELECT * FROM all_objects;

============================================================
SCRIPT: Script usado para consultar a data de criação de um usuario e a ultima alteração de senha
============================================================
SELECT
   name,
   TO_CHAR(ctime, 'DD/MM/YYYY HH24:MI:SS') "User was created on",
   TO_CHAR(PTIME, 'DD/MM/YYYY HH24:MI:SS') "Password was last changed on"
FROM 
   sys.user$
WHERE
    NAME='USERNAME';

============================================================
SCRIPT: Para encontrar o perfil atual de um usuario.
ORIGEM: Notion (PROFILE USERS)
============================================================
SELECT 
    username, 
    profile
FROM 
    dba_users
WHERE 
    username = '<username>';

============================================================
SCRIPT: Para encontrar os parâmetros do DEFAULT ou outro PROFILE.
ORIGEM: Notion (PROFILE USERS)
============================================================
SELECT 
  * 
FROM 
    dba_profiles
WHERE 
    PROFILE = '<profile_name>'
ORDER BY 
    resource_type, 
    resource_name;

============================================================
SCRIPT: comando usado para criação de um profile novo
ORIGEM: Notion (PROFILE USERS)
============================================================
CREATE PROFILE <profilename> LIMIT 
    SESSIONS_PER_USER          UNLIMITED
    CPU_PER_SESSION            UNLIMITED 
    CPU_PER_CALL               3000 
    CONNECT_TIME               15
    .
    .
    .
    .;

============================================================
SCRIPT: Alter profile
ORIGEM: Notion (PROFILE USERS)
============================================================
ALTER PROFILE DEFAULT LIMIT <profile_name> UNLIMITED;

============================================================
SCRIPT: Comando usado para alterar o profile default de um user
ORIGEM: Notion (PROFILE USERS)
============================================================
ALTER USER <USERNAME> PROFILE <PROFILENAME>;
