radix unsigned

set NU_COUNT [examine -unsigned definitions.NU_COUNT]

add wave clk
add wave reset

add wave -divider "Control Signals"
add wave nn/controller/inst_addr
add wave nn/controller/counter
add wave nn/mac_x_select
add wave nn/mac_w_select
add wave nn/mac_reg_enable
add wave nn/mac_acc_loopback
add wave nn/serializer_update
add wave nn/act_input_select
add wave nn/act_bypass
add wave nn/xy_acc_loopback
add wave nn/xy_acc_op
add wave nn/xy_read_addr
add wave nn/xy_write_enable
add wave nn/xy_write_addr
add wave nn/w_read_addr
add wave nn/w_write_enable
add wave nn/w_write_addr

add wave -divider "Controller"
add wave -color "Yellow" nn/controller/inst_addr
add wave -color "Yellow" nn/controller/instruction
add wave nn/controller/looped_instruction

add wave -divider "Mac Units"
add wave nn/x
add wave mac_reg
add wave nn/w
add wave nn/prod
add wave nn/mac

add wave -divider "Serializer"
add wave nn/serializer_out
add wave nn/serializer/data

add wave -divider "Activation Function"
add wave nn/activation_function/x
add wave nn/activation_function/fx

add wave -divider "XY write"
add wave nn/xy_writeback

mem load -i ../memories/xy.mem -format mti /testbench/nn/xy_mem/data

for {set i 0} {$i < $NU_COUNT} {incr i} {
    mem load -i ../memories/w$i.mem -format mti /testbench/nn/mac_gen[$i]/w_mem/data
}

run -all
wave zoom range 0ns 200ns
