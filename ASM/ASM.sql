============================================================
SCRIPT: Comandos ORACLEASM
============================================================
# Comando para iniciar o ORACLEASM (ele cria um diretorio chamado /dev/oracleasm/disks)
oracleasm init

# Comando para consultar o status e discover
oracleasm status
oracleasm-discover

# Criando os ALIAS ASM para as partições
oracleasm createdisk ASMDATA01 /dev/sdb1
oracleasm createdisk ARCH01 /dev/partition

# Comando para listar os alias ASM
oracleasm listdisks

============================================================
SCRIPT: Scripts para consultar informações de ASM disk e diskgroups
============================================================
set pagesize 200
set lines 200
set long 1000
col path for a50
col name for a10
col header_Status for a12
col read_mb for 99999.99
col write_mb for 99999.99
select name, path, header_status, total_mb, free_mb, trunc(bytes_read/1024/1024) read_mb, trunc(bytes_written/1024/1024)
write_mb from v$asm_disk;

============================================================
SCRIPT: Script para consultar o tamanho e o espaço livre em um ASM diskgroup
============================================================
col name for a10
col percentage 999.99
SELECT name, free_mb, total_mb, free_mb/total_mb*100 as percentage FROM v$asm_diskgroup;

============================================================
SCRIPT: Se conectar ao usuário grid e acessar o ASM
ORIGEM: Notion (ORACLE ASMCMD)
============================================================
su - grid
	
. oraenv
> +ASM1

============================================================
SCRIPT: Script shell para consultar o ASM, detalhes dos Diskgroups
ORIGEM: Notion (ORACLE ASMCMD)
============================================================
./asmdu_v3 
./asmdu_v3.sh -g
https://unknowndba.blogspot.com/2018/03/asmdush-far-better-du-for-asmcmd.html

#!/bin/bash
# Fred Denis -- June 2016 -- fred.denis3@gmail.com -- http://unknowndba.blogspot.com
# asmdu.sh - Shows a clear and nice summary of the ASM diskgroups used and free space (https://bit.ly/3c1pvfQ)
# Copyright (C) 2021 Fred Denis
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#
# More info and git repo: https://bit.ly/3c1pvfQ -- https://github.com/freddenis/oracle-scripts
#
# A note on the --nocp option
# Note that the --nocp asmcmd option (it disables the connection pooling) has been originaly implemented
# as a workaround of a bug that appeared with the April 2016 PSU
# It resolves error messages like this one :
# sh: -c: line 0: unexpected EOF while looking for matching `''
# sh: -c: line 1: syntax error: unexpected end of file
#
#
# The current version of the script is 20211111
#
# 20211111 - Fred Denis - GPLv3 licence
# 20211018 - Fred Denis - Cosmetic, indentation, protect and quote, $() instead of ``
#                         Use of olr.loc instead of oraenv if possible
# 20190906 - Fred Denis - A new -V option to show the version of the script
# 20190219 - Fred Denis - Some had issues with the instance list, I then moved from sed to cut to fix it -- Thanks Jakub !
# 20181218 - Fred Denis - A new -n option to print with no color -- DEFAULT_NOCOLOR can be used to modify the default behavior
#                         Fixed the regexp to list the instances running
# 20180827 - Fred Denis - A better regexp to list the instances running
# 20180503 - Fred Denis - GI 12c introduces a "Logical_Sector" column, took this into account (Thanks Leon !)
# 20180327 - Fred Denis - "Raw Used " label for the subdirectories "Mirror_used_MB" column, adjustments in the help
# 20180318 - Fred Denis - Shows only mirrored sizes by default and the total non mirrored size only shown with the -v option
# 20180211 - Fred Denis -  Many improvements :
#                       - -d options to list the subdirectories of a directory
#                       - -v option to show the Raw Free and Reserverd size
#                       - -m -g and -t to choose the Unit you want the report to be in
#                       - Default values and verbosity can be changed using the DEFAULT_UNIT and the DEFAULT_VERBOSE variables
#                       - A nice usage function
# 20170719 - Fred Denis - Remove the --nocp option as default
#
#
# Default values (when no option is specified in the command line)
# The last uncommented value wins
#
   DEFAULT_UNIT="MB"                     # asmcmd default
   DEFAULT_UNIT="GB"
   DEFAULT_UNIT="TB"
