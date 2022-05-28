`timescale 1 ns / 1 ps
//`include "../definitions.sv"

import definitions::*;

module testbench;
    parameter CLK_PERIOD = 10;
    parameter CLK_HALF_PERIOD = CLK_PERIOD/2;

    logic clk = 1, reset = 0;

    initial repeat(200) #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(CLK_HALF_PERIOD) reset = 0; end

    NeuralNetwork nn(
        .clk(clk), .reset(reset)
    );

    wire [NU_COUNT-1:0][2*Q_INT-1:-2*Q_FRAC] prod_full = {
        nn.mac_gen[3].mac_unit.prod_full,
        nn.mac_gen[2].mac_unit.prod_full,
        nn.mac_gen[1].mac_unit.prod_full,
        nn.mac_gen[0].mac_unit.prod_full
    };

    wire [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] mac_reg = {
        nn.mac_gen[3].mac_unit.mac_reg,
        nn.mac_gen[2].mac_unit.mac_reg,
        nn.mac_gen[1].mac_unit.mac_reg,
        nn.mac_gen[0].mac_unit.mac_reg
    };


    wire [NU_COUNT-1:0] sum_pos_overflow = {
        nn.mac_gen[3].mac_unit.sum_pos_overflow,
        nn.mac_gen[2].mac_unit.sum_pos_overflow,
        nn.mac_gen[1].mac_unit.sum_pos_overflow,
        nn.mac_gen[0].mac_unit.sum_pos_overflow
    };

    wire [NU_COUNT-1:0] sum_neg_overflow = {
        nn.mac_gen[3].mac_unit.sum_neg_overflow,
        nn.mac_gen[2].mac_unit.sum_neg_overflow,
        nn.mac_gen[1].mac_unit.sum_neg_overflow,
        nn.mac_gen[0].mac_unit.sum_neg_overflow
    };

     wire [NU_COUNT-1:0] prod_pos_overflow = {
        nn.mac_gen[3].mac_unit.prod_pos_overflow,
        nn.mac_gen[2].mac_unit.prod_pos_overflow,
        nn.mac_gen[1].mac_unit.prod_pos_overflow,
        nn.mac_gen[0].mac_unit.prod_pos_overflow
    };

    wire [NU_COUNT-1:0] prod_neg_overflow = {
        nn.mac_gen[3].mac_unit.prod_neg_overflow,
        nn.mac_gen[2].mac_unit.prod_neg_overflow,
        nn.mac_gen[1].mac_unit.prod_neg_overflow,
        nn.mac_gen[0].mac_unit.prod_neg_overflow
    };

endmodule
