`include "common.vh"
`include "decoded.vh"


module lsoc1000_stage_de2(
    input               clk,
    input               resetn,
    //exception
    input               exception,
    input               eret,
    input               int_except,
    //jump / branch
    input               bru_cancel,
    input               wb_cancel,
    // csr related
    input [`LSOC1K_CSR_OUTPUT_BIT-1:0] csr_output,
    // pipe in
    output              de2_allow_in,
    output [ 2:0]       de2_accept,
    // port0
    input                      de2_port0_valid,
    input [`GRLEN-1:0]         de2_port0_pc,
    input [31:0]               de2_port0_inst,
    input [`GRLEN-3:0]         de2_port0_br_target,
    input                      de2_port0_br_taken,
    input                      de2_port0_exception,
    input [5 :0]               de2_port0_exccode,
    input [`LSOC1K_PRU_HINT:0] de2_port0_hint,
    // port1
    input                      de2_port1_valid,
    input [`GRLEN-1:0]         de2_port1_pc,
    input [31:0]               de2_port1_inst,
    input [`GRLEN-3:0]         de2_port1_br_target,
    input                      de2_port1_br_taken,
    input                      de2_port1_exception,
    input [5 :0]               de2_port1_exccode,
    input [`LSOC1K_PRU_HINT:0] de2_port1_hint,
    // port2
    input                      de2_port2_valid,
    input [`GRLEN-1:0]         de2_port2_pc,
    input [31:0]               de2_port2_inst,
    input [`GRLEN-3:0]         de2_port2_br_target,
    input                      de2_port2_br_taken,
    input                      de2_port2_exception,
    input [5 :0]               de2_port2_exccode,
    input [`LSOC1K_PRU_HINT:0] de2_port2_hint,
    // barrier info
    input                      data_mshr_empty,
    input                      ex1_port0_valid,
    input                      ex1_port1_valid,
    input                      ex2_port0_valid,
    input                      ex2_port1_valid,
    input                      wb_port0_valid ,
    input                      wb_port1_valid ,
    // pipe out
    input                                   is_allow_in,
    // port0
    output                                  is_port0_valid,
    output reg [31:0]                       is_port0_inst,
    output reg [`GRLEN-1:0]                 is_port0_pc,
    output reg [`LSOC1K_DECODE_RES_BIT-1:0] is_port0_op,
    output reg                              is_port0_exception,
    output reg [5 :0]                       is_port0_exccode,
    output reg [`GRLEN-3:0]                 is_port0_br_target,
    output reg                              is_port0_br_taken,
    output reg                              is_port0_rf_wen,
    output reg [4:0]                        is_port0_rf_target,
    output reg [`LSOC1K_PRU_HINT:0]         is_port0_hint,
    // output reg                              is_port0_has_microop,
    // port1
    output                                  is_port1_valid,
    output reg [31:0]                       is_port1_inst,
    output reg [`GRLEN-1:0]                 is_port1_pc,
    output reg [`LSOC1K_DECODE_RES_BIT-1:0] is_port1_op,
    output reg                              is_port1_exception,
    output reg [5 :0]                       is_port1_exccode,
    output reg [`GRLEN-3:0]                 is_port1_br_target,
    output reg                              is_port1_br_taken,
    output reg                              is_port1_rf_wen,
    output reg [4:0]                        is_port1_rf_target,
    output reg [`LSOC1K_PRU_HINT:0]         is_port1_hint,
    // output reg                              is_port1_is_microop,
    // port2
    output                                  is_port2_valid,
    output reg                              is_port2_app,
    output reg                              is_port2_id,
    output reg [31:0]                       is_port2_inst,
    output reg [`GRLEN-1:0]                 is_port2_pc,
    output reg [`LSOC1K_DECODE_RES_BIT-1:0] is_port2_op,
    output reg                              is_port2_exception,
    output reg [5 :0]                       is_port2_exccode,
    output reg [`GRLEN-3:0]                 is_port2_br_target,
    output reg                              is_port2_br_taken,
    output reg [`LSOC1K_PRU_HINT:0]         is_port2_hint
);

