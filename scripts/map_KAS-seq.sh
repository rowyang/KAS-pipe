#!/bin/bash
# creatation: 2020-1-14

# Stop on error
set -e

###
### map_KAS-seq.sh - This script is used to map KAS-seq data to the reference genome.
###
### Usage:
### Single_end: map_KAS-seq.sh <bowtie2_index_path> <threads> <basename> <assembly> <single> <raw_fastq_read>
### Paired_end: map_KAS-seq.sh <bowtie2_index_path> <threads> <basename> <assembly> <paired> <raw_fastq_read1> <raw_fastq_read2>
###
### Example:
### Single_end: nohup map_KAS-seq.sh /Genome/hg19_Bowtie2Index/hg19 10 KAS-seq_data hg19 single KAS-seq.single.fastq.gz &
### Paired_end: nohup map_KAS-seq.sh /Genome/hg19_Bowtie2Index/hg19 10 KAS-seq_data hg19 paired KAS-seq.paired.R1.fastq.gz KAS-seq.paired.R2.fastq.gz &
###
### Options:
### <bowtie2_index_path> Input the path of reference genome bowtie2 index.
###
### <threads> Input the number of threads.
###
### <basename> Input the basename of KAS-seq_mapping.sh output files.
###
### <assembly> Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
###
### <paired_or_single> Specify the mode of KAS-seq data alignment(single, paired).
###
### <raw_fastq_read1> Input the single-end KAS-seq fastq file or read 1 of paired-end KAS-seq fastq files.
###
### <raw_fastq_read2> Input the read 2 of paired-end KAS-seq fastq files.
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


if [[ "$#" -lt 7 ]]; then
  echo
  echo "This script is used to map KAS-seq data to the reference genome."
  echo

  echo "Usage: 
Single-end mode: map_KAS-seq.sh <bowtie2_index_path> <threads> <basename> <assembly> <single> <raw_fastq_read1>

Paired-end mode: map_KAS-seq.sh <bowtie2_index_path> <threads> <basename> <assembly> <paired> <raw_fastq_read1> <raw_fastq_read2>"

  echo "Example: 
Single-end mode: nohup map_KAS-seq.sh /Genome/hg19_Bowtie2Index/hg19 10 KAS-seq_data hg19 single KAS-seq.single.fastq.gz &

Paired-end mode: nohup map_KAS-seq.sh /Genome/hg19_Bowtie2Index/hg19 10 KAS-seq_data hg19 paired KAS-seq.paired.R1.fastq.gz KAS-seq.paired.R2.fastq.gz &"

fi

# test the options submitted into KAS-seq_mapping.sh shell script.

if test -z $1 
   then
   echo "please input the path of reference genome bowtie2 index(/share/Genome/hg19(mm10)_Bowtie2Index/hg19(mm10))." 
   exit
fi

if test -z $2
   then
   echo "please input the number of threads."
   exit
fi

if test -z $3
   then
   echo "please input basename of output files."
   exit
fi

if test -z $4
   then
   echo "please input the assembly of reference genome(mm9, mm10, hg19, hg38...)"
   exit
fi

if test -z $5
then
   echo "please input the alignment mode(single or paired) of KAS-seq data."
   exit
fi

if [[ $5 != "single" ]] && [[ $5 != "paired" ]]
then
   echo "Error: unsupported types of adapter $5."
   exit
fi

if test -z $6
then
   echo "please input the single-end KAS-seq fastq file or read1 of paired-end KAS-seq fastq files."
   exit
fi 

if [[ "${5}" == "paired" ]] && test -z $7 ;then
   echo "please input read2 of paired-end KAS-seq fastq files"
   exit
   else
   echo ""
fi

# parameters for mapping KAS-seq data.
bowtie2_index_path=$1
threads=$2
basename=$3
assembly=$4
paired_or_single=$5
raw_fastq_read1=$6
raw_fastq_read2=$7
SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

echo "  "
echo "Welcom to analyze KAS-seq raw fastq files... "
echo "  "
echo "Mapping to reference genome with bowtie2... "
echo "  "

if [ "${paired_or_single}" == "single" ]; then
echo "Map single-end KAS-seq data... "

