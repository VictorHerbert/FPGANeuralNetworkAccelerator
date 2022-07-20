import definitions::*;

module MacUnit (
    input clk,

    input mac_acc_loopback,
    input mac_acc_update,

    input signed [Q_INT-1:-Q_FRAC] x,
    input signed [Q_INT-1:-Q_FRAC] w,
    output reg signed [Q_INT-1:-Q_FRAC] prod,
    output reg signed [Q_INT-1:-Q_FRAC] acc,
    output reg signed [Q_INT-1:-Q_FRAC] mac,

    // in IO for simulation only
    // TODO use a bigger vector to store sum
    output reg signed [Q_INT-1:-Q_FRAC] sum,
    output reg signed [2*Q_INT-1:-2*Q_FRAC] prod_full,
    output signed [Q_INT-1:-Q_FRAC] loopback_sum
);

    wire sum_pos_overflow, sum_neg_overflow;
    wire prod_pos_overflow, prod_neg_overflow;

    assign prod_full = x*w;


    assign sum_pos_overflow = ({prod[Q_INT-1], loopback_sum[Q_INT-1], sum[Q_INT-1]} == 3'b001);
    assign sum_neg_overflow = ({prod[Q_INT-1], loopback_sum[Q_INT-1], sum[Q_INT-1]} == 3'b110);

    assign prod_pos_overflow = ~prod_full[2*Q_INT-1] & |prod_full[2*Q_INT-2:Q_INT-1];
    assign prod_neg_overflow = prod_full[2*Q_INT-1] & ~(&prod_full[2*Q_INT-2:Q_INT-1]);


    assign loopback_sum = ({Q_SIZE{mac_acc_loopback}}&acc);
    assign sum = prod + loopback_sum;

    always_comb begin
        case ({sum_pos_overflow, sum_neg_overflow})
            2'b10:
                mac <= {1'b0, {Q_SIZE-1{1'b1}}};
            2'b01:
                mac <= {1'b1, {Q_SIZE-1{1'b0}}};
            default:
                mac <= sum;
        endcase
    end

    always_comb begin
        case ({prod_pos_overflow, prod_neg_overflow})
            2'b10:
                prod <= {1'b0, {Q_SIZE-1{1'b1}}};
            2'b01:
                prod <= {1'b1, {Q_SIZE-1{1'b0}}};
            default:
                prod <= prod_full[Q_INT-1:-Q_FRAC];
        endcase
    end

    always_ff @(posedge clk) begin
        if (mac_acc_update)
            acc <= mac;
    end


endmodule