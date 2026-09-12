/*
Author: Thiago Batista Barbosa Ribeiro
Date: 2026-09-12 
Version: Alfa
Objective: Script de instalação do Oracle Database 19c em um servidor Oracle Linux 8+ single instance com ASM.
Link de apoio: https://en.data4tech.com/post/oracle-grid-infrastructure-19c-and-oracle-database-19c-single-instance-installation-on-oracle-linux
*/

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
SELINUX=disable
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
*/


--Adicionar uma entrada no arquivo hosts
vi /etc/hosts
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

--Criacao do usuario grid.
[root@oraclelinux ~]# useradd -g asmadmin -G asmdba,asmoper,dba 

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





