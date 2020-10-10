#!/bin/bash
# creatation: 2020-1-14
# Author: Ruitu Lyu (lvruitu@gmail.com)

# Stop on error
set -e
###
### setup.sh - This script is used to setup the KAS-seq analysis pipeline.
###
### make sure you have conda installed in your server or PCs.
###
### you can follow the user guide to accomplish the anaconda installation: https://docs.conda.io/projects/conda/en/latest/user-guide/install/.
###
### Usage: ./setup.sh	
###
### -h or --help Print the help.
###

# Help message for shell scripts

help() { 
    sed -rn 's/^### ?//;T;p' "$0"
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    help
fi

if [[ "$#" -eq 1 ]]; then
    exit 1
elif [[ "$#" -gt 1 ]]; then
    echo "please refer the usage: ./setup.sh"
    exit 1
elif [[ "$#" -eq 0 ]]; then 
    echo "setup KAS-seq pipeline"
fi    

# make these scripts executable and add their directory to your PATH

SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

chmod 755 ${SH_SCRIPT_DIR}/scripts/*sh
echo export PATH=\"${SH_SCRIPT_DIR}/scripts:"$"PATH\" >> $HOME/.bashrc
. $HOME/.bashrc

echo "All the shell scripts have been made to be executable and added to the path variable, please enjoy the KAS-seq analysis pipeline!"
