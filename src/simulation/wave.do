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

set SHOW_INTERFACE 1
set SHOW_MEMORY_WRITE  1
set SHOW_CONTROL_MOVE 0
set SHOW_CONTROL_REPEAT 0
set SHOW_INST_FULL 0

set SHOW_MAC 1
set SHOW_SERIALIZER 1
set SHOW_ACT_FUNCTION 1
set SHOW_XY_MEMORY 1
set SHOW_INST_MEMORY 1
set SHOW_INST_MEMORY0 1

add wave clk
add wave reset

if {$SHOW_INTERFACE == 1} {
    add wave -divider "Interface"

    add wave read_enable
    add wave write_enable
    add wave available

    add wave -hex read_addr
    add wave -radix fx read_data
    add wave -hex write_addr
    add wave -radix fx write_data
}

if {$SHOW_MEMORY_WRITE == 1} {
    add wave -divider "Memory write"

    add wave nn/act_write_enable
    add wave -binary nn/w_write_enable
    add wave -binary nn/status_write_enable
    add wave nn/inst_write_enable

    add wave nn/xy_write_enable_internal
    add wave nn/xy_write_enable_external
    add wave nn/xy_write_enable
    
}

add wave -divider "Act Memory"

add wave nn/activation_function/write_enable
add wave nn/activation_function/write_addr
add wave nn/activation_function/write_data

add wave -divider "Act Memory 0"
add wave nn/activation_function/lookup_table/mem_bank_gen[0]/mem_i/write_enable
add wave nn/activation_function/lookup_table/mem_bank_gen[0]/mem_i/write_addr
add wave nn/activation_function/lookup_table/mem_bank_gen[0]/mem_i/data_in
add wave nn/activation_function/lookup_table/mem_bank_gen[0]/mem_i/data_out


if {$SHOW_INST_MEMORY == 1} {
    add wave -divider "Inst Memory"

    add wave nn/inst_write_enable
    add wave nn/inst_mem/memory_select

    add wave nn/inst_mem/read_addr
    add wave nn/inst_mem/write_addr

    add wave nn/inst_mem/data_in
    add wave nn/inst_mem/data_out
   
}

if {$SHOW_INST_MEMORY0 == 1} {
    add wave /nn/inst_mem/mem_bank_gen[0]/mem_i/read_addr
    add wave nn/inst_mem/mem_bank_gen[0]/mem_i/write_addr
    add wave nn/inst_mem/mem_bank_gen[0]/mem_i/write_enable
    add wave nn/inst_mem/mem_bank_gen[0]/mem_i/data_in
    add wave nn/inst_mem/mem_bank_gen[0]/mem_i/data_out
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

add wave -divider "Read Addresses"
add wave nn/w_read_addr
add wave nn/xy_read_addr

add wave -divider ">> PIPELINE"

if {$SHOW_MAC == 1} {
    add wave -divider "Mac Units"

    add wave nn/xy_read_addr
    add wave nn/xy_write_addr[1]

    add wave nn/xy_data_forwarding[1]
    add wave -radix fx nn/xy_read_data
    add wave -radix fx "nn/mac_gen[0]/mac_unit/x"
    add wave -radix fx nn/w_read_data
    add wave -radix fx nn/prod
    add wave -radix fx nn/acc
    add wave -radix fx nn/mac
    add wave -divider ">>> PIPELINE"
}

if {$SHOW_SERIALIZER == 1} {
    add wave -divider "Serializer"
    add wave -radix fx nn/serializer/data_in
    add wave -radix fx nn/serializer/data
    add wave -radix fx nn/serializer/serial_out
    add wave nn/serializer/serializer_update
}

if {$SHOW_XY_MEMORY == 1} {
    add wave -divider "Activation Function"

    add wave nn/activation_function/mask
    add wave nn/activation_function/function_type
    add wave -radix fx nn/activation_function/x

    add wave -divider ">>>> PIPELINE"
    add wave -radix fx nn/activation_function/x_reg
    add wave -radix act_a_fx nn/activation_function/a_coef
    add wave -radix act_b_fx nn/activation_function/b_coef
    add wave -radix fx nn/activation_function/fx
}

if {$SHOW_XY_MEMORY == 1} {
    add wave -divider "XY Memory"
    add wave nn/xy_mem/write_enable
    add wave nn/xy_mem/read_addr
    add wave -radix fx nn/xy_mem/data_out
    add wave nn/xy_mem/write_addr
    add wave -radix fx nn/xy_mem/data_in
}


