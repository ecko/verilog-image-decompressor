/*
	Milestone 2
*/


`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// 
module milestone_2 (
	
	input	logic Clock_50,
	input	logic Resetn,
	
	input	logic milestone_start,
	output	logic milestone_done,
	
	input	logic	[15:0]	SRAM_read_data,
	output	logic	[17:0]	SRAM_address,
	output	logic	[15:0]	SRAM_write_data,
	output	logic			SRAM_we_n
		
);

m2_state_type M2_state;



//logic [17:0] Y_offset = 18'd0;
//logic [17:0] U_offset = 18'd38400;
//logic [17:0] V_offset = 18'd57600;
logic [17:0] IDCT_offset = 18'd76800;
//logic [17:0] IDCT_U_offset = 18'd153600;
//logic [17:0] IDCT_V_offset = 18'd192000;


logic [6:0] address_a[1:0];
logic [6:0] address_b[1:0];
logic [31:0] write_data_a [1:0];
logic [31:0] write_data_b [1:0];
logic write_enable_a [1:0];
logic write_enable_b [1:0];
logic [31:0] read_data_a [1:0];
logic [31:0] read_data_b [1:0];


logic [5:0] ReadMatIndex, ReadMatIndex2;	// changes every read
logic [5:0] SecondaryMatIndex;
//logic [17:0] ReadMatIndex;	// changes every read
logic [4:0] ReadBlockRow;	// changes every 64 cycles (goes from 0 to 29)
logic [5:0] ReadBlockCol;	// changes every 30 columns (goes from 0 to 39)

logic [7:0] row_address, row_address2;
logic [8:0] col_address, col_address2;

logic [15:0] sram_read_buffer;
logic [31:0] matrix_address, matrix_address2;

logic [1:0] processing_YUV;


// COMPUTE T
logic compute_t, compute_s;

logic [3:0] index, index_s;
logic [6:0] s_matrix_index;
//Constants
logic [7:0] Coff = 7'd64;
logic [7:0] Soff = 7'd64;

//Multipliers
logic signed [31:0] Mult1_op_1, Mult1_op_2, Mult1_result;
logic signed [63:0] Mult1_result_long;

logic signed [31:0] Mult2_op_1, Mult2_op_2, Mult2_result;
logic signed [63:0] Mult2_result_long;

//Registers
logic [15:0] SBuff;
logic [15:0] SFactor;

logic [31:0] CBuff;
logic [15:0] CFactor1, CFactor2;

logic [31:0] t0, t1;
logic [31:0] tsymout, tsymin;

//##############
logic [31:0] TBuff1, TBuff2, TBuff3, TBuff4;
logic [31:0] TFactor;

logic [7:0] s_write_buffer0, s_write_buffer1;


// Instantiate RAM0
dual_port0	dual_port0_inst0 (
	.address_a ( address_a[0] ),
	.address_b ( address_b[0] ),
	.clock ( Clock_50 ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( write_enable_a[0] ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
);

// Instantiate RAM1
dual_port0	dual_port0_inst1 (
	.address_a ( address_a[1] ),
	.address_b ( address_b[1] ),
	.clock ( Clock_50 ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
);





always_ff @ (posedge Clock_50 or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		M2_state <= S_M2_IDLE;
		
		milestone_done <= 1'b0;
		
		
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		SRAM_address <= IDCT_offset + 16'd0;
		
		ReadMatIndex <= 6'd0;
		ReadMatIndex2 <= 6'd0;
		SecondaryMatIndex <= 1'd0;
		
		//address_a[0] <= 7'd0;
		sram_read_buffer <= 16'd0;
		
		ReadBlockRow <= 5'd0;
		ReadBlockCol <= 6'd0;
				
		address_a[0] <= 7'd0;
		address_b[0] <= 7'd0;
		address_a[1] <= 7'd0;
		address_b[1] <= 7'd0;
		
		write_enable_a[0] <= 1'b0;
		write_enable_b[0] <= 1'b0;
		write_enable_a[1] <= 1'b0;
		write_enable_b[1] <= 1'b0;
		
		write_data_a[0] <= 32'd0;
		
		compute_t <= 1'b0;
		compute_s <= 1'b0;
		
		s_matrix_index <= 2'd0;
		
	end else begin
		case (M2_state)
		S_M2_IDLE: begin
			
			//`ifdef SIMULATION
			//	$write("IDLE of Milestone 2 @ %t\n", $realtime);
			//`endif
			
			//$write("m2 start: %d , m2_done: %d\n", milestone_start, milestone_done);
			
			if ((milestone_start == 1'b1) && (milestone_done == 1'b0)) begin
				M2_state <= S_M2_START;
				
				SRAM_address <= IDCT_offset;
				ReadMatIndex <= ReadMatIndex + 6'd1;
				processing_YUV <= 1'b0;
				
				`ifdef SIMULATION
					$write("START of Milestone 2 @ %t\n", $realtime);
				`endif
				
				
			end
		end
		
		S_M2_JUMP_BACK_START: begin
			M2_state <= S_M2_START;
			
			SRAM_address <= IDCT_offset +matrix_address;
			ReadMatIndex <= ReadMatIndex + 6'd1;
			SRAM_we_n <= 1'b1;
			
		end
		
		S_M2_START: begin
			M2_state <= S_M2_START_DELAY_1;
			
			//`ifdef SIMULATION
			//	$write("START state of Milestone 2 @ %t\n", $realtime);
			//`endif
			
			SRAM_address <= IDCT_offset + matrix_address; 
			ReadMatIndex <= ReadMatIndex + 6'd1;
			SRAM_we_n <= 1'b1;
			
			address_a[0] <= 7'd0;
			write_enable_a[0] <= 1'b0;
			
			
		end
		
		S_M2_START_DELAY_1: begin
			M2_state <= S_M2_READ_S_PRIME_1;
			
			SRAM_address <= IDCT_offset + matrix_address; 
			ReadMatIndex <= ReadMatIndex + 6'd1;
			
			address_a[0] <= 7'd127;
			address_b[0] <= 7'd0;
			write_enable_a[0] <= 1'b0;
			write_enable_b[0] <= 1'b0;
			
			
		end
		
		
		
		S_M2_READ_S_PRIME_1: begin
			M2_state <= S_M2_READ_S_PRIME_2;
			
			SRAM_address <= IDCT_offset + matrix_address; 
			
			
			//$write("SRAM_address should be: %d + %d\n", matrix_address, IDCT_offset);
			// first SRAM read here
			sram_read_buffer <= SRAM_read_data;
			
			// going to need to change ReadBlockCol max for U & V (change to 0-19)
			
			if (ReadMatIndex >= 6'd63) begin
				//ReadBlockCol <= ReadBlockCol + 1'd1;
				SecondaryMatIndex <= SecondaryMatIndex + 1'd1;
				
				
				
				ReadMatIndex <= 1'd0;
				//total_s_primes <= total_s_primes + 6'd63;
				// this is where we want to start the IDCT process.
				// probably jump outside of this state then return once done IDCT and SRAM write.
				
				// start the T matrix process
				// careful that ReadMatIndex is still increased?
				
				//M2_state <= S_M2_CALC_T_START;
				
				// ***** just a test.
				//M2_state <= S_CT_init;
				//M2_state <= S_M2_START_DELAY_1;
				//M2_state <= S_PRINT_S_PRIME;
				
				M2_state <= S_M2_READ_S_PRIME_END1;
				
				
				//$write("\n\n ROUND TWO \n\n\n\n\n");
				
				//address_b[0] <= 7'd64;
				address_b[0] <= 7'd0;
				write_enable_a[0] <= 1'd0;
				write_enable_b[0] <= 1'd0;
				
				
			end else begin
				ReadMatIndex <= ReadMatIndex + 6'd1;
			end
		end
		
		S_M2_READ_S_PRIME_2: begin
			//M2_state <= S_M2_READ_S_PRIME_3;
			M2_state <= S_M2_READ_S_PRIME_1;
			
			SRAM_address <= IDCT_offset + matrix_address; 
			//$write("SRAM_address should be: %d + %d\n", matrix_address, IDCT_offset);
			//ReadMatIndex <= ReadMatIndex + 6'd1;
			
			// if (ReadBlockCol == 1'd0) begin
				// $write("SRAM_address: %d => %d\n", SRAM_address, $signed(SRAM_read_data));
			// end
			
			// second SRAM read here
			address_a[0] <= address_a[0] + 1'd1;
			write_data_a[0] <= {sram_read_buffer, SRAM_read_data};
			write_enable_a[0] <= 1'b1;
			
			
			
			//$write("SRAM_address: %d\n", SRAM_address);
			//$write("next address_a[0]: %d\n", address_a[0] + 1'd1);
			
			//$write("SRAM_read_data [2]: %d\n", $signed(SRAM_read_data));
			
			//$write("writing out [%d]: %d %d (%x %x hex)\n", address_a[0], sram_read_buffer, SRAM_read_data, sram_read_buffer, SRAM_read_data);
			
			if (ReadMatIndex >= 6'd63) begin
				//ReadBlockCol <= ReadBlockCol + 1'd1;
				ReadMatIndex <= 1'd0;
				//total_s_primes <= total_s_primes + 6'd63;
				// this is where we want to start the IDCT process.
				// probably jump outside of this state then return once done IDCT and SRAM write.
				
				// start the T matrix process
				// careful that ReadMatIndex is still increased?
				
				//M2_state <= S_M2_CALC_T_START;
				
				// ***** just a test.
				//M2_state <= S_CT_init;
				//M2_state <= S_M2_START_DELAY_1;
				//M2_state <= S_PRINT_S_PRIME;
				
				M2_state <= S_M2_READ_S_PRIME_END1;
				
				
				//$write("\n\n ROUND TWO \n\n\n\n\n");
				
				//address_b[0] <= 7'd64;
				address_b[0] <= 7'd0;
				write_enable_a[0] <= 1'd0;
				write_enable_b[0] <= 1'd0;

				
			end else begin
				ReadMatIndex <= ReadMatIndex + 6'd1;
			end
		end
		
		S_M2_READ_S_PRIME_END1: begin
			M2_state <= S_M2_READ_S_PRIME_END2;
			
			//SRAM_address <= IDCT_offset + matrix_address; 
			//SRAM_address <= SRAM_address + 1'd1; 
			//sram_read_buffer <= SRAM_read_data;
			
			// second SRAM read here
			address_a[0] <= address_a[0] + 1'd1;
			write_data_a[0] <= {sram_read_buffer, SRAM_read_data};
			write_enable_a[0] <= 1'b1;
		end
		
		S_M2_READ_S_PRIME_END2: begin
			M2_state <= S_M2_READ_S_PRIME_END3;
			
			
			sram_read_buffer <= SRAM_read_data;
		end
		
		S_M2_READ_S_PRIME_END3: begin
			M2_state <= S_M2_READ_S_PRIME_END4;
			
			//SRAM_address <= IDCT_offset + matrix_address; 
			//sram_read_buffer <= SRAM_read_data;
			
			// second SRAM read here
			address_a[0] <= address_a[0] + 1'd1;
			write_data_a[0] <= {sram_read_buffer, SRAM_read_data};
			write_enable_a[0] <= 1'b1;
		end
		
		S_M2_READ_S_PRIME_END4: begin
			M2_state <= S_M2_READ_S_PRIME_END5;
			
			
		end
		
		S_M2_READ_S_PRIME_END5: begin
			//M2_state <= S_PRINT_S_PRIME;
			M2_state <= S_CT_init;
			
			address_b[0] <= 7'd0;
			write_enable_a[0] <= 1'd0;
			write_enable_b[0] <= 1'd0;
		end
		
		
		
		
		
		
		
		
		S_PRINT_S_PRIME: begin
			M2_state <= S_PRINT_S_PRIME_3;
			
			address_a[0] <= 1'd0;
		end
		
		/*
		S_PRIMT_S_PRIME_DELAY: begin
			M2_state <= S_M2_READ_S_PRIME_1;
			
		end
		*/
		
		S_PRINT_S_PRIME_3: begin
			M2_state <= S_PRINT_S_PRIME_1;
			
			//address_a[0] <= address_a[0] + 1'd1;
			
			if (address_a[0] >= 7'd127) begin
				//$stop;
				
				//M2_state <= S_M2_START;
				M2_state <= S_CT_init;
			end
		end
		
		S_PRINT_S_PRIME_1: begin
			M2_state <= S_PRINT_S_PRIME_3;
			
			//if (processing_YUV >= 8'd1) begin
				//$write("S_PRIME [%d]: %d %d [%x hex]\n", address_a[0], $signed(read_data_a[0][31:16]), $signed(read_data_a[0][15:0]), read_data_a[0]);
			//end
			address_a[0] <= address_a[0] + 1'd1;
			
			
		end
		
		
		
		// ------------------- end of reading from SRAM to S'
		// ------------------- start of T matrix compute
		
		
		
		S_CT_init: begin
			M2_state <= S_CT_0;
			
			index <= 4'd0;
			
			compute_t <= 1'b1;
			
			
			write_enable_a[0] <= 1'b0;
			write_enable_b[0] <= 1'b0;
			
			
			address_b[0] <= 7'd0 + Coff;
		end
			
		S_CT_0: begin
			//M2_state <= S_CT_1;
			M2_state <= S_CT_0_DELAY;
			
			//$write("INDEX: %d\n", index);
			
			
			address_a[0] <= {index[3:1], 2'b0};
			//address_a[0] <= 7'd0;
			address_b[0] <= index[0] + Coff;
			write_enable_a[0] <= 1'b0;
			write_enable_b[0] <= 1'b0;
			
				
			
			t0 <= 16'd0;
			t1 <= 16'd0;
			tsymout <= 16'd0;
			tsymin <= 16'd0;
			
			
		end
		
		S_CT_0_DELAY: begin
			M2_state <= S_CT_1;
			
			address_a[0] <= 3'd4 + index[0] + Coff;
			address_b[0] <= 4'd8 + index[0] + Coff;
			
		end
			
		S_CT_1: begin 

			M2_state <= S_CT_2;
			
			SBuff <= read_data_a[0][15:0];
			
			address_a[0] <= 1'd1 + {index[3:1], 2'b0};
			address_b[0] <= 4'd12 + index[0] + Coff;
			
			
			SFactor <= read_data_a[0][31:16];
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			
		end
			
		S_CT_2: begin
			SFactor <= SBuff;
			CFactor1 <= read_data_a[0][31:16];
			CFactor2 <= read_data_a[0][15:0];
			//P10 <= Mult1_result;
			t0 <= t0 + (Mult1_result);
			
			
			address_a[0] <= 2'd2 + {index[3:1], 2'b0};
			address_b[0] <= 7'd16 + index[0] + Coff;
			
			
			
			//$write("S_CT_2 \n");
			//$write("SFactor %d * CFactor1 %d = Mult1_result %d (%x hex)\n", $signed(SFactor), $signed(CFactor1), (Mult1_result), (Mult1_result));
			//$write("SFactor %d * CFactor2 %d = Mult1_result %d (%x hex)\n", $signed(SFactor), $signed(CFactor2), (Mult2_result), (Mult2_result));
			//$write("INDEX: %d\n", index);
			
			
			tsymout <= tsymout + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin + (Mult2_result);
			CBuff <= read_data_b[0];
			
			
			//P20 <= Mult2_result;
			M2_state <= S_CT_3;
		end
		
		S_CT_3: begin
			
			SBuff <= read_data_a[0][15:0];
			SFactor <= read_data_a[0][31:16];
			//P11 <= Mult1_result;
			CFactor1 <= CBuff[31:16];
			CFactor2 <= CBuff[15:0];
			CBuff <= read_data_b[0];
			//P21 <= Mult2_result;
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout - (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin - (Mult2_result);
			M2_state <= S_CT_4;
			
		end	
			
		S_CT_4: begin
			SFactor <= SBuff;
			//P12 <= Mult1_result;
			CFactor1 <= CBuff[31:16];
			CFactor2 <= CBuff[15:0];
			CBuff <= read_data_b[0];
			//P21 <= Mult2_result;
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin + (Mult2_result);
			M2_state <= S_CT_5;
			
			
			address_a[0] <= 5'd20 + index[0] + Coff;		
			address_b[0] <= 5'd24 + index[0] + Coff;
			
			
		end
		
		S_CT_5: begin
			SBuff <= read_data_a[0][15:0];
			SFactor <= read_data_a[0][31:16];
			//P13 <= Mult1_result;
			CFactor1 <= CBuff[31:16];
			CFactor2 <= CBuff[15:0];
			//P23 <= Mult2_result;	
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout - (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin - (Mult2_result);	
			M2_state <= S_CT_6;
			
			address_a[0] <= 2'd3 + {index[3:1], 2'b0};		
			address_b[0] <= 5'd28 + index[0] + Coff;
			
			
		end
			
		S_CT_6: begin
			SFactor <= SBuff;
			//P14 <= Mult1_result;
			CFactor1 <= read_data_a[0][31:16];
			CFactor2 <= read_data_a[0][15:0];
			CBuff <= read_data_b[0];
			//P24 <= Mult2_result;
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin + (Mult2_result);
			M2_state <= S_CT_7;
			
			
		end
			
		S_CT_7: begin
			SBuff <= read_data_a[0][15:0];
			SFactor <= read_data_a[0][31:16];
			//P15 <= Mult1_result;
			CFactor1 <= CBuff[31:16];
			CFactor2 <= CBuff[15:0];
			CBuff <= read_data_b[0];
			//P25 <= Mult2_result;
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout - (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin - (Mult2_result);
			M2_state <= S_CT_8;
			
			
		end
			
		S_CT_8: begin
			SFactor <= SBuff;
			//P16 <= Mult1_result;
			CFactor1 <= CBuff[31:16];
			CFactor2 <= CBuff[15:0];
			//P26 <= Mult2_result;
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin + (Mult2_result);
			M2_state <= S_CT_PRE_9;
			
			
		end
		
		S_CT_PRE_9: begin
			M2_state <= S_CT_9;
			
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout - (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin - (Mult2_result);
			
		end

		S_CT_9: begin
			//P17 <= Mult1_result;
			//P27 <= Mult2_result;
			M2_state <= S_CT_10;
			
			//address_a[1] <= {index[3:1], 2'b0};
			//address_b[1] <= {index[3:1], 2'b0} + (3'd3 - index[0]);
			
			
			
			write_enable_a[1] <= 1'b1;
			write_enable_b[1] <= 1'b1;
			
			write_data_a[1] <= { {8{t0[31]}}, t0[31:8] };
			write_data_b[1] <= { {8{t1[31]}}, t1[31:8] };
			
			
			// $write("t0 divide by 256: %d\n", t0[31:8]);
			// $write("t1 divide by 256: %d\n", $signed(t1[31:8]));
			
			
			
			address_a[1] <= {index[3:1], 3'd0} + {index[0],1'd0};
			address_b[1] <= {index[3:1], 3'd0} + 1'd1 + {index[0],1'd0};
			
			
			// $write("earlier... t0: %d , t1 %d %b\n", $signed(t0), $signed(t1), $signed(t1));
			// $write("earlier... t0: %d , t1 %d %b\n", (t0), (t1), t1);
			// $write(" tsymin: %d , tsymout: %d\n\n", tsymin, tsymout);
			
			
			
		end
		
		S_CT_10: begin
			//M2_state <= S_CT_0;
			M2_state <= S_CT_11;
			
			//index <= index + 1'b1;
			//tsymout <= P10 - P11 + P12 - P13 + P14 - P15 + P16 - P17;
			//tsymin <= P20 - P21 + P22 - P23 + P24 - P25 + P26 - P27;
			
			//$write("INDEX: %d\n", index);
			
			
			write_enable_a[1] <= 1'b1;
			write_enable_b[1] <= 1'b1;
			
			write_data_a[1] <= { {8{tsymin[31]}}, tsymin[31:8] };
			write_data_b[1] <= { {8{tsymout[31]}}, tsymout[31:8] };
			
			//write_data_a[1] <= {{32{t0[31]}}, t0[31:8], {32{t1[31]}}, t1[31:8]};
			//write_data_b[1] <= {{32{t0[31]}}, t0[31:8], {32{t1[31]}}, t1[31:8]};
			
			address_a[1] <= {index[3:1], 3'd0} + (3'd6 - {index[0],1'd0});
			address_b[1] <= {index[3:1], 3'd0} + (3'd7 - {index[0],1'd0});
			
			// $write("10: address_a[1]: %d\n", address_a[1]);
			// $write("10: address_b[1]: %d\n", address_b[1]);
			
			//$write(" t0: %d , t1 %d\n", $signed({ {8{t0[31]}}, t0[31:8] }), $signed({ {8{t1[31]}}, t1[31:8] }));
			//$write(" tsymin: %d , tsymout: %d\n\n", $signed(tsymin[31:8]), $signed(tsymout[31:8]));
		end
		
		S_CT_11: begin
			M2_state <= S_CT_0;
			/*
			$write("write_data_a[1]: %d\n", write_data_a[1]);
			$write("write_data_b[1]: %d\n", write_data_b[1]);
			
			
			$write("11: address_a[1]: %d\n", address_a[1]);
			$write("11: address_b[1]: %d\n", address_b[1]);
			*/
			//address_a[1] <= {index[3:1], 2'b0} + (3'd3 - index[0]);
			//address_b[1] <= {index[3:1], 2'b0} + (3'd3 - index[0]) + 1'd1;
			//write_data_a[1] <= {32{t0[31]}, t0[31:8], 32{t1[31]}, t1[31:8]};
			//write_data_b[1] <= {32{t0[31]}, t0[31:8], 32{t1[31]}, t1[31:8]};
			index <= index + 1'd1;
			
			
			//$write("INDEX: %d\n", index);
			
			
			//write_data_a[1] <= { {8{tsymin[31]}}, tsymin[31:8] };
			//write_data_b[1] <= { {8{tsymout[31]}}, tsymout[31:8] };
			
			
			//t0 <= 32'd0;
			//t1 <= 32'd0;
			
				write_enable_a[1] <= 1'b0;
				write_enable_b[1] <= 1'b0;
			
			
			if (index >= 4'd15) begin
				//M2_state <= S_CT_READ_T;
				M2_state <= S_S_init;
				
				address_a[1] <= 7'd0;
				
				//$write("stopping compute T after 16 iterations\n");
				//$stop;
			end
		end
		
		S_CT_READ_DELAY: begin
			M2_state <= S_CT_READ_T;
			
			address_a[1] <= address_a[1] + 1'd1;
			
		end
		
		S_CT_READ_T: begin
			M2_state <= S_CT_READ_DELAY;
			
			//if (ReadBlockRow >= 10) begin
				//$write("T[%d]: %d\n", address_a[1], $signed(read_data_a[1]));
			//end
			
			if (address_a[1] == 7'd127) begin
				//$write("READ 127\n");
				//$stop;
				
				M2_state <= S_S_init;
			end
		end
		
		
		S_S_init: begin
			M2_state <= S_S_0;
			
			index_s <= 4'd0;
			compute_s <= 1'b1;
			compute_t <= 1'b0;
			
			TBuff1 <= 32'd0;
			TBuff2 <= 32'd0;
			TBuff3 <= 32'd0;
			TBuff4 <= 32'd0;
			
			
			write_enable_b[0] <= 1'b0;
			write_enable_a[1] <= 1'b0;
			write_enable_b[1] <= 1'b0;
			
		end
			
		S_S_0: begin
			M2_state <= S_S_0_DELAY;
			
			//$write("INDEX: %d\n", index);
			
			
			address_b[0] <= 7'd0 + index_s[0] + Coff;
			address_a[1] <= 7'd0 + index_s[3:1];
			address_b[1] <= 7'd8 + index_s[3:1];
			
			
			
			write_enable_b[0] <= 1'b0;
			write_enable_a[1] <= 1'b0;
			write_enable_b[1] <= 1'b0;
			
			
			t0 <= 16'd0;
			t1 <= 16'd0;
			tsymout <= 16'd0;
			tsymin <= 16'd0;
			
			
		end
		
		S_S_0_DELAY: begin
			M2_state <= S_S_1;
			
			address_b[0] <= 4'd4 + index_s[0] + Coff;
			address_a[1] <= 5'd16 + index_s[3:1];
			address_b[1] <= 5'd24 + index_s[3:1];
			
		end
			
		S_S_1: begin 
			M2_state <= S_S_2;
			
			TBuff1 <= read_data_b[1];
			
			
			address_b[0] <= 8'd8 + index_s[0] + Coff;
			
			address_a[1] <= 8'd32 + index_s[3:1];
			address_b[1] <= 8'd40 + index_s[3:1];
			
			TFactor <= read_data_a[1];
			
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
		end
			
		S_S_2: begin
			M2_state <= S_S_3;
			
			
			TBuff1 <= read_data_a[1];
			TBuff2 <= read_data_b[1];
			
			TFactor <= TBuff1;
			
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout + (Mult1_result);
			tsymin <= tsymin + (Mult2_result);
			
			//$write("read_data_a[0]: %d\n", read_data_a[0][31:16]);
			
			
			address_b[0] <= 8'd12 + index_s[0] + Coff;
			address_a[1] <= 8'd48 + index_s[3:1];
			address_b[1] <= 8'd56 + index_s[3:1];
			
		end
		
		
		S_S_3: begin
			M2_state <= S_S_4;
			
			TBuff3 <= read_data_b[1];
			TBuff2 <= read_data_a[1];
			TBuff1 <= TBuff2;
			
			TFactor <= TBuff1;
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout - (Mult1_result);
			tsymin <= tsymin - (Mult2_result);
			
			
			address_b[0] <= 8'd16 + index_s[0] + Coff;
			
		end	
			
		S_S_4: begin
			M2_state <= S_S_5;
			
			TBuff4 <= read_data_b[1];
			TBuff3 <= read_data_a[1];
			TBuff2 <= TBuff3;
			TBuff1 <= TBuff2;
			
			TFactor <= TBuff1;
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			tsymout <= tsymout + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymin <= tsymin + (Mult2_result);
			
			
			
			address_b[0] <= 8'd20 + index_s[0] + Coff;
			
			
			
		end
		
		S_S_5: begin
			M2_state <= S_S_6;
			
			TBuff3 <= TBuff4;
			TBuff2 <= TBuff3;
			TBuff1 <= TBuff2;
			
			
			TFactor <= TBuff1;
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout - (Mult1_result);
			tsymin <= tsymin - (Mult2_result);	
			
			
			
			address_b[0] <= 8'd24 + index_s[0] + Coff;
			
			
			
		end
		
		S_S_6: begin
			M2_state <= S_S_7;
			
			TBuff2 <= TBuff3;
			TBuff1 <= TBuff2;
			
			TFactor <= TBuff1;
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout + (Mult1_result);
			tsymin <= tsymin + (Mult2_result);
			
			
			address_b[0] <= 8'd28 + index_s[0] + Coff;
			
			
		end
		
		S_S_7: begin
			M2_state <= S_S_8;
			
			TBuff1 <= TBuff2;
			
			TFactor <= TBuff1;
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout - (Mult1_result);
			tsymin <= tsymin - (Mult2_result);
			
			
			
		end
			
		S_S_8: begin
			M2_state <= S_S_PRE_9;
			
			TFactor <= TBuff1;
			CFactor1 <= read_data_b[0][31:16];
			CFactor2 <= read_data_b[0][15:0];
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout + (Mult1_result);
			tsymin <= tsymin + (Mult2_result);
			
			
		end
		
		S_S_PRE_9: begin
			M2_state <= S_S_9;
			
			t0 <= t0 + (Mult1_result);
			t1 <= t1 + (Mult2_result);
			tsymout <= tsymout - (Mult1_result);
			tsymin <= tsymin - (Mult2_result);
			
		end

		S_S_9: begin
			M2_state <= S_S_10;
			
			
			
			
			
			//$write("S_S_9 \n");
			//$write("TFactor %d * CFactor1 %d = Mult1_result %d (%x hex)\n", $signed(TFactor), $signed(CFactor1), (Mult1_result), (Mult1_result));
			//$write("TFactor %d * CFactor2 %d = Mult1_result %d (%x hex)\n", $signed(TFactor), $signed(CFactor2), (Mult2_result), (Mult2_result));
			//$write("INDEX: %d\n", index_s);
			
			//$write(" t0: %d\n", $signed(t0));
			
			
			//$write("t0 divide by 65536: %d\n", t0[31:16]);
			//$write("t1 divide by 65536: %d\n", $signed(t1[31:16]));
			
			// address_a[1] <= {index[3:1], 3'd0} + (3'd6 - {index[0],1'd0});
			
			
			//$write("earlier... t0: %d , t1 %d %b\n", $signed(t0), $signed(t1), $signed(t1));
			//$write("earlier... t0: %d , t1 %d %b\n", (t0), (t1), t1);
			//$write(" t0: %d , t1: %d\n\n", $signed(t0[31:16]), $signed(t1[31:16]));
			//$write(" tsymin: %d , tsymout: %d\n\n", tsymin[31:16], tsymout[31:16]);
			
			//$stop;
			// *****************************
			
			
			write_enable_a[1] <= 1'b1;
			write_enable_b[1] <= 1'b1;
			
			//write_data_a[1] <= { {8{t0[31]}}, t0[31:16] };
			//write_data_b[1] <= { {8{t1[31]}}, t1[31:16] };
			
			
			if (t0[31] == 1'b1) begin
				write_data_a[1] <= 32'd0;
			end else begin
				write_data_a[1] <= { {16{1'd0}}, t0[31:16] };
			end
			
			if (t1[31] == 1'b1) begin
				write_data_b[1] <= 32'd0;
			end else begin
				write_data_b[1] <= { {16{1'd0}}, t1[31:16] };
			end
			
			
			address_a[1] <= {index_s[3:1]} + {index_s[0],4'd0} +Soff;
			address_b[1] <= {index_s[3:1]} + {index_s[0],4'd0} + 5'd8 + Soff;
			
			
		end
		
		S_S_10: begin
			M2_state <= S_S_11;
			
			
			
			
			//address_a[1] <= {index_s[3:1], 3'd0} + { index_s[0], 4'd0} + Soff;
			//address_b[1] <= {index_s[3:1], 3'd0} + { index_s[0] ,4'd0} + 4'd8 + Soff;
			
			
			
			write_enable_a[1] <= 1'b1;
			write_enable_b[1] <= 1'b1;
			
			if (tsymin[31] == 1'b1) begin
				write_data_a[1] <= 32'd0;
			end else begin
				write_data_a[1] <= { {16{1'b0}}, tsymin[31:16] };
			end
			
			if (tsymout[31] == 1'b1) begin
				write_data_b[1] <= 32'd0;
			end else begin
				write_data_b[1] <= { {16{1'b0}}, tsymout[31:16] };
			end
			
			
			
			address_a[1] <= {index_s[3:1]} + (6'd48 - {index_s[0],4'd0}) + Soff;
			address_b[1] <= {index_s[3:1]} + (6'd56 - {index_s[0],4'd0}) + Soff;
			
			
			
		end
		
		S_S_11: begin
			M2_state <= S_S_0;
			//M2_state <= S_S_11;
			
			index_s <= index_s + 1'd1;
			
			
			
			//$write("INDEX_s: %d\n", index_s);
			
			
				write_enable_a[1] <= 1'b0;
				write_enable_b[1] <= 1'b0;
			// $write("10: address_a[1]: %d\n", address_a[1]);
			// $write("10: address_b[1]: %d\n", address_b[1]);
			
			// $write(" t0: %d , t1 %d\n", $signed({ {8{t0[31]}}, t0[31:8] }), $signed({ {8{t1[31]}}, t1[31:8] }));
			// $write(" tsymin: %d , tsymout: %d\n\n", $signed(tsymin[31:8]), $signed(tsymout[31:8]));
			
			if (index_s >= 4'd15) begin
				//M2_state <= S_S_READ_DELAY;
				M2_state <= S_M2_WRITE_S_INIT;
				
				address_a[1] <= 7'd63;
				
				write_enable_a[1] <= 1'b0;
				write_enable_b[1] <= 1'b0;
				
				
				//$write("stopping compute S after 16 iterations\n");
				//$stop;
			end
			
		end
		
		S_S_READ_DELAY: begin
			M2_state <= S_S_READ_T;
			
			address_a[1] <= address_a[1] + 1'd1;
			
			if (ReadBlockRow >= 8'd10) begin
				//$write("S[%d]: %d %x hex\n", address_a[1], $signed(read_data_a[1]), read_data_a[1]);
			end
		end
		
		S_S_READ_T: begin
			M2_state <= S_S_READ_DELAY;
			
			//$write("S[%d]: %d %x hex\n", address_a[1], $signed(read_data_a[1]), read_data_a[1]);
			
			
			if (address_a[1] >= 7'd127) begin
				//$write("READ 127\n");
				//$stop;
				
				M2_state <= S_M2_WRITE_S_INIT;
			end
		end
		
		
		
		S_M2_WRITE_S_INIT: begin
			M2_state <= S_M2_WRITE_S_DELAY_1;
			
			//$write("in S_M2_WRITE_S_INIT state\n");
			
		end
		
		S_M2_WRITE_S_DELAY_1: begin
			M2_state <= S_M2_WRITE_S_DELAY_2;
			
			address_a[1] <= s_matrix_index + Soff;
			address_b[1] <= 1'd1 + s_matrix_index + Soff;
			
			//SRAM_address <= {s_matrix_index[6:3], 8'd0} + {s_matrix_index[6:3], 6'd0} + s_matrix_index[2:1];
			
			
			//SRAM_address <= {s_matrix_index[6:3], 7'd0} + {s_matrix_index[6:3], 5'd0} + s_matrix_index[2:1] + matrix_address2;
			SRAM_address <= matrix_address2;
			
			//$write("SRAM_address should be: %d\n", matrix_address2);
			
			SRAM_we_n <= 1'd1;
		end
		
		S_M2_WRITE_S_DELAY_2: begin
			M2_state <= S_M2_WRITE_S_2;
			
		end
		
		
		S_M2_WRITE_S_2: begin
			M2_state <= S_M2_WRITE_S_SRAM;
			
			
			// do clipping 
			
			s_write_buffer0 <= read_data_a[1][7:0];
			s_write_buffer1 <= read_data_b[1][7:0];
			
			
			if (|read_data_a[1][30:8] == 1'b1) begin
				s_write_buffer0 <= 8'd255;
			end
			if (read_data_a[1][31] == 1'b1) begin
				s_write_buffer0 <= 8'd0;
			end
			
			if (|read_data_b[1][30:8] == 1'b1) begin
				s_write_buffer1 <= 8'd255;
			end
			if (read_data_b[1][31] == 1'b1) begin
				s_write_buffer1 <= 8'd0;
			end
			
			// 
			if (SRAM_address == 18'd76800) begin
				// we're done
				
				SRAM_we_n <= 1'b1;
				
				`ifdef SIMULATION
					$write(" GO TO DONE \n\n\n");
				`endif
				
				M2_state <= S_M2_DONE;
			end
			
		end
		
		S_M2_WRITE_S_SRAM: begin
			M2_state <= S_M2_WRITE_S_DELAY_1;
			
			s_matrix_index <= s_matrix_index + 2'd2;
			ReadMatIndex2 <= ReadMatIndex2 + 2'd1;
			
			SRAM_write_data <= {s_write_buffer0, s_write_buffer1};
			SRAM_we_n <= 1'b0;
			
			//$write("\n writing: %d (%x hex) %d (%x hex) to: %d\n", s_write_buffer0,s_write_buffer0, s_write_buffer1,s_write_buffer1, SRAM_address);
			
			//$write("s_matrix_index[5:0]: %d\n", s_matrix_index[5:0]);
	
			if (s_matrix_index >= 6'd63) begin
				// jump right back to the start.
				M2_state <= S_M2_JUMP_BACK_START;
				//M2_state <= S_M2_JUMP_BACK_DELAY_2;
				
				//$write(" JUMP BACK TO IDLE \n");
				
				//SRAM_we_n <= 1'b1;
				
				ReadMatIndex <= 1'd0;
				//ReadMatIndex2 <= 1'd0;
				
				index <= 1'd0;
				s_matrix_index <= 1'd0;
				
				address_a[0] <= 1'd0;
				address_b[0] <= 1'd0;
				address_a[1] <= 1'd0;
				address_b[1] <= 1'd0;
						
						
				SRAM_write_data <= 16'd0;
				SRAM_we_n <= 1'b1;
				SRAM_address <= IDCT_offset + 16'd0;
				
				ReadMatIndex <= 6'd0;
								
				//address_a[0] <= 7'd0;
				sram_read_buffer <= 16'd0;
			
				address_a[0] <= 7'd0;
				address_b[0] <= 7'd0;
				address_a[1] <= 7'd0;
				address_b[1] <= 7'd0;
				
				write_enable_a[0] <= 1'b0;
				write_enable_b[0] <= 1'b0;
				write_enable_a[1] <= 1'b0;
				write_enable_b[1] <= 1'b0;
				
				write_data_a[0] <= 32'd0;
				
				s_matrix_index <= 2'd0;
				
				
				// if (ReadBlockRow >= 8'd29) begin
					 //$write("YUV: %d  ReadBlockCol: %d  ReadBlockRow: %d @ %t\n", processing_YUV, ReadBlockCol, ReadBlockRow, $realtime);
				// end
				
				ReadBlockCol <= ReadBlockCol + 1'd1;
				
				if (processing_YUV == 1'd0) begin
					if (ReadBlockCol >= 6'd39) begin
						ReadBlockRow <= ReadBlockRow + 1'd1;
						
						// reset to zero
						ReadBlockCol <= 1'd0;
						
					end
				end else begin
					if (ReadBlockCol >= 6'd19) begin
						ReadBlockRow <= ReadBlockRow + 1'd1;
						
						// reset to zero
						ReadBlockCol <= 1'd0;
						
					end
				end
				
				if (processing_YUV == 1'd0) begin
					if ((ReadBlockRow == 5'd29) && (ReadBlockCol == 6'd39)) begin
						// it should be all done with the Y, move on to U, V and change the limits
						//$write(" ALL DONE ?");
						//$stop;
						
						ReadBlockRow <= 1'd0;
						ReadBlockCol <= 1'd0;
						
						// go on to the next set!
						processing_YUV <= processing_YUV + 1'd1;
					end
				end else begin
					if ((ReadBlockRow == 5'd29) && (ReadBlockCol == 6'd19)) begin
						
						// it should be all done with the Y, move on to U, V and change the limits
						//$write(" ALL DONE ?");
						//$stop;
						
						ReadBlockRow <= 1'd0;
						ReadBlockCol <= 1'd0;
						
						// go on to the next set!
						processing_YUV <= processing_YUV + 1'd1;
						
						if (processing_YUV == 2'd2) begin
							//done!
							
							//$write(" GO TO DONE \n\n\n");
							
							M2_state <= S_M2_DONE;
						end
					end
				end
			end
		end
	
		S_M2_JUMP_BACK_DELAY_2: begin
			M2_state <= S_M2_JUMP_BACK_DELAY;
		end
		
		S_M2_JUMP_BACK_DELAY: begin
			M2_state <= S_M2_READ_S_PRIME_1;
		end
	
		S_M2_DONE: begin
			`ifdef SIMULATION
				$write("\n\nDONE MILESTONE 2 @ %t\n\n", $realtime);
			`endif
			
			milestone_done <= 1'b1;
			
			// just do some last minute cleanup before heading to idle
			M2_state <= S_M2_CLEANUP;
		end
		
		S_M2_CLEANUP: begin
			milestone_done <= 1'd0;
			
			M2_state <= S_M2_IDLE;
		end
				
		default: M2_state <= S_M2_IDLE;
		endcase
	end
end

always_comb begin
	if (compute_t == 1'b1) begin
		Mult1_op_1 = $signed(SFactor);
		Mult2_op_1 = $signed(SFactor);
		
		Mult1_op_2 = $signed(CFactor1);
		Mult2_op_2 = $signed(CFactor2);
	end else begin
		Mult1_op_1 = $signed(TFactor);
		Mult2_op_1 = $signed(TFactor);
		
		Mult1_op_2 = $signed(CFactor1);
		Mult2_op_2 = $signed(CFactor2);
	end
end

always_comb begin
	//col_address2 = {ReadBlockCol, ReadMatIndex2[1:0]};
	//row_address2 = {ReadBlockRow, ReadMatIndex2[5:2]};
	if (processing_YUV == 2'd1) begin
		// U
		matrix_address2 = s_matrix_index[2:1] + {s_matrix_index[5:3], 6'd0} + {s_matrix_index[5:3], 4'd0} + {ReadBlockCol, 2'd0} + {ReadBlockRow, 7'd0} + {ReadBlockRow, 9'd0} + 16'd38400;
		
	end else if (processing_YUV == 2'd2) begin
		// V
		matrix_address2 = s_matrix_index[2:1] + {s_matrix_index[5:3], 6'd0} + {s_matrix_index[5:3], 4'd0} + {ReadBlockCol, 2'd0} + {ReadBlockRow, 7'd0} + {ReadBlockRow, 9'd0} + 16'd57600;
		
	end else begin
		// for Y
		matrix_address2 = s_matrix_index[2:1] + {s_matrix_index[5:3], 7'd0} + {s_matrix_index[5:3], 5'd0} + {ReadBlockCol, 2'd0} + {ReadBlockRow, 10'd0} + {ReadBlockRow, 8'd0};
		
	end
end

always_comb begin
	
	// i = ReadMatIndex[5:3]
	// j = ReadMatIndex[2:0]
	
	// RA = {rb, ri} => {ReadBlockRow, ReadMatIndex[5:3]}
	
	if (processing_YUV == 2'd1) begin
		matrix_address = {ReadBlockRow, 8'd0} + {ReadBlockRow, 10'd0} + {ReadBlockCol, 3'd0} + {ReadMatIndex[5:3], 7'd0} + {ReadMatIndex[5:3], 5'd0} + ReadMatIndex[2:0] + 18'd76800;
	end else if (processing_YUV == 2'd2) begin
		matrix_address = {ReadBlockRow, 8'd0} + {ReadBlockRow, 10'd0} + {ReadBlockCol, 3'd0} + {ReadMatIndex[5:3], 7'd0} + {ReadMatIndex[5:3], 5'd0} + ReadMatIndex[2:0] + 18'd115200;
	end else begin
		// Y
		
		matrix_address = {ReadBlockRow, 9'd0} + {ReadBlockRow, 11'd0} + {ReadBlockCol, 3'd0} + {ReadMatIndex[5:3], 8'd0} + {ReadMatIndex[5:3], 6'd0} + ReadMatIndex[2:0];
	end
end

assign Mult1_result_long = Mult1_op_1 * Mult1_op_2;
assign Mult1_result = Mult1_result_long[31:0];

assign Mult2_result_long = Mult2_op_1 * Mult2_op_2;
assign Mult2_result = Mult2_result_long[31:0];

endmodule
