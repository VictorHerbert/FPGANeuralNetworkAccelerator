transcript off

set NU_COUNT [examine -unsigned definitions.NU_COUNT]
set Q_FRAC [examine -unsigned definitions.Q_FRAC]
set ACT_A_Q_FRAC [examine -unsigned definitions.ACT_A_Q_FRAC]
set ACT_B_Q_FRAC [examine -unsigned definitions.ACT_B_Q_FRAC]

radix unsigned
radix define fx -fixed -fraction $Q_FRAC -precision 3 -base decimal -signed
radix define fx_prod -fixed -fraction 16 -precision 3 -base decimal -signed
radix define fx_prod_full -fixed -fraction 24 -precision 3 -base decimal -signed
radix define act_a_fx -fixed -fraction $ACT_A_Q_FRAC -precision 3 -base decimal -signed
radix define act_b_fx -fixed -fraction $ACT_B_Q_FRAC -precision 3 -base decimal -signed



set SHOW_CONTROL 1
set SHOW_CONTROL_MOVE 0
set SHOW_CONTROL_REPEAT 0
set SHOW_INST_FULL 1

add wave clk
add wave reset

if { $SHOW_CONTROL == 1 } {
    add wave -divider "Control Signals"
    add wave nn/mac_acc_update
    add wave nn/mac_acc_loopback
    add wave nn/serializer_update

    add wave nn/xy_read_addr
    add wave nn/xy_write_enable
    add wave nn/xy_write_addr

    add wave nn/w_write_enable
    add wave nn/w_addr

    add wave nn/controller/repeat_counter
    add wave nn/controller/accmov_length
    add wave nn/controller/accmov_counter
}

if { $SHOW_CONTROL_REPEAT == 1 } {
    add wave -divider "Repeat Move logic"
    add wave nn/controller/repeat_update
}

add wave -divider "Instructions"
add wave -color "Yellow" nn/controller/inst_read_addr
add wave -color "Yellow" nn/controller/instruction
if { $SHOW_INST_FULL == 1 } {
    add wave -color "Yellow" nn/controller/matmul_inst_packet
    add wave -color "Yellow" nn/controller/accmov_inst_packet
    add wave -color "Yellow" nn/controller/jump_inst_packet
    add wave -color "Yellow" nn/controller/repeat_inst_packet
}

add wave -divider "Mac Units"
add wave -radix fx nn/xy_read_data
add wave -radix fx nn/w_read_data
add wave -radix fx nn/prod
add wave -radix fx_prod_full nn/prod_full
add wave -radix fx nn/loopback_sum
add wave -radix fx nn/sum
add wave -radix binary sum_pos_overflow
add wave -radix binary sum_neg_overflow
add wave -radix binary prod_pos_overflow
add wave -radix binary prod_neg_overflow
add wave -radix fx nn/mac
add wave -radix fx nn/acc

add wave -divider "Serializer"
add wave -radix fx nn/serializer_out
add wave -radix fx nn/serializer/data

add wave -divider "Activation Function"
add wave nn/activation_function/mask
add wave nn/activation_function/function_type
add wave -radix fx nn/activation_function/x
add wave -radix act_a_fx nn/activation_function/a_coef
add wave -radix act_b_fx nn/activation_function/b_coef
add wave -radix fx nn/activation_function/fx

mem load -i ../memories/xy.mem -format mti /testbench/nn/xy_mem/data
mem load -i ../memories/inst.mem -format mti /testbench/nn/inst_mem/data
mem load -i ../memories/act_func.mem -format mti /testbench/nn/activation_function/lookup_table/data

for {set i 0} {$i < $NU_COUNT} {incr i} {
    mem load -i ../memories/w$i.mem -format mti /testbench/nn/mac_gen[$i]/w_mem/data
}

run -all
wave zoom range 0ns 200ns