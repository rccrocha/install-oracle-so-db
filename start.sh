#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo
   echo "Silent install of Oracle binaries and creation of a database."
   echo
   echo "You also need to create a parameters.txt file with all the db_install.rsp"
   echo "and dbca.rsp values in case you do not want to add the values in runtime."
   echo
   echo "Syntax: scriptTemplate [-h|-s|-b|-d|-i]"
   echo
   echo "options:"
   echo "h     Print this Help."
   echo "s     Add the hostname."
   echo "b     Add Oracle Base absolute path."
   echo "d     Add Oracle SID."
   echo "i     Add Inventory path."
   echo
}

STARTTIME=$(date +%H%M%S)

echo "
System requirements check
_________________________
"

echo "- 1st check - Oracle Database 19c Binaries -
"

if [[ -f /home/$USER/LINUX.X64_193000_db_home.zip ]]
then
    echo -e "\e[1;32mOracle 19c Binaries File exists!\e[0m
"
else
    echo -e "\e[1;31mFailed!\e[0m You need to download the binaries before proceeding. You can find it at
https://www.oracle.com/database/technologies/oracle-database-software-downloads.html
"
    exit 1
fi

echo "- 2nd check - System Hardware -"

MEM=$(free -h | grep Mem | awk -F ":" '{print $2}' | awk -F "G" '{print $1}' | sed -e 's/^[[:space:]]*//')
SR=$(df -h . | grep / | awk -F "G" '{print $3}' | sed -e 's/^[[:space:]]*//')

echo -e "
Requirement  Minimum  Available  Status
-----------  -------  ---------  -------"

if (( $(bc <<<"$SR > 10") )); then
    printf "Disk Space   10 G     $SR G      \e[1;32m Passed \e[0m \n"
else
    printf "Disk Space   10 G     $SR G      \e[1;31m Failed \e[0m \n"
    exit 1
fi

if (( $(bc <<<"$MEM > 2") )); then
    printf "Memory RAM   2 G      $MEM G     \e[1;32m Passed \e[0m \n"
else
    printf "Memory RAM   2 G      $MEM G     \e[1;31m Failed \e[0m \n"
    exit 1
fi

while true; do

    echo "Please enter your choice:
"
    echo "1 - Using a pre-filled text file for the parameters"
    echo "2 - Adding manually each parameter"
    echo "3 - Quit"
    echo

    read n
    
    case $n in
        1)
            echo "You chose to use the file to fill the parameters!"
            echo

            echo "
- 3rd check - Parameters for the response file -
"

            if [[ -f /home/$USER/parameters.txt ]]
            then
                echo -e "\e[1;32mParameters File exists!\e[0m
"
                else
                echo -e "\e[1;31mFailed!\e[0m You need to create a parameters file if you want to use it as an option
for your variables instead of adding in runtime.
"
                exit 1
            fi

            while true; do
                arrayparam="ORACLE_HOSTNAME
ORACLE_BASE
ORACLE_SID
INVENTORY"

                line='------------------------------------'

                x=param
                var=array$x[@]

                echo -e "Enter values for the following:
"

                for par in ${!var};
                do
                    read -p "Enter $par value: " $par
                done


                echo -e "
Summary of the variables

