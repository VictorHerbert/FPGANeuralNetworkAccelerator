import definitions::*;

module NeuralNetwork(
    input clk, reset,

    input write_enable,
    output busy,

    input [MM_DEPTH-1:0] read_addr,
    output [MM_SIZE-1:0] read_data,
    input [MM_DEPTH-1:0] write_addr,
    input [MM_SIZE-1:0] write_data
);

    wire xy_write_select;

    wire buffer_read_enable;
    wire buffer_write_enable;
    wire buffer_empty;
    wire buffer_full;

    wire [BUFFER_LENGTH-1:0] buffer_addr_out;
    wire [Q_SIZE-1:0] buffer_data_out;

    wire mac_acc_loopback;
    wire mac_acc_update;
    wire serializer_update;
    wire serializer_shift;

    wire xy_write_enable;
    wire [NU_COUNT-1:0] w_write_enable;
    wire inst_write_enable;
    wire act_write_enable;

    wire [XY_MEM_DEPTH:0] xy_read_addr;
    wire [XY_MEM_DEPTH:0] xy_write_addr;
    wire [Q_SIZE-1:0] xy_read_data;
    wire [Q_SIZE-1:0] xy_write_data;
    
    
    wire [W_MEM_DEPTH-1:0] w_read_addr;
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
        .DEPTH(XY_MEM_DEPTH),
        .BIT_SIZE(Q_SIZE))
    xy_mem (
        .clk(clk),
        .write_enable(xy_write_enable),
        .read_addr(xy_read_addr),
        .write_addr(xy_write_select ? buffer_addr_out : xy_write_addr),
        .data_in(xy_write_select ? buffer_data_out : act_read_data),
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
            .read_addr(w_read_addr),
            .write_addr(buffer_addr_out),
            .data_in(buffer_data_out),
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
        .write_addr(buffer_addr_out),
        .write_data(buffer_data_out)
    );

    // ---------------------------------------
    // ------- IO Components  -----------
    // ---------------------------------------


    Fifo #(
        .SIZE(BUFFER_LENGTH+Q_SIZE),
        .DEPTH(BUFFER_DEPTH)
    )
    buffer(
        .clk(clk), .reset(reset),
        .read_update(buffer_read_enable),
        .write_enable(write_enable),
        .empty(buffer_empty),
        .full(busy),

        .data_in({write_addr[MM_DEPTH-1:0], write_data[Q_SIZE-1:0]}),
        .data_out({buffer_addr_out, buffer_data_out})
    );

    assign read_data[MM_SIZE-1:Q_SIZE] = 'd0;

    Memory #(
        .DEPTH(OUTPUT_MEM_DEPTH),
        .BIT_SIZE(Q_SIZE))
    output_mem(
        .clk(clk),
        .write_enable(xy_write_enable & xy_write_addr[XY_MEM_DEPTH]),
        .read_addr(read_addr[OUTPUT_MEM_DEPTH-1:0]),
        .write_addr(xy_write_addr[OUTPUT_MEM_DEPTH-1:0]),
        .data_in(act_read_data),
        .data_out(read_data[Q_SIZE-1:0])
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
        .write_addr(buffer_addr_out),
        .data_in(buffer_data_out),
        .data_out(inst_read_data)
    );


    Controller controller(
        .clk(clk),
        .reset(reset),

        .buffer_empty(buffer_empty),
        .buffer_addr(buffer_addr_out),
        .buffer_read_enable(buffer_read_enable),

        .inst_write_enable(inst_write_enable),
        .inst_read_addr(inst_read_addr),
        .inst_read_data(inst_read_data),

        .mac_acc_loopback(mac_acc_loopback),
        .mac_acc_update(mac_acc_update),

        .serializer_update(serializer_update),
        .serializer_shift(serializer_shift),
        
        .act_mask(act_mask),        
        .act_write_enable(act_write_enable),

        .xy_write_enable(xy_write_enable),
        .xy_write_select(xy_write_select),
        .xy_read_addr(xy_read_addr),      
        .xy_write_addr(xy_write_addr),

        .w_write_enable(w_write_enable),
        .w_read_addr(w_read_addr)
    );

endmodule