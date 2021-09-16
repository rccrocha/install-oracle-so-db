######################
### AS ORACLE USER ###
######################

echo -e "
###########################################################################
### Checking if transparent_hugepage changed to: \e[1;35malways madvise [never]\e[0m ###
###########################################################################
"
cat /sys/kernel/mm/transparent_hugepage/enabled

echo -e "
Starting \e[1;31mOracle \e[0muser part.
"
cd /home/oracle
source .bash_profile




touch /etc/oratab

echo
echo -e "\e[0m
############################################################
Unzip binaries to oracle home (\e[1;35m$ORACLE_HOME\e[0m)
############################################################
"
if [[ -f $ORACLE_HOME/linux_db.zip ]]
then
    echo "File already exists"
else
    cp linux_db.zip $ORACLE_HOME/
    cd $ORACLE_HOME
    unzip linux_db.zip
    ls -la
    echo
fi

echo -e "\e[0m
##############################################################
Install \e[1;31mOracle\e[0m binaries
Backup original response file \e[1;35mdb_install.rsp\e[0m before editing it
##############################################################
"
cp $ORACLE_HOME/install/response/db_install.rsp $ORACLE_HOME/install/response/db_install.rsp.bck

echo -e "
Copy done!
"

echo -e "\e[0m
#######################################################################
Edit file\e[1;35m db_install.rsp\e[0m to set parameters required to install binaries
#######################################################################
"
cd $ORACLE_HOME/install/response/
sed -i "s/^oracle.install.option=.*$/oracle.install.option=$oracle_install_option/" db_install.rsp
sed -i "s/^UNIX_GROUP_NAME=.*$/UNIX_GROUP_NAME=$UNIX_GROUP_NAME/" db_install.rsp
sed -i "s~^INVENTORY_LOCATION=.*$~INVENTORY_LOCATION=$INVENTORY_LOCATION~" db_install.rsp
sed -i "s~^ORACLE_HOME=.*$~ORACLE_HOME=$O_HOME~" db_install.rsp
sed -i "s~^ORACLE_BASE=.*$~ORACLE_BASE=$O_BASE~" db_install.rsp
sed -i "s/^oracle.install.db.InstallEdition=.*$/oracle.install.db.InstallEdition=$InstallEdition/" db_install.rsp
sed -i "s/^oracle.install.db.OSDBA_GROUP=.*$/oracle.install.db.OSDBA_GROUP=$OSDBA_GROUP/" db_install.rsp
sed -i "s/^oracle.install.db.OSOPER_GROUP=.*$/oracle.install.db.OSOPER_GROUP=$OSOPER_GROUP/" db_install.rsp
sed -i "s/^oracle.install.db.OSBACKUPDBA_GROUP=.*$/oracle.install.db.OSBACKUPDBA_GROUP=$OSBACKUPDBA_GROUP/" db_install.rsp
sed -i "s/^oracle.install.db.OSDGDBA_GROUP=.*$/oracle.install.db.OSDGDBA_GROUP=$OSDGDBA_GROUP/" db_install.rsp
sed -i "s/^oracle.install.db.OSKMDBA_GROUP=.*$/oracle.install.db.OSKMDBA_GROUP=$OSKMDBA_GROUP/" db_install.rsp
sed -i "s/^oracle.install.db.OSRACDBA_GROUP=.*$/oracle.install.db.OSRACDBA_GROUP=$OSRACDBA_GROUP/" db_install.rsp

echo -e "
Editing done!
"

echo -e "\e[0m
###########################
Start \e[1;35mbinaries\e[0m installation
###########################
"
cd $ORACLE_HOME
./runInstaller -silent \ -responseFile $ORACLE_HOME/install/response/db_install.rsp

echo -e "
Binaries installation done!
"

echo -e "\e[0m
##############################################################
Quick binaries check with Sql*Plus - Connection should be idle
##############################################################
"
sqlplus / as sysdba << EOF
exit;
EOF

echo -e "\e[0m
###############################
Backup and Configure \e[1;35mOracle Net\e[0m
###############################
"
cp $ORACLE_HOME/assistants/netca/netca.rsp $ORACLE_HOME/assistants/netca/netca.rsp.bck

echo -e "
Backup done!
"

echo -e "\e[0m
######################################
Applying standard config to\e[1;35m Oracle Net\e[0m
######################################
"
cd $ORACLE_HOME/assistants/netca/
sed -i "s/^LISTENER_NAMES={"LISTENER"}.*$/LISTENER_NAMES={"LISTENER_$DATABASE"}/" netca.rsp
sed -i "s/^LISTENER_START=""LISTENER"".*$/LISTENER_START=""LISTENER_$DATABASE""/" netca.rsp
netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp

echo -e "
Standard config applied!
"

echo -e "\e[0m
######################################
Applying standard config to\e[1;35m Oracle Net\e[0m
######################################
"
cd $ORACLE_HOME/network/admin
FQDN=$(cat /etc/hostname)
echo "# Listeners

LISTENER_$DATABASE =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = $FQDN)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
" > listener.ora
lsnrctl start LISTENER_$DATABASE

echo -e "
################################################################################################################
Configure database
Create new container database\e[1;35m $DATABASE \e[0mwith one pluggable database \e[1;35mPG$DATABASE\e[0m, configure and enable \e[1;35mOracle DB Express\e[0m
################################################################################################################
"
mkdir -p $O_BASE/oradata
mkdir -p $O_BASE/flash_recovery_area

echo -e "
Backing up original response file for DBCA
"
cp $ORACLE_HOME/assistants/dbca/dbca.rsp $ORACLE_HOME/assistants/dbca/dbca.rsp.bck

echo -e "
Backup done!
"
cd $ORACLE_HOME/assistants/dbca
sed -i "s/^gdbName=.*$/gdbName=$gdbName/" dbca.rsp
sed -i "s/^sid=.*$/sid=$DATABASE/" dbca.rsp
sed -i "s/^createAsContainerDatabase=.*$/createAsContainerDatabase=$createAsContainerDatabase/" dbca.rsp
sed -i "s/^numberOfPDBs=.*$/numberOfPDBs=$numberOfPDBs/" dbca.rsp
sed -i "s/^pdbName=.*$/pdbName=PG$DATABASE/" dbca.rsp
sed -i "s/^useLocalUndoForPDBs=.*$/useLocalUndoForPDBs=$useLocalUndoForPDBs/" dbca.rsp
sed -i "s/^pdbAdminPassword=.*$/pdbAdminPassword=$pdbAdminPassword/" dbca.rsp
sed -i "s/^templateName=.*$/templateName=$templateName/" dbca.rsp
sed -i "s/^sysPassword=.*$/sysPassword=$sysPassword/" dbca.rsp
sed -i "s/^systemPassword=.*$/systemPassword=$systemPassword/" dbca.rsp
sed -i "s/^emConfiguration=.*$/emConfiguration=$emConfiguration/" dbca.rsp
sed -i "s/^emExpressPort=.*$/emExpressPort=$emExpressPort/" dbca.rsp
sed -i "s/^dbsnmpPassword=.*$/dbsnmpPassword=$dbsnmpPassword/" dbca.rsp
sed -i "s~^datafileDestination=.*$~datafileDestination=$datafileDestination~" dbca.rsp
sed -i "s~^recoveryAreaDestination=.*$~recoveryAreaDestination=$recoveryAreaDestination~" dbca.rsp
sed -i "s/^storageType=.*$/storageType=$storageType/" dbca.rsp
sed -i "s/^characterSet=.*$/characterSet=$characterSet/" dbca.rsp
sed -i "s/^nationalCharacterSet=.*$/nationalCharacterSet=$nationalCharacterSet/" dbca.rsp
sed -i "s/^listeners=.*$/listeners=LISTENER_$DATABASE/" dbca.rsp
sed -i "s/^sampleSchema=.*$/sampleSchema=$sampleSchema/" dbca.rsp
sed -i "s/^databaseType=.*$/databaseType=$databaseType/" dbca.rsp
sed -i "s/^totalMemory=.*$/totalMemory=$totalMemory/" dbca.rsp

echo -e "
Editing done!
"

echo -e "\e[0m
###########################
Start database installation
###########################
"
cd $ORACLE_HOME/assistants/dbca/
dbca -silent -createDatabase -responseFile $ORACLE_HOME/assistants/dbca/dbca.rsp

echo -e "
Installation done!
Now, check if it went well by executing sqlplus / as sysdba"
sqlplus / as sysdba << EOF
show parameter db_name;
exit;
EOF
