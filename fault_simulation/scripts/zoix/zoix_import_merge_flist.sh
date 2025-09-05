#!/usr/bin/bash


cd `dirname $0`
script_dir=${PWD}
cd - &>/dev/null
script_name=`basename $0`

#-----------------------------------------------
# FIXED VALUES
#-----------------------------------------------


#-----------------------------------------------
# MAIN
#-----------------------------------------------


usage() {
   echo "${script_name} - Convert fault list from testmax to Z01X format"
   echo " "
   echo "usage: ${script_name} (no options) - interactive mode"
   echo "or     ${script_name} options      - command mode"
   echo " "
   echo "options:"
   echo "-import                          import opt"
   echo "import options:                           "
   echo "-input-tool-format 					input tool format"
   echo "-fault-model				         fault model"
   echo "-input-fault-list				      fault list path"
   echo " "
   echo "-merge"
   echo "merge optioss"
   echo "-input-fault-report              fault lists to merge"
   echo "-output                          output file name of merge"
   echo ""
   echo "-h, --help                show brief help"
   echo " "
}


input_tool_format_opt=false
input_tool_format=""
fault_model=""
fault_model_opt=false
input_fault_list=""
input_fault_list_opt=false
merge_opt=false
import_opt=false
declare -a fault_lists
superimposed_fault_list="merged"

# GET OPTIONS
interactive_mode=true
while test $# -gt 0; do
   case "$1" in
      -h|--help)
         usage
         exit 0
         ;;
      -import)
         if ${import_opt}; then
            echo "-import: option redundant" >&2
            exit 1
         fi
         import_opt=true
         shift
         interactive_mode=false
         ;;
      -merge)
         if ${merge_opt}; then
            echo "-merge: option redundant" >&2
            exit 1
         fi
         merge_opt=true
         shift
         interactive_mode=false
         ;;
         -output)
         if ${output_opt}; then
            echo "-output: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            superimposed_fault_list=$1
            output_opt=true
         else
           echo "-output: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;
 
      -input-tool-format)
         if ${input_tool_format_opt}; then
            echo "-input-tool-format: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            input_tool_format=$1
            input_tool_format_opt=true
         else
           echo "-input-tool-format: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;
 
         -fault-model)
         if ${fault_model_opt}; then
            echo "-fault-model: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            fault_model=$1
            fault_model_opt=true
         else
           echo "-fault-model: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;
		
	  -input-fault-list)
         if ${input_fault_list_opt}; then
            echo "-input-fault-list: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            input_fault_list=$1
            input_fault_list_opt=true
         else
           echo "-input-fault-list: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;

      *)
         interactive_mode=false
         break
         ;;
   esac
done



if ${interactive_mode}; then

