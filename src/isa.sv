package isa;

    typedef enum logic [2:0] {
        INST_INPUT = 3'd1,
        INST_HALT = 3'd2,
        INST_JUMP = 3'd3
    } InstructionType;
        
    typedef struct packed {
        logic is_instruction;
        logic [10:0] x_offset;
        logic [11:0] w_offset;
        logic output_layer;
        logic [10:0] y_offset;
        logic [11:0] x_length;
        logic [11:0] y_length;
        logic [3:0] act_mask;
    } Layer;

    typedef struct packed {
        logic is_instruction;
        InstructionType instruction;
        logic [11:0] address;
        logic [47:0] unused;
    } Instruction;


endpackage