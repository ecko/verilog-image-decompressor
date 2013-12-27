

# add waves to waveform
add wave Clock_50
add wave -divider {some label for my divider}
add wave uut/SRAM_we_n
add wave -decimal uut/SRAM_write_data
add wave -decimal uut/SRAM_read_data
add wave -hexadecimal uut/SRAM_address

add wave uut/M1_unit/M1_state

#add wave uut/M2_unit/SRAM_address

#add wave -divider {some label for my divider}
#add wave uut/M2_unit/address_a
#add wave uut/M2_unit/address_b
#add wave uut/M2_unit/write_enable_a
#add wave uut/M2_unit/write_enable_b
#add wave uut/M2_unit/write_data_a
#add wave uut/M2_unit/write_data_b

#add wave uut/M2_unit/read_data_a
#add wave uut/M2_unit/read_data_b


