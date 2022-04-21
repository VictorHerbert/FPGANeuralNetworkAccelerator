module layer #(parameter LAYER_SIZE, parameter LAYER_DEPTH, parameter BIT_SIZE)(
    input  clk, rst,

    output [$clog2(LAYER_DEPTH)-1:0] layer,
    output [$clog2(LAYER_SIZE)-1:0] node,
    
    input  [BIT_SIZE-1:0] x, // Serial input
	input  [LAYER_SIZE-1:0][BIT_SIZE-1:0] w, 
	output [BIT_SIZE-1:0] y // Serial output
);
    genvar i,j;
    enum {IDLE, SHIFT, STORE, CLEAR} state = IDLE;    

    reg [$clog2(LAYER_DEPTH)-1:0] _layer = 0;
    reg [$clog2(LAYER_SIZE)-1:0] _node;

    assign layer = _layer;
    assign node = _node;

    logic [LAYER_SIZE-1:0][BIT_SIZE-1:0] neuron_out, y_shifter = 0;

    wire neuron_rst = (state == CLEAR) | (state == IDLE);
    
    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            state = CLEAR;
            _layer = 0; _node = 0; 
        end
        else begin
            case(state)
                STORE: begin
                    state <= CLEAR;
                    _node = 0;
                end
                CLEAR: begin
                    state <= SHIFT;
                end
                SHIFT: begin
                    _node <= _node+1;
                    if(_node == LAYER_SIZE-1) begin
                        _layer <= layer+1;
                        if(_layer == LAYER_DEPTH-1)
                            state <= IDLE;                        
                        else
                            state <= STORE;
                    end

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