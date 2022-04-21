import definitions::*;

module ActivationFunction (
    input clk,
    input write_enable,
    input [ACT_LUT_DEPTH-1:0] write_addr,
    input [ACT_LUT_SIZE-1:0] write_data,

    input signed [Q_INT-1:-Q_FRAC] x,
    input act_bypass,
    input[ACT_MASK_SIZE-1:0] mask,
    output signed [Q_INT-1:-Q_FRAC] fx
);
    
    wire signed [ACT_A_Q_INT-1:-ACT_A_Q_FRAC] a_coef;
    wire signed [ACT_B_Q_INT-1:-ACT_B_Q_FRAC] b_coef;
    wire signed [Q_INT+ACT_A_Q_INT-1:-(Q_FRAC+ACT_A_Q_FRAC)] full_product;
    wire signed [Q_INT+ACT_A_Q_INT-1:-(Q_FRAC+ACT_A_Q_FRAC)] b_shifted;
    wire signed [Q_INT-1:-Q_FRAC] interp;
   
    assign b_shifted = {{Q_INT+ACT_A_Q_INT-ACT_B_Q_INT-1{1'b0}}, b_coef, {(Q_FRAC+ACT_A_Q_FRAC)-ACT_B_Q_FRAC{1'b0}}};
    // TODO check for overflow
    assign full_product = a_coef*x+b_shifted;
    assign interp = full_product[Q_INT-1:-Q_FRAC];

    assign fx = act_bypass ? x : interp;

    Memory #(
        .DEPTH(ACT_MASK_SIZE+ACT_LUT_DEPTH), .BIT_SIZE(ACT_LUT_SIZE))
    lookup_table (
        .clk(clk),
        .write_enable(write_enable),
        .read_addr({mask, x[Q_INT-1:Q_INT-ACT_LUT_DEPTH]}),
        .write_addr({mask, write_addr}),

        .data_in(write_data),
        .data_out({a_coef, b_coef})
    );

endmodule
