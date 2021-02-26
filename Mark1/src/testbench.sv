`timescale 1ns / 1ns

module testbench;
    parameter BIT_SIZE = 16;
    parameter LAYER_SIZE = 4;
    parameter LAYER_DEPTH = 4;

    logic  clk = 0, rst = 0, input_select = 1, weight_write_enable = 1, input_write_enable = 1;
    
    logic [BIT_SIZE-1:0] x = 0, y, y_mem;
    
    logic [$clog2(LAYER_DEPTH)-1:0] layer = 0;
    logic [$clog2(LAYER_SIZE)-1:0] node = 0;

    neural_network #(LAYER_SIZE, LAYER_DEPTH, BIT_SIZE) nn(
        clk, rst, 
        weight_write_enable, input_write_enable,
        input_select,
        layer, node,

        x, y, y_mem
    );

    integer x_input, w_input, ret;

    initial begin
        for(integer i = 0; i < 2*LAYER_DEPTH; i++) begin
            for(integer j = 0; j < LAYER_SIZE; j++) begin
                #4 node++;
            end
            layer++;
        end
    end
    initial begin

        weight_write_enable = 1;
        #(4*LAYER_DEPTH*LAYER_SIZE)
        weight_write_enable = 0;
        
        
           
        #(4*LAYER_SIZE)
        input_write_enable = 0;

        rst = 1;
        #1 rst = 0;     
        #(4*LAYER_SIZE-3)
        input_select = 0;
        
    end
    initial begin
        x_input=$fopen("../src/inputs/x.in","r");
        w_input=$fopen("../src/inputs/w.in","r");

        #2
        for(integer i = 0; i < 100; i++) begin            
            ret = $fscanf(x_input,"%d", x);
            #4;
        end

    end
    initial begin        
        for(integer i = 0; i < 100; i++) begin
        	#2 clk = 1;
            #2 clk = 0;
        end
        $fclose(x_input);
        $fclose(w_input);
    end
    

endmodule    