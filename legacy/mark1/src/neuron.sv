module neuron #(parameter SIZE, parameter  BIT_SIZE)(
	input  clk, rst,
    input  [BIT_SIZE-1:0] x, w,
	output [BIT_SIZE-1:0] y
);

	reg [BIT_SIZE-1:0] acc;

	wire [BIT_SIZE-1:0] prod = x*w;
	wire [BIT_SIZE-1:0] sum  = prod + acc;

	wire sign_prod = prod[BIT_SIZE-1];
	wire sign_acc  = acc[BIT_SIZE-1];
	wire sign_sum  = sum[BIT_SIZE-1];

	assign y = acc;

	// Use negedge 
	always_ff @(negedge clk or posedge rst) begin
		if(rst) begin
			acc = 0;		
		end
		else begin			
			acc <= ((sign_prod == sign_acc) & (sign_sum != sign_acc)) ? {~sign_sum, {BIT_SIZE-1{sign_sum}}} : sum; // Overflow clamp
		end
	end
	

endmodule