#!/bin/bash

cd ${MoW4EDA_SIM_DIR}
export evcd_name=$(basename ${MoW4EDA_SIMULATION_EXECUTABLE})

ncsim  -mcdump -64bit  -INPUT ${MoW4EDA_SIMULATION_SCRIPTS_DIR}/${MoW4EDA_DESIGN}_simulation_script.tcl  -f ${MoW4EDA_SIM_DIR}/INCA_libs/irun.nc/ncsim.args +define+tmax_parallel=1 +tmax_parallel

if [[ $? -ne 0 ]] ; then 
echo "NCSIM Simulation not completed"
exit 1
fi 

cd ${MoW4EDA_WORK_DIR}