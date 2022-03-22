import definitions::*;

module Controller (
    input clk, reset,

    input [INST_MEM_SIZE-1:0] inst_data,
    output reg [INST_MEM_DEPTH-1:0] inst_addr,
    output [INST_MEM_SIZE-1:0] inst_write_addr,
    output  inst_write_enable,

    output reg [NU_COUNT-1:0] mac_reg_enable,
    output reg mac_acc_loopback,
    output reg mac_x_select,
    output reg mac_w_select,

    output reg serializer_update,

    output reg act_input_select,
    output reg act_bypass,
    output reg[ACT_MASK_SIZE-1:0] act_mask,
    output reg [ACT_LUT_DEPTH-1:0] act_addr,
    output reg act_write_enable,

    output reg xy_acc_loopback,
    output reg xy_acc_op,

    output reg [XY_MEM_DEPTH-1:0] xy_read_addr,
    output reg [XY_MEM_DEPTH-1:0] xy_write_addr,
    output reg xy_write_enable,

    output reg [W_MEM_DEPTH-1:0] w_read_addr,
    output reg [W_MEM_DEPTH-1:0] w_write_addr,
    output reg w_write_enable
);
    instruction_type instruction;
    instruction_type prev_instruction;
    instruction_type next_instruction;    

    reg looped_instruction;
    assign looped_instruction = (instruction == prev_instruction);

    wire[$clog2(NU_COUNT)-1:0] mac_addr;

    reg [LENGTH_DEPTH-1:0] length0, length1;
    reg [LENGTH_DEPTH-1:0] counter;

    reg instruction_advance;
    reg counter_reset;


    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            inst_addr <= 0;
            counter <= 0;
        end
        else begin
            if(instruction_advance)
                inst_addr <= inst_addr+1;
            if(counter_reset)
                counter <= 0;
        end
    end

    forward_instruction_type forward_inst, next_forward_inst;


    always_ff @(posedge clk)  begin
        prev_instruction <= instruction;
        forward_inst <= next_forward_inst;
    end


    always_comb begin
        unique case (instruction)
            INST_FORWARD: begin
                case (forward_inst)
                    FORWARDINST_MATMUL: begin
                        counter_reset <= (counter == length0);
                        instruction_advance <= 0;
                        next_forward_inst <= counter_reset ? FORWARDINST_ACCMOV : FORWARDINST_MATMUL;
                    end
                    FORWARDINST_ACCMOV: begin
                        counter_reset <= (counter == length1);
                        instruction_advance <= (counter == length1);
                        next_forward_inst <= counter_reset ? FORWARDINST_MATMUL : FORWARDINST_ACCMOV;
                    end
                endcase
            end
 
        endcase
    end









endmodule
