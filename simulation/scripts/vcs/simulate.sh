#!/bin/bash

cd ${MoW4EDA_SIM_DIR}

echo "Running simulation for ${MoW4EDA_SIMULATION_TIME}"

export evcd_name=$(basename ${MoW4EDA_SIMULATION_EXECUTABLE})
${MoW4EDA_SIMULATION_EXECUTABLE}  +vcs+initreg+0 +dumpports+ieee -ucli ${MoW4EDA_SYNTH_TOP_LEVEL_NAME} -do ${MoW4EDA_SIMULATION_SCRIPTS_DIR}/${MoW4EDA_DESIGN}_simulation_script.tcl -l ${MoW4EDA_SIMULATION_LOG_DIR}/${MoW4EDA_DESIGN}_simulation.log 

if [[ $? -ne 0 ]] ; then 
echo "VCS Simulation not completed"
exit 1
fi 

cd ${MoW4EDA_WORK_DIR}