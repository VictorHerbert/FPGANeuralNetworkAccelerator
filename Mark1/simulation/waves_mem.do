radix decimal

add wave -height 20 -divider Stimulus 

add wave -height 20 clk
add wave -height 20 rst
add wave -height 20 write

add wave -height 20 -color yellow w_in
add wave -height 20 -color yellow w_out
add wave -height 20 -color yellow layer
add wave -height 20 -color yellow node

add wave -height 20 -divider Memory

add wave -height 20 m0/write



run -all
wave zoom range 0ps 45ns

