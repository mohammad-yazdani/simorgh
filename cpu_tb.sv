// this testbench loads SimpleAdd.x into the memory and executes the
// instructions found in it
module tb_SimpleAdd;
	`include "params.sv"
	logic clk;
	logic reset;

	// instruction memory / I-cache
	logic im_rw = 1; // 1=read,0=write
	logic [31:0] im_addr, im_dout;
	logic [1:0] im_access_sz = sz_word;
    memory imem(.clk(clk), .addr(im_addr), .data_out(im_dout),
		.access_size(im_access_sz), .rd_wr(im_rw), .enable(~reset));

	// data memory / D-cache
	logic dm_rw; // 1=read,0=write
	logic [31:0] dm_addr, dm_din, dm_dout;
	logic [1:0] dm_access_sz = sz_word;
    memory dmem(.clk(clk), .addr(dm_addr), .data_in(dm_din), .data_out(dm_dout),
		.access_size(dm_access_sz), .rd_wr(dm_rw), .enable(~reset));

	// mips processor
	// #(...) overrides parameters defined inside the module
	mips #(.pc_init(mem_start), .sp_init(mem_start+mem_depth), .ra_init(0))
		proc(.clk(clk), .reset(reset),
		.instr_addr(im_addr), .instr_in(im_dout),
		.data_addr(dm_addr), .data_in(dm_dout), .data_out(dm_din),
		.data_rd_wr(dm_rw));


	logic [31:0] pc_stack [5:0];

    initial begin
        clk = 1; forever #5 clk = ~clk;
    end

    initial begin
		reset <= 1;
		#10 reset <= 0;

		// for each instruction output the PC and show any store to memory
		// in ME stage or write to register in WB stage
		#1 ;
		
		for(int i=0; i<18; i++) begin
			#10 pc_stack[i % 5] <= im_addr;
			#40 if(tb_SimpleAdd.proc.reg_wr_en)
				$write("pc %h write %8h to r%1d\n",
					pc_stack[((i % 5) > 1)? ((i % 5) - 2) : 3 + (i % 5)], tb_SimpleAdd.proc.reg_wr_data,
					tb_SimpleAdd.proc.reg_wr_num);
			if(tb_SimpleAdd.proc.st_en)
				$write("pc %h store %8h at [%8h]\n",
					pc_stack[((i % 5) > 0)? ((i % 5) - 1) : 4], dm_din, dm_addr);
		end
		$write("pc %h\n",
			pc_stack[((18 % 5) > 1)? ((18 % 5) - 2) : 3 + (18 % 5)]);

		#10 $stop;
    end

    initial $dumpvars(0, tb_SimpleAdd); // creates waveform file

endmodule
