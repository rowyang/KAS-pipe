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
# use shell input.
rowname <- read.table(args[2], header = F)
colname <- read.table(args[3], header = F)
rowname <- as.vector(unlist(rowname[,1]))
colname <- as.vector(unlist(colname[1,]))
KAS.matrix <- round(as.matrix(read.table(args[1], header = F)))
dimnames(KAS.matrix)=list(rowname,colname)
# install.packages("ggpubr",repos = "http://cran.us.r-project.org")

## -----------------------------------------------------------------------------
# Plot the correlation using a matrix of scatter plot and save it to png format.
upper.panel<-function(x, y){
  points(x,y, pch=19, col="green")
  r <- round(cor(x, y), digits=2)
  txt <- paste0("R = ", r)
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  text(0.5, 0.9, txt)
}

# Plot the correlation scatterplot matrix and save it to png format.
png(file="KAS-seq_corr_scatterplot_matrix.png", bg="transparent")
pairs(KAS.matrix, lower.panel = NULL, 
      upper.panel = upper.panel)
dev.off()

# Plot the correlation scatterplot matrix and save it to svg format.
svg(file="KAS-seq_corr_scatterplot_matrix.svg", bg="transparent")
pairs(KAS.matrix, lower.panel = NULL, 
      upper.panel = upper.panel)
dev.off()

## ----sessionInfo--------------------------------------------------------------
sessionInfo()
