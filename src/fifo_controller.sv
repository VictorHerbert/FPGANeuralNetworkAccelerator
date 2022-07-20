module FifoController #(parameter DEPTH)(
    input clk, reset, 
    input write_enable, read_enable,
    output[DEPTH-1:0] write_addr, 
    output[DEPTH-1:0] read_addr,
    output empty,
    output full
);

    reg[DEPTH-1:0] _write_addr;
    reg[DEPTH-1:0] _read_addr;
    assign write_addr = _write_addr;
    assign read_addr = _read_addr;

    wire[DEPTH-1:0] _read_addr_1 = _read_addr+'d1;
    wire[DEPTH-1:0] _write_addr_1 = _write_addr+'d1;

    assign empty = (_read_addr_1 == _write_addr);
    assign full = (_write_addr_1 == _read_addr);

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            _write_addr <= 'd1;
            _read_addr <= 'd0;
        end
        else begin
            if(write_enable & ~full) begin
                _write_addr <= _write_addr_1;
            end
            if(read_enable & ~empty) begin
                _read_addr <= _read_addr_1;
            end
        end
    end



endmodule