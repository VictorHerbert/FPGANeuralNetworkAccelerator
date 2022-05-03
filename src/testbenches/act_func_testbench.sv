import definitions::*;

module act_func_testbench;

    parameter CLK_PERIOD = 10;
    parameter CLK_HALF_PERIOD = CLK_PERIOD/2;

    logic clk = 1, reset = 0;

    initial repeat(200) #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(CLK_HALF_PERIOD) reset = 0; end

    logic signed [Q_INT-1:-Q_FRAC] x;
    logic act_bypass;
    logic[ACT_MASK_SIZE-1:0] mask;
    logic signed [Q_INT-1:-Q_FRAC] fx;


    ActivationFunction act_funct(
        .clk(clk),
        .write_enable(0),

        .x(x),
        .act_bypass(1'b0),
        .mask(mask),
        .fx(fx)
    );

    initial begin
        static int step = 4096;

        for(int i = 0; i < 4; i++) begin
            mask <= i;
            x <= -32768;
            #CLK_PERIOD;
            for(int j = 0; j < step-1; j++) begin
                x <= x+65536/step;
                #CLK_PERIOD;
            end
        end
    end

endmodule