#!/bin/sh

# Default values

# Function to display help message
show_help() {
    echo "Usage: $0 [-l <log_dir>] [-g] [-o <output_dir>]"
    echo "Options:"
    echo "  -l <log_dir>   : Specify the log file path."
    echo "  -e              : Elaborate design (no argument)."
    echo "  -o <output_dir> : Specify the output directory (default: ${MoW4EDA_FSIM_RESULTS_DIR})."
    echo " -d               : Dump evcd during fault simulation"
    echo " -i <file_path>   : stil stimulus file"
    echo " -g               : Execute golden (logic) simulation "
    echo " -p  <num>        : Number of processes for fault simulations"
    echo " -c               : cleun up the fault manager databases"
    echo "  -h              : Display this help message."
}

declare -i processes
processes=${DEFAULT_PROCESSES}
cores=`grep -c ^processor /proc/cpuinfo`


log_dir=${MoW4EDA_FSIM_LOG_DIR}
use_gui=false
output_dir=${MoW4EDA_FSIM_RESULTS_DIR}
elaborate=false
evcd_dump_opt=false
golden_sim_opt=false
stil_opt=false
stil_file_path=""
clean_env=false
# Parse command-line options
while getopts ":l:i:p:o:deghc" opt; do
    case $opt in
        i)
            stil_file_path="$OPTARG"
            stil_opt=true
            ;;
        l)
            log_dir="$OPTARG"
            ;;
         e)
            elaborate=true
            ;;
        c)
            clean_env=true
            ;;
        
        d)
            evcd_dump_opt=true
            ;;
        g)
            golden_sim_opt=true
            ;;
        o)
            output_dir="$OPTARG"
            ;;
        p)
            processes="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            show_help
            exit 1
            ;;
    esac
done

# If no command-line options provided, prompt for interactive input
if [ $OPTIND -eq 1 ]; then
    echo "Interactive mode:"
    read -e -p "Enter log file path:" -i "${MoW4EDA_FSIM_LOG_DIR}" log_dir
    read -p "Elaborate the design? (y/n): " enable_elaborate

    if [ "$enable_elaborate" == "y" ]; then 
         elaborate=true
    fi 
    read -e -p "Enter output directory:" -i "${output_dir}" output_dir
    read -p "Clean the fault manager database? (y/n): " enable_clean

    if [ "$enable_clean" == "y" ]; then 
         clean_env=true
    fi 
   # select the stil stimulus 
    stils=$(find -L ${MoW4EDA_ATPG_STIL_DIR}/  -mindepth 1  -type f -name "*zoix.stil" ! \( -name "doc" -o -name "scripts" -o -name "tags" \) | xargs -I{} basename {} | sort) 
    if [ -z "${stils}" ]; then
      echo "No stils in your workspace." >&2
      exit 1
    fi
    echo "Select an input stil file in ${MoW4EDA_ATPG_STIL_DIR}:"
    select stil_file_path in ${stils}; do
       if [ -z "${stil_file_path}" ]; then
          echo "wrong choice" >&2
       else
          break
       fi
    done
    stil_file_path=${MoW4EDA_ATPG_STIL_DIR}/${stil_file_path}
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
    
   read -p "Execute golden (logic) simulation? (y/n): " enable_golden
   if [[ "$enable_golden" == "y" ||  "$enable_golden" == "Y" ]]; then 
      golden_sim_opt=true
   fi 

   if ${golden_sim_opt} ; then 
   read -p "Dumping the vcd with internal signals? (y/n): " enable_vcd_dump
   if [[ "$enable_vcd_dump" == "y" ||  "$enable_vcd_dump" == "Y" ]]; then 
      evcd_dump_opt=true
   fi 
   fi 

fi

## for avoiding problems between libc and openblas
unset LD_PRELOAD

cd ${MoW4EDA_FSIM_DIR}
echo "Running Structural Fault Simulation with ${MoW4EDA_FSIM_TOOL}"


if ${elaborate} ; then 
echo "Running fresh elaboration"

## clean up first 
if [[ -d "${MoW4EDA_FSIM_DIR}/image_structural" ]] ; then 
rm -rf ${MoW4EDA_FSIM_DIR}/image_structural
fi 
mkdir ${MoW4EDA_FSIM_DIR}/image_structural

echo "${MoW4EDA_FSIM_SCRIPTS_DIR}/elaborate_structural_fsim.sh"
${MoW4EDA_FSIM_SCRIPTS_DIR}/elaborate_structural_fsim.sh -l  ${log_dir}/elaboration_structural.log

fi

if [[ $? -ne 0 ]] ; then 
echo "Elaboration not completed"
exit 1
fi 

if ${evcd_dump_opt} ; then 
dump_evcd_opt=" -dump_evcd "
fi 

if ${golden_sim_opt} ; then 
dump_evcd_opt=${dump_evcd_opt}" -g "
fi 

clean_env_opt=" "
if ${clean_env} ; then 
clean_env_opt="-c "
fi 
echo "${MoW4EDA_FSIM_SCRIPTS_DIR}/run_structural_fsim_internal.sh  -stil ${stil_file_path}  -processes ${processes} ${dump_evcd_opt} -result-dir ${output_dir} ${clean_env_opt}"
${MoW4EDA_FSIM_SCRIPTS_DIR}/run_structural_fsim_internal.sh -stil ${stil_file_path} -processes ${processes} ${dump_evcd_opt} -result-dir ${output_dir} -l ${log_dir} ${clean_env_opt}|  tee ${log_dir}/fsim_structural.log

if [[ $? -ne 0 ]] ; then 
echo "Structural Fault Simulation not completed"
exit 1
fi 

cd ${MoW4EDA_WORK_DIR}
