#!/bin/bash
# creatation: 2019-5-14
# Author: Ruitu Lyu (lvruitu@gmail.com)

###
### make_BigWig_files.sh - This script is used to transfer bedGraph format to bigWig format.
###
### Usage: make_BigWig_files.sh <KAS_seq_file> <assembly>.
###
### Example: nohup make_BigWig_files.sh KAS_seq_file.txt hg19 &
###
### <KAS_seq_file> Input the text file containing the normalized bedGraph files.
### Example: KAS-seq.rep1.nor.bg KAS-seq.rep2.nor.bg KAS-seq.rep3.nor.bg  ---KAS_seq_file.txt
###
### <assembly> Input the assembly of reference genome you use for KAS-seq data mapping.
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
  echo "This script is used to transfer bedGraph format to bigWig format."
  echo

  echo "Usage: make_BigWig_files.sh <KAS_seq_file> <assembly>"
  echo " "
  echo "Example: nohup make_BigWig_files.sh KAS_seq_file.txt hg19 &"
  echo " " 
  echo
fi

# check the options submitted to make_BigWig_files.sh 

if test -z $1
then
   echo "please input the text file containing the normalized bedGraph files."
   exit
fi

if test -z $2
then
   echo "please input the assembly of reference genome you use for KAS-seq data mapping."
   exit
fi

# parameters for make_BigWig_files.sh 

KAS_seq_file=$1
assembly=$2
SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

number_of_samples=$( head -1 $KAS_seq_file | awk '{print NF}' - )

#normalize bedGraph files

for ((i=1; i<=${number_of_samples}; i++))
do
sample_selected=$(awk '{print $'$i' }' $KAS_seq_file)
KAS_seq_basename=$(basename ${sample_selected} .bg)
bedSort $sample_selected ${KAS_seq_basename}.sort.bg
bedGraphToBigWig ${KAS_seq_basename}.sort.bg ${SH_SCRIPT_DIR}/../chrom_size/${assembly}.chrom.sizes ${KAS_seq_basename}.bigWig
rm -rf ${KAS_seq_basename}.sort.bg
done

echo "=== All done successfully"
