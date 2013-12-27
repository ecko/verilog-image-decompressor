/*
	Milestone 1
*/


`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// 
module milestone_1 (
	
	input	logic Clock_50,
	input	logic Resetn,
	
	input	logic m1_start,
	output	logic milestone_done,
	
	input	logic	[15:0]	SRAM_read_data,
	output	logic	[17:0]	SRAM_address,
	output	logic	[15:0]	SRAM_write_data,
	output	logic			SRAM_we_n
		
);

m1_state_type M1_state;

M1_Multiplier_Mux_type multiplier_mux;


logic [17:0] RGB_offset = 18'd146944;
logic [17:0] index;
logic [17:0] data_counter;
logic [17:0] u_7_counter;

logic [17:0] odd_read_address;
logic [17:0] u_7_counter_less_one;
logic [17:0] u_7_odd_plus_seven;
logic [17:0] modulo_317;

logic [17:0] Y_offset = 18'd0;
logic [17:0] U_offset = 18'd38400;
logic [17:0] V_offset = 18'd57600;

logic [31:0] Mult1_op_1, Mult1_op_2, Mult1_result;
logic [63:0] Mult1_result_long;

logic [31:0] Mult2_op_1, Mult2_op_2, Mult2_result;
logic [63:0] Mult2_result_long;

logic signed [31:0] Mult3_op_1, Mult3_op_2, Mult3_result;
logic [63:0] Mult3_result_long;

// data registers/buffers
logic [15:0] data_reg_yEven, data_reg_yOdd;
logic [15:0] data_reg_uEven, data_reg_vEven;
logic [15:0] data_reg_uOdd, data_reg_vOdd;

logic [7:0] data_reg_u7, data_reg_u6, data_reg_u5, data_reg_u4, data_reg_u3, data_reg_u2, data_reg_u1, data_reg_u0;
logic [7:0] data_reg_v7, data_reg_v6, data_reg_v5, data_reg_v4, data_reg_v3, data_reg_v2, data_reg_v1, data_reg_v0;
logic signed [31:0] data_reg_preR_mult, data_reg_preG_mult, data_reg_preB_mult;
logic signed [15:0] data_reg_preR, data_reg_preG, data_reg_preB;
logic [7:0] data_reg_R, data_reg_G, data_reg_B, data_reg_R_buffer, data_reg_B_buffer;

logic flag_RGB_first_pair;

logic [4:0] cc_first_round;

logic [15:0] Y;
logic [7:0] U_prime, V_prime;
logic [31:0] U_prime_odd, V_prime_odd;


logic [31:0] data_reg_CC_y_value;
logic [16:0] data_reg_FIR_result;




always_ff @ (posedge Clock_50 or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		data_reg_u5 <= 8'b0;
		data_reg_u4 <= 8'b0;
		data_reg_u3 <= 8'b0;
		data_reg_u2 <= 8'b0;
		data_reg_u1 <= 8'b0;
		data_reg_u0 <= 8'b0;
			
		data_reg_v5 <= 8'b0;
		data_reg_v4 <= 8'b0;
		data_reg_v3 <= 8'b0;
		data_reg_v2 <= 8'b0;
		data_reg_v1 <= 8'b0;
		data_reg_v0 <= 8'b0;
		
		data_reg_yEven <= 8'h00;
		data_reg_yOdd <= 8'h00;
		
		data_reg_uEven <= 8'h00;
		data_reg_uOdd <= 8'h00;
		
		data_reg_vEven <= 8'h00;
		data_reg_vOdd <= 8'h00;
		
		SRAM_address <= U_offset;
		
		M1_state <= S_M1_IDLE;
		milestone_done <= 1'b0;
		
		U_prime <= 8'hFF;
		
		
		cc_first_round <= 1'b1;
		
		index <= 18'd0;
		data_counter <= 18'd0;
		
		u_7_counter <= 17'd0;
		
		
		u_7_counter_less_one <= 17'd1;
		u_7_odd_plus_seven <= 17'd1;
		
		modulo_317 <= 9'd1;
		
		data_reg_R_buffer <= 8'd0;
		
	end else begin
		case (M1_state)
		S_M1_IDLE: begin
			u_7_counter <= 17'd0;
			u_7_counter_less_one <= 17'd1;

			if ((m1_start == 1'b1) && (milestone_done == 1'b0)) begin
				M1_state <= S_M1_START;

				//`ifdef SIMULATION
				//	$write("Heading to START @ %t\n", $realtime);
				//`endif
			end
		end
		
		S_M1_START: begin
			// this is the LEAD IN state
			
			//$write("START state of Milestone 1\n\n");
			`ifdef SIMULATION
				$write("START state of Milestone 1 @ %t\n", $realtime);
			`endif
			
			
			//M1_state <= S_M1_RESTART;
			M1_state <= S_M1_START_DELAY_1;
			
			//index <= 17'd0;
			SRAM_we_n <= 1'b1;
			SRAM_address <= V_offset;
			data_counter <= data_counter + 1'd1; // next pair
			//SRAM_address <= 17'd0;
			
			// remember, u5 is our most significant reg (it gets newest data)
			data_reg_u5 <= 8'd000;
			data_reg_u4 <= 8'd000;
			data_reg_u3 <= 8'd000;
			data_reg_u2 <= 8'd000;
			data_reg_u1 <= 8'd000;
			data_reg_u0 <= 8'd000;
			
			data_reg_v5 <= 8'd000;
			data_reg_v4 <= 8'd000;
			data_reg_v3 <= 8'd000;
			data_reg_v2 <= 8'd000;
			data_reg_v1 <= 8'd000;
			data_reg_v0 <= 8'd000;
		end
		
		// need two delay states to start with!!
		
		// _RESTART takes one
		
		S_M1_START_DELAY_1: begin
			M1_state <= S_M1_LEAD_IN_1;
			SRAM_address <= U_offset + data_counter;
			
		end
		
		S_M1_LEAD_IN_1: begin
			M1_state <= S_M1_LEAD_IN_2;
			SRAM_address <= V_offset + data_counter;
			data_counter <= data_counter + 1'd1;
			
			//setting up lead in stuff
			data_reg_u7 <= SRAM_read_data[7:0];
			data_reg_u6 <= SRAM_read_data[15:8];
			
			data_reg_u5 <= SRAM_read_data[15:8];
			data_reg_u4 <= SRAM_read_data[15:8];
			data_reg_u3 <= data_reg_u5;
			data_reg_u2 <= data_reg_u4;
			data_reg_u1 <= data_reg_u3;
			data_reg_u0 <= data_reg_u2;
			
		end
		
		S_M1_LEAD_IN_2: begin
			M1_state <= S_M1_LOAD_U;
			M1_state <= S_M1_LEAD_IN_3;
			SRAM_address <= U_offset + data_counter;
			//data_counter <= data_counter + 1'd1;
			//SRAM_address <= Y_offset + index;
			
			data_reg_v7 <= SRAM_read_data[7:0];
			data_reg_v6 <= SRAM_read_data[15:8];
			
			data_reg_v5 <= SRAM_read_data[15:8];
			data_reg_v4 <= SRAM_read_data[15:8];
			data_reg_v3 <= data_reg_v5;
			data_reg_v2 <= data_reg_v4;
			data_reg_v1 <= data_reg_v3;
			data_reg_v0 <= data_reg_v2;
			
			//data_reg_uEven <= data_reg_u2;
			//data_reg_vEven <= SRAM_read_data[15:8];
		end
		
		S_M1_LEAD_IN_3: begin
			M1_state <= S_M1_LEAD_IN_4;
			SRAM_address <= V_offset + data_counter;
			data_counter <= data_counter + 1'd1;
			
			data_reg_u7 <= SRAM_read_data[7:0];
			data_reg_u6 <= SRAM_read_data[15:8];
			
			data_reg_u5 <= data_reg_u7;
			data_reg_u4 <= data_reg_u6;
			data_reg_u3 <= data_reg_u5;
			data_reg_u2 <= data_reg_u4;
			data_reg_u1 <= data_reg_u3;
			data_reg_u0 <= data_reg_u2;
			
		end
		
		S_M1_LEAD_IN_4: begin
			M1_state <= S_M1_LOAD_U;
			//data_counter <= data_counter + 1'd1;
			
			data_counter <= data_counter + 1'd1;
			SRAM_address <= Y_offset + index;
			
			data_reg_v7 <= SRAM_read_data[7:0];
			data_reg_v6 <= SRAM_read_data[15:8];
			
			data_reg_v5 <= data_reg_v7;
			data_reg_v4 <= data_reg_v6;
			data_reg_v3 <= data_reg_v5;
			data_reg_v2 <= data_reg_v4;
			data_reg_v1 <= data_reg_v3;
			data_reg_v0 <= data_reg_v2;
			
			data_reg_uEven <= data_reg_u2;
			data_reg_vEven <= SRAM_read_data[15:8];
		end
		
		
		
		S_M1_BORDER_1: begin
			M1_state <= S_M1_BORDER_1_2;
			SRAM_address <= SRAM_address + 1'd1;
			
			
			`ifdef SIMULATION
				// just print something so we know it's still working.
				$write(".");
			`endif
		end
		
		S_M1_BORDER_1_2: begin
			M1_state <= S_M1_BORDER_2;
			SRAM_address <= V_offset + u_7_counter_less_one[17:2];
			
			
		end
		
		S_M1_BORDER_2: begin
			M1_state <= S_M1_BORDER_3;
			
			SRAM_address <= SRAM_address + 1'd1;
			
			data_reg_u5 <= SRAM_read_data[7:0];
			data_reg_u4 <= SRAM_read_data[15:8];
			data_reg_u3 <= SRAM_read_data[15:8];
			data_reg_u2 <= SRAM_read_data[15:8];
			data_reg_u1 <= data_reg_u3;
			data_reg_u0 <= data_reg_u2;
				
			
			if (u_7_counter[1] == 1'd0) begin
				data_reg_uEven <= SRAM_read_data[15:8];
			end else begin
				data_reg_uEven <= SRAM_read_data[7:0];
			end
		
				
		end
		
		S_M1_BORDER_3: begin
			M1_state <= S_M1_BORDER_4;
			
			//SRAM_address <= U_offset + {2'd0, u_7_odd_plus_seven[17:2]};
			SRAM_address <= Y_offset + u_7_counter[17:1];
			
			data_reg_u5 <= SRAM_read_data[7:0];
			data_reg_u4 <= SRAM_read_data[15:8];
			data_reg_u3 <= data_reg_u5;
			data_reg_u2 <= data_reg_u4;
			data_reg_u1 <= data_reg_u3;
			data_reg_u0 <= data_reg_u2;
			
		end
		
		S_M1_BORDER_4: begin
			M1_state <= S_M1_BORDER_5;
			
			SRAM_address <= RGB_offset + index;
			
			
			data_reg_v5 <= SRAM_read_data[7:0];
			data_reg_v4 <= SRAM_read_data[15:8];
			data_reg_v3 <= SRAM_read_data[15:8];
			data_reg_v2 <= SRAM_read_data[15:8];
			data_reg_v1 <= data_reg_v3;
			data_reg_v0 <= data_reg_v2;
			
			U_prime_odd <= data_reg_FIR_result[15:8];
			
			if (u_7_counter[1] == 1'd0) begin
				data_reg_vEven <= SRAM_read_data[15:8];
			end else begin
				data_reg_vEven <= SRAM_read_data[7:0];
			end
			
			
		end
		
		S_M1_BORDER_5: begin
			M1_state <= S_M1_LOAD_Y;
			
			data_reg_v5 <= SRAM_read_data[7:0];
			data_reg_v4 <= SRAM_read_data[15:8];
			data_reg_v3 <= data_reg_v5;
			data_reg_v2 <= data_reg_v4;
			data_reg_v1 <= data_reg_v3;
			data_reg_v0 <= data_reg_v2;
			
			modulo_317 <= 17'd1;
			multiplier_mux <= FIR_V;
		end
		
		
		// we load in an EVEN AND ODD U value
		S_M1_LOAD_U: begin
			M1_state <= S_M1_LOAD_V;
			
			SRAM_address <= Y_offset + u_7_counter[17:1];
			
			SRAM_we_n <= 1'b1;
			
			
			// do the multiplications for U' with j odd
			multiplier_mux <= FIR_U;
			
			
			// this should really only push ONE value
			
			
			// *****
			// read the location TWICE. pushing the MSBits or LSBits?
			
			// this will work once LEAD IN is complete
			// for now it's trying to push 0 onto to of stack (should already be on bottom)
			
			if (u_7_counter <= 8'd0) begin
				//$write(" DOING IT THE ORIG WAY \n");
				
				data_reg_u7 <= SRAM_read_data[7:0];
				data_reg_u6 <= SRAM_read_data[15:8];
				
				data_reg_u5 <= data_reg_u7;
				data_reg_u4 <= data_reg_u6;
				data_reg_u3 <= data_reg_u5;
				data_reg_u2 <= data_reg_u4;
				data_reg_u1 <= data_reg_u3;
				data_reg_u0 <= data_reg_u2;
			end else begin
				//data_reg_u7 <= SRAM_read_data[15:8];
				
				if (modulo_317 == 17'd321) begin
					M1_state <= S_M1_BORDER_1;
					
					SRAM_address <= U_offset + u_7_counter_less_one[17:2];
					
				end else if (modulo_317 >= 17'd315) begin
					data_reg_u4 <= data_reg_u5;
					data_reg_u3 <= data_reg_u4;
					data_reg_u2 <= data_reg_u3;
					data_reg_u1 <= data_reg_u2;
					data_reg_u0 <= data_reg_u1;
				
				end else begin
					if (u_7_counter_less_one[1] == 1'd1) begin
						data_reg_u5 <= SRAM_read_data[15:8];
					end else begin
						data_reg_u5 <= SRAM_read_data[7:0];
					end
					
					data_reg_u4 <= data_reg_u5;
					data_reg_u3 <= data_reg_u4;
					data_reg_u2 <= data_reg_u3;
					data_reg_u1 <= data_reg_u2;
					data_reg_u0 <= data_reg_u1;
				end
			end
			
			
			if (u_7_counter_less_one > 17'd76799) begin
				M1_state <= S_M1_DONE;
			end
			
		end
		
		S_M1_LOAD_V: begin
			M1_state <= S_M1_LOAD_Y;
			
			// set SRAM for writing RGB
			SRAM_address <= RGB_offset + index;
			
			SRAM_we_n <= 1'b1;
			
			
			U_prime_odd <= data_reg_FIR_result[15:8];
			
			U_prime <= data_reg_uEven;
			
			// border case
			if (modulo_317 >= 17'd320) begin
				modulo_317 <= 17'd1;
				
				//M1_state <= S_M1_BORDER_1;
				
			end
			
			
			multiplier_mux <= FIR_V;
			
			if (u_7_counter <= 8'd0) begin
				data_reg_v7 <= SRAM_read_data[7:0];
				data_reg_v6 <= SRAM_read_data[15:8];
				
				data_reg_v5 <= data_reg_v7;
				data_reg_v4 <= data_reg_v6;
				data_reg_v3 <= data_reg_v5;
				data_reg_v2 <= data_reg_v4;
				data_reg_v1 <= data_reg_v3;
				data_reg_v0 <= data_reg_v2;
			end else begin
				
				if (modulo_317 >= 17'd315) begin
					data_reg_v4 <= data_reg_v5;
					data_reg_v3 <= data_reg_v4;
					data_reg_v2 <= data_reg_v3;
					data_reg_v1 <= data_reg_v2;
					data_reg_v0 <= data_reg_v1;
				
				end else begin
					
					if (u_7_counter_less_one[1] == 1'd1) begin
						data_reg_v5 <= SRAM_read_data[15:8];
					end else begin
						data_reg_v5 <= SRAM_read_data[7:0];
					end
					
					data_reg_v4 <= data_reg_v5;
					data_reg_v3 <= data_reg_v4;
					data_reg_v2 <= data_reg_v3;
					data_reg_v1 <= data_reg_v2;
					data_reg_v0 <= data_reg_v1;
				end
			end
		end
		
		
		S_M1_LOAD_Y: begin
			M1_state <= S_M1_CC_FIRST_SET_CALCULATED;
			
			`ifdef SIMULATION
				//$write(" Working on pixel index: [u_7_counter_less_one (start 1 +2)]: %d \n", u_7_counter_less_one);
			`endif
			
			SRAM_we_n <= 1'b1;
			
			
			
			V_prime_odd <= data_reg_FIR_result[15:8];
			
		//	$write("V_prime_even: %d\n", data_reg_vEven);
		//	$write("V_prime_odd: %d\n", data_reg_FIR_result[15:8]);
			
			
				V_prime <= data_reg_vEven;
			//$write(" U_prime: %d \n ", U_prime);
			
			data_reg_yEven <= SRAM_read_data[15:8];
			data_reg_yOdd <= SRAM_read_data[7:0];
			
		//	$write("yEven: %d\n", SRAM_read_data[15:8]);
		//	$write("yOdd: %d\n", SRAM_read_data[7:0]);
			
			
			// work with Even first
			Y <= SRAM_read_data[15:8];
			
		//	$write("SRAM_read_data 2: %d %d\n", SRAM_read_data[15:8], SRAM_read_data[7:0]);
			
			cc_first_round <= 2'd0;
			
			// do the colourspace conversion
			multiplier_mux <= COLOR_CONV;
			
			//SRAM_write_data <= {data_reg_R, data_reg_G};
			
			//Y <= SRAM_read_data;
			//$write("Y: %h", Y);
			//$write("FIR_V: 5,4,3,2,1,0: %d,%d,%d,%d,%d,%d\n", data_reg_v5, data_reg_v4, data_reg_v3, data_reg_v2, data_reg_v1, data_reg_v0);
			
			//$write(" writing to SRAM_address #1: %d \n", SRAM_address);
			
		end
		
		S_M1_CC_FIRST_SET_CALCULATED: begin
			M1_state <= S_M1_CC_SECOND_SET_CALCULATED;
			//SRAM_we_n <= 1'b1;
			
			
			cc_first_round <= 2'd1;
			
			//Y <= data_reg_yOdd;
			
			data_reg_CC_y_value <= Mult1_result;
			
			
			// write!
			SRAM_we_n <= 1'b1; // can't write yet since I don't have G calculated yet
			
			// remember, actually WRITING in NEXT cycle.
			// ****** THIS IS GOOD ******* 2:53 AM Saturday, November 16, 2013
			// it's working, the comparison just doesn't match because it has a leading 0 for some reason in the testbench
			//SRAM_write_data <= {data_reg_R, data_reg_G};
			//SRAM_write_data <= {data_reg_R, 8'hFF};
			
			data_reg_R_buffer <= data_reg_R;
			
		//	$write(" first set, 0 \n");
		//	$write(" R value before division: %d \n", data_reg_preR_mult);
			//$write(" G value before division: %d \n", data_reg_preG_mult);
			//$write(" B value before division: %d \n", data_reg_preB_mult);
			
			// store this value because it's going to be used often
			//data_reg_CC_y_value <= Mult1_result;
			
			//data_reg_R <= Mult1_result + Mult2_result;
			
			// this result is now invalid. data reg calculated in CC
			//$write("** data_reg_R value (value before division): %d (%x hex)\n", (Mult1_result + Mult2_result), (Mult1_result + Mult2_result));
			
			//$write(" writing to SRAM_address #2: %d \n", SRAM_address);
			
		//	$write("RGB[%d] => %d %d %d \n", (index-1), data_reg_R,data_reg_G,data_reg_B);
			
		end
		
		S_M1_CC_SECOND_SET_CALCULATED: begin
			M1_state <= S_M1_TRANSITION;
			
			
			// write! (write enable for this cycle set in the previous cycle)
			SRAM_we_n <= 1'b0;
			// ****** THIS IS GOOD ******* 2:53 AM Saturday, November 16, 2013
			//SRAM_write_data <= {data_reg_B, 8'h00};
			//SRAM_write_data <= { 8'h2d, 8'h38};
			//SRAM_write_data <= {data_reg_R, data_reg_G};
			SRAM_write_data <= {data_reg_R_buffer, data_reg_G};
			index <= index + 1'd1;
			
			data_reg_B_buffer <= data_reg_B;
			
			cc_first_round <= 2'd2;
			Y <= data_reg_yOdd;
			U_prime <= U_prime_odd;
			V_prime <= V_prime_odd;
			
		end
		
		S_M1_TRANSITION: begin
			M1_state <= S_M1_TEST2;
			
			SRAM_address <= RGB_offset + index;
			// ****** THIS IS GOOD ******* 2:53 AM Saturday, November 16, 2013
			// wrote RGB triplet 0
			SRAM_we_n <= 1'b0;
			//SRAM_write_data <= {data_reg_B, data_reg_R}; // this is the NEXT R value
			SRAM_write_data <= {data_reg_B_buffer, data_reg_R};
			//data_reg_R_buffer <= data_reg_R;
			
			
			//SRAM_address <= RGB_offset + index;
			index <= index + 1'd1;
			
			cc_first_round <= 2'd3;
			// push the even values onto our shift reg
			data_reg_CC_y_value <= Mult1_result;
			
		//	$write("RGB[%d] => %d %d %d \n", (index-1), data_reg_R,data_reg_G,data_reg_B);
			
		end
		
		S_M1_TEST2: begin
			M1_state <= S_M1_DELAY_1;
			//M1_state <= S_M1_TEST3;
			
		//	$write(" S_M1_TEST2 \n");
			
			
			
		//	$write("second set\n");
			//$write(" R value before division: %d \n", data_reg_preR_mult);
		//	$write(" G value before division: %d \n", data_reg_preG_mult);
		//	$write(" B value before division: %d \n", data_reg_preB_mult);
			
			SRAM_address <= RGB_offset + index;
			SRAM_we_n <= 1'b0;
			SRAM_write_data <= {data_reg_G, data_reg_B};
			//SRAM_write_data <= {data_reg_G, 8'hAA};
			index <= index + 1'd1;
		
			
		//	$write("RGB[%d] => %d %d %d \n", (index-1), data_reg_R,data_reg_G,data_reg_B);
			
			
			u_7_counter <= u_7_counter + 2'd2;
			u_7_counter_less_one <= u_7_counter_less_one + 2'd2;
			u_7_odd_plus_seven <= u_7_counter_less_one + 2'd2 + 4'd5;
			modulo_317 <= modulo_317 + 2'd2;
		end
		
		
		S_M1_DELAY_1: begin
			M1_state <= S_M1_DELAY_2;
			
			
		//	$write(" S_M1_DELAY_1 \n");
		//	$write(" data_counter: %d\n", data_counter);
			
			// this address is setting the NEXT S_M1_LOAD_U read_data location
			
			// grab data for the next uEVEN. U[data_counter/2]
			//SRAM_address <= U_offset + data_counter - 1'b1;
			
			// divide data counter by 4
			SRAM_address <= U_offset + {2'b0, u_7_counter[17:2]} - 4'd0;
			SRAM_we_n <= 1'b1;			
		end
		
		S_M1_DELAY_2: begin
			M1_state <= S_M1_DELAY_3;
			
		//	$write(" S_M1_DELAY_2 \n");
			
			//SRAM_address <= V_offset + data_counter;
			// divide data counter by 2
			SRAM_address <= V_offset + {2'd0, u_7_counter[17:2]} - 4'd0;
			
		//	$write(" Just a test2: addr:%d => %d (%x hex)\n", SRAM_address, SRAM_read_data, SRAM_read_data);
			
			
			//u_7_counter <= u_7_counter + 2'd1;
		end
		
		S_M1_DELAY_3: begin
			M1_state <= S_M1_LOAD_U_EVEN;
			
		//	$write(" S_M1_DELAY_3 \n");
			
			//SRAM_address <= Y_offset + data_counter;
			//SRAM_address <= U_offset + u_7_counter;
			SRAM_address <= U_offset + {2'd0, u_7_odd_plus_seven[17:2]};
			
		
			
		//	$write(" Just a test3: addr:%d => %d (%x hex)\n", SRAM_address, SRAM_read_data, SRAM_read_data);
			
		end
		
		S_M1_LOAD_U_EVEN: begin
			M1_state <= S_M1_LOAD_V_EVEN;
			
		//	$write(" S_M1_LOAD_U_EVEN \n");
			
			//SRAM_address <= Y_offset + data_counter;
			
			// don't worry. address is from previous state!
			//SRAM_address <= V_offset + u_7_counter;
			SRAM_address <= V_offset + {2'd0, u_7_odd_plus_seven[17:2]};
			SRAM_we_n <= 1'b1;
			
			if (u_7_counter[1] == 1'd0) begin
				data_reg_uEven <= SRAM_read_data[15:8];
			end else begin
				data_reg_uEven <= SRAM_read_data[7:0];
			end
			
			
		end
		
		S_M1_LOAD_V_EVEN: begin
			M1_state <= S_M1_LOAD_U;
			
		//	$write(" S_M1_LOAD_V_EVEN \n");
			
			// this is correct now!!! 10:03 PM Saturday, November 16, 2013
			SRAM_address <= Y_offset + data_counter - 4'd3;
			
		//	$write(" Just a test5: addr:%d => %d (%x hex)\n", SRAM_address, SRAM_read_data, SRAM_read_data);
			//$write(" INDEX = %d \t data_counter = %d ; u_7_counter = %d \n", index, data_counter, u_7_counter);
			
			//data_reg_vEven <= SRAM_read_data[15:8];
			
			data_counter <= data_counter + 1'd1;
			
			
			if (u_7_counter[1] == 1'd0) begin
				data_reg_vEven <= SRAM_read_data[15:8];
			end else begin
				data_reg_vEven <= SRAM_read_data[7:0];
			end
			
		end
		
		
		
		S_M1_DONE: begin
			
			`ifdef SIMULATION
				$write("\n\nDONE MILESTONE 1 @ %t\n\n", $realtime);
			`endif
			
			milestone_done <= 1'b1;
			//M1_state <= S_M1_IDLE;
			M1_state <= S_M1_CLEANUP;


			SRAM_write_data <= 16'd0;
			SRAM_we_n <= 1'b1;
			data_reg_u5 <= 8'b0;
			data_reg_u4 <= 8'b0;
			data_reg_u3 <= 8'b0;
			data_reg_u2 <= 8'b0;
			data_reg_u1 <= 8'b0;
			data_reg_u0 <= 8'b0;
				
			data_reg_v5 <= 8'b0;
			data_reg_v4 <= 8'b0;
			data_reg_v3 <= 8'b0;
			data_reg_v2 <= 8'b0;
			data_reg_v1 <= 8'b0;
			data_reg_v0 <= 8'b0;
			
			data_reg_yEven <= 8'h00;
			data_reg_yOdd <= 8'h00;
			data_reg_uEven <= 8'h00;
			data_reg_uOdd <= 8'h00;
			data_reg_vEven <= 8'h00;
			data_reg_vOdd <= 8'h00;
			
			SRAM_address <= U_offset;		
			U_prime <= 8'hFF;			
			cc_first_round <= 1'b1;
			index <= 18'd0;
			data_counter <= 18'd0;
			u_7_counter <= 17'd0;
			u_7_counter_less_one <= 17'd1;
			u_7_odd_plus_seven <= 17'd1;
			
			modulo_317 <= 9'd1;
			
			data_reg_R_buffer <= 8'd0;

			//index <= 17'd0;
			SRAM_we_n <= 1'b1;
			SRAM_address <= V_offset;
			data_counter <= 1'd0; // next pair
			//SRAM_address <= 17'd0;
			
			// remember, u5 is our most significant reg (it gets newest data)
			data_reg_u5 <= 8'd000;
			data_reg_u4 <= 8'd000;
			data_reg_u3 <= 8'd000;
			data_reg_u2 <= 8'd000;
			data_reg_u1 <= 8'd000;
			data_reg_u0 <= 8'd000;
			
			data_reg_v5 <= 8'd000;
			data_reg_v4 <= 8'd000;
			data_reg_v3 <= 8'd000;
			data_reg_v2 <= 8'd000;
			data_reg_v1 <= 8'd000;
			data_reg_v0 <= 8'd000;
		end
		
		S_M1_CLEANUP: begin
			milestone_done <= 1'd0;
			
			M1_state <= S_M1_IDLE;
		end
				
		default: M1_state <= S_M1_IDLE;
		endcase
	end
end

always_comb begin
	
	Mult1_op_1 = 32'd0;
	Mult2_op_1 = 32'd0;
	Mult3_op_1 = 32'd0;
	Mult1_op_2 = 32'd0;
	Mult2_op_2 = 32'd0;
	Mult3_op_2 = 32'd0;
	
	data_reg_preR_mult = 32'd0;
	data_reg_preG_mult = 32'd0;
	data_reg_preB_mult = 32'd0;
	
	data_reg_preR = 16'd0;
	data_reg_preG = 16'd0;
	data_reg_preB = 16'd0;
	
	data_reg_FIR_result = 17'd0;
	
	data_reg_R = 8'd0;
	data_reg_G = 8'd0;
	data_reg_B = 8'd0;
	
	if (multiplier_mux == FIR_U) begin
		
		// doing the FIR filter multiplications for U'
		Mult1_op_1 = 32'd21;
		Mult1_op_2 = data_reg_u5 + data_reg_u0;
		
		Mult2_op_1 = 32'd52;
		Mult2_op_2 = data_reg_u4 + data_reg_u1;
		
		Mult3_op_1 = 32'd159;
		Mult3_op_2 = data_reg_u3 + data_reg_u2;
		
	//	$write(" FIR_U results: %d %d %d \n", Mult1_result, Mult2_result, Mult3_result);
		data_reg_FIR_result = Mult1_result - Mult2_result + Mult3_result + 8'd128;
	//	$write(" FIR_U data_reg_FIR_result: %d \n", data_reg_FIR_result);		
	end
	else if (multiplier_mux == FIR_V) begin
		// doing the FIR filter multiplications for V'
		Mult1_op_1 = 32'd21;
		Mult1_op_2 = data_reg_v5 + data_reg_v0;
		
		Mult2_op_1 = 32'd52;
		Mult2_op_2 = data_reg_v4 + data_reg_v1;
		
		Mult3_op_1 = 32'd159;
		Mult3_op_2 = data_reg_v3 + data_reg_v2;
		
	//	$write(" FIR_V results: %d %d %d \n", Mult1_result, Mult2_result, Mult3_result);
		data_reg_FIR_result = Mult1_result - Mult2_result + Mult3_result + 8'd128;
	//	$write(" FIR_V data_reg_FIR_result: %d \n", data_reg_FIR_result);
	end else if (multiplier_mux == COLOR_CONV) begin
		// COLOR_CONV
		// doing the colourspace conversions
		
		
		// *** these should actually just use U', V' (and we set them in states)
		
		// EVEN FIRST
		
		// we have two rounds of colourspace conversion
		if (cc_first_round == 2'b0) begin
			
			// even R
		
			// processing the first three multiplications
			Mult1_op_1 = 32'd76284;
		
			Mult1_op_2 = data_reg_yEven - 32'd16;
			
			Mult2_op_1 = 32'd104595;
			Mult2_op_2 = data_reg_vEven - 32'd128;
			
			Mult3_op_1 = 32'd25624;
			Mult3_op_2 = data_reg_uEven - 32'd128;
			
			// store this value because it's going to be used often
			//data_reg_CC_y_value = Mult1_result;
			
			data_reg_preR_mult = Mult1_result + Mult2_result;
			
		//	$write(" R value before division: %d \n", data_reg_preR_mult);
			
			// do the clipping and everything here?
			data_reg_preR = data_reg_preR_mult[31:16];
			data_reg_R = data_reg_preR[7:0];
			
		//	$write("*** data_reg_R from CC conv: %d\n", data_reg_R);
			
			// do some clipping
			if (|data_reg_preR_mult[30:24] == 1'b1) begin
				// value is above 255, so clip to 255
				data_reg_R = 8'd255;
			end
			if (data_reg_preR_mult[31] == 1'b1) begin
				// it's a negative number
				// clip to zero
				data_reg_R = 8'b0;
			end
			
		//	$write("*** clipped data_reg_R from CC conv: %d\n", data_reg_R);
		end else if (cc_first_round == 2'd1) begin
			// we're processing the last two multiplications 
			// also include the first G value again
			Mult1_op_1 = 32'd25624;
			Mult1_op_2 = data_reg_uEven - 32'd128;
			
			Mult2_op_1 = 32'd53281;
			Mult2_op_2 = data_reg_vEven - 32'd128;
			
			Mult3_op_1 = 32'd132251;
			Mult3_op_2 = data_reg_uEven - 32'd128;
			
			data_reg_preG_mult = data_reg_CC_y_value - Mult1_result - Mult2_result;
		//	$write(" G value before division: %d \n", data_reg_preG_mult);
			
			// do the clipping and everything here
			data_reg_preG = data_reg_preG_mult[31:16];
			data_reg_G = data_reg_preG[7:0];
			
		//	$write("*** data_reg_G from CC conv: %d\n", data_reg_G);
			
			// do some clipping
			if (|data_reg_preG_mult[30:24] == 1'b1) begin
				// value is above 255, so clip to 255
				data_reg_G = 8'd255;
			end
			if (data_reg_preG_mult[31] == 1'b1) begin
				// it's a negative number
				// clip to zero
				data_reg_G = 8'b0;
			end
			
		//	$write("*** clipped data_reg_G from CC conv: %d\n", data_reg_G);
			
			
			// now do the B values
			data_reg_preB_mult = data_reg_CC_y_value + Mult3_result;
		//	$write(" B value before division: %d \n", data_reg_preB_mult);
			
			// do the clipping and everything here
			data_reg_preB = data_reg_preB_mult[31:16];
			data_reg_B = data_reg_preB[7:0];
		//	$write("*** data_reg_B from CC conv: %d\n", data_reg_B);
			
			// do some clipping
			if (|data_reg_preB_mult[30:24] == 1'b1) begin
				// value is above 255, so clip to 255
				data_reg_B = 8'd255;
			end
			if (data_reg_preB_mult[31] == 1'b1) begin
				// it's a negative number
				// clip to zero
				data_reg_B = 8'b0;
			end
			
		//	$write("*** clipped data_reg_B from CC conv: %d (%x hex)\n", data_reg_B, data_reg_B);
			
		
		end else if (cc_first_round == 2'd2)  begin
			// ODD R
			
			// processing the first three multiplications
			Mult1_op_1 = 32'd76284;
			Mult1_op_2 = data_reg_yOdd - 32'd16;
			
			Mult2_op_1 = 32'd104595;
			Mult2_op_2 = V_prime_odd - 32'd128;
			
			Mult3_op_1 = 32'd25624;
			Mult3_op_2 = U_prime_odd - 32'd128;
			
			// store this value because it's going to be used often
			//data_reg_CC_y_value = Mult1_result;
			
			data_reg_preR_mult = Mult1_result + Mult2_result;
			
		//	$write(" R value before division: %d \n", data_reg_preR_mult);
			
			// do the clipping and everything here?
			data_reg_preR = data_reg_preR_mult[31:16];
			data_reg_R = data_reg_preR[7:0];
			
		//	$write("*** data_reg_R from CC conv: %d\n", data_reg_R);
			
			// do some clipping
			if (|data_reg_preR_mult[30:24] == 1'b1) begin
				// value is above 255, so clip to 255
				data_reg_R = 8'd255;
			end
			if (data_reg_preR_mult[31] == 1'b1) begin
				// it's a negative number
				// clip to zero
				data_reg_R = 8'b0;
			end
			
		end else if (cc_first_round == 2'd3)  begin
			
			// we're processing the last two multiplications 
			// also include the first G value again
			Mult1_op_1 = 32'd25624;
			Mult1_op_2 = U_prime_odd - 32'd128;
			
			Mult2_op_1 = 32'd53281;
			Mult2_op_2 = V_prime_odd - 32'd128;
			
			Mult3_op_1 = 32'd132251;
			Mult3_op_2 = U_prime_odd - 32'd128;
			
			data_reg_preG_mult = data_reg_CC_y_value - Mult1_result - Mult2_result;
		//	$write(" G value before division: %d \n", data_reg_preG_mult);
			
			// do the clipping and everything here
			data_reg_preG = data_reg_preG_mult[31:16];
			data_reg_G = data_reg_preG[7:0];
			
		//	$write("*** data_reg_G from CC conv: %d\n", data_reg_G);
			
			// do some clipping
			if (|data_reg_preG_mult[30:24] == 1'b1) begin
				// value is above 255, so clip to 255
				data_reg_G = 8'd255;
			end
			if (data_reg_preG_mult[31] == 1'b1) begin
				// it's a negative number
				// clip to zero
				data_reg_G = 8'b0;
			end
			
		//	$write("*** clipped data_reg_G from CC conv: %d\n", data_reg_G);
			
			
			// now do the B values
			data_reg_preB_mult = data_reg_CC_y_value + Mult3_result;
		//	$write(" B value before division: %d \n", data_reg_preB_mult);
			
			// do the clipping and everything here
			data_reg_preB = data_reg_preB_mult[31:16];
			//data_reg_B = data_reg_preB_mult[24:16];
			data_reg_B = data_reg_preB[7:0];
		//	$write("*** data_reg_B from CC conv: %d\n", data_reg_B);
			
			// do some clipping
			if (|data_reg_preB_mult[30:24] == 1'b1) begin
				// value is above 255, so clip to 255
				data_reg_B = 8'd255;
			end
			if (data_reg_preB_mult[31] == 1'b1) begin
				// it's a negative number
				// clip to zero
				data_reg_B = 8'b0;
			end	
		end
	end
end

assign Mult1_result_long = Mult1_op_1 * Mult1_op_2;
assign Mult1_result = Mult1_result_long[31:0];

assign Mult2_result_long = Mult2_op_1 * Mult2_op_2;
assign Mult2_result = Mult2_result_long[31:0];

assign Mult3_result_long = Mult3_op_1 * Mult3_op_2;
assign Mult3_result = Mult3_result_long[31:0];


endmodule
