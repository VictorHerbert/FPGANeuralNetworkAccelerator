import definitions::*;

module MacUnit (
    input clk, reset,

    input mac_reg_enable,
    input mac_x_select,
    input mac_w_select,
    input mac_acc_loopback,
    input mac_acc_update,

    input signed [Q_INT-1:-Q_FRAC] x,
    input signed [Q_INT-1:-Q_FRAC] w,
    output reg signed [Q_INT-1:-Q_FRAC] prod,
    output reg signed [Q_INT-1:-Q_FRAC] acc,
    output reg signed [Q_INT-1:-Q_FRAC] mac
);

    localparam Q_SIZE = Q_INT + Q_FRAC;

    // TODO use a bigger vector to store sum
    reg signed [Q_INT-1:-Q_FRAC] sum;
    reg signed [Q_INT-1:-Q_FRAC] mac_reg;
    wire signed [2*Q_INT-1:-2*Q_FRAC] prod_full;
    wire signed [Q_INT-1:-Q_FRAC] loopback_sum;

    wire sum_pos_overflow, sum_neg_overflow;
    wire prod_pos_overflow, prod_neg_overflow;

    assign prod_full =
        ((mac_x_select ? x : mac_reg)*
        (mac_w_select ? w : x));


    assign sum_pos_overflow = ({prod[Q_INT-1],loopback_sum[Q_INT-1],sum[Q_INT-1]} == 3'b001);
    assign sum_neg_overflow = ({prod[Q_INT-1],loopback_sum[Q_INT-1],sum[Q_INT-1]} == 3'b110);

    assign prod_pos_overflow = ~prod_full[2*Q_INT-1] & |prod_full[2*Q_INT-2:Q_INT-1];
    assign prod_neg_overflow = prod_full[2*Q_INT-1] & ~(&prod_full[2*Q_INT-2:Q_INT-1]);


    assign loopback_sum = ({Q_SIZE{mac_acc_loopback}}&acc);
    assign sum = prod + loopback_sum;

    always_comb begin
        case ({sum_pos_overflow,sum_neg_overflow})
            2'b10:
                mac <= {1'b0, {Q_SIZE-1{1'b1}}};
            2'b01:
                mac <= {1'b1, {Q_SIZE-1{1'b0}}};
            default:
                mac = sum;
        endcase
    end

    always_comb begin
        case ({prod_pos_overflow,prod_neg_overflow})
            2'b10:
                prod <= {1'b0, {Q_SIZE-1{1'b1}}};
            2'b01:
                prod <= {1'b1, {Q_SIZE-1{1'b0}}};
            default:
                prod = prod_full[Q_INT-1:-Q_FRAC];
        endcase
    end


    always_ff @(posedge clk) begin
        if(mac_reg_enable)
            mac_reg <= x;
    end

    // TODO take out reset
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            acc <= 0;
        else if (mac_acc_update)
            acc <= mac;
    end


endmodule