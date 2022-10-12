transcript off

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+../ {../definitions.sv}
vlog -sv -work work +incdir+../ {../isa.sv}
vlog -sv -work work +incdir+../ {../*.sv}

vlog -sv -work work +incdir+../testbenches {../testbenches/testbench.sv}

vsim -t 1ns -L rtl_work -L work -voptargs="+acc" testbench


mem load -i ../memories/xy.mem -format mti /testbench/nn/xy_mem/data
mem load -i ../memories/inst.mem -format mti /testbench/nn/inst_mem/data
mem load -i ../memories/act_func.mem -format mti /testbench/nn/activation_function/lookup_table/data

set NU_COUNT [examine -unsigned definitions.NU_COUNT]

for {set i 0} {$i < $NU_COUNT} {incr i} {
    mem load -i ../memories/w$i.mem -format mti /testbench/nn/mac_gen[$i]/w_mem/data
}

run -all

mem save -o ../memories/output.mem -f mti -data decimal -addr decimal -wordsperline 1 /testbench/nn/output_mem/data

exit