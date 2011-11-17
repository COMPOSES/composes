# Pipeline to Generate/Evaluate AN Vectors #

## Compositionality Models
1. Baseline Models (adjective and noun only)
2. Addition
3. Multiplication
4. Dilation Model (Mitchell & Lapata, 2010)
5. Linear Model: Emiliano-Style (Guevara, 2010)
6. Adjective-Specific Linear Model (Baroni & Zamparelli, 2010)

## Generate qsub script for a full run of the pipeline ##

**Step 1: AN Vector Prediction**

	$ create_anVectors_qsub_script.sh [test-an-file] [output-directory] [data-directory]
	$ qsub [output-directory]/anVectors-full-run.sh

**Step 2: Evaluation of Predicted AN Vectors**

	$ create_vectorEval_qsub_script.sh [test-an-file] [output-directory] [data-directory]
	$ qsub [output-directory]/vectorEval-full-run.sh

> **Additional Information**
>
> * Scripts located between scripts/an-vector-prediction/bin/ and
scripts/task-independent/ and scripts/dim-prediction/
> * The scripts will generate and evaluate vectors for **all** composition models and parameters

## Details of the Full Pipeline ##

**AN Vector Prediction**

	$ file-prep-an-vectors.sh [test-an-file] [output-directory] [data-directory]
	$ generate-an-vectors.sh [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]

**Evaluation of Predicted AN Vectors**

	$ file-prep-vector-eval.sh [test-an-file] [output-directory] [data-directory]
	$ evaluate-an-vector-predictions.sh [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]

**Description of Command Line Arguments**

	[test-an-file]

> * File Format: one AN per line in format "adj-j_noun-n"

	[output-directory]

> * Full path of the output directory
> * **Note**: should be the same for all scripts

	[data-directory]

> * Full path where the full/reduced Semantic Spaces are stored
> * Expected to include a directory an-sets/ which contains devel, test and training AN datasets
> * **Note**: these datasets and the necessary files are updated automatically when the semantic space is built (use scripts/semantic-space-construction/build-semantic-space.sh)

	[model]

> * This parameter specifies which compositionality model to use
> * Options: adj | ns | add | mult | dl | lm | alm

	[semantic-space]

> * This parameter specifies which Semantic Space to use
> * Options: reduced | full
	*     space="reduced": models use the SVD-reduced space (300 dimensions)
	*     space="full": models use the non-reduced space (10K dimensions)
> * **Note**: the linear models are *not* executed on the full space (memory reasons)

	[norm]

> * This parameter is specifically for the Addition, Multiplication and Dilation models
> * Options: nonnormalized | normalized
	*     norm="nonnormalized": the models use the raw A and N vectors from the Semantic Space
	*     norm="normalized": the models use NORMALIZED A and N vectors

	[param]

> * Specify model-specific parameters
	* add,mult: {none, 4a6n, 3a7n, 6a4n, 7a3n}
		* param="none": NO weighted addition or multiplication
		* param="XaYn": use weighted addition or multiplication where AN = 0.X*a + 0.Y*n  || AN = 0.X*a * 0.Y*n
	* lm: {300, 200, 100, 50, 40, 30, 20, 10}
		* param is the number of latent dimensions for the Emi-Style Linear Model
	* alm: {50, 40, 30, 20, 10}
		* param is the number of latent dimensions for the Adj-Specific Linear Model

___________________________________________

**(eof)**

