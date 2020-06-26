vsim -gui work.sha3_trial_tb

add wave -position insertpoint sim:/sha3_trial_tb/sha3/*
add wave -position insertpoint sim:/sha3_trial_tb/sha3/ram/*

run 2884900