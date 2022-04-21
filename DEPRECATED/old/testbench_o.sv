`timescale 1 ns / 1 ps
//`include "../definitions.sv"

import definitions::*;

module testbench;
    parameter CLK_PERIOD = 10;
    parameter CLK_HALF_PERIOD = CLK_PERIOD/2;

    logic clk = 1, reset = 0;

    initial repeat(200) #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(CLK_HALF_PERIOD) reset = 0; end

    NeuralNetwork nn(
        .clk(clk), .reset(reset)
    );

    wire [NU_COUNT-1:0][Q_SIZE-1:0] mac_reg = {
        nn.mac_gen[3].mac_unit.mac_reg,
        nn.mac_gen[2].mac_unit.mac_reg,
        nn.mac_gen[1].mac_unit.mac_reg,
        nn.mac_gen[0].mac_unit.mac_reg
    };

    task matmul(reg[XY_MEM_DEPTH-1:0] x_addr, reg[XY_MEM_DEPTH-1:0]  y_addr, reg[W_MEM_DEPTH-1:0] w_addr, reg[LENGTH_DEPTH-1:0] length0, reg[LENGTH_DEPTH-1:0] length1);
    begin
        force nn.controller.instruction = INST_FORWARD;
        force nn.controller.length0 = length0;
        force nn.controller.length1 = length1;
        force nn.w_read_addr = w_addr;
        force nn.xy_read_addr = x_addr;
        force nn.xy_write_addr = y_addr;
        

        repeat(length0+length1) @(posedge clk);
        release nn.controller.instruction;
        release nn.controller.length0;
        release nn.controller.length1;
        release nn.w_read_addr;
        release nn.xy_read_addr;
        release nn.xy_write_addr;

        
    end
    endtask


    task halt();
    begin
        force nn.controller.instruction = INST_HALT;

        @(posedge clk)
        release nn.controller.instruction;
    end
    endtask


    

    initial begin
        
        matmul(2,0,12,4,2);

        halt();        
    end

endmodule