// define
wire rst = !resetn;
wire fuse_happen;
reg  valid0;
reg  valid1;
reg  valid2;
wire [`LSOC1K_DECODE_RES_BIT-1:0] port0_op;
wire [`LSOC1K_DECODE_RES_BIT-1:0] port1_op;
wire [`LSOC1K_DECODE_RES_BIT-1:0] port2_op;
wire [`FUSE_INFO_BIT-1:0] port0_fuse_info;
wire [`FUSE_INFO_BIT-1:0] port1_fuse_info;

////func
decoder port0_decoder(.inst(de2_port0_inst), .res(port0_op)); //decode the inst
decoder port1_decoder(.inst(de2_port1_inst), .res(port1_op));
decoder port2_decoder(.inst(de2_port2_inst), .res(port2_op));

//reg file related
wire rf_wen0 = port0_op[`LSOC1K_GR_WEN];
wire rf_wen1 = port1_op[`LSOC1K_GR_WEN] || port0_op[`LSOC1K_RDTIME];
wire rf_wen2 = port2_op[`LSOC1K_GR_WEN];

wire [4:0] waddr0 = (port0_op[`LSOC1K_BRU_RELATED] && (port0_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_BL)) ? 5'd1 : `GET_RD(de2_port0_inst);
wire [4:0] waddr1 = (port0_op[`LSOC1K_RDTIME] && de2_port0_valid) ? `GET_RJ(de2_port0_inst) : (port1_op[`LSOC1K_BRU_RELATED] && (port1_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_BL)) ? 5'd1 : `GET_RD(de2_port1_inst);// rdtime has priority because original port1 inst may be invalid even incorrect
wire [4:0] waddr2 = (port2_op[`LSOC1K_BRU_RELATED] && (port2_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_BL)) ? 5'd1 : `GET_RD(de2_port2_inst);

//// crash check
// exception
wire port0_fpd = !csr_output[`LSOC1K_CSR_OUTPUT_EUEN_FPE] && port0_op[`LSOC1K_FLOAT];
wire port1_fpd = !csr_output[`LSOC1K_CSR_OUTPUT_EUEN_FPE] && port1_op[`LSOC1K_FLOAT];
wire port2_fpd = !csr_output[`LSOC1K_CSR_OUTPUT_EUEN_FPE] && port2_op[`LSOC1K_FLOAT];

`ifdef LA64
wire port0_ipe = ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd1) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL1] && port0_op[`LSOC1K_RDTIME]) ||
                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd2) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL2] && port0_op[`LSOC1K_RDTIME]) ||
                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd3) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL3] && port0_op[`LSOC1K_RDTIME]) ;
wire port1_ipe = ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd1) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL1] && port1_op[`LSOC1K_RDTIME]) ||
                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd2) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL2] && port1_op[`LSOC1K_RDTIME]) ||
                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd3) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL3] && port1_op[`LSOC1K_RDTIME]) ;
wire port2_ipe = ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd1) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL1] && port2_op[`LSOC1K_RDTIME]) ||
                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd2) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL2] && port2_op[`LSOC1K_RDTIME]) ||
                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd3) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL3] && port2_op[`LSOC1K_RDTIME]) ;
`elsif LA32
wire port0_ipe = 1'B0;//(csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] != 2'd0) && (port0_op[`LSOC1K_CSR_READ] || port0_op[`LSOC1K_CACHE_RELATED] || port0_op[`LSOC1K_TLB_RELATED] || port0_op[`LSOC1K_WAIT] || port0_op[`LSOC1K_ERET]);
wire port1_ipe = 1'B0;//(csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] != 2'd0) && (port1_op[`LSOC1K_CSR_READ] || port1_op[`LSOC1K_CACHE_RELATED] || port1_op[`LSOC1K_TLB_RELATED] || port1_op[`LSOC1K_WAIT] || port1_op[`LSOC1K_ERET]);
wire port2_ipe =1'B0;// (csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] != 2'd0) && (port2_op[`LSOC1K_CSR_READ] || port2_op[`LSOC1K_CACHE_RELATED] || port2_op[`LSOC1K_TLB_RELATED] || port2_op[`LSOC1K_WAIT] || port2_op[`LSOC1K_ERET]);

