`timescale 1ns / 1ns

module testbench;
    parameter LAYER_SIZE = 4;
    parameter LAYER_DEPTH = 4;
    parameter BIT_SIZE = 16;

    parameter x_path = "../src/inputs/x.in";
    parameter w_path = "../src/inputs/w.in";

    logic  clk = 0, rst = 0, write_enable = 0, bank_select = 0;
    
    logic [BIT_SIZE-1:0] x = 0, y, y_mem;
    
    logic [$clog2(LAYER_DEPTH)-1:0] layer = 0;
    logic [$clog2(LAYER_SIZE)-1:0] node_j = 0, node_k = 0;

    neural_network #(LAYER_SIZE, LAYER_DEPTH, BIT_SIZE, x_path, w_path) nn(
        clk, rst, 
        weight_write_enable, input_write_enable,        

        layer, node_j, node_k,

        x, y
    );


    initial begin               
        rst = 1;
        #1
        rst = 0;          
    end    
    initial begin
        for(integer i = 0; i < 100; i++) begin
        	#2 clk = 0;
            #2 clk = 1;
        end
    end
    

endmodule    