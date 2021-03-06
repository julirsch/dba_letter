#' ---
#' title: "Analyze GSE89540 with reference data using RMA (pre-processing)"
#' author: "Jacob C Ulirsch"
#' date: "`r Sys.Date()`"
#' output: html_document
#' ---

#' RMA normalizes samples within a batch. RMA is normally our choice for analyzing singular datasets, but since these are across multiple platforms and there is batch normalization, it probably makes more sense to SCAN + BN rather than RMA (in groups) + BN as BN may do some strange things between RMA-normalized groups. (Note, we considered fRMA but fRMA reference datasets were not available for HuGene 2.0 ST microarrays).
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE
# Import libraries
library(oligo)
library(dplyr)
library(annotate)
library(sva)
library(reshape2)
library(tidyr)
library(limma)

#' Read in data for each experiment on GEO and save as RDS object so we only have to do this once
#+ cache = TRUE, message=FALSE, warning=FALSE, echo = TRUE, eval = FALSE
geneCELs <- list.celfiles("../data/GSE22552_RAW/", full.names = TRUE, listGzipped=T) 
affyGeneFS.GSE22552 <- read.celfiles(geneCELs)
geneCELs <- list.celfiles("../data/GSE24759_RAW/", full.names = TRUE, listGzipped=T) 
affyGeneFS.GSE24759 <- read.celfiles(geneCELs, pkgname="pd.ht.hg.u133a")
geneCELs <- list.celfiles("../data/GSE41817_RAW/", full.names = TRUE, listGzipped=T) 
affyGeneFS.GSE41817 <- read.celfiles(geneCELs)
geneCELs <- list.celfiles("../data/GSE89540_RAW/", full.names = TRUE, listGzipped=T)
affyGeneFS.GSE89540 <- read.celfiles(geneCELs)
#RMA normalize
RMA.GSE22552 <- rma(affyGeneFS.GSE22552)
saveRDS(RMA.GSE22552,"../processed/RMA.GSE22552.rds")
RMA.GSE24759 <- rma(affyGeneFS.GSE24759)
saveRDS(RMA.GSE24759,"../processed/RMA.GSE24759.rds")
RMA.GSE41817 <- rma(affyGeneFS.GSE41817)
saveRDS(RMA.GSE41817,"../processed/RMA.GSE41817.rds")
RMA.GSE89540 <- rma(affyGeneFS.GSE89540)
saveRDS(RMA.GSE89540,"../processed/RMA.GSE89540.rds")

#' Load in RMA-normalized expression
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = FALSE, eval = TRUE
RMA.GSE22552 <- readRDS("../processed/RMA.GSE22552.rds")
RMA.GSE24759 <- readRDS("../processed/RMA.GSE24759.rds")
RMA.GSE41817 <- readRDS("../processed/RMA.GSE41817.rds")
RMA.GSE89540 <- readRDS("../processed/RMA.GSE89540.rds")

#' Load and add gene level annotation for each microarray study, remove probesets without gene annotations, take max across probesets 
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = TRUE, eval = TRUE
# GSE22552
library(hgu133plus2.db)
annotation(RMA.GSE22552) <- "hgu133plus2.db"
ID <- featureNames(RMA.GSE22552)
Symbol <- getSYMBOL(ID,"hgu133plus2.db")
fData(RMA.GSE22552) <- data.frame(ID=ID,Symbol=Symbol)
exprs.GSE22552 <- as.data.frame(exprs(RMA.GSE22552))
exprs.GSE22552$gene <- as.vector(fData(RMA.GSE22552)$Symbol)
exprs.GSE22552 <- exprs.GSE22552 %>%
  filter(gene != "<NA>") %>%
  group_by(gene) %>%
  summarise_each(funs(max))
