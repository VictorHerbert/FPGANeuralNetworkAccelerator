module AdressRegister #(parameter DEPTH)(
    input clk,
    input write_enable,
    input[DEPTH-1:0] data_in,
    output[DEPTH-1:0] data_out
);
    reg[DEPTH-1:0] data;

    assign data_out = data;

    always_ff @(clk) begin
        if(write_enable)        data <= data_in;
        else                    data <= data+1;
    end


endmodule