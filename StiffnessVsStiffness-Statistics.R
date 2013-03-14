# analyze the stiffness data

# read in the data file with a header line and the row names contained in column 1
stiffness <- read.table(
  "/home/seth/Documents/Research/Projects/Open Projects/12-024 Stiffness Analysis/StiffnessComparisons-2.txt",
  header=T,row.names=1)

# repace the zeros with NAs
stiffness[stiffness == 0] <- NA
attach(stiffness) # make it so that I can refernce columns directly without the "stiffness$" identifier

#compute some basic descriptive stats
Stiffness_Summary <- summary(stiffness)

# some hypothesis tests
# t-test assuming normal distribution
DT_Ins_Stiff_different_ttest <- t.test(Droptower.N.m.,Instron.N.m.,paired=1) # DT and Ins stiffness different
DT_Stiff_Greater_ttest <- t.test(Droptower.N.m.,Instron.N.m.,paired=1,alternative="greater") # DT greater stiffness
# wilcoxon assuming no distribution
DT_Ins_Stiff_different_wilcoxon <- wilcox.test(Droptower.N.m.,Instron.N.m.,paired=1) # DT and Ins stiffness different
DT_Stiff_Greater_wilcoxon <- wilcox.test(Droptower.N.m.,Instron.N.m.,paired=1,alternative="greater") # DT greater stiffness

# Linear regression of max dorce with force with DXA
options(na.action=na.exclude) # exclude elements that have NA's in them.
DT_maxF_DXA_LinMod <- lm(Max_DT.Force_.N.~DXA_Score) # use summary(DT_maxF_DAX_LinMod) to view stats
DT_maxF_DXA_PerCor <- cor.test(Max_DT.Force_.N.,DXA_Score)
# plot the fit line and the segments
plot(DXA_Score,Max_DT.Force_.N.)
lines(DXA_Score,fitted(DT_maxF_DXA_LinMod))
segments(DXA_Score,fitted(DT_maxF_DXA_LinMod),DXA_Score,Max_DT.Force_.N.)
# check if the residuals are normally distributed (random noise)
qqnorm(resid(DT_maxF_DXA_LinMod))

# linear regression of DT stiffness with DXA
DT_stiff_DXA_LinMod <- lm(Droptower.N.m.~DXA_Score)
DT_stiff_DXA_PerCor <- cor.test(Droptower.N.m.,DXA_Score)
plot(DXA_Score,Droptower.N.m.)
lines(DXA_Score,fitted(DT_stiff_DXA_LinMod))
segments(DXA_Score,fitted(DT_stiff_DXA_LinMod),DXA_Score,Droptower.N.m.)
qqnorm(resid(DT_stiff_DXA_LinMod))

#linear regression of Ins Stiffness with DXA
Ins_stiff_DXA_LinMod <- lm(Instron.N.m.~DXA_Score)
Ins_stiff_DXA_PerCor <- cor.test(Instron.N.m.,DXA_Score)
plot(DXA_Score,Instron.N.m.)
lines(DXA_Score,fitted(Ins_stiff_DXA_LinMod))
segments(DXA_Score,fitted(Ins_stiff_DXA_LinMod),DXA_Score,Instron.N.m.)
qqnorm(resid(Ins_stiff_DXA_LinMod))

# linear regression of DT stiffness with loading rate
DT_stiff_rate_LinMod <- lm(Droptower.N.m.~Trochante_DT_Loading_Rate_.m.s.)
DT_Stiff_rate_PerCor <- cor.test(Droptower.N.m.,Trochante_DT_Loading_Rate_.m.s.)
plot(Trochante_DT_Loading_Rate_.m.s.,Droptower.N.m.)
lines(Trochante_DT_Loading_Rate_.m.s.,fitted(DT_stiff_rate_LinMod))
segments(Trochante_DT_Loading_Rate_.m.s.,fitted(DT_stiff_rate_LinMod),Trochante_DT_Loading_Rate_.m.s.,Droptower.N.m.)
qqnorm(resid(DT_stiff_rate_LinMod))

