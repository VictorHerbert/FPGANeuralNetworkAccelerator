import definitions::*;
import isa::*;

module Controller (
    input clk, reset,

    input buffer_empty,
    input [BUFFER_LENGTH-1:0] buffer_addr,
    output buffer_read_enable,

    output reg inst_write_enable,
    output reg unsigned [INST_MEM_DEPTH-1:0] inst_read_addr,
    input  reg [INST_MEM_SIZE-1:0] inst_read_data,
    
    output reg mac_acc_loopback,
    output reg mac_acc_update,

    output reg serializer_update,
    output reg serializer_shift,

    output reg act_write_enable,
    output reg [ACT_MASK_SIZE-1:0] act_mask,

    output reg mm_xy_write_enable,
    output reg xy_write_enable,
    output reg xy_write_select,
    output reg [XY_MEM_DEPTH:0] xy_read_addr,
    output reg [XY_MEM_DEPTH:0] xy_write_addr,

    output reg [NU_COUNT-1:0] w_write_enable,
    output reg [W_MEM_DEPTH-1:0] w_read_addr
);
    GenericInstPacket generic_inst_packet;
    MatmulInstPacket matmul_inst_packet;
    AccmovInstPacket accmov_inst_packet;
    JmpInstPacket jump_inst_packet;
    RepeatInstPacket repeat_inst_packet;
    FlushbufferInstPacket flushbuffer_inst_packet;

    InstructionType instruction;

    reg repeat_enable;
    reg cpu_xy_write_enable;

    reg unsigned [INST_MEM_DEPTH-1:0]  inst_read_addr_prev;
    reg unsigned [INST_MEM_DEPTH-1:0]  inst_read_addr_next;
    reg [REPEAT_LENGTH-1:0] repeat_counter, repeat_counter_reg;
    reg [$clog2(NU_COUNT)-1:0] accmov_counter, accmov_length, accmov_length_reg;

    reg [ACT_MASK_SIZE-1:0] act_mask_reg;

    reg [XY_MEM_DEPTH:0] prev_xy_read_addr;
    reg [W_MEM_DEPTH-1:0] prev_w_read_addr;

    reg [XY_MEM_DEPTH:0] xy_write_addr_reg;

    assign generic_inst_packet = inst_read_data;
    assign instruction = generic_inst_packet.mnemonic;

    assign matmul_inst_packet = (instruction==INST_MATMUL) ? inst_read_data : 'x;
    assign accmov_inst_packet = (instruction==INST_ACCMOV) ? inst_read_data : 'x;
    assign jump_inst_packet = (instruction==INST_JUMP) ? inst_read_data : 'x;
    assign repeat_inst_packet = (instruction==INST_REPEAT) ? inst_read_data : 'x;
    assign flushbuffer_inst_packet = (instruction==INST_FLUSHBUFFER) ? inst_read_data : 'x;

    always_ff @(posedge clk, posedge reset)  begin
        if(reset)   inst_read_addr_prev <= 'd0;
        else        inst_read_addr_prev <= inst_read_addr;
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
                2'b00: repeat_counter <= 'd0;
                2'b01: repeat_counter <= 'x;
                2'b10: repeat_counter <= repeat_counter + 1'd1;
                2'b11: repeat_counter <= 'd0;
            endcase

            case({
                accmov_counter == accmov_length,
                instruction == INST_ACCMOV,
                accmov_counter == 0
            })
                3'b000: accmov_counter <= accmov_counter + 1'd1;
                3'b001: accmov_counter <= 'd0;
                3'b010: accmov_counter <= accmov_counter + 1'd1;
                3'b011: accmov_counter <= accmov_counter + 1'd1;
                3'b100: accmov_counter <= 'd0;
                3'b101: accmov_counter <= 'd0;
                3'b110: accmov_counter <= 'x;
                3'b111: accmov_counter <= 'd0;
            endcase

            act_mask_reg <= (instruction==INST_ACCMOV) ? act_mask : act_mask_reg;

            xy_write_addr_reg <= xy_write_addr + 1'd1;
        end


    end

    always_ff @(posedge clk) begin
        prev_xy_read_addr <= xy_read_addr;
        prev_w_read_addr <= w_read_addr;
    end

    assign inst_write_enable = ~buffer_addr[MEM_DEPTH+4]&buffer_addr[MEM_DEPTH];
    assign act_write_enable = ~buffer_addr[MEM_DEPTH+4]&buffer_addr[MEM_DEPTH+1];
    assign mm_xy_write_enable = ~buffer_addr[MEM_DEPTH+4]&buffer_addr[MEM_DEPTH+2]; // check for use
    assign w_write_enable = {4{buffer_addr[MEM_DEPTH+4]}}&buffer_addr[MEM_DEPTH+3:MEM_DEPTH];

    reg update_buffer, update_buffer_reg;

    always_ff @(posedge clk, posedge reset) begin
        if(reset)
            update_buffer_reg <= 1'b1;
        else begin
            if(buffer_read_enable)
                update_buffer_reg <= 1'b0;
            else if(inst_write_enable|act_write_enable|xy_write_select|(|w_write_enable))
                update_buffer_reg <= 1'b1;
        end
    end

    assign update_buffer =
        inst_write_enable|act_write_enable|xy_write_select|(|w_write_enable)|update_buffer_reg;

    assign xy_write_select = mm_xy_write_enable&(~cpu_xy_write_enable);
    assign xy_write_enable = cpu_xy_write_enable|xy_write_select;

    assign buffer_read_enable = ~buffer_empty&update_buffer;

    always_comb begin
        mac_acc_loopback = 'x;
        mac_acc_update = 'x;
        serializer_update = 'd0;
        cpu_xy_write_enable = (instruction==INST_ACCMOV)|(accmov_counter != 'd0);
        xy_read_addr = 'x;
        xy_write_addr = xy_write_select ? buffer_addr[XY_MEM_DEPTH:0] : xy_write_addr_reg;

        w_read_addr = 'x;       
        serializer_shift <= cpu_xy_write_enable;
        accmov_length = accmov_length_reg;
        act_mask = act_mask_reg;

        inst_read_addr = inst_read_addr_prev + 1'd1;

        casez (instruction)
            INST_MATMUL:  begin
                mac_acc_loopback = 1'b0;
                mac_acc_update = 1'b1;
                serializer_update = 1'b0;
                xy_read_addr = matmul_inst_packet.x_addr;
                w_read_addr = matmul_inst_packet.w_addr;
            end
            INST_ACCMOV: begin
                serializer_update = 1'b1;
                xy_write_addr = accmov_inst_packet.y_addr;
                accmov_length = accmov_inst_packet.length[$clog2(NU_COUNT)-1:0];

                act_mask = accmov_inst_packet.act_mask;
            end
            INST_JUMP: begin
                inst_read_addr = jump_inst_packet.inst_addr;
            end
            INST_REPEAT: begin
                mac_acc_loopback = 1'b1;
                mac_acc_update = 1'b1;
                serializer_update = 1'b0;
                xy_read_addr = prev_xy_read_addr + 1'd1;
                w_read_addr = prev_w_read_addr + 1'd1;

                inst_read_addr = (repeat_counter == repeat_inst_packet.length) ?
                    inst_read_addr_prev + 1'd1 : inst_read_addr_prev;
            end
            INST_FLUSHBUFFER: begin
                // TODO
                inst_read_addr = buffer_empty ? (inst_read_addr_prev + 1'd1) : inst_read_addr_prev;
            end
            default: begin
            end
        endcase
    end

endmodule