#---------------------------------------------------------
# INTERACTIVE MODE
#---------------------------------------------------------

   echo "Interactive mode. Use -h for the option list."
   ## ask for input tool format to import

   # ask for import 
   read -p "Import fault list in Z01X [yN]: " -n 1 -r
   [[ $REPLY =~ ^[Yy]$ ]] && import_opt=true || import_opt=false
   echo
   
   # ask for merge
   read -p "Merge Z01X fault list  [yN]: " -n 1 -r
   [[ $REPLY =~ ^[Yy]$ ]] && merge_opt=true || merge_opt=false
   echo

   if ${import_opt} ; then 
   ## for avoiding mess with tmax2
   if [[ "${SDENV_ATPG_TOOL}" == "tmax2" ]] ; then 
      input_tool_format="tetramax"
   fi 
      
   echo "Environment fault model ${SDENV_FAULT_MODEL}"
   ## ask for fault list to convert 
   flists=`find ${SDENV_ATPG_FAULT_LIST_DIR} -name "*${SDENV_FAULT_MODEL}*.fau"|remove_str "${SDENV_ATPG_FAULT_LIST_DIR} "|sort`
   if [ -z "${flists}" ]; then
      echo "No fault list found in ${SDENV_ATPG_FAULT_LIST_DIR}" >&2
      exit 1
   fi
   echo "Select a fault list in ${SDENV_ATPG_FAULT_LIST_DIR}:"
   select input_fault_list in ${flists}; do
      if [ -z "${input_fault_list}" ]; then
         echo "wrong choice" >&2
      else
         break
      fi
   done
   input_fault_list_path=${SDENV_ATPG_FAULT_LIST_DIR}
   input_fault_list=$(basename ${input_fault_list} .fau)
   fi 


   if ${merge_opt}; then 

   ## to be fixed

   #evcd_set=""
   i=0
   ## select evcd to intersect stop on None command 
   echo "Choose fault lists to be intersected for ${SDENV_DESIGN} (None for end acquisition):"
   fault_lists=$(find ${SDENV_FSIM_RESULTS_DIR}  -name "*.fr" -type f ! \( -name "doc" -o -name "scripts" -o -name "tags" \) | remove_str "${SDENV_FSIM_RESULTS_DIR}/" | sort)
   fault_lists=${fault_lists}" All None"

   select fault_list_tmp in ${fault_lists}; do	
   if [ -z "${fault_list_tmp}" ]; then
   echo "wrong choice" >&2
   elif [[ "None" == "${fault_list_tmp}" ]] ; then
   break
   elif [[ "All" ==  "${fault_list_tmp}" ]] ; then 	
   fault_lists=$(find ${SDENV_FSIM_RESULTS_DIR}"/"  -name "*.fr" -type f ! \( -name "doc" -o -name "scripts" -o -name "tags" \) | sort)
   # just for being sure
   #evcd_set[i]="${evcd_file}" # not removed the basename nor the extensions
   i=$((i+1))
   break
   else
   ## increment i 
   fault_lists[i]="${SDENV_FSIM_RESULTS_DIR}/${fault_list_tmp}"
   i=$((i+1))
   fi
   done


   ##choose output name 
   while :; do
   read -e -p "Output file name name: " -i "${superimposed_fault_list}" superimposed_fault_list
   [ -z "${superimposed_fault_list}" ] || break
   done

   fi 
else
#---------------------------------------------------------
# COMMAND MODE
#---------------------------------------------------------
   # check missing/redundant options

   if ! ${input_tool_format_opt} || ! ${fault_model_opt} || ! ${input_fault_list_opt} || ! ${merge_opt} || ! ${import_opt}; then
      echo "Missing required options"
      usage
      exit 1
   fi

   if test $# -gt 0; then
      echo "Redundant arguments."
      usage
      exit 1
   fi


fi

