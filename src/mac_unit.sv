import definitions::*;

module MacUnit (
    input clk, reset,
    
    input mac_reg_enable,
    input mac_x_select,
    input mac_w_select,
    input mac_acc_loopback,

    input[Q_INT-1:-Q_FRAC] x,
    input[Q_INT-1:-Q_FRAC] w,
    output[Q_INT-1:-Q_FRAC] prod,
    output[Q_INT-1:-Q_FRAC] mac
);    
    localparam Q_SIZE = Q_INT + Q_FRAC;

    reg[Q_INT-1:-Q_FRAC] acc;
    reg[Q_INT-1:-Q_FRAC] mac_reg;

    assign prod = 
        (mac_x_select ? x : mac_reg)*
        (mac_w_select ? w : x);
    assign mac = prod + ({Q_SIZE{mac_acc_loopback}}&acc);
    
    always_ff @(posedge clk) begin
        if(mac_reg_enable)
            mac_reg <= x;
    end

    // TODO take out reset
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            acc <= 0;
        else
            acc <= mac;        
    end


endmodule