`endif

wire port0_exception = de2_port0_exception   || port0_op[`LSOC1K_SYSCALL] || port0_op[`LSOC1K_BREAK ] || port0_op[`LSOC1K_INE] ||
                       port0_fpd || port0_ipe || int_except;
wire port1_exception = de2_port1_exception   || port1_op[`LSOC1K_SYSCALL] || port1_op[`LSOC1K_BREAK ] || port1_op[`LSOC1K_INE] ||
                       port1_fpd || port1_ipe;
wire port2_exception = de2_port2_exception   || port2_op[`LSOC1K_SYSCALL] || port2_op[`LSOC1K_BREAK ] || port2_op[`LSOC1K_INE] ||
                       port2_fpd || port2_ipe;

wire [5:0] port0_exccode = int_except                ? `EXC_INT          :
                           de2_port0_exception       ? de2_port0_exccode : 
                           port0_op[`LSOC1K_SYSCALL] ? `EXC_SYS          :
                           port0_op[`LSOC1K_BREAK  ] ? `EXC_BRK          :
                           port0_op[`LSOC1K_INE    ] ? `EXC_INE          :
                           port0_fpd                 ? `EXC_FPD          :
                                                       6'd0              ;
wire [5:0] port1_exccode = de2_port1_exception       ? de2_port1_exccode : 
                           port1_op[`LSOC1K_SYSCALL] ? `EXC_SYS          :
                           port1_op[`LSOC1K_BREAK  ] ? `EXC_BRK          :
                           port1_op[`LSOC1K_INE    ] ? `EXC_INE          :
                           port1_fpd                 ? `EXC_FPD          :
                                                       6'd0              ;
wire [5:0] port2_exccode = de2_port2_exception       ? de2_port2_exccode : 
                           port2_op[`LSOC1K_SYSCALL] ? `EXC_SYS          :
                           port2_op[`LSOC1K_BREAK  ] ? `EXC_BRK          :
                           port2_op[`LSOC1K_INE    ] ? `EXC_INE          :
                           port2_fpd                 ? `EXC_FPD          :
                                                       6'd0              ;

