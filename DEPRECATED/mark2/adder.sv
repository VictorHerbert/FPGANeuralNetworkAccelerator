module Adder #(parameter Q_SIZE, parameter LENGTH)(
    input clk,
    input[LENGTH-1:0][Q_SIZE-1:0] x,
    output[Q_SIZE-1:0] y
);
    wire [2*LENGTH-1:1][Q_SIZE-1:0] s;

    assign y = s[1];

    generate
    genvar i;
        for(i = 1; i < LENGTH; i++) begin : sum_gen
            assign s[i] = s[2*i]+s[2*i+1];
        end
        for(i = LENGTH; i < 2*LENGTH; i++) begin : sum_input
            assign s[i] = x[i-LENGTH];
        end
    endgenerate

endmodule