#!/usr/bin/bash

echo "Cleaning workspace results dir for ${MoW4EDA_DESIGN}" 

echo "Cleaning simulation dir"
echo "rm -rf ${MoW4EDA_SIM_DIR}"
rm -rf ${MoW4EDA_SIM_DIR}

echo "Cleaning logs dir"
echo "rm -rf ${MoW4EDA_LOGS_DIR}"
rm -rf ${MoW4EDA_LOGS_DIR}

echo "Cleaning fault simulation dir"
echo "rm -rf ${MoW4EDA_FSIM_DIR}"
rm -rf ${MoW4EDA_FSIM_DIR}

echo "Cleaning synthesis dir"
echo "rm -rf ${MoW4EDA_SYN_DIR}"
rm -rf ${MoW4EDA_SYN_DIR}

echo "Cleaning ATPG dir"
echo "rm -rf ${MoW4EDA_ATPG_DIR}"
rm -rf ${MoW4EDA_ATPG_DIR}

## TODO Add any additional clean up steps here
