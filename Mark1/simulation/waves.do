radix unsigned

add wave -height 20 -divider Stimulus 

add wave -height 20 nn/clk
add wave -height 20 nn/rst
add wave -height 20 nn/write_enable
add wave -height 20 nn/input_select
add wave -height 20 nn/layer
add wave -height 20 nn/node
add wave -height 20 -color "Goldenrod" y_mem

add wave -height 20 -divider

add wave -height 20 nn/data_in
add wave -height 20 nn/data_out

add wave -height 20 -divider FSM

add wave -height 20 -color "Sky blue" nn/l0/node
add wave -height 20 -color "Sky blue" nn/l0/state

add wave -height 20 -divider Layer

add wave -height 20 -color "Goldenrod" nn/l0/y
add wave -height 20 -color "Goldenrod" nn/l0/neuron_out
add wave -height 20 -color "Goldenrod" nn/l0/y_shifter

add wave -height 20 nn/l0/neuron_rst

add wave -height 20 -divider Y_Memory

add wave -height 20 -color "light blue" nn/y_mem/data

run -all
wave zoom range 0ps 45ns

