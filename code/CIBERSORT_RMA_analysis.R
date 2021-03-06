#' ---
#' title: "Analyze GSE89540 with reference data using CIBERSORT (RMA-normalized data)"
#' author: "Jacob C Ulirsch"
#' date: "`r Sys.Date()`"
#' output: html_document
#' ---

#' Check if DBA status and genotype are confounded by maturation stage using CIBERSORT.
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE
# Import libraries
library(readr)
library(dplyr)
library(tidyr)
library(reshape2)
library(ggplot2)
library(BuenColors)
sem<-function(x) {sd(x)/sqrt(length(x))}
source("CIBERSORT.r")

#' Run essentially the code implemented by cibersort (https://cibersort.stanford.edu). Small differences incldue that we are using log2 normalized data and do not scale to mean=0, sd=1 prior to running SVR.
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = TRUE, eval = TRUE
# Read in signature matrix and mixture
# sigMat_In Defines a set of features / referent cell type
# used to classify in unknown samples, which are encoded in mix_In
sigMat_In <- read_tsv("../processed/combined_RMA_BN_SIG_GSE22552.txt")
mix_In <- readRDS("../processed/combined_RMA_BN.rds")

# Reformat data.frames including gene subsetting
#mix_In <- data.frame(mix_In[,-1], row.names = as.character(mix_In[[1]]))
sigMat <- data.frame(sigMat_In[,-1], row.names = as.character(sigMat_In[[1]]))
mix <- mix_In[rownames(sigMat), ]

# Run CIBERSORT on input mixture (mix) using signature matrix (sigMat)
resmat <- sapply(1:dim(mix)[2], modelSample, mix, sigMat)
colnames(resmat) <- colnames(mix)
resdf <- data.frame(row.names = colnames(sigMat), resmat)
CIBERSORT.RMA.BN.sigGSE22552 <- t(resdf)

# Annotation with sample information
samples <- read.table("../data/Samples.txt",sep="\t",stringsAsFactors=F)
names(samples) <- c("GSM","name","GSE","stage","group1","group2")
CIBERSORT.RMA.BN.sigGSE22552 <- merge(CIBERSORT.RMA.BN.sigGSE22552,samples,by.x="row.names",by.y="name")
CIBERSORT.RMA.BN.sigGSE22552$group2 <- as.factor(CIBERSORT.RMA.BN.sigGSE22552$group2)
CIBERSORT.GSE22552 <- CIBERSORT.RMA.BN.sigGSE22552 #for convenience

# Read in signature matrix and mixture
# sigMat_In Defines a set of features / referent cell type
# used to classify in unknown samples, which are encoded in mix_In
sigMat_In <- read_tsv("../processed/combined_RMA_BN_SIG_GSE24759.txt")
mix_In <- readRDS("../processed/combined_RMA_BN.rds")

# Reformat data.frames including gene subsetting
#mix_In <- data.frame(mix_In[,-1], row.names = as.character(mix_In[[1]]))
sigMat <- data.frame(sigMat_In[,-1], row.names = as.character(sigMat_In[[1]]))
mix <- mix_In[rownames(sigMat), ]

# Run CIBERSORT on input mixture (mix) using signature matrix (sigMat)
resmat <- sapply(1:dim(mix)[2], modelSample, mix, sigMat)
colnames(resmat) <- colnames(mix)
resdf <- data.frame(row.names = colnames(sigMat), resmat)
CIBERSORT.RMA.BN.sigGSE24759 <- t(resdf)

# Annotation with sample information
samples <- read.table("../data/Samples.txt",sep="\t",stringsAsFactors=F)
names(samples) <- c("GSM","name","GSE","stage","group1","group2")
CIBERSORT.RMA.BN.sigGSE24759 <- merge(CIBERSORT.RMA.BN.sigGSE24759,samples,by.x="row.names",by.y="name")
CIBERSORT.RMA.BN.sigGSE24759$group2 <- as.factor(CIBERSORT.RMA.BN.sigGSE24759$group2)
CIBERSORT.GSE24759 <- CIBERSORT.RMA.BN.sigGSE24759 #for convenience