# GSE24759
library(hthgu133a.db)
annotation(RMA.GSE24759) <- "hthgu133a.db"
ID <- featureNames(RMA.GSE24759)
Symbol <- getSYMBOL(ID,"hthgu133a.db")
fData(RMA.GSE24759) <- data.frame(ID=ID,Symbol=Symbol)
exprs.GSE24759 <- as.data.frame(exprs(RMA.GSE24759))
exprs.GSE24759$gene <- as.vector(fData(RMA.GSE24759)$Symbol)
exprs.GSE24759 <- exprs.GSE24759 %>%
  filter(gene != "<NA>") %>%
  group_by(gene) %>%
  summarise_each(funs(max))
# GSE41817
library(hgu133a.db)
annotation(RMA.GSE41817) <- "hgu133a.db"
ID <- featureNames(RMA.GSE41817)
Symbol <- getSYMBOL(ID,"hgu133a.db")
fData(RMA.GSE41817) <- data.frame(ID=ID,Symbol=Symbol)
exprs.GSE41817 <- as.data.frame(exprs(RMA.GSE41817))
exprs.GSE41817$gene <- as.vector(fData(RMA.GSE41817)$Symbol)
exprs.GSE41817 <- exprs.GSE41817 %>%
  filter(gene != "<NA>") %>%
  group_by(gene) %>%
  summarise_each(funs(max))
# GSE89540
library(hugene20sttranscriptcluster.db)
annotation(RMA.GSE89540) <- "hugene20sttranscriptcluster.db"
ID <- featureNames(RMA.GSE89540)
Symbol <- getSYMBOL(ID,"hugene20sttranscriptcluster.db")
fData(RMA.GSE89540) <- data.frame(ID=ID,Symbol=Symbol)
exprs.GSE89540 <- as.data.frame(exprs(RMA.GSE89540))
exprs.GSE89540$gene <- as.vector(fData(RMA.GSE89540)$Symbol)
exprs.GSE89540 <- exprs.GSE89540 %>%
  filter(gene != "<NA>") %>%
  group_by(gene) %>%
  summarise_each(funs(max))

#' Merge datasets together by gene name and convert from GSM to human interpretable sample names
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = TRUE, eval = TRUE
combined <- list(exprs.GSE22552, exprs.GSE24759, exprs.GSE41817, exprs.GSE89540) %>%
  Reduce(function(dtf1,dtf2) inner_join(dtf1,dtf2,by="gene"), .)
names(combined) <- gsub(".CEL.gz","",gsub("_.*","",names(combined)))
samples <- read.table("../data/Samples.txt",sep="\t",stringsAsFactors=F)
names(samples) <- c("GSM","name","GSE","stage","group1","group2")
samples$GSM <- factor(samples$GSM,levels=names(combined),ordered=T)
samples <- samples[order(samples$GSM),]
samples <- samples %>% filter(samples$GSM %in% names(combined))
names(combined) <- c("gene",samples$name)
combined <- data.frame(combined)
row.names(combined) <- combined$gene
combined <- combined[,-1]
combined.t <- data.frame(t(combined))
names(combined.t) <- row.names(combined)

#' Batch normalize! Can choose model with only intercept or include covariate for a rough sorted "stage". Really should only include studies with multiple stages (e.g. two references and O'Brien et al.) otherwise completely confounded.
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = TRUE, eval = TRUE
keep <- samples %>% 
  filter(GSE %in% c("GSE22552", "GSE24759", "GSE89540")) %>% 
  filter(group1 != "")
combined.temp <- data.frame(combined) %>% 
  dplyr::select(one_of(keep$name))
combined.temp.t <- data.frame(t(combined.temp))
names(combined.temp.t) <- row.names(combined.temp)
modcombat <- model.matrix(~1, data=combined.temp.t)
#modcombat <- model.matrix(~1 + samples$stage, data=combined.t)
combined.bn <- ComBat(dat=combined.temp, batch=as.factor(keep$GSE), mod=modcombat, par.prior=TRUE, prior.plots=F)
row.names(combined.bn) <- row.names(combined)
combined.bn.t <- data.frame(t(combined.bn))

