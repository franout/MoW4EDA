
#!/usr/bin/bash

cd `dirname $0`
script_dir=${PWD}
cd - &>/dev/null
script_name=`basename $0`

#-----------------------------------------------
# MAIN
#-----------------------------------------------


usage() {
   echo "${script_name} - Compile design for Z01X fault simulation"
   echo " "
   echo "-h, --help                show brief help"
   echo " "
}

interactive_mode=true
log_file=""
while getopts "l:h" opt; do
    case $opt in
        l)
        log_file="$OPTARG"
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



cd ${MoW4EDA_FSIM_DIR}/image_structural

export ZOIX_CC=/usr/bin/gcc

## generate the image/compile

cmd="vcs -full64 -hsopt=gates -f ${MoW4EDA_FSIM_ELABORATION_FILE_DIR}/${MoW4EDA_DESIGN}.f  ${MoW4EDA_FSIM_DELAY_COMPILE_OPT} -l ${log_file} -o ${MoW4EDA_DESIGN}_simv"
echo ${cmd}
${cmd}

if [[ $? -ne 0 ]] ; then
   echo "Failed Z01x Compilation" >&2
   exit 1
fi

# Move to the work dir
cd ${MoW4EDA_WORK_DIR}