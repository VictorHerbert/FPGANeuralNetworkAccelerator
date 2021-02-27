
add wave -height 20 -divider Memory

add wave -height 20 -divider Output
add wave -height 20 -color "light blue" nn/input_mem/data

add wave -height 20 -divider Output
add wave -height 20 -color "light blue" nn/output_mem/data

add wave -height 20 -divider Weights
add wave -height 20 -color "light blue" {nn/weight_mem/gen_mem[0]/mi/data}
add wave -height 20 -color "light blue" {nn/weight_mem/gen_mem[1]/mi/data}
add wave -height 20 -color "light blue" {nn/weight_mem/gen_mem[2]/mi/data}
add wave -height 20 -color "light blue" {nn/weight_mem/gen_mem[3]/mi/data}