============================================================
SCRIPT: Script para exibir a descrição de todas as tabelas do usuário e as que foram concedidas a ele, mesmo ele não sendo o owner.
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT OWNER, 
       TABLE_NAME,
       TABLESPACE_NAME,
       STATUS
       FROM all_tables
WHERE OWNER NOT IN ('SYS', 'OUTLN', 'SYSTEM');

============================================================
SCRIPT: Script para exibir a descrição de todas as tabelas do usuário.
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
Select * from user_tables;

============================================================
SCRIPT: Script para consultar o tamanho de uma determinada tabela/schema
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT
   owner, 
   table_name, 
   TRUNC(sum(bytes)/1024/1024/1024) GB,
   ROUND( ratio_to_report( sum(bytes) ) over () * 100) Percent
FROM
(SELECT segment_name table_name, owner, bytes
 FROM dba_segments
 WHERE segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
 UNION ALL
 SELECT i.table_name, i.owner, s.bytes
 FROM dba_indexes i, dba_segments s
 WHERE s.segment_name = i.index_name
 AND   s.owner = i.owner
 AND   s.segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION')
 UNION ALL
 SELECT l.table_name, l.owner, s.bytes
 FROM dba_lobs l, dba_segments s
 WHERE s.segment_name = l.segment_name
 AND   s.owner = l.owner
 AND   s.segment_type IN ('LOBSEGMENT', 'LOB PARTITION')
 UNION ALL
 SELECT l.table_name, l.owner, s.bytes
 FROM dba_lobs l, dba_segments s
 WHERE s.segment_name = l.index_name
 AND   s.owner = l.owner
 AND   s.segment_type = 'LOBINDEX')
WHERE table_name in UPPER('DFE_NFE_EVENTO')
GROUP BY table_name, owner
HAVING SUM(bytes)/1024/1024 > 10  /* Ignore really small tables */
ORDER BY SUM(bytes) desc
;

============================================================
SCRIPT: Script para listar o tamanho de cada seguimento
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
select segment_type, 
       segment_name, 
       sum(bytes/1024/1024/1024) GB
 from dba_segments
--where segment_name='&Your_Table_Name' 
group by segment_type, segment_name
order by segment_type desc;

============================================================
SCRIPT: Script para consultar o informações das colunas de lob
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT * FROM DBA_LOBS
WHERE 
    OWNER = '<owner_schema>'
    AND
    TABLE_NAME = '<table_name>';

============================================================
SCRIPT: Script para obter informações detalhadas sobre as colunas das suas tabelas. No qual, você é dono.
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT * FROM user_tab_columns;

============================================================
SCRIPT: script para descrever os objetos de tabela para o usuario corrente/atual
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT OWNER, --DONO DA TABELA
       TABLE_NAME, --NOME DA TABELA
       TABLESPACE_NAME, --NOME DA TABLEPACE QUE CONTEM A TABELA, NULL PARA TABELAS PARTICIONADAS E TEMP...
       STATUS, -- SE UM DROP TABLE ANTERIOR FALHOU INDICA SE A TBL ESTA UNUSABLE OU VALID
       COMPRESSION, --INDICA SE O HCC ESTÁ HABILITADA OU NÃO
       COMPRESS_FOR -- COMPRESSÃO PADRÃO PRA QUE TIPO DE OPERAÇÃO
       FROM ALL_ALL_TABLES;

============================================================
SCRIPT: Script para descrever todos os objetos de tabelas no banco de dados
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT OWNER, --DONO DA TABELA
       TABLE_NAME, --NOME DA TABELA
       TABLESPACE_NAME, --NOME DA TABLEPACE QUE CONTEM A TABELA, NULL PARA TABELAS PARTICIONADAS E TEMP...
       STATUS, -- SE UM DROP TABLE ANTERIOR FALHOU INDICA SE A TBL ESTA UNUSABLE OU VALID
       COMPRESSION, --INDICA SE O HCC ESTÁ HABILITADA OU NÃO
       COMPRESS_FOR -- COMPRESSÃO PADRÃO PRA QUE TIPO DE OPERAÇÃO
       FROM DBA_ALL_TABLES;

============================================================
SCRIPT: Script para descrever todos os objetos de tabelas onde o user atual é o owner
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
SELECT 
       TABLE_NAME, --NOME DA TABELA
       TABLESPACE_NAME, --NOME DA TABLEPACE QUE CONTEM A TABELA, NULL PARA TABELAS PARTICIONADAS E TEMP...
       STATUS, -- SE UM DROP TABLE ANTERIOR FALHOU INDICA SE A TBL ESTA UNUSABLE OU VALID
       COMPRESSION, --INDICA SE O HCC ESTÁ HABILITADA OU NÃO
       COMPRESS_FOR -- COMPRESSÃO PADRÃO PRA QUE TIPO DE OPERAÇÃO
       FROM USER_ALL_TABLES;

============================================================
SCRIPT: Scripts para consultar as ultimas movimentações em uma tabela.
ORIGEM: Notion (TABELAS/INDEX/LOBS)
============================================================
    SELECT
        o.owner,
        o.object_name,
        o.object_type,
        to_char(s.last_active_time, 'DD/MM/YYYY HH24:MI:SS'),
        s.sql_text
    FROM
        v$sqlarea s
    JOIN
        dba_objects o ON s.parsing_schema_name = o.owner AND s.sql_text LIKE '%' || o.object_name || '%'
    WHERE
        o.object_type = 'TABLE'
        AND o.object_name = 'Z'
        AND UPPER(s.sql_text) not like '%X%'
        AND UPPER(s.sql_text) LIKE '%Y%'        
        AND s.last_active_time between SYSDATE - 31 AND SYSDATE;
        
      //=============================================================================
      
	--  4. Verificar SCN (último número de mudança) via DBA_TAB_MODIFICATIONS

BEGIN
  DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
END;
/

SELECT table_name, inserts, updates, deletes, timestamp
FROM dba_tab_modifications
WHERE table_name = 'NOME_DA_TABELA';

-- A coluna TIMESTAMP pode indicar a última modificação.

-- Mas pode estar desatualizada se o FLUSH_DATABASE_MONITORING_INFO não for chamado recentemente.

-- Funciona apenas se monitoramento de estatísticas estiver habilitado.

============================================================
SCRIPT: Lista todas as tabelas e views do dicionario de dados que estão acessiveis ao usurio
============================================================
SELECT * FROM DICTIONARY;
/
SELECT * FROM DIC;

============================================================
SCRIPT: Comando usado para trazer todos as tabelas pertencentes ao usuario que executou.
============================================================
SELECT * FROM TAB;
