module layer #(parameter LAYER_SIZE = 3, parameter BIT_SIZE = 1)(
    input  clk, rst,
    output [$clog2(LAYER_SIZE)-1:0] node,

    input  [BIT_SIZE-1:0] x, // Serial input
	input  [LAYER_SIZE-1:0][BIT_SIZE-1:0] w, 
	output [BIT_SIZE-1:0] y // Serial output
);
    genvar i,j;
    enum {IDLE, SHIFT, STORE, CLEAR} state = IDLE;    

    logic [$clog2(LAYER_SIZE)-1:0] _node = 0;
    logic [LAYER_SIZE-1:0][BIT_SIZE-1:0] neuron_out, y_shifter = 0;
    logic neuron_rst;

    assign node = _node;
    


    // Can be optimized
    assign neuron_rst = (state == CLEAR) | (state == IDLE);
    
    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            state = CLEAR;
            _node = 0;
        end
        else begin
            case(state)
                STORE: begin
                    state <= CLEAR;
                    _node <= 0;
                end
                CLEAR: begin
                    state <= SHIFT;
                end
                SHIFT: begin
                    _node <= _node + 1;
                    if(_node == LAYER_SIZE-2)
                        state <= STORE;
                end
            endcase
        end
    end
    
    generate
    for(i = 0; i < LAYER_SIZE; i++) begin : gen_shifter
        neuron #(LAYER_SIZE, BIT_SIZE) ni(
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
                    if(i < LAYER_SIZE-1)
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