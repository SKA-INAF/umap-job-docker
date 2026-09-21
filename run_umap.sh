#!/bin/bash -e

# NB: -e makes script to fail if internal script fails (for example when --run is enabled)

#######################################
##         CHECK ARGS
#######################################
NARGS="$#"
echo "INFO: NARGS= $NARGS"

if [ "$NARGS" -lt 1 ]; then
	echo "ERROR: Invalid number of arguments...see script usage!"
  echo ""
	echo "**************************"
  echo "***     USAGE          ***"
	echo "**************************"
 	echo "$0 [ARGS]"
	echo ""
	echo "=========================="
	echo "==    ARGUMENT LIST     =="
	echo "=========================="
	echo "*** MANDATORY ARGS ***"
	echo "--inputfile=[FILENAME] - Input file name (.json) containing images to be processed."
	echo ""

	echo "*** OPTIONAL ARGS ***"
	echo "=== INPUT OPTIONS ==="
	echo "--datalist-key=[KEY] - Dictionary key name to be read in input datalist. Default: data"
	echo "--selcols=[COLS] - Data column ids to be selected from input data, separated by colons"
	echo ""
	
	echo "=== UMAP OPTIONS ==="
	echo "--predict - Predict data encoding using input UMAP model. Default: False"
	echo "--model=[MODEL] - UMAP model filename (.h5) when using predict mode"
	echo "--nfeats=[NFEATS] - Encoded data dim in UMAP. Default: 2"
	echo "--mindist=[MINDIST] - Min dist UMAP par. Default: 0.1"
	echo "--nneighbors=[NN] - N neighbors UMAP par. Default: 15"
	echo ""
	
	echo "=== DATA PRE-PROCESSING OPTIONS ==="
	echo "--normalize - Apply minmax normalization to images "
	echo "--scalerfile=[SCALER_FILE] - Load and use data transform stored in this file (.sav)."
	echo "--classid-label-map=[DICT] - Class ID label dictionary. Will take labels from input dictionary label field if left empty. Default: empty"
	echo "--objids-excluded-in-train=[OBJIDS] - Source ids, separated by colons, not included for supervised UMAP training as considered unknown classes. Default: -1:0"		
	echo ""
	
	echo "=== SAVE OPTIONS ==="
	echo "--no-save-ascii - Disable save output to ascii format "
	echo "--no-save-json - Disable save output to json format  "
	echo "--outfile-unsup=[FILENAME] - Name of UMAP encoded data output file. Default: latent_data_umap_unsupervised.dat"
	echo "--outfile-unsup-json=[FILENAME] - Name of UMAP encoded data output file in json format. Default: latent_data_umap_unsupervised.json"
	echo "--outfile-sup=[FILENAME] - Name of UMAP output file with encoded data produced using supervised method (if label data available). Default: latent_data_umap_unsupervised.dat"
	echo "--outfile-preclass=[FILENAME] - Name of UMAP output file with encoded data produced from pre-classified data (if available). Default: latent_data_umap_preclass.dat"
	echo "--save-labels-in-ascii - Save class labels to ascii. Default: False (save class ids) "
	
	echo "=== RUN OPTIONS ==="
	echo "--run-supervised - Run UMAP also on labelled data alone (if available)."	
	echo "--run - Run the generated run script on the local shell. If disabled only run script will be generated for later run."	
	echo "--scriptdir=[SCRIPT_DIR] - Job directory where to find scripts (default=/usr/bin)"
	echo "--modeldir=[MODEL_DIR] - Job directory where to find model & weight files (default=/opt/models)"
	echo "--jobdir=[JOB_DIR] - Job directory where to run (default=pwd)"
	echo "--outdir=[OUTPUT_DIR] - Output directory where to put run output file (default=pwd)"
	echo "--waitcopy - Wait a bit after copying output files to output dir (default=no)"
	echo "--copywaittime=[COPY_WAIT_TIME] - Time to wait after copying output files (default=30)"
	echo "--no-logredir - Do not redirect logs to output file in script "	
	echo "=========================="
  exit 1
fi


#######################################
##         PARSE ARGS
#######################################
# - Run options
JOB_DIR=""
JOB_OUTDIR=""
SCRIPT_DIR="/usr/bin"
RUN_SCRIPT=false
WAIT_COPY=false
COPY_WAIT_TIME=30
REDIRECT_LOGS=true

# - Input options
DATALIST=""
DATALIST_GIVEN=false
DATALIST_KEY="data"
SELCOLS=""

