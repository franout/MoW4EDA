
if { $env(MoW4EDA_FSIM)=="false" } { 
puts "Running toggle analysis"
set fid [dump -file $env(MoW4EDA_SIMULATION_PATH_EVCD)/$env(evcd_name).evcd -type EVCD]
dump -add {testbench.dut} -depth 0 -fid $fid -ports
dump -add {testbench.dut.*} -depth 0 -fid $fid -ports
dump -add {testbench.dut.*} -depth 0 -fid $fid

} else {
puts "Running fault simulation"
set fid [dump -file $env(MoW4EDA_SIMULATION_PATH_EVCD)/$env(evcd_name)_$env(MoW4EDA_SIMULATION_TIME)_fsim.evcd -type EVCD]
dump -add {testbench.dut} -depth 1 -fid $fid -ports
dump -add {testbench} -depth 1 -fid $fid -ports
}
puts "Running"
run $env(MoW4EDA_SIMULATION_TIME)
#dump -closes
quit 