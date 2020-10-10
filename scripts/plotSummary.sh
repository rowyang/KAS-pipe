#!/bin/bash
# creatation: 2020-3-4
# Author: Ruitu Lyu (lvruitu@gmail.com)

set -e # Stop on error

###
### plotSummary.sh - This script is used to generate heatmap or metagene profile for KAS-seq data(bigWig files are needed).
###
### Usage:
### genes regions: plotSummary.sh <KAS_seq_files> <labels> <assembly> <threads> <basename> <regions> <plot_type> <colors> 
### peaks regions: plotSummary.sh <KAS_seq_files> <labels> <assembly> <threads> <basename> <regions> <plot_type> <colors> <peaks_list>
### Example:
### genes regions: nohup plotSummary.sh KAS_seq_files.txt labels.txt hg19 10 KAS-seq_example genebody heatmap colors.txt &
### peaks regions: nohup plotSummary.sh KAS_seq_files.txt labels.txt hg19 10 KAS-seq_example genebody heatmap colors.txt peaks_list.bed &
### 
### Options:
### <KAS_seq_files> Input the text file containing file name of KAS-seq bigWig files.
### Example: KAS.rep1.bigWig KAS.rep2.bigWig KAS.rep3.bigWig KAS.rep4.bigWig ---KAS_seq_files.txt
###
### <labels> Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
### Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files. 
### Example: KAS.rep1 KAS.rep2 KAS.rep3 KAS.rep4 ---labels.txt
### 
### <assembly> Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
###
### <threads> Input the number of threads.
###
### <basename> Input the basename of output files.
###
### <regions> Input the features you want to generate the plots(peaks, genebody, TSS, TES)
###
### <plot_type> Input the types of the summary plots(heatmap, profile).
###
### <colors> Input the text file containing color list of KAS-seq data in profile plot
### Note:The number of colors in the profile plot needs to be consistent with the number of KAS-seq bigWig files.
### The list of valid color names: https://matplotlib.org/examples/color/named_colors.html.
### Example: red blue green purple ---colors.txt
###
### For heatmap, you can input one color for all the heatmaps or colorlist for every single heatmaps
### Example: Reds ---colors.txt or Reds Oranges Blues Greens ---colors.txt
###
### <peaks_list> Input the peaks list you want to generate the summary plot(e.g. enhancers, exon). Input just when you select peaks in <regions>.
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

if [[ "$#" -lt 8 ]]; then
  echo
  echo "This script is used to create heatmap or metagene profile for KAS-seq data."
  echo

  echo "Usage:
        genes regions: plotSummary.sh <KAS_seq_files> <labels> <assembly> <threads> <basename> <regions> <plot_type> <colors>
        peaks regions: plotSummary.sh <KAS_seq_files> <labels> <assembly> <threads> <basename> <regions> <plot_type> <colors> <peaks_list>"

  echo "Example: 
        genes regions: nohup plotSummary.sh KAS_seq_files.txt labels.txt hg19 10 KAS-seq_example genebody heatmap colors.txt &
        peaks regions: nohup plotSummary.sh KAS_seq_files.txt labels.txt hg19 10 KAS-seq_example genebody heatmap colors.txt peaks_list.bed &"
  echo

fi

# check the parameters users provide to the shell script.

if test -z $1
then
   echo "please input the text file containing file names of KAS-seq bigWig files"
   exit 2
fi

if test -z $2
then
   echo "please input the text file containing the labels of KAS-seq data in <KAS_seq_files>"
   echo "note:the number of labels needs to be consistent with the number of KAS-seq bigWig files"
   exit 2
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
   echo "please input the assembly of reference genome(mm9, mm10, hg19, hg38...)"
   exit 2
fi

if test -z $4
then
   echo "please input the number of threads"
   exit 2
fi

if test -z $5
then
   echo "please input the basename of output files"
   exit 2
fi

if test -z $6
then
   echo "please input the regions you want to create the summary plot(peaks, genebody, TSS or TES)"
   exit 2
fi

if [[ "$6" != "peaks" ]] && [[ "$6" != "genebody" ]] && [[ "$6" != "TSS" ]] && [[ "$6" != "TES" ]]
then
 echo "Error: unsupported region types $6"
 exit 2
fi

if test -z $7
then
   echo "please input the plot types you want to create(heatmap or profile)"
   exit 2
fi

if [[ "$7" != "heatmap" ]] && [[ "$7" != "profile" ]]
then
 echo "Error: unsupported plot types $7"
 exit 2
fi

if [[ "$7" == "profile" ]] && test -z $8 ;then
 echo "please input the text file containing color list for the metagene profile."
 echo "note:The number of colors needs to be consistent with the number of KAS-seq bigWig files."
 echo "refer to the list of valid color at https://matplotlib.org/examples/color/named_colors.html"
 exit 2
