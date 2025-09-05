set_messages -level expert

set_build -merge noglobal_tie_propagate
set_build -nodelete_unused_gates 
set_build -add_celldefine_nets
set_netlist -escape all
#-fault_boundary hierarchical
#set_build -nonet_connections_change_netlist
#set_build -merge nodlat_from_flipflop  


read_netlist -noabort $env(MoW4EDA_ATPG_LIB)
read_netlist -noabort $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN).v

run_build_model $env(MoW4EDA_SYNTH_TOP_LEVEL_NAME)

set_simulation -num_processes 8
set_rules C4 warning
if { $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
    set_faults -model "Transition" -noequiv_code
} else {
set_faults -model $env(MoW4EDA_FAULT_MODEL) -noequiv_code
}



set_drc -allow_unstable_set_resets -blockage_aware_clock_grouping  -clock -dynamic -dynamic_clock_equivalencing nodisturb -disturb_clock_grouping
set_drc -initialize_dff_dlat 0 -allow_unstable_set_resets  -dynamic_clock_equivalencing disturb -extract_cascaded_clock_gating -remove_false_clocks


## set up the scan cells 
set_drc $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN)_test_protocol.spf
remove_clocks -all
add_clocks 1  { clk }
add_clocks 0  { reset }

#add_pi_constraints 0 "test_se"

if { $env(MoW4EDA_FAULT_MODEL) == "Transition" || $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
#read_sdc $env(MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH)/$env(MoW4EDA_DESIGN)_timing.sdf
#set_delay -launch system_clock
#set_delay -nopi_changes
#set_delay -nopo_measures
set_delay -launch_cycle last_shift

set_delay -common_launch_capture_clock
set_delay -allow_multiple_common_clocks
}

if { $env(MoW4EDA_FAULT_MODEL) == "Transition" } {
set_atpg -capture 10
} elseif {$env(MoW4EDA_FAULT_MODEL) == "SDF" } {
set_atpg -capture 2
}

run_drc
set_patterns -internal 
set_atpg -abort_limit $env(MoW4EDA_ATPG_ABORT_LIMIT)
if { $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
set_faults -model "Transition" -noequiv_code -report uncollapsed
} else {
set_faults -model $env(MoW4EDA_FAULT_MODEL) -noequiv_code -report uncollapsed
}

# only for tdf -capture_cycles 1 
if { $env(MoW4EDA_FAULT_MODEL) == "Stuck" } {
set_atpg -add_setreset_test -chain_test 0011 -coverage 100
}

if { $env(MoW4EDA_FAULT_MODEL) == "Transition" } {
set_atpg -coverage 95
}

if { $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
set_delay -slackdata_for_atpg -slackdata_for_faultsim -max_tmgn 100
set_delay -max_delta_per_fault 0
## small delay faults
set_atpg -coverage 95 
read_timing $env(MoW4EDA_SLACK_FILE)
}
set_atpg -num_processes 20
add_faults -all
set_faults -noequiv_code -fault_coverage -summary verbose
report_summaries
run_atpg -auto_compression

set_faults -noequiv_code -fault_coverage -summary verbose
report_summaries 
## write fault list

if { $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
report_faults -verbose -all -slack tmgn 0.9 > $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL)_tmgn.fau
report_faults -verbose -all -slack tdet  > $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL)_tdet.fau
report_faults -verbose -all -slack delta  > $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL)_delta.fau
report_faults -verbose -all -slack coverage  > $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL)_cov.fau
report_faults -verbose -all -slack effectiveness  > $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL)_effectiveness.fau
}

write_faults  $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL).fau -all -replace
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_$env(MoW4EDA_FAULT_MODEL).sum -replace -summary

## write still 

