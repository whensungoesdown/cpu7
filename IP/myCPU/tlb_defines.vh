`define TEST_TLB 1

//`define LA64
`define LA32

`ifdef LA64
  `define GRLEN        64
  `define VABITS       48
  `define PABITS       40
`elsif LA32
  `define GRLEN        32
  `define VABITS       32
  `define PABITS       32
`endif

`define TLB_IDXBITS    5
`define TLB_ENTRIES   (1<<`TLB_IDXBITS)

`define PFNBITS    (`PABITS-8)
`define VPNBITS    (`VABITS-13)