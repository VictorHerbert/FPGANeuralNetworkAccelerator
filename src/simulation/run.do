transcript off

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+../ {../definitions.sv}
vlog -sv -work work +incdir+../ {../isa.sv}

vlog -sv -work work +incdir+../ {../memory.sv}
vlog -sv -work work +incdir+../ {../activation_function.sv}
vlog -sv -work work +incdir+../ {../address_register.sv}
vlog -sv -work work +incdir+../ {../controller.sv}
vlog -sv -work work +incdir+../ {../mac_unit.sv}
vlog -sv -work work +incdir+../ {../serializer.sv}
vlog -sv -work work +incdir+../ {../fifo.sv}
vlog -sv -work work +incdir+../ {../neural_network.sv}


vlog -sv -work work +incdir+../testbenches {../testbenches/testbench.sv}
vlog -sv -work work +incdir+../testbenches {../testbenches/act_func_testbench.sv}

vsim -t 1ns -L rtl_work -L work -voptargs="+acc" testbench

do wave.do