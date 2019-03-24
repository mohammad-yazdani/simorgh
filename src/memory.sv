module memory(
		input clk, input [31:0] addr, input [31:0] data_in,
		output logic [31:0] data_out, input [1:0] access_size, input rd_wr,
		output logic busy, input enable);
	`include "params.sv"

    reg[31:0] data [0:mem_depth/4-1];
    initial $readmemh(mem_file, data);

	wire[29:0] data_index = (addr - 32'h80020000) >> 2;
	logic [3:0] burst_count;
	logic [29:0] burst_addr;
	logic burst_rd_wr;
	assign busy = | burst_count;

	always @(posedge clk)
	begin
		if(enable) begin
			if(burst_count > 0) begin
				if(burst_rd_wr)
					data_out <= data[burst_addr];
				else
					data[burst_addr] <= data_in;
				burst_addr <= burst_addr + 1;
				burst_count <= burst_count - 1;
			end
			else begin
				if(rd_wr == 1) begin //read
					if(access_size==sz_byte)
						case(addr[1:0])
							// data is stored in big-endian order!!!
							3: data_out <=
								{24'hzzzzzz,data[data_index][7:0]};
							2: data_out <=
								{24'hzzzzzz,data[data_index][15:8]};
							1: data_out <=
								{24'hzzzzzz,data[data_index][23:16]};
							0: data_out <=
								{24'hzzzzzz,data[data_index][31:24]};
						endcase
					else
						data_out <= data[data_index];
				end
				else begin // write
					if(access_size==sz_byte)
						case(addr[1:0])
							// data is stored in big-endian order!!!
							3: data[data_index][7:0] <= data_in[7:0];
							2: data[data_index][15:8] <= data_in[7:0];
							1: data[data_index][23:16] <= data_in[7:0];
							0: data[data_index][31:24] <= data_in[7:0];
						endcase
					else
						data[data_index] <= data_in;
				end

				case(access_size)
					sz_byte: burst_count <= 0;
					sz_word: burst_count <= 0;
					sz_4word: burst_count <= 3;
					sz_8word: burst_count <= 7;
				endcase
				burst_addr <= data_index + 1;
				burst_rd_wr <= rd_wr;
			end
		end
		else begin
			burst_count <= 0;
			data_out <= 'Z;
		end
	end

endmodule
