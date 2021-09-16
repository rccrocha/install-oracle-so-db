#!/bin/bash

cd /home/oracle 
sed -i "16r parameters.txt" oracle_silent_install_oracle_args.sh
. oracle_silent_install_oracle_args.sh
