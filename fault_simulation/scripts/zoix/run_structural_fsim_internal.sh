#!/usr/bin/bash


cd `dirname $0`
script_dir=${PWD}
cd - &>/dev/null
script_name=`basename $0`

#-----------------------------------------------
# FIXED VALUES
#-----------------------------------------------

#-----------------------------------------------
# DEFAULTS VALUES
#-----------------------------------------------
DEFAULT_PROCESSES=1

#-----------------------------------------------
# MAIN
#-----------------------------------------------

declare -i processes
processes=${DEFAULT_PROCESSES}
cores=`grep -c ^processor /proc/cpuinfo`


evcd_dump_opt=false
processes_opt=false
result_dir_opt=false
log_dir_opt=false
golden_sim_opt=false
clean_opt=false
log_dir=${SDENV_FSIM_LOG_DIR}
stil=""
stil_opt=false

usage() {
   echo "${script_name} - Run fault simulation"
   echo " "
   echo "usage: ${script_name} (no options) - interactive mode"
   echo "or     ${script_name} options      - command mode"
   echo " "
   echo "options:"
   echo "-stil    <FILE_PATH>    stil stimulus file path"
   echo "-dump_evcd              enable dumping of evcd"
   echo "-g                      golden simulation"
   echo "-processes <NUM>        the number of processes used in fault simulation (default: ${processes})"
   echo "-result-dir <DIR>       specify a directory to store result files in (default: <fsim-dir>/results/<image-name>/<evcd-name>)"
   echo "-l <PATH>               path to log dir for internal fault simulation log"
   echo "-c                      clean the fault manager database"
   echo " "
   echo "-h, --help                show brief help"
   echo " "
}

# GET OPTIONS
interactive_mode=true
while test $# -gt 0; do
   case "$1" in
      -h|--help)
         usage
         exit 0
         ;;
      -c)
         if ${clean_opt} ; then 
            echo "-c: option redundant" >&2
            exit 1
         fi
         shift 
         clean_opt=true
         interactive_mode=false
         ;; 
      -stil)
         if ${stil_opt}; then
            echo "-stil: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            stil=$1
            stil_opt=true
         else
           echo "-stil: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;
      -dump_evcd)
         if ${evcd_dump_opt}; then
            echo "-dump_evcd: option redundant" >&2
            exit 1
         fi
         shift
         evcd_dump_opt=true
         interactive_mode=false
         ;;
      -g)
         if ${golden_sim_opt}; then
            echo "-g: option redundant" >&2
            exit 1
         fi
         shift
         golden_sim_opt=true
         interactive_mode=false
         ;;
      -processes)
         if ${processes_opt}; then
            echo "-processes: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            processes=$1
            processes_opt=true
         else
           echo "-processes: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;

      -result-dir)
         if ${result_dir_opt}; then
            echo "-result-dir: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            result_dir=$1
            result_dir_opt=true
         else
           echo "-result-dir: no argument specified" >&2
           exit 1
         fi
         shift
         interactive_mode=false
         ;;
      -l)
         if ${log_dir_opt}; then
            echo "-l: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            log_dir=$1
            log_dir_opt=true
         else
           echo "-l: no argument specified" >&2
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
   
   read -e -p "Enter log file path:" -i "${SDENV_FSIM_LOG_DIR}" log_dir
   
   # ask for number of processes
   processes_list=$(seq 1 ${cores})
   echo "Select the number of processes:"
   select processes in ${processes_list}; do
      if [ -z "${processes}" ]; then
         echo "wrong choice" >&2
      else
         break
      fi
   done
   # select the stil stimulus 
    stils=$(find -L ${SDENV_ATPG_STIL_DIR}/  -mindepth 1  -type f -name "*zoix.stil" ! \( -name "doc" -o -name "scripts" -o -name "tags" \) | xargs -I{} basename {} | sort) 
    if [ -z "${stils}" ]; then
      echo "No stils in your workspace." >&2
      exit 1
    fi
    echo "Select an input stil file in ${SDENV_ATPG_STIL_DIR}:"
    select stil in ${stils}; do
       if [ -z "${stil}" ]; then
          echo "wrong choice" >&2
       else
          break
       fi
    done
   stil=${SDENV_ATPG_STIL_DIR}/${stil}

   # ask for logic simulation 
   read -p "Execute golden (logic) simulation? (y/n): " enable_golden
   if [[ "$enable_golden" == "y" ||  "$enable_golden" == "Y" ]]; then 
      golden_sim_opt=true
   fi 
   if ${golden_sim_opt} ; then 
   # ask for dumping the internal vcd
   read -p "Dumping the vcd with internal signals? (y/n): " enable_vcd_dump
   if [[ "$enable_vcd_dump" == "y" ||  "$enable_vcd_dump" == "Y" ]]; then 
      evcd_dump_opt=true
   fi 
   fi 
   

   # ask for the output dir 
   read -e -p "Enter output directory:" -i "${output_dir}" output_dir

   read -p "Clean the fault manager database? (y/n): " enable_clean
   if [[ "$enable_clean" == "y" ||  "$enable_clean" == "Y" ]]; then 
      clean_opt=true
   fi    
