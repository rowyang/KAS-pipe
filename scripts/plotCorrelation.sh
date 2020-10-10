#!/bin/bash
# creatation: 2020-5-23
# Author: Ruitu Lyu (lvruitu@gmail.com)

# Stop on error
set -e

###
### plotCorrelation.sh - This script is used to generate correlation plot for KAS-seq data.
### BigWig files of KAS-seq data were needed
###
### Usage:
### Bins mode: plotCorrelation.sh <KAS_seq_files> <labels> <bins> <assembly> <basename> <threads> <plot_types>
### Peaks mode: plotCorrelation.sh <KAS_seq_files> <labels> <peaks> <assembly> <basename> <threads> <plot_types> <peaks_list>
###
### Example:
### Bins mode: nohup plotCorrelation.sh KAS_seq_files.txt labels.txt bins hg19 KAS-seq 10 heatmap &
### Peaks mode: nohup plotCorrelation.sh KAS_seq_files.txt labels.txt peaks hg19 KAS-seq 10 heatmap peaks_list.bed &
###
### Options:
### <KAS_seq_files> Input the text file containing the name of KAS-seq bigWig files.
### Example: KAS.rep1.bigWig KAS.rep2.bigWig KAS.rep3.bigWig KAS.rep4.bigWig ---KAS_seq_files.txt
###
### <labels> Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
### Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files.
### Example: KAS.rep1 KAS.rep2 KAS.rep3 KAS.rep3 ---labels.txt
###
### <regions> Input the regions you want to use to do the correlation analysis(e.g. bins or peaks).
###
### <assembly> Input the assembly of reference genome you use for KAS-seq data mapping.
###
### <basename> Input the basename of output files.
###
### <threads> Input the number of threads.
###
### <plot_types> Input the types of plot you want to generate(e.g. scatterplot or heatmap).
### If you want to plot heatmap, please make sure if you have more than 2 samples.
###
### <peaks_list> Input the merged KAS-seq peaks list(mergeBed -i Sorted_total_KAS-seq_peak.bed > merged_KAS-seq_peaks.bed).
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
  echo "This script is used to generate correlation plot for KAS-seq data."
  echo "BigWig files of KAS-seq data were needed"

  echo "Usage:
Bins mode: plotCorrelation.sh <KAS_seq_files> <labels> <bins> <assembly> <basename> <threads> <plot_types>
Peaks mode: plotCorrelation.sh <KAS_seq_files> <labels> <bins> <assembly> <basename> <threads> <plot_types> <peaks_list>"

  echo "Example:
Bins mode: nohup plotCorrelation.sh KAS_seq_files.txt labels.txt bins hg19 KAS-seq 10 scatterplot(or heatmap) &
Peaks mode: nohup plotCorrelation.sh KAS_seq_files.txt labels.txt peaks hg19 KAS-seq 10 scatterplot(or heatmap) peaks_list.bed &"
  echo
fi

# check the parameters users provide to the shell script.

if test -z $1
   then
   echo "please input the text file containing the name of KAS-seq bigWig files"
   exit
fi

if test -z $2
   then
   echo "please input the text file containing the labels of KAS-seq data in <KAS_seq_files>"
   echo "the number of labels need to be consistent with the number of KAS-seq bigWig files."
   exit
fi

number_of_samples=$(awk '{print NF}' $1 )
number_of_labels=$(awk '{print NF}' $2 )

if [[ ${number_of_labels} != ${number_of_samples} ]]
then
   echo "error:the number of labels isn't consistent with the number of samples"
   exit
fi

if test -z $3
   then
   echo "please input the regions you want to use to do the correlation analysis(e.g. bins or peaks)."
   exit
fi

if [[ $3 != "bins" ]] && [[ $3 != "peaks" ]]
then
   echo "error:unsupported types of regions $3"
   exit
fi

if test -z $4
   then
   echo "please input the assembly of reference genome you use for KAS-seq data mapping."
   exit
fi

if test -z $5
   then
   echo "please input the basename of the output files."
   exit
fi

if test -z $6
   then
   echo "please input the number of threads."
   exit
fi

if test -z $7
   then
   echo "please input the types of plot you want to generate(e.g. scatterplot or heatmap); if you want to plot heatmap, please make sure if you have more than 2 samples."
   exit
fi

if [[ ${7} != "scatterplot" ]] && [[ ${7} != "heatmap" ]]
   then
   echo "Error: unsupported types of plot $7"
   exit
fi

if [[ "$3" == "peaks" ]] && test -z $8;then 
   echo "please input merged KAS-seq peaks list(mergeBed -i Sorted_total_KAS-seq_peak.bed > merged_KAS-seq_peaks.bed)"
   exit
   else 
   echo " "
fi

