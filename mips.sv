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
	logic [31:0] ex_op, ex_funct;
	logic [31:0] ex_pc;
	logic [4:0] ex_reg0, ex_reg1, ex_reg2;
	// Data forwarding
	logic [1:0] forward;
	logic fwd_reg;
	logic [31:0] forward_data;

	// ME signals
	logic st_en;
	assign data_out = b;
	assign data_rd_wr = ~st_en;
	assign data_addr = alu_out;
	logic [31:0] me_pc;
	logic [31:0] me_op, me_funct;
	logic [4:0] me_reg0, me_reg1, me_reg2;

	// WD signals
    logic [4:0] reg_wr_num;
    logic [31:0] reg_wr_data;
    logic reg_wr_en;
	logic [31:0] wb_op, wb_funct;
	logic [4:0] wb_reg1;
	logic [31:0] wb_pc;

	enum { init, idle, fetch, id, ex, me, wb } state;

	logic [31:0] jump, idle_ctrl;
	integer pfetch, pid, pex, pme, pwb;

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
					jump <= 1;

					pfetch = 0;
					pid = 0;
					pex = 0;
					pme = 0;
					pwb = 0;

					// this state is needed since we have to wait for
					// memory to produce the first instruction after reset
					forward <= 0;
					idle_ctrl <= 5;
					state <= idle;
				end
				idle: begin
					// TODO : IDLE to make startup
					idle_ctrl <= idle_ctrl - 1;
					case(idle_ctrl)
						0: begin
							state <= ex;
						end
						3: begin
							state <= fetch;
						end
						default:
							state <= idle;
					endcase
				end
				fetch: begin
					//$display("\nIF %h %h", alu_out, data_in);

					ir <= instr_in;
					pc <= pc + 4;
					pfetch += 1;

					case(jump)
						1: begin
							state <= id;
						end
						2: begin
							state <= idle;
						end
						4: begin
							state <= me;
						end
						13: begin
							state <= wb;
						end
						default:
							state <= wb;
					endcase
					
				end
				id: begin
					//$write(" [ID %h %h %h %h] ", a, b, data_in, alu_out);			
					// TODO : Return to fetch does not affect these regs.
					a <= reg_rd_data0;
					b <= reg_rd_data1;
					sign_ext_imm <= {{16{ir[15]}},ir[15:0]};
					
					//$display("calc imm: %h | ex alu %h", sign_ext_imm, alu_out);

					ex_op <= opcode;
					ex_funct <= funct;
					ex_reg0 <= reg_rd_num0;
					ex_reg1 <= reg_rd_num1;
					ex_reg2 <= reg_rd_num2;
					ex_pc <= pc;

					jump <= jump + 1;	
					state <= fetch;
					pid += 1;
				end
				ex: begin
					//$write(" [EX %h %h %h %h] ", a, b, data_in, alu_out);		
					//$display("\nEX %h %h", alu_out, data_in);

					if (ex_op == 'h0) // add*
					begin
						if (forward == 1)
						begin
							if (fwd_reg == 0)
							begin
								alu_out <= forward_data + b;
								forward_data <= forward_data + b;
							end
							else
							begin
								alu_out <= a + b;
								forward_data <= a + b;
							end
						end
						else
						begin
							alu_out <= a + b;
							forward_data <= a + b;
						end
					end
					else
					begin
						if (forward == 1 && fwd_reg == 0)
						begin
							alu_out <= forward_data + sign_ext_imm;
							forward_data <= forward_data + sign_ext_imm;
						end
						else
						begin
							alu_out <= a + sign_ext_imm;
							forward_data <= a + sign_ext_imm;
						end
					end

					//$display(" EX Calc ex: %h %h", a, sign_ext_imm);

					if (forward == 1)
					begin
						//$display("\nFWD REG %0d", fwd_reg);
						forward <= 0;
					end

					//$display("\nEX %2d, %2d, %2d", ex_reg0, ex_reg1, ex_reg2);
					//$display("\nID %2d, %2d, %2d", reg_rd_num0, reg_rd_num1, reg_rd_num2);
					if (ex_reg1 != 0 && (ex_reg1 == reg_rd_num0 || ex_reg1 == reg_rd_num1))
					begin
						forward <= 1;
						if (ex_reg1 == reg_rd_num0)
							fwd_reg <= 0;
						else
							fwd_reg <= 1;
					end

					if (ex_op == 'h2B) // sw
					begin
						//$write("\nprev b %h\n", b);
						st_en <= 1;
					end

					me_reg0 <= ex_reg0;
					me_reg1 <= ex_reg1;
					me_reg2 <= ex_reg2;
					me_op <= ex_op;
					me_funct <= ex_funct;
					me_pc <= ex_pc;

					// st_en = 1; uncomment to enable store to mem
					jump <= jump + 1;
					state <= id;
					pex += 1;		
				end
				me: begin
					//$write(" [ME %h %h %h %h] ", a, b, data_in, alu_out);		
					//$display("\nME %h %h", alu_out, data_in);
					
					st_en <= 0;

					if (me_funct == 'h21)
					begin // TODO : addu
						reg_wr_en <= 1;
						reg_wr_num <= me_reg2;
						reg_wr_data <= alu_out;
						if (ex_op == 'h2B && reg_wr_num != 29) // TODO : TEMP SOLUTION
						begin
							b <= alu_out;
						end
					end
					if (me_op == 'h09)
					begin // TODO : addiu
						reg_wr_en <= 1;
						reg_wr_num <= me_reg1;
						reg_wr_data <= alu_out;
						
						if (ex_op == 'h2B && reg_wr_num != 29) // TODO : TEMP SOLUTION
						begin
							b <= alu_out;
						end
						
						//$write("\n ME test write %h\n", alu_out);
					end
					if (me_op == 'h23) // lw
					begin
						reg_wr_num <= me_reg1;
						if (me_reg0 == 29) // Memory check
							reg_wr_data <= 'hxxxxxx;
						else
						begin
							if (forward == 1)
							begin
								reg_wr_data <= b;
							end
							else
								reg_wr_data <= data_in;
						end
						reg_wr_en <= 1;
					end

					wb_reg1 <= me_reg1;
					wb_op <= me_op;
					wb_funct <= me_funct;
					wb_pc <= me_pc;

					jump <= jump + 1;
					state <= ex;
					pme += 1;
				end
				wb: begin
					//$write(" [WB %h %h %h %h] ", a, b, data_in, alu_out);

					reg_wr_en <= 0;
					
					jump <= jump + 1;
					state <= me;
					pwb += 1;
				end
				default: begin
					reg_wr_en <= 0;
					state <= fetch;
				end
			endcase
	end

endmodule
