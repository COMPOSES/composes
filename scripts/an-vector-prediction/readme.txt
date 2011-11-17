___________________________________________

Pipeline to Generate/Evaluate AN Vectors 
___________________________________________

** Compositionality Models **
    1. Addition
    2. Multiplication
    3. Dilation Model
    4. Linear Model (Emiliano-Style)
    5. Adjective-Specific Linear Model (EMNLP-2010-Style)

___________________________________________

** Generate qsub script for full run of pipeline **

Scripts located between scripts/an-vector-prediction/bin/ and
scripts/task-independent/ and scripts/dim-prediction/


1. Create qsub script for AN Vector Prediction (Step 1 of Pipeline)
   Usage: create_anVectors_qsub_script.sh [test-an-file] [output-directory] [data-directory]

   * To run qsub script:
     Usage: qsub [output-directory]/anVectors-full-run.sh


2. Create qsub script for Evaluation of Predicted AN Vectors (Step 2 of Pipeline)
   Usage: create_vectorEval_qsub_script.sh [test-an-file] [output-directory] [data-directory]

   * To run qsub script:
     Usage: qsub [output-directory]/vectorEval-full-run.sh


Note: The qsub script will be printed to and run in the specified output-directory

___________________________________________

** PIPELINE **

Scripts located in /mnt/8tera/shareZBV/data/eva/an-vector-prediction/scripts/


Step 1. AN Vector Prediction
   Usage: 
	file-prep-an-vectors.sh [test-an-file] [output-directory]
	generate-an-vectors.sh [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]


Step 2. Evaluation of Predicted AN Vectors
   Usage: 
	file-prep-vector-eval.sh [test-an-file] [output-directory]
	evaluate-an-vector-predictions.sh [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]

___________________________________________

** Description of Command Line Arguments **

--[test-an-file]
	* Full path
	* Format: one AN per line in format "adj-j_noun-n"

--[output-directory]
	* Full path of the output directory
	* NOTE: should be the same for all scripts

--[data-directory]
	* Full path where the full/reduced Semantic Spaces are stored
	* Expected to include a directory an-sets/ which contains devel, test and training AN datasets
	*     NOTE: these datasets are updated automatically when the semantic space is built
	* Default (with generated qsub script): /mnt/8tera/shareZBV/data/an-vector-pipeline/data/

--[model]
	* This parameter specifies which compositionality model to use
	* options: add | mult | lm | alm

--[semantic-space]
	* This parameter specifies which Semantic Space to use
	* options: reduced | full
	*     space="reduced": models use the SVD-reduced space (300 dimensions)
	*     space="full": models use the non-reduced space (10K dimensions)
	* Note: the linear models are *not* executed on the full space (memory reasons)

--[norm]
	* This parameter is specifically for the Addition and Multiplication models
	* options: nonnormalized | normalized
	*     norm="nonnormalized": the models use the raw A and N vectors from the Semantic Space
	*     norm="normalized": the models use NORMALIZED A and N vectors

--[param]
	* Specify model-specific parameters
	* add,mult: {none, 4a6n, 3a7n, 6a4n, 7a3n}
	*     param="none": NO weighted addition or multiplication
	*     param="XaYn": use weighted addition or multiplication where
	*		AN = 0.X*a + 0.Y*n  || AN = 0.X*a * 0.Y*n
	* lm: {300, 200, 100}
	*     param is the number of training items for the Emi-Style Linear Model
	* alm: {50, 40, 30, 20, 10}
	*     param is the number of training items for the Adj-Specific Linear Model

___________________________________________

(eof)

