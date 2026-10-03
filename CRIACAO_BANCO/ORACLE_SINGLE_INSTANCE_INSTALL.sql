/*
Author: Thiago Batista Barbosa Ribeiro
Date: 2026-09-12 
Version: Alfa
Objective: Script de instalação do Oracle Database 19c em um servidor Oracle Linux 8+ single instance com ASM.
Link de apoio: https://en.data4tech.com/post/oracle-grid-infrastructure-19c-and-oracle-database-19c-single-instance-installation-on-oracle-linux
*/


--** ETAPA 1 - CONFIGURAÇÃO DO SERVIDOR, PRE-INSTALL DO ORACLE, CRIACAO DO USUARIO GRID E GRUPOS E CONFIGURAÇÃO DE DISCOS PARA ASM **--
--Desativar o firewall default do linux.
[root@oraclelinux ~]# systemctl stop firewalld
[root@oraclelinux ~]# systemctl disable firewalld
Removed /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.

--Configurar o arquivo SELINUX conf.
[root@oraclelinux ~]# vi /etc/selinux/config

/*DE:
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=enforcing
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
*/

/*PARA:
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
*/

--A alteracao do SELINUX so vale apos o reboot. Para desativar o enforcing imediatamente:
[root@oraclelinux ~]# setenforce 0


--Adicionar uma entrada no arquivo hosts
[root@oraclelinux ~]# vi /etc/hosts
/*
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.100.140 oraclelinux     oraclelinux.localdomain
*/

--Atualizar o servidor e rodar um upgrade do sistema operacional.
[root@oraclelinux ~]# yum update -y
[root@oraclelinux ~]# yum -y upgrade


--Instalar os pacotes necessários para o Oracle Database 19c.
[root@oraclelinux ~]# yum install -y oracle-database-preinstall-19c

--Criação dos grupos de asm.
[root@oraclelinux ~]# groupadd -g 54327 asmadmin
[root@oraclelinux ~]# groupadd -g 54328 asmdba
[root@oraclelinux ~]# groupadd -g 54329 asmoper

--Criacao do usuario grid (grupo primario oinstall, o mesmo do oraInventory e do chown de /u01).
[root@oraclelinux ~]# useradd -u 54331 -g oinstall -G asmadmin,asmdba,asmoper,dba grid
[root@oraclelinux ~]# passwd grid

--Adicionar o usuario oracle ao grupo de dba e asmdba.
[root@oraclelinux ~]# usermod -a -G dba,asmdba oracle


--Criação do diretório de instalação do Oracle Grid Infrastructure.
[root@oraclelinux ~]# mkdir -p /u01/app/grid
[root@oraclelinux ~]# mkdir -p /u01/app/19.0.0/grid
[root@oraclelinux ~]# mkdir -p /u01/app/oracle
[root@oraclelinux ~]# mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1

--Alterar as permissões do diretório de instalação do Oracle Grid Infrastructure.
[root@oraclelinux ~]# chown -R grid:oinstall /u01
[root@oraclelinux ~]# chown -R oracle:oinstall /u01/app/oracle
[root@oraclelinux ~]# chmod -R 775 /u01


--Instalação do chronyd (com usuario root) para sincronização de horário.
[root@oraclelinux ~]# yum install -y chrony
[root@oraclelinux ~]# systemctl enable chronyd 
[root@oraclelinux ~]# systemctl start chronyd

--Checar a sincronização do chronyd.
[root@oraclelinux ~]# chronyc tracking



--Configuração dos discos para serem usados no ASM. (Com usuario root)

--Listar os discos disponíveis no servidor.
[root@oraclelinux ~]# lsblk


--Com o nome dos discos disponíveis, criar os volumes físicos para o ASM. rodar o comando abaixo para pegar o UID dos discos.
[root@oraclelinux ~]# /lib/udev/scsi_id -gud /dev/sdb
[root@oraclelinux ~]# /lib/udev/scsi_id -gud /dev/sdc

--Criar um arquivo de rules para dispositivos do ASM com os parametros abaixo.
[root@oraclelinux ~]# vi /etc/udev/rules.d/99-asm-disks.rules

