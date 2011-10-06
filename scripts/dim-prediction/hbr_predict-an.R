## Usage(): 
## R --slave --args [adjective] [adjective_betas_file] [nouns_in_50_space_file] [rand_coef_file] [output_file] < hbr_predict-an.R

## Read the input arguments

## 1) The adjective to analyze
Adj =  commandArgs()[4]
print(paste("adjective in question",Adj))

## 2) Input (Betas) file
ifile = commandArgs()[5]
print(paste("betas file is ",ifile))

## 3) Noun Vectors in 300 space
nounFile =  commandArgs()[6]

## 4) random coefficient file
#randFile = commandArgs()[7]
#rand_coef <- read.table(randFile, sep="\t", row.name=1)
predFile = commandArgs()[7]
preds <- read.table(predFile, sep="\t", row.name=1)

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
	adj_betas <- read.table(ifile,sep="\t")
#	ans <- (as.matrix(nouns) %*% as.matrix(adj_betas))

	ans <- matrix(numeric(0),ncol=50)
	for ( r in (1:nrow(nouns))){
                an <- (as.matrix(nouns[r,]) %*% as.matrix(adj_betas) + as.matrix(preds[Adj,]))
		ans <- rbind(ans,an)
	}
	write.table(data.frame(round(ans, digits=4)), ofile, quote=FALSE,sep="\t",row.names=TRUE,col.names=FALSE)
}

## ----------------------------------------------------------------------------------------------------------

print("processing all done")

quit(save="no")
