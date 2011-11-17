## Usage(): 
## R --slave --args [adjective] [emi_betas_file] [adjective_vector_file] [nouns_in_300_space_file] [output_file] < lm_vector_analysis.R

## 1) The adjective to analyze
Adj = commandArgs()[4]
print(paste("adjective in question",Adj))

## 2) Input (Betas) file
ifile = commandArgs()[5]
print(paste("betas file is ",ifile))

## 3) Adjective Vector in 300 space
vfile = commandArgs()[6]
adj_v<-read.table(vfile,sep="\t",row.name=1)

## 4) Noun Vectors in 300 space
nounFile = commandArgs()[7]

## 5) Output Directory
ofile = commandArgs()[8]
print(paste("output file is ",ofile))

## ----------------------------------------------------------------------------------------------------------

## Functions called within the script 
compute.length=function(x){sqrt(sum(x^2))}
normalize.vector<-function(x){x/sqrt(sum(x^2))}
compute.cosine=function(x,y){sum(x*y)/(sqrt(sum(x^2))*sqrt(sum(y^2)))}

## ----------------------------------------------------------------------------------------------------------

# Get Noun matrices
nouns <- read.table(nounFile, sep="\t", row.name=1)
row.names(nouns) = paste("p.",Adj,"_",row.names(nouns),sep="")

## ----------------------------------------------------------------------------------------------------------

## Get the AN matrices for the specified parameter setting
if ( file.exists(ifile) ) {

	## Betas
	adj_betas <- read.table(ifile,sep="\t")

	## Adj-Nouns
	a_cat_n <- t(apply(as.matrix(nouns),1,function(x){matrix(c(x,as.matrix(adj_v)))}))

	ans <- (as.matrix(a_cat_n) %*% as.matrix(adj_betas))
	row.names(ans) = row.names(nouns)
	write.table(data.frame(round(ans, digits=4)), ofile, quote=FALSE,sep="\t",row.names=TRUE,col.names=FALSE)
}

## ----------------------------------------------------------------------------------------------------------

print("processing all done")

quit(save="no")
