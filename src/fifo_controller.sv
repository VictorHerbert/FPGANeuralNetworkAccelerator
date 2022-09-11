module FifoController #(parameter DEPTH)(
    input clk, reset, 
    input write_enable, read_enable,
    output reg [DEPTH-1:0] write_addr, 
    output reg [DEPTH-1:0] read_addr,
    output empty,
    output full
);
    wire[DEPTH-1:0] read_addr_next = read_addr + 1'd1;
    wire[DEPTH-1:0] write_addr_next = write_addr + 1'd1;

    assign empty = (read_addr_next == write_addr);
    assign full = (write_addr_next == read_addr);

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            write_addr <= 'd1;
            read_addr <= 'd0;
        end
        else begin
            if(write_enable & ~full)
                write_addr <= write_addr_next;
            if(read_enable & ~empty)
                read_addr <= read_addr_next;
        end
    end



endmodule