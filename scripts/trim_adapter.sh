#!/bin/bash
# creatation: 2019-12-29
# Author: Ruitu Lyu (lvruitu@gmail.com)

set -e  # Stop on error

###
### trim_adapter.sh - This script is used to trim adapter and low quality sequence from Raw KAS-seq data.
###
### Usage:
### Single_end: trim_adapter.sh <Adapter_type> <Minimum_reads_length> <threads> <single> <raw_fastq_read>
### Paired_end: trim_adapter.sh <Adapter_type> <Minimum_reads_length> <threads> <paired> <raw_fastq_read1> <raw_fastq_read2>
###
### Example:
### nohup trim_adapter.sh illumina 30 10 single raw_fastq_read1.fastq.gz &
### nohup trim_adapter.sh illumina 30 10 paired raw_fastq_read1.fastq.gz raw_fastq_read2.fastq.gz &
###
### Options:
### <adapter_type> Input the adapter types during KAS-seq libraries construction(illumina, nextera, small_rna).
###
### <min_reads_length> Discard reads that became shorter than length <min_reads_length> because of either quality or adapter trimming.
###
### <threads> Input the number of cores to be used for trimming.
###
### <paired_or_single> Specify the mode of sequencing data(single, paired).
###
### <raw_fastq_read1> Input the single-end raw fastq file or read 1 of paired-end raw fastq files.
###
### <raw_fastq_read2> Input the read 2 of paired-end raw fastq files.
### 
### -h or --help Print the help.
###
### Note: This shell script invoke the trim-galore, please refer http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/ for more information. 
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
  echo "This script is used to adapter sequence and low quality sequence trimming."
  echo

  echo "Usage: 
  Single end: trim_adapter.sh <Adapter_type> <Minimum_reads_length> <threads> <single> <raw_fastq_read>
  Paired end: trim_adapter.sh <Adapter_type> <Minimum_reads_length> <threads> <paired> <raw_fastq_read1> <raw_fastq_read2>" 

  echo "Example: 
  Single end: nohup trim_adapter.sh illumina 30 10 single KAS-seq.fastq.gz &  
  Paired end: nohup trim_adapter.sh illumina 30 10 paired KAS-seq.read1.fastq.gz KAS-seq.read2.fastq.gz & "
  echo
fi

# check the parameters users provide to the shell script.

if test -z $1 
   then
	echo "please input the adapter types you used during KAS-seq libraries construction(illumina,nextera,small_rna)" 
   exit
fi

if [[ $1 != "illumina" ]] && [[ $1 != "nextera" ]] && [[ $1 != "small_rna" ]]
then
   echo "Error: unsupported types of adapter $1"
   exit
fi

if test -z $2
   then
   echo "please input the minimum length of trimmed reads"
   exit
fi 

if test -z $3
   then
   echo "please input the number of cores to be used for trimming"
   exit
fi

if test -z $4
   then
   echo "please input paired or single to specify the KAS-seq sequencing mode"
   exit
fi

if [[ $4 != "single" ]] && [[ $4 != "paired" ]]
then
   echo "Error: unsupported types of KAS-seq sequencing mode $3"
   exit
fi

if test -z $5
   then
   echo "please input single-end raw fastq file or read 1 of paired-end raw fastq files"
   exit
fi


if [[ "$4" == "paired" ]] && test -z $6 ;then 
   echo "please input read2 of paired-end raw fastq files"
   exit
   else 
   echo " "
   fi

# parameters for trimming adapter sequence and low-quality sequence.

adapter_type=$1
minimum_reads_length=$2
threads=$3
paired_or_single=$4
raw_fastq_read1=$5
raw_fastq_read2=$6

echo "  "
echo "Welcom to analyze KAS-seq from fastq file... "
echo "  "
echo "[1] Quality control analysis with fastqc ... "
echo "  "

if [[ "${paired_or_single}" == "single" ]]; then
fastqc -t $threads $raw_fastq_read1
elif [[ "${paired_or_single}" == "paired" ]]; then
fastqc -t $threads $raw_fastq_read1
fastqc -t $threads $raw_fastq_read2
fi

echo "  "
echo "[2] Automate quality and adapter trimming as well as quality control with Trim Galore! ... "
echo "  "

if [ "$paired_or_single" == "single" ]; then
trim_galore --${adapter_type} -j $threads --fastqc --length $minimum_reads_length $raw_fastq_read1 

elif [ "$paired_or_single" == "paired" ]; then
trim_galore --${adapter_type} -j $threads --fastqc --length $minimum_reads_length --paired $raw_fastq_read1 $raw_fastq_read2 
fi
 
if test -e fastqc; then
        cd fastqc
        mv ../*html ./ 
	cd ..
else
	mkdir -p fastqc
        cd fastqc
	mv ../*html ./
	cd ..
fi

rm -rf *txt
rm -rf *zip 

echo "[3] All done successfully"
