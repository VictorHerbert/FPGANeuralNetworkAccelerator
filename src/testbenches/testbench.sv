`timescale 1 ns / 1 ps
//`include "../definitions.sv"

import definitions::*;

module testbench;
    parameter CLK_PERIOD = 10;
    parameter CLK_HALF_PERIOD = CLK_PERIOD/2;

    logic clk = 1, reset = 0;

    initial repeat(300) #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(CLK_HALF_PERIOD) reset = 0; end

    logic write_enable;
    logic busy;

    logic [MM_DEPTH-1:0] read_addr;
    logic [MM_SIZE-1:0] read_data;
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
        await_ticks(1);

        /*write_packet(17'h4002, 16'd512);
        write_packet(17'h4003, 16'd512);
        write_packet(17'h4004, 16'd512);
        write_packet(17'h4005, 16'd2000);

        write_packet(17'h4006, 16'd0120);
        write_packet(17'h4007, 16'd0200);
        write_packet(17'h4008, 16'd0512);
        write_packet(17'h4006, 16'd0120);
        write_packet(17'h4007, 16'd0200);
        write_packet(17'h4008, 16'd0512);
        write_packet(17'h4006, 16'd0120);
        write_packet(17'h4007, 16'd0200);
        write_packet(17'h4008, 16'd0512);*/
    end
   
    initial begin
        await_ticks(60);
        read_packet(32'h0);
        read_packet(32'h1);
        read_packet(32'h2);
    end



endmodule