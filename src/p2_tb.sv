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
 
    initial begin
        clk = 1; forever #5 clk = ~clk;
    end

    initial begin
		reset <= 1;
		#10 reset <= 0;

		// for each instruction output the PC and show any store to memory
		// in ME stage or write to register in WB stage
		#1 ;
		for(int i=0; i<17; i++) begin
			#10 $write("pc %8h", im_addr);
			#30 if(tb_SimpleAdd.proc.st_en)
				$write(" store %8h at [%8h]\n", dm_din, dm_addr);
			#10 if(tb_SimpleAdd.proc.reg_wr_en)
				$write(" write %8h to r%1d\n", tb_SimpleAdd.proc.reg_wr_data,
					tb_SimpleAdd.proc.reg_wr_num);
			//$write("\n");
		end
		$write("\n");
		#10 $stop;
    end

    initial $dumpvars(0, tb_SimpleAdd); // creates waveform file

endmodule
