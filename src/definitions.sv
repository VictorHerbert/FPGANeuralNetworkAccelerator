package definitions;

    localparam NU_COUNT = 4;

    localparam Q_INT = 4, Q_FRAC = 12;
    localparam Q_SIZE = Q_INT + Q_FRAC;

    localparam MM_SIZE = 32;
    localparam INST_MEM_SIZE = 64;
    localparam MOV_LENGTH = 5;
    localparam REPEAT_LENGTH = 28;

    localparam MEM_DEPTH = 12;
    localparam STATUS_DEPTH = 12;

    localparam MM_DEPTH = 16;
    localparam INST_MEM_DEPTH = 6;

    localparam XY_MEM_DEPTH = 12;
    localparam W_MEM_DEPTH = 12;
    localparam BUFFER_DEPTH = 4;
    localparam OUTPUT_MEM_DEPTH = 6;
    
    
    localparam ACT_MASK_SIZE = 4;
    localparam ACT_LUT_DEPTH = 6;
    localparam ACT_LUT_SIZE = 32;

    localparam ACT_A_Q_INT = 4;
    localparam ACT_A_Q_FRAC = 12;
    localparam ACT_A_COEF_SIZE = ACT_A_Q_INT + ACT_A_Q_FRAC;

    localparam ACT_B_Q_INT = 4;
    localparam ACT_B_Q_FRAC = 12;
    localparam ACT_B_COEF_SIZE = ACT_B_Q_INT + ACT_B_Q_FRAC;

    
endpackage