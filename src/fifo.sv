module Fifo #(parameter WIDTH, parameter DEPTH)(
    input clk, reset,

    input   read_update,
    input   write_enable,
    output  reg empty,
    output  full, // FIXME check for pipeline

    input   [WIDTH-1:0] data_in,
    output  [WIDTH-1:0] data_out
);

    wire [DEPTH-1:0] write_addr;
    wire [DEPTH-1:0] read_addr;
    reg [1:0] empty_reg;

    FifoController #(.DEPTH(DEPTH))
    fifo_controller(
        .clk(clk), .reset(reset),
        .write_enable(write_enable), .read_enable(read_update),
        .write_addr(write_addr), .read_addr(read_addr),
        .empty(empty_reg[0]), .full(full)
    );

    /*always_ff @(posedge clk) begin
        empty_reg[1] <= empty_reg[0];
        empty <= empty_reg[1];
    end*/

    assign empty = empty_reg[0];


    Memory #(.DEPTH(DEPTH), .WIDTH(WIDTH), .ZEROS(1'd1))
    fifo_mem (
        .clk(clk),
        .write_enable(write_enable),

        .read_addr(read_addr),
        .write_addr(write_addr),

        .data_in(data_in),
        .data_out(data_out)
    );


endmodule