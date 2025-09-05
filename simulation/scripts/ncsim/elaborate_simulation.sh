#!/bin/bash

## build and analyze files
rm -rf  ${MoW4EDA_SIM_DIR}/INCA_libs/irun.nc/ncsim.args 


irun  -file ${MoW4EDA_SIMULATION_ELABORATION_SCRIPT} -l ${MoW4EDA_SIMULATION_LOG_DIR}/elaboration.log  

if [[ $? -ne 0 ]] ; then 
echo "Elaboration not completed"
exit 1
fi 
