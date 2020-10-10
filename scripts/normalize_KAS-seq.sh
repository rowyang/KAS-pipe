#!/bin/bash
# creatation: 2020-1-20
set -e  # Stop on error

###
### normalize_KAS-seq.sh - This script is used to normalize KAS-seq data(bedGraph file).
###
### Usage: normalize_KAS-seq.sh <KAS_seq_file> <ratio>.
###
### Example: nohup normalize_KAS-seq.sh KAS_seq_file.txt ratio.txt &
###
### <KAS_seq_file> Input the text file containing the bedGraph files generated from KAS-seq_mapping.sh.
### Example: KAS-seq.rep1.bg KAS-seq.rep2.bg KAS-seq.rep3.bg  ---KAS_seq_file.txt
###
### <ratio> Input the text file containing ratios that you want to use to normalize KAS-seq data.
### The ratio you can calculate based on unique mapped reads or Spike-In reads.
### Example: 1.10 1.20 1.30  ---ratio.txt
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
  echo "This script is used to normalize KAS-seq data(bedGraph file)."
  echo
  echo "Usage: 
        normalize_KAS-seq.sh <KAS_seq_file> <ratio>"

  echo "Example: 
        nohup normalize_KAS-seq.sh KAS_seq_file.txt ratio.txt &"
  echo
fi

# check the parameters to normalize_KAS-seq.sh

if test -z $1 
then
   echo "please input the text file containing the bedGraph files generated from KAS-seq_mapping.sh" 
   exit
fi

if test -z $2
then
   echo "please input the text file containing ratios that you want to use to normalize KAS-seq data"
   echo "you can calculate the ratio based on unique mapped reads or Spike-In reads."
   exit
fi

number_of_samples=$(head -1 $1 | awk '{print NF}' - )
number_of_ratios=$(head -1 $2 | awk '{print NF}' - )

if [[ ${number_of_samples} != ${number_of_ratios} ]]
then
   echo "error:the number of ratios isn't consistent with the number of samples"
   exit
fi


# parameters for KAS-seq_normalization.sh

KAS_seq_file=$1
ratio=$2

#normalize bedGraph files

for ((i=1; i<=${number_of_samples}; i++))
do
    samples_selected=$(awk '{print $'$i' }' $KAS_seq_file)
    ratio_selected=$(awk '{print $'$i' }' $ratio)
    KAS_seq_basename=$(basename ${samples_selected} .bg) 
    awk -v ratios="$ratio_selected" '{printf("%s\t%d\t%d\t%.2f\n",$1,$2,$3,$4*ratios)}' $samples_selected > ${KAS_seq_basename}.nor.bg 
done

echo "=== All done successfully."
