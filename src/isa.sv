package isa;

    typedef enum logic [2:0] {
        INST_RESET = 3'd2,
        INST_JUMP = 3'd3
    } InstructionType;
        
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