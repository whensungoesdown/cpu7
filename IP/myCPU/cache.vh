`include "tlb_defines.vh"

`define SCWAY_LEN    4

`define STATE_LEN     2
`define STATE_I          2'b00
`define STATE_S          2'b01
`define STATE_E          2'b10
`define STATE_D          2'b11


// icache
  //icache
`define INST_OUT_NUM         4
`define INST_OUT_LEN         128

`ifdef LA64
  `define I_LINE_SIZE_b      512    // bit
  `define I_OFFSET_LEN       4
  `define I_INDEX_LEN        7
  `define I_IO_WDATA_LEN    (64 * `I_BANK_NUM)
  //`define I_BANK_BITS       5 : 3 
  `define BUS_DATA_WIDTH     128
`elsif LA32
  `define I_LINE_SIZE_b      256    // bit
  `define I_OFFSET_LEN       3
  `define I_INDEX_LEN        8
  `define I_IO_WDATA_LEN    (32 * `I_BANK_NUM)
  //`define I_BANK_BITS       4 : 2
  `define BUS_DATA_WIDTH     64
`endif

`define LINE_INST_NUM       (1 << `I_OFFSET_LEN)
`define RFIL_RECORD_LEN     (`I_LINE_SIZE_b / `BUS_DATA_WIDTH)

  // Bank
`define I_BANK_NUM           8

  // offset
`define I_OFFSET_BITS       `I_OFFSET_LEN + 1 : 2

  // way
`define I_WAY_NUM4
`ifdef I_WAY_NUM4
  `define I_WAY_LEN          2
`endif
`define I_WAY_NUM           (1 << `I_WAY_LEN)
`define I_WAY_BITS          `I_WAY_LEN - 1 : 0

  // index
`define I_SET_NUM           (1 << `I_INDEX_LEN)
`define I_INDEX_BITS        `I_INDEX_LEN + `I_OFFSET_LEN + 1 : `I_OFFSET_LEN + 2

  // tag
`define I_TAG_LEN           (`PABITS - 12)  // bit
`define I_TAG_BITS           `PABITS-1 : 12

`define I_TAGARRAY_LEN      (`STATE_LEN + `SCWAY_LEN + `I_TAG_LEN)

`define LINE_PADDR_LEN      (`PABITS - `I_OFFSET_LEN - 2)

  // replace
`define I_LRU_REPLACE
`ifdef I_WAY_NUM4
  `define I_LRU_WIDTH        6
`endif

`define I_WORD0_BITS          31 :   0
`define I_WORD1_BITS          63 :  32
`define I_WORD2_BITS          95 :  64
`define I_WORD3_BITS         127 :  96
`define I_WORD4_BITS         159 : 128
`define I_WORD5_BITS         191 : 160
`define I_WORD6_BITS         223 : 192
`define I_WORD7_BITS         255 : 224
`define I_WORD8_BITS         287 : 256
`define I_WORD9_BITS         319 : 288
`define I_WORD10_BITS        351 : 320
`define I_WORD11_BITS        383 : 352
`define I_WORD12_BITS        415 : 384
`define I_WORD13_BITS        447 : 416
`define I_WORD14_BITS        479 : 448
`define I_WORD15_BITS        511 : 480

// IO
`define I_IO_TAG_LEN        (`I_TAGARRAY_LEN << `I_WAY_LEN)
`define I_IO_EN_LEN         (`I_BANK_NUM << `I_WAY_LEN)
`define I_IO_RDATA_LEN      (`I_LINE_SIZE_b << `I_WAY_LEN)


// DCache
`ifdef LA64
  `define DATA_LEN           3
  `define D_INDEX_LEN        7
`elsif LA32
  `define DATA_LEN           2
  `define D_INDEX_LEN        8
