onerror {quit -f}
vlib work
vlog -work work ScalingUnit.vo
vlog -work work ScalingUnit.vt
vsim -novopt -c -t 1ps -L cycloneii_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.ScalingUnit_vlg_vec_tst
vcd file -direction ScalingUnit.msim.vcd
vcd add -internal ScalingUnit_vlg_vec_tst/*
vcd add -internal ScalingUnit_vlg_vec_tst/i1/*
add wave /*
run -all
