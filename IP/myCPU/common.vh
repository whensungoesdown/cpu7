//
// `define GS264C_64BIT
`include "tlb_defines.vh"


// Coprocessor 0 Registers
`define LSOC1K_CSR_BIT           14
`define LSOC1K_CSR_CRMD          `LSOC1K_CSR_BIT'h0_0_0_0
`define LSOC1K_CSR_PRMD          `LSOC1K_CSR_BIT'h0_0_0_1
`define LSOC1K_CSR_EUEN          `LSOC1K_CSR_BIT'h0_0_0_2
`define LSOC1K_CSR_MISC          `LSOC1K_CSR_BIT'h0_0_0_3  //
`define LSOC1K_CSR_ECTL          `LSOC1K_CSR_BIT'h0_0_0_4
`define LSOC1K_CSR_ESTAT         `LSOC1K_CSR_BIT'h0_0_0_5  //
`define LSOC1K_CSR_EPC           `LSOC1K_CSR_BIT'h0_0_0_6
`define LSOC1K_CSR_BADV          `LSOC1K_CSR_BIT'h0_0_0_7
`define LSOC1K_CSR_BADI          `LSOC1K_CSR_BIT'h0_0_0_8
`define LSOC1K_CSR_EBASE         `LSOC1K_CSR_BIT'h0_0_0_C
`define LSOC1K_CSR_INDEX         `LSOC1K_CSR_BIT'h0_0_1_0
`define LSOC1K_CSR_TLBEHI        `LSOC1K_CSR_BIT'h0_0_1_1
`define LSOC1K_CSR_TLBELO0       `LSOC1K_CSR_BIT'h0_0_1_2
`define LSOC1K_CSR_TLBELO1       `LSOC1K_CSR_BIT'h0_0_1_3
`define LSOC1K_CSR_ASID          `LSOC1K_CSR_BIT'h0_0_1_8
`define LSOC1K_CSR_PGDL          `LSOC1K_CSR_BIT'h0_0_1_9
`define LSOC1K_CSR_PGDH          `LSOC1K_CSR_BIT'h0_0_1_A
`define LSOC1K_CSR_PGD           `LSOC1K_CSR_BIT'h0_0_1_B
`define LSOC1K_CSR_PWCL          `LSOC1K_CSR_BIT'h0_0_1_C
`define LSOC1K_CSR_PWCH          `LSOC1K_CSR_BIT'h0_0_1_D
`define LSOC1K_CSR_STLBPS        `LSOC1K_CSR_BIT'h0_0_1_E
`define LSOC1K_CSR_RVACFG        `LSOC1K_CSR_BIT'h0_0_1_F
`define LSOC1K_CSR_CPUNUM        `LSOC1K_CSR_BIT'h0_0_2_0
`define LSOC1K_CSR_PRCFG1        `LSOC1K_CSR_BIT'h0_0_2_1
`define LSOC1K_CSR_PRCFG2        `LSOC1K_CSR_BIT'h0_0_2_2
`define LSOC1K_CSR_PRCFG3        `LSOC1K_CSR_BIT'h0_0_2_3
`define LSOC1K_CSR_SAVE0         `LSOC1K_CSR_BIT'h0_0_3_0
`define LSOC1K_CSR_SAVE1         `LSOC1K_CSR_BIT'h0_0_3_1
`define LSOC1K_CSR_SAVE2         `LSOC1K_CSR_BIT'h0_0_3_2
`define LSOC1K_CSR_SAVE3         `LSOC1K_CSR_BIT'h0_0_3_3
`define LSOC1K_CSR_SAVE4         `LSOC1K_CSR_BIT'h0_0_3_4
`define LSOC1K_CSR_SAVE5         `LSOC1K_CSR_BIT'h0_0_3_5
`define LSOC1K_CSR_SAVE6         `LSOC1K_CSR_BIT'h0_0_3_6
`define LSOC1K_CSR_SAVE7         `LSOC1K_CSR_BIT'h0_0_3_7
`define LSOC1K_CSR_TID           `LSOC1K_CSR_BIT'h0_0_4_0
`define LSOC1K_CSR_TCFG          `LSOC1K_CSR_BIT'h0_0_4_1
`define LSOC1K_CSR_TVAL          `LSOC1K_CSR_BIT'h0_0_4_2
`define LSOC1K_CSR_CNTC          `LSOC1K_CSR_BIT'h0_0_4_3
`define LSOC1K_CSR_TICLR         `LSOC1K_CSR_BIT'h0_0_4_4
`define LSOC1K_CSR_LLBCTL        `LSOC1K_CSR_BIT'h0_0_6_0
`define LSOC1K_CSR_IMPCTL1       `LSOC1K_CSR_BIT'h0_0_8_0 //
`define LSOC1K_CSR_IMPCTL2       `LSOC1K_CSR_BIT'h0_0_8_1 //
`define LSOC1K_CSR_TLBREBASE     `LSOC1K_CSR_BIT'h0_0_8_8
`define LSOC1K_CSR_TLBRBADV      `LSOC1K_CSR_BIT'h0_0_8_9
`define LSOC1K_CSR_TLBREPC       `LSOC1K_CSR_BIT'h0_0_8_A
`define LSOC1K_CSR_TLBRSAVE      `LSOC1K_CSR_BIT'h0_0_8_B
`define LSOC1K_CSR_TLBRELO0      `LSOC1K_CSR_BIT'h0_0_8_C //
`define LSOC1K_CSR_TLBRELO1      `LSOC1K_CSR_BIT'h0_0_8_D //
`define LSOC1K_CSR_TLBREHI       `LSOC1K_CSR_BIT'h0_0_8_E
`define LSOC1K_CSR_TLBRPRMD      `LSOC1K_CSR_BIT'h0_0_8_F
`define LSOC1K_CSR_ERRCTL        `LSOC1K_CSR_BIT'h0_0_9_0
`define LSOC1K_CSR_ERRINFO1      `LSOC1K_CSR_BIT'h0_0_9_1
`define LSOC1K_CSR_ERRINFO2      `LSOC1K_CSR_BIT'h0_0_9_2
`define LSOC1K_CSR_ERREBASE      `LSOC1K_CSR_BIT'h0_0_9_3
`define LSOC1K_CSR_ERREPC        `LSOC1K_CSR_BIT'h0_0_9_4
`define LSOC1K_CSR_ERRSAVE       `LSOC1K_CSR_BIT'h0_0_9_5
`define LSOC1K_CSR_CTAG          `LSOC1K_CSR_BIT'h0_0_9_8 //
`define LSOC1K_CSR_DMW0          `LSOC1K_CSR_BIT'h0_1_8_0
`define LSOC1K_CSR_DMW1          `LSOC1K_CSR_BIT'h0_1_8_1
`define LSOC1K_CSR_PMCFG0        `LSOC1K_CSR_BIT'h0_2_0_0
`define LSOC1K_CSR_PMCNT0        `LSOC1K_CSR_BIT'h0_2_0_1

