/*
*
*	3DQ5 Project 2013:
*	Hardware Implementation of an Image Decompressor
*	
*	Milestone 3
*	
*	
*/


`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

//
module milestone_3 (
	
	input	logic Clock_50,
	input	logic Resetn,
	
	input	logic milestone_start,
	output	logic milestone_done,
	
	input	logic	[15:0]	SRAM_read_data,
	output	logic	[17:0]	SRAM_address,
	output	logic	[15:0]	SRAM_write_data,
	output	logic			SRAM_we_n
		
);

m3_state_type M3_state;

logic [17:0] Y_offset = 18'd0;
logic [17:0] U_offset = 18'd38400;
logic [17:0] V_offset = 18'd57600;
logic [17:0] IDCT_offset = 18'd76800;
logic [17:0] IDCT_U_offset = 18'd153600;
logic [17:0] IDCT_V_offset = 18'd192000;

// Instantiate RAM2
/*
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
*/


always_ff @ (posedge Clock_50 or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		M3_state <= S_M3_IDLE;
		
		milestone_done <= 1'b0;
		
		
	end else begin
		case (M3_state)
		S_M3_IDLE: begin
			
			
			if ((milestone_start == 1'b1) && (milestone_done == 1'b0)) begin
				M3_state <= S_M3_START;
				
				`ifdef SIMULATION
					$write("START of Milestone 3 @ %t\n", $realtime);
				`endif
			end
		end
		
		
		S_M3_START: begin
			M3_state <= S_M3_DONE;
			
		end
		
		
		
		
		
		
		
		
		
		
		
		S_M3_DONE: begin
			M3_state <= S_M3_IDLE;
			
			`ifdef SIMULATION
				$write("\n\nDONE MILESTONE 3 @ %t\n\n", $realtime);
			`endif
			
			milestone_done <= 1'b1;
		end
		
		
		
		default: M3_state <= S_M3_IDLE;
		endcase
	end
end

endmodule