# - UMAP options
PREDICT=""
MODEL=""
NFEATS=2
MINDIST=0.1
NN=15

# - Data pre-processing options
NORMALIZE=""
SCALERFILE=""
CLASSID_LABEL_MAP=""
OBJS_EXCLUDED_IN_TRAIN="-1:0"
RUN_SUPERVISED=""
NO_SAVE_ASCII=""
NO_SAVE_JSON=""
NO_SAVE_MODEL=""

# - Save options
SAVE_LABELS=""
OUTFILE_UNSUP="latent_data_umap_unsupervised.dat"
OUTFILE_UNSUP_JSON="latent_data_umap_unsupervised.json"
OUTFILE_SUP="latent_data_umap_supervised.dat"
OUTFILE_PRECLASS="latent_data_umap_preclass.dat"


for item in "$@"
do
	case $item in 
		# **************************
		# **   MANDATORY
		# **************************
		# - INPUT OPTIONS 	
    --inputfile=*)
    	DATALIST=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`		
			if [ "$DATALIST" != "" ]; then
				DATALIST_GIVEN=true
			fi
    ;;
    --datalist-key=*)
    	DATALIST_KEY=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --selcols=*)
    	SELCOLS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    
    # **************************
		# **   OPTIONAL OPTIONS 
		# **************************
		# - UMAP options
		--predict*)
    	PREDICT="--predict"
    ;;
		--model=*)
    	MODEL=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --nfeats=*)
    	NFEATS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --mindist=*)
    	MINDIST=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --nneighbors=*)
    	NN=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		
		# - PREPROC OPTIONS
		--normalize*)
    	NORMALIZE="--normalize"
    ;;
    --scalerfile=*)
    	SCALERFILE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --classid-label-map=*)
    	CLASSID_LABEL_MAP=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --objids-excluded-in-train=*)
    	OBJS_EXCLUDED_IN_TRAIN=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    
    # - SAVE OPTIONS
    --no-save-ascii*)
    	NO_SAVE_ASCII="--no_save_ascii"
    ;;
    --no-save-json*)
    	NO_SAVE_JSON="--no_save_json"
    ;;
    --no-save-model*)
    	NO_SAVE_MODEL="--no_save_model"
    ;;
    --outfile-unsup=*)
    	OUTFILE_UNSUP=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --outfile-unsup-json=*)
    	OUTFILE_UNSUP_JSON=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --outfile-sup=*)
    	OUTFILE_SUP=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --outfile-preclass=*)
    	OUTFILE_PRECLASS=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --save-labels-in-ascii*)
    	SAVE_LABELS="--save_labels_in_ascii" 
    ;;
    
	
		# - RUN OPTIONS
		--run-supervised*)
    	RUN_SUPERVISED="--run_supervised"
    ;;
    --run*)
    	RUN_SCRIPT=true
    ;;
    --scriptdir=*)
    	SCRIPT_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    
    --outdir=*)
    	JOB_OUTDIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--waitcopy*)
    	WAIT_COPY=true
    ;;
		--copywaittime=*)
    	COPY_WAIT_TIME=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --jobdir=*)
    	JOB_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --no-logredir*)
			REDIRECT_LOGS=false
		;;
    
    *)
    # Unknown option
    echo "ERROR: Unknown option ($item)...exit!"
    exit 1
    ;;
	esac
done


## Check arguments parsed
if [ "$DATALIST_GIVEN" = false ]; then
  echo "ERROR: Missing or empty DATALIST args (hint: you must specify it)!"
  exit 1
fi

if [ "$JOB_DIR" = "" ]; then
  echo "WARN: Empty JOB_DIR given, setting it to pwd ($PWD) ..."
	JOB_DIR="$PWD"
fi

if [ "$JOB_OUTDIR" = "" ]; then
  echo "WARN: Empty JOB_OUTDIR given, setting it to pwd ($PWD) ..."
	JOB_OUTDIR="$PWD"
fi

#######################################
##   SET OPTIONS
#######################################
INPUT_OPTS="--inputfile=$DATALIST --datalist_key=$DATALIST_KEY --selcols=$SELCOLS "
PREPROC_OPTS="$NORMALIZE --scalerfile=$SCALERFILE --classid_label_map=$CLASSID_LABEL_MAP --objids_excluded_in_train=$OBJS_EXCLUDED_IN_TRAIN "
UMAP_OPTS="--modelfile_umap=$MODEL $PREDICT --latentdim_umap=$NFEATS --mindist_umap=$MINDIST --nneighbors_umap=$NN "
SAVE_OPTS="--outfile_umap_unsupervised=$OUTFILE_UNSUP --outfile_umap_supervised=$OUTFILE_SUP --outfile_umap_preclassified=$OUTFILE_PRECLASS --outfile_umap_unsupervised_json=$OUTFILE_UNSUP_JSON $SAVE_LABELS $NO_SAVE_ASCII $NO_SAVE_JSON $NO_SAVE_MODEL "
RUN_OPTS="$RUN_SUPERVISED "

#######################################
##   DEFINE GENERATE EXE SCRIPT FCN
#######################################
# - Set shfile
shfile="run_umap.sh"

# - Set log file
logfile="out.log"

generate_exec_script(){

	local shfile=$1
	
	
	echo "INFO: Creating sh file $shfile ..."
	( 
			echo "#!/bin/bash -e"
			
      echo " "
      echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         PREPARE JOB                     ****"'
      echo 'echo "*************************************************"'

      echo " "
       
      echo "echo \"INFO: Entering job dir $JOB_DIR ...\""
      echo "cd $JOB_DIR"

			echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         RUN CLASSIFIER                  ****"'
      echo 'echo "*************************************************"'
				
			EXE="python $SCRIPT_DIR/run_umap.py" 
			ARGS="$INPUT_OPTS $PREPROC_OPTS $UMAP_OPTS $SAVE_OPTS $RUN_OPTS "
			CMD="$EXE $ARGS"

			echo "date"
			echo ""
		
			echo "echo \"INFO: Running UMAP ...\""
			
			if [ $REDIRECT_LOGS = true ]; then			
      	echo "$CMD >> $logfile 2>&1"
			else
				echo "$CMD"
      fi
      
			echo " "

			echo 'JOB_STATUS=$?'
			echo 'echo "UMAP run terminated with status=$JOB_STATUS"'

			echo "date"

			echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         COPY DATA TO OUTDIR             ****"'
      echo 'echo "*************************************************"'
      echo 'echo ""'
			
			if [ "$JOB_DIR" != "$JOB_OUTDIR" ]; then
				echo "echo \"INFO: Copying job outputs in $JOB_OUTDIR ...\""
				echo "ls -ltr $JOB_DIR"
				echo " "

				echo "# - Copy output data"
				echo 'tab_count=`ls -1 *.dat 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output table file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.dat $JOB_OUTDIR"
				echo "fi"

				echo " "
				
				echo 'tab_count=`ls -1 *.json 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output json file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.json $JOB_OUTDIR"
				echo "fi"
				
				echo " "
				
				echo 'tab_count=`ls -1 *.log 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output log file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.log $JOB_OUTDIR"
				echo "fi"
				
				echo " "
				
				echo 'tab_count=`ls -1 *.sav 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output model & data loader file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.sav $JOB_OUTDIR"
				echo "fi"
				
				echo " "
		
				echo "# - Show output directory"
				echo "echo \"INFO: Show files in $JOB_OUTDIR ...\""
				echo "ls -ltr $JOB_OUTDIR"

				echo " "

				echo "# - Wait a bit after copying data"
				echo "#   NB: Needed if using rclone inside a container, otherwise nothing is copied"
				if [ $WAIT_COPY = true ]; then
           echo "sleep $COPY_WAIT_TIME"
        fi
	
			fi

      echo " "
      echo " "
      
      echo 'echo "*** END RUN ***"'

			echo 'exit $JOB_STATUS'

 	) > $shfile

	chmod +x $shfile
}
## close function generate_exec_script()

###############################
##    RUN UMAP
###############################
# - Check if job directory exists
if [ ! -d "$JOB_DIR" ] ; then 
  echo "INFO: Job dir $JOB_DIR not existing, creating it now ..."
	mkdir -p "$JOB_DIR" 
fi

# - Moving to job directory
echo "INFO: Moving to job directory $JOB_DIR ..."
cd $JOB_DIR

# - Generate run script
echo "INFO: Creating run script file $shfile ..."
generate_exec_script "$shfile"

# - Launch run script
if [ "$RUN_SCRIPT" = true ] ; then
	echo "INFO: Running script $shfile to local shell system ..."
	$JOB_DIR/$shfile
fi


echo "*** END SUBMISSION ***"

