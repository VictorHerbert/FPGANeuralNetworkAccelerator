module Fifo #(parameter SIZE, parameter DEPTH)(
    input clk, reset,

    input read_update,
    input write_enable,
    output empty,
    output full,

    input [SIZE-1:0] data_in,
    output [SIZE-1:0] data_out
);

    wire[DEPTH-1:0] write_addr;
    wire[DEPTH-1:0] read_addr;

    FifoController #(.DEPTH(DEPTH))
    fifo_controller(
        .clk(clk), .reset(reset),
        .write_enable(write_enable), .read_enable(read_update),
        .write_addr(write_addr), .read_addr(read_addr),
        .empty(empty), .full(full)
    );


    Memory #(.DEPTH(DEPTH), .BIT_SIZE(SIZE))
    fifo_mem (
        .clk(clk),
        .write_enable(write_enable),

        .read_addr(read_addr),
        .write_addr(write_addr),

        .data_in(data_in),
        .data_out(data_out)
    );


endmodule