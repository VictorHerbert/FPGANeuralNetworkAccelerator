module layer #(parameter SIZE = 3, parameter BIT_SIZE = 1)(
    input  clk, rst, input_select,
    input  [BIT_SIZE-1:0] x_input, // Serial input
	input  [SIZE-1:0][BIT_SIZE-1:0] w, 
	output [BIT_SIZE-1:0] y // Serial output
);
    genvar i,j;
    enum {IDLE, SHIFT, STORE, CLEAR} state = IDLE;


    logic [$clog2(SIZE+1)+1:0] counter;
    logic [BIT_SIZE-1:0] x;
    logic [SIZE-1:0][BIT_SIZE-1:0] neuron_out, y_shifter = 0;
    logic neuron_rst;
    
    assign x = input_select ? x_input : y;

    
    assign neuron_rst = (state == CLEAR) | (state == IDLE);
    
    //Can be replaced by a counter and STORE == 0, CLEAR == 1, ...
    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            state = CLEAR;
            counter = 0;
        end
        else begin
            case(state)
                STORE: begin
                    state <= CLEAR;
                    counter <= 0;
                end
                CLEAR: begin
                    state <= SHIFT;                
                    counter <= 1;
                end
                SHIFT: begin
                    counter <= counter + 1;
                    if(counter == SIZE-1)
                        state <= STORE;
                end
            endcase
        end
    end
    
    generate
    for(i = 0; i < SIZE; i++) begin : gen_shifter
        neuron #(SIZE, BIT_SIZE) ni(
            clk, neuron_rst,
            x,
            w[i],
            neuron_out[i]
        );

        always_ff @ (posedge clk) begin
            if (state == STORE) begin
                y_shifter[i] = neuron_out[i];
            end
            else begin    
                if(state == SHIFT) begin
                    if(i < SIZE-1)
                        y_shifter[i] <= y_shifter[i+1];
                end
            end
        end
    end
    endgenerate

    act_function #(BIT_SIZE) lut(
		y_shifter[0], y
	);

endmodule


  /*if(i < SIZE-1) begin
            always_ff @( posedge clk or posedge done) begin
                if(done) y_shifter[i] = neuron_out[i];
                else y_shifter[i] <= y_shifter[i+1];
            end
        end
        else begin
            always_ff @(posedge clk or posedge done) begin
                if(done) y_shifter[i] = neuron_out[i];
            end
        end*/
        