`endif

`define WSTRB_WIDTH         (1 << `DATA_LEN)
`define D_LINE_SIZE_b       (`GRLEN  << 3)
`define D_LINE_LEN          (`D_BANK_LEN + `D_OFFSET_LEN)

  // OFFSET
`define D_OFFSET_LEN        `DATA_LEN
`define D_OFFSET_BITS       `DATA_LEN - 1 :0

  // Bank
`define D_BANK_LEN           3
`define D_BANK_NUM          (1 << `D_BANK_LEN)
`define D_BANK_BITS         `D_BANK_LEN + `DATA_LEN - 1  : `DATA_LEN

  // INDEX
`define D_SET_NUM           (1 << `D_INDEX_LEN)
`define D_INDEX_BITS        `D_INDEX_LEN + `D_BANK_LEN + `DATA_LEN - 1 : `D_BANK_LEN + `DATA_LEN

  // TAG
`define D_TAG_LEN           (`PABITS - 12)
`define D_TAG_BITS          `PABITS-1 : 12

`define D_TAGARRAY_LEN      (`STATE_LEN + `SCWAY_LEN + `D_TAG_LEN)

  // WAY
//`define D_WAY_NUM1
//`define D_WAY_NUM2
`define D_WAY_NUM4

`ifdef D_WAY_NUM1
  `define D_WAY_LEN 0
`endif

`ifdef D_WAY_NUM2
  `define D_WAY_LEN 1
`endif

`ifdef D_WAY_NUM4
  `define D_WAY_LEN 2
`endif

`define D_WAY_NUM            (1 << `D_WAY_LEN)
`define D_WAY_BITS           `D_WAY_LEN - 1 : 0

  // replace algorithm
`define D_LRU_REPLACE
`ifdef D_WAY_NUM4
  `define D_LRU_WIDTH         6
`endif

`define D_LRU_BITS           `D_LRU_WIDTH-1:0
`define D_DIRTY_BITS         `D_WAY_NUM + `D_LRU_WIDTH-1:`D_LRU_WIDTH
`define D_LRUD_WIDTH         (`D_LRU_WIDTH + `D_WAY_NUM)

  // MSHR
`define D_MSHR_ENTRY4

`ifdef D_MSHR_ENTRY4
  `define MSHR_NUM_LEN        2
  `define D_MSHR_ENTRY_NUM    4
`endif

`define MSHR_PADDR_LEN       (`PABITS-`DATA_LEN)
`define MSHR_WSTRB_LEN       (`D_LINE_SIZE_b / 8)
`define MSHR_RECORD_LEN      (`D_LINE_SIZE_b / `BUS_DATA_WIDTH)

  // ATOM
`define ATOM_WEN_LEN         (`D_LINE_SIZE_b / 32)

  // RAM SIGNAL
`define D_RAM_TAG_LEN        (`D_TAGARRAY_LEN << `D_WAY_LEN)

`define D_RAM_EN_LEN         (`D_BANK_NUM     << `D_WAY_LEN)
`define D_RAM_WEN_LEN        (`WSTRB_WIDTH    << `D_WAY_LEN)
`define D_RAM_ADDR_LEN       (`D_INDEX_LEN    *  `D_BANK_NUM  )
`define D_RAM_WDATA_LEN      (`GRLEN          *  `D_BANK_NUM  )
`define D_RAM_RDATA_LEN      (`D_LINE_SIZE_b  << `D_WAY_LEN)

// cache inst
`define IDX_ST_TAG            0   // I & D
`define IDX_INV               1   // I
`define IDX_INV_WB            1   // D
`define HIT_INV               2   // I
`define HIT_INV_WB            2   // D

// external req
`define EX_OP_WIDTH           3
`define INV_WTBK              0
`define WTBK                  1
`define INV                   2

`define BANK0_BITS           `GRLEN * 1 - 1 : `GRLEN * 0
`define BANK1_BITS           `GRLEN * 2 - 1 : `GRLEN * 1
`define BANK2_BITS           `GRLEN * 3 - 1 : `GRLEN * 2
`define BANK3_BITS           `GRLEN * 4 - 1 : `GRLEN * 3
`define BANK4_BITS           `GRLEN * 5 - 1 : `GRLEN * 4
`define BANK5_BITS           `GRLEN * 6 - 1 : `GRLEN * 5
`define BANK6_BITS           `GRLEN * 7 - 1 : `GRLEN * 6
`define BANK7_BITS           `GRLEN * 8 - 1 : `GRLEN * 7


// miss queue
`define Q_ITEM_BIT            3
`define Q_ITEM_NUM           (1 << `Q_ITEM_BIT)

// victim buffer
`define VIC_ITEM2
`ifdef VIC_ITEM2
  `define VIC_ITEM_BIT        1
`endif
`define VIC_ITEM_NUM         (1 << `VIC_ITEM_BIT)

`define VIC_RECORD_LEN       (`D_LINE_SIZE_b / `BUS_DATA_WIDTH)

`define WR_FMT_LEN            4
`define WR_FMT_ALLLINE        4'b0001
`define WR_FMT_EXTINV         4'b0010
`define WR_FMT_UNCACHE        4'b1000

// prefetch
`define PRE_REQ_QLEN           8
`define PRE_WAY_NUM            4
`define PRE_PC_REF_LEN        10
`define PRE_PC_INDEX_LEN       4
`define PRE_STRIDE_LEN         5


// axi
//4'b1100—Request Read
//4'b1101—Request Write
//4'b0000—Scache Index Invalidate and Writeback
//4'b0101—Scache Hit   Invalidate and Writeback
`define ARCMD_REQREAD          4'b1100
`define ARCMD_REQWRITE         4'b1101
`define ARCMD_SCIDXINVWTBK     4'b0000
`define ARCMD_SCHITINVWTBK     4'b0101

//4'b0010-Scache Index Store Tag
//4'b1000-Response to Invalidate & Writeback ext req
//4'b1001-Response to Writeback  ext req
//4'b1010-Response to Invalidate ext req
//4'b1111-Cache Replace
`define AWCMD_SCIDXSTAG        4'b0010
`define AWCMD_INVWTBK          4'b1000
`define AWCMD_WTBK             4'b1001
`define AWCMD_INV              4'b1010
`define AWCMD_RPLC             4'b1111


`define ATOM_OP_WIDTH                   5

`define PIPELINE2DCACHE_BUS_WIDTH      (1+1+`WSTRB_WIDTH+`GRLEN+`GRLEN+1+1+1+1+`GRLEN+1+1+1+`ATOM_OP_WIDTH+`GRLEN)
`define PIPELINE2DCACHE_BUS_REQ         0
`define PIPELINE2DCACHE_BUS_WR          1
`define PIPELINE2DCACHE_BUS_WSTRB      `WSTRB_WIDTH + 1 :  2
`define PIPELINE2DCACHE_BUS_ADDR       `WSTRB_WIDTH + `GRLEN * 1 + 1 : `WSTRB_WIDTH + 2
`define PIPELINE2DCACHE_BUS_WDATA      `WSTRB_WIDTH + `GRLEN * 2 + 1 : `WSTRB_WIDTH + `GRLEN * 1 + 2
`define PIPELINE2DCACHE_BUS_RECV       `WSTRB_WIDTH + `GRLEN * 2 + 2
`define PIPELINE2DCACHE_BUS_CANCEL     `WSTRB_WIDTH + `GRLEN * 2 + 3
`define PIPELINE2DCACHE_BUS_EX2CANCEL  `WSTRB_WIDTH + `GRLEN * 2 + 4
`define PIPELINE2DCACHE_BUS_PREFETCH   `WSTRB_WIDTH + `GRLEN * 2 + 5
`define PIPELINE2DCACHE_BUS_PC         `WSTRB_WIDTH + `GRLEN * 3 + 5 : `WSTRB_WIDTH + `GRLEN * 2 + 6
`define PIPELINE2DCACHE_BUS_LL         `WSTRB_WIDTH + `GRLEN * 3 + 6
`define PIPELINE2DCACHE_BUS_SC         `WSTRB_WIDTH + `GRLEN * 3 + 7
`define PIPELINE2DCACHE_BUS_ATOM       `WSTRB_WIDTH + `GRLEN * 3 + 8
`define PIPELINE2DCACHE_BUS_ATOMOP     `WSTRB_WIDTH + `GRLEN * 3 + `ATOM_OP_WIDTH + 8 : `WSTRB_WIDTH + `GRLEN * 3 + 9
`define PIPELINE2DCACHE_BUS_ATOMSRC    `WSTRB_WIDTH + `GRLEN * 4 + `ATOM_OP_WIDTH + 8 : `WSTRB_WIDTH + `GRLEN * 3 + `ATOM_OP_WIDTH + 9


`define DCACHE2PIPELINE_BUS_WIDTH       (1+1+`GRLEN+1+6+`GRLEN+1+1)
`define DCACHE2PIPELINE_BUS_ADDROK       0
`define DCACHE2PIPELINE_BUS_DATAOK       1
`define DCACHE2PIPELINE_BUS_RDATA       `GRLEN + 1     :  2
`define DCACHE2PIPELINE_BUS_EXCEPTION   `GRLEN + 2
`define DCACHE2PIPELINE_BUS_EXCCODE     `GRLEN + 8     : `GRLEN + 3
`define DCACHE2PIPELINE_BUS_BADVADDR    `GRLEN * 2 + 8 : `GRLEN + 9
`define DCACHE2PIPELINE_BUS_REQEMPTY    `GRLEN * 2 + 9
`define DCACHE2PIPELINE_BUS_SCSUCCEED   `GRLEN * 2 + 10