/*
KERNEL=="sd*", OWNER="grid", GROUP="asmadmin", MODE="0660", ENV{DEVTYPE}=="disk", PROGRAM=="/lib/udev/scsi_id -gud /dev/$name", RESULT=="1ATA_VBOX_HARDDISK_VB8ffdec7f-e4ab2503", SYMLINK+="oracleasm/DATA_ASM_1"
KERNEL=="sd*", OWNER="grid", GROUP="asmadmin", MODE="0660", ENV{DEVTYPE}=="disk", PROGRAM=="/lib/udev/scsi_id -gud /dev/$name", RESULT=="1ATA_VBOX_HARDDISK_VB2f9218b4-51c05db1", SYMLINK+="oracleasm/RECO_ASM_1"
*/

--Recarregar as regras do udev.
[root@oraclelinux ~]# udevadm control --reload-rules && udevadm trigger --action=add

--(Opcional) Verificar se os discos foram criados corretamente.
[root@oraclelinux ~]# ls -lahtr /dev | grep -e sdb -e sdc
[root@oraclelinux ~]# ls -lahtr /dev/oracleasm/



--** ETAPA 2 - INSTALAÇÃO DO ORACLE GRID INFRASTRUCTURE E ORACLE DATABASE **--

--Fazer o download do Oracle Grid Infrastructure 19c e Oracle Database 19c no site da Oracle. (https://www.oracle.com/br/database/technologies/oracle19c-linux-downloads.html)

--1) Subir o Oracle Grid Infrastructure 19c no servidor alterar o owner para grid e descompactar o arquivo como grid.
[root@oraclelinux ~]# chown grid:oinstall /u01/app/19.0.0/grid/LINUX.X64_193000_grid_home.zip
[root@oraclelinux ~]# su - grid
[grid@oraclelinux ~]$ cd /u01/app/19.0.0/grid
[grid@oraclelinux grid]$ unzip -q /u01/app/19.0.0/grid/LINUX.X64_193000_grid_home.zip


--2) Exportar as variáveis de ambiente DISPLAY e CV_ASSUME_DISTID (com o usuario grid).
[grid@oraclelinux grid]$ export DISPLAY=<ip_do_servidor_local>:0.0
[grid@oraclelinux grid]$ export CV_ASSUME_DISTID=OEL7

--3) Rodar o comando de instalação do Oracle Grid Infrastructure 19c (com o usuario grid, o instalador nao roda como root).
[grid@oraclelinux grid]$ ./gridSetup.sh

--4) Seguir os passos do assistente de instalação do Oracle Grid Infrastructure 19c.
"Configure Oracle Grid Infrastructure for a Standalone Server (Oracle Restart)"
"Create ASM Disk Group -> Disk group Name -> DATA -> Redundancy -> external (only for this lab) change discovery path to /dev/oracleasm/* -> Select Disks 'DATA_ASM_1' only"
"Specify ASM Passwords -> Use same password for all accounts -> Enter Password"
"Specify Management Options -> Do not configure Enterprise Manager (EM) Express"
"Privileged Operating System Groups -> OSASM: asmadmin | OSDBA for ASM: asmdba | OSOPER for ASM: asmoper"
"Specify Installation Location -> Oracle base: /u01/app/grid (Software location ja fixo em /u01/app/19.0.0/grid)"
"Create Inventory -> /u01/app/oraInventory"
"Root Script Execution -> Execute the scripts as root user"
"Perform Prerequisite Checks -> Ignore any warnings and continue"
"Installation Summary -> Install"
"Execute Configuration Scripts -> Execute the scripts as root user in another terminal"
"After the scripts have been executed, click OK to continue"
"The configuration of Oracle Grid Infrastructure for a Standalone Server is complete"


--5) Com a conclusão da instalação, rodar o comando crsctl stat res -t
[grid@oraclelinux grid]$ /u01/app/19.0.0/grid/bin/crsctl stat res -t
"
--------------------------------------------------------------------------------
Name           Target  State        Server                   State details
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.DATA.dg
               ONLINE  ONLINE       oraclelinux              STABLE
ora.LISTENER.lsnr
               ONLINE  ONLINE       oraclelinux              STABLE
ora.asm
               ONLINE  ONLINE       oraclelinux              Started,STABLE
ora.ons
               OFFLINE OFFLINE      oraclelinux              STABLE
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.cssd
      1        ONLINE  ONLINE       oraclelinux              STABLE
