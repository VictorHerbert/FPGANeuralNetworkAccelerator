module memory_cell_dual #(parameter DEPTH = 2, parameter BIT_SIZE = 16)(
    input clk, write_enable,
    input [$clog2(DEPTH)-1:0] read_addr,
    input [$clog2(DEPTH)-1:0] write_addr,

    input   [BIT_SIZE-1:0] data_in,
    output  [BIT_SIZE-1:0] data_out
);
 
	reg [BIT_SIZE-1:0] data [DEPTH-1:0];

    assign  data_out = data[read_addr];
  
    always @ (posedge clk) begin
        if (write_enable)
            data[write_addr] <= data_in;
        
        //data_out <= data[read_addr];
    end
endmodule


//{10, 1010}