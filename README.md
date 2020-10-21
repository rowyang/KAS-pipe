# KAS-pipe
KAS-pipe is an analysis pipeline for KAS-seq data. KAS-seq is a kethoxal-assisted single-stranded DNA sequencing (KAS-seq) approach, based on the fast and specific reaction between N3-kethoxal and guanines in ssDNA. KAS-seq allows rapid (within 5 min), sensitive and genome-wide capture and mapping of ssDNA produced by transcriptionally active RNA polymerases or other processes in situ using as few as 1,000 cells. KAS-seq can also enable definition of a group of enhancers that are single-stranded and enrich unique sequence motifs. Overall, KAS-seq facilitates fast and accurate analysis of transcription dynamics and enhancer activities simultaneously in both low-input and high-throughput manner. KAS-pipe as a analysis pipeline for KAS-seq data, which provides many shell scripts for KAS-seq data processing, for example, reference genome index setup, adapter sequence trimming, alignment, differential analysis and so on.   

![image](https://github.com/Ruitulyu/KAS-pipe/blob/master/images/Schematic%20diagram%20for%20KAS-seq.png)

# Table of Contents
----------------------------------------
- [Dependencies](#Dependencies)
- [Installation](#Installation)
- [Adapter and low quality sequence trimming](#Adapter-and-low-quality-sequence-trimming)
- [Map KAS-seq data to reference genome](#Map-KAS-seq-data-to-reference-genome)
- [KAS-seq peaks calling](#KAS-seq-peaks-calling)
- [Plot heatmap or metagene profiles](#Plot-heatmap-or-metagene-profiles)
- [KAS-seq correlation analysis](#KAS-seq-correlation-analysis)
- [Differential KAS-seq analysis](#Differential-KAS-seq-analysis)
- [Plot principal component analysis(PCA)](#Plot-principal-component-analysis)
- [Introduction for other provided shell scripts in KAS-pipe](#Introduction-for-other-provided-shell-scripts-in-KAS-pipe)
- [Define single-stranded enhancers](#Define-single-stranded-enhancers)
- [Citation](#Citation)


# Dependencies
- samtools ==1.9
- bedtools ==2.29.0
- picard ==2.20.7
- fastqc

- ucsc-fetchchromsizes ==357 
- ucsc-bedgraphtobigwig ==357
- ucsc-bedsort

- r ==3.5.1
- r-devtools
- r-corrplot
- r-RColorBrewer
- bioconductor-rsamtools
- bioconductor-deseq2

- bowtie2 ==2.3.4.3
- bowtie
- deeptools ==3.3.1
- cutadapt ==2.5
- trim-galore ==0.6.5
- macs2 ==2.2.4

- java-jdk
- python3

# Installation
Please make sure you have [miniconda3](https://docs.conda.io/en/latest/miniconda.html) or [anaconda3](https://www.anaconda.com/products/individual) environments in your server in order to use the provided shell script to install the dependencies. Or you can follow the user guide to accomplish the conda installation: https://docs.conda.io/projects/conda/en/latest/user-guide/install/.

## Install KAS-pipe by cloning this repository
```Swift
$ git clone https://github.com/Ruitulyu/KAS-pipe
$ cd KAS-pipe
$ chmod 755 setup.sh
$ ./setup.sh
# Install conda environment.
$ install_conda_env.sh
```
## Install reference genome on your linux
```Swift
# Please create a directory where you want to install your reference genome and index.
$ mkdir -p ~/Software/
$ cd ~/Software/Genome/
$ build_reference_genome.sh hg19 ~/Software/Genome/

build_reference_genome.sh - This script is used to install reference genome <assembly> in a directory <dest_dir>.
Usage: build_reference_genome.sh <assembly> <dest_dir>
Example: nohup build_reference_genome.sh hg19 /your/genome/data/path/ &

Options:
<assembly>               Input the assembly of the reference genome you want to download and install(mm9, mm10, hg19, hg38...).
<dest_dir>               Input the path of the directory that you want to install your interested genome in your server.
-h or --help             Print the help.
```
# Usage:

## Adapter and low quality sequence trimming
trim_adapter.sh - This script is used to trim adapter and low quality sequence from Raw KAS-seq data.
```Swift
Single_end: trim_adapter.sh <Adapter_type> <Minimum_reads_length> <threads> <single> <raw_fastq_read>
Paired_end: trim_adapter.sh <Adapter_type> <Minimum_reads_length> <threads> <paired> <raw_fastq_read1> <raw_fastq_read2>

Example:
nohup trim_adapter.sh illumina 30 10 single raw_fastq_read1.fastq.gz &
nohup trim_adapter.sh illumina 30 10 paired raw_fastq_read1.fastq.gz raw_fastq_read2.fastq.gz &

Options:
<adapter_type>           Input the adapter types during KAS-seq libraries construction(illumina, nextera, small_rna).
<min_reads_length>       Discard reads that became shorter than length <min_reads_length> because of either quality or adapter trimming.
<threads>                Input the number of cores to be used for trimming.
<paired_or_single>       Specify the mode of sequencing data(single, paired).
<raw_fastq_read1>        Input the single-end raw fastq file or read 1 of paired-end raw fastq files.
<raw_fastq_read2>        Input the read 2 of paired-end raw fastq files.
-h or --help             Print the help.
Note: This shell script invokes the trim-galore, please refer http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/ for more information. 
```

## Map KAS-seq data to reference genome
map_KAS-seq.sh - This script is used to map KAS-seq data to the reference genome.
```Swift
Usage:
Single_end: map_KAS-seq.sh <bowtie2_index_path> <threads> <basename> <assembly> <single> <raw_fastq_read>
Paired_end: map_KAS-seq.sh <bowtie2_index_path> <threads> <basename> <assembly> <paired> <raw_fastq_read1> <raw_fastq_read2>

Example:
Single_end: nohup map_KAS-seq.sh /Genome/hg19_Bowtie2Index/hg19 10 KAS-seq_data hg19 single KAS-seq.single.fastq.gz &
Paired_end: nohup map_KAS-seq.sh /Genome/hg19_Bowtie2Index/hg19 10 KAS-seq_data hg19 paired KAS-seq.paired.R1.fastq.gz KAS-seq.paired.R2.fastq.gz &

Options:
<bowtie2_index_path>      Input the path of reference genome bowtie2 index.
<threads>                 Input the number of threads.
<basename>                Input the basename of KAS-seq_mapping.sh output files.
<assembly>                Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
<paired_or_single>        Specify the mode of KAS-seq data alignment(single, paired).
<raw_fastq_read1>         Input the single-end KAS-seq fastq file or read 1 of paired-end KAS-seq fastq files.
<raw_fastq_read2>         Input the read 2 of paired-end KAS-seq fastq files.
-h or --help              Print the help.
Note: map_KAS-seq.sh will generate KAS-seq deduplicated mapped reads(bam and bed files), density files(bedGraph file) and mapping summary file.

If you want to transfer normalized bedGraph file to bigWig file, please refer to the provided shell scripts --normalize_KAS-seq.sh & --make_BigWig_files.sh.
```

## KAS-seq peaks calling
call_KAS-seq_peaks.sh - This script is used to call peaks for KAS-seq data.
```Swift
# Bed files or indexed bam files are needed for KAS-seq peaks calling.

Usage:
regular peaks: call_KAS-seq_peaks.sh <KAS_seq_files> <Input_files> <regular> <basename> <genome_size>
broad peaks: call_KAS-seq_peaks.sh <KAS_seq_files> <Input_files> <broad> <basename> <genome_size>

Example:
nohup call_KAS-seq_peaks.sh KAS_seq_files.txt Input_files.txt regular KAS-seq_regular hg &
nohup call_KAS-seq_peaks.sh KAS_seq_files.txt Input_files.txt broad KAS-seq_broad hg &

Options:
<KAS_seq_files>           Input the text file containing the name of KAS-seq IP bed or indexed bam files generated by map_KAS-seq.sh.
Example: KAS.rep1.bed KAS.rep2.bed KAS.rep3.bed        ---KAS_seq_files.txt
<Input_files>             Input the text file containing the name of KAS-seq Input bed or indexed bam files..
Example: Input.rep1.bed Input.rep2.bed Input.rep3.bed  ---Input_files.txt
<regular_or_broad>        Specify regular or broad to tell macs2 that if put nearby highly enriched regions into a broad region with loose cutoff.
<basename>                Input the basename of output files.
<genome_size>             Input mappable genome size or effective genome size which is defined as the genome size which can be sequenced(hs, mm, ce, dm).
Note: hs for Homo sapiens, mm for Mus musculus, ce for Caenorhabditis elegans, dm for Drosophila melanogaster.
-h or --help              Print the help.
```

## Plot heatmap or metagene profiles
plotSummary.sh - This script is used to generate heatmap or metagene profile for KAS-seq data(bigWig files are needed).
```Swift
Usage:
genes regions: plotSummary.sh <KAS_seq_files> <labels> <assembly> <threads> <basename> <regions> <plot_type> <colors> 
peaks regions: plotSummary.sh <KAS_seq_files> <labels> <assembly> <threads> <basename> <regions> <plot_type> <colors> <peaks_list>

Example:
genes regions: nohup plotSummary.sh KAS_seq_files.txt labels.txt hg19 10 KAS-seq_example genebody heatmap colors.txt &
peaks regions: nohup plotSummary.sh KAS_seq_files.txt labels.txt hg19 10 KAS-seq_example genebody heatmap colors.txt peaks_list.bed &

Options:
<KAS_seq_files>           Input the text file containing file name of KAS-seq bigWig files.
Example: KAS.rep1.bigWig KAS.rep2.bigWig KAS.rep3.bigWig KAS.rep4.bigWig ---KAS_seq_files.txt

<labels>                  Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files. 
Example: KAS.rep1 KAS.rep2 KAS.rep3 KAS.rep4 ---labels.txt

<assembly>                Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
<threads>                 Input the number of threads.
<basename>                Input the basename of output files.
<regions>                 Input the features you want to generate the plots(peaks, genebody, TSS, TES)
<plot_type>               Input the types of the summary plots(heatmap, profile).
<colors>                  Input the text file containing color list of KAS-seq data in profile plot
Note:The number of colors in the profile plot needs to be consistent with the number of KAS-seq bigWig files.
The list of valid color names: https://matplotlib.org/examples/color/named_colors.html.
Example: red blue green purple ---colors.txt

For heatmap, you can input one color for all the heatmaps or colorlist for every single heatmaps
Example: Reds ---colors.txt or Reds Oranges Blues Greens ---colors.txt

<peaks_list>              Input the peaks list you want to generate the summary plot(e.g. enhancers, exon). Input just when you select peaks in <regions>.
-h or --help              Print the help.
```
Successful KAS-seq data:

- Profile on genebody
  
<img src="https://github.com/Ruitulyu/KAS-pipe/blob/master/images/KAS-seq_on_hg19_Refseq.mRNA.Profile.png" width="300" height="250">
  
- Heatmap on genebody
  
<img src="https://github.com/Ruitulyu/KAS-pipe/blob/master/images/KAS-seq_on_hg19_Refseq.mRNA.heatmap.png" width="300" height="500">

## KAS-seq correlation analysis
plotCorrelation.sh - This script is used to generate correlation plot for KAS-seq data.
```Swift
Note: BigWig files of KAS-seq data were needed
Usage:
Bins mode: plotCorrelation.sh <KAS_seq_files> <labels> <bins> <assembly> <basename> <threads> <plot_types>
Peaks mode: plotCorrelation.sh <KAS_seq_files> <labels> <peaks> <assembly> <basename> <threads> <plot_types> <peaks_list>

Example:
Bins mode: nohup plotCorrelation.sh KAS_seq_files.txt labels.txt bins hg19 KAS-seq 10 heatmap &
Peaks mode: nohup plotCorrelation.sh KAS_seq_files.txt labels.txt peaks hg19 KAS-seq 10 heatmap peaks_list.bed &

Options:
<KAS_seq_files>          Input the text file containing the name of KAS-seq bigWig files.
Example: KAS.rep1.bigWig KAS.rep2.bigWig KAS.rep3.bigWig KAS.rep4.bigWig ---KAS_seq_files.txt

<labels>                 Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files.
Example: KAS.rep1 KAS.rep2 KAS.rep3 KAS.rep3 ---labels.txt

<regions>                Input the regions you want to use to do the correlation analysis(e.g. bins or peaks).
<assembly>               Input the assembly of reference genome you use for KAS-seq data mapping.
<basename>               Input the basename of output files.
<threads>                Input the number of threads.
<plot_types>             Input the types of plot you want to generate(e.g. scatterplot or heatmap).
If you want to plot heatmap, please make sure if you have more than 2 samples.

<peaks_list>             Input the merged KAS-seq peaks list(mergeBed -i Sorted_total_KAS-seq_peak.bed > merged_KAS-seq_peaks.bed).
-h or --help             Print the help.
```

## Differential KAS-seq analysis
diff_KAS-seq.sh - This script is used to identify regions with differential KAS-seq signal.
```Swift
# KAS-seq bigWig files are needed.
Usage:
gene regions: diff_KAS-seq.sh <KAS_seq_files> <labels> <regions> <assembly> <basename> <threads> <diff_condition>
peak regions: diff_KAS-seq.sh <KAS_seq_files> <labels> <regions> <assembly> <basename> <threads> <diff_condition> <peaks_list>

Example:
gene regions: nohup diff_KAS-seq.sh KAS_seq_files.txt labels.txt promoter hg19 KAS-seq_treat_vs_DMSO 10 diff_condition.txt &
peak regions: nohup diff_KAS-seq.sh KAS_seq_files.txt labels.txt peaks hg19 KAS-seq_treat_vs_DMSO 10 diff_condition.txt peaks_list.bed &

Options:
<KAS_seq_files>            Input the text file containing the file name of KAS-seq bigWig files.
Example: KAS.treated.rep1.bigWig KAS.treated.rep2.bigWig KAS.DMSO.rep1.bigWig KAS.DMSO.rep2.bigWig ---KAS_seq_files.txt

<labels>                   Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files.
Example: KAS.treated.rep1 KAS.treated.rep2 KAS.DMSO.rep1 KAS.DMSO.rep2 ---labels.txt

<regions>                  Input the features you want to use for KAS-seq differential analysis(bins, peaks, promoter, genebody, terminator).
<assembly>                 Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
<basename>                 Input the basename of output files generated from this shell script.
<threads>                  Input the number of threads you want to use.
<diff_condition>           Input the condition table(tab delimited file) you want to use for KAS-seq differential anlsysis.
Example:              condition
KAS.treated.rep1      treated
KAS.treated.rep2      treated
KAS.DMSO.rep1         DMSO
KAS.DMSO.rep2         DMSO             ---diff_condition.txt

<peaks_list>               Input the peaks list only you specify peaks in <regions>(e.g. enhancers, KAS-seq peaks...).
-h or --help               Print the help.
Note: diff_KAS-seq.sh uses DESeq2 package to do statistical test.

diff_KAS-seq.sh outputs two files containing the peaks, bins or genes list with differential KAS-seq signal. 
---treated_vs_untreated_DESeq2_output.csv
---DE.KAS_treated_vs_untreated_DESeq2_Fold1.5_padj0.01_output.csv
```
## Plot principal component analysis
plotPCA.sh - This script is used to plot PCA analysis for KAS-seq data(bigWig files are needed).
```Swift
Usage:
Bins mode: plotPCA.sh <KAS_seq_files> <labels> <colors> <bins> <basename> <threads>
Peaks mode: plotPCA.sh <KAS_seq_files> <labels> <colors> <peaks> <basename> <threads> <peaks_list>

Example:
Bins mode: nohup plotPCA.sh KAS_seq_files.txt labels.txt colors.txt bins KAS-seq 10 &
Peaks mode: nohup plotPCA.sh KAS_seq_files.txt labels.txt colors.txt peaks KAS-seq 10 peaks_list.bed &

Options:
<KAS_seq_files>           Input the text file containing file name of KAS-seq bigWig files.
Example: KAS.rep1.bigWig KAS.rep2.bigWig KAS.rep3.bigWig KAS.rep4.bigWig ---KAS_seq_files.txt

<labels>                  Input the text file containing the labels of KAS-seq data in <KAS_seq_files>.
Note:The number of labels needs to be consistent with the number of KAS-seq bigWig files. 
Example: KAS.rep1 KAS.rep2 KAS.rep3 KAS.rep4 ---labels.txt

<colors>                  Input the text file containing color list for the dots of KAS-seq data in PCA plot.
Note:The number of colors needs to be consistent with the number of KAS-seq bigWig files.
The list of valid color names: https://matplotlib.org/examples/color/named_colors.html.
Example: red blue green purple ---colors.txt

<regions>                 Input the mode you want to define the KAS-seq signal enriched regions(bins, peaks).
<threads>                 Input the number pf threads.
<basename>                Input the basename of output files.
<peaks_list>              Input the merged KAS-seq peaks list(mergeBed -i Sorted_total_KAS-seq_peak.bed > merged_KAS-seq_peaks.bed).
-h or --help              Print the help.
```
## Define single-stranded enhancers
define_single-stranded_enhancers.sh - This script is used to define single-stranded(Entire KAS and Middle KAS) enhancers.
```Swift
Usage: define_single-stranded_enhancers.sh <enhancer_list> <KAS_peaks> <assembly>.

Example: nohup define_single-stranded_enhancers.sh enhancers.bed KAS_peaks.bed hg19 &

Options:
<enhancer_list>           Input the enhancers list at bed format, which can be defined using distal H3K27ac or ATAC-seq peaks.
<KAS_peaks>               Input the KAS-seq peaks.
Note: KAS-seq peaks on genebody enhancers may be affected by elongation related KAS signal, so it will be great if you use KAS-seq peaks in elongation inhibited cells, e.g DRB inhibited cells.
<assembly>                Input the assembly of your reference genome(mm9, mm10, hg19, hg38...).
-h or --help              Print the help.
```

## Introduction for other provided shell scripts in KAS-pipe
```Swift
define_single-stranded_enhancers.sh       This script is used to define single-stranded enhancers.
download_reference_genome.sh              This script is used to download reference genome <assembly> in a directory <dest_dir>.
make_UCSC_files.sh                        This script is used to generate UCSC genome browser submit ready file.
plotFingerprint.sh                        This script is used to plot fingerprint for KAS-seq data(indexed KAS-seq Bam files are needed).
uninstall_conda_env.sh                    This script is used to uninstall KAS-pipe conda environment.
update_conda_env.sh                       This script is used to update KAS-pipe conda environment.
```

# Citation
Wu, Tong, et al. [Kethoxal-assisted single-stranded DNA sequencing captures global transcription dynamics and enhancer activity in situ](https://www.nature.com/articles/s41592-020-0797-9). Nature Methods 17.5 (2020): 515-523.
