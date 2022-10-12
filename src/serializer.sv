module Serializer #(parameter SIZE, parameter WIDTH)(
    input clk,
    input serializer_update,
    
    input   [SIZE-1:0][WIDTH-1:0]   data_in,
    output  [WIDTH-1:0]             serial_out
);
    reg[SIZE-2:0][WIDTH-1:0] data;
    assign serial_out = serializer_update ? data_in[0] : data[0];

    always_ff @(posedge clk) begin
        if(serializer_update)
            data <= data_in[SIZE-1:1];
        else
            data <= {{WIDTH{1'bx}}, data[SIZE-2:1]};
    end

endmodule