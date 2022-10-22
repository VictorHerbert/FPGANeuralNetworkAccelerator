`default_nettype none

module MemoryBank #(parameter DEPTH, parameter WIDTH, parameter BANKS)(
    input wire clk, write_enable,
    
    input wire      [DEPTH-1:0] read_addr,
    input wire      [DEPTH+$clog2(BANKS)-1:0] write_addr,

    input wire      [WIDTH/BANKS-1:0] data_in,
    output reg      [WIDTH-1:0] data_out
);

    reg [BANKS-1:0] memory_select;

    always_comb begin
        memory_select = 0;
        memory_select[write_addr[$clog2(BANKS)-1:0]] = 1;
    end

    generate
    genvar i;
        for(i = 0 ; i < BANKS; i++) begin : mem_bank_gen    
            Memory #(DEPTH, WIDTH/BANKS) mem_i(
                .clk(clk), .write_enable(write_enable & memory_select[i]),
                
                .read_addr(read_addr),
                .write_addr(write_addr[DEPTH+$clog2(BANKS)-1:$clog2(BANKS)]),

                .data_in(data_in),
                .data_out(data_out[WIDTH/BANKS*(i+1)-1:WIDTH/BANKS*i])
            );
        end
    endgenerate 
    

endmodule

// READ     addr+2 -> 4x16
// WRITE    addr --> 1x64