DEFAULT_VERBOSE="Yes"
DEFAULT_VERBOSE="No"
DEFAULT_NOCOLOR="Yes"                    # Print with no color
DEFAULT_NOCOLOR="No"                     # Print with colors
       CRITICAL=90                       # Colored thresholds (Red, Yellow, Green)
        WARNING=75                       # Colored thresholds (Red, Yellow, Green)
          WHITE="\033[1;37m"
      END_COLOR="\033[m"
            OLR="/etc/oracle/olr.loc"    # olr.loc file to get crs home if oratab does not have ASM entry

#
# Show the version of the script (-V)
#
show_version() {
    VERSION=$(awk '{if ($0 ~ /^# 20[0-9][0-9][0-1][0-9]/) {print $2; exit}}' $0)
    printf "\n\t\033[1;36m%s\033[m\n" "The current version of "`basename $0`" is "$VERSION"."          ;
}
#
# An usage function
#
usage() {
printf "\n\033[1;37m%-8s\033[m\n" "NAME"                ;
cat << END
    asmdu.sh - Shows a clear and nice summary of the ASM diskgroups used and free space (https://bit.ly/3c1pvfQ)
END

printf "\n\033[1;37m%-8s\033[m\n" "SYNOPSIS"            ;
cat << END
    $0 [-d] [-m -g -t] [-n] [-v] [-V] [-h]
END

printf "\n\033[1;37m%-8s\033[m\n" "DESCRIPTION"         ;
cat << END
    $0 needs to be executed as the GI owner user to be able to use asmcmd
    With no option $0 will be showing what instances are running and a size summary for each DiskGroup
END

printf "\n\033[1;37m%-8s\033[m\n" "OPTIONS"             ;
cat << END
    -d        The directory you want the size details

    -v        Verbose -- show the "Total Raw", "Raw Free" and "Reserved" size
              You can change the default behavior with the DEFAULT_VERBOSE variable

    -m        Shows the output in MB
    -g        Shows the output in GB
    -t        Shows the output in TB
    -m -g -t  The default Unit can be specified using the DEFAULT_UNIT variable
              If more than one of these options is specified, the last one wins

    -n        Shows the output with no color (handy to send it by email)

    -V        Shows the version of the script
    -h        Shows this help

END
exit 123
}
#
# Parameters management
#
    PARAM_UNIT=""
 PARAM_VERBOSE=""
#
while getopts "d:mgtnvhV" OPT; do
    case ${OPT} in
    d)                  D=${OPTARG}                         ;;
    m)         PARAM_UNIT="MB"                              ;;
    g)         PARAM_UNIT="GB"                              ;;
    t)         PARAM_UNIT="TB"                              ;;
    n)      PARAM_NOCOLOR="Yes"                             ;;
    v)      PARAM_VERBOSE="Yes"                             ;;
    V)      show_version; exit 567                          ;;
    h)      usage                                           ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage          ;;
    esac
done
#
if [[ -z "${PARAM_UNIT}" ]]; then                           # No parameter specified, we use the default
    UNIT="${DEFAULT_UNIT}"
else
    UNIT="${PARAM_UNIT}"
fi
if [[ -z "${PARAM_VERBOSE}" ]]; then                        # No parameter specified, we use the default
        VERBOSE="${DEFAULT_VERBOSE}"
else
        VERBOSE="${PARAM_VERBOSE}"
fi
if [[ -z "${PARAM_NOCOLOR}" ]]; then                        # No parameter specified, we use the default
        NOCOLOR="${DEFAULT_NOCOLOR}"
else
        NOCOLOR="${PARAM_NOCOLOR}"
fi
if [[ "${NOCOLOR}" == "Yes" ]]; then
          WHITE=""
      END_COLOR=""
