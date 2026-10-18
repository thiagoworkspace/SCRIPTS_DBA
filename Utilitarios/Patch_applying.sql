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


--12) This application of the patch only change the dbhome files, we need to run the datapatch utility to apply the SQL changes to the database. We can do this by running the following command in the terminal:
--0bs: First, we need to garantee that some steps
/*
   Step 1: Start the database in normal mode/open mode (not upgrade mode, unless specific instructions ask it).
   > STARTUP;
   
   Step 2: Open all pluuggable databases (PDBs) in read/write mode. (if the pdb is closed, it will be skipped by the datapatch utility).
   ALTER PLUGGABLE DATABASE ALL OPEN;
*/



--13) After doing all the steps above, we can run the datapatch utility to apply the SQL changes to the database. We can do this by running the following command in the terminal:
[oracle@oraclelinux OPatch]$ ./datapatch -verbose

--obs: something lie this will be displayed in the terminal:
/*
Connecting to database...OK
Gathering database info...done

Note:  Datapatch will only apply or rollback SQL fixes for PDBs
       that are in an open state, no patches will be applied to closed PDBs.
       Please refer to Note: Datapatch: Database 12c Post Patch SQL Automation
       (Doc ID 1585822.1)

Bootstrapping registry and package to current versions...done
Determining current state...done

Current state of interim SQL patches:
  No interim patches found

Current state of release update SQL patches:
  Binary registry:
    19.32.0.0.0 Release_Update 260705220710: Installed
  PDB CDB$ROOT:
    Applied 19.3.0.0.0 Release_Update 190410122720 successfully on 03-OCT-26 05.15.41.450838 PM
  PDB PDB:
    Applied 19.3.0.0.0 Release_Update 190410122720 successfully on 03-OCT-26 05.26.35.380820 PM
  PDB PDB$SEED:
    Applied 19.3.0.0.0 Release_Update 190410122720 successfully on 03-OCT-26 05.26.35.380820 PM

Adding patches to installation queue and performing prereq checks...done
Installation queue:
  For the following PDBs: CDB$ROOT PDB$SEED PDB
    No interim patches need to be rolled back
    Patch 39472050 (Database Release Update : 19.32.0.0.260721 (39472050)):
      Apply from 19.3.0.0.0 Release_Update 190410122720 to 19.32.0.0.0 Release_Update 260705220710
    No interim patches need to be applied
    Installing patches...

    Patch installation complete.  Total patches installed: 3

Validating logfiles...done
Patch 39472050 apply (pdb CDB$ROOT): SUCCESS
  logfile: /u01/app/oracle/cfgtoollogs/sqlpatch/39472050/28919163/39472050_apply_ORCL_CDBROOT_2026Oct12_13_59_18.log (no errors)
Patch 39472050 apply (pdb PDB$SEED): SUCCESS
  logfile: /u01/app/oracle/cfgtoollogs/sqlpatch/39472050/28919163/39472050_apply_ORCL_PDBSEED_2026Oct12_14_32_22.log (no errors)
Patch 39472050 apply (pdb PDB): SUCCESS
  logfile: /u01/app/oracle/cfgtoollogs/sqlpatch/39472050/28919163/39472050_apply_ORCL_PDB_2026Oct12_14_32_23.log (no errors)
SQL Patching tool complete on Mon Oct 12 14:59:31 2026

*/


--15) Now we need to check and upgrade (if necessery) the timezone file
/*
  The timezone file is a file that contains information about time zones and their offsets from Coordinated Universal Time (UTC). It is used by the database to handle date and time values correctly, especially when dealing with different time zones. The timezone file is important for applications that rely on accurate date and time calculations, such as scheduling, logging, and reporting.
*/


--16) Chek current ttime zone version
/*
  The v$timezone_file view displays the zone file version being used by the database.
*/

SQL> SELECT * FROM V$TIMEZONE_FILE;

FILENAME                VERSION     CON_ID
-------------------- ---------- ----------
timezlrg_32.dat              32          0

SQL>


--17) The latest available version of the timezone file is displayed using the GET_LATEST_TIMEZONE_VERSION Function in the DBMS_DST package.

SQL> SELECT DBMS_DST.GET_LATEST_TIMEZONE_VERSION FROM DUAL;

GET_LATEST_TIMEZONE_VERSION
---------------------------
                         45

SQL>


--OBS: We can see there is a difference between the current and latest version of the timezone file, so we should consider performing an upgrade.



--18) Now we need to access the following directory to run the two important .sql files to check/run the timezone upgrade.
--obs: In an multi-tenant environment, we need to run the scripts in the root container (CDB$ROOT) and in all PDBs.
[oracle@oraclelinux admin]$ cd /u01/app/oracle/product/19.0.0/dbhome_1/rdbms/admin
SQL> show con_name;

