`timescale 1 ns / 1 ps

module fifo_testbench;
    parameter CLK_PERIOD = 10;
    parameter CLK_HALF_PERIOD = CLK_PERIOD/2;
    localparam LENGTH = 8;

    logic clk = 1, reset = 0;

    logic read_update = 0;
    logic write_enable = 0;
    logic empty;
    logic full;

    logic [LENGTH-1:0] data_in;
    logic [LENGTH-1:0] data_out;  

    task await_ticks(int ticks);
        repeat(ticks) @(posedge clk);
    endtask

    task write_data (logic [LENGTH-1:0] data);
        data_in = data;
        write_enable = 1'b1;
        @(posedge clk);
        data_in = 'dx;
        write_enable = 1'b0;
    endtask

    task read_data;
        read_update = 1'b1;
        @(posedge clk);
        read_update = 1'b0;
    endtask

    initial repeat(200) #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(CLK_HALF_PERIOD) reset = 0; end

    Fifo #(.SIZE(LENGTH), .DEPTH(5)) fifo(
        .clk(clk), .reset(reset),

        .read_update(read_update),
        .write_enable(write_enable),
        .empty(empty),
        .full(full),

        .data_in(data_in),
        .data_out(data_out)
    );

    initial repeat(40) write_data($random());
    initial begin
        await_ticks(5);
        repeat(40) read_data();
    end

endmodule
