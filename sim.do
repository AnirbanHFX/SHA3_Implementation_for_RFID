vsim -gui work.sha3_trial_tb
add wave -position insertpoint sim:/sha3_trial_tb/*
add wave -position insertpoint sim:/sha3_trial_tb/ram/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/rhoblock/reg1/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/rhoblock/reg2/*

run 155300