`define LSOC1K_CSR_DBG           `LSOC1K_CSR_BIT'h0_5_0_0 //
`define LSOC1K_CSR_DEPC          `LSOC1K_CSR_BIT'h0_5_0_1 //
`define LSOC1K_CSR_DSAVE         `LSOC1K_CSR_BIT'h0_5_0_2 //

// self defined
`define LSOC1K_CSR_BSEC          `LSOC1K_CSR_BIT'h0_1_0_0 //

//CPUNUM
`define COREID_WIDTH        9
`define CPU_COREID          9'h0

// TLB parameters
`define TLB_ENTRIES_DEC     10'd544

// Modified begin
`define VADDR_EXTEND_BITS   63:48

//// CSR
// CRMD 0x0_0_0
`define CRMD_WE    9
`define CRMD_DATM  8:7
`define CRMD_DATF  6:5
`define CRMD_PG    4
`define CRMD_DA    3
`define CRMD_IE    2
`define CRMD_PLV   1:0

// CRMD 0x0_0_1
`define LSOC1K_PRMD_PWE    3
`define LSOC1K_PRMD_PIE    2
`define LSOC1K_PRMD_PPLV   1:0

// EUEN 0x0_0_2
`define LSOC1K_EUEN_BTE    3
`define LSOC1K_EUEN_ASXE   2
`define LSOC1K_EUEN_SXE    1
`define LSOC1K_EUEN_FPE    0