mkdir -p $basename
cd $basename
mv ../$raw_fastq_read1 ./
echo "Single-end KAS-seq reads mapping statistics" > reads_statistics.txt

# All Output to reads_statistics.txt(alignment summary), nothing to the screen.
bowtie2 -p $threads -x $bowtie2_index_path $raw_fastq_read1 -S ${basename}.sam >> reads_statistics.txt 2>&1
samtools sort -@ 3 ${basename}.sam -o ${basename}_sorted.bam
samtools index ${basename}_sorted.bam
echo "" >> reads_statistics.txt
echo "Reads duplication statistics" >> reads_statistics.txt
samtools rmdup -sS ${basename}_sorted.bam ${basename}_rmdup.bam >> reads_statistics.txt 2>&1

# filter unique mapped reads
# samtools view -b -q 10 ${basename}_rmdup.bam > ${basename}_unique.bam

bamToBed -i ${basename}_rmdup.bam > ${basename}.bed
# bamToBed -i ${basename}_unique.bam > ${basename}.bed
awk '$3-150>0 {if ($6~"+") printf("%s\t%d\t%d\t%s\t%d\t%s\n",$1,$2,$2+150,$4,$5,$6); else if ($6~"-") printf("%s\t%d\t%d\t%s\t%d\t%s\n",$1,$3-150,$3,$4,$5,$6)}' ${basename}.bed > ${basename}.ext150.bed
genomeCoverageBed -bg -i ${basename}.ext150.bed -g ${SH_SCRIPT_DIR}/../chrom_size/${assembly}.chrom.sizes > ${basename}.ext150.bg
rm -f *sam
rm -f ${basename}_sorted.bam.bai
rm -f ${basename}_sorted.bam
rm -f ${basename}.bed 

elif [ "${paired_or_single}" == "paired" ]; then
echo "Map paired-end KAS-seq data... "

mkdir -p $basename
cd $basename 
mv ../$raw_fastq_read1 ./
mv ../$raw_fastq_read2 ./
echo "Paired-end KAS-seq reads mapping statistics" > reads_statistics.txt

# All Output to reads_statistics.txt(alignment summary), nothing to the screen.
bowtie2 -X 1000 -p $threads -x $bowtie2_index_path -1 $raw_fastq_read1 -2 $raw_fastq_read2 -S ${basename}.sam >> reads_statistics.txt 2>&1
sed -i '/^@PG/d' ${basename}.sam
samtools sort -@ 3 ${basename}.sam -o ${basename}_sorted.bam
samtools index ${basename}_sorted.bam
echo "" >> reads_statistics.txt
echo "Reads duplication statistics" >> reads_statistics.txt
picard MarkDuplicates INPUT=${basename}_sorted.bam OUTPUT=${basename}_rmdup.bam METRICS_FILE=${basename}.PCR_duplicates REMOVE_DUPLICATES=true 
cat ${basename}.PCR_duplicates >> reads_statistics.txt
samtools index ${basename}_rmdup.bam

# filter unique mapped reads
# samtools view -b -q 10 ${basename}_rmdup.bam > ${basename}_unique.bam

echo "" >> reads_statistics.txt
echo "Average length of DNA fragments" >> reads_statistics.txt
samtools view -h  ${basename}_rmdup.bam | ${SH_SCRIPT_DIR}/../src/SAMtoBED  -i - -o  ${basename}.bed -x -v >> reads_statistics.txt 2>&1
# samtools view -h ${basename}_unique.bam | ${SH_SCRIPT_DIR}/../src/SAMtoBED  -i - -o  ${basename}.bed -x -v
bedSort ${basename}.bed ${basename}.sort.bed
genomeCoverageBed -bg -i ${basename}.sort.bed -g ${SH_SCRIPT_DIR}/../chrom_size/${assembly}.chrom.sizes > ${basename}.bg

rm -f *sam
rm -f ${basename}_sorted.bam.bai
rm -f ${basename}_sorted.bam
rm -f ${basename}.PCR_duplicates
rm -f ${basename}.bed 
fi

echo "=== All done successfully."
