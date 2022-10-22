package definitions;

    localparam NU_COUNT = 4;

    localparam Q_INT = 4, Q_FRAC = 12;
    localparam Q_DEPTH = Q_INT + Q_FRAC;

    localparam MM_DEPTH = 16;
    localparam MM_WIDTH = 16;
       
    localparam STATUS_DEPTH = 12;

    localparam INST_MEM_DEPTH = 9;
    localparam INST_MEM_INPUT_WIDTH = 16;
    localparam INST_MEM_BANK = 4;
    localparam INST_MEM_WIDTH = INST_MEM_INPUT_WIDTH*INST_MEM_BANK;

    localparam XY_MEM_DEPTH = 12;
    localparam W_MEM_DEPTH = 12;
    localparam BUFFER_DEPTH = 4;
    localparam OUTPUT_MEM_DEPTH = 6;
    
    localparam ACT_MASK_SIZE = 4;
    localparam ACT_LUT_DEPTH = 6;
    localparam ACT_LUT_SIZE = 32;
    localparam ACT_LUT_MEM = 2;

    localparam ACT_A_Q_INT = 4;
    localparam ACT_A_Q_FRAC = 12;
    localparam ACT_A_COEF_SIZE = ACT_A_Q_INT + ACT_A_Q_FRAC;

    localparam ACT_B_Q_INT = 4;
    localparam ACT_B_Q_FRAC = 12;
    localparam ACT_B_COEF_SIZE = ACT_B_Q_INT + ACT_B_Q_FRAC;

    localparam [15:0] MM_REGION_XY = 16'h0000;
    localparam [15:0] MM_REGION_ACT = 16'h2000;
    localparam [15:0] MM_REGION_W [0:3] = {16'h4000, 16'h6000, 16'h8000, 16'hA000};
    localparam [15:0] MM_REGION_STATUS = 16'hC000;
    localparam [15:0] MM_REGION_INST = 16'hE000;


    localparam [15:0] MM_REGION_XY_MASK = 16'b000xxxxxxxxxxxxx;
    localparam [15:0] MM_REGION_ACT_MASK = 16'b001xxxxxxxxxxxxx;
    localparam [15:0] MM_REGION_W_MASK [0:3] = {
        16'b010xxxxxxxxxxxxx,
        16'b011xxxxxxxxxxxxx,
        16'b100xxxxxxxxxxxxx,
        16'b101xxxxxxxxxxxxx};
    localparam [15:0] MM_REGION_STATUS_MASK = 16'b110xxxxxxxxxxxxx;
    localparam [15:0] MM_REGION_INST_MASK = 16'b111xxxxxxxxxxxxx;


    typedef struct packed {
        logic reset;
        logic [10:0] x_offset;
        logic [11:0] w_offset;
        logic output_layer;
        logic [10:0] y_offset;
        logic [11:0] x_length;
        logic [11:0] y_length;
        logic [3:0] act_mask;
    } Layer;

    typedef struct packed {
        logic [14:0] unused;
        logic continuous;
        logic run;
    } Status;
    
endpackage