fi
#
# Set the ASM env
#
if [[ -f "${OLR}" ]]; then
    export ORACLE_HOME=$(cat "${OLR}" | grep "^crs_home" | awk -F "=" '{print $2}')
    export ORACLE_BASE=$(${ORACLE_HOME}/bin/orabase)
    export        PATH="${PATH}:${ORACLE_HOME}/bin"
else
    ORACLE_SID=$(ps -ef | grep pmon | grep asm | awk '{print $NF}' | sed s'/asm_pmon_//' | egrep "^[+]")
    export ORAENV_ASK=NO
    . oraenv > /dev/null 2>&1
fi
#
# A quick list of the instances that are running on the server
#
ps -ef | grep pmon | grep -v grep | awk '{print $NF}' | cut -d_ -f3,4 | sort | awk -v H="`hostname -s`" 'BEGIN {printf("\n%s", "Instances running on " H " : ")} { printf("%s, ", $0)} END{printf("\n")}' | sed s'/, $//'
#
# Manage parameters
#
if [[ -z "${D}" ]]; then                                    # No directory provided, will check all the DG
        DG=$(asmcmd lsdg | grep -v State | awk '{print $NF}' | sed s'/\///')
    SUBDIR="No"                                             # Do not show the subdirectories details if no directory is specified
else
        DG=$(echo $D | sed s'/\/.*$//g')
fi
#
# A header
#
printf "\n%25s%16s${WHITE}%16s${END_COLOR}"   "DiskGroup" "Redundancy" "Total ${UNIT}"  # "Raw Free ${UNIT}" "Reserved ${UNIT}"  "Usable ${UNIT}" "% Free"
if [[ "${VERBOSE}" == "Yes" ]]; then
    printf "%16s%16s%16s" "Raw Total ${UNIT}" "Raw Free ${UNIT}" "Reserved ${UNIT}"
fi
printf "${WHITE}%16s%14s${END_COLOR}\n" "Usable ${UNIT}" "% Free"

printf "%25s%16s${WHITE}%16s${END_COLOR}"   "---------"     "-----------" "--------"
if [[ "${VERBOSE}" == "Yes" ]]; then
    printf "%16s%16s%16s"           "------------"  "-----------" "-----------"
fi
printf "${WHITE}%16s${END_COLOR}%14s\n"     "---------"     "------"
#
# Show DG info
#
for X in ${DG}; do
    asmcmd lsdg "${X}" | tail -1 |\
    awk -v DG="$X" -v W="$WARNING" -v C="$CRITICAL" -v UNIT="$UNIT" -v VERBOSE="$VERBOSE" -v NOCOLOR="$NOCOLOR" '\
    BEGIN \
    {   if (NOCOLOR == "Yes") {
            COLOR_BEGIN =           ""                                  ;
              COLOR_END =           ""                                  ;
                    RED =           ""                                  ;
                  GREEN =           ""                                  ;
                 YELLOW =           ""                                  ;
                  WHITE =           ""                                  ;
                  COLOR =           ""                                  ;
        } else {
            COLOR_BEGIN =           "\033[1;"                           ;
              COLOR_END =           "\033[m"                            ;
                    RED =           COLOR_BEGIN"31m"                    ;
                  GREEN =           COLOR_BEGIN"32m"                    ;
                 YELLOW =           COLOR_BEGIN"33m"                    ;
                  WHITE =           COLOR_BEGIN"37m"                    ;
                  COLOR =           GREEN                               ;
        }
        DIVIDER = 1                                                     ;       # Unit divider
        RED_DIV = 1                                                     ;       # Redundancy divider

        if (UNIT == "GB")       { DIVIDER="1024"   }                    ;
        if (UNIT == "TB")       { DIVIDER="1048576"}                    ;       # 1024 * 1024
    }
    {   if ($2 == "HIGH")           {RED_DIV=3                          ;}      # Redundancy divider
        if ($2 == "NORMAL")         {RED_DIV=2                          ;}      # Redundancy divider

         TOTAL = sprintf("%16.2f", $(NF-6)/DIVIDER/RED_DIV)             ;       # Total mirrored in Unit
        USABLE = sprintf("%16.2f", $(NF-3)/DIVIDER)                     ;       # Usable space in Unit
          FREE = sprintf("%12d"  , USABLE/TOTAL*100)                    ;       # % Free calculated using the Usable size

        if ((100-FREE) > W)     { COLOR=YELLOW                          ;}      # Colored %Free thresholds
        if ((100-FREE) > C)     { COLOR=RED                             ;}      # Colored %Free thresholds

        printf("%25s%16s%16s", DG, $2, WHITE TOTAL COLOR_END)           ;       # DG Redundancy and Total

        if (VERBOSE == "Yes") {
            printf("%16.2f%16.2f%16.2f", $(NF-6)/DIVIDER, $(NF-5)/DIVIDER, $(NF-4)/DIVIDER);       # Total Raw, Raw Free and reserved if Verbose
        }
        printf("%16s%14s\n", WHITE USABLE COLOR_END, COLOR FREE COLOR_END)  ;       # Usable and Free %
    }'