// data crash
wire triple_read_0  = (port0_op[`LSOC1K_TRIPLE_READ] && de2_port0_valid);
wire triple_read_1  = (port1_op[`LSOC1K_TRIPLE_READ] && de2_port1_valid);
wire triple_read_2  = (port2_op[`LSOC1K_TRIPLE_READ] && de2_port2_valid);

wire raddr0_0_valid = port0_op[`LSOC1K_RJ_READ] || port0_op[`LSOC1K_RD2RJ  ];
wire raddr0_1_valid = port0_op[`LSOC1K_RK_READ] || port0_op[`LSOC1K_RD_READ];
wire raddr1_0_valid = port1_op[`LSOC1K_RJ_READ] || port1_op[`LSOC1K_RD2RJ  ];
wire raddr1_1_valid = port1_op[`LSOC1K_RK_READ] || port1_op[`LSOC1K_RD_READ];
wire raddr2_0_valid = port2_op[`LSOC1K_RJ_READ] || port2_op[`LSOC1K_RD2RJ  ];
wire raddr2_1_valid = port2_op[`LSOC1K_RK_READ] || port2_op[`LSOC1K_RD_READ];

wire [4:0] raddr0_0 = port0_op[`LSOC1K_RD2RJ  ] ? `GET_RD(de2_port0_inst) : `GET_RJ(de2_port0_inst);
wire [4:0] raddr0_1 = port0_op[`LSOC1K_RD_READ] ? `GET_RD(de2_port0_inst) : port0_op[`LSOC1K_RK_READ] ? `GET_RK(de2_port0_inst) : 5'd0;
wire [4:0] raddr1_0 = port1_op[`LSOC1K_RD2RJ  ] ? `GET_RD(de2_port1_inst) : `GET_RJ(de2_port1_inst);
wire [4:0] raddr1_1 = port1_op[`LSOC1K_RD_READ] ? `GET_RD(de2_port1_inst) : port1_op[`LSOC1K_RK_READ] ? `GET_RK(de2_port1_inst) : 5'd0;
wire [4:0] raddr2_0 = port2_op[`LSOC1K_RD2RJ  ] ? `GET_RD(de2_port2_inst) : `GET_RJ(de2_port2_inst);
wire [4:0] raddr2_1 = port2_op[`LSOC1K_RD_READ] ? `GET_RD(de2_port2_inst) : port2_op[`LSOC1K_RK_READ] ? `GET_RK(de2_port2_inst) : 5'd0;
wire [4:0] stx_read = `GET_RK(de2_port1_inst);

wire data_crash_01 =   (((raddr1_0 == waddr0) && raddr1_0_valid) || ((raddr1_1 == waddr0) && raddr1_1_valid) || ((stx_read == waddr0) && triple_read_1) ) 
                    && de2_port0_valid && rf_wen0 && (waddr0 != 5'd0);

wire data_crash_02 =   (((raddr2_0 == waddr0) && raddr2_0_valid) || ((raddr2_1 == waddr0) && raddr2_1_valid)) 
                    && de2_port0_valid && rf_wen0 && (waddr0 != 5'd0);

wire data_crash_12 =   (((raddr2_0 == waddr1) && raddr2_0_valid) || ((raddr2_1 == waddr1) && raddr2_1_valid)) 
                    && de2_port1_valid && rf_wen1 && (waddr1 != 5'd0);

// unit control
wire port0_csr_write = port0_op[`LSOC1K_CSR_WRITE] || port0_op[`LSOC1K_CACHE_RELATED];
wire port0_csr_read  = port0_op[`LSOC1K_CSR_READ ] || port0_op[`LSOC1K_ERET] || port0_op[`LSOC1K_CACHE_RELATED]; // raddr or waddr refers to cp0 regs
wire port1_csr_write = port1_op[`LSOC1K_CSR_WRITE] || port1_op[`LSOC1K_CACHE_RELATED];
wire port1_csr_read  = port1_op[`LSOC1K_CSR_READ ] || port1_op[`LSOC1K_ERET] || port1_op[`LSOC1K_CACHE_RELATED];
wire port2_csr_write = port2_op[`LSOC1K_CSR_WRITE] || port2_op[`LSOC1K_CACHE_RELATED];
wire port2_csr_read  = port2_op[`LSOC1K_CSR_READ ] || port2_op[`LSOC1K_ERET] || port2_op[`LSOC1K_CACHE_RELATED];

wire port0_csr_related = port0_op[`LSOC1K_CSR_RELATED] || port0_op[`LSOC1K_CACHE_RELATED] || port0_op[`LSOC1K_ERET];
wire port1_csr_related = port1_op[`LSOC1K_CSR_RELATED] || port1_op[`LSOC1K_CACHE_RELATED] || port1_op[`LSOC1K_ERET];
wire port2_csr_related = port2_op[`LSOC1K_CSR_RELATED] || port2_op[`LSOC1K_CACHE_RELATED] || port2_op[`LSOC1K_ERET];

wire port0_tlb_related = port0_op[`LSOC1K_TLB_RELATED];
wire port1_tlb_related = port1_op[`LSOC1K_TLB_RELATED];
wire port2_tlb_related = port2_op[`LSOC1K_TLB_RELATED];

wire port0_cache_related = port0_op[`LSOC1K_CACHE_RELATED];
wire port1_cache_related = port1_op[`LSOC1K_CACHE_RELATED];
wire port2_cache_related = port2_op[`LSOC1K_CACHE_RELATED];

wire port0_lsu_related = port0_op[`LSOC1K_LSU_RELATED] || port0_tlb_related || port0_cache_related;
wire port1_lsu_related = port1_op[`LSOC1K_LSU_RELATED] || port1_tlb_related || port1_cache_related;
wire port2_lsu_related = port2_op[`LSOC1K_LSU_RELATED] || port1_tlb_related || port1_cache_related;

wire port0_mul_related = port0_op[`LSOC1K_MUL_RELATED];
wire port1_mul_related = port1_op[`LSOC1K_MUL_RELATED];
wire port2_mul_related = port2_op[`LSOC1K_MUL_RELATED];

wire port0_div_related = port0_op[`LSOC1K_DIV_RELATED];
wire port1_div_related = port1_op[`LSOC1K_DIV_RELATED];
wire port2_div_related = port2_op[`LSOC1K_DIV_RELATED];

wire port0_bru_related = port0_op[`LSOC1K_BRU_RELATED];
wire port1_bru_related = port1_op[`LSOC1K_BRU_RELATED];
wire port2_bru_related = port2_op[`LSOC1K_BRU_RELATED];

wire csr_crash_01   = (port0_csr_related || port0_tlb_related) && (port1_csr_related || port1_tlb_related);
wire csr_crash_02   = (port0_csr_related || port0_tlb_related) && (port2_csr_related || port2_tlb_related);
wire csr_crash_12   = (port1_csr_related || port1_tlb_related) && (port2_csr_related || port2_tlb_related);

wire unit_crash_01  = ((port0_lsu_related && port1_lsu_related) || (port0_bru_related && port1_bru_related) || ((port0_mul_related || port0_div_related) && (port1_mul_related || port1_div_related)) || csr_crash_01) && de2_port0_valid && de2_port1_valid;
wire unit_crash_02  = ((port0_lsu_related && port2_lsu_related) || (port0_bru_related && port2_bru_related) || ((port0_mul_related || port0_div_related) && (port2_mul_related || port2_div_related)) || csr_crash_02) && de2_port0_valid && de2_port2_valid;
wire unit_crash_12  = ((port1_lsu_related && port2_lsu_related) || (port1_bru_related && port2_bru_related) || ((port1_mul_related || port1_div_related) && (port2_mul_related || port2_div_related)) || csr_crash_12) && de2_port1_valid && de2_port2_valid;
// wire lsu_protect_01 = (((port0_lsu_related /*&& !port0_op[`LSOC1K_LSU_ST]*/) && (port1_mul_related || port1_div_related)) ||
//                        ((port1_lsu_related /*&& !port1_op[`LSOC1K_LSU_ST]*/) && (port0_mul_related || port0_div_related)) ) && de2_port0_valid && de2_port1_valid;
// wire lsu_protect_02 = (((port0_lsu_related /*&& !port0_op[`LSOC1K_LSU_ST]*/) && (port2_mul_related || port2_div_related)) ||
//                        ((port2_lsu_related /*&& !port2_op[`LSOC1K_LSU_ST]*/) && (port0_mul_related || port0_div_related)) ) && de2_port0_valid && de2_port2_valid;
// wire lsu_protect_12 = (((port1_lsu_related /*&& !port1_op[`LSOC1K_LSU_ST]*/) && (port2_mul_related || port2_div_related)) ||
//                        ((port2_lsu_related /*&& !port2_op[`LSOC1K_LSU_ST]*/) && (port1_mul_related || port1_div_related)) ) && de2_port1_valid && de2_port2_valid;
wire lsu_protect_01 = 1'b0;
wire lsu_protect_02 = 1'b0;
wire lsu_protect_12 = 1'b0;