Variable                              Value Entered
------------------------------------- -----------------------------------"

                for pa in ${!var};
                do
                    printf "%s %s ${!pa}\n" $pa "${line:${#pa}}"
                done

                echo ""

                read -p "Answer Yy to confirm parameters or Nn to exit: " yn
                case $yn in
                    [Yy]* ) break;;
                    [Nn]* ) exit;;
                    * ) echo -e "Please answer \e[1;32mYES\e[0m or \e[1;31mNO\e[0m: ";;
                esac
            done

            # Substitution root 1
            sed -i "s~^user_folder.*$~cd /home/$USER~" oracle_silent_install_root_1.sh
            sed -i "s~^mkdir -p.*$~mkdir -p $ORACLE_BASE/oh~" oracle_silent_install_root_1.sh
            sed -i "s~^export ORACLE_HOSTNAME=.*$~export ORACLE_HOSTNAME=$ORACLE_HOSTNAME~" oracle_silent_install_root_1.sh
            sed -i "s~^export ORACLE_UNQNAME=O.*$~export ORACLE_UNQNAME=O$ORACLE_SID~" oracle_silent_install_root_1.sh
            sed -i "s~^export ORACLE_BASE=.*$~export ORACLE_BASE=$ORACLE_BASE~" oracle_silent_install_root_1.sh
            sed -i "s~^export ORACLE_SID=.*$~export ORACLE_SID=$ORACLE_SID~" oracle_silent_install_root_1.sh
            sed -i "s~^orainventory_scripts.*$~cd $INVENTORY~" oracle_silent_install_root_1.sh
            sed -i "s~^oracle_base_scripts.*$~cd $ORACLE_BASE/oh~" oracle_silent_install_root_1.sh

            # Substitution parameters.txt
            sed -i "s~^DATABASE=.*$~DATABASE=$ORACLE_SID~" parameters.txt
            sed -i "s~^HOST_NAME=.*$~HOST_NAME=$ORACLE_HOSTNAME~" parameters.txt
            sed -i "s~^INVENTORY_LOCATION=.*$~INVENTORY_LOCATION=$INVENTORY~" parameters.txt
            sed -i "s~^O_HOME=.*$~O_HOME=$ORACLE_BASE/oh~" parameters.txt
            sed -i "s~^O_BASE=.*$~O_BASE=$ORACLE_BASE~" parameters.txt
            sed -i "s~^gdbName=.*$~gdbName=$ORACLE_SID.$ORACLE_HOSTNAME~" parameters.txt
            sed -i "s~^datafileDestination=.*$~datafileDestination=$ORACLE_BASE/oh/oradata~" parameters.txt
            sed -i "s~^recoveryAreaDestination=.*$~recoveryAreaDestination=$ORACLE_BASE/oh/flash_recovery_area~" parameters.txt

            chmod +x /home/$USER/*sh
            sudo ./oracle_silent_install_root_1.sh
            break;;
        2)
            echo "You chose to add the parameters manually"
            echo

            while true; do
                arrayparam="ORACLE_HOSTNAME
ORACLE_BASE
ORACLE_SID
INVENTORY"

                line='------------------------------------'

                x=param
                var=array$x[@]

                echo -e "Enter values for the following:
"

                for par in ${!var};
                do
                    read -p "Enter $par value: " $par
                done


                echo -e "
Summary of the variables

Variable                              Value Entered
------------------------------------- -----------------------------------"

                for pa in ${!var};
                do
                    printf "%s %s ${!pa}\n" $pa "${line:${#pa}}"
                done

                echo ""

                read -p "Answer Yy to confirm parameters or Nn to exit: " yn
                case $yn in
                    [Yy]* ) break;;
                    [Nn]* ) exit;;
                    * ) echo -e "Please answer \e[1;32mYES\e[0m or \e[1;31mNO\e[0m: ";;
                esac
            done

            # Substitution root 2
            sed -i "s~^user_folder.*$~cd /home/$USER~" oracle_silent_install_root_2.sh
            sed -i "s~^mkdir -p.*$~mkdir -p $ORACLE_BASE/oh~" oracle_silent_install_root_2.sh
            sed -i "s~^export ORACLE_HOSTNAME=.*$~export ORACLE_HOSTNAME=$ORACLE_HOSTNAME~" oracle_silent_install_root_2.sh
            sed -i "s~^export ORACLE_UNQNAME=.*$~export ORACLE_UNQNAME=O$ORACLE_SID~" oracle_silent_install_root_2.sh
            sed -i "s~^export ORACLE_BASE=.*$~export ORACLE_BASE=$ORACLE_BASE~" oracle_silent_install_root_2.sh
            sed -i "s~^export ORACLE_SID=.*$~export ORACLE_SID=$ORACLE_SID~" oracle_silent_install_root_2.sh
            sed -i "s~^orainventory_scripts.*$~cd $INVENTORY~" oracle_silent_install_root_2.sh
            sed -i "s~^oracle_base_scripts.*$~cd $ORACLE_BASE/oh~" oracle_silent_install_root_2.sh

            chmod +x /home/$USER/*sh
            sudo ./oracle_silent_install_root_2.sh
            break;;
        3)
            while true; do
                echo "Press Ctrl-C to quit..."
            done
    esac
done

ENDTIME=$(date +%H%M%S)

echo -e "Start time: $STARTTIME. End time: $ENDTIME. Elapsed: $(($ENDTIME - $STARTTIME))
"

read -p "Time to reboot. Press ENTER to reboot now..."

sudo reboot now

