import definitions::*;

module ActivationFunction (
    input clk,
    input write_enable,

    input signed        [Q_INT-1:-Q_FRAC]   x,
    input               [ACT_MASK_SIZE-1:0] mask,
    output reg signed   [Q_INT-1:-Q_FRAC]   fx,
    
    input [ACT_MASK_SIZE+ACT_LUT_DEPTH-1:0] write_addr,
    input [ACT_LUT_SIZE-1:0]                write_data    
);

    typedef enum logic [3:0] {
        FUNC_LUT = 4'd0,
        FUNC_ID = 4'd1,
        FUNC_STEP = 4'd2,
        FUNC_RELU = 4'd3
    } FunctionType;

    FunctionType function_type, function_type_reg;
    
    wire signed [ACT_A_Q_INT-1:-ACT_A_Q_FRAC] a_coef;
    wire signed [ACT_B_Q_INT-1:-ACT_B_Q_FRAC] b_coef;
    wire signed [Q_INT+ACT_A_Q_INT-1:-(Q_FRAC+ACT_A_Q_FRAC)] full_product;
    wire signed [Q_INT+ACT_A_Q_INT-1:-(Q_FRAC+ACT_A_Q_FRAC)] b_shifted;
    wire signed [Q_INT-1:-Q_FRAC] interp;

    reg signed [Q_INT-1:-Q_FRAC] x_reg;

    assign function_type = FunctionType'(mask[ACT_MASK_SIZE-1:ACT_MASK_SIZE-2]);
   
    assign b_shifted = {{Q_INT+ACT_A_Q_INT-ACT_B_Q_INT-1{1'b0}}, b_coef, {(Q_FRAC+ACT_A_Q_FRAC)-ACT_B_Q_FRAC{1'b0}}};
    // TODO check for overflow
    assign full_product = a_coef*x_reg+b_shifted;
    assign interp = full_product[Q_INT-1:-Q_FRAC];

    

    always_ff @(posedge clk) begin
        x_reg <= x;
        function_type_reg <= function_type;
    end
    
    always_comb begin
        case(function_type_reg)
            FUNC_ID:    fx <= x_reg;
            FUNC_STEP:  fx <= ~x_reg[Q_INT-1];
            FUNC_RELU:  fx <= {Q_SIZE-1{~x_reg[Q_INT-1]}}&x_reg;
            FUNC_LUT:   fx <= interp;
        endcase
    end

    Memory #(.DEPTH(ACT_MASK_SIZE+ACT_LUT_DEPTH), .WIDTH(ACT_LUT_SIZE))
    lookup_table (
        .clk(clk),
        .write_enable(write_enable),
        .read_addr({mask, x[Q_INT-1:Q_INT-ACT_LUT_DEPTH]}),
        .write_addr(write_addr),

        .data_in(write_data),
        .data_out({a_coef, b_coef})
    );

endmodule
