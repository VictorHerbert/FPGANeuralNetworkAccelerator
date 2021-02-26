module memory_weight #(parameter LAYER_SIZE, parameter LAYER_DEPTH, parameter BIT_SIZE = 16)(
    input clk, write_enable,
    
    input [$clog2(LAYER_DEPTH)-1:0] layer,  // layer
    input [$clog2(LAYER_SIZE)-1:0] node, //node

    input   [BIT_SIZE-1:0] data_in,
    output  [LAYER_SIZE-1:0][BIT_SIZE-1:0] data_out
);

    logic [LAYER_SIZE-1:0] write;    

    genvar i;
    generate
        
        for(i = 0; i < LAYER_SIZE; i++) begin : gen_mem
            assign write[i] = (node == i) & write_enable; // Implement manual decoder

            memory_cell #(LAYER_DEPTH, BIT_SIZE) mi(
                clk, write[i],
                layer, 
                data_in,
                data_out[i]
            );
        end
    endgenerate
endmodule


//{10, 1010}