// MISC 0x0_0_3
`define LSOC1K_MISC_DWPL2    18
`define LSOC1K_MISC_DWPL1    17
`define LSOC1K_MISC_DWPL0    16
`define LSOC1K_MISC_ALCL3    15
`define LSOC1K_MISC_ALCL2    14
`define LSOC1K_MISC_ALCL1    13
`define LSOC1K_MISC_ALCL0    12
`define LSOC1K_MISC_RPCNTL3  11
`define LSOC1K_MISC_RPCNTL2  10
`define LSOC1K_MISC_RPCNTL1   9
`define LSOC1K_MISC_DRDTL3    7
`define LSOC1K_MISC_DRDTL2    6
`define LSOC1K_MISC_DRDTL1    5
`define LSOC1K_MISC_VA32L3    3
`define LSOC1K_MISC_VA32L2    2
`define LSOC1K_MISC_VA32L1    1

// ECTL 0x0_0_4
`define LSOC1K_ECTL_VS  18:16
`define LSOC1K_ECTL_LIE 12:0

// ESTAT 0x0_0_5
`define LSOC1K_ESTAT_ESUBCODE 30:22
`define LSOC1K_ESTAT_ECODE    21:16
`define LSOC1K_ESTAT_IS       12: 2
`define LSOC1K_ESTAT_SIS       1: 0

// BADI 0x0_0_8
`define LSOC1K_BADI_INST 31:0

// EBASE 0x0_0_C
`ifdef LA64
`define LSOC1K_EBASE_EBASE 63:12
`elsif LA32
`define LSOC1K_EBASE_EBASE 31:6
`endif

// INDEX 0x0_1_0
`define LSOC1K_INDEX_NP    31
`define LSOC1K_INDEX_PS    29:24
`define LSOC1K_INDEX_INDEX `TLB_IDXBITS-1: 0

// ENTRYHI 0x0_1_1
`define LSOC1K_TLBEHI_VPN2 `VABITS-1:13

// csr 0x12/0x13 EntryLo0, EntryLo1
`define LSOC1K_TLBELO_RPLV         63
`define LSOC1K_TLBELO_NX           62
`define LSOC1K_TLBELO_NR           61
`ifdef GS264C_64BIT
  `define LSOC1K_TLBELO_PFN        `PABITS-1:12
`else
  `define LSOC1K_TLBELO_PFN        31:8
`endif
`define LSOC1K_TLBELO_G            6
`define LSOC1K_TLBELO_MAT          5: 4
`define LSOC1K_TLBELO_PLV          3: 2
`define LSOC1K_TLBELO_WE           1
`define LSOC1K_TLBELO_V            0

// ASID 0x0_1_8  
`define LSOC1K_ASID_ASIDBITS       23:16
`define LSOC1K_ASID_ASID            9: 0

// PGDL 0x0_1_9
`define LSOC1K_PGDL_BASE `GRLEN-1:12

// PGDH 0x0_1_A
`define LSOC1K_PGDH_BASE `GRLEN-1:12

// PGD 0x0_1_B
`define LSOC1K_PGD_BASE  `GRLEN-1:12

