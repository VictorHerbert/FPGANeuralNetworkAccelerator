package isa;

    typedef enum logic [3:0] {
        INST_NOP = 4'd0,
        INST_MATMUL = 4'd1,
        INST_REPEAT = 4'd2,
        INST_ACCMOV = 4'd3,
        INST_FLUSHBUFFER = 4'd4,
        
        INST_JUMP = 4'd14,
        INST_BREQ = 4'd15
    } InstructionType;

    typedef struct packed {
        InstructionType mnemonic;
        logic [27:0] unused;
    } GenericInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] x_addr;
        logic [11:0] w_addr;
        logic [3:0] unused;
    } MatmulInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [11:0] length;
        logic [15:0] unused;
    } RepeatInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [12:0] y_addr;
        logic [4:0] length;
        logic [4:0] act_mask;
        logic [4:0] unused;
    } AccmovInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [13:0] inst_addr;
        logic [13:0] unused;
    } JmpInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [13:0] inst_addr;
        logic [3:0] r1;
        logic [3:0] r2;
        logic [5:0] unused;
    } BreqInstPacket;

    typedef struct packed {
        InstructionType mnemonic;
        logic [27:0] unused;
    } FlushbufferInstPacket;


endpackage