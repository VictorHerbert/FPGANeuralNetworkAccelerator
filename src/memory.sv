module Memory #(parameter DEPTH, parameter BIT_SIZE)(
    input clk, write_enable,
    input [DEPTH-1:0] read_addr,
    input [DEPTH-1:0] write_addr,

    input       [BIT_SIZE-1:0] data_in,
    output reg  [BIT_SIZE-1:0] data_out
);

	reg [BIT_SIZE-1:0] data [2**DEPTH-1:0];


    // TODO include in pipeline
    assign  data_out = data[read_addr]; // Async read

    always @ (posedge clk) begin
        if (write_enable)
            data[write_addr] <= data_in;

        //data_out <= data[read_addr]; // Sync read
    end

endmodule