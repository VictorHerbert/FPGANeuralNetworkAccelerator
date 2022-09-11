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
    assign layer = inst_read_data;

    reg unsigned [INST_MEM_DEPTH-1:0]  inst_read_addr_prev;

    reg [$clog2(NU_COUNT)-1:0] serializer_counter;
    reg [XY_MEM_DEPTH-1:0] x_counter;

    reg write_available;

    assign serializer_shift = 1'b1;    
    assign xy_write_select = 0;


    reg [7:0] y_count;
    reg [7:0] serializer_length;

    wire last_y_batch = y_count + NU_COUNT >= layer.y_length;
    wire remainder_y_batch = layer.y_length%NU_COUNT != 0;

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

                serializer_update <= write_available&(xy_read_addr == layer.x_length);

                if(xy_read_addr == layer.x_length&last_y_batch)
                    inst_read_addr = inst_read_addr_prev+1;
            end
            WAIT: begin
                serializer_update <= write_available;
            end
        endcase
    end

    assign xy_write_enable = ~write_enable

    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            layer_state <= IDLE;
            inst_read_addr_prev <= 'd0;
            write_available <= 1;
        end
        else begin
            if(serializer_update) begin
                serializer_counter <= 1;
                write_available <= 0;
            end
            else begin
                serializer_counter <= serializer_counter+1;
            end

            if (serializer_counter == serializer_length)
                write_available <= 1;

            if((~write_available)|(serializer_counter == NU_COUNT-1))
                xy_write_addr <= xy_write_addr + 1'b1;

            inst_read_addr_prev = inst_read_addr;


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
                    y_count <= 0;
                end
                ACC: begin
                    xy_read_addr <= xy_read_addr + 1'b1;
                    w_read_addr <= w_read_addr + 1'b1;
                    mac_acc_loopback <= 1'b1;

                    if(xy_read_addr == layer.x_length) begin
                        if(last_y_batch) begin
                            layer_state <= START;
                        end
                        else if(~write_available)
                            layer_state <= WAIT;

                        y_count <= y_count + NU_COUNT;

                        serializer_length <= last_y_batch&remainder_y_batch ? layer.y_length%NU_COUNT : NU_COUNT-1;
                        xy_read_addr <= layer.x_offset;
                    end
                end
                WAIT: begin
                    if(write_available)
                        layer_state <= ACC;
                end
            endcase
        end
    end

endmodule


//add wave -radix fx_prod_full nn/prod_full
//add wave -radix fx nn/loopback_sum
//add wave -radix fx nn/sum