// this is a mips module that can only execute the addiu instruction
module mips(
	// port list
	input clk, reset,
	output [31:0] instr_addr,
	input [31:0] instr_in,
	output [31:0] data_addr,
	input [31:0] data_in,
	output logic [31:0] data_out,
	output data_rd_wr);

	// parameters overridden in testbench
	parameter [31:0] pc_init = 0;
	parameter [31:0] sp_init = 0;
	parameter [31:0] ra_init = 0;

	// IF signals
	logic [31:0] pc;
	assign instr_addr = pc;
	logic [31:0] ir;

	// ID signals
    logic [4:0] reg_rd_num0, reg_rd_num1, reg_rd_num2;
	logic [31:0] opcode, funct;
    wire [31:0] reg_rd_data0, reg_rd_data1;
	assign reg_rd_num0 = ir[25:21];
	assign reg_rd_num1 = ir[20:16];
	assign reg_rd_num2 = ir[15:11];
	assign opcode = ir[31:26];
	assign funct = ir[5:0];

	// EX signals
	logic [31:0] a, b, sign_ext_imm;
	logic [31:0] alu_out;

	// ME signals
	logic st_en;
	assign data_out = b;
	assign data_rd_wr = ~st_en;
	assign data_addr = alu_out;

	// WD signals
    logic [4:0] reg_wr_num;
    logic [31:0] reg_wr_data;
    logic reg_wr_en;

	enum { init, fetch, id, ex, me, wb } state;

	// register file
    regfile #(.sp_init(sp_init), .ra_init(ra_init)) regs(
		.wr_num(reg_wr_num), .wr_data(reg_wr_data), .wr_en(reg_wr_en),
        .rd0_num(reg_rd_num0), .rd0_data(reg_rd_data0),
		.rd1_num(reg_rd_num1), .rd1_data(reg_rd_data1),
        .clk(clk), .reset(reset));

	always @(posedge clk or posedge reset) begin
		if(reset) begin
			reg_wr_en <= 0;
			pc <= pc_init;
			state <= init;
		end
		else
			case(state)
				init: begin
					// this state is needed since we have to wait for
					// memory to produce the first instruction after reset
					state <= fetch;
				end
				fetch: begin		
					if (opcode == 'h23) // lw
					begin
						reg_wr_en <= 0;
					end

					ir <= instr_in;
					pc <= pc + 4;
					state <= id;
				end
				id: begin
					a <= reg_rd_data0;
					b <= reg_rd_data1;
					sign_ext_imm <= {{16{ir[15]}},ir[15:0]};
					state <= ex;
				end
				ex: begin
					//$write(" a: %h, b %h, imm %h ", a, b, sign_ext_imm);
					
					if (opcode == 'h0) // add*
						alu_out <= a + b;
					else
						alu_out <= a + sign_ext_imm;

					if (opcode == 'h2B) // sw
					begin
						st_en <= 1;
					end

					// st_en = 1; uncomment to enable store to mem
					state <= me;
				end
				me: begin
					st_en <= 0;
					reg_wr_num <= ir[20:16];
					
					if (ir[5:0] == 'h21)
					begin // TODO : addiu
						reg_wr_en <= 1;
						reg_wr_num <= ir[15:11];
						reg_wr_data <= alu_out;
					end
					if (ir[31:26] == 'h09)
					begin
						reg_wr_en <= 1;
						reg_wr_num <= ir[20:16];
						reg_wr_data <= alu_out;
					end

					if (opcode == 'h23) // lw
					begin
						st_en <= 0;
					end
					state <= wb;
				end
				wb: begin
					if (opcode == 'h23) // lw
					begin
						reg_wr_data <= data_in;
						reg_wr_en <= 1;
						$write(" write %h to r%1d\n", data_in, ir[20:16]);
					end
					else
						reg_wr_en <= 0;
					
					state <= fetch;
				end
				default: begin
					reg_wr_en <= 0;
					state <= fetch;
				end
			endcase
	end

endmodule