#' Deconvolved mixtures of reference set GSE22552 using GSE22552 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, fig.width=7, fig.height=2.5, fig.align='center'
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(GSE == "GSE22552") %>%
  dplyr::select(CFU_E:PRO_E,group1)
CIBERSORT.GSE22552.melt <- melt(CIBERSORT.GSE22552.temp)
CIBERSORT.GSE22552.melt$variable <- factor(CIBERSORT.GSE22552.melt$variable, levels= rev(c("CFU_E","PRO_E","INT_E","LATE_E")), ordered=T)
CIBERSORT.GSE22552.melt$group1 <- factor(CIBERSORT.GSE22552.melt$group1, levels= c("CFU_E","PRO_E","INT_E","LATE_E"), ordered=T)
CIBERSORT.GSE22552.sum <- CIBERSORT.GSE22552.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE22552.plot <- CIBERSORT.GSE22552.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE22552.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("flame_light")[c(2,4,6,8)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")

#' Deconvolved mixtures of reference set GSE247599 using GSE22552 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, fig.width=10, fig.height=2.5, fig.align='center'
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(GSE == "GSE24759") %>%
  dplyr::select(CFU_E:PRO_E,group1)
CIBERSORT.GSE22552.melt <- melt(CIBERSORT.GSE22552.temp)
CIBERSORT.GSE22552.melt$variable <- factor(CIBERSORT.GSE22552.melt$variable, levels= rev(c("CFU_E","PRO_E","INT_E","LATE_E")), ordered=T)
CIBERSORT.GSE22552.melt$group1 <- factor(CIBERSORT.GSE22552.melt$group1, levels= c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos"), ordered=T)
CIBERSORT.GSE22552.sum <- CIBERSORT.GSE22552.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE22552.plot <- CIBERSORT.GSE22552.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE22552.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("flame_light")[c(2,4,6,8)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")

#' Deconvolved mixtures of reference set GSE24759 using GSE24759 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, fig.width=10, fig.height=2.5, fig.align='center'
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(GSE == "GSE24759") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group1)
CIBERSORT.GSE24759.melt <- melt(CIBERSORT.GSE24759.temp)
CIBERSORT.GSE24759.melt$variable <- factor(CIBERSORT.GSE24759.melt$variable, levels= rev(c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos")), ordered=T)
CIBERSORT.GSE24759.melt$group1 <- factor(CIBERSORT.GSE24759.melt$group1, levels= c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos"), ordered=T)
CIBERSORT.GSE24759.sum <- CIBERSORT.GSE24759.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE24759.plot <- CIBERSORT.GSE24759.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE24759.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("brewer_celsius")[c(9,7,5,3,1)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")

#' Deconvolved mixtures of reference set GSE22552 using GSE24759 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, fig.width=7, fig.height=2.5, fig.align='center'
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(GSE == "GSE22552") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group1)
CIBERSORT.GSE24759.melt <- melt(CIBERSORT.GSE24759.temp)
CIBERSORT.GSE24759.melt$variable <- factor(CIBERSORT.GSE24759.melt$variable, levels= rev(c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos")), ordered=T)
CIBERSORT.GSE24759.melt$group1 <- factor(CIBERSORT.GSE24759.melt$group1, levels= c("CFU_E","PRO_E","INT_E","LATE_E"), ordered=T)
CIBERSORT.GSE24759.sum <- CIBERSORT.GSE24759.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE24759.plot <- CIBERSORT.GSE24759.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE24759.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("brewer_celsius")[c(9,7,5,3,1)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")

#' Deconvolved mixtures of O'Brien et al. CD235a+/CD235a- mixtures using GSE22552 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, results = 'hide', fig.width=4, fig.height=2.5, fig.align='center'
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(group1 == "Control") %>%
  dplyr::select(CFU_E:PRO_E,group2)
CIBERSORT.GSE22552.melt <- melt(CIBERSORT.GSE22552.temp)
CIBERSORT.GSE22552.melt$variable <- factor(CIBERSORT.GSE22552.melt$variable, levels= rev(c("CFU_E","PRO_E","INT_E","LATE_E")), ordered=T)
CIBERSORT.GSE22552.sum <- CIBERSORT.GSE22552.melt %>% 
  group_by(group2,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE22552.plot <- CIBERSORT.GSE22552.sum %>% 
  group_by(group2) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE22552.plot, aes(x=group2, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("flame_light")[c(2,4,6,8)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")
###Test for differences in proportions of each stage between groups
mod.null <- glm(factor(group2) ~ 1, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.full <- glm(factor(group2) ~ CFU_E+PRO_E+INT_E+LATE_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.CFU_E <- glm(factor(group2) ~ CFU_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.PRO_E <- glm(factor(group2) ~ PRO_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.INT_E <- glm(factor(group2) ~ INT_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.LATE_E <- glm(factor(group2) ~ LATE_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
anova(mod.full,mod.null,test="Chisq")
anova(mod.CFU_E,mod.null,test="Chisq")
anova(mod.PRO_E,mod.null,test="Chisq")
anova(mod.INT_E,mod.null,test="Chisq")
anova(mod.LATE_E,mod.null,test="Chisq")

#' Deconvolved mixtures of O'Brien et al. CD235a- DBA genotype mixtures using GSE22552 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, results = 'hide', fig.width=4, fig.height=4, fig.align='center'
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(group2 == "44") %>%
  dplyr::select(CFU_E:PRO_E,group1)
CIBERSORT.GSE22552.melt <- melt(CIBERSORT.GSE22552.temp)
CIBERSORT.GSE22552.melt$variable <- factor(CIBERSORT.GSE22552.melt$variable, levels= rev(c("CFU_E","PRO_E","INT_E","LATE_E")), ordered=T)
CIBERSORT.GSE22552.sum <- CIBERSORT.GSE22552.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE22552.plot <- CIBERSORT.GSE22552.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE22552.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("flame_light")[c(2,4,6,8)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")
###Test for differences in proportions of each stage between groups (DBA vs normal)
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(group2 == "44",group1 !="DBA_GATA1") %>%
  dplyr::select(CFU_E:PRO_E,group1)
mod.null <- glm(factor(group1) ~ 1, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.full <- glm(factor(group1) ~ CFU_E+PRO_E+INT_E+LATE_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.CFU_E <- glm(factor(group1) ~ CFU_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.PRO_E <- glm(factor(group1) ~ PRO_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.INT_E <- glm(factor(group1) ~ INT_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.LATE_E <- glm(factor(group1) ~ LATE_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
anova(mod.full,mod.null,test="Chisq")
anova(mod.CFU_E,mod.null,test="Chisq")
anova(mod.PRO_E,mod.null,test="Chisq")
anova(mod.INT_E,mod.null,test="Chisq")
anova(mod.LATE_E,mod.null,test="Chisq")
###Test for differences in proportions of each stage between groups (DBA_GATA1 vs normal)
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(group2 == "44",group1 !="DBA") %>%
  dplyr::select(CFU_E:PRO_E,group1)
mod.null <- glm(factor(group1) ~ 1, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.full <- glm(factor(group1) ~ CFU_E+PRO_E+INT_E+LATE_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.CFU_E <- glm(factor(group1) ~ CFU_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.PRO_E <- glm(factor(group1) ~ PRO_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.INT_E <- glm(factor(group1) ~ INT_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
mod.LATE_E <- glm(factor(group1) ~ LATE_E, data=CIBERSORT.GSE22552.temp, family = binomial(link = "logit"))
anova(mod.full,mod.null,test="Chisq")
anova(mod.CFU_E,mod.null,test="Chisq")
anova(mod.PRO_E,mod.null,test="Chisq")
anova(mod.INT_E,mod.null,test="Chisq")
anova(mod.LATE_E,mod.null,test="Chisq")

#' Deconvolved mixtures of O'Brien et al. CD235a+ DBA genotype mixtures using GSE22552 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, fig.width=4, fig.height=4, fig.align='center'
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(group2 == "235") %>%
  dplyr::select(CFU_E:PRO_E,group1)
CIBERSORT.GSE22552.melt <- melt(CIBERSORT.GSE22552.temp)
CIBERSORT.GSE22552.melt$variable <- factor(CIBERSORT.GSE22552.melt$variable, levels= rev(c("CFU_E","PRO_E","INT_E","LATE_E")), ordered=T)
CIBERSORT.GSE22552.sum <- CIBERSORT.GSE22552.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE22552.plot <- CIBERSORT.GSE22552.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE22552.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("flame_light")[c(2,4,6,8)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")

#' Deconvolved mixtures of O'Brien et al. CD235a+/CD235a- mixtures using GSE24759 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, results = 'hide', fig.width=4, fig.height=4, fig.align='center'
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(group1 == "Control") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group2)
CIBERSORT.GSE24759.melt <- melt(CIBERSORT.GSE24759.temp)
CIBERSORT.GSE24759.melt$variable <- factor(CIBERSORT.GSE24759.melt$variable, levels= rev(c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos")), ordered=T)
CIBERSORT.GSE24759.sum <- CIBERSORT.GSE24759.melt %>% 
  group_by(group2,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE24759.plot <- CIBERSORT.GSE24759.sum %>% 
  group_by(group2) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE24759.plot, aes(x=group2, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("brewer_celsius")[c(9,7,5,3,1)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")
###Test for differences in proportions of each stage between groups
mod.null <- glm(factor(group2) ~ 1, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.full <- glm(factor(group2) ~ CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71lo_GlyApos+CD34neg_CD71neg_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34pos_CD71pos_GlyAneg <- glm(factor(group2) ~ CD34pos_CD71pos_GlyAneg, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71pos_GlyAneg <- glm(factor(group2) ~ CD34neg_CD71pos_GlyAneg, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71pos_GlyApos <- glm(factor(group2) ~ CD34neg_CD71pos_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71lo_GlyApos <- glm(factor(group2) ~ CD34neg_CD71lo_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71neg_GlyApos <- glm(factor(group2) ~ CD34neg_CD71neg_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
anova(mod.full,mod.null,test="Chisq")
anova(mod.CD34pos_CD71pos_GlyAneg,mod.null,test="Chisq")
anova(mod.CD34neg_CD71pos_GlyAneg,mod.null,test="Chisq")
anova(mod.CD34neg_CD71pos_GlyApos,mod.null,test="Chisq")
anova(mod.CD34neg_CD71lo_GlyApos,mod.null,test="Chisq")
anova(mod.CD34neg_CD71neg_GlyApos,mod.null,test="Chisq")

#' Deconvolved mixtures of O'Brien et al. CD235a- DBA genotype mixtures using GSE24759 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, results = 'hide', fig.width=5, fig.height=4, fig.align='center'
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(group2 == "44") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group1)
CIBERSORT.GSE24759.melt <- melt(CIBERSORT.GSE24759.temp)
CIBERSORT.GSE24759.melt$variable <- factor(CIBERSORT.GSE24759.melt$variable, levels= rev(c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos")), ordered=T)
CIBERSORT.GSE24759.sum <- CIBERSORT.GSE24759.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE24759.plot <- CIBERSORT.GSE24759.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE24759.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("brewer_celsius")[c(9,7,5,3,1)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")
###Test for differences in proportions of each stage between groups (DBA vs normal)
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(group2 == "44", group1 != "DBA_GATA1") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group1)
mod.null <- glm(factor(group1) ~ 1, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.full <- glm(factor(group1) ~ CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71lo_GlyApos+CD34neg_CD71neg_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34pos_CD71pos_GlyAneg <- glm(factor(group1) ~ CD34pos_CD71pos_GlyAneg, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71pos_GlyAneg <- glm(factor(group1) ~ CD34neg_CD71pos_GlyAneg, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71pos_GlyApos <- glm(factor(group1) ~ CD34neg_CD71pos_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71lo_GlyApos <- glm(factor(group1) ~ CD34neg_CD71lo_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71neg_GlyApos <- glm(factor(group1) ~ CD34neg_CD71neg_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
anova(mod.full,mod.null,test="Chisq")
anova(mod.CD34pos_CD71pos_GlyAneg,mod.null,test="Chisq")
anova(mod.CD34neg_CD71pos_GlyAneg,mod.null,test="Chisq")
anova(mod.CD34neg_CD71pos_GlyApos,mod.null,test="Chisq")
anova(mod.CD34neg_CD71lo_GlyApos,mod.null,test="Chisq")
anova(mod.CD34neg_CD71neg_GlyApos,mod.null,test="Chisq")
###Test for differences in proportions of each stage between groups (DBA_GATA1 vs normal)
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(group2 == "44",group1 !="DBA") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group1)
mod.null <- glm(factor(group1) ~ 1, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.full <- glm(factor(group1) ~ CD34pos_CD71pos_GlyAneg+CD34neg_CD71pos_GlyAneg+CD34neg_CD71pos_GlyApos+CD34neg_CD71lo_GlyApos+CD34neg_CD71neg_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34pos_CD71pos_GlyAneg <- glm(factor(group1) ~ CD34pos_CD71pos_GlyAneg, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71pos_GlyAneg <- glm(factor(group1) ~ CD34neg_CD71pos_GlyAneg, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71pos_GlyApos <- glm(factor(group1) ~ CD34neg_CD71pos_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71lo_GlyApos <- glm(factor(group1) ~ CD34neg_CD71lo_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
mod.CD34neg_CD71neg_GlyApos <- glm(factor(group1) ~ CD34neg_CD71neg_GlyApos, data=CIBERSORT.GSE24759.temp, family = binomial(link = "logit"))
anova(mod.full,mod.null,test="Chisq")
anova(mod.CD34pos_CD71pos_GlyAneg,mod.null,test="Chisq")
anova(mod.CD34neg_CD71pos_GlyAneg,mod.null,test="Chisq")
anova(mod.CD34neg_CD71pos_GlyApos,mod.null,test="Chisq")
anova(mod.CD34neg_CD71lo_GlyApos,mod.null,test="Chisq")
anova(mod.CD34neg_CD71neg_GlyApos,mod.null,test="Chisq")

#' Deconvolved mixtures of O'Brien et al. CD235a+ DBA genotype mixtures using GSE24759 cell types
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE, fig.width=5, fig.height=4, fig.align='center'
CIBERSORT.GSE24759.temp <- CIBERSORT.GSE24759 %>%
  filter(group2 == "235") %>%
  dplyr::select(CD34neg_CD71lo_GlyApos:CD34pos_CD71pos_GlyAneg,group1)
CIBERSORT.GSE24759.melt <- melt(CIBERSORT.GSE24759.temp)
CIBERSORT.GSE24759.melt$variable <- factor(CIBERSORT.GSE24759.melt$variable, levels= rev(c("CD34pos_CD71pos_GlyAneg","CD34neg_CD71pos_GlyAneg","CD34neg_CD71pos_GlyApos","CD34neg_CD71lo_GlyApos","CD34neg_CD71neg_GlyApos")), ordered=T)
CIBERSORT.GSE24759.sum <- CIBERSORT.GSE24759.melt %>% 
  group_by(group1,variable) %>%
  summarize(percent = mean(value)) %>%
  arrange(desc(variable))
CIBERSORT.GSE24759.plot <- CIBERSORT.GSE24759.sum %>% 
  group_by(group1) %>%
  mutate(pos = cumsum(percent)) %>%
  mutate(lower = pos - sem(percent), upper = pos + sem(percent))
ggplot(CIBERSORT.GSE24759.plot, aes(x=group1, y=percent, fill=variable)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin = lower, ymax = upper), size = 0.2, width = .1, col = "black") +
  scale_fill_manual(values = jdb_palette("brewer_celsius")[c(9,7,5,3,1)]) +
  theme_bw() +
  xlab("") + 
  ylab ("")

#' Save deconvolved mixtures of O'Brien et al. CD235a- DBA genotype mixtures using GSE22552 cell types for synthetic normals.
#+ cache = FALSE, message = FALSE, warning = FALSE, echo = FALSE, eval = TRUE
CIBERSORT.GSE22552.temp <- CIBERSORT.GSE22552 %>%
  filter(group2 == "44") %>%
  dplyr::select(CFU_E:PRO_E,group1,Row.names)
saveRDS(CIBERSORT.GSE22552.temp,"../processed/CIBERSORT.RMA.GSE22552.mixture.rds")


