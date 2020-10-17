### Ref links
# http://tuxette.nathalievilla.org/?p=1696
# https://swcarpentry.github.io/r-novice-inflammation/05-cmdline/

## -----------------------------------------------------------------------------
# get the input passed from the shell script
args <- commandArgs(TRUE)

## -----------------------------------------------------------------------------
# test if there is at least one argument: if not, return an error
if (length(args) == 0) {
  stop("At least two argument must be supplied (input file).\n", call. = FALSE)
} else {
  print(paste0("Arg input:  ","option1:", args[1]," option2:", args[2]," option3:",args[3]," option4:",args[4]))
}

## -----------------------------------------------------------------------------
# use shell input
rowname <- read.table(args[2], header = F)
colname <- read.table(args[3], header = F)
rowname <- as.vector(unlist(rowname[,1]))
colname <- as.vector(unlist(colname[1,]))
KAS.matrix <- round(as.matrix(read.table(args[1], header = F)))
dimnames(KAS.matrix)=list(rowname,colname)
coldata <- read.table(args[4], header = T,row.names = 1)

## -----------------------------------------------------------------------------
# install and load DESeq2 package
# if (!requireNamespace("BiocManager", quietly = TRUE))
# install.packages("BiocManager",repos = "http://cran.us.r-project.org")

# BiocManager::install("DESeq2")
library("DESeq2")

## -----------------------------------------------------------------------------
#generate DESeqDataSet
coldata$condition <- factor(coldata$condition)
dds <- DESeqDataSetFromMatrix(countData = KAS.matrix,
                              colData = coldata,
                              design = ~ condition)
#prefilter bins or regions with low KAS-seq signal
keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep,]

#specify the reference level
dds$condition <- relevel(dds$condition, ref = "untreated")

#Differential KAS-seq analysis
dds <- DESeq(dds)
res <- results(dds, name="condition_treated_vs_untreated")
resOrdered <- res[order(res$padj),]
resOrdered=as.data.frame(resOrdered)
DE.KAS=resOrdered[abs(resOrdered$log2FoldChange)>log2(1.5) & resOrdered$padj <0.01 ,]

## -----------------------------------------------------------------------------
#output the results of differential KAS-seq analysis
write.csv(resOrdered,"treated_vs_untreated_DESeq2_output.csv")
write.csv(DE.KAS,"DE.KAS_treated_vs_untreated_DESeq2_Fold1.5_padj0.01_output.csv")

## ----sessionInfo--------------------------------------------------------------
sessionInfo()