wire dbar_ibar_0    = port0_op[`LSOC1K_DBAR] || port0_op[`LSOC1K_IBAR];
wire dbar_ibar_1    = port1_op[`LSOC1K_DBAR] || port1_op[`LSOC1K_IBAR];
wire dbar_ibar_2    = port2_op[`LSOC1K_DBAR] || port2_op[`LSOC1K_IBAR];

wire port0_roll_back = port0_exception || port0_op[`LSOC1K_ERET  ] || port0_csr_write || port0_tlb_related || port0_cache_related;
wire port1_roll_back = port1_exception || port1_op[`LSOC1K_ERET  ] || port1_csr_write || port1_tlb_related || port1_cache_related;
wire port2_roll_back = port2_exception || port2_op[`LSOC1K_ERET  ] || port2_csr_write || port2_tlb_related || port2_cache_related;

wire single_issue   = port0_roll_back || port1_roll_back || port2_roll_back ||
                      dbar_ibar_0 || dbar_ibar_1 || dbar_ibar_2 || 
                      port0_div_related || port1_div_related || port2_div_related ||
                      port0_op[`LSOC1K_CPUCFG] || port1_op[`LSOC1K_CPUCFG] || port2_op[`LSOC1K_CPUCFG] ||
                      port0_op[`LSOC1K_RDTIME] || port1_op[`LSOC1K_RDTIME] || port2_op[`LSOC1K_RDTIME] ||
                      port0_op[`LSOC1K_WAIT]   || port1_op[`LSOC1K_WAIT]   || port2_op[`LSOC1K_WAIT]   ;