ora.diskmon
      1        OFFLINE OFFLINE                               STABLE
ora.evmd
      1        ONLINE  ONLINE       oraclelinux              STABLE
--------------------------------------------------------------------------------
"

--6) Rodar o comando asmca para criar o disk group de RECO (lembrar de exportar as variaveis CV_ASSUME_DISTID e DISPLAY).
[grid@oraclelinux bin]$ cd /u01/app/19.0.0/grid/bin
[grid@oraclelinux bin]$ ./asmca

"ASM -> Disk Groups -> Create -> Disk Group Name: RECO -> Redundancy: External (only for this lab)  -> Select Disks 'RECO_ASM_1' -> Click OK"

--7) Instalar o Oracle Database 19c. Subir o Oracle Database 19c no servidor alterar o owner para oracle e descompactar o arquivo como oracle (com o usuario oracle).
[oracle@oraclelinux ~]$ cd /u01/app/oracle/product/19.0.0/dbhome_1/
[oracle@oraclelinux dbhome_1]$ chown oracle:oinstall /u01/app/oracle/product/19.0.0/dbhome_1/LINUX.X64_193000_db_home.zip
[oracle@oraclelinux dbhome_1]$ unzip -q /u01/app/oracle/product/19.0.0/dbhome_1/LINUX.X64_193000_db_home.zip



---8) Exportar as varíaveis de ambiente DISPLAY e CV_ASSUME_DISTID (com o usuario oracle).
[oracle@oraclelinux dbhome_1]$ export DISPLAY=<ip_do_servidor_local>:0.0
[oracle@oraclelinux dbhome_1]$ export CV_ASSUME_DISTID=OEL7


--9) Seguir os passos do assistente de instalação do Oracle Datbase 19c.
"Select Configuration Option -> Set up Software Only"
"Select Database Installation Option -> Single Instance Database Installation"
"Select Database Edition -> Enterprise Edition"
"Specify Installation Location -> Oracle base: /u01/app/oracle" 
"Privileged Operating System Groups -> OSDBA: dba | OSOPER: dba | OSBACKUPDBA: dba | OSDGDBA: dba | OSKMDBA: dba | OSRACDBA: dba"
"Root Script Execution -> Execute the scripts as root user"
"Perform Prerequisite Checks -> Ignore any warnings and continue"
"Install progress -> Install"
"Execute root scripts -> Execute the scripts as root user in another terminal"
"Completion of Oracle Database 19c Software Installation"



--10) Seguir os passos para criar o banco de dados Oracle Database 19c. com dbca (com o usuario oracle).
[oracle@oraclelinux dbhome_1]$ cd /u01/app/oracle/product/19.0.0/dbhome_1/bin
[oracle@oraclelinux bin]$ ./dbca
"Select Database Operation -> Create a Database"
"Select Database Creation Mode -> Advanced Configuration"
"Select Database Template -> General Purpose or Transaction Processing"
"Specify Database Identification -> Create as Container Database -> Global Database Name: orcl | SID: orcl | Create as a Container Database: Yes | Number of PDBs to create: 1 | PDB Name: pdb"
"Select Database Storage -> Use Automatic Storage Management (ASM) -> Disk Group: DATA"
"Select Fast Recovery Option -> Specify Fast Recovery Area: Automatic Storage Management (ASM) -> Disk Group: RECO | Enabling Archivelog Mode: Yes | Specify Fast Recovery Area Size: 5GB"
"Specify Network Configuration Details -> Listener: LISTENER -> next"
"Select Oracle Data Vault Config Option -> do nothing"
"Specify Configuration Options -> Memory: Use Automatic Memory Management (AMM) | SGA Target: XGB | PGA Aggregate Target: XMB | Sizing Process -> 300 | Character Sets: WE8MSWN1252 | National Character Set: AL16UTF16 | Default Language and Territory: American/United States | Connections Mode: Dedicated | Sample Schemas: Add Sample Schemas"
"Specify Management Options -> disable Enterprise Manager (EM) Express | Enable Enterprise Manager (EM) Database Express: No"
"Specify Database User Credentials -> Use the same administrative password for all accounts: Administrative Password: <senha> | Confirm Password: <senha>"
"Select Database Creation Options -> Create Database"
"Finish -> Database Creation in Progress"














