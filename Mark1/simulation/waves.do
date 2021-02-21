radix decimal

add wave -height 20 -divider Input 

add wave -height 20 l0/clk
add wave -height 20 l0/rst
add wave -height 20 l0/input_select
add wave -height 20 -color yellow -expand l0/w
add wave -height 20 -color yellow l0/w_T

add wave -height 20 -divider FSM

add wave -height 20 -color "Spring Green" l0/counter
add wave -height 20 -color "Spring Green" l0/state


add wave -height 20 -divider Output

add wave -height 20 -color "Goldenrod" l0/x
add wave -height 20 -color "Goldenrod" l0/y
add wave -height 20 -color "Goldenrod" l0/neuron_out
add wave -height 20 -color "Goldenrod" l0/y_shifter
add wave -height 20 l0/neuron_rst


run -all
wave zoom range 0ps 45ns

