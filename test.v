`timescale 1ns / 1ps

module test;

	// Inputs
	reg clk;
	reg rst;
	reg [3:0] display;

	// Outputs
	wire [31:0] f;

	// Instantiate the Unit Under Test (UUT)
	cpu uut (
		.clk(clk), 
		.rst(rst), 
		.display(display), 
		.f(f)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		display = 4'b0001;

		// Wait 100 ns for global reset to finish
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
		#100;
		clk = 0;
		#100;
		clk = 1;	
	end
endmodule