done
printf "\n"
#
# Subdirs info
#
if [[ -z "${SUBDIR}" ]]; then
(for DIR in $(asmcmd ls "${D}"); do
            echo "${DIR}" $(asmcmd --nocp du "${D}/${DIR}" | tail -1)      # Please look at the "About the --nocp option" notes in the header for more information
#            echo ${DIR} `asmcmd du ${D}/${DIR} | tail -1`
done) | awk -v D="${D}" -v UNIT="${UNIT}"\
    ' BEGIN {      printf("\n\t\t%40s\n\n", D " subdirectories size")                      ;
                   printf("%25s%16s%16s\n", "Subdir", "Used " UNIT, "Raw Used " UNIT)      ;
                   printf("%25s%16s%16s\n", "------", "-------", "-----------")            ;

                   DIVIDER=1                                                               ;
                   if (UNIT == "GB")       { DIVIDER="1024"        }                       ;
                   if (UNIT == "TB")       { DIVIDER="1048576"     }                       ;   # 1024 * 1024
            }
            {
                   use=sprintf("%16.2f", $2/DIVIDER)                                       ;
                   mir=sprintf("%16.2f", $3/DIVIDER)                                       ;

                   printf("%25s%16s%16s\n", $1, use, mir)                                  ;

                   total_use += $2                                                         ;
                   total_mir += $3                                                         ;
            }
     END    {      total_use = sprintf("%16.2f", total_use/DIVIDER)                        ;
                   total_mir = sprintf("%16.2f", total_mir/DIVIDER)                        ;
                   printf("\n\n%25s%16s%16s\n", "------", "-------", "---------")          ;
                   printf("%25s%16s%16s\n\n", "Total", total_use, total_mir)               ;
             } '
fi
#
# For information
#
if [[ "${VERBOSE}" == "Yes" ]]; then
    printf "\t\t%40s\n\n" "Note : Usable = (Raw Free - Reserved)/Redundancy"                ;
fi
#****************************************************************************************#
#*                          E N D          O F          S O U R C E                     *#
#****************************************************************************************#

============================================================
SCRIPT: Listar todos os DiskGroups
ORIGEM: Notion (ORACLE ASMCMD)
============================================================
ASMCMD> lsdg

# Include dismounted diskgroups
ASMCMD> lsdg --discovery

# List diskgroups across all nodes of cluster
ASMCMD> lsdg -g --discovery

============================================================
SCRIPT: Listar os discos do ASM
ORIGEM: Notion (ORACLE ASMCMD)
============================================================
--List all asm disks
ASMCMD> lsdsk -k

--List disks of a Diskgroup <Diskgroup_name> with free and total mb
ASMCMD> lsdsk -k -g <Diskgroup_name>

--List disks of a diskgroup <diskgroup_name> with group and disk number
ASMCMD> lsdsk -p -G <diskgroup_name>

--List disks with disk creation data
ASMCMD> lsdsk -t -G <diskgroup_name>

--List candidate disk only
ASMCMD> lsdsk --candidate -k

--List member disks only
ASMCMD> lsdsk --candidate -p

