#!/bin/bash



# Default values

# Function to display help message
show_help() {
    echo "Usage: $0 [-l <log_dir>] [-g] [-o <output_dir>]"
    echo "Options:"
    echo "  -l <log_dir>   : Specify the log file path."
    echo "  -g              : Enable GUI (no argument)."
    echo "  -o <output_dir> : Specify the output directory (default: ${MoW4EDA_ATPG_DIR})."
    echo "  -h              : Display this help message."
}


log_dir=${MoW4EDA_ATPG_LOG_DIR}
use_gui=false
output_dir=${MoW4EDA_ATPG_DIR}
enable_gui="n"

# Parse command-line options
while getopts ":l:go:h" opt; do
    case $opt in
        l)
            log_dir="$OPTARG"
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
    read -e -p "Enter log file path :" -i "${MoW4EDA_ATPG_LOG_DIR}" log_dir
    read -p "Enable GUI? (y/n): " enable_gui
    if [ "$enable_gui" == "y" ]; then
        use_gui=true
    fi
    read -e -p "Enter output directory:" -i "${MoW4EDA_ATPG_DIR}" output_dir
fi

export output_dir

cd ${MoW4EDA_ATPG_DIR}
echo "Runnign ATPG"

if ${use_gui}; then 
echo "${MoW4EDA_ATPG_TOOL}  -tcl ${MoW4EDA_ATPG_SCRIPTS_DIR}/scan_pattern_generation_${MoW4EDA_DESIGN}.tcl -gui"
${MoW4EDA_ATPG_TOOL} -tcl ${MoW4EDA_ATPG_SCRIPTS_DIR}/scan_pattern_generation_${MoW4EDA_DESIGN}.tcl -gui | tee ${log_dir}/log.log

else 
echo "${MoW4EDA_ATPG_TOOL}  -shell -tcl ${MoW4EDA_ATPG_SCRIPTS_DIR}/scan_pattern_generation_${MoW4EDA_DESIGN}.tcl "
${MoW4EDA_ATPG_TOOL} -shell -tcl ${MoW4EDA_ATPG_SCRIPTS_DIR}/scan_pattern_generation_${MoW4EDA_DESIGN}.tcl | tee ${log_dir}/log.log
fi 

cd ${MoW4EDA_WORK_DIR}
