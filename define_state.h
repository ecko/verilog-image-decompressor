`ifndef DEFINE_STATE

// This defines the states
typedef enum logic [2:0] {
	S_IDLE,
	S_ENABLE_UART_RX,
	S_WAIT_UART_RX,

	S_DUMMY,
	S_DELAY_START_M1,
	
	S_START_M1,
	S_START_M2


} top_state_type;

// milestone states
typedef enum logic [5:0] {
	S_M1_IDLE,
	S_M1_START,
	
	S_M1_CLEANUP,
	S_M1_DONE,
	
	S_M1_START_DELAY_1,
	S_M1_START_DELAY_2,
	
	S_M1_LEAD_IN_1,
	S_M1_LEAD_IN_2,
	S_M1_LEAD_IN_3,
	S_M1_LEAD_IN_4,
	
	S_M1_TRANSITION,
	
	S_M1_CC_FIRST_SET_CALCULATED,
	S_M1_CC_SECOND_SET_CALCULATED,
	
	S_M1_TEST2,
	S_M1_TEST3,
	
	
	S_M1_DELAY_1,
	S_M1_DELAY_2,
	S_M1_DELAY_3,
	
	S_M1_DELAY_4,
	S_M1_DELAY_5,
	
	S_M1_RESTART,
	S_M1_LOAD_U_EVEN,
	S_M1_LOAD_U_ODD,
	S_M1_SET_U,
	S_M1_LOAD_V_EVEN,
	S_M1_LOAD_V_ODD,
	S_M1_SET_V,
	S_M1_LOAD_Y,
	S_M1_LOAD_U,
	
	S_M1_LOAD_V,
	
	
	S_M1_LOAD_G_EVEN,
	S_M1_LOAD_BR_EVEN,
	S_M1_WRITE_RG_EVEN,
	S_M1_LOAD_R_ODD,
	S_M1_WRITE_BR_MIXED,
	S_M1_LOAD_G_ODD,
	S_M1_LOAD_B_ODD,
	S_M1_WRITE_GB_ODD,
	
	S_M1_BORDER_1,
	S_M1_BORDER_1_2,
	S_M1_BORDER_2,
	S_M1_BORDER_3,
	S_M1_BORDER_4,
	S_M1_BORDER_5,
	S_M1_BORDER_6
	
	
	
} m1_state_type;

typedef enum logic [6:0] {
	S_M2_IDLE,
	S_M2_START,
	
	
	S_M2_START_DELAY_1,
	S_M2_READ_S_PRIME,
	S_M2_READ_S_PRIME_1,
	S_M2_READ_S_PRIME_2,
	
	S_M2_WRITE_IDCT_SRAM_START,
	S_M2_WRITE_IDCT_SRAM_DELAY_1,
	S_M2_WRITE_IDCT_SRAM_DELAY_2,
	
	S_M2_CALC_T_START,
	S_M2_CALC_T_1,
	S_M2_CALC_T_DELAY,
	
	S_CT_init,
	S_CT_0,
	S_CT_1,
	S_CT_2,
	S_CT_3,
	S_CT_4,
	S_CT_5,
	S_CT_6,
	S_CT_7,
	S_CT_8,
	S_CT_9,
	S_CT_10,
	S_CT_11,
	
	S_CT_0_DELAY,
	S_CT_READ_T,
	S_CT_READ_DELAY,
	
	S_S_init,
	S_S_0_DELAY,
	S_S_0,
	S_S_1,
	S_S_2,
	S_S_3,
	S_S_4,
	S_S_5,
	S_S_6,
	S_S_7,
	S_S_8,
	S_S_9,
	S_S_10,
	S_S_11,
	
	S_S_READ_T,
	S_S_READ_DELAY,
	
	S_M2_READ_S_PRIME_END1,
	S_M2_READ_S_PRIME_END2,
	S_M2_READ_S_PRIME_END3,
	S_M2_READ_S_PRIME_END4,
	S_M2_READ_S_PRIME_END5,
	
	
	S_M2_WRITE_S_INIT,
	S_M2_WRITE_S_DELAY_1,
	S_M2_WRITE_S_DELAY_2,
	S_M2_WRITE_S_2,
	S_M2_WRITE_S_SRAM,
	
	TEMP_DELAY,
	
	S_PRINT_S_PRIME,
	S_PRINT_S_PRIME_1,
	S_PRINT_S_PRIME_3,
	
	S_M2_JUMP_BACK_DELAY,
	S_M2_JUMP_BACK_DELAY_2,
	
	S_M2_JUMP_BACK_START,
	
	S_M2_READ_S_PRIME_3,
	S_M2_READ_S_PRIME_4,
	S_M2_READ_S_PRIME_5,
	S_M2_READ_S_PRIME_6,
	S_M2_READ_S_PRIME_7,
	S_M2_READ_S_PRIME_WRITE,
	
	
	S_S_PRE_9,
	S_CT_PRE_9,
	
	
	S_M2_CLEANUP,
	S_M2_DONE
	
} m2_state_type;

typedef enum logic [2:0] {
	S_M3_IDLE,
	S_M3_START,
	
	S_M3_DONE
	
} m3_state_type;


typedef enum logic [1:0] {
	FIR_U,
	FIR_V,
	COLOR_CONV
} M1_Multiplier_Mux_type;



typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

`define DEFINE_STATE 1
`endif
