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

--8) Now, we can proceed to apply the patch. Before applying the patch, we need to ensure that the databases are in a consistent state. We can do this by shutting down the databases and backup the DB_HOME directory.
--obs: to backup the DB_HOME directory, we can use the step in the README file
/*
2 Prerequisites
It is highly recommended to take a backup of the Oracle_Home binaries and Central Inventory prior to applying patches. For further information, see My Oracle Support document KB137807 How to Perform ORACLE_HOME Backup?.

For SUSE Linux Enterprise Server (SLES) 15 SP3, and above, install the compat-libpthread-nonshared package. See section 5.5.12 in SUSE's release notes (for SLES 15 SP3) and Note KB117927.

This section includes the following section:

Section 2.1, "OPatch Utility"
*/
--obs: Or to simplyfy the process, we can use the following command to backup the DB_HOME directory:
[oracle@oraclelinux 19.0.0]$ tar -pcvf /home/oracle/oracle_home_bkup.tar dbhome_1/


--9) (OPTIONAL: because it's a good practice and when we run the apply it do the prereq automatically) Access the folder where the patch is located and run the following command to run the prereq script for the patch:
[oracle@oraclelinux installs]$ /u01/app/oracle/product/19.0.0/dbhome_1/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph 39472050/
Oracle Interim Patch Installer version 12.2.0.1.53
Copyright (c) 2026, Oracle Corporation.  All rights reserved.

PREREQ session

Oracle Home       : /u01/app/oracle/product/19.0.0/dbhome_1
Central Inventory : /u01/app/19.0.0/oraInventory
   from           : /u01/app/oracle/product/19.0.0/dbhome_1/oraInst.loc
OPatch version    : 12.2.0.1.53
OUI version       : 12.2.0.7.0
Log file location : /u01/app/oracle/product/19.0.0/dbhome_1/cfgtoollogs/opatch/opatch2026-10-11_14-38-00PM_1.log

Invoking prereq "checkconflictagainstohwithdetail"

Prereq "checkConflictAgainstOHWithDetail" passed.

OPatch succeeded.


--10) After running the prereq script, we can proceed to apply the patch. We can do this by running the following command in the terminal:
oracle@oraclelinux 39472050]$ /u01/app/oracle/product/19.0.0/dbhome_1/OPatch/opatch apply -oh /u01/app/oracle/product/19.0.0/dbhome_1/
--obs: In this moment we can see the patch doing the prereq automatically and asking if we want to continue with the patch application. We can type "y" to proceed.
"Oracle Interim Patch Installer version 12.2.0.1.53
Copyright (c) 2026, Oracle Corporation.  All rights reserved.


Oracle Home       : /u01/app/oracle/product/19.0.0/dbhome_1
Central Inventory : /u01/app/19.0.0/oraInventory
   from           : /u01/app/oracle/product/19.0.0/dbhome_1/oraInst.loc
OPatch version    : 12.2.0.1.53
OUI version       : 12.2.0.7.0
Log file location : /u01/app/oracle/product/19.0.0/dbhome_1/cfgtoollogs/opatch/opatch2026-10-11_15-09-28PM_1.log

Verifying environment and performing prerequisite checks...

--------------------------------------------------------------------------------
Start OOP by Prereq process.
Launch OOP...

Oracle Interim Patch Installer version 12.2.0.1.53
Copyright (c) 2026, Oracle Corporation.  All rights reserved.


Oracle Home       : /u01/app/oracle/product/19.0.0/dbhome_1
Central Inventory : /u01/app/19.0.0/oraInventory
   from           : /u01/app/oracle/product/19.0.0/dbhome_1/oraInst.loc
OPatch version    : 12.2.0.1.53
OUI version       : 12.2.0.7.0
Log file location : /u01/app/oracle/product/19.0.0/dbhome_1/cfgtoollogs/opatch/opatch2026-10-11_15-11-37PM_1.log

Verifying environment and performing prerequisite checks...
OPatch continues with these patches:   39472050

Do you want to proceed? [y|n]"

Patch 39472050 successfully applied.
Sub-set patch [29517242] has become inactive due to the application of a super-set patch [39472050].
Please refer to Doc ID 2161861.1 for any possible further required actions.
Log file location: /u01/app/oracle/product/19.0.0/dbhome_1/cfgtoollogs/opatch/opatch2026-10-11_15-11-37PM_1.log

OPatch succeeded.



--11) After applying the patch, we can check the current database version again to verify that the patch has been applied successfully. We can do this by running the following command in sqlplus:
SQL> SET LINESIZE 200
SQL> COL INSTANCE_NAME FORMAT A30
SQL> COL VERSION FORMAT A50
SQL> COL VERSION_FULL FORMAT A50
SQL> COL STATUS FORMAT A10
SQL> SELECT INSTANCE_NAME, VERSION, VERSION_FULL, STATUS FROM V$INSTANCE;
INSTANCE_NAME                  VERSION                                            VERSION_FULL                                       STATUS
------------------------------ -------------------------------------------------- -------------------------------------------------- ----------
orcl                           19.0.0.0.0                                         19.32.0.0.0                                        OPEN


--12) But this application of the patch only change the dbhome files, we need to run the datapatch utility to apply the SQL changes to the database. We can do this by running the following command in the terminal:









