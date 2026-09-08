============================================================
SCRIPT: Parar o serviço do firewalld
============================================================
[root@oracle ~]# systemctl stop firewalld
[root@oracle ~]# systemctl disable firewalld
Removed /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.

============================================================
SCRIPT: Configurar o SElinux
============================================================
#editar o seguinte arquivo
[root@oracle ~]# vi /etc/selinux/config

#alterar o valor do parametro SELINUX 
#de 
SELINUX=enforcing
#para
SELINUX=disabled

============================================================
SCRIPT: Editar o arquivo /etc/hosts
============================================================
#nesse arquivo adicionar uma linha com o IP e o hostname da maquina exemplo
192.168.100.25  oracle  oracle.localdomain

#rodar o comando ping + hostname para testar se a configuração funcionou

============================================================
SCRIPT: realizar o update do SO
============================================================
[root@oracle ~]# yum search update
[root@oracle ~]# yum -yu update
[root@oraclegridapex ~]# yum clean all ; yum repolist

============================================================
SCRIPT: 2) Instalação do pré-install Oracle 21c
============================================================
[root@oracle ~]# yum -y install oracle-database-preinstall-21c

============================================================
SCRIPT: 3) Criar os seguintes grupos (asmdba, asmoper, asmadmin)
============================================================
[root@oracle ~]# groupadd asmdba
[root@oracle ~]# groupadd asmoper
[root@oracle ~]# groupadd asmadmin

============================================================
SCRIPT: 4) Criado o usuario grid
============================================================
[root@oracle ~]# useradd -u 54322 -g oinstall -G dba,oper,asmdba,asmoper,asmadmin grid
[root@oracle ~]# usermod -g oinstall -G dba,racdba,oper,backupdba,dgdba,kmdba,asmdba,asmadmin grid

============================================================
SCRIPT: 5) Alterando o user oracle
============================================================
[root@oracle8u601 ~]# usermod -G oinstall,dba,racdba,oper,backupdba,dgdba,kmdba,asmdba,asmadmin oracle -c "Database"

============================================================
SCRIPT: 6) Criando os diretorios base e home
============================================================
[root@oracle8u601 ~]# mkdir -p /u01/app/21.0.0.0/grid (oracle home do grid)
[root@oracle8u601 ~]# mkdir -p /u01/app/grid
[root@oracle8u601 ~]# chown -R grid:oinstall /u01/app/21.0.0.0/grid/
[root@oracle8u601 ~]# chown -R grid:oinstall /u01/app/grid/
[root@oracle8u601 ~]# chmod -R 775 /u01/app/21.0.0.0/grid
[root@oracle8u601 ~]# chmod -R 775 /u01/app/grid/
[root@oracle8u601 ~]# chmod 775 /u01/app/
[root@oracle8u6 ~]# chown grid:oinstall /u01/app

============================================================
SCRIPT: 12) Download do Oracle GRID 21c e unzip para o GRID_HOME
============================================================
#link para download
https://www.oracle.com/database/technologies/oracle21c-linux-downloads.html#license-lightbox

# O arquivo pode ser jogado dentro do temp e unzip para dentro do grid_home
[grid@oracle tmp]$ unzip LINUX.X64_213000_grid_home.zip -d /u01/app/21.0.0.0/grid/

============================================================
SCRIPT: 13) Executar o gridSetup para configurar o diskgroup DATA
============================================================
#OBS - antes rodar os seguintes passos para exportar o display e a variavel CV_ASSUME_DISTID
export DISPLAY:ip_maquina:0.0
export CV_ASSUME_DISTID='OL7'
#Dentro do grid home executar o seguinte comando

./gridsetup.sh

============================================================
SCRIPT: Execução dos scripts root.sh (orainstRoot.sh e grid root.sh) solicitados durante a instalação do GRID
============================================================
[root@oracle ~]# /u01/app/oraInventory/orainstRoot.sh
Changing permissions of /u01/app/oraInventory.
Adding read,write permissions for group.
Removing read,write,execute permissions for world.

Changing groupname of /u01/app/oraInventory to oinstall.
The execution of the script is complete.

root@oracle ~]# /u01/app/oraInventory/orainstRoot.sh
Changing permissions of /u01/app/oraInventory.
Adding read,write permissions for group.
Removing read,write,execute permissions for world.

