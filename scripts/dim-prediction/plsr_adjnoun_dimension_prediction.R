## we must load the pls package
library(pls)

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
print(paste("output files will be named",
	betas.file))

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

## ind and dep vars
indvars<-as.matrix(d[,first.ind.var.index:last.ind.var.index])
depvars<-as.matrix(d[,first.dep.var.index:ncol(d)])

## from here, I don't think we need d anymore
rm(d)

## an empty matrix to be filled with the prediced values
preds <- matrix(numeric(0),ncol=ncol(depvars))

fitted.model = plsr(depvars~indvars, ncomp=comp.number)

## print fit stats directly to stdout
print("printing results")

print("global model summary")

print(summary(fitted.model))

print("explained variance in total")
print(explvar(fitted.model))

write.table(coef(fitted.model,ncomp=comp.number,intercept=FALSE),betas.file,
            quote=FALSE,sep="\t",row.names=FALSE,col.names=FALSE)

print("processing all done")

quit(save="no")
