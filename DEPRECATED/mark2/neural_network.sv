import definitions::*;

module NeuralNetwork(
    input clk, reset
);

    // Control Signals
    wire [NU_COUNT-1:0] mac_reg_enable;
    wire mac_x_select;
    wire mac_w_select;
    wire mac_acc_loopback;
    wire mac_acc_update;

    wire serializer_update;
    wire serializer_shift;

    wire act_input_select;
    wire act_bypass;

    wire [XY_MEM_DEPTH-1:0] xy_read_addr;
    wire [XY_MEM_DEPTH-1:0] xy_write_addr;
    wire xy_write_enable;

    wire xy_acc_loopback;
    wire xy_acc_op;

    wire [W_MEM_DEPTH-1:0] w_read_addr;
    wire [W_MEM_DEPTH-1:0] w_write_addr;
    wire w_write_enable;

    wire inst_write_enable;
    wire [INST_MEM_DEPTH-1:0] inst_read_addr;
    wire [INST_MEM_DEPTH-1:0] inst_write_addr;
    wire [INST_MEM_SIZE-1:0] inst_data;

    // Datapath Signals
    wire[Q_SIZE-1:0] x;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] w;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] acc;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] mac;
    wire[NU_COUNT-1:0][Q_INT-1:-Q_FRAC] prod;

    wire [Q_INT-1:-Q_FRAC] adder_out;
    wire [Q_INT-1:-Q_FRAC] serializer_out;

    wire [Q_INT-1:-Q_FRAC] act_input;
    wire [Q_INT-1:-Q_FRAC] act_ouput;
    wire [ACT_MASK_SIZE-1:0] act_mask;

    wire [Q_INT-1:-Q_FRAC] xy_writeback;
    wire [Q_INT-1:-Q_FRAC] xy_acc;

    assign act_input = act_input_select ? serializer_out : adder_out;

    assign xy_writeback = xy_acc_loopback ? xy_acc : act_ouput;
    assign xy_acc = xy_acc_op ? x+act_ouput : x*act_ouput;

    // ----------------------------------------
    // ------- Datapath Components  -----------
    // ----------------------------------------
    Memory #(
        .DEPTH(XY_MEM_DEPTH), .BIT_SIZE(Q_SIZE)
    )
    xy_mem (
        .clk(clk),
        .write_enable(xy_write_enable),
        .read_addr(xy_read_addr),
        .write_addr(xy_write_addr),
        .data_in(xy_writeback),
        .data_out(x)
    );

    generate
    genvar i;
    for(i = 0; i < NU_COUNT; i++) begin : mac_gen
        Memory #(
            .DEPTH(W_MEM_DEPTH), .BIT_SIZE(Q_SIZE)
        )
        w_mem (
            .clk(clk),
            .write_enable(w_write_enable),
            .read_addr(w_read_addr),
            .write_addr(w_write_addr),
            .data_in(mac[i]),
            .data_out(w[i])
        );

        MacUnit mac_unit(
            .clk(clk), .reset(reset),

            .mac_x_select(mac_x_select),
            .mac_w_select(mac_w_select),
            .mac_reg_enable(mac_reg_enable[i]),
            .mac_acc_loopback(mac_acc_loopback),
            .mac_acc_update(mac_acc_update),
            .x(x),
            .w(w[i]),
            .prod(prod[i]),
            .acc(acc[i]),
            .mac(mac[i])
        );
    end
    endgenerate


    Adder #(
        .Q_SIZE(Q_SIZE),
        .LENGTH(NU_COUNT))
    adder (
        .clk(clk),
        .x(prod), .y(adder_out)
    );

    Serializer #(
        .INPUT_SIZE(NU_COUNT), .Q_SIZE(Q_SIZE))
    serializer (
        .clk(clk),
        .serializer_update(serializer_update),
        .serializer_shift(serializer_shift),
        .data_in(acc),
        .serial_out(serializer_out)
    );

    wire [ACT_LUT_DEPTH-1:0] act_addr;
    wire [ACT_LUT_SIZE-1:0] act_write_data;
    wire act_write_enable;

    ActivationFunction activation_function (
        .clk(clk),
        .act_bypass(act_bypass),
        .x(act_input),
        .fx(act_ouput),
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
        .write_addr(inst_write_addr),
        //.data_in(),
        .data_out(inst_data)
    );


    Controller controller(
        .clk(clk),
        .reset(reset),
        .inst_data(inst_data),
        .inst_addr(inst_read_addr),
        .inst_write_enable(inst_write_enable),
        .inst_write_addr(inst_write_addr),

        .mac_x_select(mac_x_select),
        .mac_w_select(mac_w_select),
        .mac_reg_enable(mac_reg_enable),
        .mac_acc_loopback(mac_acc_loopback),
        .mac_acc_update(mac_acc_update),

        .serializer_update(serializer_update),
        .serializer_shift(serializer_shift),

        .act_input_select(act_input_select),
        .act_mask(act_mask),
        .act_bypass(act_bypass),
        .act_addr(act_addr),
        .act_write_enable(act_write_enable),

        .xy_acc_loopback(xy_acc_loopback),
        .xy_acc_op(xy_acc_op),
        .xy_read_addr(xy_read_addr),
        .xy_write_enable(xy_write_enable),
        .xy_write_addr(xy_write_addr),

        .w_read_addr(w_read_addr),
        .w_write_enable(w_write_enable),
        .w_write_addr(w_write_addr)
    );

endmodule