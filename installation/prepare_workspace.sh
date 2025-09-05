#!/bin/bash

# Check if the script is being run from the main folder (should contain 'MoW4EDA' script file)
if [ ! -f "$(pwd)/MoW4EDA" ]; then
    echo "Error: 'MoW4EDA' script file not found in the current directory."
    echo "Please navigate to the main folder and try again."
    exit 1
fi

# Check if the at least a setup_default script file exists in the installation folder
if [ ! -f "$(pwd)/setup_default" ]; then
    echo "Error: 'setup_default' script file not found in the installation folder."
    echo "Please ensure you are in the correct directory and try again."
    exit 1
fi 

# Check if the workspace name is provided as an argument
if [ $# -gt 0 ]; then
    name="$1"
else
    # Prompt the user for the workspace name
    read -p "Enter the name of the workspace: " name
fi

echo "Keep calm, preparing the workspace with name: $name"
echo "This may take a few seconds... Go grab a coffee :)"

# Find and replace all occurrences of 'MoW4EDA_' with the user-provided name
# in all files within the parent folder of the current directory
find "$(pwd)" -type f -exec sed -i "s/MoW4EDA_/${name}_/g" {} +

echo "Substitution complete: 'MoW4EDA_' replaced with '${name}_' in all files."

# FInd and replace all the occurences of 'MoW4EDA' with the user-provided name
# in all files within the parent folder of the current directory
find "$(pwd)" -type f -exec sed -i "s/MoW4EDA/${name}/g" {} +
echo "Substitution complete: 'MoW4EDA' replaced with '${name}' in all files."