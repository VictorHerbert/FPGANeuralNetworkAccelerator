import definitions::*;
import isa::*;

module Controller (
    input clk, reset,

    //input [INST_MEM_SIZE-1:0]
    input reg [INST_MEM_SIZE-1:0] inst_data,
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

    GenericInstPacket generic_inst_packet;
    MatmulInstPacket matmul_inst_packet;
    LoadmacInstPacket loadmac_inst_packet;
    AccmovInstPacket accmov_inst_packet;
    MatmultInstPacket matmult_inst_packet;
    VecttomatInstPacket vecttomat_inst_packet;
    WconstprodInstPacket wconstprod_inst_packet;
    WaccInstPacket wacc_inst_packet;
    JmpInstPacket jump_inst_packet;
    RepeatInstPacket repeat_inst_packet;

    InstructionType instruction;
    InstructionType prev_instruction;
    InstructionType next_instruction;

    wire[$clog2(NU_COUNT)-1:0] mac_addr;

    reg looped_instruction;
    assign looped_instruction = (instruction == prev_instruction);

    reg [REPEAT_LENGTH-1:0] repeat_counter, reg_repeat_counter;

    reg [MOV_LENGTH-1:0] mov_counter;
    reg [MOV_LENGTH-1:0] mov_length, reg_mov_length;
    reg mov_update;

    reg [INST_MEM_DEPTH-1:0] inst_addr_next;

    reg prev_mac_acc_loopback;
    reg prev_mac_acc_update;
    reg [NU_COUNT-1:0] prev_mac_reg_enable;
    reg prev_mac_x_select;
    reg prev_mac_w_select;
    reg prev_serializer_update;
    reg [XY_MEM_DEPTH-1:0] prev_xy_read_addr; // Address of 1
    reg prev_w_write_enable;
    reg [W_MEM_DEPTH-1:0] prev_w_read_addr;
    reg [W_MEM_DEPTH-1:0] prev_w_write_addr;

    reg prev_repeat_update;

    reg jump, repeat_update;

    assign instruction = generic_inst_packet.mnemonic;
    assign generic_inst_packet = inst_data;
    assign matmul_inst_packet = (instruction==INST_MATMUL) ? inst_data : 'x;
    assign loadmac_inst_packet = (instruction==INST_LOADMAC) ? inst_data : 'x;
    assign accmov_inst_packet = (instruction==INST_ACCMOV) ? inst_data : 'x;
    assign matmult_inst_packet = (instruction==INST_MATMULT) ? inst_data : 'x;
    assign vecttomat_inst_packet = (instruction==INST_VECTTOMAT) ? inst_data : 'x;
    assign wconstprod_inst_packet = (instruction==INST_WCONSTPROD) ? inst_data : 'x;
    assign wacc_inst_packet = (instruction==INST_WACC) ? inst_data : 'x;
    assign jump_inst_packet = (instruction==INST_JUMP) ? inst_data : 'x;
    assign repeat_inst_packet = (instruction==INST_REPEAT) ? inst_data : 'x;

    always_ff @(posedge clk)  begin
        prev_instruction <= instruction;

        prev_mac_acc_loopback <= mac_acc_loopback;
        prev_mac_acc_update <= mac_acc_update;
        prev_mac_reg_enable <= mac_reg_enable;
        prev_mac_x_select <= mac_x_select;
        prev_mac_w_select <= mac_w_select;

        prev_serializer_update <= serializer_update;
        prev_xy_read_addr <= xy_read_addr;

        prev_w_write_enable <= w_write_enable;
        prev_w_read_addr <= w_read_addr;
        prev_w_write_addr <= w_write_addr;

        prev_repeat_update <= repeat_update;
    end

    always_ff @(posedge clk, posedge reset)  begin
        if(reset)   inst_addr <= 0;
        else        inst_addr <= inst_addr_next;
    end

    always_ff @(posedge clk) begin
        if(~looped_instruction)
            reg_repeat_counter <= 2;
        else
            reg_repeat_counter <= reg_repeat_counter+1;
    end

    assign repeat_counter = looped_instruction ? reg_repeat_counter : 1;



    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            mov_counter <= 0;
        end
        else begin
            if(mov_update) begin
                xy_write_addr <= accmov_inst_packet.y_addr;
                mov_counter <= accmov_inst_packet.length;
                act_bypass <= accmov_inst_packet.bypass;
                act_mask <= accmov_inst_packet.act_mask;
                act_input_select <= accmov_inst_packet.input_select;
                xy_acc_loopback <= accmov_inst_packet.loopback;
                xy_acc_op <= accmov_inst_packet.operation;
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
                xy_read_addr <= matmul_inst_packet.x_addr;

                w_write_enable <= 1'b0;
                w_read_addr <= matmul_inst_packet.w_addr;
                w_write_addr <= 'x;

                mov_update <= 1'b0;

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
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

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
            end
            INST_LOADMAC: begin
                mac_acc_loopback <= 1'bx;
                mac_acc_update <= 1'b0;
                mac_reg_enable = 0; mac_reg_enable[loadmac_inst_packet.mac_addr] = 1;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 1'b0;
                xy_read_addr <= loadmac_inst_packet.x_addr;

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;

                mov_update <= 1'b0;

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
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
                w_read_addr <= matmult_inst_packet.w_addr;
                w_write_addr <= 'x;

                mov_update <= 1'b0;

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
            end
            INST_VECTTOMAT: begin
                mac_acc_loopback <= 1'b0;
                mac_acc_update <= 1'b1;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b0;
                mac_w_select <=  1'b0;

                serializer_update <= 1'b0;
                xy_read_addr <= vecttomat_inst_packet.x_addr;

                w_write_enable <= 1'b1;
                w_read_addr <= 'x;
                w_write_addr <= vecttomat_inst_packet.w_addr;

                mov_update <= 1'b0;

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
            end
            INST_WCONSTPROD: begin // Only differs to the previous by mac selects
                mac_acc_loopback <= 1'b0;
                mac_acc_update <= 1'b1;
                mac_reg_enable <= 0;
                mac_x_select <= 1'b1;
                mac_w_select <=  1'b1;

                serializer_update <= 1'b0;
                xy_read_addr <= wconstprod_inst_packet.x_addr;

                w_write_enable <= 1'b0;
                w_read_addr <= wconstprod_inst_packet.w_addr;
                w_write_addr <= 'x;

                mov_update <= 1'b0;

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
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
                w_read_addr <= wacc_inst_packet.w_r_addr;
                w_write_addr <= wacc_inst_packet.w_w_addr;

                mov_update <= 1'b0;

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
            end
            INST_JUMP: begin // Only differs to the previous by mac selects
                mac_acc_loopback <= 1'bx;
                mac_acc_update <= 1'bx;
                mac_reg_enable <= 0;
                mac_x_select <= 1'bx;
                mac_w_select <=  1'bx;

                serializer_update <= 1'b0;
                xy_read_addr <= 'x; // Address of 1

                w_write_enable <= 1'b0;
                w_read_addr <= 'x;
                w_write_addr <= 'x;

                mov_update <= 1'b0;

                inst_addr_next <= jump_inst_packet.inst_addr;

                repeat_update <= 1'b0;
            end
            INST_REPEAT: begin
                mac_acc_loopback <= prev_mac_acc_loopback;
                mac_acc_update <= prev_mac_acc_update;
                mac_reg_enable <= prev_mac_reg_enable;
                mac_x_select <= prev_mac_x_select;
                mac_w_select <= prev_mac_w_select;

                serializer_update <= prev_serializer_update;
                xy_read_addr <= prev_xy_read_addr+1;

                w_write_enable <= prev_w_write_enable;
                w_read_addr <= prev_w_read_addr+1;
                w_write_addr <= prev_w_write_addr+1;

                mov_update <= 1'b0;

                inst_addr_next <= (repeat_counter == repeat_inst_packet.length) ? inst_addr+1 : inst_addr;

                repeat_update <= 1'b1;
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

                inst_addr_next <= inst_addr+1;

                repeat_update <= 1'b0;
            end
        endcase
    end









endmodule
