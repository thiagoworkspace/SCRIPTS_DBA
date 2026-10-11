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

--4) Access the unziped patch directory and check the README file for any specific instructions or prerequisites before applying the patch (we can export the README.html to our computer to a better view).
--obs: Its important to read the README file carefully, as it may contain critical information about the patch, including any known issues or additional steps required for a successful application, such as the OPatch utility version.
--obs2: For exemple, in this patch, the README file indicates that we need to have OPatch version 12.2.0.1.52 or later to apply this patch.

--5) To check the current OPatch version installed on the server, we can run the following command in the terminal:
$ORACLE_HOME/OPatch/opatch version
OPatch Version: 12.2.0.1.17

OPatch succeeded.

--6) If the OPatch version is lower than the required version, we need to download and install the latest OPatch utility from the Oracle support site. The OPatch number is in the README file
--obs: We download the release Opatch for DB <version> in this case 19.0.0.0.0 and plataform or language Linux x86-64. Upload the zip file in the same directory where we have the patch and unzip it. (owner mus be oracle:oinstall).


--7) Now, we need to make a backup of the original OPatch directory before replacing it with the new version. We can do this by renaming the existing OPatch directory to something like "OPatch_bkp". After that, we can move the new OPatch directory to the $ORACLE_HOME directory. The commands to do this are as follows:
[oracle@oraclelinux installs]$ mv OPatch/ OPatch_bkp/
[oracle@oraclelinux installs]$ mv OPatch/ /u01/app/oracle/product/19.0.0/dbhome_1/
[oracle@oraclelinux OPatch]$ ./opatch version
OPatch Version: 12.2.0.1.53

OPatch succeeded.




