#!/bin/bash
# Author: Ruitu Lyu (lvruitu@gmail.com)
set -e  # Stop on error

###
### install_conda_env.sh - This script is used to install conda environment.
###
### Note: Before try to install conda environment, make sure you have installed anaconda in your PC.
### Please refer to https://www.anaconda.com/products/individual about how to download and install the anaconda installer.
###
### Usage: install_conda_env.sh --run this shell script directly.
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

SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

CONDA_ENV_PY3=KAS-seq_pipeline
REQ_TXT_PY3=${SH_SCRIPT_DIR}/../requirements.txt

conda --version  # check if conda exists

echo "=== Installing pipeline's Conda environments ==="
conda create -n ${CONDA_ENV_PY3} --file ${REQ_TXT_PY3} -y -c defaults -c r -c bioconda -c conda-forge

echo "=== Configuring for pipeline's Conda environments ==="
CONDA_PREFIX_PY3=$(conda env list | grep -P "\b${CONDA_ENV_PY3}\s" | awk '{if (NF==3) print $3; else print $2}')

if [ ! "${CONDA_PREFIX_PY3}" ];
then
	echo "Error: Pipeline's Conda environments not found."
	echo "Try to reinstall pipeline's Conda environments."
	echo
	echo "1) $ bash Uninstall_conda_env.sh"
	echo "2) $ bash Install_conda_env.sh"
	exit 1
fi

# make activate.d to init pipeline's Conda envs
CONDA_LIB="${CONDA_PREFIX_PY3}/lib"
CONDA_BIN="${CONDA_PREFIX_PY3}/bin"
CONDA_ACTIVATE_D="${CONDA_PREFIX_PY3}/etc/conda/activate.d"
CONDA_DEACTIVATE_D="${CONDA_PREFIX_PY3}/etc/conda/deactivate.d"
CONDA_ACTIVATE_SH="${CONDA_ACTIVATE_D}/env_vars.sh"
CONDA_DEACTIVATE_SH="${CONDA_DEACTIVATE_D}/env_vars.sh"
mkdir -p ${CONDA_ACTIVATE_D}
mkdir -p ${CONDA_DEACTIVATE_D}
touch ${CONDA_ACTIVATE_SH}
touch ${CONDA_DEACTIVATE_SH}

# disable multithreading for BLAS
echo "export OPENBLAS_NUM_THREADS=1" > ${CONDA_ACTIVATE_SH}
echo "export MKL_NUM_THREADS=1" >> ${CONDA_ACTIVATE_SH}
echo "unset OPENBLAS_NUM_THREADS MKL_NUM_THREADS" >> ${CONDA_DEACTIVATE_SH}

# to prevent conflict between Conda's python packages and user's local one
echo "export PYTHONNOUSERSITE=True" >> ${CONDA_ACTIVATE_SH}
echo "unset PYTHONNOUSERSITE" >> ${CONDA_DEACTIVATE_SH}

# LD_LIBRARY_PATH due to libgcc problem
echo "export OLD_LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}" >> ${CONDA_ACTIVATE_SH}
echo "export LD_LIBRARY_PATH=${CONDA_LIB}:\${LD_LIBRARY_PATH}" >> ${CONDA_ACTIVATE_SH}

echo "export LD_LIBRARY_PATH=\${OLD_LD_LIBRARY_PATH}" >> ${CONDA_DEACTIVATE_SH}
echo "unset OLD_LD_LIBRARY_PATH" >> ${CONDA_DEACTIVATE_SH}

# to prevent conflict between Conda's R and global(local) R
echo "export OLD_R_HOME=\${R_HOME}" >> ${CONDA_ACTIVATE_SH}
echo "export OLD_R_LIBS=\${R_LIBS}" >> ${CONDA_ACTIVATE_SH}
echo "export R_HOME=${CONDA_LIB}/R" >> ${CONDA_ACTIVATE_SH}
echo "export R_LIBS=${CONDA_LIB}/R/library" >> ${CONDA_ACTIVATE_SH}

echo "export R_HOME=\${OLD_R_HOME}" >> ${CONDA_DEACTIVATE_SH}
echo "export R_LIBS=\${OLD_R_LIBS}" >> ${CONDA_DEACTIVATE_SH}
echo "unset OLD_R_HOME" >> ${CONDA_DEACTIVATE_SH}
echo "unset OLD_R_LIBS" >> ${CONDA_DEACTIVATE_SH}

echo "=== All done successfully ==="
