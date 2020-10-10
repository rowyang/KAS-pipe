#!/bin/bash
# creatation: 2020-2-14
# Author: Ruitu Lyu (lvruitu@gmail.com)

set -e # Stop on error

###
### plotFingerprint.sh - This script is used to plot fingerprint for KAS-seq data(indexed KAS-seq Bam files are needed).
###
### Usage: plotFingerprint.sh <KAS_seq_files> <labels> <threads> <assembly> <basename>
###  
### Example: nohup plotFingerprint.sh KAS_seq_files.txt labels.txt 10 hg19 KAS-seq &
### 
### Options:
### <KAS_seq_files> Input the text file containing file name of indexed KAS-seq bam files.
### Example: KAS.rep1.bam KAS.rep2.bam KAS.rep3.bam Input.bam ---KAS_seq_files.txt
###
### <labels> Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
### Note:The number of labels needs to be consistent with the number of KAS-seq bam files. 
### Example: KAS.rep1 KAS.rep2 KAS.rep3 Input ---labels.txt
### 
### <threads> Input the number of threads.
###
### <assembly> Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
###
### <basename> Input the basename of output files.
###
### <regions> Input the features you want to generate the plots(peaks, genebody, TSS, TES)
###
### <plot_type> Input the types of the summary plots(heatmap, profile).
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

if [[ "$#" -lt 5 ]]; then
  echo
  echo "This script is used to plot fingerprint for KAS-seq data"
  echo "Indexed KAS-seq Bam files are needed."
  echo
  echo "Usage: plotFingerprint.sh <KAS_seq_files> <labels> <threads> <assembly> <basename>"
  echo " "
  echo "Example:nohup plotFingerprint.sh KAS_seq_files.txt label.txt 10 hg19 KAS-seq &"
  echo
fi

# check the options submitted to shell script.
if test -z $1
then
   echo "please input the txt file containing the file names of indexed KAS-seq IP and Input bam file."
   exit
fi

if test -z $2
then
   echo "please input the txt file containing the labels of indexed KAS-seq and Input bam files."
   exit
fi

number_of_samples=$( head -1 $1 | awk '{print NF}' $1 )
number_of_labels=$(head -1 $2 | awk '{print NF}' $2 )

if [[ ${number_of_labels} != ${number_of_samples} ]]
then
   echo "error:the number of labels isn't consistent with the number of samples."  
   exit
fi

if test -z $3
then
   echo "please input the number of threads."
   exit
fi

if test -z $4
then
	echo "please input the assembly of reference genome(mm9, mm10, hg19, hg38...)"
   exit
fi
 
if test -z $5
then
        echo "please input the basename of output files."
   exit
fi

KAS_seq_files=$(cat $1)
labels=$(cat $2)
threads=$3
assembly=$4
basename=$5
SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# generate the index for bam files.
for i in $KAS_seq_files; do samtools index $i ; done;

# plot the fingerprint.
plotFingerprint -b $KAS_seq_files --labels $labels --minMappingQuality 30 --skipZeros --region 1 --numberOfSamples 500000 -T "${basename} KAS-seq Fingerprint plot" --plotFile ${basename}_KAS-seq_Fingerprints_plot.svg --plotFileFormat svg --outRawCounts ${basename}_KAS-seq_Fingerprints_plot.tab --numberOfProcessors $threads --blackListFileName ${SH_SCRIPT_DIR}/../blacklist/${assembly}-blacklist.bed 

plotFingerprint -b $KAS_seq_files --labels $labels --minMappingQuality 30 --skipZeros --region 1 --numberOfSamples 500000 -T "${basename} KAS-seq Fingerprint plot" --plotFile ${basename}_KAS-seq_Fingerprints_plot.png --plotFileFormat png --outRawCounts ${basename}_KAS-seq_Fingerprints_plot.tab --numberOfProcessors $threads --blackListFileName ${SH_SCRIPT_DIR}/../blacklist/${assembly}-blacklist.bed 

echo "=== All done successfully ==="
