vlib work
vlog +incdir+../../../common ../../../common/*.sv ../*.sv
vsim -voptargs=+acc work.tb
add wave -radix bin sim:/tb/i_lab_top/*
run -all
wave zoom full
