`define VectorSize 32

`define ICACHE_SIZE_BIT 3

`define ROB_WIDTH_BIT 5
`define ROB_WIDTH (1 << `ROB_WIDTH_BIT)

`define RS_TYPE_BIT 5 
`define RS_SIZE_BIT 3

`define LS_TYPE_BIT 4
`define LSB_SIZE_BIT 3

`define ROB_TYPE_BIT 2
`define ROB_TYPE_RG 2'b00
`define ROB_TYPE_ST 2'b01
`define ROB_TYPE_BR 2'b10
`define ROB_TYPE_EX 2'b11
