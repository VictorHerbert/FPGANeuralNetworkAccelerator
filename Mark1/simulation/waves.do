radix decimal

add wave -height 20 -divider Stimulus 

add wave -height 20 l0/clk
add wave -height 20 l0/rst
add wave -height 20 write
add wave -height 20 l0/input_select


add wave -height 20 -divider FSM

add wave -height 20 -color "Sky blue" l0/counter
add wave -height 20 -color "Sky blue" l0/state


add wave -height 20 -divider Input

add wave -height 20 -color yellow l0/w
add wave -height 20 -color yellow l0/x

add wave -height 20 -divider Output

add wave -height 20 -color "Goldenrod" l0/y
add wave -height 20 -color "Goldenrod" l0/neuron_out
add wave -height 20 -color "Goldenrod" l0/y_shifter
add wave -height 20 l0/neuron_rst


add wave -height 20 -divider Memory

add wave -height 20 -color "light blue" {m0/gen_mem[0]/mi/data}
add wave -height 20 -color "light blue" {m0/gen_mem[1]/mi/data}
add wave -height 20 -color "light blue" {m0/gen_mem[2]/mi/data}
add wave -height 20 -color "light blue" {m0/gen_mem[3]/mi/data}

run -all
wave zoom range 0ps 45ns

