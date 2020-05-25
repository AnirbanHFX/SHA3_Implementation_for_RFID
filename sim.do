vsim -gui work.sha3_trial_tb
add wave -position insertpoint sim:/sha3_trial_tb/*
add wave -position insertpoint sim:/sha3_trial_tb/sliceprocessor/parityreg_component/*
run 52100