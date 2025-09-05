
-top ${MoW4EDA_FSIM_ELABORATION_TOP_LEVEL_NAME}

-kdb 
-lca
-override_timescale=1ns/1ps

-sverilog
-deraceclockdata

+define+build
+define+FUNCTIONAL
+error+100

-noautonaming 

+libverbose 
+systemverilogext+.sv


+vcs+initreg+random

+neg_tchk
+no_tchk_msg
-debug_access +vcs+fsdbon
#-debug_access+all
#-debug_region+cell
#-debug_region+cellports

-verbose
#${MoW4EDA_FSIM_ELABORATION_INTERNAL_STROBER_FILE}
+nolibcell
+notimingcheck 
## files 
${MoW4EDA_FSIM_LIB_GL}
${MoW4EDA_SYNTH_SYNTHESIZED_LIB_PATH}/${MoW4EDA_DESIGN}.v

### FSIM options 
-fsim
-fsim=portfaults 
#-debug_region=cell+lib
-fsim=suppress+cell
-fsim=class


-stim=module:${MoW4EDA_SYNTH_TOP_LEVEL_NAME}

-fsim=inprim



# for sdf simulation 
#-fsim=serial_flow 
