import definitions::*;
import isa::*;

module ControllerFSM (
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
    typedef enum reg[2:0] {RESET, INPUT, DECODE, ACC, WAIT, HALT} LayerState;
    Layer layer;
    LayerState layer_state, layer_state_next;

    JumpInst jump_inst;

    assign jump_inst = inst_read_data;



    reg unsigned [INST_MEM_DEPTH-1:0]  inst_read_addr_prev;
    reg [7:0] serializer_counter;

    reg [7:0] batch_count;
    reg [7:0] batch_length;
    reg [7:0] batch_remainder;
    reg [7:0] wait_length;
    reg [NU_COUNT-1:0] xy_write_counter;


    reg [7:0] x_offset, y_offset;
    reg [7:0] x_length, y_length;

    assign layer = inst_read_data;
    assign serializer_shift = 1'b1;
    assign xy_write_select = 0;

    assign wait_length = 0; // TODO

    assign batch_length = layer.y_length/NU_COUNT;
    assign batch_remainder = layer.y_length%NU_COUNT;

    assign xy_write_enable = xy_write_counter != 0;


    always_comb begin
        inst_read_addr = inst_read_addr_prev;
        serializer_update = 0;
        mac_acc_update = 0;


        case(layer_state)
            RESET: begin
            end
            INPUT: begin
                inst_read_addr = inst_read_addr_prev + 1;
            end
            DECODE: begin
                mac_acc_update = 1'b0;
                case(layer.instruction)
                    INST_INPUT: inst_read_addr <= inst_read_addr_prev+1;
                    INST_JUMP: inst_read_addr <= 0;
                endcase
            end
            ACC: begin
                mac_acc_update = 1'b1;

                serializer_update = (xy_read_addr == x_offset+x_length-1)&(wait_length == 0);
                inst_read_addr = (xy_read_addr == x_offset+x_length-1)&(wait_length == 0)&(batch_count == batch_length) ? inst_read_addr_prev + 1 : inst_read_addr_prev;
            end
            WAIT: begin
                serializer_update = (serializer_counter == wait_length); // TODO check
            end
        endcase
    end


    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            xy_write_counter <= 0;
            layer_state <= RESET;
            inst_read_addr_prev <= 'd0;
        end
        else begin
            inst_read_addr_prev <= inst_read_addr;

            case(layer_state)
                RESET: begin
                    layer_state <= DECODE;
                end
                INPUT: begin
                    layer_state <= DECODE;
                    xy_read_addr <= 2;
                    xy_write_addr <= layer.y_length + 2;
                    w_read_addr <= 0;

                    act_mask <= layer.act_mask;
                    y_length <= layer.y_length;
                end
                DECODE: begin
                    case(layer.instruction)
                    INST_INPUT: begin
                        layer_state <= DECODE;
                        xy_read_addr <= 2;
                        xy_write_addr <= layer.y_length + 2;
                        w_read_addr <= 0;

                        act_mask <= layer.act_mask;
                        y_length <= layer.y_length;
                    end
                    INST_LAYER: 
                        layer_state <= ACC;
                    INST_HALT: 
                        layer_state <= HALT;
                    endcase

                    x_length <= y_length;
                    x_offset <= xy_read_addr;
                    y_length <= layer.y_length;
                    act_mask <= layer.act_mask;
                    mac_acc_loopback <= 1'b0;
                    batch_count <= 0;
                end
                ACC: begin
                    xy_read_addr <= xy_read_addr + 1'b1;
                    w_read_addr <= w_read_addr + 1'b1;
                    mac_acc_loopback <= 1'b1;

                    if(xy_read_addr == x_offset+x_length-1) begin
                        batch_count <= batch_count + 1;
                        xy_read_addr <= x_offset;

                        if(wait_length == 0) begin
                            serializer_counter <= 0;
                            if(batch_count == batch_length) begin
                                xy_read_addr <= xy_read_addr + 1'b1;
                                layer_state <= DECODE;
                            end
                        end
                        else
                            layer_state <= WAIT;
                    end
                end
                WAIT: begin

                end
                HALT: begin

                end
            endcase

            if(serializer_update) begin
                xy_write_counter <=
                (batch_count == batch_length) ?
                    ((batch_remainder==0) ? NU_COUNT : batch_remainder) :
                    NU_COUNT;
            end
            else
                if(xy_write_counter != 0)
                    xy_write_counter <= xy_write_counter-1;

            if(xy_write_enable)
                xy_write_addr <= xy_write_addr + 1;
        end
    end

endmodule