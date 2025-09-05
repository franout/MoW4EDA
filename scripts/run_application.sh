#!/bin/bash

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
		echo "-a 					app name application name to run"
		echo "-r 					recompile the target application"
		echo "-i <input file> 		input data for the application"
		echo "-o <output_dir> 		output dir for the application run" 
		echo "-g 					execute only golden run"
		echo " "
		echo "-h, --help                show brief help"
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

# GET OPTIONS
while test $# -gt 0; do
case "$1" in
-h|--help)
usage
exit 0
;;

--app) 
if ${app_opt}; then
echo "--app: option redundant" >&2
exit 1
fi
shift
if [[ $# -gt 0  &&  ! $1 =~ ^- ]]; then
app_name=$1
app_name_opt=true
else
echo "--app: no argument specified" >&2
exit 1
fi
shift
interactive_mode=false
;; 
-g)
golden_run_opt=true
shift 
interactive_mode=false
;;

-r)
recompile_opt=true
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


output_dir=${app_dir}/results

if [[ ! -L ${output_dir}|| ! -d ${output_dir} ]] ; then 
## create output dir 
if ${MoW4EDA_COPY_DIR_LINK_MODE} ;  then 
ln -s ${MoW4EDA_APPLICATION_OUTPUTS_DIR} ${output_dir}
else 
mkdir ${output_dir}
fi 
fi 

## ask for application 


apps=$(find ${app_dir}"/" -mindepth 1 -maxdepth 1  -type d ! \(  -name "doc" -o -name "scripts" -o -name "tags" -o -name "resources" -o -name "deps" \) | xargs -I{} basename {} | sort)
apps=${apps}" All"
echo "Select the application"
select app_name in ${apps} ; do	
if [[ -z "${app_name}" ]] ; then
echo "wrong choice" >&2
elif [[ "All" ==  "${app_name}" ]] ; then 	
app_name=$(find ${app_dir}"/" -mindepth 1 -maxdepth 1  -type d ! \(  -name "doc" -o -name "scripts" -o -name "tags"  -o -name "resources" -o -name "deps" \) | xargs -I{} basename {} | sort)
else 
break 
fi
done

output_dir=${app_dir}/results/${app_name}

### recompile 
enable_recompile="n"
 read -p "Recompile ${app_name}? (y/n): " enable_recompile
    if [[ "$enable_recompile" == "y" || "$enable_recompile" == "Y" ]]; then
        recompile_opt=true
    fi
### golden run 
enable_golden_run="y"
 read -p "Run only golden run for ${app_name}? (y/n): " enable_golden_run
    if [[ "$enable_golden_run" == "y" || "$enable_golden_run" == "Y" ]]; then
        golden_run_opt=true
    fi

else
#---------------------------------------------------------
# COMMAND MODE
#---------------------------------------------------------

if !${app_opt} || !${type_opt} || !${target_operation_opt} ; then
echo "Missing required options:"
${app_opt} ||   echo "	--app app name"
${type_opt}  ||   echo "	--type application type"
${target_operation_opt}  ||   echo "--target-operations target operation to evaluate"
echo
usage
exit 1
fi

if test $# -gt 0 ; then
echo "Redundant arguments."
usage
exit 1
fi  

fi ; # command line 

res_dir=${MoW4EDA_APPLICATIONS_DIR}/results
if [[ ! -L ${res_dir} || ! -d ${res_dir} ]] ; then 
## create output dir 
if ${MoW4EDA_COPY_DIR_LINK_MODE} ;  then 
ln -s ${MoW4EDA_APPLICATION_OUTPUTS_DIR} ${res_dir}
else 
mkdir ${res_dir}
fi 
fi 

app_dir=${MoW4EDA_APPLICATIONS_DIR}/${app_name}


if ${recompile_opt}; then 
##  recompile script for app 
echo "Recompiling ${app_name}"
echo "${MoW4EDA_APPLICATION_COMPILE_SCRIPT} --app ${app_name} "
${MoW4EDA_APPLICATION_COMPILE_SCRIPT} --app ${app_name}

if [[ $? -ne 0 ]]; then 
echo "ERROR: in compiling ${app_name}" >&2
exit 1 
fi 

fi 
export app_dir
export inputs_dir=$(dirname ${inputs_data})
echo "${MoW4EDA_APPLICATION_INTERNAL_RUNNER} ${inputs_data} ${output_dir}  ${golden_run_opt} | tee ${MoW4EDA_APPLICATION_RUN_DIR_LOG}/${app_name}_run.log" 
${MoW4EDA_APPLICATION_INTERNAL_RUNNER} ${inputs_data} ${output_dir}  ${golden_run_opt} | tee ${MoW4EDA_APPLICATION_RUN_DIR_LOG}/${app_name}_run.log


cd ${script_dir}
exit 0
