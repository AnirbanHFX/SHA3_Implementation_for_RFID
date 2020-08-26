vsim -gui work.sha3_tb
add wave -position insertpoint sim:/sha3_tb/*
add wave -position insertpoint sim:/sha3_tb/hash/*
add wave -position insertpoint sim:/sha3_tb/hash/lproc/*
add wave -position insertpoint sim:/sha3_tb/hash/ram/*


run 21700