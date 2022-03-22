package definitions;

    localparam NU_COUNT = 4;
    localparam Q_INT = 4, Q_FRAC = 12;
    localparam Q_SIZE = Q_INT + Q_FRAC;

    localparam XY_MEM_DEPTH = 5;
    localparam W_MEM_DEPTH = 5;
    
    localparam INST_MEM_SIZE = 32;
    localparam INST_MEM_DEPTH = 64;

    localparam ACT_LUT_DEPTH = 4;
    localparam ACT_MASK_SIZE = 4;
    localparam ACT_A_COEF_SIZE = 2;

    typedef enum {
        INST_HALT,
        INST_NOP,
        INST_REPEAT,
        INST_MATMUL,
        INST_ACCMOV,
        INST_LOADMAC,
        INST_MATMULT,
        INST_VECTTOMAT,
        INST_WCONSTPROD,
        INST_WACC,
        INST_MAT_UPDATE
    } instruction_type;
    
endpackage