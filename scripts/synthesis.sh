#!/bin/bash

# Default values

# Function to display help message
show_help() {
    echo "Usage: $0 [-l <log_dir>] [-g] [-o <output_dir>]"
    echo "Options:"
    echo "  -l <log_dir>   : Specify the log file path."
    echo "  -g              : Enable GUI (no argument)."
    echo "  -o <output_dir> : Specify the output directory (default: ${MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH})."
    echo "  -h              : Display this help message."
}


log_dir=${MoW4EDA_SYN_LOG_DIR}
use_gui=false
output_dir=${MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH}

# Parse command-line options
while getopts ":l:go:h" opt; do
    case $opt in
        l)
            log_log_dirfile="$OPTARG"
            ;;
        g)
            use_gui=true
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
    read -e -p "Enter log file path:" -i "${MoW4EDA_SYN_LOG_DIR}" log_dir
    read -p "Enable GUI? (y/n): " enable_gui
    if [ "$enable_gui" == "y" ]; then
        use_gui=true
    fi
    read -e -p "Enter output directory:" -i "${MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH}" output_dir
fi

export output_dir

if [[ ! -d "${MoW4EDA_SYN_DIR}/work" ]] ; then 
mkdir ${MoW4EDA_SYN_DIR}/work
fi

echo "Running Synthesis"
cd ${MoW4EDA_SYN_DIR}/work
if ${use_gui} ; then 
echo "${MoW4EDA_SYN_TOOL} -f ${MoW4EDA_SYN_SCRIPTS_DIR}/synt_${MoW4EDA_DESIGN}.tcl -output_log_file ${log_dir}/log.txt -no_local_init -gui"
${MoW4EDA_SYN_TOOL} -f ${MoW4EDA_SYN_SCRIPTS_DIR}/synt_${MoW4EDA_DESIGN}.tcl -output_log_file ${log_dir}/log.txt -no_local_init -gui
else 
echo "${MoW4EDA_SYN_TOOL} -f ${MoW4EDA_SYN_SCRIPTS_DIR}/synt_${MoW4EDA_DESIGN}.tcl -output_log_file ${log_dir}/log.txt -no_local_init"
${MoW4EDA_SYN_TOOL} -f ${MoW4EDA_SYN_SCRIPTS_DIR}/synt_${MoW4EDA_DESIGN}.tcl -output_log_file ${log_dir}/log.txt -no_local_init
fi 

cd ${MoW4EDA_SLACK_GENERATOR_TOOL_DIR}

echo "Running slack calculation"
echo "${MoW4EDA_SLACK_GENERATOR_TOOL} -file ${MoW4EDA_SLACK_GENERATOR_SCRIPTS_DIR}/generate_slack_${MoW4EDA_DESIGN}.tcl -output_log_file ${MoW4EDA_SLACK_GENERATOR_TOOL_LOG_DIR}/log.txt "
${MoW4EDA_SLACK_GENERATOR_TOOL} -file ${MoW4EDA_SLACK_GENERATOR_SCRIPTS_DIR}/generate_slack_${MoW4EDA_DESIGN}.tcl -output_log_file ${MoW4EDA_SLACK_GENERATOR_TOOL_LOG_DIR}/log.txt 

cd ${MoW4EDA_WORK_DIR}