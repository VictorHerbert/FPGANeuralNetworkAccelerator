transcript off

radix unsigned

add wave clk
add wave reset
add wave read_update
add wave write_enable
add wave empty
add wave full

add wave data_in
add wave write_enable
add wave fifo/write_addr
add wave read_enable
add wave fifo/read_addr

add wave data_out

run -all
wave zoom range 0ns 500ns
