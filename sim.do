vsim -gui work.sha3_trial_tb
add wave -position insertpoint sim:/sha3_trial_tb/*
add wave -position insertpoint sim:/sha3_trial_tb/ram/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/muxup/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/muxdwn/*
add wave -position insertpoint sim:/sha3_trial_tb/laneprocessor/rhoblock/*

run 77700