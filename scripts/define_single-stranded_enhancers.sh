#!/bin/bash
# creatation: 2020-2-18

set -e  # Stop on error

###
### define_single-stranded_enhancers.sh - This script is used to define single-stranded enhancers.
###
### Usage: define_single-stranded_enhancers.sh <enhancer_list> <KAS_peaks> <assembly>.
###
### Example: nohup define_single-stranded_enhancers.sh enhancers.bed KAS_peaks.bed hg19 &
###
### <enhancer_list> Input the enhancers list at bed format, which can be defined using distal H3K27ac or ATAC-seq peaks.
###
### <KAS_peaks> Input the KAS-seq peaks.
### Note: KAS-seq peaks on genebody enhancers may be affected by elongation related KAS signal, so it will be great if you use KAS-seq peaks in elongation inh
### ibited cells, e.g DRB inhibited cells.
###
### <assembly> Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
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

if [[ "$#" -lt 3 ]]; then
  echo
  echo "This script is used to define single-stranded enhancers."
  echo
  echo "Usage:
        define_single-stranded_enhancers.sh <enhancer_list> <KAS_peaks> <assembly>"

  echo "Example:
        nohup define_single-stranded_enhancers.sh enhancers.bed KAS_peaks.bed hg19 &"
  echo
fi

# parameters submittted to define_single-stranded_enhancers.sh

enhancer_list=$1
KAS_peaks=$2
assembly=$3
SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# check the parameters to define_single-stranded_enhancers.sh
if test -z $1
then
   echo "please input the enhancers list at bed format, which can be defined using distal H3K27ac or ATAC-seq peaks"
   exit
fi

if test -z $2
then
   echo "please input the KAS-seq peaks"
   echo "Note: KAS-seq peaks on genebody enhancers may be affected by elongation related KAS signal, so it will be great if you use KAS-seq peaks in elongation inhibited cells, e.g DRB inhibited cells."
   exit
fi

if test -z $3
then
   echo "the assembly of your reference genome(mm9, mm10, hg19, hg38...)"
   exit
fi


bedtools intersect -a $enhancer_list -b ${SH_SCRIPT_DIR}/../Annotation/${assembly}.promoter.bed -v > ${enhancer_list}.distal.bed
enhancer_basename=$(basename ${enhancer_list} .bed)
bedtools intersect -a ${enhancer_list}.distal.bed -b $KAS_peaks -wa -F 0.9 | sort -u | sortBed -i > ${enhancer_basename}_SSEs.bed
awk '{printf("%s\t%d\t%d\n",$1,$2,$3)}' ${enhancer_basename}_SSEs.bed > ${enhancer_basename}_SSEs.3bed
awk '{printf("%s\t%d\t%d\n",$1,$2,$3)}' $KAS_peaks > ${KAS_peaks}.3bed
bedtools intersect -a ${KAS_peaks}.3bed -b ${enhancer_basename}_SSEs.3bed -wo | awk '{printf("%s\t%d\t%d\t%d\t%d\t%.2f\n",$4,$5,$6,$6-$5,$7,$7/($6-$5))}' > ${enhancer_basename}_SSEs.twotypes.bed
awk '$6>=0.5 {printf("%s\t%d\t%d\t%d\t%d\t%.2f\n",$1,$2,$3,$4,$5,$6)}' ${enhancer_basename}_SSEs.twotypes.bed > ${enhancer_basename}_SSEs.entire.no_header.bed
awk '$6<0.5 {printf("%s\t%d\t%d\t%d\t%d\t%.2f\n",$1,$2,$3,$4,$5,$6)}' ${enhancer_basename}_SSEs.twotypes.bed > ${enhancer_basename}_SSEs.middle.no_header.bed
echo -e "#chr\tstart\tend\tenhancer_length\tKAS_length\tratio" > header.txt
cat header.txt ${enhancer_basename}_SSEs.entire.no_header.bed > ${enhancer_basename}_SSEs.entire.bed
cat header.txt ${enhancer_basename}_SSEs.middle.no_header.bed > ${enhancer_basename}_SSEs.middle.bed

rm -f ${enhancer_list}.distal.bed 
rm -f ${enhancer_basename}_SSEs.3bed
rm -f ${KAS_peaks}.3bed
rm -f ${enhancer_basename}_SSEs.twotypes.bed
rm -f ${enhancer_basename}_SSEs.entire.no_header.bed
rm -f ${enhancer_basename}_SSEs.middle.no_header.bed

echo "=== All done successfully."
