### Ref links
# http://tuxette.nathalievilla.org/?p=1696
# https://swcarpentry.github.io/r-novice-inflammation/05-cmdline/

## -----------------------------------------------------------------------------
# get the input passed from the shell script.
args <- commandArgs(TRUE)

# test if there is at least one argument: if not, return an error.
if (length(args) == 0) {
  stop("At least two argument must be supplied (input file).\n", call. = FALSE)
} else {
  print(paste0("Arg input:  ", args[1], args[2], args[3]))
}

## -----------------------------------------------------------------------------
#install and load ggpubr package.
#install.packages("ggpubr",repos = "http://cran.us.r-project.org")
library("ggpubr")

## -----------------------------------------------------------------------------
# use shell input.
rowname <- read.table(args[2], header = F)
colname <- read.table(args[3], header = F)
rowname <- as.vector(unlist(rowname[,1]))
colname <- as.vector(unlist(colname[1,]))
KAS.matrix <- round(as.matrix(read.table(args[1], header = F)))
dimnames(KAS.matrix)=list(rowname,colname)
KAS.matrix <- as.data.frame(KAS.matrix)

## -----------------------------------------------------------------------------
# Plot the correlation scatterplot and save it to png format.
png(file="KAS-seq_corr_scatterplot.png", bg="transparent")
ggscatter(KAS.matrix, x = colnames(KAS.matrix)[1], y = colnames(KAS.matrix)[2],
          add = "reg.line", conf.int = TRUE,
          add.params = list(color = "blue",fill = "lightgray")) +
          stat_cor(method = "pearson")

# ggplot2.scatterplot(data=KAS.matrix, xName = colnames(KAS.matrix)[1], yName = colnames(KAS.matrix)[2], size=3,
#        addRegLine=TRUE, regLineColor="black",
#        addConfidenceInterval=TRUE,
#        backgroundColor="white", 
#        xtitle=colnames(KAS.matrix)[1], ytitle=colnames(KAS.matrix)[2],
#        removePanelGrid=TRUE,removePanelBorder=TRUE,
#        axisLine=c(0.5, "solid", "black"))

dev.off()

# Plot the correlation scatterplot and save it to svg format.
svg(file="KAS-seq_corr_scatterplot.svg", bg="transparent")
ggscatter(KAS.matrix, x = colnames(KAS.matrix)[1], y = colnames(KAS.matrix)[2],
          add = "reg.line", conf.int = TRUE,
          add.params = list(color = "blue",fill = "lightgray")) +
          stat_cor(method = "pearson")
dev.off()

#http://www.sthda.com/english/wiki/wiki.php?title=ggplot2-scatterplot-easy-scatter-plot-using-ggplot2-and-r-statistical-software 

## ----sessionInfo--------------------------------------------------------------
sessionInfo()