elif [[ "$7" == "heatmap" ]] && test -z $8 ;then
 echo "please input the text file containing colorlist of heatmap(Reds, Blues, Greens...)"
 echo "you can specify one color(e.g. Reds) for whole heatmap, or colorlist(Reds, Blues, Greens...) for every single panel, but the number of colors need to be consistent with number of panels."
 exit 2
fi

number_of_colors=$( head -1 $8 | awk '{print NF}' - )
if [[ "$7" == "profile" ]] && [[ ${number_of_colors} != ${number_of_samples} ]]
then
   echo "error:the number of colors isn't consistent with the number of samples"  
   exit
fi

if [[ "$6" == "peaks" ]] && test -z $9 ;then
	echo "please input the peaks list you want to generate the summary plot(e.g. enhancers, exon)."
 exit 2
fi

# parameters for creating heatmap and metagene profile plot
KAS_seq_files=$(cat $1)
labels=$(cat $2)
assembly=$3
threads=$4
basename=$5
regions=$6
plot_type=$7
colors=$(cat $8)
peaks_list=$9
SH_SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)


if [[ "${regions}" == "genebody" ]]; then

# deeptools: generate the matrix file.
computeMatrix scale-regions -R ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.bed -S $KAS_seq_files -b 3000 -a 3000 --regionBodyLength 6000 --skipZeros --samplesLabel $labels --missingDataAsZero -p $threads -o ${basename}_on_${assembly}_${regions}.matrix.gz 
 # generate the heatmap plot
 if [[ "${plot_type}" == "heatmap" ]]; then
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.png --plotFileFormat png 
 
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.svg --plotFileFormat svg
 
 elif [[ "${plot_type}" == "profile" ]]; then
#The list of valid color names:https://matplotlib.org/examples/color/named_colors.html
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.png --samplesLabel $labels --colors $colors --plotFileFormat png  --perGroup --plotHeight 7 --plotWidth 9 
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.svg --samplesLabel $labels --colors $colors --plotFileFormat svg  --perGroup --plotHeight 7 --plotWidth 9
 fi

elif [[ "${regions}" == "TSS" ]]; then
computeMatrix reference-point --referencePoint TSS -R ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.bed -S $KAS_seq_files -b 5000 -a 5000 --skipZeros --samplesLabel $labels --missingDataAsZero -p $threads -o ${basename}_on_${assembly}_${regions}.matrix.gz 
 if [[ "${plot_type}" == "heatmap" ]]; then
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.png --plotFileFormat png   
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.svg --plotFileFormat svg
 
 elif [[ "${plot_type}" == "profile" ]]; then
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.png --samplesLabel $labels --colors $colors --plotFileFormat png  --perGroup --plotHeight 7 --plotWidth 9
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.svg --samplesLabel $labels --colors $colors --plotFileFormat svg  --perGroup --plotHeight 7 --plotWidth 9
 fi

elif [[ "${regions}" == "TES" ]]; then
computeMatrix reference-point --referencePoint TES -R ${SH_SCRIPT_DIR}/../Annotation/${assembly}_Refseq.bed -S $KAS_seq_files -b 5000 -a 5000 --skipZeros --samplesLabel $labels --missingDataAsZero -p $threads -o ${basename}_on_${assembly}_${regions}.matrix.gz 
 if [[ "${plot_type}" == "heatmap" ]]; then
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.png --plotFileFormat png
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.svg --plotFileFormat svg
 
 elif [[ "${plot_type}" == "profile" ]]; then
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.png --samplesLabel $labels --colors $colors --plotFileFormat png  --perGroup --plotHeight 7 --plotWidth 9
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.svg --samplesLabel $labels --colors $colors --plotFileFormat svg  --perGroup --plotHeight 7 --plotWidth 9 
 fi

elif [[ "${regions}" == "peaks" ]]; then
computeMatrix reference-point --referencePoint center -R $peaks_list -S $KAS_seq_files -b 5000 -a 5000 --skipZeros --samplesLabel $labels --missingDataAsZero -p $threads -o ${basename}_on_${assembly}_${regions}.matrix.gz                 
 if [[ "${plot_type}" == "heatmap" ]]; then
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.png --plotFileFormat png
 plotHeatmap -m ${basename}_on_${assembly}_${regions}.matrix.gz --colorMap $colors --boxAroundHeatmaps no --whatToShow "heatmap and colorbar" -out ${basename}_on_${assembly}_${regions}_heatmap.svg --plotFileFormat svg

 elif [[ "${plot_type}" == "profile" ]]; then
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.png --samplesLabel $labels --colors $colors --plotFileFormat png  --perGroup --plotHeight 7 --plotWidth 9
 plotProfile -m ${basename}_on_${assembly}_${regions}.matrix.gz -out ${basename}_on_${assembly}_${regions}_Profile.svg --samplesLabel $labels --colors $colors --plotFileFormat svg  --perGroup --plotHeight 7 --plotWidth 9                                 
 fi

fi

echo "=== All done successfully ==="
