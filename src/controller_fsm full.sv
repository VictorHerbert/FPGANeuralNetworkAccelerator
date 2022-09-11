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
    typedef enum reg[2:0] {IDLE, START, ACC, WAIT} LayerState;
    Layer layer;
    LayerState layer_state, layer_state_next;

    reg unsigned [INST_MEM_DEPTH-1:0]  inst_read_addr_prev;
    reg [7:0] serializer_counter;

    reg [7:0] batch_count;
    reg [7:0] batch_length;
    reg [7:0] batch_remainder;
    reg [7:0] wait_length;
    reg [NU_COUNT-1:0] xy_write_counter;

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
            IDLE: begin
            end
            START: begin
                mac_acc_update = 1'b0;
            end
            ACC: begin
                mac_acc_update = 1'b1;

                serializer_update = (xy_read_addr == layer.x_end)&(wait_length == 0);
                inst_read_addr = (xy_read_addr == layer.x_end)&(wait_length == 0)&(batch_count == batch_length) ? inst_read_addr_prev + 1 : inst_read_addr_prev;
            end
            WAIT: begin
                serializer_update = (serializer_counter == wait_length);
            end
        endcase
    end


    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            xy_write_counter <= 0;
            layer_state <= IDLE;
            inst_read_addr_prev <= 'd0;
        end
        else begin
            inst_read_addr_prev <= inst_read_addr;
            case(layer_state)
                IDLE: begin
                    layer_state <= START;
                end
                START: begin
                    layer_state <= ACC;
                    xy_read_addr <= layer.x_offset;
                    w_read_addr <= layer.w_offset;
                    xy_write_addr <= layer.y_offset;
                    mac_acc_loopback <= 1'b0;
                    act_mask <= layer.act_mask;

                    batch_count <= 0;
                end
                ACC: begin
                    xy_read_addr <= xy_read_addr + 1'b1;
                    w_read_addr <= w_read_addr + 1'b1;
                    mac_acc_loopback <= 1'b1;

                    if(xy_read_addr == layer.x_end) begin
                        batch_count <= batch_count + 1; 
                        xy_read_addr <= layer.x_offset;

                        if(wait_length == 0) begin
                            serializer_counter <= 0;
                            if(batch_count == batch_length) begin
                                // FOR SIMULATION
                                xy_read_addr <= 'x;
                                w_read_addr <= 'x;
                                mac_acc_loopback <= 1'b0;

                                layer_state <= START;
                            end
                        end
                        else
                            layer_state <= WAIT;      
                    end
                end
                WAIT: begin

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