else
#---------------------------------------------------------
# COMMAND MODE
#---------------------------------------------------------
   # check missing/redundant options
   if ! ${evcd_opt} ; then
      echo "Missing required options"
      usage
      exit 1
   fi
   if test $# -gt 0; then
      echo "Redundant arguments."
      usage
      exit 1
   fi

   if ! ${stil_opt} ; then 
      echo "Missing required options"
      usage
      exit 1
   fi 

   if [[ ${processes} -lt 1 || ${processes} -gt ${cores} ]]; then
      echo "Error: processes out of range (1-${cores})." >&2
      exit 1
   fi

fi
# get stil name 
stil_path=`abs_path ${stil}`
stil_name=`basename ${stil} .stil`


if [[ ! -z "${SDENV_FSIM_STROBE_TYPE}" ]] ; then 
result_dir=${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/${SDENV_FAULT_MODEL}/structural/${stil_name}_${SDENV_FSIM_STROBE_TYPE}
else
# the results dir
result_dir=${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/${SDENV_FAULT_MODEL}/structural/${stil_name}
fi

# create result dir if it does not exist
mkdir -p ${result_dir} || {
   echo "Error: cannot create ${result_dir}. Abort" >&2
   exit 1
}

echo "Result directory: ${result_dir}"

if [[ ! -f "${SDENV_FSIM_SCRIPTS_DIR}/${SDENV_DESIGN}_structural.fmsh" ]] ; then 
echo "Script for fault simulation of ${SDENV_DESIGN}_structural is wrong"
exit 1
fi 

## exporting variables for fault manager shell
export image_path
export stil_path
export processes
export result_dir
export processes
export stil_name

# Move to the run dir
cd ${SDENV_FSIM_DIR}/image_structural
## here we go for parallel stil loading, otherwise we would get too old 
logic_simulation_cmd="./zoix.${SDENV_DESIGN} +stil+parallel \
+stil+file+${stil_path} \
+stil+dut+${SDENV_SYNTH_TOP_LEVEL_NAME} +stim+sdo+*so +stim+sdi+*si "


if ${golden_sim_opt} ; then 
echo "Running logic simulation with parallel load"
if ${evcd_dump_opt} ; then 
   ## dump the vcd file for all the signals in the design
   logic_simulation_cmd=${logic_simulation_cmd}" \
         +vcd+dumpvars+${SDENV_FSIM_STROBE_FILE_DIR}/${SDENV_DESIGN}_vcd_dump_probes \
         +vcd+dumpfile+${SDENV_ACTIVATION_INPUT_DIR}/${evcd_name}_zoix.vcd"
   ${logic_simulation_cmd} 
else 
## just run the logic simulation
echo ${logic_simulation_cmd}
   ${logic_simulation_cmd}
fi 


if [ $? -ne 0 ]; then
   echo "Failed Z01x Logic Sim" >&2
   exit 1
fi
fi 

echo "Running structural fault simulation"

## cleanup 
if ${clean_opt} ; then 
   fmsh -blast ${SDENV_DESIGN}
fi 

fault_simulation_cmd="fmsh -load ${SDENV_FSIM_SCRIPTS_DIR}/${SDENV_DESIGN}_structural.fmsh -l ${log_dir}/fsim_internal_${stil_name}.log  -useenv"
${fault_simulation_cmd}

if [ $? -ne 0 ]; then
   echo "Failed Z01x fault Sim" >&2
   exit 1
fi

cd ${script_dir}
exit 0
