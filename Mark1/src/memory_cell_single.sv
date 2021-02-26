module memory_cell #(parameter DEPTH = 2, parameter BIT_SIZE = 16)(
    input clk, write_enable,
    input [$clog2(DEPTH)-1:0] addr, //2**DEPTH size

    input   [BIT_SIZE-1:0] data_in,
    output  [BIT_SIZE-1:0] data_out
);
 
	reg [BIT_SIZE-1:0] data [DEPTH-1:0];
 
   assign  data_out = data[addr];
 
    always @ (posedge clk) begin
        if (write_enable)
            data[addr] <= data_in;
    end
endmodule


//{10, 1010}