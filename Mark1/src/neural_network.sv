module neural_network #(parameter LAYER_SIZE = 3, parameter LAYER_DEPTH, parameter BIT_SIZE = 1)(
    input  clk, rst,
    weight_write_enable, input_write_enable,
    input_select,
    input [$clog2(LAYER_DEPTH)-1:0] addr_layer,
    input [$clog2(LAYER_SIZE)-1:0] addr_node,

    input  [BIT_SIZE-1:0] data_in, // Serial input
    output  [BIT_SIZE-1:0] data_out, // Serial output

    output  [BIT_SIZE-1:0] y
);

    logic [$clog2(LAYER_DEPTH)-1:0] layer = 0;
    logic [$clog2(LAYER_SIZE)-1:0] node;

    wire [LAYER_SIZE-1:0][BIT_SIZE-1:0] w;
    wire  [BIT_SIZE-1:0] x, x_mem;

    wire layer_roll = (node == 0);

    assign x = input_select ? x_mem : data_out;


    always_ff @( posedge layer_roll or posedge rst) begin
        if(rst)
            layer = 0;
        else begin
            if(layer < LAYER_DEPTH-1)
                layer <= layer + 1;
        end
    end


    layer #(LAYER_SIZE,BIT_SIZE) l0(
        clk, rst,
        node,

        x, w, data_out
    );

    memory_weight #(LAYER_SIZE, LAYER_DEPTH, BIT_SIZE) weight_mem(
        clk, weight_write_enable,
        addr_layer, addr_node,

        data_in, w
    );

    memory_cell_dual  #(LAYER_SIZE, BIT_SIZE) input_mem(
        clk, input_write_enable,
        node, addr_node, 

        data_in, x_mem
    );

    memory_cell_dual  #(LAYER_SIZE, BIT_SIZE) output_mem(
        clk, layer == LAYER_DEPTH-1, // replace by layer == last
        addr_node, node,

        data_out, y
    );

    

endmodule