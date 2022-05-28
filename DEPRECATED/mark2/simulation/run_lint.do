if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

vlog -sv -work work src/definitions.sv
vlog -sv -work work src/testbenches/testbench.sv
vlog -sv -work work src/memory.sv
vlog -sv -work work src/activation_function.sv
vlog -sv -work work src/adder.sv
vlog -sv -work work src/address_register.sv
vlog -sv -work work src/controller.sv
vlog -sv -work work src/mac_unit.sv
vlog -sv -work work src/serializer.sv
vlog -sv -work work src/neural_network.sv

vsim -t 1ns -L rtl_work -L work -voptargs="+acc" testbench

quit


vlog -sv -work work definitions.sv