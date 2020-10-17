#!/bin/bash
# creatation: 2020-1-14
# Author: Ruitu Lyu (lvruitu@gmail.com)

# Stop on error
set -e

###
### diff_KAS-seq.sh - This script is used to identify regions with differential KAS-seq signal.
### KAS-seq bigWig files are needed.
### 
### Usage:
### gene regions: diff_KAS-seq.sh <KAS_seq_files> <labels> <regions> <assembly> <basename> <threads> <diff_condition>
### peak regions: diff_KAS-seq.sh <KAS_seq_files> <labels> <regions> <assembly> <basename> <threads> <diff_condition> <peaks_list>
###
### Example:
### gene regions: nohup diff_KAS-seq.sh KAS_seq_files.txt labels.txt promoter hg19 KAS-seq_treat_vs_DMSO 10 diff_condition.txt &
### peak regions: nohup diff_KAS-seq.sh KAS_seq_files.txt labels.txt peaks hg19 KAS-seq_treat_vs_DMSO 10 diff_condition.txt peaks_list.bed &
###
### Options:
### <KAS_seq_files> Input the text file containing the file name of KAS-seq bigWig files.
### Example: KAS.treated.rep1.bigWig KAS.treated.rep2.bigWig KAS.DMSO.rep1.bigWig KAS.DMSO.rep2.bigWig ---KAS_seq_files.txt
###
### <labels> Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
### Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files.
### Example: KAS.treated.rep1 KAS.treated.rep2 KAS.DMSO.rep1 KAS.DMSO.rep2 ---labels.txt
###
### <regions> Input the features you want to use for KAS-seq differential analysis(bins, peaks, promoter, genebody, terminator).
###
### <assembly> Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
###
### <basename> Input the basename of output files generated from this shell script.
###
### <threads> Input the number of threads you want to use.
###
### <diff_condition> Input the condition table you want to use for KAS-seq differential anlsysis.
### Example:              condition
### KAS.treated.rep1      treated
### KAS.treated.rep2      treated
### KAS.DMSO.rep1         DMSO
### KAS.DMSO.rep2         DMSO             ---diff_condition.txt
###
### <peaks_list> input the peaks list only you specify peaks in <regions>(e.g. enhancers, KAS-seq peaks...).
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
  echo "This script is used to identify regions with differential KAS-seq signal."
  echo

  echo "Usage: 
        gene regions: diff_KAS-seq.sh <KAS_seq_files> <labels> <regions> <assembly> <basename> <threads> <diff_condition>
	peak regions: diff_KAS-seq.sh <KAS_seq_files> <labels> <regions> <assembly> <basename> <threads> <diff_condition> <peaks_list>"

  echo "Example: 
        gene regions: nohup diff_KAS-seq.sh KAS_seq_files.txt labels.txt bins hg19 KAS-seq_treat_vs_DMSO 10 diff_condition.txt &
	peak regions: nohup diff_KAS-seq.sh KAS_seq_files.txt labels.txt bins hg19 KAS-seq_treat_vs_DMSO 10 diff_condition.txt peaks_list.bed &"
  echo
fi

# check the parameters users provide to the shell script.

if test -z $1
   then
        echo "please input the text file with names of normalized KAS-seq bigWig files."
   exit
fi

if test -z $2
   then
        echo "please input the text file with labels of corresponding KAS-seq bigWig files."
   exit 
fi

number_of_samples=$( head -1 $1 | awk '{print NF}' - )
number_of_labels=$( head -1 $2 | awk '{print NF}' - )

if [[ ${number_of_labels} != ${number_of_samples} ]]
then
   echo "error:the number of labels isn't consistent with the number of samples."  
   exit
fi

if test -z $3
   then
   echo "please input the regions you want to do KAS-seq differential analysis(bins, peaks, promoter, genebody, terminator)."
   exit
fi

if [[ "$3" != "bins" ]] && [[ "$3" != "peaks" ]] && [[ "$3" != "promoter" ]] && [[ "$3" != "genebody" ]] && [[ "$3" != "terminator" ]]; then
  echo "Error: unsupported types of regions $3"
  exit 1
  else
  echo " "
fi

if test -z $4
   then
   echo "please input the genome assembly of the KAS-seq data(mm9, mm10, hg19, hg38...)."
   exit
fi

if test -z $5
   then
   echo "please input the basename of the output file generated from this shell script."
   exit
fi

if test -z $6
   then
   echo "please input the number of threads."
   exit
