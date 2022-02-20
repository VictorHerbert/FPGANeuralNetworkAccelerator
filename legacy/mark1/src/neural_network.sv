module neural_network #(
    parameter LAYER_SIZE = 4,
    parameter LAYER_DEPTH = 4,
    parameter BIT_SIZE = 16, 
    parameter X_INIT_FILE = "", 
    parameter W_INIT_FILE = ""
)(
    input  clk, rst,
    weight_write_enable, input_write_enable,

    input [$clog2(LAYER_DEPTH)-1:0] addr_layer,
    input [$clog2(LAYER_SIZE)-1:0] addr_node_j,
    input [$clog2(LAYER_SIZE)-1:0] addr_node_k,

    input  [BIT_SIZE-1:0] data_in, // Serial input
    output  [BIT_SIZE-1:0] data_out // Serial output
);

    logic [$clog2(LAYER_DEPTH)-1:0] layer;
    logic [$clog2(LAYER_SIZE)-1:0] node;


    wire [LAYER_SIZE-1:0][BIT_SIZE-1:0] w;
    wire [BIT_SIZE-1:0] x, x_mem, y;

    wire input_select = (layer == 0);
    wire  [BIT_SIZE-1:0] y_layer;

    assign x = input_select ? x_mem : y_layer;

    layer #(LAYER_SIZE, LAYER_DEPTH, BIT_SIZE) l0(
        clk, rst,
        layer, node,

        x, w, y_layer
    );

    memory_weight #(LAYER_SIZE, LAYER_DEPTH, BIT_SIZE, W_INIT_FILE) weight_mem(
        clk, weight_write_enable,
        
        layer, node,// node_k,
        addr_layer, addr_node_j, addr_node_k,

        data_in, w
    );

    memory_cell_dual  #(LAYER_SIZE, BIT_SIZE, X_INIT_FILE) input_mem(
        clk, input_write_enable,
        node, addr_node_j, 

        data_in, x_mem
    );

    memory_cell_dual  #(LAYER_SIZE, BIT_SIZE) output_mem(
        clk, (layer == LAYER_DEPTH-1), // replace by layer == last
        addr_node_j, node,

        y_layer, data_out
    );

    

endmodule