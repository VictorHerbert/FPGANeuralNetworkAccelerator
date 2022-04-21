import definitions::*;
import isa::*;

module Controller (
    input clk, reset,

    //input [INST_MEM_SIZE-1:0] 
    input InstPacket inst_data,
    output reg [INST_MEM_DEPTH-1:0] inst_addr,
    output [INST_MEM_SIZE-1:0] inst_write_addr,
    output  inst_write_enable,

    output reg [NU_COUNT-1:0] mac_reg_enable,
    output reg mac_acc_loopback,
    output reg mac_x_select,
    output reg mac_w_select,
    output reg mac_acc_update,

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
    InstructionType instruction;
    InstructionType prev_instruction;
    InstructionType next_instruction;

    wire[$clog2(NU_COUNT)-1:0] mac_addr;

    reg looped_instruction;
    assign looped_instruction = (instruction == prev_instruction);

    reg [LENGTH_DEPTH-1:0] mov_counter;
    reg [LENGTH_DEPTH-1:0] mov_length, reg_mov_length;
    reg mov_update;

    assign instruction = inst_data.generic_inst_packet.mnemonic;

    always_ff @(posedge clk)  begin
        prev_instruction <= instruction;
    end    

    always_ff @(posedge clk, posedge reset)  begin
        if(reset)
            inst_addr <= 0;
        else
            inst_addr <= inst_addr+1;
    end

    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            mov_counter <= 0;
        end
        else begin
            if(mov_update) begin
                xy_write_addr <= inst_data.accmov_inst_packet.y_addr;
                mov_counter <= inst_data.accmov_inst_packet.length;
                act_bypass <= inst_data.accmov_inst_packet.bypass;
                act_mask <= inst_data.accmov_inst_packet.act_mask;
                act_input_select <= inst_data.accmov_inst_packet.input_select;
                xy_acc_loopback <= inst_data.accmov_inst_packet.loopback;
                xy_acc_op <= inst_data.accmov_inst_packet.operation;
                
            end
            else begin
                xy_write_addr <= xy_write_addr+1;
                if (mov_counter != 0)
                    mov_counter <= mov_counter-1;
            end
            
        end
    end
    assign xy_write_enable = (mov_counter != 0);


    always_comb begin
        case (instruction)
            INST_MATMUL:  begin
                mac_acc_loopback <= looped_instruction; // TODO from inst
                mac_acc_update <= 1'b1; // TODO from inst
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;

                serializer_update <= 1'b0;
                xy_read_addr <= inst_data.matmul_inst_packet.x_addr;
                
                w_write_enable <= 1'b0;
                w_read_addr <= inst_data.matmul_inst_packet.w_addr;
                w_write_addr <= 'x;

                mov_update <= 1'b0;
            end
            INST_ACCMOV: begin
                mac_acc_loopback <= 1'bx;
                mac_acc_update <= 1'b0;
                mac_reg_enable <= 0;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 1'b1;
                xy_read_addr <= 'x;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;

                mov_update <= 1'b1;
            end
            INST_LOADMAC: begin
                mac_acc_loopback <= 1'bx;
                mac_acc_update <= 1'b0;
                mac_reg_enable = 0; mac_reg_enable[inst_data.loadmac_inst_packet.mac_addr] = 1;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 1'b0;
                xy_read_addr <= inst_data.loadmac_inst_packet.x_addr;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;

                mov_update <= 1'b0;
            end
            INST_MATMULT: begin
                mac_acc_loopback <= looped_instruction;
                mac_acc_update <= 1'b1;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b0;
                mac_w_select <=  1'b1;
                
                serializer_update <= 1'b0;
                xy_read_addr <= 'x;

                w_write_enable <= 1'b0;
                w_read_addr <= inst_data.matmult_inst_packet.w_addr;
                w_write_addr <= 'x;

                mov_update <= 1'b0;
            end
            INST_VECTTOMAT: begin
                mac_acc_loopback <= 1'b0;
                mac_acc_update <= 1'b1;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b0;
                mac_w_select <=  1'b0;
                
                serializer_update <= 1'b0;
                xy_read_addr <= inst_data.vecttomat_inst_packet.x_addr;

                w_write_enable <= 1'b1;
                w_read_addr <= 'x;
                w_write_addr <= inst_data.vecttomat_inst_packet.w_addr;

                mov_update <= 1'b0;
            end
            INST_WCONSTPROD: begin // Only differs to the previous by mac selects
                mac_acc_loopback <= 1'b0;
                mac_acc_update <= 1'b1;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;

                serializer_update <= 1'b0;
                xy_read_addr <= inst_data.wconstprod_inst_packet.x_addr;

                w_write_enable <= 1'b0;
                w_read_addr <= inst_data.wconstprod_inst_packet.w_addr;
                w_write_addr <= 'x;

                mov_update <= 1'b0;
            end
            INST_WACC: begin // Only differs to the previous by mac selects
                mac_acc_loopback <= 1'b1;
                mac_acc_update <= 1'b0;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;
                
                serializer_update <= 1'b0;
                xy_read_addr <= 0; // Address of 1

                w_write_enable <= 1'b0;
                w_read_addr <= inst_data.wacc_inst_packet.w_r_addr;
                w_write_addr <= inst_data.wacc_inst_packet.w_w_addr;

                mov_update <= 1'b0;
            end
            default: begin
                mac_acc_loopback <= 'x;
                mac_acc_update <= 1'b0;
                mac_reg_enable <= 0;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 1'b0;
                xy_read_addr <= 'x;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;
                
                mov_update <= 1'b0;
                
            end
        endcase
    end


    






endmodule
