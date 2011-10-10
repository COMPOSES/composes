## we must load the lme4 package
library(lme4)

## reading input arguments

## 1) input file
ifile = commandArgs()[4]
print(paste("input file is",ifile))
## above should have structure:
## adj noun indvar1 ... indvarN depvar1 ... depvarM
## where number of indepenent variables (N) must be passed as an
## argument (see below)

## NB: if ind vars contain an all 0 column, the script will die!

## 2) output file prefix
ofilepref =  commandArgs()[5]
betas.file = paste(ofilepref,"betas",sep=".")
preds.file = paste(ofilepref,"preds",sep=".")
rands.file = paste(ofilepref,"rands",sep=".")
#predictions.file = paste(ofilepref,"preds",sep=".")
print(paste("output files will be named", betas.file,preds.file,rands.file))

## 3) number of independent variables
ind.var.count =  as.integer(commandArgs()[6])
print(paste("number of independent variables",ind.var.count))
## we must account for the adj and noun fields
last.ind.var.index = ind.var.count+2
## first ind var must always be at position 3
first.ind.var.index = 3

## first dep var will be after last ind var
first.dep.var.index = last.ind.var.index+1

## 4) number of principal components
comp.number = as.integer(commandArgs()[7])

## other preliminaries
d<-read.table(ifile)

## if there are all-0 columns among the ind vars, we complain and
## quit!
if (sum(colSums(d[,first.ind.var.index:last.ind.var.index]^2)==0)>0) {
  print("no all 0 ind vars allowed!")
  quit(save="no")
}

## in current version, dv must be at least 2!
if (first.dep.var.index>=ncol(d)) {
  print("script needs at least 2 ds!")
  quit(save="no")
}

## the label columns from the data frame
label.columns<-data.frame(d[,1:2])

## +-concatenated names of ivs, extract once and for all
iv.combination=paste(colnames(d[,first.ind.var.index:last.ind.var.index]), collapse="+")

## do the first dimension's fitted model out of the loop (sanity check)
fm = lmer(paste(colnames(d)[first.dep.var.index],'~',iv.combination,'+(1|V1)'), d)
fitted.model <- cbind(fitted(fm))

## matrix (for now empty) to hold the betas
betas<- matrix(numeric(0),ncol=ind.var.count)
## appending the dimension's betas to the betas matrix
betas <- rbind(betas, fixef(fm)[-1])

## getting predictions values for the dimension's fitted model
preds <- cbind(fixef(fm)[1] + ranef(fm)$V1)
## getting random coef values for the dimension's fitted model
rands <- cbind(ranef(fm)$V1)

#predict.lmer <- function(model, X, Zt) {
#        if(missing(X)){
#                X <- model @ X
#        }
#        b <- fixef(model)
#        if(missing(Zt)){
#                Zt <- as.matrix(model @ Zt)
#        }
#        plogis( X %*% b + t(Zt) )
#}

## loop through the dependent variables
for (curr.dep.var.index in (first.dep.var.index+1:ncol(d))) {

	fm = lmer(paste(colnames(d)[curr.dep.var.index],'~',iv.combination,'+(1|V1)'), d)
	fitted.model <- cbind(fitted.model,fitted(fm))

	## appending the dimension's betas to the betas matrix
	betas <- rbind(betas, fixef(fm)[-1])
	
	## getting predictions values for the dimension's fitted model
	preds <- cbind(preds, fixef(fm)[1] + ranef(fm)$V1)
	rands <- cbind(rands, ranef(fm)$V1)
}

write.table(betas,betas.file, quote=FALSE,sep="\t",row.names=FALSE,col.names=FALSE)
write.table(preds,preds.file,quote=FALSE,sep="\t",row.names=TRUE,col.names=FALSE)
write.table(rands,rands.file,quote=FALSE,sep="\t",row.names=TRUE,col.names=FALSE)
write.table(fitted.model,"fitted.model",quote=False,sep="\t",row.names=FALSE,col.names=FALSE)

print("processing all done")

quit(save="no")

