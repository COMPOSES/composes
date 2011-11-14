# given a matrix A whose rows represent element of interest and the
# t(V) matrix coming out of truncated SVD, this script produces the
# matrix obtained by projecting the row vectors of A onto the V space

# A is a mxn matrix (with an extra column at the beginning for the row
# labels), V is a nxk matrix, and thus its transpose, the input matrix
# t(V), is a kxn matrix

## reading input arguments

## 1) input A matrix file
A.ifile = commandArgs()[4]
print(paste("input A file is",A.ifile))

## 2) input t(V) matrix file
Vt.ifile = commandArgs()[5]
print(paste("input t(V) file is",Vt.ifile))

## 3) output file name
ofile =  commandArgs()[6]
print(paste("output matrix will go to file",ofile))

## read A with labels in first col
print("reading and processing A matrix")

labels.A = read.table(A.ifile,header=FALSE)

rowlabels=as.character(labels.A[1:nrow(labels.A),1])

A=as.matrix(labels.A[,2:ncol(labels.A)])

rm(labels.A)


## read t(V)
print("reading t(V) matrix")

Vt = read.table(Vt.ifile,header=FALSE)

## multiply:
print("multiplying")
## we want same precision as in the output of svdlibc
projected <- apply(A %*% t(Vt),2, function(x) sprintf("%.4f",x)) 


# printing to out file
print("producing output file")
# hack for single item case
if (length(rowlabels)==1) {
   write.table(data.frame(rowlabels,t(projected)),ofile,quote=FALSE,sep="\t",row.names=FALSE,col.names=FALSE)
} else {
   write.table(data.frame(rowlabels,projected),ofile,quote=FALSE,sep="\t",row.names=FALSE,col.names=FALSE)
}

print("all done")

quit(save="no")



