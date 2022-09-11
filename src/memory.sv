module Memory #(parameter DEPTH, parameter BIT_SIZE, parameter ZEROS = 1'd0)(
    input clk, write_enable,
    input [DEPTH-1:0] read_addr,
    input [DEPTH-1:0] write_addr,

    input       [BIT_SIZE-1:0] data_in,
    output reg  [BIT_SIZE-1:0] data_out
);

	reg [BIT_SIZE-1:0] data [2**DEPTH-1:0];

    reg [DEPTH-1:0] read_addr_reg;

    

    // TODO include in pipeline
    assign  data_out = data[read_addr_reg]; // Async read

    always @ (posedge clk) begin
        if (write_enable)
            data[write_addr] <= data_in;

        //data_out <= data[read_addr]; // Sync read

        read_addr_reg <= read_addr;
    end

    
    initial begin
        if(ZEROS)
            for(int i = 0; i < 2**DEPTH; i++) data[i] <= 'd0;
    end
    

endmodule