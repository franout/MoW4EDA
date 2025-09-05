
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



cd ${SDENV_FSIM_DIR}/image_functional

export ZOIX_CC=/usr/bin/gcc

## generate the image/compile

echo "zoix -design ${SDENV_DESIGN} \
         -j32 -f ${SDENV_FSIM_ELABORATION_FILE_DIR}/${SDENV_DESIGN}.f \
         -l ${log_file} ${SDENV_FSIM_DELAY_COMPILE_OPT}"

zoix -design ${SDENV_DESIGN}  \
 -j32 -f ${SDENV_FSIM_ELABORATION_FILE_DIR}/${SDENV_DESIGN}.f \
 -l ${log_file} ${SDENV_FSIM_DELAY_COMPILE_OPT}

if [[ $? -ne 0 ]] ; then
   echo "Failed Z01x Compilation" >&2
   exit 1
fi

# Move to the work dir
cd ${SDENV_WORK_DIR}