radix unsigned

add wave -height 20 -divider Stimulus 

add wave -height 20 nn/clk
add wave -height 20 nn/rst

add wave -height 20 -divider

add wave -height 20 nn/data_in
add wave -height 20 nn/data_out

do wave_layer.do

run -all
wave zoom range 0ns 45ns

