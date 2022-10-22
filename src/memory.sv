module Memory #(parameter DEPTH, parameter WIDTH)(
    input clk, write_enable,
    
    input       [DEPTH-1:0] read_addr,
    input       [DEPTH-1:0] write_addr,

    input       [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);

	reg [WIDTH-1:0] data [2**DEPTH-1:0];
    reg [DEPTH-1:0] read_addr_reg;


    assign  data_out = data[read_addr_reg];

    always @ (posedge clk) begin
        if (write_enable)
            data[write_addr] <= data_in;

        read_addr_reg <= read_addr;
    end
    

endmodule