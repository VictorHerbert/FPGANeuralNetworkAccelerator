`timescale 1 ns / 1 ps

import definitions::*;

module testbench;

// ---------------------------------------
// ------- Test Vector Signals  ----------
// ---------------------------------------

    localparam TEST_BEGIN = 0;
    localparam TEST_END = 1000;

    int file, log_file;
    string test_vector_final_name;

    string vector_filename = "../testbench/vectors/case%0d.txt";
    string log_filename = "../testbench/log.txt";

    int input_size, output_size;
    reg signed [15:0] expected_output, mse;


// ---------------------------------------
// ----------- Dut Signals  --------------
// ---------------------------------------

    localparam CLK_PERIOD = 10;
    localparam CLK_HALF_PERIOD = CLK_PERIOD/2;

    logic clk = 1, reset = 0;

    initial forever #CLK_HALF_PERIOD clk = ~clk;
    initial begin reset = 1; #(3*CLK_PERIOD) reset = 0; end

    logic write_enable = 0, read_enable = 0;
    logic available;

    logic [MM_DEPTH-1:0] read_addr;
    logic [Q_DEPTH-1:0] read_data;
    logic [MM_DEPTH-1:0] write_addr;
    logic [MM_WIDTH-1:0] write_data;

    task await_ticks(int ticks);
        repeat(ticks) @(posedge clk);
    endtask

    task write_packet ();
        write_enable = 1'b1;
        @(posedge clk);
        write_addr = 'dx;
        write_data = 'dx;
        write_enable = 1'b0;
    endtask

    task read_packet();
        read_enable = 1;
        @(posedge clk);
        read_addr = 'dx;
        read_enable = 0;
    endtask

    NeuralNetwork nn(
        .clk(clk), .reset(reset),

        .write_enable(write_enable),
        .read_enable(read_enable),
        .available(available),

        .read_addr(read_addr),
        .read_data(read_data),
        .write_addr(write_addr),
        .write_data(write_data)
    );



// ---------------------------------------
// -------- Vector based tests  ----------
// ---------------------------------------

    initial begin
        log_file = $fopen(log_filename, "w");
        if(!log_file) $error("Log File not found");

        for(int test_case = TEST_BEGIN; test_case < TEST_END; test_case++) begin
            $sformat(test_vector_final_name, vector_filename, test_case);

            file = $fopen(test_vector_final_name, "r");
            if(!file) $error("File not found");

            $fscanf(file, "%d", input_size);

            await_ticks(4);
            for(int i = 0; i < input_size; i++) begin
                $fscanf(file, "%d %d", write_addr, write_data);
                write_packet();
            end

            await_ticks(4);
            write_addr = 16'hC000; write_data = 16'd0001;
            write_packet();
            await_ticks(4);

            wait(available);

            $fscanf(file, "%d", output_size);

            mse = 0;
            await_ticks(4);
            for(int i = 0; i < output_size; i++) begin
                $fscanf(file, "%d %d", read_addr, expected_output);
                read_packet();

                await_ticks(1);
                if(read_data == 'x) begin
                    $display("Case %d: x during read");
                    $fdisplay(log_file, "Case %d: x during read");
                end

                //read_data[31:15] = {16{read_data[15]}};
                //expected_output[31:15] = {16{expected_output[15]}};

                mse += (read_data - expected_output)*(read_data - expected_output);
            end

            $display("Case %d: ME %f", test_case, $itor(mse)*(2.0**-12.0)/$itor(output_size));
            $fdisplay(log_file, "Case %d: MSE %f", test_case, $itor(mse)*(2.0**-12.0)/$itor(output_size));

            await_ticks(4);
            $fclose(file);
        end
        $fclose(log_file);
        $stop();
    end



endmodule