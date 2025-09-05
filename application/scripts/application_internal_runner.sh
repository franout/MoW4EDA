#!/bin/bash
# This is a placeholder script for running the application once compiled.
# TODO The actual implementation would depend on the specific application requirements.
# TODO applications can be executed on different simulated platforms (for example gem5, logic simulation, qemu, etc)

cd `dirname $0`
script_dir=${PWD}
cd - &>/dev/null
script_name=`basename $0`

#---------------------------------------------------------------
# FIXED VALUES
#-----------------------------------------------

#-----------------------------------------------
# DEFAULTS VALUES
#-----------------------------------------------
DEFAULT_APPLICATIONS_DIR=${MoW4EDA_APPLICATIONS_DIR}

#-----------------------------------------------
# LOCAL SCRIPTS
#-----------------------------------------------
usage() {
    echo "${script_name} - run a given application"
    echo " "
    echo "usage: ${script_name} (no options) - interactive mode"
    echo "or     ${script_name} options      - command mode"
    echo " "
    echo "options:"
    echo "-a                   app name application name to run"
    echo "-i <input file>      input data for the application"
    echo "-o <output_dir>      output dir for the application run"
    echo "-g                   execute only golden run"
    echo "-h, --help           show brief help"
    echo " "
}

#-----------------------------------------------
# MAIN
#-----------------------------------------------
interactive_mode=true
app_name_opt=false
app_dir=""
app_opt=false
app_name=""
golden_run_opt=false
recompile_opt=false
input_data_opt=false
output_dir_opt=false
inputs_data=""
output_dir=""

# GET OPTIONS
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -a)
            shift
            if ${app_name_opt}; then
                echo "-a: option redundant" >&2
                exit 1
            fi
            app_name_opt=true
            app_name="$1"
            interactive_mode=false
            app_opt=true
            shift
            ;;
        -i)
            shift
            if ${input_data_opt}; then
                echo "-i: option redundant" >&2
                exit 1
            fi
            input_data_opt=true
            inputs_data="$1"
            interactive_mode=false
            shift
            ;;
        -o)
            shift
            if ${output_dir_opt}; then
                echo "-o: option redundant" >&2
                exit 1
            fi
            output_dir_opt=true
            output_dir="$1"
            interactive_mode=false
            shift
            ;;
        -g)
            golden_run_opt=true
            interactive_mode=false
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Validate required options
if ${app_opt} && [ -z "${app_name}" ]; then
    echo "Error: Application name (-a) is required." >&2
    exit 1
fi

if ${input_data_opt} && [ ! -f "${inputs_data}" ]; then
    echo "Error: Input file '${inputs_data}' does not exist." >&2
    exit 1
fi

if ${output_dir_opt} && [ ! -d "${output_dir}" ]; then
    echo "Error: Output directory '${output_dir}' does not exist." >&2
    exit 1
fi

# Run the application
if ${interactive_mode}; then
    echo "Interactive mode is not implemented yet."
    exit 0
fi

if ${golden_run_opt}; then
    echo "Executing golden run for application '${app_name}'..."
    # Add logic for golden run here
    exit 0
fi

if ${app_opt}; then
    echo "Running application '${app_name}'..."
    echo "Input file: ${inputs_data}"
    echo "Output directory: ${output_dir}"
    # Add logic to execute the application here
    exit 0
fi
# Interactive mode logic
if ${interactive_mode}; then
    echo "Entering interactive mode..."
    read -p "Enter application name: " app_name
    if [ -z "${app_name}" ]; then
        echo "Application name is required." >&2
        exit 1
    fi

    read -p "Enter input file path (leave blank if not applicable): " inputs_data
    if [ -n "${inputs_data}" ] && [ ! -f "${inputs_data}" ]; then
        echo "Input file '${inputs_data}' does not exist." >&2
        exit 1
    fi

    read -p "Enter output directory path (leave blank if not applicable): " output_dir
    if [ -n "${output_dir}" ] && [ ! -d "${output_dir}" ]; then
        echo "Output directory '${output_dir}' does not exist." >&2
        exit 1
    fi

    read -p "Execute golden run only? (y/n): " golden_run_response
    if [[ "${golden_run_response}" =~ ^[Yy]$ ]]; then
        golden_run_opt=true
    fi
fi

# Execute the application based on the provided options
if ${golden_run_opt}; then
    echo "Executing golden run for application '${app_name}'..."
    # Placeholder for golden run logic
    echo "Golden run logic not implemented yet."
    exit 0
fi

if [ -n "${app_name}" ]; then
    echo "Running application '${app_name}'..."
    echo "Input file: ${inputs_data}"
    echo "Output directory: ${output_dir}"
    # TODO Placeholder for application execution logic
    echo "Application execution logic not implemented yet."
fi

cd ${script_dir}
exit 0