transcript on

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+../src {../src/testbench.sv}

vlog -sv -work work +incdir+../src {../src/memory_cell_single.sv}
vlog -sv -work work +incdir+../src {../src/memory_cell_dual.sv}
vlog -sv -work work +incdir+../src {../src/memory_weight.sv}

vlog -sv -work work +incdir+../src {../src/neuron.sv}
vlog -sv -work work +incdir+../src {../src/activation_function.sv}

vlog -sv -work work +incdir+../src {../src/layer.sv}
vlog -sv -work work +incdir+../src {../src/neural_network.sv}

vsim -t 1ps -L rtl_work -L work -voptargs="+acc"  testbench

view structure
view signals

do wave.do