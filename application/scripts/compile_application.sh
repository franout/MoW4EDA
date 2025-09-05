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
	echo "${script_name} - compile a given application"
	echo " "
	echo "usage: ${script_name} (no options) - interactive mode"
	echo "or     ${script_name} options      - command mode"
	echo " "
	echo "compile application(s) options:"
	echo "--app name application name to compile"
	echo "--clean--compilation--deps (optional) execute a clean compilation of dependencies by eliminating tar file and sources"
	echo "Note: source files for entire applications are kept for future developments"
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
clean_compilation_deps_opt=false
app_name="" 

# GET OPTIONS
while test $# -gt 0; do
case "$1" in
-h|--help)
usage
exit 0
;;

--clean--compilation--deps)
if ${clean_compilation_deps_opt}; then
echo "--clean--compilation--deps: option redundant" >&2
exit 1
fi
clean_compilation_deps_opt=true
shift
interactive_mode=false
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

read -p "Do you want to perform a deep clean compilation? (y/n): " deep_clean_choice
case "$deep_clean_choice" in
	y|Y|yes|YES)
		clean_compilation_deps_opt=true
		;;
	n|N|no|NO)
		clean_compilation_deps_opt=false
		;;
	*)
		echo "Invalid choice. Please enter 'y' or 'n'."
		exit 1
		;;
esac

else
#---------------------------------------------------------
# COMMAND MODE
#---------------------------------------------------------

# check missing/redundant options
if ! ${app_name_opt} ||
then
echo "Missing required options:"
${app_name_opt} ||   echo "	--app app name"
echo
usage
exit 1
fi
if test $# -gt 0; then
echo "Redundant arguments."
usage
exit 1
fi  

fi # interactive mode

#---------------------------------------------------------
# COMPILE APPLICATION
#---------------------------------------------------------
app_dir=${MoW4EDA_APPLICATIONS_DIR}/${app_name}
echo ${app_dir}
if [[ -d ${app_dir} ]] ; then

if ${clean_compilation_deps_opt} ; then 

# TODO Placeholder for cleaning dependencies
echo "Cleaning dependencies logic goes here."

fi 

# TODO Placeholder for downloading necessary data
echo "Downloading necessary data logic goes here."

# TODO Placeholder for application compilation logic
echo "Application compilation logic goes here."

else 

echo "ERROR: application ${app_name} does not exist" >&2

fi  # app name 

cd ${script_dir}
exit 0
