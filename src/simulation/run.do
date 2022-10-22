transcript off

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+../ {../definitions.sv}
vlog -sv -work work +incdir+../ {../*.sv}

vlog -sv -work work +incdir+../testbench {../testbench/testbench.sv}

vsim -t 1ns -L rtl_work -L work -voptargs="+acc" testbench

do wave.do

run -all
wave zoom range 0ns 200ns