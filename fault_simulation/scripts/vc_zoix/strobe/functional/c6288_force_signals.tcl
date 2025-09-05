## force reset placeholder file
force c6288.test_si 1'b0
run 10ns
force c6288.reset  1'b0
run 10ns
force c6288.reset  1'b1