/*
Author: Thiago Batista Barbosa Ribeiro
Date: 2026-10-10
Version: Alpha
Objective: Step-by-step guide to apply patches to Oracle Database 19c on an Oracle Linux 8+ single instance server with ASM.
Brief description: This script contains detailed instructions to apply patches to Oracle Database 19c, ensuring the process is performed safely and efficiently. It includes preparation steps, patch execution and post-application verification.
In this script we will apply the RU 19.32 patch (the latest from Oracle so far) to Oracle Database 19c.
*/

--1) Connected to the database as SYSDBA, check the current database version (sqlplus):
--In this example the full version is 19.3, which is the initial database version when installing Oracle Database 19c.
SQL> SET LINESIZE 200
SQL> COL INSTANCE_NAME FORMAT A30
SQL> COL VERSION FORMAT A50
SQL> COL VERSION_FULL FORMAT A50
SQL> COL STATUS FORMAT A10
SQL> SELECT INSTANCE_NAME, VERSION, VERSION_FULL, STATUS FROM V$INSTANCE;
INSTANCE_NAME                  VERSION           VERSION_FULL                                       STATUS
------------------------------ ----------------- -------------------------------------------------- ----------
orcl                           19.0.0.0.0        19.3.0.0.0                                         OPEN




--2) Access the Oracle support site (MOS) and download the desired patch. In our case, we will download the RU 19.32 patch (Patch Number: 39472050) for Oracle Database 19c.

--3) After downloading the patch, upload the file to a "temporary" directory on the Oracle Linux 8+ server where Oracle Database 19c is installed. For example, we can create a directory called "/u01/installs", copy the patch file there, change the owner to oracle:oinstall and unzip the file.


