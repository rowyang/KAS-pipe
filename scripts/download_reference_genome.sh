#!/bin/bash
# Stop on error
set -e

###
### download_reference_genome.sh - This script is used to download reference genome <assembly> in a directory <dest_dir>.
###
### Usage: download_reference_genome.sh <assembly> <dest_dir>
###
### Example: nohup download_reference_genome.sh hg19 /your/genome/data/path/ &
###
### Options:
### <assembly> Input the assembly of the reference genome you want to download(mm9, mm10, hg19, hg38...).
###
### <dest_dir> Input the path of the directory that you want to download your interested genome in your PC.
###
### -h or --help Print the help.
###


if [[ "$#" -lt 2 ]]; then
  echo
  echo "This script is used to download reference genome."
  echo
  echo "Supported genomes: mm9, mm10, hg19 and hg38"
  echo
  echo "Usage: download_reference_genome.sh <assembly> <dest_dir>"
  echo
  echo "Example: nohup download_reference_genome.sh hg19 /your/genome/data/path/"
  echo
fi

if test -z $1 
then
	echo "please input the reference genome you want to download(mm9, mm10, hg19 and hg38)" 
   exit 2
fi

if test -z $2
then
   echo "please input the path of your downloaded reference genome"
   exit 2
fi 


assembly=$1
dest_dir=$(cd $(dirname $2) && pwd -P)/$(basename $2)

######################################################
echo "  "
echo "=== Creating destination directory and TSV file..."
mkdir -p ${dest_dir}
cd ${dest_dir}

if [[ "${assembly}" == "hg19" ]]; then
REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz"

elif [[ "${assembly}" == "mm9" ]]; then
REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/mm9/bigZips/mm9.fa.gz"

elif [[ "${assembly}" == "hg38" ]]; then
REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz"
  
elif [[ "${GENOME}" == "mm10" ]]; then
REF_FA="http://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz"    

fi

if [[ -z "${REF_FA}" ]]; then
  echo "Error: unsupported reference genome $assembly"
  exit 1
fi


echo "=== Downloading files..."
wget -c  ${REF_FA}

echo "=== All done successfully."