#' Split both normalized and normalized + batch normalized into data frames for each study.
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = TRUE, eval = TRUE
# GSE22552 BN
keep <- samples %>% 
  filter(GSE == "GSE22552") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.bn.GSE22552 <- data.frame(combined.bn) %>% 
  dplyr::select(one_of(keep))
# GSE24759 BN
keep <- samples %>% 
  filter(GSE == "GSE24759") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.bn.GSE24759 <- data.frame(combined.bn) %>% 
  dplyr::select(one_of(keep))
# GSE89540 BN
keep <- samples %>% 
  filter(GSE == "GSE89540") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.bn.GSE89540 <- data.frame(combined.bn) %>% 
  dplyr::select(one_of(keep))
# GSE22552
keep <- samples %>% 
  filter(GSE == "GSE22552") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.GSE22552 <- data.frame(combined) %>% 
  dplyr::select(one_of(keep))
# GSE24759
keep <- samples %>% 
  filter(GSE == "GSE24759") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.GSE24759 <- data.frame(combined) %>% 
  dplyr::select(one_of(keep))
# GSE41817
keep <- samples %>% 
  filter(GSE == "GSE41817") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.GSE41817 <- data.frame(combined) %>% 
  dplyr::select(one_of(keep))
# GSE89540
keep <- samples %>% 
  filter(GSE == "GSE89540") %>% 
  filter(group1 != "") %>% 
  .$name 
combined.GSE89540 <- data.frame(combined) %>% 
  dplyr::select(one_of(keep))

#' Done with pre-processing. Save both normalized and normalized + batch normalized data.
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = TRUE, eval = TRUE
saveRDS(combined,"../processed/combined_RMA.rds")
saveRDS(combined.GSE22552,"../processed/combined_RMA_GSE22552.rds")
saveRDS(combined.GSE24759,"../processed/combined_RMA_GSE24759.rds")
saveRDS(combined.GSE41817,"../processed/combined_RMA_GSE41817.rds")
saveRDS(combined.GSE89540,"../processed/combined_RMA_GSE89540.rds")
saveRDS(combined.bn,"../processed/combined_RMA_BN.rds")
saveRDS(combined.bn.GSE22552,"../processed/combined_RMA_BN_GSE22552.rds")
saveRDS(combined.bn.GSE24759,"../processed/combined_RMA_BN_GSE24759.rds")
saveRDS(combined.bn.GSE89540,"../processed/combined_RMA_BN_GSE89540.rds")

#' Identify most variable genes between groups in the two reference datasets. Write signature gene sets for overlaps.
#+ cache = FALSE, message=FALSE, warning=FALSE, echo = TRUE, eval = TRUE
# GSE22552
# Do this for later
combined.bn.GSE22552.melt <- melt(as.matrix(combined.bn.GSE22552))
combined.bn.GSE22552.melt <- list(combined.bn.GSE22552.melt, samples) %>%
  Reduce(function(dtf1,dtf2) left_join(dtf1,dtf2,by=c("Var2"="name")), .)
# Make one vs all comparisons for each
groups <- samples %>%
  filter(name %in% names(combined.bn.GSE22552)) %>%
  .$group1 %>%
  factor(levels=c("CFU_E","PRO_E","INT_E","LATE_E"), ordered=TRUE)
condition <- model.matrix(~0+groups)
colnames(condition) <- c("CFU_E","PRO_E","INT_E","LATE_E")
cont_matrix <- makeContrasts(CFU_EvALL = CFU_E - (PRO_E+INT_E+LATE_E)/3,
                             PRO_EvALL = PRO_E - (CFU_E+INT_E+LATE_E)/3,
                             INT_EvALL = INT_E - (CFU_E+PRO_E+LATE_E)/3,
                             LATE_EvALL = LATE_E - (CFU_E+PRO_E+INT_E)/3,
                             levels = condition)
