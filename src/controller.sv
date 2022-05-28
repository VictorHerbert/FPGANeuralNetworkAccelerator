import definitions::*;
import isa::*;

module Controller (
    input clk, reset,

    input mm_write_enable,
    input mm_read_enable,
    input [MM_LENGTH-1:0] mm_addr,
    input [MM_SIZE-1:0] mm_write_data,
    output reg [MM_SIZE-1:0] mm_read_data,

    input buffer_empty,
    output buffer_read_enable,
    input [Q_SIZE-1:0] buffer_data_out,

    output reg inst_write_enable,
    input  reg [INST_MEM_SIZE-1:0] inst_read_data,
    output reg [INST_MEM_SIZE-1:0] inst_write_data,
    output reg [INST_MEM_DEPTH-1:0] inst_read_addr,
    output reg [INST_MEM_SIZE-1:0] inst_write_addr,

    output reg mac_acc_loopback,
    output reg mac_acc_update,

    output reg serializer_update,
    output reg serializer_shift,

    output reg act_write_enable,
    output reg [ACT_MASK_SIZE-1:0] act_mask,
    output reg [ACT_LUT_DEPTH-1:0] act_addr,
    output reg [ACT_LUT_SIZE-1:0] act_write_data,
    input reg [Q_SIZE-1:0] act_read_data,

    output reg [XY_MEM_DEPTH-1:0] xy_read_addr,
    output reg [XY_MEM_DEPTH-1:0] xy_write_addr,
    input  reg [Q_SIZE-1:0] xy_read_data,
    output reg [Q_SIZE-1:0] xy_write_data,
    output reg xy_write_enable,

    output reg [W_MEM_DEPTH-1:0] w_addr,
    output reg [NU_COUNT-1:0] w_write_enable,
    input  reg [NU_COUNT-1:0][Q_SIZE-1:0] w_read_data,
    output reg [NU_COUNT-1:0][Q_SIZE-1:0] w_write_data
);

    GenericInstPacket generic_inst_packet;
    MatmulInstPacket matmul_inst_packet;
    AccmovInstPacket accmov_inst_packet;
    JmpInstPacket jump_inst_packet;
    RepeatInstPacket repeat_inst_packet;
    FlushbufferInstPacket flushbuffer_inst_packet;

    InstructionType instruction;
    InstructionType prev_instruction;


    reg accmov_enable;
    reg repeat_enable;

    reg [INST_MEM_DEPTH-1:0] inst_read_addr_next;
    reg [REPEAT_LENGTH-1:0] repeat_counter, repeat_counter_reg;
    reg [NU_COUNT-1:0] accmov_counter, accmov_length, accmov_length_reg;

    reg [ACT_MASK_SIZE-1:0] act_mask_reg;

    reg [XY_MEM_DEPTH-1:0] prev_xy_read_addr;
    reg [W_MEM_DEPTH-1:0] prev_w_addr;

    reg [XY_MEM_DEPTH-1:0] xy_write_addr_reg;

    assign generic_inst_packet = inst_read_data;
    assign instruction = generic_inst_packet.mnemonic;

    assign matmul_inst_packet = (instruction==INST_MATMUL) ? inst_read_data : 'x;
    assign accmov_inst_packet = (instruction==INST_ACCMOV) ? inst_read_data : 'x;
    assign jump_inst_packet = (instruction==INST_JUMP) ? inst_read_data : 'x;
    assign repeat_inst_packet = (instruction==INST_REPEAT) ? inst_read_data : 'x;
    assign flushbuffer_inst_packet = (instruction==INST_FLUSHBUFFER) ? inst_read_data : 'x;

    always_ff @(posedge clk, posedge reset)  begin
        if(reset)   inst_read_addr <= 0;
        else        inst_read_addr <= inst_read_addr_next;
    end

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            accmov_counter <= 0;
            accmov_length_reg <= 0;
            repeat_counter <= 0;
        end
        else begin
            accmov_length_reg <= accmov_length;

            case({
                instruction==INST_REPEAT,
                repeat_counter == repeat_inst_packet.length
            })
                2'b00: repeat_counter <= 0;
                2'b01: repeat_counter <= 'x;
                2'b10: repeat_counter <= repeat_counter+1;
                2'b11: repeat_counter <= 0;
            endcase

            case({
                accmov_counter == accmov_length,
                instruction == INST_ACCMOV,
                accmov_counter == 0
            })
                3'b000: accmov_counter <= accmov_counter+1;
                3'b001: accmov_counter <= 0;
                3'b010: accmov_counter <= accmov_counter+1;
                3'b011: accmov_counter <= accmov_counter+1;
                3'b100: accmov_counter <= 0;
                3'b101: accmov_counter <= 0;
                3'b110: accmov_counter <= 'x;
                3'b111: accmov_counter <= 0;
            endcase

            act_mask_reg <= (instruction==INST_ACCMOV) ? act_mask : act_mask_reg;

            xy_write_addr_reg <= xy_write_addr+1;
        end


    end

    always_ff @(posedge clk) begin
        prev_instruction <= instruction;
        prev_xy_read_addr <= xy_read_addr;
        prev_w_addr <= w_addr;
    end

    always_comb begin
        mac_acc_loopback = 'x;
        mac_acc_update = 'x;
        serializer_update = 0;
        xy_write_enable = (instruction==INST_ACCMOV)|(accmov_counter != 0);
        xy_read_addr = 'x;
        xy_write_addr = xy_write_addr_reg;

        w_addr = 'x;       
        serializer_shift <= xy_write_enable;
        accmov_length = accmov_length_reg;
        act_mask = act_mask_reg;

        inst_read_addr_next = inst_read_addr+1;

        xy_write_data = act_read_data;

        casez (instruction)
            INST_MATMUL:  begin
                mac_acc_loopback = 1'b0;
                mac_acc_update = 1'b1;
                serializer_update = 1'b0;
                xy_read_addr = matmul_inst_packet.x_addr;
                w_addr = matmul_inst_packet.w_addr;
            end
            INST_ACCMOV: begin
                serializer_update = 1'b1;
                accmov_enable = 1'b1;
                xy_write_addr = accmov_inst_packet.y_addr;
                accmov_length = accmov_inst_packet.length;

                act_mask = accmov_inst_packet.act_mask;
            end
            INST_JUMP: begin
                inst_read_addr_next = jump_inst_packet.inst_addr;
            end
            INST_REPEAT: begin
                mac_acc_loopback = 1'b1;
                mac_acc_update = 1'b1;
                serializer_update = 1'b0;
                xy_read_addr = prev_xy_read_addr+1;
                w_addr = prev_w_addr+1;

                inst_read_addr_next = (repeat_counter == repeat_inst_packet.length) ?
                    inst_read_addr + 1 : inst_read_addr;
            end
            INST_FLUSHBUFFER: begin
                inst_read_addr_next = buffer_empty ? inst_read_addr+1 : inst_read_addr;
            end
        endcase
    end

endmodule