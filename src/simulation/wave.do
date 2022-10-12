config wave -signalnamewidth 1

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


set SHOW_CONTROL 0
set SHOW_CONTROL_MOVE 0
set SHOW_CONTROL_REPEAT 0
set SHOW_INST_FULL 0
set SHOW_FIFO 0

add wave clk
add wave reset

add wave -divider "Interface"

add wave write_enable
add wave busy

add wave read_addr
add wave -radix fx read_data
add wave -hex write_addr
add wave -radix fx write_data

add wave nn/act_write_enable
add wave -binary nn/w_write_enable
add wave -binary nn/status_write_enable


add wave nn/xy_write_enable_internal
add wave nn/xy_write_enable_external
add wave nn/xy_write_enable


if { $SHOW_CONTROL == 1 } {
    add wave -divider "Control Signals"
    add wave nn/controller/mac_acc_update
    add wave nn/controller/mac_acc_loopback
    add wave nn/serializer_update[0]

    add wave nn/xy_read_addr
    add wave nn/xy_write_select[0]
    
    add wave nn/xy_write_enable
    add wave nn/xy_write_enable_controller[0]
    add wave nn/xy_write_addr[0]
    add wave nn/controller/xy_write_addr_updated

    add wave nn/w_write_enable
    add wave nn/w_read_addr
    
    add wave nn/controller/xy_write_counter
    add wave nn/controller/end_of_batch
    add wave nn/controller/last_batch
    add wave nn/controller/batch_remainder
    add wave nn/controller/batch_count

    add wave nn/controller/act_mask
    add wave nn/activation_function/write_enable
}

if { $SHOW_CONTROL_REPEAT == 1 } {
    add wave -divider "Repeat Move logic"
    add wave nn/controller/repeat_update
}

add wave -divider "Instructions"
add wave -color "Dark Orchid" nn/controller/status

add wave -divider "> PIPELINE"
add wave -color "Yellow" nn/controller/inst_read_addr_prev
add wave -color "Yellow" nn/controller/layer_state
add wave -color "Yellow" nn/controller/layer

add wave -divider ">> PIPELINE"
add wave -divider "Mac Units"
add wave nn/xy_data_forwarding[1]
add wave -radix fx nn/xy_read_data
add wave -radix fx "nn/mac_gen[0]/mac_unit/x"
add wave -radix fx nn/w_read_data
add wave -radix fx nn/prod
add wave -radix fx nn/acc
add wave -radix fx nn/mac
add wave -divider ">>> PIPELINE"

add wave -divider "Serializer"
add wave -radix fx nn/serializer_out
add wave nn/serializer/serializer_update

add wave -divider "Activation Function"
add wave nn/controller/act_mask_prev
add wave nn/activation_function/mask
add wave nn/activation_function/function_type
add wave -radix fx nn/activation_function/x
add wave -divider ">>>> PIPELINE"
add wave -radix fx nn/activation_function/x_reg
add wave -radix act_a_fx nn/activation_function/a_coef
add wave -radix act_b_fx nn/activation_function/b_coef
add wave -radix fx nn/activation_function/fx

add wave -divider "XY Writeback"
add wave nn/xy_mem/write_enable
add wave nn/output_mem/write_enable


add wave nn/xy_mem/write_addr
add wave -radix fx nn/xy_mem/data_in

mem load -i ../memories/xy.mem -format mti /testbench/nn/xy_mem/data
mem load -i ../memories/inst.mem -format mti /testbench/nn/inst_mem/data
mem load -i ../memories/act_func.mem -format mti /testbench/nn/activation_function/lookup_table/data

for {set i 0} {$i < $NU_COUNT} {incr i} {
    mem load -i ../memories/w$i.mem -format mti /testbench/nn/mac_gen[$i]/w_mem/data
}

run -all
wave zoom range 0ns 200ns

mem save -o ../memories/output.mem -f mti -data decimal -addr decimal -wordsperline 1 /testbench/nn/output_mem/data
