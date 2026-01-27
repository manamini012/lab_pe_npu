transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/MAC_FP_16.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/ei_adder8.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/ei_adder32.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/FP_Add_16.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/FP_Mul_16.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/Mantissa_Multiplier_16.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/regN.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/ei_multiplier.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/full_adder.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/pe_fp16.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/Systolic_Array_4x6.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/Data_Skew_Buffer.v}
vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/TPU_Top.v}

vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/FP16_MAC_Design/MAC {C:/altera/13.0sp1/FP16_MAC_Design/MAC/tb_tpu_top.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneiv_hssi_ver -L cycloneiv_pcie_hip_ver -L cycloneiv_ver -L rtl_work -L work -voptargs="+acc"  tb_tpu_top

add wave *
view structure
view signals
run -all
