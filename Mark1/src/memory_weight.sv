module memory_weight #(parameter LAYER_SIZE, parameter LAYER_DEPTH, parameter BIT_SIZE, parameter INIT_FILE = "")(
    input clk, write_enable,

    input [$clog2(LAYER_DEPTH)-1:0] layer,  // layer
    input [$clog2(LAYER_SIZE)-1:0] node, //node

    input [$clog2(LAYER_DEPTH)-1:0] addr_layer,  // layer
    input [$clog2(LAYER_SIZE)-1:0] addr_node_j, //node row
    input [$clog2(LAYER_SIZE)-1:0] addr_node_k, //node col

    input   [BIT_SIZE-1:0] data_in,
    output  [LAYER_SIZE-1:0][BIT_SIZE-1:0] data_out
);

    logic [LAYER_SIZE-1:0] write;    

    genvar i;
    generate
        
        for(i = 0; i < LAYER_SIZE; i++) begin : gen_mem
            assign write[i] = (addr_node_j == i) & write_enable; // Implement manual decoder
            
            memory_cell_dual #(LAYER_DEPTH * LAYER_SIZE, BIT_SIZE, INIT_FILE) mi(
                clk, write[i],
                {layer, node}, 
                {addr_layer, addr_node_k}, 
                data_in,
                data_out[i]
            );
        end
    endgenerate

endmodule


//{10, 1010}