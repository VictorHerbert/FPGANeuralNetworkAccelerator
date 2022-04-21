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

    task matmul(reg[15:0] x_addr, reg[15:0] w_addr, reg serializer_update);
    begin
        force nn.controller.instruction = INST_MATMUL;
        force nn.controller.serializer_update = serializer_update;
        force nn.w_read_addr = w_addr;
        force nn.xy_read_addr = x_addr;

        @(posedge clk)
        release nn.controller.instruction;
        release nn.controller.serializer_update;
        release nn.w_read_addr;
        release nn.xy_read_addr;
    end
    endtask

    task acc_mov(reg[15:0] y_addr, reg[LENGTH_DEPTH-1:0] length, bypass, mask, loopback, operation);
    begin
        force nn.controller.instruction = INST_ACCMOV;
        force nn.controller.mov_length = length;
        force nn.controller.act_bypass = bypass;
        force nn.controller.act_mask = mask;
        force nn.controller.xy_acc_loopback = loopback;
        force nn.controller.xy_acc_op = operation;
        force nn.xy_write_addr = y_addr;

        @(posedge clk)
        release nn.controller.instruction;
        //release nn.controller.mov_length;
        force nn.controller.mov_length = 'x;
        release nn.controller.act_bypass;
        release nn.controller.act_mask;
        release nn.controller.xy_acc_loopback;
        release nn.controller.xy_acc_op;
        release nn.xy_write_addr;

    end
    endtask

    task load_mac(reg[15:0] x_addr, reg[15:0] mac_addr);
    begin
        force nn.controller.instruction = INST_LOADMAC;

        force nn.xy_read_addr = x_addr;
        force nn.controller.mac_addr = mac_addr;


        @(posedge clk)
        release nn.controller.instruction;
        release nn.xy_read_addr;
        release nn.controller.mac_addr;
    end
    endtask

    task matmul_t(reg[15:0] w_addr, reg[15:0] x_addr, reg[15:0] y_addr, bypass, mask);
    begin
        force nn.controller.instruction = INST_MATMULT;
        force nn.controller.act_bypass = bypass;
        force nn.controller.act_mask = mask;
        force nn.xy_read_addr = x_addr;
        force nn.xy_write_addr = y_addr;
        force nn.w_read_addr = w_addr;

        @(posedge clk)
        release nn.controller.instruction;
        release nn.controller.act_bypass;
        release nn.controller.act_mask;
        release nn.xy_read_addr;
        release nn.xy_write_addr;
        release nn.w_read_addr;
    end
    endtask

    task vect_to_mat(reg[15:0] x_addr, reg[15:0] w_addr);
    begin
        force nn.controller.instruction = INST_VECTTOMAT;
        force nn.controller.xy_read_addr = x_addr;
        force nn.w_write_addr = w_addr;

        @(posedge clk)
        release nn.controller.instruction;
        release nn.controller.xy_read_addr;
        release nn.w_write_addr;
    end
    endtask

    task w_const_prod(reg[15:0] x_addr, reg[15:0] w_read_addr);
    begin
        force nn.controller.instruction = INST_WCONSTPROD;
        force nn.controller.xy_read_addr = x_addr;
        force nn.w_read_addr = w_read_addr;

        @(posedge clk)
        release nn.controller.instruction;
        release nn.controller.xy_read_addr;
        release nn.w_read_addr;
    end
    endtask

    task w_acc(reg[15:0] w_read_addr, reg[15:0] w_write_addr);
    begin
        force nn.controller.instruction = INST_WACC;
        force nn.w_read_addr = w_read_addr;
        force nn.w_write_addr = w_write_addr;

        @(posedge clk)
        release nn.controller.instruction;
        release nn.w_read_addr;
        release nn.w_write_addr;
    end
    endtask

    task halt();
    begin
        force nn.controller.instruction = INST_HALT;
    end
    endtask

    task nop();
    begin
        force nn.controller.instruction = INST_NOP;
        force nn.controller.move = 0;

        @(posedge clk)
        release nn.controller.instruction;
        release nn.controller.move;

    end
    endtask

    initial begin
        nop();
       
        matmul(4,4,0);
        matmul(5,5,0);
        matmul(6,6,1);
        acc_mov(11,4,1,0,0,0);
        matmul(7,11,0);
        matmul(8,12,0);
        matmul(9,13,0);
        matmul(10,14,1);
        acc_mov(20,4,1,0,0,0);
        matmul(11,11,0);
        matmul(12,12,0);
        matmul(13,13,0);
        matmul(14,14,1);
        acc_mov(24,1,1,0,0,0);
        nop();
        nop();
        nop();
        acc_mov(19,1,1,0,0,0);
        matmul(15,20,0);
        matmul(16,21,0);
        matmul(17,22,0);
        matmul(18,23,0);
        matmul(19,24,1);
        acc_mov(27,2,1,0,0,0);
        nop();
        nop();
        acc_mov(25,2,1,0,0,0);       
        halt();
    end

endmodule