# linear regression of difference in stiffness with loading rate
Diff_stiff <- Droptower.N.m.-Instron.N.m.
Diff_stiff_Rate_LinMod <- lm(Diff_stiff~Trochante_DT_Loading_Rate_.m.s.)
Diff_stiff_Rate_PerCor <- cor.test(Diff_stiff,Trochante_DT_Loading_Rate_.m.s.)
plot(Trochante_DT_Loading_Rate_.m.s.,Diff_stiff)
lines(Trochante_DT_Loading_Rate_.m.s.,fitted(Diff_stiff_Rate_LinMod))
segments(Trochante_DT_Loading_Rate_.m.s.,fitted(Diff_stiff_Rate_LinMod),Trochante_DT_Loading_Rate_.m.s.,Diff_stiff)
qqnorm(resid(Diff_stiff_Rate_LinMod))

# prediction and confidence bands can be plotted using the procedurew on page 117 (CH6, page 9) of Dalgaard
# pred.frame <- data.frame(load.rate=seq(from=0,to=0.8,by=0.8/(length(Trochante_DT_Loading_Rate_.m.s.[!is.na(Trochante_DT_Loading_Rate_.m.s.)])-1)))
# pp <- predict(Diff_stiff_Rate_LinMod,int="p",na.action=na.omit,newdata=pred.frame)
# pc <- predict(Diff_stiff_Rate_LinMod,int="c",na.action=na.omit,newdata=pred.frame)
# pred.rate <- pred.frame$load.rate
# matlines(Trochante_DT_Loading_Rate_.m.s.,pp,lty=c(1,2,3),col="black")
# matlines(pred.rate,pp,lty=c(1,2,3),col="black")

# some plots to check out:
# histograms
# hist(Droptower.N.m.)
# hist(Instron.N.m.)
# hist(Trochante_DT_Loading_Rate_.m.s.)
# hist(Max_DT.Force_.N.)
# hist(DXA_Score)

# normal q-q plot (a stright line indicates a normal distribution page 74)
# qqnorm(Droptower.N.m.)
# qqnorm(Instron.N.m.)
# qqnorm(Trochante_DT_Loading_Rate_.m.s.)
# qqnorm(Max_DT.Force_.N.)
# qqnorm(DXA_Score)



# box plots
# agrigate box plots of drop tower and stiffness
# get the ylimits for plotting next to each other
hDT <- boxplot(Droptower.N.m./1000000,plot=F)
hIn <- boxplot(Instron.N.m./1000000,plot=F)
ylims <- range(hDT$out, hDT$stats, hIn$out, hIn$stats)
ylim <- c(floor(min(ylims)),ceiling(max(ylims)))
par(mfrow=c(1,2),cex.axis=1.5) # tell R that you are plottin "multi-frame, rowwise 1x2" layout
boxplot(Droptower.N.m./1000000,ylim=ylim)
yaxData <- par("yaxp")
abline(h=seq(yaxData[1],yaxData[2],(yaxData[2]-yaxData[1])/yaxData[3]),lty=3)
mtext(text="Drop Tower",side=1,line=1,cex=2)
mtext(text="kN/mm",side=2,line=2.5,cex=2)
boxplot(Instron.N.m./1000000,ylim=ylim)
yaxData <- par("yaxp")
abline(h=seq(yaxData[1],yaxData[2],(yaxData[2]-yaxData[1])/yaxData[3]),lty=3)
mtext(text="Instron",side=1,line=1,cex=2)
par(mfrow=c(1,1)) # go back to a 1x1 layout
title(main="Stiffness in the Drop Tower and Instron",cex.main=2.2)

# boxplots of DT and Instron by DXA classification
hDT <- boxplot(Droptower.N.m./1000000,plot=F)
hIn <- boxplot(Instron.N.m./1000000,plot=F)
ylims <- range(hDT$out, hDT$stats, hIn$out, hIn$stats)
ylim <- c(floor(min(ylims)),ceiling(max(ylims)))
par(mfcol=c(2,1),cex.axis=1.5)
plot(Droptower.N.m./1000000~DXA_Classification,ylab="Stiffness kN/mm",ylim=ylim)
yaxData <- par("yaxp")
abline(h=seq(yaxData[1],yaxData[2],(yaxData[2]-yaxData[1])/yaxData[3]),lty=3)
plot(Instron.N.m./1000000~DXA_Classification,ylab="Stiffness kN/mm",ylim=ylim)
abline(h=seq(yaxData[1],yaxData[2],(yaxData[2]-yaxData[1])/yaxData[3]),lty=3)
par(mfcol=c(1,1))
title(main="Stiffnesses in the Drop Tower and Instron \nGrouped by OP Status",cex.main=2.2)