
if { $env(MoW4EDA_FSIM)=="false" } { 
puts "Running toggle analysis"
database -open evcd_db -evcd -default -into $env(MoW4EDA_SIMULATION_PATH_EVCD)/$env(evcd_name).evcd  -timescale ns  
probe -create $env(MoW4EDA_SYNTH_TOP_LEVEL_NAME).dut -evcd simple -evcdformat 2 -all -depth all
} else {
puts "Running fault simulation"
   probe -create $env(MoW4EDA_SYNTH_TOP_LEVEL_NAME).dut -evcd simple -evcdformat 2  -all -depth  1 ;  # all 
}

run 