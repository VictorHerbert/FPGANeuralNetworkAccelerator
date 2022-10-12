import definitions::*;
import isa::*;

module ControllerFSM (
    input clk, reset,

    input Status status,

    output reg                                  inst_write_enable,
    output reg [INST_MEM_DEPTH-1:0]             inst_read_addr,
    input  reg [INST_MEM_SIZE-1:0]              inst_read_data,

    output reg                                  mac_acc_loopback,
    output reg                                  mac_acc_update,

    output reg                                  serializer_update,
    output reg                                  serializer_shift,

    output reg [ACT_MASK_SIZE-1:0]              act_mask,

    output reg                                  xy_write_enable,
    output reg                                  xy_output_write_select,
    output reg [XY_MEM_DEPTH-1:0]               xy_read_addr,
    output reg [XY_MEM_DEPTH-1:0]               xy_write_addr,

    output reg [NU_COUNT-1:0]                   w_write_enable,
    output reg [W_MEM_DEPTH-1:0]                w_read_addr
);
    typedef enum reg[2:0] {RESET, START, ACC, WAIT} LayerState;
    LayerState layer_state, layer_state_next;
    Layer layer;

    reg unsigned [INST_MEM_DEPTH-1:0]  inst_read_addr_prev;
    logic end_of_batch, last_batch, xy_write_addr_updated;
    reg [7:0] batch_count;
    reg [7:0] batch_length;
    reg [7:0] batch_remainder;
    reg [$clog2(NU_COUNT)+1:0] xy_write_counter;

    assign layer = inst_read_data;
    assign instruction = inst_read_data;

    assign serializer_shift = 1'b1;
    assign batch_length = layer.y_length/NU_COUNT;
    assign batch_remainder = layer.y_length%NU_COUNT;
    assign end_of_batch = (xy_read_addr == layer.x_offset+layer.x_length-1);
    assign last_batch = (batch_count == 1);

    assign xy_write_enable = xy_write_counter != 0;

    reg [ACT_MASK_SIZE-1:0] act_mask_prev;

    always_comb begin
        inst_read_addr = inst_read_addr_prev;
        serializer_update = 0;
        mac_acc_update = 0;
        mac_acc_loopback = 1'bx;


    
        case(layer_state)
            RESET: begin
                //TODO fix start addr
                inst_read_addr = 0;
            end
            START: begin
                mac_acc_update = 1'b0;
            end
            ACC: begin
                mac_acc_update = 1;
                mac_acc_loopback = (xy_read_addr != layer.x_offset);
                serializer_update = end_of_batch&(xy_write_counter <= 1);
                inst_read_addr = end_of_batch&last_batch&(xy_write_counter <= 1) ? inst_read_addr_prev + 1 : inst_read_addr_prev;
            end
            WAIT: begin
                mac_acc_update = 1'b0;
                mac_acc_loopback = 1'b1;
                serializer_update = (xy_write_counter <= 1);
                inst_read_addr = (xy_write_counter <= 1)&last_batch ? inst_read_addr_prev + 1 : inst_read_addr_prev;
            end
        endcase
   

    end

    always_ff @(posedge clk, posedge reset)  begin
        if(reset) begin
            inst_read_addr_prev <= 'd0;
            xy_write_counter <= 0;
            xy_write_addr_updated <= 0;
            layer_state <= RESET;
        end
        else begin
            inst_read_addr_prev <= inst_read_addr;

            if(xy_write_counter <= 1 & ~xy_write_addr_updated) begin
                xy_write_addr_updated <= 1;
                xy_write_addr <= layer.y_offset;
                xy_output_write_select <= layer.output_layer;
                act_mask <= layer.act_mask;
            end
            else if(xy_write_counter != 0)
                xy_write_addr <= xy_write_addr + 1;

            case(layer_state)
                RESET: begin
                    layer_state <= status.run ? START : RESET;
                end
                START: begin
                    xy_read_addr <= layer.x_offset;
                    w_read_addr <= layer.w_offset;
                    batch_count <= batch_length + (batch_remainder != 0);
                    xy_write_addr_updated <= 0;


                    layer_state <= ACC;
                end
                ACC: begin
                    xy_read_addr <= xy_read_addr + 1'b1;
                    w_read_addr <= w_read_addr + 1'b1;

                    if(end_of_batch) begin

                        xy_read_addr <= layer.x_offset;

                        if(xy_write_counter <= 1) begin
                            batch_count <= batch_count - 1;

                            if(last_batch) begin
                                // To help in simulation
                                xy_read_addr <= 'x;
                                w_read_addr <= 'x;
                                batch_count <= 'x;

                                layer_state <= layer.reset ? RESET : START;
                            end
                        end
                        else begin
                            layer_state <= WAIT;
                        end
                    end
                end
                WAIT: begin
                    if(xy_write_counter <= 1) begin
                        batch_count <= batch_count - 1;

                        if(last_batch) begin
                            // To help in simulation
                            xy_read_addr <= 'x;
                            w_read_addr <= 'x;
                            batch_count <= 'x;

                            layer_state <= layer.reset ? RESET : START;
                        end
                        else begin
                            xy_read_addr <= layer.x_offset;
                            layer_state <= ACC;
                        end
                    end
                end
            endcase
                

            if(serializer_update) begin
                xy_write_counter <=
                    (batch_count == 1) ?
                        ((batch_remainder==0) ? NU_COUNT : batch_remainder) :
                        NU_COUNT;
            end
            else if(xy_write_counter != 0)
                xy_write_counter <= xy_write_counter-1;



        end
    end

endmodule