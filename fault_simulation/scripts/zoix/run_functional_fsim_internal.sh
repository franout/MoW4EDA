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


evcd_opt=false
evcd_dump_opt=false
processes_opt=false
result_dir_opt=false
log_dir_opt=false
golden_sim_opt=false
clean_opt=false
log_dir=${SDENV_FSIM_LOG_DIR}

usage() {
   echo "${script_name} - Run fault simulation"
   echo " "
   echo "usage: ${script_name} (no options) - interactive mode"
   echo "or     ${script_name} options      - command mode"
   echo " "
   echo "options:"
   echo "-evcd <PATH>            the eVCD file to load test patterns from"
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
      -evcd)
         if ${evcd_opt}; then
            echo "-evcd: option redundant" >&2
            exit 1
         fi
         shift
         if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
            evcd=$1
            evcd_opt=true
         else
           echo "-evcd: no argument specified" >&2
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
   
   # ask for eVCD
   evcds=`find ${SDENV_FSIM_PATTERNS_DIR}/ -name "*.evcd"|remove_str "${SDENV_FSIM_PATTERNS_DIR}/"|sort`
   if [ -z "${evcds}" ]; then
      echo "No eVCD found in ${SDENV_FSIM_PATTERNS_DIR}" >&2
      exit 1
   fi
   echo "Select an eVCD file in ${SDENV_FSIM_PATTERNS_DIR}:"
   select evcd in ${evcds}; do
      if [ -z "${evcd}" ]; then
         echo "wrong choice" >&2
      else
         break
      fi
   done
   evcd_path=${SDENV_FSIM_PATTERNS_DIR}/${evcd}

   output_dir=${SDENV_FSIM_RESULTS_DIR}/${evcd}
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

   if [ ! -e "${evcd}" ]; then
      echo "Error: ${evcd} not found." >&2
      exit 1
   fi
   evcd_path=${evcd}

   if [[ ${processes} -lt 1 || ${processes} -gt ${cores} ]]; then
      echo "Error: processes out of range (1-${cores})." >&2
      exit 1
   fi

fi

# get absolute paths
evcd_path=`abs_path ${evcd_path}`
evcd_name=`basename ${evcd_path} .evcd`

if [[ ! -z "${SDENV_FSIM_STROBE_TYPE}" ]] ; then 
result_dir=${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/${SDENV_FAULT_MODEL}/${evcd_name}_${SDENV_FSIM_STROBE_TYPE}
else
# the results dir
result_dir=${SDENV_FSIM_RESULTS_DIR}/${SDENV_DESIGN}/${SDENV_FAULT_MODEL}/${evcd_name}
fi

# create result dir if it does not exist
mkdir -p ${result_dir} || {
   echo "Error: cannot create ${result_dir}. Abort" >&2
   exit 1
}

echo "Result directory: ${result_dir}"

if [[ ! -f "${SDENV_FSIM_SCRIPTS_DIR}/${SDENV_DESIGN}.fmsh" ]] ; then 
echo "Script for fault simulation of ${SDENV_DESIGN} is wrong"
exit 1
fi 

## exporting variables for fault manager shell
export image_path
export evcd_path
export processes
export result_dir
export processes
export evcd_name

# Move to the run dir
cd ${SDENV_FSIM_DIR}/image_functional

## check if force signal file is present 
if [[ -f "${SDENV_FSIM_STROBE_FILE_DIR}/${SDENV_DESIGN}_force_signals.tcl" ]] ;then 
zoix_lsim_cmd_forces="-i ${SDENV_FSIM_STROBE_FILE_DIR}/${SDENV_DESIGN}_force_signals.tcl"
echo "Using ${SDENV_FSIM_STROBE_FILE_DIR}/${SDENV_DESIGN}_force_signals.tcl for forcing signals"
fi 

logic_simulation_cmd="./zoix.${SDENV_DESIGN} +vcd+verbose +timescale+override+1ns/1ps \
      ${zoix_lsim_cmd_forces} \
      +vcd+file+${evcd_path} \
      +vcd+dut+${SDENV_FSIM_ELABORATION_TOP_LEVEL_NAME}+${SDENV_FSIM_EVCD_TOP_LEVEL_NAME}"

if ${golden_sim_opt} ; then 
echo "Running logic simulation"
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

echo "Running functional fault simulation"

## cleanup 
if ${clean_opt} ; then 
   fmsh -blast ${SDENV_DESIGN}
fi 

## add strobes in the vcd 
if [[ ! -d "${SDENV_FSIM_DIR}/image_functional/__tmp__/" ]] ; then 
mkdir -p ${SDENV_FSIM_DIR}/image_functional/__tmp__/
fi 
## remove eventually extensions
evcd_name=`basename ${evcd_path} .evcd`

echo "Adding strobe signals in the evcd"
# TODO we can make this design dependent with a related file 
if [[ "${SDENV_DESIGN}" == "systolic_array" ]] ; then 
## drop time unit and move to ps to ns (same unit of vcd file)
export STROBE_OFFSET="3"
export STROBE_PERIOD=$(( ${SDENV_SYNTH_CLOCK_VALUE_NS} * 1000 ))

add_strobe_cmd="addstrobe  -fsgroup ${evcd_path} ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd \
         ${SDENV_FSIM_STROBE_FILE_DIR}/${SDENV_DESIGN}_rtl.fstrobe ${STROBE_PERIOD} ${STROBE_OFFSET} "
else 
## drop time unit and move to ps to ns (same unit of vcd file)
export STROBE_OFFSET="3000"
export STROBE_PERIOD=$(( ${SDENV_SYNTH_CLOCK_VALUE_NS} * 1000 ))

add_strobe_cmd="addstrobe  -fsgroup ${evcd_path} ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd \
         ${SDENV_FSIM_STROBE_FILE} ${STROBE_PERIOD} ${STROBE_OFFSET} "
fi

echo ${add_strobe_cmd}
${add_strobe_cmd}
if [[ "${SDENV_DESIGN}" == "systolic_array" ]] ; then 
## because addstrobe is bugged
echo "tail -n +2 ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd > ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.tmp  && mv -f ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.tmp ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd"
tail -n +2 ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd > ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.tmp  
mv -f ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.tmp ${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd

fi 
export evcd_path="${SDENV_FSIM_DIR}/image_functional/__tmp__/fstrobe.${evcd_name}.evcd" 

fault_simulation_cmd="fmsh -load ${SDENV_FSIM_SCRIPTS_DIR}/${SDENV_DESIGN}.fmsh -l ${log_dir}/fsim_internal_${evcd_name}.log  -useenv"
${fault_simulation_cmd}

if [ $? -ne 0 ]; then
   echo "Failed Z01x fault Sim" >&2
   exit 1
fi

cd ${script_dir}
exit 0
