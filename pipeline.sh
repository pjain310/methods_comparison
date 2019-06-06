#!/bin/bash

#*******************************************************************************#
#*******************************************************************************#
#Script name: pipeline.sh	                                                    	#
#									                                                             	#
#Usage:						                                                             	#
#									                                                             	#
#Description: A methods comparison pipeline to get performance metrics for      #
#             different pooled CRISPR screen analysis software (MAGeCK-RRA,     #
#             MAGeCK-MLE, BAGEL, CB2, PBNPA, casTLE).                           #
#             INPUT: Read count files                                           #
#             OUTPUT: Directory containing a list of significant gene hits,     #
#             plots of performance metrics                                      #
#										                                                            #
#Arguments:   -i : Location of reads file directory (Required)                  #
#             -c : Location of counts file	(Required)		               	      #
#	            -o : Output directory name (Required)                         		#
#	            -t : Comma separated list  of tools to be used (Options: mageck,  #
#                  bagel, pbnpa,cb2). If not specified, all tools will	        #
#                  be run.                      	                         		  #
#             -v : Verbose mode                                                 #
#             -h : Print usage instructions				                             	#
#										                                                            #
#Author:      Prerna Jain						                                           	#
#*******************************************************************************#
#*******************************************************************************#

print_help() {
  #Description: Prints usage and help when called

  help_message="
  USAGE:       pipeline.sh <add input args here>

  DESCRIPTION: A methods comparison pipeline to get performance metrics for
               different pooled CRISPR screen analysis software (MAGeCK-RRA,
               MAGeCK-MLE, BAGEL, CB2, PBNPA).
               INPUT: Read count files or raw fastq reads
               OUTPUT: Directory containing a list of significant gene hits,
               plots of performance metrics

  ARGUMENTS:   -i : Path to counts file
               -s : Path to sample map file
               -o : Output directory name
               -t : Comma separated list  of tools to be used (Options: mageckrra, mageckmle,
                    bagel, pbnpa, cb2). If not specified, all tools will
                    be run.
               -v : Verbose mode
               -h : Print usage instructions"

  echo "$help_message"
}

prepareDirectory() {
  local dest=$1
  #Check if temp directory is already present.
	if [ -d "$dest" ]
    #If present, give option to rewrite.
    then
  		echo "directory ${dest} already exists, would you like to overwrite? Reply with y/n"
  		read answer
  		case $answer in
  			y) echo "Overwriting temp diectory"
           mkdir -p ${dest};;
  			n) echo "Folder overwrite denied, exiting pipeline"
  				 exit 1;;
  			\?) echo "Incorrect option specified, exiting pipeline"
  				  exit 1;;
  		esac
    #If not, create temp directory
    else mkdir -p ${dest}  # -p is essential when $dest contains subdirectory, such as output/results
	fi
}

# global variable
declare -xa tools

get_input() {
	# Description: Parse input arguments and perform checks

  #Set default values for tools
  # use global variable

	#Getopts block - will take in the arguments as inputs and assign them to variables
  while getopts "i:s:o:t:vh" option; do
    case $option in
      i) counts=$OPTARG;;
      s) sample_map=$OPTARG;;
      o) output_dir=$OPTARG;;
      t) tools+=($OPTARG);;
      v) v=1;;
      h) print_help
          exit 0;;
      \?) echo "Invalid option."
          print_help
          exit 1;;
    esac
  done

  #Check for presence of required arguments (counts file, output directory, sample map file)
  declare -a required_opts=("counts" "output_dir" "sample_map")
  for opt in "${required_opts[@]}"; do 
    if [[ -z ${!opt} ]]; then 
      echo "Missing required option \"$opt\", exiting..." 
      exit $LINENO
    fi
  done

  #Check if output directory is already present. If present, give option to rewrite.
  if ! prepareDirectory $output_dir; then 
    exit $LINENO
  fi
  
  #Check for counts file
  if [ ! -f $counts ]
  then
    echo "Path to counts file incorrect or file missing. Exiting pipeline"
    exit $LINENO
  fi

  #Check for sample map file
  if [ ! -f $sample_map ]
  then
    echo "Path to sample map file incorrect or file missing. Exiting pipeline"
    exit $LINENO
  fi

  #Export variables so that they can be used within xargs
  export counts
  export sample_map

}

convert_output(){
  #Description: Convert output from different software into consistent format for downstream data analysis.
  echo "Op converter"
}

run_mageck(){
  #Description: First, use sample_mapper functions to convert sample map into appropriate format for software.
  #             Second, Run MAGeCK-RRA on counts data.
  #             Third convert output to consistent format using convert_output()
  echo "Running mageckrra"

  mkdir -p temp/mageckrra

  #mageck sampler prints appropriate args from the sample_map to be fed to mageck test
  python -c "from python_modules.sample_mapper import *; mageck_sampler(makeSampleMap('$sample_map'))" | xargs -n3 bash -c 'mageck test -k $counts -t $1 -t $2 -n temp/mageckrra/"$0"_vs_"$2"'

}

run_mageck_mle(){
  #Description: Run MAGeCK-MLE on counts data, convert output to consistent format using convert_output()
  echo "Running mageck mle"
}

run_pbnpa(){
  #Description: Run pbnpa on counts data, convert output to consistent format using convert_output()
  echo "Running pbnpa"
}

run_cb2(){
  #Description: Run cb2 on counts data, convert output to consistent format using convert_output()
  echo "Running cb2"
}

run_bagel(){
  #Description: Run bagel on counts data, convert output to consistent format using convert_output()
  echo "Running bagel"
}



main() {
	# Function that defines the order in which functions will be called

  #Parse input arguments and perform file checks
	get_input "$@"

  #Create temp directory
  if ! prepareDirectory "temp"; then 
    exit $LINENO
  fi 

  #Run tools according to option specified in tools flag
  if [[ -z $tools ]]; then 
    tools=("mageck" "mageck_mle" "pbnpa" "cb2" "bagel")
  fi

  for tool in "${tools[@]}"; do
    if ! run_${tool} ; then 
      echo "Failed to run tool \"${tool}\"..."
    fi
  done

  #rm -r temp

}

# Calling the main function
main "$@"
