vsim -gui work.sha3_tb
add wave -position insertpoint sim:/sha3_tb/*
add wave -position insertpoint sim:/sha3_tb/hash/*
add wave -position insertpoint sim:/sha3_tb/hash/ram/*
add wave -position insertpoint sim:/sha3_tb/hash/lproc/*
add wave -position insertpoint sim:/sha3_tb/hash/lproc/rhoblock/leaver/*

run 124100