module neural_network #(parameter LAYER_SIZE = 3, parameter LAYER_DEPTH, parameter BIT_SIZE = 1)(
    input  clk, rst, write_enable, input_select,
    input [$clog2(LAYER_DEPTH)-1:0] layer,
    input [$clog2(LAYER_SIZE)-1:0] node,

    input  [BIT_SIZE-1:0] data_in, // Serial input
    output  [BIT_SIZE-1:0] data_out, // Serial output

    output  [BIT_SIZE-1:0] y
);
    logic [$clog2(LAYER_DEPTH)-1:0] _layer;
    logic [$clog2(LAYER_SIZE)-1:0] _node;


    wire [LAYER_SIZE-1:0][BIT_SIZE-1:0] w;
    wire  [BIT_SIZE-1:0] x;

    assign x = input_select ? data_in : data_out;

    memory_weight #(LAYER_SIZE, LAYER_DEPTH, BIT_SIZE) m0(
        clk, write_enable,
        layer, node,

        data_in, w
    );

    layer #(LAYER_SIZE,BIT_SIZE) l0(
        clk, rst,
        _node,
        x, w, data_out
    );

    memory_cell_dual  #(LAYER_SIZE, BIT_SIZE) y_mem(
        clk, 1'b1,
        node, _node,

        data_out, y
    );

    

endmodule