// PWCL 0x0_1_C 
`define LSOC1K_PWCL_PTBASE      4: 0
`define LSOC1K_PWCL_PTWIDTH     9: 5
`define LSOC1K_PWCL_DIR1_BASE  14:10
`define LSOC1K_PWCL_DIR1_WIDTH 19:15
`define LSOC1K_PWCL_DIR2_BASE  24:20
`define LSOC1K_PWCL_DIR2_WIDTH 29:25
`define LSOC1K_PWCL_PTEWIDTH   31:30

// PWCH 0x0_1_D
`define LSOC1K_PWCH_PTBASE      4: 0
`define LSOC1K_PWCH_PTWIDTH     9: 5
`define LSOC1K_PWCH_DIR1_BASE  14:10
`define LSOC1K_PWCH_DIR1_WIDTH 19:15
`define LSOC1K_PWCH_DIR2_BASE  24:20
`define LSOC1K_PWCH_DIR2_WIDTH 29:25
`define LSOC1K_PWCH_PTEWIDTH   31:30

// FTLB PageSize 0x0_1_E
`define LSOC1K_STLBPS_PS      5: 0

// RVACFG 0x0_1_F
`define LSOC1K_RVACFG_RBITS     3: 0

// CPUNUM 0x0_2_0
`define LSOC1K_CPUNUM_COREID    8: 0

// PRCFG1 0x0_2_1
`define LSOC1K_PRCFG1_SAVENUM   3 : 0
`define LSOC1K_PRCFG1_TIMERBITS 11: 4
`define LSOC1K_PRCFG1_VSMAX     14:12

// PRCFG2 0x0_2_2

// PRCFG3 0x0_2_3
`define LSOC1K_PRCFG3_TLBTYPE     3 : 0
`define LSOC1K_PRCFG3_MTLBENTRIES 11: 4
`define LSOC1K_PRCFG3_STLBWAYS    19:12
`define LSOC1K_PRCFG3_STLBSETS    25:20

// TID 0x0_4_0
`define LSOC1K_TID_TID 31:0

// TCFG 0x0_4_1
`define LSOC1K_TCFG_EN       0
`define LSOC1K_TCFG_PERIODIC 1
`define LSOC1K_TCFG_INITVAL  `GRLEN-1:2

// TVAL 0x0_4_2
`define LSOC1K_TVAL_TIMEVAL `GRLEN-1:0

// CNTC 0x0_4_3
`define LSOC1K_CNTC_COMPENSATION 63:0

// TICLR 0x0_4_4
`define LSOC1K_TICLR_CLR 0

// LLBCTL 0x0_6_0
`define LSOC1K_LLBCTL_ROLLB     0
`define LSOC1K_LLBCTL_WCLLB     1
`define LSOC1K_LLBCTL_KLO       2


// TLBREBASE 0x0_8_8
`ifdef GS264C_64BIT
  `define LSOC1K_TLBREBASE_EBASE `PABITS-1:12
`else
  `define LSOC1K_TLBREBASE_EBASE `GRLEN-1:6
`endif

// TLBREPC 0x0_8_A
`define LSOC1K_TLBREPC_ISTLBR 0
`define LSOC1K_TLBREPC_EPC    63:2

// TLBRPRMD 0x0_8_F
`define LSOC1K_TLBRPRMD_PPLV 1:0
`define LSOC1K_TLBRPRMD_PIE  2
`define LSOC1K_TLBRPRMD_PWE  4

// ERRCTL 0x0_9_0
`define LSOC1K_ERRCTL_ISERR       0
`define LSOC1K_ERRCTL_REPAIRABLE  1
`define LSOC1K_ERRCTL_PPLV        3:2
`define LSOC1K_ERRCTL_PIE         4
`define LSOC1K_ERRCTL_PWE         6
`define LSOC1K_ERRCTL_PDA         7
`define LSOC1K_ERRCTL_PPG         8
`define LSOC1K_ERRCTL_PDATF      10:9
`define LSOC1K_ERRCTL_PDATM      12:11
`define LSOC1K_ERRCTL_CAUSE      23:16