fi

if test -z $7
   then
   echo "please input the condition table you want to use for KAS-seq differential anlsysis."
   exit
fi

if [[ "$3" == "peaks" ]] && test -z $8 ;then 
   echo "please input the peaks list only you specify peaks in <regions>(e.g. enhancers, KAS-seq peaks...)"
   exit
   else 
   echo " "
fi

# Parameters for generating heatmap and metagene profile plot.

KAS_seq_files=$(cat $1)
labels=$(cat $2)
regions=$3
assembly=$4
basename=$5
threads=$6
diff_condition=$7
peaks_list=$8
label_file=$2

SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

if [[ "${regions}" == "bins" ]]; then
echo "Generate the matrix with the value of KAS-seq density on 1kb bins..."

multiBigwigSummary bins -b $KAS_seq_files --labels $labels --binSize 1000 -p $threads --blackListFileName ${SH_SCRIPT_DIR}/../blacklist/${assembly}-blacklist.bed -out ${basename}_on_1kb_bins.npz --outRawCounts ${basename}_on_1kb_bins.tab

sed "s/nan/0/g" ${basename}_on_1kb_bins.tab | sed "1d" > ${basename}_on_1kb_bins.bed

#calculate the average value of very single row in the table. 
awk 'BEGIN{if(NR>0) a[NR]=0}{if(NR>0) for(i=4; i<=NF; i++) a[NR]+=$i}END{for(j in a) print  a[j]/NF }' ${basename}_on_1kb_bins.bed > ${basename}_on_1kb_bins.average
#filter the bins with averaged KAS-seq density lower than 10.
paste ${basename}_on_1kb_bins.average ${basename}_on_1kb_bins.bed | awk '$1>=10 {print $0}' > ${basename}_on_1kb_bins.filter.bed
cut -f1,2,3,4 --complement ${basename}_on_1kb_bins.filter.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n","gene"NR"-"$2"-"$3"-"$4)}' ${basename}_on_1kb_bins.filter.bed > ${basename}_on_${assembly}_${regions}.rowname

rm -f ${basename}_on_1kb_bins.tab  
rm -f ${basename}_on_1kb_bins.npz
rm -f ${basename}_on_1kb_bins.bed
rm -f ${basename}_on_1kb_bins.average
rm -f ${basename}_on_1kb_bins.filter.bed

elif [[ "${regions}" == "peaks" ]]; then
echo "Generate the matrix with the value of KAS-seq density on merged KAS-seq peaks..."

multiBigwigSummary BED-file --bwfiles $KAS_seq_files --BED $peaks_list --labels $labels -p $threads -out ${basename}_on_${assembly}_${regions}.npz --outRawCounts ${basename}_on_${assembly}_${regions}.tab &

sed "s/nan/0/g" ${basename}_on_${assembly}_${regions}.tab | sed "1d" > ${basename}_on_${assembly}_${regions}.bed
cut -f1,2,3 --complement ${basename}_on_${assembly}_${regions}.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n","gene"NR"-"$1"-"$2"-"$3)}' ${basename}_on_${assembly}_${regions}.bed > ${basename}_on_${assembly}_${regions}.rowname

rm -f ${basename}_on_${assembly}_${regions}.tab
rm -f ${basename}_on_${assembly}_${regions}.npz
rm -f ${basename}_on_${assembly}_${regions}.bed

elif [[ "${regions}" == "promoter" ]]; then
echo "Generate the matrix with the value of KAS-seq density on Refseq promoters..."

multiBigwigSummary BED-file --bwfiles $KAS_seq_files --BED ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.${regions}.bed --labels $labels -p $threads -out ${basename}_on_${assembly}_Refseq.${regions}.npz --outRawCounts ${basename}_on_${assembly}_Refseq.${regions}.tab &

sed "s/nan/0/g" ${basename}_on_${assembly}_Refseq.${regions}.tab | sed "1d" > ${basename}_on_${assembly}_Refseq.${regions}.bed
bedSort ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.${regions}.bed ${assembly}_Refseq.${regions}.sort.bed
bedSort ${basename}_on_${assembly}_Refseq.${regions}.bed ${basename}_on_${assembly}_Refseq.${regions}.sort.bed
paste ${assembly}_Refseq.${regions}.sort.bed ${basename}_on_${assembly}_Refseq.${regions}.sort.bed > ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed
cut -f1,2,3,4,5,6,7,8,9 --complement ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n","gene"NR"-"$1"-"$2"-"$3"-"$4)}' ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed > ${basename}_on_${assembly}_${regions}.rowname 