============================================================
SCRIPT: pegar os atributos de um ASM Diskgroup
ORIGEM: Notion (ORACLE ASMCMD)
============================================================
-- List attribute of all diskgroups
ASMCMD> lsattr - lm

-- List attribute of specific diskgroup <diskgroup_name>
ASMCMD> lsattr -lm -G <diskgroup_name>

-- List attributes with specific pattern

ASMCMD> lsattr -lm %au_size%

============================================================
SCRIPT: Comandos para montar e desmontar um diskgroup
ORIGEM: Notion (ORACLE ASMCMD)
============================================================
# Mount command works only on the local node. So if you want to Mount the diskgroup from all nodes of cluster, then run this command from all the nodes.

-- mount all diskgroups on local node
ASMCMD> mount -a

-- mount a specific diskgroup on local node
ASMCMD> mount <diskgroup>

# Unmount command works only on the local node. So if you want to unmount the diskgroup from all nodes of cluster, then run this command from all the nodes.

-- unmount all diskgroups
ASMCMD> umount -a

-- unmount specific diskgroup <diskgroup_names>
ASMCMD> umount <diskgroup_name>

============================================================
SCRIPT: 7) Download e instalação do ASMLIB
============================================================
# realizar o download dos arquivos no diretorio TEMP
# Rodar o comando abaixo para download do wget caso não esteja instalado.
[root@oracle tmp]# yum install -y wget.x86_64

#download dos pacotes asmlib e install local
wget https://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.17-1.el8.x86_64.rpm
  wget https://public-yum.oracle.com/repo/OracleLinux/OL8/addons/x86_64/getPackage/oracleasm-support-2.1.12-1.el8.x86_64.rpm
  yum -y localinstall ./oracleasm-support-2.1.12-1.el8.x86_64.rpm ./oracleasmlib-2.0.17-1.el8.x86_64.rpm
  
 [root@oraclegridapex ~]# rpm -qa | grep -i oracleasm

============================================================
SCRIPT: 8) Nessa etapa, vamos realizar a configuração do ASMLIB
============================================================
[root@oracle tmp]# oracleasm configure -i
Configuring the Oracle ASM library driver.

This will configure the on-boot properties of the Oracle ASM library
driver.  The following questions will determine whether the driver is
loaded on boot and what permissions it will have.  The current values
will be shown in brackets ('[]').  Hitting <ENTER> without typing an
answer will keep that current value.  Ctrl-C will abort.

Default user to own the driver interface []: grid
Default group to own the driver interface []: dba
Start Oracle ASM library driver on boot (y/n) [n]: Y
Scan for Oracle ASM disks on boot (y/n) [y]: Y
Writing Oracle ASM library driver configuration: done

============================================================
SCRIPT: 9) Seguir o passo abaixo para iniciar o ORACLEASM
============================================================
[root@oracle tmp]# oracleasm init
Creating /dev/oracleasm moRunt point: /dev/oracleasm
Loading module "oracleasm": oracleasm
Configuring "oracleasm" to use device physical block size
Mounting ASMlib driver filesystem: /dev/oracleasm

--https://www.br8dba.com/configure-asmlib-for-oracle-asm/
--obs CASO APRESENTE ERRO DE:
--Loading module "oracleasm": failed
--Unable to load module "oracleasm"
--Mounting ASMlib driver filesystem: failed
--Unable to mount ASMlib driver filesystem

-- Seguir o seguinte passo abaixo (OBS - PEGAR SEMPRE O SEGUNDO VMLINUX)

[root@oraclec1 ~]# yum search oracleasm
Last metadata expiration check: 0:21:05 ago on Sun 06 Oct 2024 11:24:01 AM -03.
===================================================================================================== Name & Summary Matched: oracleasm ======================================================================================================
kmod-redhat-oracleasm.src : oracleasm kernel module
kmod-redhat-oracleasm.x86_64 : oracleasm kernel module
kmod-redhat-oracleasm-kernel_4_18_0_240.x86_64 : oracleasm kernel module for kernel version 4.18.0-240.el8..4.18.0-240.14.1.el8_3
kmod-redhat-oracleasm-kernel_4_18_0_240_14_1.x86_64 : oracleasm kernel module for kernel version 4.18.0-240.14.1.el8_3 and higher
kmod-redhat-oracleasm-kernel_4_18_0_425_10_1.x86_64 : oracleasm kernel module for kernel version 4.18.0-425.10.1.el8_7 and higher
kmod-redhat-oracleasm-kernel_4_18_0_425_3_1.x86_64 : oracleasm kernel module for kernel version 4.18.0-425.3.1.el8..4.18.0-425.10.1.el8_7

