`timescale 1 ns / 1 ps

import definitions::*;

module testbench;
    parameter CLK_PERIOD = 10;
    parameter CLK_HALF_PERIOD = CLK_PERIOD/2;

    logic clk = 1, reset = 0;

    initial repeat(300) #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(3*CLK_PERIOD) reset = 0; end

    logic write_enable = 0;
    logic busy;

    logic [MM_DEPTH-1:0] read_addr;
    logic [Q_SIZE-1:0] read_data;
    logic [MM_DEPTH-1:0] write_addr;
    logic [MM_SIZE-1:0] write_data;

    task await_ticks(int ticks);
        repeat(ticks) @(posedge clk);
    endtask

    task write_packet (logic [MM_DEPTH-1:0] addr, logic [MM_SIZE-1:0] data);
        write_addr = addr;
        write_data = data;
        write_enable = 1'b1;
        @(posedge clk);
        write_addr = 'dx;
        write_data = 'dx;
        write_enable = 1'b0;
    endtask

    task read_packet(logic [MM_DEPTH-1:0] addr);
        read_addr = addr;
        @(posedge clk);
        read_addr = 'dx;
    endtask

    NeuralNetwork nn(
        .clk(clk), .reset(reset),

        .write_enable(write_enable),
        .busy(busy),

        .read_addr(read_addr),
        .read_data(read_data),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    initial begin
        await_ticks(2);
        write_packet(16'h0002, 16'h1000);
        write_packet(16'h0003, 16'h1000);
        write_packet(16'h0004, 16'h1000);

        await_ticks(2);
        write_packet(16'hC005, 16'd0003);
    end
   
    initial begin
        await_ticks(50);
        read_packet(32'h5);
        await_ticks(1);
        $display(read_data);

        read_packet(32'h6);
        await_ticks(1);
        $display(read_data);

        read_packet(32'h7);
        await_ticks(1);
        $display(read_data);
    end



endmodule