rm -f ${basename}_on_${assembly}_Refseq.${regions}.npz
rm -f ${basename}_on_${assembly}_Refseq.${regions}.tab
rm -f ${basename}_on_${assembly}_Refseq.${regions}.bed
rm -f ${assembly}_Refseq.${regions}.sort.bed
rm -f ${basename}_on_${assembly}_Refseq.${regions}.sort.bed
rm -f ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed

elif [[ "${regions}" == "genebody" ]]; then
echo "Generate the matrix with the value of KAS-seq density on Refseq genebodies..."

multiBigwigSummary BED-file --bwfiles $KAS_seq_files --BED ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.${regions}.bed --labels $labels -p $threads -out ${basename}_on_${assembly}_Refseq.${regions}.npz --outRawCounts ${basename}_on_${assembly}_Refseq.${regions}.tab &

sed "s/nan/0/g" ${basename}_on_${assembly}_Refseq.${regions}.tab | sed "1d" > ${basename}_on_${assembly}_Refseq.${regions}.bed
bedSort ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.${regions}.bed ${assembly}_Refseq.${regions}.sort.bed
bedSort ${basename}_on_${assembly}_Refseq.${regions}.bed ${basename}_on_${assembly}_Refseq.${regions}.sort.bed
paste ${assembly}_Refseq.${regions}.sort.bed ${basename}_on_${assembly}_Refseq.${regions}.sort.bed > ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed
cut -f1,2,3,4,5,6,7,8,9 --complement ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n","gene"NR"-"$1"-"$2"-"$3"-"$4)}' ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed > ${basename}_on_${assembly}_${regions}.rowname

rm -f ${basename}_on_${assembly}_Refseq.${regions}.npz
rm -f ${basename}_on_${assembly}_Refseq.${regions}.tab
rm -f ${basename}_on_${assembly}_Refseq.${regions}.bed
rm -f ${assembly}_Refseq.${regions}.sort.bed
rm -f ${basename}_on_${assembly}_Refseq.${regions}.sort.bed
rm -f ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed

elif [[ "${regions}" == "terminator" ]]; then
echo "Generate the matrix with the value of KAS-seq density on Refseq terminators..."

multiBigwigSummary BED-file --bwfiles $KAS_seq_files --BED ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.${regions}.bed --labels $labels -p $threads -out ${basename}_on_${assembly}_Refseq.${regions}.npz --outRawCounts ${basename}_on_${assembly}_Refseq.${regions}.tab &

sed "s/nan/0/g" ${basename}_on_${assembly}_Refseq.${regions}.tab | sed "1d" > ${basename}_on_${assembly}_Refseq.${regions}.bed
bedSort ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.${regions}.bed ${assembly}_Refseq.${regions}.sort.bed
bedSort ${basename}_on_${assembly}_Refseq.${regions}.bed ${basename}_on_${assembly}_Refseq.${regions}.sort.bed
paste ${assembly}_Refseq.${regions}.sort.bed ${basename}_on_${assembly}_Refseq.${regions}.sort.bed > ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed
cut -f1,2,3,4,5,6,7,8,9 --complement ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n","gene"NR"-"$1"-"$2"-"$3"-"$4)}' ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed > ${basename}_on_${assembly}_${regions}.rowname

rm -f ${basename}_on_${assembly}_Refseq.${regions}.npz
rm -f ${basename}_on_${assembly}_Refseq.${regions}.tab
rm -f ${basename}_on_${assembly}_Refseq.${regions}.bed
rm -f ${assembly}_Refseq.${regions}.sort.bed
rm -f ${basename}_on_${assembly}_Refseq.${regions}.sort.bed
rm -f ${basename}_on_${assembly}_Refseq.${regions}.annotation.bed

fi

# generate matrix files for DESeq2 differential analysis.
matrix_dir=$(pwd)/${basename}_on_${assembly}_${regions}.matrix
rowname_dir=$(pwd)/${basename}_on_${assembly}_${regions}.rowname
label_dir=$(pwd)/${label_file}
diffcondition_dir=$(pwd)/${diff_condition}

Rscript --vanilla ${SH_SCRIPT_DIR}/../R/DESeq2_Diff_KAS.R ${matrix_dir} ${rowname_dir} ${label_dir} ${diffcondition_dir} 

echo "=== All done successfully"
