`timescale 1ns / 1ns

module testbench;
    logic  clk = 0, rst = 1, input_select = 1;

    parameter SIZE = 3;
    parameter DEPTH = 16;

    logic [DEPTH-1:0] x = 0;
    logic [DEPTH-1:0] y;
    logic [SIZE-1:0][SIZE-1:0][DEPTH-1:0] w;

    layer #(SIZE,DEPTH) l0(
        clk, rst, input_select,
        x, w, y
    );

    integer x_input, w_input, ret;

    initial begin
        x_input=$fopen("C:/Users/victo/Desktop/FPGA/Neural/src/inputs/x.in","r");
        w_input=$fopen("C:/Users/victo/Desktop/FPGA/Neural/src/inputs/w.in","r");


        for(integer i = 0; i < SIZE; i++) begin
            for(integer j = 0; j < SIZE; j++) begin
                ret = $fscanf(w_input,"%d", w[i][j]);
            end
        end

            rst = 1;
        #1  rst = 0;

    end

    initial begin
        #(2*(SIZE+4)) input_select = 0;
    end


    
    initial begin        
        for(integer i = 0; i < 4*SIZE; i++) begin
        	#2 clk = 1;
            ret = $fscanf(x_input,"%d", x);
            #2 clk = 0;
        end
        $fclose(x_input);
        $fclose(w_input);
    end
    

endmodule