#!/bin/bash
conda deactivate

CONDA_ENV_PY3=KAS-seq_pipeline
CONDA_ENV_OLD_PY3=KAS-seq_pipeline-python3

conda env remove -n ${CONDA_ENV_PY3} -y
conda env remove -n ${CONDA_ENV_OLD_PY3} -y

