#!/bin/bash


rm -rf ${MoW4EDA_SIM_DIR}/work
mkdir ${MoW4EDA_SIM_DIR}/work
## build and analyze files 

vcs  -full64 -file ${MoW4EDA_SIMULATION_ELABORATION_SCRIPT} -l ${MoW4EDA_SIMULATION_LOG_DIR}/elaboration.log  

if [[ $? -ne 0 ]] ; then 
echo "Elaboration not completed"
exit 1
fi 
