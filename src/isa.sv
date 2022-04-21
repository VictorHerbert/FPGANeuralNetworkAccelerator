package isa;

    typedef enum logic [3:0] {
        INST_NOP = 4'd0,
        INST_MATMUL = 4'd1,
        INST_ACCMOV = 4'd2,
        INST_LOADMAC = 4'd3,
        INST_MATMULT = 4'd4,
        INST_VECTTOMAT = 4'd5,
        INST_WCONSTPROD = 4'd6,
        INST_WACC = 4'd7,
        INST_MAT_UPDATE = 4'd8,
        INST_HALT = 4'd9,
        INST_REPEAT = 4'd10
    } InstructionType;

    typedef struct packed {
        InstructionType mnemonic;
        logic [27:0] unused;
    } GenericInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] x_addr;
        logic [11:0] w_addr;
        logic [0:0] serializer_update;
        logic [2:0] unused;
    } MatmulInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] x_addr;
        logic [2:0] mac_addr;
        logic [12:0] unused;
    } LoadmacInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] y_addr;
        logic [2:0] length;
        logic [3:0] act_mask;
        logic bypass;
        logic input_select;
        logic loopback;
        logic operation;
        logic [4:0] unused;
    } AccmovInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] w_addr;
        logic [0:0] serializer_update;
        logic [14:0] unused;
    } MatmultInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] x_addr;
        logic [11:0] w_addr;
        logic [3:0] unused;
    } VecttomatInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] x_addr;
        logic [11:0] w_addr;
        logic [3:0] unused;
    } WconstprodInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] w_r_addr;
        logic [11:0] w_w_addr;
        logic [3:0] unused;
    } WaccInstPacket;

    typedef union packed {
        GenericInstPacket generic_inst_packet;
        MatmulInstPacket matmul_inst_packet;
        LoadmacInstPacket loadmac_inst_packet;
        AccmovInstPacket accmov_inst_packet;
        MatmultInstPacket matmult_inst_packet;
        VecttomatInstPacket vecttomat_inst_packet;
        WconstprodInstPacket wconstprod_inst_packet;
        WaccInstPacket wacc_inst_packet;
    } InstPacket;

endpackage