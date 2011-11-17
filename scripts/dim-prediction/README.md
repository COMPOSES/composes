# Linear Model Dimension Prediction #

This directory contains scripts used for dimension prediction in the AN Vector Prediction Pipeline.

> plsr_adjnoun_dimension_prediction.R
> * Used to predict AN dimensions using linear regression (partial least squares).

  Parameters:
	- Input File: tab-delimited file with the structure:
	      adj noun indvar1 ... indvarN depvar1 ... depvarM
	      where number of indepenent variables (N) must be passed as an argument (see below)
	- Output file prefix 
	- Number of independent variables 
	  	 ex1: for adjective-specific linear model (Baroni&Zamparelli,2010) 300 for SVD-Reduced semantic space
		 ex2: for Emiliano-style linear model (Guevara,2010) 600 for SVD-Reduced semantic space
	- Number of principal components

  Output:
	- Predicted betas values (file with nxn matrix) 

  Usage Example:
  	R --slave --args ivs-dvs.txt plsr_predicted_dims 300 50 < plsr_adjnoun_dimension_prediction.R

  Notes: 
  	 - In current implementation of adj-specific linear model, condition to check for overtraining.  I.e., only continue if 
	   if [ $(grep -c "^$ADJ_" $outDir/training.matrix.$space) -ge  $[ $almParam*2 ] ]