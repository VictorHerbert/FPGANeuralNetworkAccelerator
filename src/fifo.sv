module Fifo #(parameter SIZE, parameter DEPTH)(
    input clk,

    input read_enable,
    input write_enable,
    output empty,
    output full,

    input [SIZE-1:0] data_in,
    output [SIZE-1:0] data_out

);

endmodule