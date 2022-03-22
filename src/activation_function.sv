import definitions::*;

module ActivationFunction (
    input clk,
    input write_enable,
    input [ACT_LUT_DEPTH-1:0] write_addr,
    input[Q_INT-1:-Q_FRAC] write_data,

    input[Q_INT-1:-Q_FRAC] x,
    input act_bypass,
    input[ACT_MASK_SIZE-1:0] mask,
    output[Q_INT-1:-Q_FRAC] fx
);
    
    wire [Q_INT-1:-Q_FRAC] lut_out;
    wire [Q_INT-1:-Q_FRAC] interp;

    assign fx = act_bypass ? x : interp;
    // TODO check for size
    assign interp = lut_out[ACT_LUT_DEPTH-1:ACT_LUT_DEPTH-ACT_A_COEF_SIZE]*x+lut_out[ACT_A_COEF_SIZE-1:0];

    Memory #(
        .DEPTH(ACT_MASK_SIZE+ACT_LUT_DEPTH), .BIT_SIZE(Q_SIZE))
    lookup_table (
        .clk(clk),
        .write_enable(write_enable),
        .read_addr({mask, x[Q_INT-1:Q_INT-ACT_LUT_DEPTH]}),
        .write_addr({mask, write_addr}),

        .data_in(write_data),
        .data_out(lut_out)
    );

endmodule
