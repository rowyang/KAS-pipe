# KAS-pipe
KAS-pipe is an analysis pipeline for KAS-seq data. KAS-seq is a kethoxal-assisted single-stranded DNA sequencing (KAS-seq) approach, based on the fast and specific reaction between N3-kethoxal and guanines in ssDNA. KAS-seq allows rapid (within 5 min), sensitive and genome-wide capture and mapping of ssDNA produced by transcriptionally active RNA polymerases or other processes in situ using as few as 1,000 cells. KAS-seq can also enable definition of a group of enhancers that are single-stranded and enrich unique sequence motifs. Overall, KAS-seq facilitates fast and accurate analysis of transcription dynamics and enhancer activities simultaneously in both low-input and high-throughput manner. KAS-pipe as a analysis pipeline for KAS-seq data, which provides many shell scripts for KAS-seq data processing, for example, reference genome index setup, adapter sequence trimming, alignment, differential analysis and so on.   

![image](https://github.com/Ruitulyu/KAS-pipe/blob/master/Schematic%20diagram%20for%20KAS-seq.PNG)

# Citation:
Wu, Tong, et al. [Kethoxal-assisted single-stranded DNA sequencing captures global transcription dynamics and enhancer activity in situ](https://www.nature.com/articles/s41592-020-0797-9) Nature Methods 17.5 (2020): 515-523.

# Dependencies:
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

# Installation:
