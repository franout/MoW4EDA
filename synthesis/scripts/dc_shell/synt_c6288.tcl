############################################
########## c6288                      #####
############################################
## my init script

set_app_var compile_shift_register_max_length 700000000
set_app_var compile_seqmap_identify_shift_registers_with_synchronous_logic true
set_app_var compile_identify_synchronous_shift_register_effort medium
set_app_var compile_seqmap_honor_sync_set_reset true 

source $env(MoW4EDA_SYN_SCRIPTS_DIR)/synopsys_dc.setup

lappend search_path $env(MoW4EDA_DESIGN_DIR)/frontend

analyze  -format sverilog  -autoread -library work    $env(MoW4EDA_DESIGN_DIR)/frontend/c6288.sv
elaborate  c6288
current_design c6288
link

## design environment condition 
set_drive 0.15 [all_inputs]
set_load 0.1 [all_outputs]
set_drive 0 clk

## automatically set 
#set_wire_load_model "10x10"


set_optimize_registers -sync_transform decompose -async_transform decompose

## design constraints 
## create clock 
create_clock -period  $env(MoW4EDA_SYNTH_CLOCK_VALUE_NS) clk
set_input_delay 0.000003 -clock clk \
[remove_from_collection [all_inputs] [get_ports clk]]


set_output_delay  0.0925 -clock clk [all_outputs]



change_names -rules verilog -hierarchy



#scan insertion
## lets generate a design with the number of scan chains equal to the number of rows

set_scan_configuration -style multiplexed_flip_flop
compile -scan  -gate_clock -area_effor medium -map_effort medium 

set_scan_configuration -chain_count 1  -create_test_clocks_by_system_clock_domain true
set_dft_signal -view existing_dft -type ScanClock -port "clk"  -timing [list 45 95] -active_state 1 -connect_to "clk"
create_port test_si -direction in
create_port test_se -direction in
create_port test_so -direction out
set_dft_signal -view spec -type Reset -port reset -active_state 0 
set_dft_signal -view spec -type ScanDataIn -port test_si 
set_dft_signal -view spec -type ScanDataOut -port test_so
set_dft_signal -view spec -type ScanEnable -port test_se -active_state 1
#compile -scan 
##compile -scan  -area_effor medium -map_effort medium -exact_map -no_map 


create_test_protocol
dft_drc -verbose
preview_dft
insert_dft
check_scan
dft_drc
check_design

compile  -incremental -scan 
write -format verilog -hierarchy  -output $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN).v
write_test_protocol -output $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN)_test_protocol.spf

## report 
report_cell   -verbose -physical [ get_cells ] > $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/report_cells_$env(MoW4EDA_DESIGN).rpt
report_test -scan_path
report_area  > $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/report_area_$env(MoW4EDA_DESIGN).rpt
report_timing  > $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/report_timing_$env(MoW4EDA_DESIGN).rpt
write_scan_def -output $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/report_dft.scandef
write_sdf $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN)_timing.sdf

quit