# Convert to eSet and run limma
v <-new("ExpressionSet", exprs=as.matrix(combined.bn.GSE22552))
fit <- lmFit(v, condition)
fit <- contrasts.fit(fit, cont_matrix)
fit <- eBayes(fit)
out <- data.frame(fit$coefficients)
combined.bn.GSE22552.limma <- NULL
#Calculate unsigned GSA statistics
for (i in 1:4) {
  out[,i] <- abs(fit$coefficients[,i] * log10(fit$p.value)[,i])
  combined.bn.GSE22552.limma <- c(combined.bn.GSE22552.limma,row.names(head(out[order(out[,i]),],30)))
}
combined.bn.GSE22552.limma <- unique(combined.bn.GSE22552.limma)
# GSE24759
# Do this for later
combined.bn.GSE24759.melt <- melt(as.matrix(combined.bn.GSE24759))
combined.bn.GSE24759.melt <- list(combined.bn.GSE24759.melt, samples) %>%
  Reduce(function(dtf1,dtf2) left_join(dtf1,dtf2,by=c("Var2"="name")), .)
# Make one vs all comparisons for each
groups <- samples %>%
  filter(name %in% names(combined.bn.GSE24759)) %>%
  .$group1 %>%
  factor(levels=c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos"), ordered=TRUE)
condition <- model.matrix(~0+groups)
colnames(condition) <- c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos")
cont_matrix <- makeContrasts(CD34pos_CD71pos_GlyAnegvALL = CD34pos_CD71pos_GlyAneg - (CD34neg_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71lo_GlyApos+CD34neg_CD71neg_GlyApos)/4,
                             CD34neg_CD71pos_GlyAnegvALL = CD34neg_CD71pos_GlyAneg - (CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71lo_GlyApos+CD34neg_CD71neg_GlyApos)/4,
                             CD34neg_CD71pos_GlyAposvALL = CD34neg_CD71pos_GlyApos - (CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyAneg+CD34neg_CD71lo_GlyApos+CD34neg_CD71neg_GlyApos)/4,
                             CD34neg_CD71lo_GlyAposvALL = CD34neg_CD71lo_GlyApos - (CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71neg_GlyApos)/4,
                             CD34neg_CD71neg_GlyApos = CD34neg_CD71neg_GlyApos - (CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71lo_GlyApos)/4,
                             levels = condition)
# Convert to eSet and run limma
v <-new("ExpressionSet", exprs=as.matrix(combined.bn.GSE24759))
fit <- lmFit(v, condition)
fit <- contrasts.fit(fit, cont_matrix)
fit <- eBayes(fit)
out <- data.frame(fit$coefficients)
combined.bn.GSE24759.limma <- NULL
#Calculate unsigned GSA statistics and take top 100 for each comparison
for (i in 1:5) {
  out[,i] <- abs(fit$coefficients[,i] * log10(fit$p.value)[,i])
  combined.bn.GSE24759.limma <- c(combined.bn.GSE24759.limma,row.names(head(out[order(out[,i]),],25)))
}
combined.bn.GSE24759.limma <- unique(combined.bn.GSE24759.limma)
# Create and write GSE22552 signature matrix
combined.bn.GSE22552.out <- combined.bn.GSE22552.melt %>%
  filter(Var1 %in% combined.bn.GSE22552.limma) %>%
  group_by(group1,Var1) %>%
  summarize(mean = mean(value)) %>%
  spread(group1,mean)
write.table(combined.bn.GSE22552.out,"../processed/combined_RMA_BN_SIG_GSE22552.txt",quote=F,sep="\t",row.names=F)
# Create and write GSE24759 signature matrix
combined.bn.GSE24759.out <- combined.bn.GSE24759.melt %>%
  filter(Var1 %in% combined.bn.GSE24759.limma) %>%
  group_by(group1,Var1) %>%
  summarize(mean = mean(value)) %>%
  spread(group1,mean)
write.table(combined.bn.GSE24759.out,"../processed/combined_RMA_BN_SIG_GSE24759.txt",quote=F,sep="\t",row.names=F)