if ${import_opt} ; then 
## create the folder in case it does not exist
if [[ ! -d  "${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/imported_zoix/" ]] ; then 
mkdir ${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/imported_zoix/
fi 

if [[  -f "${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}//imported_zoix/${input_fault_list}_${SDENV_DESIGN}.fdef"  ]] ; then 
   echo "${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}//imported_zoix/${input_fault_list}_${SDENV_DESIGN}.fdef already imported"
   exit 0
fi 


if [[ -d "${SDENV_FSIM_DIR}/image_structural" ]] ; then 
cd ${SDENV_FSIM_DIR}/image_structural
elif [[ -d "${SDENV_FSIM_DIR}/image_functional" ]] ; then 
cd ${SDENV_FSIM_DIR}/image_functional
else
echo "ERROR: Need to elaborate a design first!"
exit 1 
fi

if [[ -z "${SDENV_FSIM_IMPORT_HIERARCHICAL_PATH_TO_REMOVE}" ]]; then 
cat ${input_fault_list_path}/${input_fault_list}.fau > tmp.fau 
else 
## reduce the compleixity (this is done in order to avoid warning for hierarchy filtering)
cat ${input_fault_list_path}/${input_fault_list}.fau | grep ${SDENV_FSIM_IMPORT_HIERARCHICAL_PATH_TO_REMOVE} > tmp.fau 
fi 

opt_fr2fdef=""
if [[ "${SDENV_FAULT_MODEL}" == "Transition" || "${SDENV_FAULT_MODEL}" == "SDF" ]] ; then 
opt_fr2fdef="+transition"
fi 
##import and translate

import_translate_cmd="fr2fdef -fr tmp.fau  +format+${input_tool_format} +design+${SDENV_DESIGN} \
   -fdef ${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/imported_zoix/${input_fault_list}_${SDENV_DESIGN}.fdef +template+${SDENV_FSIM_FAULT_LIST_TEMPLATE} \
   -fstrobe  ${SDENV_FSIM_STROBE_FILE_DIR}/${SDENV_DESIGN}.fstrobe -full_reconvergence_check ${opt_fr2fdef} +verbose \
   -l ${SDENV_FSIM_LOG_DIR}/fault_list_${SDENV_FAULT_MODEL}_conversion_from_${input_tool_format}_to_zoix_for_${SDENV_DESIGN}.log "

echo "${import_translate_cmd}"
${import_translate_cmd}

if [ $? -eq 0 ]; then
	echo "Error in importing the fault list in Z01X"
	exit 1
fi	

rm -f tmp.fau

fault_report_cmd="fault_report  +design+${SDENV_DESIGN}  +collapseoff -fdef ${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/imported_zoix/${input_fault_list}_${SDENV_DESIGN}.fdef \
         -out ${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/imported_zoix/${input_fault_list}_${SDENV_DESIGN}_from_${input_tool_format}.fr  +format+standard \
         -l ${SDENV_FSIM_LOG_DIR}/fault_list_${SDENV_FAULT_MODEL}_conversion_from_${input_tool_format}_to_zoix_${SDENV_DESIGN}_report.log "

echo "${fault_report_cmd}"
${fault_report_cmd}

if [ $? -ne 0 ]; then
	echo "Error in generating the fault report"
	exit 1
fi

fi # import

if ${merge_opt} ; then 


if [[ ! -d "${SDENV_FSIM_RESULTS_DIR}/merged" ]] ; then 
mkdir ${SDENV_FSIM_RESULTS_DIR}/merged
fi 

if [[ -d "${SDENV_FSIM_DIR}/image_structural" ]] ; then 
cd ${SDENV_FSIM_DIR}/image_structural
elif [[ -d "${SDENV_FSIM_DIR}/image_functional" ]] ; then 
cd ${SDENV_FSIM_DIR}/image_functional
else
echo "ERROR: Need to elaborate a design first!"
exit 1 
fi

opt_fr2fdef=""
if [[ "${SDENV_FAULT_MODEL}" == "Transition" || "${SDENV_FAULT_MODEL}" == "SDF" ]] ; then 
opt_fr2fdef="+transition"
fi 

echo "fr2fdef +verbose+conflict-fr ${fault_lists[*]} -fdef ${SDENV_FSIM_RESULTS_DIR}/merged/${superimposed_fault_list}.fdef  ${opt_fr2fdef} +format+standard +verbose +design+${SDENV_DESIGN} -l fr2fdef_merge.log +template+${SDENV_FSIM_FAULT_LIST_TEMPLATE}"
fr2fdef +verbose+conflict -fr ${fault_lists[*]} -fdef ${SDENV_FSIM_RESULTS_DIR}/merged/${superimposed_fault_list}.fdef +format+standard ${opt_fr2fdef} +verbose +design+${SDENV_DESIGN} -l fr2fdef_merge.log +template+${SDENV_FSIM_FAULT_LIST_TEMPLATE}
 
 echo "fault_report  +design+${SDENV_DESIGN}   +collapseoff -fdef ${SDENV_FSIM_RESULTS_DIR}/merged/${superimposed_fault_list}.fdef ${opt_fr2fdef} -out ${SDENV_FSIM_RESULTS_DIR}/merged/${superimposed_fault_list}.fr +format+standard -l fault_report_merge.log"
fault_report  +design+${SDENV_DESIGN}  +collapseoff -fdef ${SDENV_FSIM_RESULTS_DIR}/merged/${superimposed_fault_list}.fdef ${opt_fr2fdef} -out ${SDENV_FSIM_RESULTS_DIR}/merged/${superimposed_fault_list}.fr +format+standard -l fault_report_merge.log


fi 

cd ${SDENV_WORK_DIR}