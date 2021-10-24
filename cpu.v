`timescale 1ns / 1ps

module alu(A, B, ALU_OP, F, ZF, OF);
	input [31:0] A;
	input [31:0] B;
	input [3:0] ALU_OP;
	output reg [31:0] F;
	output reg ZF, OF;
	reg C;
	always@(*)
	begin
		C = 0; OF = 0; ZF = 0;
		case(ALU_OP)
		4'b0000: begin F = A & B; end
		4'b0001: begin F = A | B; end
		4'b0010: begin F = A ^ B; end
		4'b0011: begin F = ~(A | B); end 
		4'b0100: begin {C, F} = A + B; OF = A[31] ^ B[31] ^ F[31] ^ C; end 
		4'b0101: begin {C, F} = A - B; OF = A[31] ^ B[31] ^ F[31] ^ C; end 
		4'b0110: begin F = A < B; end
		4'b0111: begin F = B << A; end
		endcase
		ZF = F==0;
		end
endmodule

module register(R_Addr_A, R_Addr_B, W_Addr, W_Data, clk, rst, Write_Reg, R_Data_A, R_Data_B);
	input [4:0] R_Addr_A;
	input [4:0] R_Addr_B;
	input [4:0] W_Addr;
	input [31:0] W_Data;
	input clk;
	input rst;
	input Write_Reg;
	output [31:0] R_Data_A;
	output [31:0] R_Data_B;
	reg[31:0] heap[0:31];
	integer i;
	initial for(i=0; i<32; i=i+1) heap[i] <= 0;
	always@(posedge rst or posedge clk)
	begin
		if(rst==1)
		begin
			for(i=0; i<32; i=i+1) heap[i] <= 0;
		end
		else if(Write_Reg==1)
		begin
			heap[W_Addr] <= W_Data;
		end
	end
	assign R_Data_A = heap[R_Addr_A];
	assign R_Data_B = heap[R_Addr_B];
endmodule

module cpu(clk, rst, display, f);
	input clk, rst;
	input [3:0] display;
	output reg [31:0] f;
	reg [31:0] PC;  // PC
	wire [31:0] PC_new;
	reg [1:0] PC_s;
	wire [31:0] Inst_code;
	initial PC = 32'h00000000;
	assign PC_new = PC + 4;
	always@(negedge clk or posedge rst)
	begin
		if(rst==1) PC <= 32'h00000000;
		else
		begin
			case(PC_s)
			2'b00: begin PC <= PC_new; end
			2'b01: begin PC <= R_Data_A; end  //
			2'b10: begin PC <= PC_new + (imm_data<<2); end  // PC + 4 + offset * 4
			2'b11: begin PC <= {PC_new[31:28], address, 2'b00}; end  //
			endcase
		end
	end

	instruction_memory ins_mem (
		.clka(clk),
		.addra(PC[7:2]),
		.douta(Inst_code)
	);

	//Decoding and Control Unit
	wire [5:0] opcode;  // instruction code
	wire [4:0] rs, rt, rd, shamt;
	wire [5:0] func;
	wire [15:0] imm;
	wire [15:0] offset;
	wire [25:0] address;
	reg Write_Reg;  //
	reg Mem_Write;  // data memory
	wire [7:0] Mem_Addr;
	reg [31:0] M_W_Data;
	wire [31:0] M_R_Data;
	reg [3:0] ALU_OP;  // ALU
	wire ZF, OF;
	wire [31:0] F;
	assign opcode = Inst_code[31:26];
	assign rs = Inst_code[25:21];
	assign rt = Inst_code[20:16];
	assign rd = Inst_code[15:11];
	assign shamt = Inst_code[10:6];
	assign func = Inst_code[5:0];
	assign imm = Inst_code[15:0];
	assign offset = Inst_code[15:0];
	assign address = Inst_code[25:0];

	reg [1:0] w_r_s, wr_data_s;
	reg imm_s, rt_imm_s;
	
	always@(*)
	begin
		//default run R type instruction--add
		ALU_OP = 4'b0100;
		PC_s = 2'b00;
		w_r_s = 2'b00;
		wr_data_s = 2'b00;
		imm_s = 1'b0;
		rt_imm_s = 1'b0;
		Write_Reg = 1'b1;
		Mem_Write = 1'b0;
		if(opcode==6'b000000)  //R type
		begin
			case(func)
			6'b100000: begin ALU_OP = 4'b0100; end  //add
			6'b100010: begin ALU_OP = 4'b0101; end  //sub
			6'b100100: begin ALU_OP = 4'b0000; end  //and
			6'b100101: begin ALU_OP = 4'b0001; end  //or
			6'b100110: begin ALU_OP = 4'b0010; end  //xor
			6'b100111: begin ALU_OP = 4'b0011; end  //nor
			6'b101011: begin ALU_OP = 4'b0110; end  //sltu
			6'b000100: begin ALU_OP = 4'b0111; end  //sllv
			6'b001000: begin Write_Reg = 0; Mem_Write = 0; PC_s = 2'b01; end  //jr
		endcase
		end
		else if(opcode==6'b000010)  //j
		begin
			Write_Reg = 1'b0;
			Mem_Write = 1'b0;
			PC_s = 2'b11;
		end
		else if(opcode==6'b000011)  //jal
		begin
			w_r_s = 2'b10;
			wr_data_s = 2'b10;
			Write_Reg = 1'b1;
			Mem_Write = 1'b0;
			PC_s = 2'b11;
		end
		else  // I type
		begin
			case(opcode)
			6'b001000: begin w_r_s = 2'b01; imm_s = 1; rt_imm_s = 1; ALU_OP = 4'b0100; end  //addi
			6'b001100: begin w_r_s = 2'b01; rt_imm_s = 1; ALU_OP = 4'b0000; end  //andi
			//6'b001101: begin w_r_s = 2'b01; rt_imm_s = 1; ALU_OP = 4'b0110; end  //ori
			6'b001110: begin w_r_s = 2'b01; rt_imm_s = 1; ALU_OP = 4'b0010; end  //xori
			6'b001011: begin w_r_s = 2'b01; rt_imm_s = 1; ALU_OP = 4'b0110; end  //sltiu
			6'b100011: begin w_r_s = 2'b01; imm_s = 1; rt_imm_s = 1; wr_data_s = 2'b01; ALU_OP=3'b100; end  //lw
			6'b101011: begin imm_s = 1; rt_imm_s = 1; ALU_OP = 3'b100; Write_Reg = 0; Mem_Write = 1; end  //sw
			6'b000100: begin ALU_OP = 3'b101; PC_s = (ZF)?2'b10:2'b00; Write_Reg = 1'b0; end  //beq
			6'b000101: begin ALU_OP = 3'b101; PC_s = (ZF)?2'b00:2'b10; Write_Reg = 1'b0; end  //bne
			endcase
		end
	end

	wire [31:0] imm_data;
	assign imm_data = (imm_s)?{{16{imm[15]}},imm}:{{16{1'b0}},imm};
	wire [4:0] W_Addr;
	assign W_Addr = (w_r_s[1])?5'b11111:((w_r_s[0])?rt:rd);
	wire [31:0] W_Data;
	assign W_Data = (wr_data_s[1])?PC_new:((wr_data_s[0])?M_R_Data:F);
	wire [31:0] B_ALU;
	assign B_ALU = (rt_imm_s)?imm_data:R_Data_B;
	assign Mem_Addr = F[7:0];
	
	//Decoding and Control Unit end

	wire [31:0] R_Data_A, R_Data_B;

	register Register (
		.R_Addr_A(rs),
		.R_Addr_B(rt),
		.W_Addr(W_Addr),  // w_r_s
		.W_Data(W_Data),  // wr_data_s
		.clk(clk),
		.rst(rst),
		.Write_Reg(Write_Reg),
		.R_Data_A(R_Data_A),
		.R_Data_B(R_Data_B)
	);

	alu ALU (
		.A(R_Data_A),
		.B(B_ALU),  // rt_imm_s
		.ALU_OP(ALU_OP),
		.F(F),
		.ZF(ZF),
		.OF(OF)
	);

	data_memory data_mem (
		.clka(clk),
		.wea(Mem_Write),
		.addra(Mem_Addr[7:2]),
		.dina(R_Data_B),
		.douta(M_R_Data)
	);
	
	always@(*)
	begin
		case(display)
		4'b1000: begin f = PC; end
		4'b0100: begin f = {ZF, OF}; end
		4'b0010: begin f = M_R_Data; end
		4'b0001: begin f = F; end
		endcase
	end

endmodule



//00002020,20050014,2006000a,0c000004,00804020,00a04820,00c05020,8d0b0000,ad2b0000,21080004,21290004,214affff,1540fffb,03e00008
