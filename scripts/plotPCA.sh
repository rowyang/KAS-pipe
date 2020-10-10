#!/bin/bash
# creatation: 2020-1-14
# Author: Ruitu Lyu (lvruitu@gmail.com)

# Stop on error
set -e

###
### plotPCA.sh - This script is used to plot PCA analysis for KAS-seq data(bigWig files are needed).
###
### Usage:
### Bins mode: plotPCA.sh <KAS_seq_files> <labels> <colors> <bins> <basename> <threads>
### Peaks mode: plotPCA.sh <KAS_seq_files> <labels> <colors> <peaks> <basename> <threads> <peaks_list>
###
### Example:
### Bins mode: nohup plotPCA.sh KAS_seq_files.txt labels.txt colors.txt bins KAS-seq 10 &
### Peaks mode: nohup plotPCA.sh KAS_seq_files.txt labels.txt colors.txt peaks KAS-seq 10 peaks_list.bed &
###
### Options:
### <KAS_seq_files> Input the text file containing file name of KAS-seq bigWig files.
### Example: KAS.rep1.bigWig KAS.rep2.bigWig KAS.rep3.bigWig KAS.rep4.bigWig ---KAS_seq_files.txt
###
### <labels> Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
### Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files. 
### Example: KAS.rep1 KAS.rep2 KAS.rep3 KAS.rep4 ---labels.txt
###
### <colors> Input the text file containing color list for the dots of KAS-seq data in PCA plot.
### Note:The number of colors needs to be consistent with the number of KAS-seq bigWig files.
### The list of valid color names: https://matplotlib.org/examples/color/named_colors.html.
### Example: red blue green purple ---colors.txt
###
### <regions> Input the mode you want to define the KAS-seq signal enriched regions(bins, peaks).
###
### <threads> Input the number pf threads.
###
### <basename> Input the basename of output files.
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


if [[ "$#" -lt 6 ]]; then
  echo
  echo "This script is used to plot PCA for KAS-seq data."
  echo "BigWig files were needed"

  echo "Usage: 
Bins mode: plotPCA.sh <KAS_seq_files> <labels> <colors> <bins> <basename> <threads>

Peaks mode: plotPCA.sh <KAS_seq_files> <labels> <colors> <peaks> <basename> <threads> <peaks_list>"

  echo "Example: 
Bins mode: nohup plotPCA.sh KAS_seq_files.txt labels.txt colors.txt bins KAS-seq 10 &

Peaks mode: nohup plotPCA.sh KAS_seq_files.txt labels.txt colors.txt peaks KAS-seq 10 peaks_list.bed &"
  echo

fi

# check the parameters users provide to the shell script.
if test -z $1 
   then
   echo "please input the text file containing the file name of KAS-seq bigWig files" 
   exit
fi

if test -z $2
   then
   echo "please input the text file containing the labels of KAS-seq data in <KAS_seq_files>"
   echo "note:The number of labels needs to be consistent with the number of KAS-seq bigWig files."
   exit
fi 

number_of_samples=$( head -1 $1 | awk '{print NF}' - )
number_of_labels=$( head -1 $2 | awk '{print NF}' - )

if [[ ${number_of_labels} != ${number_of_samples} ]]
then
   echo "error:the number of labels isn't consistent with the number of samples"  
   exit
fi

if test -z $3
   then
   echo "please input the text file containing color list for the dots of KAS-seq data in PCA plot."
   echo "note:The number of colors needs to be consistent with the number of KAS-seq bigWig files."
   echo "refer to the list of valid color at https://matplotlib.org/examples/color/named_colors.html"
   exit
fi

number_of_colors=$( head -1 $3 | awk '{print NF}' - )
if [[ ${number_of_colors} != ${number_of_samples} ]]
then
   echo "error:the number of colors isn't consistent with the number of samples."
   exit
fi

if test -z $4
   then
   echo "please input the mode you want to define the KAS-seq signal enriched regions(bins, peaks)."
   exit
fi

if [[ "$4" != "bins" ]] && [[ "$4" != "peaks" ]]; then
  echo "Error: unsupported mode $4."
  exit 1
  else
  echo " "
fi

if test -z $5
   then
   echo "please input the basename of output files."
   exit
fi

if test -z $6
   then
   echo "please input the number of threads."
   exit
fi

if [[ "$4" == "peaks" ]] && test -z $7;then 
   echo "please input merged KAS-seq peaks list(mergeBed -i Sorted_total_KAS-seq_peak.bed > merged_KAS-seq_peaks.bed)."
   exit
   else 
   echo " "
fi

##########################################
KAS_seq_files=$(cat $1)
labels=$(cat $2)
colors=$(cat $3)
regions=$4
basename=$5
threads=$6
peaks_list=$7

# setup the markers of dots in the PCA plot.
markers=$(echo | awk -v number="${number_of_samples}" 'BEGIN{for(i=1; i<=number; i++) print "o"}' | xargs)

#generate the table of KAS-seq data on bins or peaks.

if [[ "${regions}" == "bins" ]]; then

multiBigwigSummary bins -b $KAS_seq_files --labels $labels -out ${basename}_on_10kb_bin.npz --outRawCounts ${basename}_on_10kb_bin.tab 

elif [[ "${regions}" == "peaks" ]]; then
multiBigwigSummary BED-file --bwfiles $KAS_seq_files --BED $peaks_list --labels $labels -out ${basename}_on_merged_KAS-peaks.npz --outRawCounts ${basename}_on_merged_KAS-peaks.tab

fi

#generate the PCA plot.

if [[ "${regions}" == "bins" ]]; then

plotPCA -in ${basename}_on_10kb_bin.npz --plotHeight 15 --plotWidth 10 --markers $markers --colors $colors -o ${basename}_on_10kb_bin_PCA.svg --plotFileFormat svg 
plotPCA -in ${basename}_on_10kb_bin.npz --plotHeight 15 --plotWidth 10 --markers $markers --colors $colors -o ${basename}_on_10kb_bin_PCA.png --plotFileFormat png 

elif [[ "${regions}" == "peaks" ]]; then

plotPCA -in ${basename}_on_merged_KAS-peaks.npz --plotHeight 15 --plotWidth 10 --markers $markers --colors $colors -o ${basename}_on_merged_KAS-peaks_PCA.svg --plotFileFormat svg 
plotPCA -in ${basename}_on_merged_KAS-peaks.npz --plotHeight 15 --plotWidth 10 --markers $markers --colors $colors -o ${basename}_on_merged_KAS-peaks_PCA.png --plotFileFormat png

fi

echo "=== All done successfully."

