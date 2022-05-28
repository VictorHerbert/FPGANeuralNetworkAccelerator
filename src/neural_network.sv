import definitions::*;

module NeuralNetwork(
    input clk, reset,

    input write_enable,
    input read_enable,
    output busy,

    input [MM_LENGTH-1:0] addr,
    input [MM_SIZE-1:0] write_data,
    output [MM_SIZE-1:0] read_data
);

    wire buffer_read_enable;
    wire buffer_write_enable;
    wire buffer_empty;
    wire buffer_full;
    wire [Q_SIZE-1:0] buffer_data_out;

    wire mac_acc_loopback;
    wire mac_acc_update;

    wire serializer_update;
    wire serializer_shift;

    wire xy_write_enable;
    wire [NU_COUNT-1:0] w_write_enable;
    wire inst_write_enable;
    wire act_write_enable;

    wire [XY_MEM_DEPTH-1:0] xy_read_addr;
    wire [XY_MEM_DEPTH-1:0] xy_write_addr;
    wire [Q_SIZE-1:0] xy_read_data;
    wire [Q_SIZE-1:0] xy_write_data;
    
    wire [W_MEM_DEPTH-1:0] w_addr;
    wire [NU_COUNT-1:0][Q_SIZE-1:0] w_read_data;
    wire [NU_COUNT-1:0][Q_SIZE-1:0] w_write_data;

    wire [INST_MEM_DEPTH-1:0] inst_read_addr;
    wire [INST_MEM_SIZE-1:0] inst_read_data;
    wire [INST_MEM_SIZE-1:0] inst_write_data;

    wire[Q_SIZE-1:0] x;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] w;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] acc;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] mac;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] prod;
  
    wire [Q_INT-1:-Q_FRAC] serializer_out;

    
    wire [ACT_LUT_DEPTH-1:0] act_addr;
    wire [ACT_LUT_SIZE-1:0] act_write_data;
    wire [Q_INT-1:-Q_FRAC] act_input;
    wire [Q_INT-1:-Q_FRAC] act_read_data;
    wire [ACT_MASK_SIZE-1:0] act_mask;


    // ----------------------------------------
    // ------- Datapath Components  -----------
    // ----------------------------------------

    Memory #(
        .DEPTH(XY_MEM_DEPTH), .BIT_SIZE(Q_SIZE))
    xy_mem (
        .clk(clk),
        .write_enable(xy_write_enable),
        .read_addr(xy_read_addr),
        .write_addr(xy_write_addr),
        .data_in(xy_write_data),
        .data_out(xy_read_data)
    );

    wire signed [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] sum;
    wire signed [NU_COUNT-1:0][2*Q_INT-1:-2*Q_FRAC] prod_full;
    wire signed [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] loopback_sum;

    generate
    genvar i;
    for(i = 0; i < NU_COUNT; i++) begin : mac_gen
        Memory #(
            .DEPTH(W_MEM_DEPTH), .BIT_SIZE(Q_SIZE))
        w_mem (
            .clk(clk),
            .write_enable(w_write_enable[i]),
            .read_addr(w_addr),
            .write_addr(w_addr),
            .data_in(w_write_data),
            .data_out(w_read_data[i])
        );

        MacUnit mac_unit(
            .clk(clk),
            .mac_acc_loopback(mac_acc_loopback),
            .mac_acc_update(mac_acc_update),
            .x(xy_read_data),
            .w(w_read_data[i]),
            .prod(prod[i]),
            .acc(acc[i]),
            .mac(mac[i]),


            .sum(sum[i]),
            .prod_full(prod_full[i]),
            .loopback_sum(loopback_sum[i])
        );
    end
    endgenerate

    Serializer #(
        .INPUT_SIZE(NU_COUNT), .Q_SIZE(Q_SIZE))
    serializer (
        .clk(clk),
        .serializer_update(serializer_update),
        .serializer_shift(serializer_shift),
        .data_in(acc),
        .serial_out(serializer_out)
    );

  

    ActivationFunction activation_function (
        .clk(clk),
        .x(serializer_out),
        .fx(act_read_data),
        .mask(act_mask),

        .write_enable(act_write_enable),
        .write_addr(act_addr),
        .write_data(act_write_data)
    );

    // ---------------------------------------
    // ------- Control Components  -----------
    // ---------------------------------------
    Memory #(
        .DEPTH(INST_MEM_DEPTH),
        .BIT_SIZE(INST_MEM_SIZE))
    inst_mem(
        .clk(clk),
        .write_enable(inst_write_enable),
        .read_addr(inst_read_addr),
        .write_addr(inst_read_addr),
        .data_in(inst_write_data),
        .data_out(inst_read_data)
    );
  
    Fifo #(
        .SIZE(XY_MEM_DEPTH+Q_SIZE),
        .DEPTH(MM_BUFFER_DEPTH)
    )
    buffer(
        .clk(clk),
        .read_enable(buffer_read_enable),
        .write_enable(write_enable),
        .empty(buffer_empty),
        .full(busy),

        .data_in(write_data),
        .data_out(buffer_data_out)

    );


    Controller controller(
        .clk(clk),
        .reset(reset),

        .mm_write_enable(write_enable),
        .mm_read_enable(read_enable),
        .mm_addr(addr),
        .mm_read_data(read_data),
        .mm_write_data(write_data),

        .buffer_read_enable(buffer_read_enable),
        .buffer_empty(buffer_empty),
        .buffer_data_out(buffer_data_out),

        .inst_read_data(inst_read_data),
        .inst_write_data(inst_write_data),
        .inst_read_addr(inst_read_addr),
        .inst_write_enable(inst_write_enable),

        .mac_acc_loopback(mac_acc_loopback),
        .mac_acc_update(mac_acc_update),

        .serializer_update(serializer_update),
        .serializer_shift(serializer_shift),
        
        .act_mask(act_mask),        
        .act_addr(act_addr),
        .act_write_enable(act_write_enable),
        .act_write_data(act_write_data),
        .act_read_data(act_read_data),

        .xy_write_enable(xy_write_enable),
        .xy_read_addr(xy_read_addr),        
        .xy_write_addr(xy_write_addr),
        .xy_read_data(xy_read_data),
        .xy_write_data(xy_write_data),

        .w_write_enable(w_write_enable),
        .w_addr(w_addr),
        .w_read_data(w_read_data),
        .w_write_data(w_write_data)
    );

endmodule