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

    reg [NU_COUNT-1:0] prev_mac_reg_enable;
    reg prev_mac_acc_loopback;
    reg prev_mac_x_select;
    reg prev_mac_w_select;

    reg prev_serializer_update;

    reg prev_act_input_select;
    reg prev_act_bypass;
    reg [ACT_MASK_SIZE-1:0] prev_act_mask;
    reg [ACT_LUT_DEPTH-1:0] prev_act_addr;
    reg prev_act_write_enable;

    reg prev_xy_acc_loopback;
    reg prev_xy_acc_op;

    reg [XY_MEM_DEPTH-1:0] prev_xy_read_addr;
    reg [XY_MEM_DEPTH-1:0] prev_xy_write_addr;
    reg prev_xy_write_enable;

    reg [W_MEM_DEPTH-1:0] prev_w_read_addr;
    reg [W_MEM_DEPTH-1:0] prev_w_write_addr;
    reg prev_w_write_enable;

    reg [15:0] counter;
    wire [15:0] length;

    always_ff @(posedge clk, posedge reset)  begin
        if(reset)
            inst_addr <= 0;
        else begin
            if(~looped_instruction)
                counter <= 0;
            else
                counter <= counter+1;

            inst_addr <= ((counter==length)||(instruction !== INST_REPEAT)) ? inst_addr+1 : inst_addr;

        end
    end
        

    always_ff @(posedge clk)  begin
        prev_instruction <= instruction;
    end

    wire[$clog2(NU_COUNT)-1:0] mac_addr = inst_data;

    wire move;

    always_comb begin
        if(move) begin
            serializer_update <= 1'b0;
            act_input_select <= 1'b1;
            act_bypass <= 1'bx; //TODO from inst
            act_mask <= 1'bx; //TODO from inst
            xy_write_enable <= 1'b1;
            xy_write_addr <= 'x;
            xy_acc_loopback <= 1'b0; //TODO from inst
            xy_acc_op <= 1'bx; //TODO from inst
        end


        case (instruction)
            INST_MATMUL:  begin
                mac_acc_loopback <= looped_instruction;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;

                serializer_update <= 1'b1;
                act_input_select <= 'x;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;

                xy_write_enable <= 1'b0;
                xy_read_addr <= 'd10;
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'bx;
                xy_acc_op <= 1'bx;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;
            end
            INST_ACCMOV: begin
                mac_acc_loopback <= 1'bx;
                mac_reg_enable <= 0;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 1'b0;
                act_input_select <= 1'b1;
                act_bypass <= 1'bx; //TODO from inst
                act_mask <= 1'bx; //TODO from inst

                xy_write_enable <= 1'b1;
                xy_read_addr <= 'x;
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'b0; //TODO from inst
                xy_acc_op <= 1'bx; //TODO from inst

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;

            end
            INST_LOADMAC: begin
                mac_acc_loopback <= 1'bx;
                mac_reg_enable = 0; mac_reg_enable[mac_addr] = 1;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 'x;
                act_input_select <= 'x;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;
                
                xy_write_enable <= 1'b0;
                xy_read_addr <= 'x;
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'bx;
                xy_acc_op <= 1'bx;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;
            end
            INST_MATMULT: begin
                mac_acc_loopback <= 1'bx;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b0;
                mac_w_select <=  1'b1;

                serializer_update <= 1'bx;
                act_input_select <= 1'b0;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;

                xy_write_enable <= 1'b1;
                xy_read_addr <= 'x;
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'b0; //TODO from inst
                xy_acc_op <= 1'bx; // TODO check

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;
            end
            INST_VECTTOMAT: begin
                mac_acc_loopback <= 1'b0;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b0;
                mac_w_select <=  1'b0;

                serializer_update <= 1'bx;
                act_input_select <= 1'bx;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;

                xy_write_enable <= 1'b0;
                xy_read_addr <= 'x; //TODO from inst
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'bx;
                xy_acc_op <= 1'bx;

                w_write_enable <= 1'b1;
                w_read_addr <= 'x;
                w_write_addr <= 'x; //TODO from inst
            end
            INST_WCONSTPROD: begin // Only differs to the previous by mac selects
                mac_acc_loopback <= 1'b0;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;

                serializer_update <= 1'bx;
                act_input_select <= 1'bx;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;

                xy_write_enable <= 1'b0;
                xy_read_addr <= 'x; //TODO from inst
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'bx;
                xy_acc_op <= 1'bx;

                w_write_enable <= 1'b1;
                w_read_addr <= 'x;
                w_write_addr <= 'x; 
            end
            INST_WACC: begin // Only differs to the previous by mac selects
                mac_acc_loopback <= 1'b1;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;

                serializer_update <= 1'bx;
                act_input_select <= 1'bx;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;

                xy_write_enable <= 1'b0;
                xy_read_addr <= 0; // Address of 1
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'bx;
                xy_acc_op <= 1'bx;

                w_write_enable <= 1'b1;
                w_read_addr <= 'x;
                w_write_addr <= 'x; //TODO from inst
            end
            default: begin
                mac_acc_loopback <= 'x;
                mac_reg_enable <= 0;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 'x;
                act_input_select <= 'x;
                act_bypass <= 1'bx;
                act_mask <= 1'bx;
                
                xy_write_enable <= 1'b0;
                xy_read_addr <= 'x;
                xy_write_addr <= 'x;
                xy_acc_loopback <= 1'bx;
                xy_acc_op <= 1'bx;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;
                
            end
        endcase
    end


    






endmodule


/*
INST_REPEAT: begin               
mac_acc_loopback <= prev_mac_acc_loopback;
mac_reg_enable <= prev_mac_reg_enable;
mac_x_select <= prev_mac_x_select;
mac_w_select <=  prev_mac_w_select;

serializer_update <= prev_serializer_update;
act_input_select <= prev_act_input_select;

xy_write_enable <= prev_xy_write_enable;
xy_read_addr <= prev_xy_read_addr + 1;
xy_write_addr <= prev_xy_write_addr + 1;
xy_acc_loopback <= prev_xy_acc_loopback;
xy_acc_op <= prev_xy_acc_op;

w_write_enable <= prev_w_write_enable;
w_read_addr <= prev_w_read_addr;
w_write_addr <= prev_w_write_addr;

end


prev_mac_acc_loopback <= mac_acc_loopback;
prev_mac_reg_enable <= mac_reg_enable;
prev_mac_x_select <= mac_x_select;
prev_mac_w_select <=  mac_w_select;

prev_serializer_update <= serializer_update;
prev_act_input_select <= act_input_select;

prev_xy_write_enable <= xy_write_enable;
prev_xy_read_addr <= xy_read_addr;
prev_xy_write_addr <= xy_write_addr;
prev_xy_acc_loopback <= xy_acc_loopback; //TODO from inst
prev_xy_acc_op <=xy_acc_op; // TODO check

prev_w_write_enable <= w_write_enable;
prev_w_read_addr <= w_read_addr;
prev_w_write_addr <= w_write_addr;
*/