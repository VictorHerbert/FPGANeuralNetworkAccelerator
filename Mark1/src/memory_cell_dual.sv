`timescale 1ns / 1ns

module memory_cell_dual #(parameter DEPTH, parameter BIT_SIZE = 16, parameter INIT_FILE = "")(
    input clk, write_enable,
    input [$clog2(DEPTH)-1:0] read_addr,
    input [$clog2(DEPTH)-1:0] write_addr,

    input   [BIT_SIZE-1:0] data_in,
    output  [BIT_SIZE-1:0] data_out
);
 
	reg [BIT_SIZE-1:0] data [DEPTH-1:0];

    assign  data_out = data[read_addr]; // Async read
  
    always @ (posedge clk) begin
        if (write_enable)
            data[write_addr] <= data_in;
    end

    // Initialization
    initial begin
        integer in, ret;
        if (INIT_FILE != "") begin
            in = $fopen(INIT_FILE,"r");            

            for(integer i = 0; i < 2**DEPTH; i++) begin            
                ret = $fscanf(in,"%d", data[i]);
            end
        end
    end
    
endmodule


//{10, 1010}