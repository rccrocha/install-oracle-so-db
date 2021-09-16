#!/usr/bin/env bash

###############
### AS ROOT ###
###############

# Basic groups for database management
echo -e "
#########################################################
### Creating the basic groups for database management ###
#########################################################
"
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper

echo 'Done creating basic groups!'

# Extra dedicated groups can be ignored for simple installations
echo -e "
#####################################################################################
### Creating extra dedicated groups. This can be ignored for simple installations ###
#####################################################################################
"
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba

echo 'Done creating extra dedicated groups!'

# Add user Oracle for database software
echo -e "
#############################################
### Add user Oracle for database software ###
#############################################
"
useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba oracle

# Checking Oracle's groups
echo -e "
#####################################
### # Checking user oracle groups ###
#####################################
"
groups oracle

# Change password for user Oracle
echo -e "
#########################################
### Changing password for user Oracle ###
#########################################
"
passwd oracle

# Basic packages to install
echo -e "
#################################
### Installing basic packages ###
#################################
"
yum install -y bc
yum install -y binutils
yum install -y compat-libcap1
yum install -y compat-libstdc++-33
yum install -y elfutils-libelf
yum install -y elfutils-libelf-devel
yum install -y fontconfig-devel
yum install -y glibc
yum install -y glibc-devel
yum install -y ksh
yum install -y libaio
yum install -y libaio-devel
yum install -y libdtrace-ctf-devel
yum install -y libXrender
yum install -y libXrender-devel
yum install -y libX11
yum install -y libXau
yum install -y libXi
yum install -y libXtst
yum install -y libgcc
yum install -y librdmacm-devel
yum install -y libstdc++
yum install -y libstdc++-devel
yum install -y libxcb
yum install -y make
yum install -y smartmontools
yum install -y sysstat
echo -e "
Installation of packages \e[1;32mDONE\e[0m!
"

# For Oracle RAC and Oracle Clusterware
echo -e "
##########################################################################################
### Installing basic packages for \e[1;35mOracle RAC, Oracle Clusterware, ACFS and ACFS Remote\e[0m ###
##########################################################################################
"
yum install -y net-tools
yum install -y nfs-utils
yum install -y python
yum install -y python-configshell
yum install -y python-rtslib
yum install -y python-six
yum install -y targetcli

# Ïnstalling Oracle Database pre-install
echo -e "
##############################################
### Installing \e[1;35mOracle Database pre-install\e[0m ###
##############################################
"
yum install -y https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm

# Add kernel parameters to /etc/sysctl.conf kernel parameters for 19C installation
echo -e "
########################################################################################
### Add kernel parameters to \e[1;35m/etc/sysctl.conf\e[0m kernel parameters for 19C installation ###
########################################################################################
"
cd /etc
echo -e "fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
fs.aio-max-nr = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.ip_local_port_range = 9000 65500" > /etc/sysctl.conf
echo -e "
Done adding kernel parameters to \e[1;35m/etc/sysctl.conf\e[0m
"

# Apply kernel parameters
echo -e "
###############################
### Apply kernel parameters ###
###############################
"
/sbin/sysctl -p

# Set shell limits for user oracle in file /etc/security/limits.conf
echo -e "
##########################################################################
### Set shell limits for user oracle in file \e[1;35m/etc/security/limits.conf\e[0m ###
##########################################################################
"
cd /etc/security
echo -e "oracle  soft  nofile  1024
oracle  hard  nofile  65536
oracle  soft  nproc  16384
oracle  hard  nproc  16384
oracle  soft  stack  10240
oracle  hard  stack  32768
oracle  soft  memlock 134217728
oracle  hard  memlock 134217728" > /etc/security/limits.conf

# Disabling Transparent Hugepages and defrag
# This step is recommended by Oracle to avoid later performance problems – Doc ID 1557478.1
# It can be done by adding transparent_hugepage=never to /etc/default/grub
echo -e "
###########################################################################################
# Disabling Transparent Hugepages and defrag
# This step is recommended by \e[1;31mORACLE\e[0m to avoid later performance problems – \e[1;35mDoc ID 1557478.1 \e[0m
# It can be done by adding \e[1;31mtransparent_hugepage=never\e[0m to \e[1;35m/etc/default/grub \e[0m
###########################################################################################
"

sed -i 's~^GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=ol/root rd.lvm.lv=ol/swap rhgb quiet".*$~GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=ol/root rd.lvm.lv=ol/swap rhgb quiet numa=off transparent_hugepage=never"~' /etc/default/grub

# Check grub with new parameter
echo -e "
#####################################
### Check grub with new parameter ###
#####################################
"
cat /etc/default/grub

echo -e "
##############################################
# Create the Oracle folders                  #
# \e[1;35mORACLE_BASE: /ora/wiki/app/oracle/base\e[0m    #
# ORACLE_HOME: /ora/wiki/app/oracle/base/oh\e[0m #
##############################################
"
mkdir -p /ora/django/app/oracle/base/oh
chown oracle:oinstall -R /ora
ls -la 

echo -e "
########################
### Disable firewall ###
########################
"
systemctl stop firewalld
systemctl disable firewalld
echo -e "Done disabling the firewall"

echo -e "
#########################################################################
### Add following lines in \e[1;35m/home/oracle/.bash_profile\e[0m for user oracle ###
#########################################################################
"
echo '# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

### Oracle Settings

export TMP=/tmp
export ORACLE_HOSTNAME=ol7-vm-1
export ORACLE_UNQNAME=OBLOGD
export ORACLE_BASE=/ora/django/app/oracle/base
export ORACLE_HOME=$ORACLE_BASE/oh
export ORACLE_SID=BLOGD

PATH=/usr/sbin:$PATH:$ORACLE_HOME/bin

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib;
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib;

umask 022

if [ $USER = "oracle" ]; then
    if [ $SHELL = "/bin/ksh" ]; then
       ulimit -u 16384
       ulimit -n 65536
    else
       ulimit -u 16384 -n 65536
    fi
fi' > /home/oracle/.bash_profile

cat /home/oracle/.bash_profile

echo

echo -e "
#####################################
# End of the part for the user root # 
#####################################
"

echo -e "
####################################
# Starting part of the \e[1;32moracle\e[0m user #
####################################
"

echo 'Copying LINUX.X64_193000_db_hme.zip to oracle folder'

cd /home/raphael
cp oracle_silent_install_oracle_args.sh /home/oracle/oracle_silent_install_oracle_args.sh
cp parameters.txt /home/oracle/parameters.txt
cp deploy_1.sh /home/oracle/deploy_1.sh
rsync -ah --progress LINUX.X64_193000_db_home.zip /home/oracle/linux_db.zip

chown -R oracle. /home/oracle
chmod +x /home/oracle/oracle_silent_install_oracle_args.sh
chmod +x /home/oracle/deploy_1.sh

echo -e "Checking for the scripts in oracle home"
echo
ls -la /home/oracle/
echo

sudo -u oracle -s /bin/sh -c "/home/oracle/deploy_1.sh"

echo
echo -e "Applying last 2 scripts as root"
echo

orainventory_scripts
./orainstRoot.sh
oracle_base_scripts
./root.sh