// ERREBASE 0x0_9_3
`define LSOC1K_ERREBASE_EBASE    `PABITS-1:12

// ERREPC 0x0_9_4
`define LSOC1K_ERREPC_EPC        63:0

// DMWIN 0x1_8_0 - 0x1_8_1
`define LSOC1K_DMW_PLV0 0
`define LSOC1K_DMW_PLV1 1
`define LSOC1K_DMW_PLV2 2
`define LSOC1K_DMW_PLV3 3
`define LSOC1K_DMW_MAT  5:4
`ifdef GS264C_64BIT
  `define LSOC1K_DMW_VSEG 63:56
`else
  `define LSOC1K_DMW_PSEG 27:25
  `define LSOC1K_DMW_VSEG 31:29
`endif 

// PMCFG 0x2_0_0 + 2N
`define LSOC1K_PMCFG_EVENT  9:0
`define LSOC1K_PMCFG_PLV0   16
`define LSOC1K_PMCFG_PLV1   17
`define LSOC1K_PMCFG_PLV2   18
`define LSOC1K_PMCFG_PLV3   19
`define LSOC1K_PMCFG_IE     20

// PMCNT 0x2_0_1 + 2N
`define LSOC1K_PMCNT_COUNT  63:0


// BSEC (BOOT SECURITY) 0x1_0_0
`define LSOC1K_BSEC_EF       0

// Status (12, 0)
`define STATUS_CU1          29
`define STATUS_RW           28
`define STATUS_BEV          22
`define STATUS_IM           15:8
`define STATUS_UM           4
`define STATUS_ERL          2
`define STATUS_EXL          1
`define STATUS_IE           0

// Cause (13, 0)
`define CAUSE_BD            31
`define CAUSE_TI            30
`define CAUSE_CE            29:28
`define CAUSE_IV            23
`define CAUSE_IP            15:8
`define CAUSE_IP7_2         15:10
`define CAUSE_IP1_0         9:8
`define CAUSE_EXCCODE       6:2

// TagLo0(28,0)
`define TAGLO0_PTAGLO       31:8
`define TAGLO0_PSTATE       7:6
`define TAGLO0_L            5
`define TAGLO0_P            0

// TagHi0(29,0)
`define TAGHI0_PTAGLO       31:8
`define TAGHI0_PSTATE       7:6
`define TAGHI0_L            5
`define TAGHI0_P            0

// EXCCODE
`define EXC_INT         6'h00
`define EXC_PIL         6'h01
`define EXC_PIS         6'h02
`define EXC_PIF         6'h03
`define EXC_PWE         6'h04
`define EXC_PNR         6'h05
`define EXC_PNE         6'h06
`define EXC_PPI         6'h07
`define EXC_ADEF        6'h08
`define EXC_ADEM        6'h08
`define EXC_ALE         6'h09
`define EXC_BCE         6'h0a
`define EXC_SYS         6'h0b
`define EXC_BRK         6'h0c
`define EXC_INE         6'h0d
`define EXC_IPE         6'h0e
`define EXC_FPD         6'h0f
`define EXC_SXD         6'h10
`define EXC_ASXD        6'd11
`define EXC_FPE         6'd12
`define EXC_VFPE        6'd12
`define EXC_WPEF        6'h13
`define EXC_WPEM        6'h13
`define EXC_BTD         6'h14
`define EXC_BTE         6'h15
`define EXC_GSPR        6'h16
`define EXC_HYP         6'h17
`define EXC_GCSC        6'h18
`define EXC_GCHC        6'h18

`define EXC_CACHEERR    6'h1e

`define EXC_ERROR       6'h3e
`define EXC_TLBR        6'h3f