# the options
KAS_seq_files=$(cat $1)
labels=$(cat $2)
regions=$3
assembly=$4
basename=$5
threads=$6
plot_types=$7
peaks_list=$8

SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# generate the matrix of KAS-seq data on 1kb bins
if [[ "${regions}" == "bins" ]]; then
echo "generate the matrix of KAS-seq data on 1kb bins......"

# multiBigwigSummary bins -b $KAS_seq_files --labels $labels --binSize 1000 -p $threads --blackListFileName ${SH_SCRIPT_DIR}/../blacklist/${assembly}-blacklist.bed -out ${basename}_on_1kb_bins.npz --outRawCounts ${basename}_on_1kb_bins.tab

multiBigwigSummary bins -b $KAS_seq_files --labels $labels --binSize 1000 -p $threads -out ${basename}_on_1kb_bins.npz --outRawCounts ${basename}_on_1kb_bins.tab

sed "s/nan/0/g" ${basename}_on_1kb_bins.tab | sed "1d" > ${basename}_on_1kb_bins.bed 

#calculate the average value of very single row in the table. 
awk 'BEGIN{if(NR>0) a[NR]=0}{if(NR>0) for(i=4; i<=NF; i++) a[NR]+=$i}END{for(j in a) print  a[j]/NF }' ${basename}_on_1kb_bins.bed > ${basename}_on_1kb_bins.average
#filter the bins with averaged KAS-seq density lower than 10.
paste ${basename}_on_1kb_bins.average ${basename}_on_1kb_bins.bed | awk '$1>=10 {print $0}' > ${basename}_on_1kb_bins.filter.bed
cut -f1,2,3,4 --complement ${basename}_on_1kb_bins.filter.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n",$2"-"$3"-"$4)}' ${basename}_on_1kb_bins.filter.bed > ${basename}_on_${assembly}_${regions}.rowname

rm -f ${basename}_on_1kb_bins.tab 
rm -f ${basename}_on_1kb_bins.npz
rm -f ${basename}_on_1kb_bins.bed
rm -f ${basename}_on_1kb_bins.average 
rm -f ${basename}_on_1kb_bins.filter.bed

# generate the matrix of KAS-seq data on peaks
elif [[ "${regions}" == "peaks" ]]; then
echo "generate the matrix of KAS-seq data on peaks......"
peaks_list_prefix=$(basename ${peaks_list} .bed)

multiBigwigSummary BED-file --bwfiles $KAS_seq_files --BED $peaks_list --labels $labels -p $threads -out ${basename}_on_${peaks_list_prefix}.npz --outRawCounts ${basename}_on_${peaks_list_prefix}.tab 

sed "s/nan/0/g" ${basename}_on_${peaks_list_prefix}.tab | sed "1d" > ${basename}_on_${peaks_list_prefix}.bed
cut -f1,2,3 --complement ${basename}_on_${peaks_list_prefix}.bed > ${basename}_on_${assembly}_${regions}.matrix
awk '{printf("%s\n",$1"-"$2"-"$3)}' ${basename}_on_${peaks_list_prefix}.bed > ${basename}_on_${assembly}_${regions}.rowname

rm -f ${basename}_on_${peaks_list_prefix}.npz
rm -f ${basename}_on_${peaks_list_prefix}.tab
rm -f ${basename}_on_${peaks_list_prefix}.bed

fi

matrix_dir=$(pwd)/${basename}_on_${assembly}_${regions}.matrix
rowname_dir=$(pwd)/${basename}_on_${assembly}_${regions}.rowname
labels_dir=$(pwd)/$2

if [[ "${plot_types}" == "heatmap" ]]; then
Rscript --vanilla ${SH_SCRIPT_DIR}/../R/Plotcorr_heatmap.R ${matrix_dir} ${rowname_dir} ${labels_dir}

elif [[ "${plot_types}" == "scatterplot" ]]; then
   if [ "$number_of_samples" -eq 2 ]; then
   Rscript --vanilla ${SH_SCRIPT_DIR}/../R/Plotcorr_scatterplot.R ${matrix_dir} ${rowname_dir} ${labels_dir}
   elif [ "$number_of_samples" -gt 2 ]; then
   Rscript --vanilla ${SH_SCRIPT_DIR}/../R/Plotcorr_scatterplot_matrix.R ${matrix_dir} ${rowname_dir} ${labels_dir}
   elif [ "$number_of_samples" -eq 1 ]; then
   echo "please make sure the number of samples for correlation analysis must be over 2."
   exit
   fi
fi

# delete the matrix and rowname files
rm -f ${basename}_on_${assembly}_${regions}.matrix
rm -f ${basename}_on_${assembly}_${regions}.rowname

echo "=== All done successfully"
