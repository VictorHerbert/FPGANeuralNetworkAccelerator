import definitions::*;
import isa::Status;

module NeuralNetwork(
    input clk, reset,

    input   write_enable,
    output  busy,

    input   [MM_DEPTH-1:0]  read_addr,
    output  [Q_SIZE-1:0]    read_data,
    input   [MM_DEPTH-1:0]  write_addr,
    input   [MM_SIZE-1:0]   write_data
);

    Status                              status;
    reg                                 status_write_enable;

    reg                                 xy_write_enable;
    reg                                 xy_write_enable_internal;
    reg                                 xy_write_enable_external;
    reg     [2:0]                       xy_write_enable_controller;
    reg     [2:0]                       xy_write_select;
    reg     [2:0]                       xy_output_write_select;
    reg                                 xy_output_write_enable;
    reg     [1:0]                       xy_data_forwarding;
    wire    [XY_MEM_DEPTH-1:0]          xy_read_addr;
    reg     [2:0][XY_MEM_DEPTH-1:0]     xy_write_addr;
    wire    [Q_SIZE-1:0]                xy_read_data;
    wire    [Q_SIZE-1:0]                xy_write_data;
    

    reg     [NU_COUNT-1:0]              w_write_enable;
    wire    [W_MEM_DEPTH-1:0]           w_read_addr;
    wire    [NU_COUNT-1:0][Q_SIZE-1:0]  w_read_data;
    wire    [NU_COUNT-1:0][Q_SIZE-1:0]  w_write_data;

    reg     [1:0]                       mac_acc_loopback;
    reg     [1:0]                       mac_acc_update;

    wire                                inst_write_enable;
    wire    [INST_MEM_DEPTH-1:0]        inst_read_addr;
    wire    [INST_MEM_SIZE-1:0]         inst_read_data;
    wire    [INST_MEM_SIZE-1:0]         inst_write_data;

    reg     [2:0]                       serializer_update;
    reg     [1:0]                       serializer_shift;
    wire    [Q_INT-1:-Q_FRAC]           serializer_out;

    reg                                 act_write_enable;
    wire    [ACT_LUT_DEPTH-1:0]         act_addr;
    wire    [ACT_LUT_SIZE-1:0]          act_write_data;
    wire    [Q_INT-1:-Q_FRAC]           act_input;
    reg     [1:0][Q_INT-1:-Q_FRAC]      act_read_data;
    reg     [1:0][ACT_MASK_SIZE-1:0]    act_mask;

    wire    [Q_SIZE-1:0]                    x;
    wire    [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] w;
    wire    [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] acc;
    wire    [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] mac;
    wire    [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] prod;


    // ----------------------------------------
    // ------- Memory Map  -----------
    // ----------------------------------------

    

    always_comb begin
        xy_write_enable_external = 1'b0;
        act_write_enable    = 1'b0;
        w_write_enable      = 3'b0;
        status_write_enable = 1'b0;

        if(write_enable)
            casex(write_addr)
                16'b000xxxxxxxxxxxxx: xy_write_enable_external = 1'b1; // TODO fix: 1 most of the tme
                16'b001xxxxxxxxxxxxx: act_write_enable  = 1'b1;
                16'b010xxxxxxxxxxxxx: w_write_enable[3] = 1'b1;
                16'b011xxxxxxxxxxxxx: w_write_enable[2] = 1'b1;
                16'b100xxxxxxxxxxxxx: w_write_enable[1] = 1'b1;
                16'b101xxxxxxxxxxxxx: w_write_enable[0] = 1'b1;
                16'b110xxxxxxxxxxxxx: status_write_enable = 1'b1;
                //TODO Instruction mem
            endcase
    end

    assign xy_write_select = xy_write_enable_external;
    assign xy_write_enable_internal = xy_write_enable_controller[2] & ~xy_output_write_select[2];
    assign xy_write_enable = xy_write_enable_external | xy_write_enable_internal;

    assign xy_output_write_enable = xy_write_enable_controller[2] & xy_output_write_select[2];

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            status <= 0;
        end
        else begin
            if(status_write_enable)     status <= write_data;
            else                        status.run <= 1'b0;
        end
    end

    // ----------------------------------------
    // ------- Pipeline Registers  -----------
    // ----------------------------------------

    assign xy_data_forwarding[0] = (xy_read_addr == xy_write_addr[1]);

    always_ff @(posedge clk) begin : pipeline
        mac_acc_loopback[1] <= mac_acc_loopback[0];
        mac_acc_update[1] <= mac_acc_update[0];
        serializer_update[2:1] <= serializer_update[1:0];
        serializer_shift[1] <= serializer_shift[0];
        act_mask[1] <= act_mask[0];
        xy_write_addr[2:1] <= xy_write_addr[1:0];
        xy_write_enable_controller[2:1] <= xy_write_enable_controller[1:0];
        xy_data_forwarding[1] <= xy_data_forwarding[0];
        xy_output_write_select[2:1] <= xy_output_write_select[1:0];
        act_read_data[1] <= act_read_data[0];
    end

    // ----------------------------------------
    // ------- Datapath Components  -----------
    // ----------------------------------------

    Memory #(.DEPTH(XY_MEM_DEPTH), .WIDTH(Q_SIZE))
    xy_mem (
        .clk(clk),
        .write_enable(xy_write_enable),
        .read_addr(xy_read_addr),
        .write_addr(xy_write_select ? write_addr[XY_MEM_DEPTH-1:0] : xy_write_addr[2]),
        .data_in(xy_write_select ? write_data[Q_SIZE-1:0] : act_read_data),
        .data_out(xy_read_data)
    );

    // TODO delete after functional tests
    wire signed [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] sum;
    wire signed [NU_COUNT-1:0][2*Q_INT-1:-2*Q_FRAC] prod_full;
    wire signed [NU_COUNT-1:0][Q_INT-1:-Q_FRAC] loopback_sum;

    generate
    genvar i;
    for(i = 0; i < NU_COUNT; i++) begin : mac_gen
        Memory #(.DEPTH(W_MEM_DEPTH), .WIDTH(Q_SIZE))
        w_mem (
            .clk(clk),
            .write_enable(w_write_enable[i]),
            .read_addr(w_read_addr),
            .write_addr(write_addr[W_MEM_DEPTH-1:0]),
            .data_in(write_data[Q_SIZE-1:0]),
            .data_out(w_read_data[i])
        );

        MacUnit mac_unit(
            .clk(clk),
            .mac_acc_loopback(mac_acc_loopback[1]),
            .mac_acc_update(mac_acc_update[1]),
            .x(xy_data_forwarding[1] ? act_read_data : xy_read_data),
            .w(w_read_data[i]),
            .prod(prod[i]),
            .acc(acc[i]),
            .mac(mac[i]),

            .prod_full(prod_full[i]),
            .loopback_sum(loopback_sum[i])
        );
    end
    endgenerate

    Serializer #(.SIZE(NU_COUNT), .WIDTH(Q_SIZE))
    serializer (
        .clk(clk),
        .data_in(acc),
        .serializer_update(serializer_update[2]),
        .serial_out(serializer_out)
    );


    ActivationFunction activation_function (
        .clk(clk),
        .x(serializer_out),

        .fx(act_read_data[0]),
        .mask(act_mask[1]),

        .write_enable(act_write_enable),
        .write_addr(write_addr[ACT_MASK_SIZE+ACT_LUT_DEPTH-1:0]),
        .write_data(write_data[Q_SIZE-1:0])
    );

    // ---------------------------------------
    // ------- IO Components  -----------
    // ---------------------------------------

    Memory #(.DEPTH(OUTPUT_MEM_DEPTH), .WIDTH(Q_SIZE))
    output_mem(
        .clk(clk),
        .write_enable(xy_output_write_enable),
        .read_addr(read_addr[OUTPUT_MEM_DEPTH-1:0]),
        .write_addr(xy_write_addr[2][OUTPUT_MEM_DEPTH-1:0]),
        .data_in(act_read_data[0]),
        .data_out(read_data[Q_SIZE-1:0])
    );

    // ---------------------------------------
    // ------- Control Components  -----------
    // ---------------------------------------

    Memory #(.DEPTH(INST_MEM_DEPTH), .WIDTH(INST_MEM_SIZE))
    inst_mem(
        .clk(clk),
        .write_enable(inst_write_enable),
        .read_addr(inst_read_addr),
        .write_addr(write_addr[INST_MEM_DEPTH-1:0]),
        .data_in(write_data), // FIXME write_data is 32 bits wide, instruction is 64
        .data_out(inst_read_data)
    );

    ControllerFSM controller(
        .clk(clk),
        .reset(reset),
        .status(status),

        .inst_write_enable(inst_write_enable),
        .inst_read_addr(inst_read_addr),
        .inst_read_data(inst_read_data),

        .mac_acc_loopback(mac_acc_loopback[0]),
        .mac_acc_update(mac_acc_update[0]),

        .serializer_update(serializer_update[0]),
        .serializer_shift(serializer_shift[0]),

        .act_mask(act_mask[0]),

        .xy_write_enable(xy_write_enable_controller[0]),
        .xy_output_write_select(xy_output_write_select[0]),
        .xy_read_addr(xy_read_addr),
        .xy_write_addr(xy_write_addr[0]),

        .w_read_addr(w_read_addr)
    );

endmodule