#!/bin/sh

# Default values

# Function to display help message
show_help() {
    echo "Usage: $0 [-l <log_dir>] [-g] [-o <output_dir>]"
    echo "Options:"
    echo "  -l <log_dir>   : Specify the log file path."
    echo "  -e              : Elaborate design (no argument)."
    echo "  -g              : Enable GUI (no argument)."
    echo "  -o <output_dir> : Specify the output directory (default: ${MoW4EDA_SIM_DIR}/work)."
    echo "  -h              : Display this help message."
}


log_dir=${MoW4EDA_SIMULATION_LOG_DIR}
use_gui=false
output_dir=${MoW4EDA_SIM_DIR}/work
elaborate=false


# Parse command-line options
while getopts ":l:goe:h" opt; do
    case $opt in
        l)
            log_dir="$OPTARG"
            ;;
        g)
            use_gui=true
            ;;
         e)
            elaborate=true
            ;;
        o)
            output_dir="$OPTARG"
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
    read -e -p "Enter log file path:" -i "${MoW4EDA_SIMULATION_LOG_DIR}" log_dir
    read -p "Enable GUI? (y/n): " enable_gui
    read -p "Elaborate the design? (y/n): " enable_elaborate
    if [ "$enable_gui" == "y" ]; then
        use_gui=true
    fi
    if [ "$enable_elaborate" == "y" ]; then 
         elaborate=true
    fi 
    read -e -p "Enter output directory:" -i "${MoW4EDA_SIM_DIR}/work" output_dir
fi

export output_dir

cd ${MoW4EDA_SIM_DIR}
echo "Runnign Simulation with ${MoW4EDA_SIM_TOOL}"


if ${elaborate} ; then 
echo "Running fresh elaboration"

if [[ ! -d "${MoW4EDA_SIM_DIR}/work" ]] ; then 
   mkdir ${MoW4EDA_SIM_DIR}/work
fi
echo "${MoW4EDA_SIMULATION_SCRIPTS_DIR}/elaborate_simulation.sh"
${MoW4EDA_SIMULATION_SCRIPTS_DIR}/elaborate_simulation.sh

fi

if [[ $? -ne 0 ]] ; then 
echo "Elaboration not completed"
exit 1
fi 

if ${use_gui} ; then 
echo "${MoW4EDA_SIMULATION_SCRIPTS_DIR}/simulate.sh -gui"
${MoW4EDA_SIMULATION_SCRIPTS_DIR}/simulate.sh -gui
else 
echo "${MoW4EDA_SIMULATION_SCRIPTS_DIR}/simulate.sh"
${MoW4EDA_SIMULATION_SCRIPTS_DIR}/simulate.sh 

fi 

if [[ $? -ne 0 ]] ; then 
echo "Simulation not completed"
exit 1
fi 

cd ${MoW4EDA_WORK_DIR}