wire port0_llsc = port0_op[`LSOC1K_OP_CODE] == `LSOC1K_LSU_LL_W ||
                  port0_op[`LSOC1K_OP_CODE] == `LSOC1K_LSU_LL_D ||
                  port0_op[`LSOC1K_OP_CODE] == `LSOC1K_LSU_SC_W ||
                  port0_op[`LSOC1K_OP_CODE] == `LSOC1K_LSU_SC_D  ;

wire csr_read_crash = port0_lsu_related && port0_llsc && port1_csr_read;

wire crash          = unit_crash_01 || data_crash_01 || lsu_protect_01 || single_issue || csr_read_crash;

// op fusion
wire branch_fuse_allow = de2_port0_valid && de2_port1_valid && de2_port2_valid;
wire branch_p0_p1 = branch_fuse_allow && (port0_bru_related && !rf_wen0) && !(port1_bru_related || port2_bru_related);
wire branch_p1_p2 = branch_fuse_allow && (port1_bru_related && !rf_wen1) && !(port0_bru_related || port2_bru_related);
wire branch_p2    = branch_fuse_allow && (port2_bru_related && !rf_wen2) && !(port0_bru_related || port1_bru_related);

// hb
reg [1:0] wait_barrier;
wire strong_wait_barrier = dbar_ibar_0 && de2_port0_valid;
wire weak_wait_barrier   = port0_tlb_related && de2_port0_valid || port0_cache_related && de2_port0_valid ||
                           port0_csr_read && de2_port0_valid || port1_csr_read && de2_port1_valid;
wire wait_op             = port0_op[`LSOC1K_WAIT] && de2_port0_valid;
wire barrier_release =  data_mshr_empty && 
                       !ex1_port0_valid && !ex1_port1_valid &&
                       !ex2_port0_valid && !ex2_port1_valid &&
                       !wb_port0_valid  && !wb_port1_valid  ;
wire weak_barrier_release =  
                       !ex1_port0_valid && !ex1_port1_valid &&
                       !ex2_port0_valid && !ex2_port1_valid &&
                       !wb_port0_valid  && !wb_port1_valid  ;

always @(posedge clk) begin
    if      (rst || wb_cancel || bru_cancel || int_except || eret             ) wait_barrier<= 2'd0;
    else if ((wait_barrier == 2'd0) && strong_wait_barrier && de2_allow_in    ) wait_barrier<= 2'd1;
    else if ((wait_barrier == 2'd0) && weak_wait_barrier  && de2_allow_in     ) wait_barrier<= 2'd2;
    else if ((wait_barrier == 2'd0) && wait_op   && de2_allow_in              ) wait_barrier<= 2'd3;
    else if ((wait_barrier == 2'd1 || wait_barrier == 2'd2) && barrier_release) wait_barrier<= 2'd0;
    else if ((wait_barrier == 2'd2) && weak_barrier_release                   ) wait_barrier<= 2'd0;
end

// allow in
wire fuse_crash_12  = branch_p0_p1 && (data_crash_12 || unit_crash_12 || lsu_protect_12);
wire fuse_crash_02  = branch_p1_p2 && (data_crash_02 || unit_crash_02 || lsu_protect_02);
wire fuse_crash_2   = branch_p2    && (data_crash_02 || data_crash_12);
wire port2_accept   = !crash       && !(fuse_crash_12 || fuse_crash_02 || fuse_crash_2) && !(triple_read_2 || triple_read_1 || triple_read_0) && !single_issue;
wire port0_fuse     = branch_p0_p1 && port2_accept;
wire port1_fuse     = branch_p1_p2 && port2_accept;
wire port2_fuse     = branch_p2    && port2_accept;
wire port2_valid    = port0_fuse   || port1_fuse     || port2_fuse;

assign de2_allow_in = (is_allow_in || bru_cancel || exception || eret) && (wait_barrier == 2'd0);
assign de2_accept   = {port2_valid,!crash,de2_allow_in};

// basic
always @(posedge clk) begin
    if (rst)
    begin
        is_port0_br_taken    <= 1'd0;
        is_port0_exception   <= 1'd0;
        is_port0_exccode     <= 6'd0;
        is_port0_rf_wen      <= 1'd0;

        is_port1_br_taken    <= 1'd0;
        is_port1_exception   <= 1'd0;
        is_port1_exccode     <= 6'd0;
        is_port1_rf_wen      <= 1'd0;

        is_port2_br_taken    <= 1'd0;
        is_port2_exception   <= 1'd0;
        is_port2_exccode     <= 6'd0;
    end
    else
    if (de2_allow_in)
    begin
        is_port0_pc          <= port0_fuse ? de2_port1_pc        : de2_port0_pc       ;
        is_port0_inst        <= port0_fuse ? de2_port1_inst      : de2_port0_inst     ;
        is_port0_op          <= port0_fuse ? port1_op            : port0_op           ;
        is_port0_br_target   <= port0_fuse ? de2_port1_br_target : de2_port0_br_target;
        is_port0_br_taken    <= port0_fuse ? de2_port1_br_taken  : de2_port0_br_taken ;
        is_port0_hint        <= port0_fuse ? de2_port1_hint      : de2_port0_hint     ;
        is_port0_rf_wen      <= port0_fuse ? rf_wen1             : rf_wen0            ;
        is_port0_rf_target   <= port0_fuse ? {5{rf_wen1}}&waddr1 : {5{rf_wen0}}&waddr0;

        is_port1_pc          <= (port1_fuse || port0_fuse) ? de2_port2_pc        : de2_port1_pc       ;
        is_port1_inst        <= (port1_fuse || port0_fuse) ? de2_port2_inst      : de2_port1_inst     ;
        is_port1_op          <= (port1_fuse || port0_fuse) ? port2_op            : port1_op           ;
        is_port1_br_target   <= (port1_fuse || port0_fuse) ? de2_port2_br_target : de2_port1_br_target;
        is_port1_br_taken    <= (port1_fuse || port0_fuse) ? de2_port2_br_taken  : de2_port1_br_taken ;
        is_port1_exception   <= (port1_fuse || port0_fuse) ? port2_exception     : port1_exception    ;
        is_port1_exccode     <= (port1_fuse || port0_fuse) ? port2_exccode       : port1_exccode      ;
        is_port1_hint        <= (port1_fuse || port0_fuse) ? de2_port2_hint      : de2_port1_hint     ;
        is_port1_rf_wen      <= (port1_fuse || port0_fuse) ? rf_wen2             : rf_wen1            ;
        is_port1_rf_target   <= (port1_fuse || port0_fuse) ? {5{rf_wen2}}&waddr2 : {5{rf_wen1}}&waddr1;

        is_port2_id          <= port1_fuse;
        is_port2_app         <= port2_fuse;
        is_port2_pc          <= port2_fuse ? de2_port2_pc        : port1_fuse ? de2_port1_pc        : de2_port0_pc       ;
        is_port2_inst        <= port2_fuse ? de2_port2_inst      : port1_fuse ? de2_port1_inst      : de2_port0_inst     ;
        is_port2_op          <= port2_fuse ? port2_op            : port1_fuse ? port1_op            : port0_op           ;
        is_port2_br_target   <= port2_fuse ? de2_port2_br_target : port1_fuse ? de2_port1_br_target : de2_port0_br_target;
        is_port2_br_taken    <= port2_fuse ? de2_port2_br_taken  : port1_fuse ? de2_port1_br_taken  : de2_port0_br_taken ;
        is_port2_exception   <= port2_fuse ? port2_exception     : port1_fuse ? port1_exception     : port0_exception    ;
        is_port2_exccode     <= port2_fuse ? port2_exccode       : port1_fuse ? port1_exccode       : port0_exccode      ;
        is_port2_hint        <= port2_fuse ? de2_port2_hint      : port1_fuse ? de2_port1_hint      : de2_port0_hint     ;
    end

    if (de2_allow_in)
    begin
        is_port0_exception   <= port0_fuse ? port1_exception     : port0_exception;
        is_port0_exccode     <= port0_fuse ? port1_exccode       : port0_exccode  ;
    end
    else if ((wait_barrier == 2'd3) && int_except) 
    begin
        is_port0_exception  <= 1'd1;
        is_port0_exccode    <= `EXC_INT;
    end
end

always @(posedge clk) begin // internal valid
    if (rst) valid0 <= 1'd0;
    else if (exception || eret || bru_cancel || wb_cancel) valid0 <= 1'b0;
    else if (de2_allow_in) valid0 <= de2_port0_valid;
end

always @(posedge clk) begin // internal valid
    if (rst) valid1 <= 1'd0;
    else if (exception || eret || bru_cancel || wb_cancel) valid1 <= 1'b0;
    else if (de2_allow_in) valid1 <= (de2_port1_valid&& !crash) || (de2_port0_valid && port0_op[`LSOC1K_RDTIME]);
end

always @(posedge clk) begin // internal valid
    if (rst) valid2 <= 1'd0;
    else if (exception || eret || bru_cancel || wb_cancel) valid2 <= 1'b0;
    else if (de2_allow_in) valid2 <= port2_valid;
end

assign is_port0_valid = valid0 && (wait_barrier == 2'd0);
assign is_port1_valid = valid1 && (wait_barrier == 2'd0);
assign is_port2_valid = valid2 && (wait_barrier == 2'd0);

// stall counter
reg [31:0] de2_stall_cnt;
reg [31:0] de2_stall_cp0change_cnt;
reg [31:0] de2_stall_barrier_cnt;
reg [31:0] de2_stall_noinst_cnt;
reg [31:0] de2_tri_issue_cnt;
reg [31:0] de2_dual_issue_cnt;
reg [63:0] clk_counter;

wire stall_happen      = !de2_allow_in && is_allow_in;
wire stall_barrier     = stall_happen && (wait_barrier == 2'd0);
wire stall_noinst      = de2_allow_in && (!de2_port0_valid && !de2_port1_valid);
wire tri_issue_happen  = de2_allow_in && (de2_accept == 3'b111);
wire dual_issue_happen = de2_allow_in && (de2_accept == 3'b011 || de2_accept == 3'b101 || de2_accept == 3'b110);

always @(posedge clk) begin
    if (rst)                  de2_stall_cnt <= 32'd0;
    else if (stall_happen)    de2_stall_cnt <= de2_stall_cnt + 32'd1;

    if (rst)                  de2_stall_barrier_cnt <= 32'd0;
    else if (stall_barrier)   de2_stall_barrier_cnt <= de2_stall_barrier_cnt + 32'd1;

    if (rst)                  de2_stall_noinst_cnt <= 32'd0;
    else if (stall_noinst)    de2_stall_noinst_cnt <= de2_stall_noinst_cnt + 32'd1;

    if(rst)                    de2_tri_issue_cnt <= 32'd0;
    else if (tri_issue_happen) de2_tri_issue_cnt <= de2_tri_issue_cnt + 32'd1;

    if(rst)                     de2_dual_issue_cnt <= 32'd0;
    else if (dual_issue_happen) de2_dual_issue_cnt <= de2_dual_issue_cnt + 32'd1;
end

endmodule
