`timescale 1ns / 1ns

module testbench;
    logic  clk = 0, rst = 0, input_select = 1;
    
    parameter BIT_SIZE = 16;
    parameter LAYER_SIZE = 4;
    parameter LAYER_DEPTH = 4;

    logic [BIT_SIZE-1:0] x = 0, y, w_in;
    logic [LAYER_SIZE-1:0][BIT_SIZE-1:0]  w_out;

    logic write = 0;
    logic [$clog2(LAYER_DEPTH)-1:0] layer = 0;
    logic [$clog2(LAYER_SIZE)-1:0] node = 0;

    memory #(LAYER_SIZE,LAYER_DEPTH, BIT_SIZE) m0(
        clk, write,
        layer, node,

        w_in, w_out
    );

    layer #(LAYER_SIZE,BIT_SIZE) l0(
        clk, rst, input_select,
        x, w_out, y
    );

    integer x_input, w_input, ret;

    initial begin
        for(integer i = 0; i < LAYER_DEPTH; i++) begin
            for(integer j = 0; j < LAYER_SIZE; j++) begin
                #4 node++;
            end
            layer++;
        end
    end
    initial begin
        write = 1;
        #(4*LAYER_DEPTH*LAYER_SIZE) write = 0;
        
        rst = 1;
        #1 rst = 0;        
        #(4*LAYER_SIZE+1) input_select = 0;
    end
    initial begin
        x_input=$fopen("../src/inputs/x.in","r");
        w_input=$fopen("../src/inputs/w.in","r");

        #2
        for(integer i = 0; i < 100; i++) begin
            ret = $fscanf(w_input,"%d", w_in);
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