write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL).stil -format stil -replace -internal_force_clocks
## for zoix fsim
#write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_test.stil -cellnames module  -format stil -replace -parallel -nocompaction -order_pins -nocompaction -internal_scancells      
write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_zoix.stil -cellnames module  -format stil99 -replace -parallel -nocompaction -order_pins -nocompaction -internal_scancells 
## write the testbench 
write_testbench -input $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL).stil -output $env(MoW4EDA_ATPG_DIR_TESTBENCHES)/testbench_$env(MoW4EDA_DESIGN)_$env(MoW4EDA_FAULT_MODEL)_scan -replace 
report_scan_chains -verbose >  $env(MoW4EDA_ATPG_DIR)/scan_chains_report_$env(MoW4EDA_DESIGN).rpt
report_scan_cells -all -verbose >  $env(MoW4EDA_ATPG_DIR)/scan_cells_report_$env(MoW4EDA_DESIGN).rpt

set_patterns -internal 
set_simulation -basic_scan -num_processes 32 -timing_exceptions_for_stuck_at -verbose 
run_simulation 
report_summaries
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_god_sim_$env(MoW4EDA_FAULT_MODEL).fau -all -replace
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_god_sim_$env(MoW4EDA_FAULT_MODEL).sum -replace -summary


puts "Starting random stimulus generation"
remove_faults -all
if { $env(MoW4EDA_FAULT_MODEL) == "Stuck" } {
set_atpg -coverage 97
}

if { $env(MoW4EDA_FAULT_MODEL) == "Transition" || $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
set_atpg -coverage 80
}

add_faults -all
set_random_patterns -clock "clk" -length 1024 -observe master
set_patterns -random  -internal
set_simulation -basic_scan -num_processes 32 -timing_exceptions_for_stuck_at -verbose 
run_atpg 
report_summaries
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_random_pattern_$env(MoW4EDA_FAULT_MODEL).fau -all -replace
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_random_pattern_$env(MoW4EDA_FAULT_MODEL).sum -replace -summary

write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_pseudorandom.stil -format stil -replace -internal_force_clocks
## for zoix fsim
#write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_test.stil -cellnames module  -format stil -replace -parallel -nocompaction -order_pins -nocompaction -internal_scancells      
write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_zoix.stil -cellnames module  -format stil99 -replace -parallel -nocompaction -order_pins -nocompaction -internal_scancells 
## write the testbench 
write_testbench -input $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_pseudorandom.stil -output $env(MoW4EDA_ATPG_DIR_TESTBENCHES)/testbench_$env(MoW4EDA_DESIGN)_$env(MoW4EDA_FAULT_MODEL)_scan_pseudo_random -replace 

puts "Starting power aware atpg"
remove_faults -all
set_atpg -power_effort high
set_atpg -fill adjacent
set_atpg -power_budget min
add_faults -all

set_patterns -internal 
set_atpg -abort_limit $env(MoW4EDA_ATPG_ABORT_LIMIT)

if { $env(MoW4EDA_FAULT_MODEL) == "Stuck" } {
set_atpg -coverage 100
}

if { $env(MoW4EDA_FAULT_MODEL) == "Transition" } {
set_atpg -capture 10
set_delay -launch_cycle last_shift
set_atpg -coverage 95
set_delay -common_launch_capture_clock
set_delay -allow_multiple_common_clocks
}

if { $env(MoW4EDA_FAULT_MODEL) == "SDF" } {
## small delay faults
set_atpg -coverage 95 
read_timing $env(MoW4EDA_SLACK_FILE)
}

set_atpg -add_setreset_test -chain_test 0011 -coverage 100

run_atpg 
report_summaries
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_low_power_$env(MoW4EDA_FAULT_MODEL).fau -all -replace
write_faults $env(MoW4EDA_ATPG_FAULT_LIST_DIR)/$env(MoW4EDA_DESIGN)_fault_list_low_power_$env(MoW4EDA_FAULT_MODEL).sum -replace -summary

write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_low_power.stil -format stil -replace -internal_force_clocks
## for zoix fsim
write_pattern $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_zoix.stil -cellnames module  -format stil99 -replace -parallel -nocompaction -order_pins -nocompaction -internal_scancells 
## write the testbench 
write_testbench -input $env(MoW4EDA_ATPG_STIL_DIR)/pattern_$env(MoW4EDA_FAULT_MODEL)_low_power.stil -output $env(MoW4EDA_ATPG_DIR_TESTBENCHES)/testbench_$env(MoW4EDA_DESIGN)_$env(MoW4EDA_FAULT_MODEL)_scan_low_power -replace 

quit