yum install -y kmod-redhat-oracleasm-kernel_4_18_0_240.x86_64

[root@oraclegridapex ~]# ls -l /boot/vmlinuz-*
[root@oraclegridapex ~]# grubby --set-default /boot/vmlinuz-4.18.0-513.24.1.el8_9.x86_64
[root@oraclegridapex ~]# shutdown -Fr now

#comandos para consultar o status e discover
[root@oracle tmp]# oracleasm status
Checking if ASM is loaded: yes
Checking if /dev/oracleasm is mounted: yes

[root@oracle tmp]# oracleasm-discover
Using ASMLib from /opt/oracle/extapi/64/asm/orcl/1/libasm.so
[ASM Library - Generic Linux, version 2.0.17 (KABI_V2)]

============================================================
SCRIPT: 10) nessa etapa sera configurado os discos para o ASM (fdisk)
============================================================
#comando para consultar os discos
lsblk

# passo a passo para formatar as partições dos novos discos

[root@oracle ~]# fdisk /dev/sdb

Welcome to fdisk (util-linux 2.32.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0xac50694c.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-10485759, default 2048):
Last sector, +sectors or +size{K,M,G,T,P} (2048-10485759, default 10485759):

Created a new partition 1 of type 'Linux' and of size 5 GiB.

Command (m for help): x

Expert command (m for help): b
Selected partition 1
New beginning of data (1-10485759, default 2048): 1

Expert command (m for help): r

Command (m for help): w

The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks

#os valores setados foram
 fdisk /dev/sdc
> n
> p
> 1
> ENTER
> ENTER

*EXPERT MODE
> x
> b
> 1
> r
> w

============================================================
SCRIPT: 11) Criar a camada de abstração ASM (ALIAS as partições em /dev/oracleasm/disks)
============================================================
[root@oracle ~]# oracleasm createdisk ASMDATA01 /dev/sdb1
Writing disk header: done
Instantiating disk: done
[root@oracle ~]# oracleasm createdisk ASMDATA02 /dev/sdc1
Writing disk header: done
Instantiating disk: done
[root@oracle ~]# oracleasm createdisk ASMDATA03 /dev/sdd1
Writing disk header: done
Instantiating disk: done
[root@oracle ~]# oracleasm createdisk ASMDATA04 /dev/sde1
Writing disk header: done
Instantiating disk: done
[root@oracle ~]# oracleasm createdisk ARCH01 /dev/sdf1
Writing disk header: done
Instantiating disk: done
[root@oracle ~]# oracleasm createdisk ARCH02 /dev/sdg1
Writing disk header: done
Instantiating disk: done

#comandos para listar os discos do ASM
[root@oracle ~]# oracleasm listdisks
ARCH01
ARCH02
ASMDATA01
ASMDATA02
ASMDATA03
ASMDATA04

============================================================
SCRIPT: 14) Verificar diskgroup DATA criado, status do listener e status/start/stop do GRID via crsctl
============================================================
# setar o ORAENV com o SID do ORACLE ASMA e rodar o comando asmcmd para acessar o terminal
# e listar o diskgroup DATA montado
[grid@oracle grid]$ . oraenv
ORACLE_SID = [grid] ? +ASM
The Oracle base has been set to /u01/app/grid
[grid@oracle grid]$ asmcmd -p
ASMCMD [+] > ls
DATA/
ASMCMD [+] >

# PODEMOS VER TBM QUE O LISTENER JA ESTÁ STARTADO, POR ESTARMOS USANDO O GRID
# O LISTENER É CONFIGURADO PARA STARTAR E PARAR JUNTO COM O GRID
[grid@oracle grid]$ lsnrctl status

