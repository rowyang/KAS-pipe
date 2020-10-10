#!/bin/bash
# creatation: 2019-5-14
# Author: Ruitu Lyu (lvruitu@gmail.com)

###
### make_UCSC_files.sh - This script is used to generate UCSC genome browser submit ready file.
### normalized bedGraph file is needed.
###
### Usage: make_UCSC_files.sh <trackname> <KAS_seq_file>.
###
### Example: nohup make_UCSC_files.sh trackname.txt KAS_seq_file.txt &
###
### <trackname> Input the text file containing the track names of KAS-seq data you want to show on UCSC genome browser.
### Example: KAS-seq.rep1 KAS-seq.rep2  ---trackname.txt
###
### <KAS_seq_file> Input the text file containing the names of normalized KAS-seq bedGraph files.
### Example: KAS-seq.rep1.nor.bg KAS-seq.rep2.nor.bg  ---KAS_seq_file.txt
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
  echo "This script is used to generate UCSC genome browser submit ready file."
  echo
  echo "Usage: make_UCSC_files.sh <trackname> <KAS_seq_file>"
  echo " "
  echo "Example: nohup make_UCSC_files.sh trackname.txt KAS_seq_file.txt &"
  echo " "
  echo "Make sure that your bedGraph file have less than 50000000 lines, otherwise only part of your KAS-seq data can be displayed on UCSC." 
  echo
fi

if test -z $1
then
   echo "please input the text file containing the track names of KAS-seq data you want to show on UCSC genome browser."
   exit
fi

if test -z $2
then
   echo "please input the text file containing the names of normalized KAS-seq bedGraph files."
   echo "Note: Make sure your bedGraph file have less than 50000000 lines, otherwise only part of your KAS-seq data can be displayed on UCSC."
   exit
fi

number_of_tracks=$(head -1 $1 | awk '{print NF}' - )
number_of_samples=$(head -1 $2 | awk '{print NF}' - )

if [[ ${number_of_tracks} != ${number_of_samples} ]]
then
   echo "error:the number of tracks isn't consistent with the number of samples"
   exit
fi

trackname=$1
KAS_seq_file=$2

for ((i=1; i<=${number_of_samples}; i++))
do
    sample_selected=$(awk '{print $'$i' }' $KAS_seq_file)
    track_selected=$(awk '{print $'$i' }' $trackname)
    KAS_seq_basename=$(basename ${sample_selected} .bg)
echo track type=bedGraph name=\"${track_selected}.$(date +%Y-%m-%d)\" description=\"${track_selected}.$(date +%Y-%m-%d)\" visibility=full > ${track_selected}.track
head -49999999 $sample_selected > ${KAS_seq_basename}.filter.bg
cat ${track_selected}.track ${KAS_seq_basename}.filter.bg > ${KAS_seq_basename}.UCSC.bg
gzip ${KAS_seq_basename}.UCSC.bg 
rm -f ${KAS_seq_basename}.filter.bg 
rm -f ${track_selected}.track 

done

echo "=== All done successfully."