Changing groupname of /u01/app/oraInventory to oinstall.
The execution of the script is complete.
[root@oracle ~]# /u01/app/21.0.0.0/grid/root.sh
Performing root user operation.

The following environment variables are set as:
    ORACLE_OWNER= grid
    ORACLE_HOME=  /u01/app/21.0.0.0/grid

Enter the full pathname of the local bin directory: [/usr/local/bin]: (ENTER PARA CONTINUAR)
   Copying dbhome to /usr/local/bin ...
   Copying oraenv to /usr/local/bin ...
   Copying coraenv to /usr/local/bin ...

Creating /etc/oratab file...
Entries will be added to the /etc/oratab file as needed by
Database Configuration Assistant when a database is created
Finished running generic part of root script.
Now product-specific root actions will be performed.
Using configuration parameter file: /u01/app/21.0.0.0/grid/crs/install/crsconfig_params
2023-06-11 20:51:39: Got permissions of file /u01/app/grid/crsdata/oracle/crsconfig: 0775
2023-06-11 20:51:39: Got permissions of file /u01/app/grid/crsdata: 0775
2023-06-11 20:51:39: Got permissions of file /u01/app/grid/crsdata/oracle: 0775
The log of current session can be found at:
  /u01/app/grid/crsdata/oracle/crsconfig/roothas_2023-06-11_08-51-39PM.log
Redirecting to /bin/systemctl restart rsyslog.service
LOCAL ADD MODE
Creating OCR keys for user 'grid', privgrp 'oinstall'..
Operation successful.
LOCAL ONLY MODE
Successfully accumulated necessary OCR keys.
Creating OCR keys for user 'root', privgrp 'root'..
Operation successful.
CRS-4664: Node oracle successfully pinned.
2023/06/11 20:51:59 CLSRSC-330: Adding Clusterware entries to file 'oracle-ohasd.service'

oracle     2023/06/11 20:53:38     /u01/app/grid/crsdata/oracle/olr/backup_20230611_205338.olr     0
2023/06/11 20:53:42 CLSRSC-327: Successfully configured Oracle Restart for a standalone server

============================================================
SCRIPT: 16) Criar diretorios HOME e BASE do Oracle Database com permissões
============================================================
[root@oracle ~]# mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
[root@oracle ~]# chown -R oracle:oinstall /u01/app/oracle/
[root@oracle ~]# chmod -R 775 /u01/app/oracle/

============================================================
SCRIPT: Unzip do software Oracle Database 19c para o ORACLE_HOME
============================================================
[oracle@oracle tmp]$ unzip LINUX.X64_193000_db_home.zip -d /u01/app/oracle/product/19.0.0/dbhome_1/

============================================================
SCRIPT: Rodar o runInstaller.sh do Oracle Database
============================================================
#setar as variaveis abaixo
[oracle@oracle dbhome_1]$ export CV_ASSUME_DISTID='OL7'
[oracle@oracle dbhome_1]$ export DISPLAY=192.168.100.2:0.0

#rodar o comando abaixo
./runInstaller.sh

============================================================
SCRIPT: Execução do script root.sh da instalação do Oracle Database
============================================================
[root@oracle ~]# /u01/app/oracle/product/19.0.0/dbhome_1/root.sh
Performing root user operation.

The following environment variables are set as:
    ORACLE_OWNER= oracle
    ORACLE_HOME=  /u01/app/oracle/product/19.0.0/dbhome_1

Enter the full pathname of the local bin directory: [/usr/local/bin]:
The contents of "dbhome" have not changed. No need to overwrite.
The file "oraenv" already exists in /usr/local/bin.  Overwrite it? (y/n)
[n]: y
   Copying oraenv to /usr/local/bin ...
The file "coraenv" already exists in /usr/local/bin.  Overwrite it? (y/n)
[n]: y
   Copying coraenv to /usr/local/bin ...

Entries will be added to the /etc/oratab file as needed by
Database Configuration Assistant when a database is created
Finished running generic part of root script.
Now product-specific root actions will be performed.
Oracle Trace File Analyzer (TFA - Standalone Mode) is available at :
    /u01/app/oracle/product/19.0.0/dbhome_1/bin/tfactl

Note :
1. tfactl will use TFA Service if that service is running and user has been granted access
2. tfactl will configure TFA Standalone Mode only if user has no access to TFA Service or TFA is not installed