LSNRCTL for Linux: Version 21.0.0.0.0 - Production on 11-JUN-2023 21:00:36

Copyright (c) 1991, 2021, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oracle)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 21.0.0.0.0 - Production
Start Date                11-JUN-2023 20:55:16
Uptime                    0 days 0 hr. 5 min. 20 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /u01/app/21.0.0.0/grid/network/admin/listener.ora
Listener Log File         /u01/app/grid/diag/tnslsnr/oracle/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oracle)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
Services Summary...
Service "+ASM" has 1 instance(s).
  Instance "+ASM", status READY, has 1 handler(s) for this service...
Service "+ASM_DATA" has 1 instance(s).
  Instance "+ASM", status READY, has 1 handler(s) for this service...
The command completed successfully

# Comandos para STATUS - STOP (SOMENTE COM O USER ROOT) e START (SOMENTE COM O USER ROOT) o GRID
[grid@oracle grid]$ /u01/app/21.0.0.0/grid/bin/crsctl stat res -t
--------------------------------------------------------------------------------
Name           Target  State        Server                   State details
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.DATA.dg
               ONLINE  ONLINE       oracle                   STABLE
ora.LISTENER.lsnr
               ONLINE  ONLINE       oracle                   STABLE
ora.asm
               ONLINE  ONLINE       oracle                   Started,STABLE
ora.ons
               OFFLINE OFFLINE      oracle                   STABLE
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.cssd
      1        ONLINE  ONLINE       oracle                   STABLE
ora.diskmon
      1        OFFLINE OFFLINE                               STABLE
ora.evmd
      1        ONLINE  ONLINE       oracle                   STABLE
--------------------------------------------------------------------------------

[root@oracle ~]# /u01/app/21.0.0.0/grid/bin/crsctl stop has
CRS-2791: Starting shutdown of Oracle High Availability Services-managed resources on 'oracle'
CRS-2673: Attempting to stop 'ora.DATA.dg' on 'oracle'
CRS-2673: Attempting to stop 'ora.LISTENER.lsnr' on 'oracle'
CRS-2677: Stop of 'ora.DATA.dg' on 'oracle' succeeded
CRS-2673: Attempting to stop 'ora.asm' on 'oracle'
CRS-2677: Stop of 'ora.LISTENER.lsnr' on 'oracle' succeeded
CRS-2677: Stop of 'ora.asm' on 'oracle' succeeded
CRS-2673: Attempting to stop 'ora.evmd' on 'oracle'
CRS-2677: Stop of 'ora.evmd' on 'oracle' succeeded
CRS-2673: Attempting to stop 'ora.cssd' on 'oracle'
CRS-2677: Stop of 'ora.cssd' on 'oracle' succeeded
CRS-2793: Shutdown of Oracle High Availability Services-managed resources on 'oracle' has completed
CRS-4133: Oracle High Availability Services has been stopped.

[root@oracle ~]# /u01/app/21.0.0.0/grid/bin/crsctl start has
CRS-4123: Oracle High Availability Services has been started

============================================================
SCRIPT: 15) Criar o diskgroup ARCH usando o ASMCA (ASM Configuration Assistant)
============================================================
# Com o user grid logado, lembrar de rodar os exports
[grid@oracle ~]$ export CV_ASSUME_DISTID='OL7'
[grid@oracle ~]$ export DISPLAY=192.168.100.2:0.0
[grid@oracle ~]$ /u01/app/21.0.0.0/grid/bin/asmca

============================================================
SCRIPT: Consultar o novo diskgroup ARCH criado via asmcmd
============================================================
[grid@oracle ~]$ . oraenv
ORACLE_SID = [grid] ? +ASM
The Oracle base has been set to /u01/app/grid
[grid@oracle ~]$ asmcmd -p
ASMCMD [+] > ls
ARCH/
DATA/
ASMCMD [+] >

============================================================
SCRIPT: Utilitario ASMCA (ASM Configuration Assistant
============================================================

