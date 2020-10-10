#!/bin/bash
# Author: Ruitu Lyu (lvruitu@gmail.com)
set -e # Stop on error

###
### build_reference_genome.sh - This script is used to install reference genome <assembly> in a directory <dest_dir>.
###
### Usage: build_reference_genome.sh <assembly> <dest_dir>
###
### Example: nohup build_reference_genome.sh hg19 /your/genome/data/path/ &
###
### Options:
### <assembly> Input the assembly of the reference genome you want to download and install(mm9, mm10, hg19, hg38...).
###
### <dest_dir> Input the path of the directory that you want to install your interested genome in your PC.
###
### -h or --help Print the help.
###

# Help message for shell scripts

help() {
    sed -rn 's/^### ?//;T;p' "$0"
}

if [[ $# == 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    help
    exit 1
fi

if [[ "$#" -lt 2 ]]; then
  echo
  echo "Activate pipeline's conda environment before submit this script!"
  echo
  echo "This script is used to install reference genome <assembly> in a directory <dest_dir>."
  echo
  echo "Supported genomes: mm9, mm10, hg19 and hg38"
  echo
  echo "Usage: build_reference_genome.sh <assembly> <dest_dir>"
  echo 
  echo "Example: build_reference_genome.sh hg19 /your/genome/data/path/"
  echo
fi

# check the parameters users provide to the shell script.

if test -z $1
   then
   echo "please input the assembly of the reference genome you want to install(mm9, mm10, hg19 or hg38)" 
   exit
fi

if test -z $2
   then
   echo "please input the path of the directory that you want to install your interested genome in your PC"
   exit
fi



# parameters for building aligner indices
BUILD_BWT2_NTHREADS=5

assembly=$1
dest_dir=$(cd $(dirname $2) && pwd -P)/$(basename $2)


mkdir -p ${dest_dir}
cd ${dest_dir}

if [[ "${assembly}" == "mm9" ]]; then
  REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/mm9/bigZips/mm9.fa.gz"

elif [[ "${assembly}" == "mm10" ]]; then
  REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz"
  
elif [[ "${assembly}" == "hg19" ]]; then
  REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz"

elif [[ "${assembly}" == "hg38" ]]; then
  REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz"

fi 

if [[ -z "${REF_FA}" ]]; then
  echo "Error: unsupported genome $assembly"
  exit 1
fi

echo "=== Downloading files..."
if [[ ! -z "${REF_FA}" ]]; then wget -c -O $(basename ${REF_FA}) ${REF_FA}; fi

echo "=== Processing downloaded reference genome fa file..."
if [[ ${REF_FA} == *.gz ]]; then 
  REF_FA_PREFIX=$(basename ${REF_FA} .gz)
  gzip -d -f -c ${REF_FA_PREFIX}.gz > ${REF_FA_PREFIX}
else
  REF_FA_PREFIX=$(basename ${REF_FA})
fi

echo "=== Generating fasta index"
cd ${dest_dir}
samtools faidx ${REF_FA_PREFIX}

echo "=== Generating ${assembly} reference genome bowtie2 index"
mkdir -p ${dest_dir}/${assembly}_Bowtie2Index
cd ${dest_dir}/${assembly}_Bowtie2Index
mv ../${REF_FA_PREFIX} ${REF_FA_PREFIX}
mv ../${REF_FA_PREFIX}.fai ./

bt2_index_base=$(basename ${REF_FA_PREFIX} .fa)
bowtie2-build ${REF_FA_PREFIX} $bt2_index_base --threads ${BUILD_BWT2_NTHREADS}
  
echo "=== Removing temporary files..."
cd ${dest_dir}
rm -f ${REF_FA_PREFIX}.gz

echo "=== All done successfully."
