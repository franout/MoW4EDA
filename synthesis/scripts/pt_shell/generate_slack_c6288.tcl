source $env(MoW4EDA_SYN_SCRIPTS_DIR)/synopsys_dc.setup

# hard fix 
set_app_var link_library "* $target_library <path to the installation dir of dc>/libraries/syn/dw_foundation.sldb"

lappend search_path $env(MoW4EDA_DESIGN_DIR)/frontend

read_db $env(MoW4EDA_SYNTH_LIB)
read_verilog  $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN).v 
set_design_top $env(MoW4EDA_SYNTH_TOP_LEVEL_NAME)
link_design $env(MoW4EDA_SYNTH_TOP_LEVEL_NAME)


set timing_use_zero_slew_for_annotated_arcs never
set timing_save_pin_arrival_and_slack TRUE
set timing_update_status_level high
set timing_prelayout_scaling false
set pin_arrival_and_slack TRUE

# same constraints for the synthesi
## design environment condition 
set_drive 0.000022 [all_inputs]
set_load 0.000015 [all_outputs]
set_drive 0 clk

## automatically set 
#set_wire_load_model "10x10"



## design constraints 
## create clock 
create_clock -period $env(MoW4EDA_SYNTH_CLOCK_VALUE_NS) clk 
#set_clock_transition 0.2 [get_clocks clk]
set_input_delay 0.000003 -clock clk \
[remove_from_collection [all_inputs] [get_ports clk]]

set_output_delay 0.000002 -clock clk [all_outputs]


## env 
#create_operating_conditions -name WC_CUSTOM \
#-library tech_lib -process 1.2 \
#-temperature 30.0 -voltage 2.8 \
#-tree_type worst_case_tree

read_sdf  -cond_use max -load_delay net -verbose $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN)_timing.sdf

update_timing -full
report_global_slack -max -nosplit > $env(MoW4EDA_SLACK_FILE)

exit