module neuron #(parameter SIZE, parameter  DEPTH)(
	input  clk, rst,
    input  [DEPTH-1:0] x,
	input  [SIZE-1:0][DEPTH-1:0] w,
	output [DEPTH-1:0] y
);

	wire [DEPTH-1:0] prod, sum;
	wire  sign_prod, sign_acc, sign_sum;

	reg [DEPTH-1:0] acc;
	reg [SIZE-1:0][DEPTH-1:0] w_shifter;

	assign sign_acc			= acc[DEPTH-1];
	assign sign_sum		 	= sum[DEPTH-1];
	assign sign_prod 		= prod[DEPTH-1];

	assign prod = x*w_shifter[SIZE-1];
	assign sum = prod + acc;
	assign y = acc;
	
	always_ff @(negedge clk or posedge rst) begin
		if(rst) begin
			w_shifter = w;
			acc = 0;		
		end
		else begin
			w_shifter <= {w_shifter[SIZE-2:0], w_shifter[SIZE-1]}; // SIZE must be greater than 1
			acc <= ((sign_prod == sign_acc) & (sign_sum != sign_acc)) ? {~sign_sum, {DEPTH-1{sign_sum}}} : sum; // Overflow clamp
		end
	end
	

endmodule