`define EXC_NONE        6'h30

// instruction encoding
`define GET_RK(x)       x[14:10]
`define GET_RJ(x)       x[ 9: 5]
`define GET_RD(x)       x[ 4: 0]
`define GET_SA(x)       x[17:15]
`define GET_MSLSBD(x)   x[21:10]
`define GET_I5(x)       x[14:10]
`define GET_I6(x)       x[15:10]
`define GET_I12(x)      x[21:10]
`define GET_I14(x)      x[23:10]
`define GET_I16(x)      x[25:10]
`define GET_I20(x)      x[24: 5]
`define GET_OFFSET16(x) x[25:10]
`define GET_OFFSET21(x) {x[4:0],x[25:10]}
`define GET_OFFSET26(x) {x[9:0],x[25:10]}
`define GET_CSR(x)      x[23:10] // TO CHECK!!!!!!!!!!!!!!!!!!!!!!!!!!!

//write back source;  // TODO!!
`define EX_SR          9
`define EX_ALU0        9'd1
`define EX_ALU1        9'd2
`define EX_BRU         9'd3
`define EX_LSU         9'd4
`define EX_MUL         9'd5
`define EX_DIV         9'd6
`define EX_NONE0       9'd7
`define EX_NONE1       9'd8

// LSUop encoding
`define LSU_NUM         10
`define LSU_LW          0
`define LSU_SW          1
`define LSU_LB          2
`define LSU_LBU         3
`define LSU_LH          4
`define LSU_LHU         5
`define LSU_SB          6
`define LSU_SH          7
`define LSU_LL          8
`define LSU_SC          9

// EXCEPT encoding
`define EXCPT_CAUSE     7
`define EXCPT_SYSCALL   0
`define EXCPT_BREAK     1
`define EXCPT_OV        2
`define EXCPT_ADEL      3
`define EXCPT_ADES      4
`define EXCPT_RESERVE   5
`define EXCPT_INT       6

// SWITCH
`define SWITCH_NUM      2
`define SWITCH_INT_E    0
`define SWITCH_INT_D    1

// MODE
`define MODE_NUM        4
`define USER_MODE       0
`define DEBUG_MODE      1
`define KERNEL_MODE     2
`define SUPERVISOR_MODE 3

// cache
`include "./cache.vh"

// CACHEop encoding
`define CACHE_OPNUM    2
`define CACHE_TAG      0
`define CACHE_DATA     1

`define CACHE_RELATED  3
`define CACHE_CACHE    0
`define CACHE_PREF     1
`define CACHE_SYNCI    2

//
`define LSOC1K_NONE_INFO_BIT 4
`define LSOC1K_CSR_ROLL_BACK 0
`define LSOC1K_CSR_EXCPT     2:1
`define LSOC1K_CSR_EXCPT_BIT 2
`define LSOC1K_CSR_DBCALL    `LSOC1K_CSR_EXCPT_BIT'b01
`define LSOC1K_CSR_ERET      `LSOC1K_CSR_EXCPT_BIT'b10
`define LSOC1K_MICROOP       3

// csr output
`define LSOC1K_CSR_OUTPUT_BIT  13

`define LSOC1K_CSR_OUTPUT_CRMD_PLV    1:0
`define LSOC1K_CSR_OUTPUT_EUEN_FPE      2
`define LSOC1K_CSR_OUTPUT_EUEN_SXE      3
`define LSOC1K_CSR_OUTPUT_EUEN_ASXE     4
`define LSOC1K_CSR_OUTPUT_EUEN_BTE      5
`define LSOC1K_CSR_OUTPUT_MISC_DRDTL1   6
`define LSOC1K_CSR_OUTPUT_MISC_DRDTL2   7
`define LSOC1K_CSR_OUTPUT_MISC_DRDTL3   8
`define LSOC1K_CSR_OUTPUT_MISC_ALCL0    9
`define LSOC1K_CSR_OUTPUT_MISC_ALCL1   10
`define LSOC1K_CSR_OUTPUT_MISC_ALCL2   11
`define LSOC1K_CSR_OUTPUT_MISC_ALCL3   12


// Predictor Info
`define LSOC1K_PRU_HINT  4

// Front End RAMs
`include "frontend_rams.vh"


