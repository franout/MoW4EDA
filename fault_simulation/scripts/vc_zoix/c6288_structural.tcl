set_config -global_max_jobs 1 

set_config -update_interval 30

set_config -vc_coats_std_args "-collect_reason_unselected"
set_config -tsim_std_args "-stim=verify -tsim=limit_toggle:0"


create_campaign -args "-full64 -daidir $::env(MoW4EDA_FSIM_DIR)/image_structural/$::env(MoW4EDA_DESIGN)_simv.daidir \
                    -campaign $::env(MoW4EDA_DESIGN)_fsim_$::env(MoW4EDA_FSIM_MODEL)_$::env(stil_name) -sff $::env(MoW4EDA_FSIM_FAULT_LIST_FILE)  \
                    -dut $::env(MoW4EDA_FSIM_ELABORATION_TOP_LEVEL_NAME)  $::env(MoW4EDA_FSIM_FGEN_EXTRA_OPT) \
                    -overwrite -l $::env(log_dir)/fsim_internal_fgen_$::env(stil_name).log"
 

create_testcases -args "-stim=verify_off -stim=inst:$::env(MoW4EDA_FSIM_ELABORATION_TOP_LEVEL_NAME) -stim=type:stil -stim=file:$::env(stil_path) -stim=clk:clk_i" -exec "$::env(MoW4EDA_DESIGN)_simv" -fault_injection_time "1ns"  -name test1 

coats -localhost  -verbose 
report -campaign $::env(MoW4EDA_DESIGN)_fsim_$::env(MoW4EDA_FSIM_MODEL)_$::env(stil_name) -showmetadata -showmetadataid  -showsimdetails -showtimingid -report "$::env(result_dir)/before_fsim.sff" -overwrite
report  -unselected fault   -report "$::env(result_dir)/unselected.rpt" -overwrite
report  -unselected observability -report "$::env(result_dir)/unselected_observability.rpt" -overwrite
report  -unselected controllability -report "$::env(result_dir)/unselected_controllability.rpt" -overwrite
fsim -fsim_args "-fsim=fault+stats -fsim=fault+monitor+drop -fsim=fault+monitor+strobe"
report -campaign $::env(MoW4EDA_DESIGN)_fsim_$::env(MoW4EDA_FSIM_MODEL)_$::env(evcd_name) -report "$::env(result_dir)/after_fsim.sff" -overwrite
report  -unselected fault -report "$::env(result_dir)/unselected.rpt"