CON_NAME
------------------------------
CDB$ROOT
SQL>
SQL> @utltz_upg_check.sql
/*
Session altered.

INFO: Starting with RDBMS DST update preparation.
INFO: NO actual RDBMS DST update will be done by this script.
INFO: If an ERROR occurs the script will EXIT sqlplus.
INFO: Doing checks for known issues ...
INFO: Database version is 19.0.0.0 .
INFO: This database is a Multitenant database.
INFO: Current container is CDB$ROOT .
INFO: Updating the RDBMS DST version of the CDB / CDB$ROOT database
INFO: will NOT update the RDBMS DST version of PDB databases in this CDB.
WARNING: There are 1 open PDBs .
WARNING: They will be closed when running utltz_upg_apply.sql .
INFO: Database RDBMS DST version is DSTv32 .
INFO: No known issues detected.
INFO: Now detecting new RDBMS DST version.
A prepare window has been successfully started.
INFO: Newest RDBMS DST version detected is DSTv45 .
INFO: Next step is checking all TSTZ data.
INFO: It might take a while before any further output is seen ..
A prepare window has been successfully ended.
INFO: A newer RDBMS DST version than the one currently used is found.
INFO: Note that NO DST update was yet done.
INFO: Now run utltz_upg_apply.sql to do the actual RDBMS DST update.
INFO: Note that the utltz_upg_apply.sql script will
INFO: restart the database 2 times WITHOUT any confirmation or prompt.

Session altered.
*/


SQL> @utltz_upg_apply.sql
/*
Session altered.

INFO: If an ERROR occurs, the script will EXIT SQL*Plus.
INFO: The database RDBMS DST version will be updated to DSTv45 .
INFO: This database is a Multitenant database.
INFO: Current container is CDB$ROOT .
INFO: Updating the RDBMS DST version of the CDB / CDB$ROOT database
INFO: will NOT update the RDBMS DST version of PDB databases in this CDB.
WARNING: There are 1 open PDBs .
WARNING: They will be closed when CDB$ROOT is restarted
WARNING: This script will restart the database 2 times
WARNING: WITHOUT asking ANY confirmation.
WARNING: Hit control-c NOW if this is not intended.

SCRIPT
--------------------------------------------------------------------------------
?/rdbms/admin/utltz_upg_apply_patch.sql
INFO: Restarting the database in UPGRADE mode to start the DST upgrade.
Database closed.
Database dismounted.
ORACLE instance shut down.
ORACLE instance started.

Total System Global Area 6442447688 bytes
Fixed Size                  9192264 bytes
Variable Size            1442840576 bytes
Database Buffers         4982833152 bytes
Redo Buffers                7581696 bytes
Database mounted.
Database opened.
INFO: Starting the RDBMS DST upgrade.
INFO: Upgrading all SYS owned TSTZ data.
INFO: It might take time before any further output is seen ...
An upgrade window has been successfully started.
INFO: Restarting the database in NORMAL mode to upgrade non-SYS TSTZ data.
Database closed.
Database dismounted.
ORACLE instance shut down.
ORACLE instance started.

Total System Global Area 6442447688 bytes
Fixed Size                  9192264 bytes
Variable Size            1442840576 bytes
Database Buffers         4982833152 bytes
Redo Buffers                7581696 bytes
Database mounted.
Database opened.
INFO: Upgrading all non-SYS TSTZ data.
INFO: It might take time before any further output is seen ...
INFO: Do NOT start any application yet that uses TSTZ data!
INFO: Next is a list of all upgraded tables:
Table list: "GSMADMIN_INTERNAL"."AQ$_CHANGE_LOG_QUEUE_TABLE_S"
Number of failures: 0
Table list: "GSMADMIN_INTERNAL"."AQ$_CHANGE_LOG_QUEUE_TABLE_L"
Number of failures: 0
Table list: "MDSYS"."SDO_DIAG_MESSAGES_TABLE"
Number of failures: 0
Table list: "DVSYS"."AUDIT_TRAIL$"
Number of failures: 0
Table list: "DVSYS"."SIMULATION_LOG$"
Number of failures: 0
INFO: Total failures during update of TSTZ data: 0 .
An upgrade window has been successfully ended.
INFO: Your new Server RDBMS DST version is DSTv45 .
INFO: The RDBMS DST update is successfully finished.
INFO: Make sure to exit this SQL*Plus session.
INFO: Do not use it for timezone related selects.

Session altered.

SQL>
*/


--OBS: After running the utltz_upg_apply.sql script, we can check the current timezone version again to verify that the upgrade has been applied successfully.
--OBS2> Do these steps  again for all PDBs.










