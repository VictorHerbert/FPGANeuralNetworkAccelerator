module Serializer #(parameter INPUT_SIZE, parameter Q_SIZE)(
    input clk,
    input serializer_update,
    input serializer_shift,
    input[INPUT_SIZE-1:0][Q_SIZE-1:0] data_in,
    output[Q_SIZE-1:0] serial_out
);
    reg[INPUT_SIZE-1:0][Q_SIZE-1:0] data;
    assign serial_out = data[0];

    always_ff @(posedge clk) begin
        if(serializer_update)
            data <= data_in;
        else if (serializer_shift)
            data <= {data[0], data[INPUT_SIZE-1:1]};
        else
            data <= 'x;
    end

endmodule