`include "common.vh"
`include "decoded.vh"

module lsoc1000_mainpipe(
    input               clk,
    input               resetn,            //low active

    input   [7 :0]      intrpt,
    
    `LSOC1K_DECL_BHT_RAMS_M,
    
    output              inst_req      ,
    output  [ 31:0]     inst_addr     ,
    output              inst_cancel   ,
    input               inst_addr_ok  ,
    input   [127:0]     inst_rdata    ,
    input               inst_valid    ,
    input   [  1:0]     inst_count    ,
    input               inst_uncache  ,
    input   [  5:0]     inst_exccode  ,
    input               inst_exception,

    input               inst_tlb_req  ,
    input   [`GRLEN-1:0] inst_tlb_vaddr,
    input               inst_tlb_cacop,

    output [`PIPELINE2DCACHE_BUS_WIDTH-1:0] pipeline2dcache_bus,
    input  [`DCACHE2PIPELINE_BUS_WIDTH-1:0] dcache2pipeline_bus,
    output                       csr_wen  ,
    output [`LSOC1K_CSR_BIT-1:0] csr_waddr,
    output [`GRLEN-1         :0] csr_wdata,
    output                       wb_eret  ,
    input  [`GRLEN-1         :0] llbctl   ,
    
    output              tlb_req         ,
    output              cache_req       ,
    output  [4 :0]      cache_op        ,
    output [`D_TAG_LEN-1:0] cache_op_tag,
    input               cache_op_recv   ,
    input               cache_op_finish ,

    // tlb-cache interface
    output  [`PABITS-1:0]      itlb_paddr,
    output              itlb_finish,
    output              itlb_hit,
    input               itlb_cache_recv,
    output              itlb_uncache,
    output  [ 5:0]      itlb_exccode,
    
    
    output  [`PABITS-1:0]      dtlb_paddr,
    output              dtlb_finish,
    output              dtlb_hit,
    input               data_tlb_req,
    input               data_tlb_wr   ,
    input   [`GRLEN-1:0]data_tlb_vaddr,
    input               dtlb_cache_recv,
    input               dtlb_no_trans  ,
    input               dtlb_p_pgcl    ,
    output              dtlb_uncache,
    output  [ 5:0]      dtlb_exccode,

    //debug interface
    output  [`GRLEN-1:0]   debug0_wb_pc,
    output                 debug0_wb_rf_wen,
    output  [ 4:0]         debug0_wb_rf_wnum,
    output  [`GRLEN-1:0]   debug0_wb_rf_wdata,
    
    output  [`GRLEN-1:0]   debug1_wb_pc,
    output                 debug1_wb_rf_wen,
    output  [ 4:0]         debug1_wb_rf_wnum,
    output  [`GRLEN-1:0]   debug1_wb_rf_wdata
);

wire rst = !resetn;

// temp
wire               bru_port_ex2;
wire               bru_cancel_ex2;
wire  [`GRLEN-1:0] cp0_taglo0;
wire  [`GRLEN-1:0] cp0_taghi0;
wire bru_ignore_ex2;
wire bru_cancel_all_ex2;
wire bru_cancel;
wire bru_cancel_all;
wire bru_ignore;
wire bru_port;

assign cache_op_tag = {`D_TAG_LEN{1'b0}}; // TODO

// IF output
wire        de_allow_in    ;
wire [ 2:0] de_accept;
// port 1
wire                      de_port0_valid ;
wire [31:0]               de_port0_inst  ;
wire [`GRLEN-1:0]         de_port0_pc    ;
wire [`GRLEN-3:0]         de_port0_br_target;
wire                      de_port0_br_taken ;
wire                      de_port0_exception;
wire [5 :0]               de_port0_exccode;
wire [`LSOC1K_PRU_HINT:0] de_port0_hint;
wire                      de_port0_robr;
// port 2
wire                      de_port1_valid ;
wire [31:0]               de_port1_inst  ;
wire [`GRLEN-1:0]         de_port1_pc    ;
wire [`GRLEN-3:0]         de_port1_br_target;
wire                      de_port1_br_taken ;
wire                      de_port1_exception;
wire [5 :0]               de_port1_exccode;
wire [`LSOC1K_PRU_HINT:0] de_port1_hint;
wire                      de_port1_robr;
// port 3
wire                      de_port2_valid ;
wire                      de_port2_id ;
wire [31:0]               de_port2_inst  ;
wire [`GRLEN-1:0]         de_port2_pc    ;
wire [`GRLEN-3:0]         de_port2_br_target;
wire                      de_port2_br_taken ;
wire                      de_port2_exception;
wire [5 :0]               de_port2_exccode;
wire [`LSOC1K_PRU_HINT:0] de_port2_hint;
wire                      de_port2_robr;

   
//// IF output
//wire        de2_allow_in    ;
//wire [ 2:0] de2_accept;
//// port 1
//wire                      de1_port0_valid ;
//wire [31:0]               de1_port0_inst  ;
//wire [`GRLEN-1:0]         de1_port0_pc    ;
//wire [`GRLEN-3:0]         de1_port0_br_target;
//wire                      de1_port0_br_taken ;
//wire                      de1_port0_exception;
//wire [5 :0]               de1_port0_exccode;
//wire [`LSOC1K_PRU_HINT:0] de1_port0_hint;
//wire                      de1_port0_robr;
//// port 2
//wire                      de1_port1_valid ;
//wire [31:0]               de1_port1_inst  ;
//wire [`GRLEN-1:0]         de1_port1_pc    ;
//wire [`GRLEN-3:0]         de1_port1_br_target;
//wire                      de1_port1_br_taken ;
//wire                      de1_port1_exception;
//wire [5 :0]               de1_port1_exccode;
//wire [`LSOC1K_PRU_HINT:0] de1_port1_hint;
//wire                      de1_port1_robr;
//// port 3
//wire                      de1_port2_valid ;
//wire                      de1_port2_id ;
//wire [31:0]               de1_port2_inst  ;
//wire [`GRLEN-1:0]         de1_port2_pc    ;
//wire [`GRLEN-3:0]         de1_port2_br_target;
//wire                      de1_port2_br_taken ;
//wire                      de1_port2_exception;
//wire [5 :0]               de1_port2_exccode;
//wire [`LSOC1K_PRU_HINT:0] de1_port2_hint;
//wire                      de1_port2_robr;
//
//// DE1 output
//// port 1
//wire                      de2_port0_valid ;
//wire [31:0]               de2_port0_inst  ;
//wire [`GRLEN-1:0]         de2_port0_pc    ;
//wire [`GRLEN-3:0]         de2_port0_br_target;
//wire                      de2_port0_br_taken ;
//wire                      de2_port0_exception;
//wire [5 :0]               de2_port0_exccode;
//wire [`LSOC1K_PRU_HINT:0] de2_port0_hint;
//// port 2
//wire                      de2_port1_valid ;
//wire [31:0]               de2_port1_inst  ;
//wire [`GRLEN-1:0]         de2_port1_pc    ;
//wire [`GRLEN-3:0]         de2_port1_br_target;
//wire                      de2_port1_br_taken ;
//wire                      de2_port1_exception;
//wire [5 :0]               de2_port1_exccode;
//wire [`LSOC1K_PRU_HINT:0] de2_port1_hint;
//// port 3
//wire                      de2_port2_valid ;
//wire [31:0]               de2_port2_inst  ;
//wire [`GRLEN-1:0]         de2_port2_pc    ;
//wire [`GRLEN-3:0]         de2_port2_br_target;
//wire                      de2_port2_br_taken ;
//wire                      de2_port2_exception;
//wire [5 :0]               de2_port2_exccode;
//wire [`LSOC1K_PRU_HINT:0] de2_port2_hint;
// DE2 output
wire                              is_allow_in;
// port 0
wire                              is_port0_valid;
wire [`GRLEN-1:0]                 is_port0_pc;
wire [31:0]                       is_port0_inst;
wire [`LSOC1K_DECODE_RES_BIT-1:0] is_port0_op;
wire [`GRLEN-3:0]                 is_port0_br_target;
wire                              is_port0_br_taken;
wire                              is_port0_exception;
wire [5:0]                        is_port0_exccode;
wire [`LSOC1K_PRU_HINT:0]         is_port0_hint;
wire                              is_port0_rf_wen;
wire [4:0]                        is_port0_rf_target;
// port 1
wire [`GRLEN-1:0]                 is_port1_pc;
wire [31:0]                       is_port1_inst;
wire                              is_port1_valid;
wire [`LSOC1K_DECODE_RES_BIT-1:0] is_port1_op;
wire [`GRLEN-3:0]                 is_port1_br_target;
wire                              is_port1_br_taken;
wire                              is_port1_exception;
wire [5:0]                        is_port1_exccode;
wire [`LSOC1K_PRU_HINT:0]         is_port1_hint;
wire                              is_port1_rf_wen;
wire [4:0]                        is_port1_rf_target;
// port 2
wire [`GRLEN-1:0]                 is_port2_pc;
wire [31:0]                       is_port2_inst;
wire                              is_port2_id;
wire                              is_port2_app;
wire                              is_port2_valid;
wire [`LSOC1K_DECODE_RES_BIT-1:0] is_port2_op;
wire [`GRLEN-3:0]                 is_port2_br_target;
wire                              is_port2_br_taken;
wire                              is_port2_exception;
wire [5:0]                        is_port2_exccode;
wire [`LSOC1K_PRU_HINT:0]         is_port2_hint;
//reg file
wire [4:0]          waddr1;
wire [4:0]          raddr0_0;
wire [4:0]          raddr0_1;
wire                wen1;
wire [`GRLEN-1:0]   wdata1;
wire [`GRLEN-1:0]   rdata0_0;
wire [`GRLEN-1:0]   rdata0_1;
wire [4:0]          waddr2;
wire [4:0]          raddr1_0;
wire [4:0]          raddr1_1;
wire                wen2;
wire [`GRLEN-1:0]   wdata2;
wire [`GRLEN-1:0]   rdata1_0;
wire [`GRLEN-1:0]   rdata1_1;
wire [4:0]          raddr2_0;
wire [4:0]          raddr2_1;
wire [`GRLEN-1:0]   rdata2_0;
wire [`GRLEN-1:0]   rdata2_1;

// output IS
wire                ex1_allow_in;
// port 1
wire                ex1_port0_valid;
wire [`GRLEN-1:0]   ex1_port0_pc;
wire [31:0]         ex1_port0_inst;
wire [4:0]          ex1_port0_rf_target;
wire                ex1_port0_rf_wen;
wire                ex1_port0_type;
wire                ex1_port1_valid;
wire [`GRLEN-1:0]   ex1_port1_pc;
wire [31:0]         ex1_port1_inst;
wire [4:0]          ex1_port1_rf_target;
wire                ex1_port1_rf_wen;
wire                ex1_port1_type;
wire                ex1_port2_type;

wire                ex1_port0_ll;
wire                ex1_port0_sc;
wire                ex1_port1_ll;
wire                ex1_port1_sc;

wire [`GRLEN-1:0]   ex1_port0_a;
wire [`GRLEN-1:0]   ex1_port0_b;   
wire [`LSOC1K_ALU_CODE_BIT-1:0] ex1_port0_op;
wire [`GRLEN-1:0]   ex1_port0_c;
wire [`GRLEN-1:0]   ex1_port1_a;
wire [`GRLEN-1:0]   ex1_port1_b;   
wire [`LSOC1K_ALU_CODE_BIT-1:0] ex1_port1_op;
wire [`GRLEN-1:0]   ex1_port1_c;
wire                ex1_port0_a_ignore;
wire                ex1_port0_b_ignore;
wire                ex1_port0_b_get_a;
wire                ex1_port0_double;
wire                ex1_port1_a_ignore;
wire                ex1_port1_b_ignore;
wire                ex1_port1_b_get_a;
wire                ex1_port1_double;

wire [`GRLEN-1:0]   ex1_lsu_fw_data;
wire                ex1_rdata0_0_lsu_fw;
wire                ex1_rdata0_1_lsu_fw;
wire                ex1_rdata1_0_lsu_fw;
wire                ex1_rdata1_1_lsu_fw;
wire                ex1_port0_a_lsu_fw;
wire                ex1_port0_b_lsu_fw;
wire                ex1_port1_a_lsu_fw;
wire                ex1_port1_b_lsu_fw;
wire                ex1_mdu_a_lsu_fw;
wire                ex1_mdu_b_lsu_fw;
wire                ex1_bru_a_lsu_fw;
wire                ex1_bru_b_lsu_fw;
wire                ex1_lsu_base_lsu_fw;
wire                ex1_lsu_offset_lsu_fw;
wire                ex1_lsu_wdata_lsu_fw;

wire [`LSOC1K_MDU_CODE_BIT-1:0] ex1_mdu_op;
wire [`GRLEN-1:0]   ex1_mdu_a;
wire [`GRLEN-1:0]   ex1_mdu_b;   

wire [`LSOC1K_LSU_CODE_BIT-1:0] ex1_lsu_op; 
wire [`GRLEN-1:0]   ex1_lsu_base;
wire [`GRLEN-1:0]   ex1_lsu_offset;
wire [`GRLEN-1:0]   ex1_lsu_wdata;

wire                ex1_port0_branch_port;
wire [`GRLEN-1:0]   ex1_port0_branch_target;
wire                ex1_port0_branch_taken;

wire                ex1_port1_branch_port;
wire [`GRLEN-1:0]   ex1_port1_branch_target;
wire                ex1_port1_branch_taken;

wire [`GRLEN-1:0]   ex1_none0_result;
wire [`GRLEN-1:0]   ex1_none1_result;
wire                ex1_none0_exception;
wire                ex1_none1_exception;
wire [`GRLEN-1:0]   ex1_none0_csr_result;
wire [`GRLEN-1:0]   ex1_none1_csr_result;
wire [`GRLEN-1:0]   ex1_none0_csr_a;
wire [`GRLEN-1:0]   ex1_none1_csr_a;

wire [`LSOC1K_CSR_BIT-1:0]ex1_none0_csr_addr;
wire [`LSOC1K_CSR_BIT-1:0]ex1_none1_csr_addr;
wire [`LSOC1K_CSR_CODE_BIT-1:0]ex1_none0_op;
wire [`LSOC1K_CSR_CODE_BIT-1:0]ex1_none1_op;
wire [`LSOC1K_NONE_INFO_BIT-1:0]ex1_none0_info;
wire [`LSOC1K_NONE_INFO_BIT-1:0]ex1_none1_info;

wire [`EX_SR-1 : 0] ex1_port0_src;
wire [`EX_SR-1 : 0] ex1_port1_src;

wire [4:0]          ex1_raddr0_0;
wire [4:0]          ex1_raddr0_1;
wire [4:0]          ex1_raddr1_0;
wire [4:0]          ex1_raddr1_1;
wire [4:0]          ex1_raddr2_0;
wire [4:0]          ex1_raddr2_1;

//EX1
wire [`GRLEN-1:0]   ex2_port0_pc;
wire [31:0]         ex2_port0_inst;
wire                ex2_port0_valid;
wire [`EX_SR-1 : 0] ex2_port0_src;
wire [4:0]          ex2_port0_rf_target;
wire                ex2_port0_rf_wen;
wire                ex2_port0_type;
wire [`GRLEN-1:0]   ex2_port1_pc;
wire [31:0]         ex2_port1_inst;
wire                ex2_port1_valid;
wire [`EX_SR-1 : 0] ex2_port1_src;
wire [4:0]          ex2_port1_rf_target;
wire                ex2_port1_rf_wen;
wire                ex2_port1_type;
wire                ex2_port2_type;

wire                ex2_port0_ll;
wire                ex2_port0_sc;
wire                ex2_port1_ll;
wire                ex2_port1_sc;

wire [`GRLEN-1:0]   ex2_lsu_fw_data;
wire                ex2_rdata0_0_lsu_fw;
wire                ex2_rdata0_1_lsu_fw;
wire                ex2_rdata1_0_lsu_fw;
wire                ex2_rdata1_1_lsu_fw;
wire                ex2_bru_a_lsu_fw;
wire                ex2_bru_b_lsu_fw;

wire [2:0]          ex2_lsu_shift;
wire [`LSOC1K_LSU_CODE_BIT-1:0] ex2_lsu_op;
wire [`GRLEN-1:0]   ex2_lsu_wdata;
wire                ex2_lsu_recv;

wire                      bru_valid  ;
wire [`GRLEN-1:0]         bru_pc     ;
wire [`LSOC1K_PRU_HINT:0] bru_hint   ;
wire                      bru_sign   ;
wire                      bru_taken  ;
wire                      bru_link   ;
wire                      bru_jrra   ;
wire                      bru_brop   ;
wire                      bru_jrop   ;
wire [`GRLEN-1:0]         bru_target ;
wire [`GRLEN-1:0]         bru_link_pc;
wire                      bru_delay  ;

wire                      bru_valid_ex2  ;
wire [`GRLEN-1:0]         bru_pc_ex2     ;
wire [`LSOC1K_PRU_HINT:0] bru_hint_ex2   ;
wire                      bru_sign_ex2   ;
wire                      bru_taken_ex2  ;
wire                      bru_link_ex2   ;
wire                      bru_jrra_ex2   ;
wire                      bru_brop_ex2   ;
wire                      bru_jrop_ex2   ;
wire [`GRLEN-1:0]         bru_target_ex2 ;
wire [`GRLEN-1:0]         bru_link_pc_ex2;

wire                            ex2_bru_delay    ;
wire [`LSOC1K_BRU_CODE_BIT-1:0] ex2_bru_op       ;
wire [`GRLEN-1:0]               ex2_bru_a        ;
wire [`GRLEN-1:0]               ex2_bru_b        ;
wire                            ex2_bru_br_taken ;
wire [`GRLEN-1:0]               ex2_bru_br_target;
wire [`GRLEN-1:0]               ex2_bru_offset   ;
wire [`GRLEN-1:0]               ex2_bru_link_pc  ;
wire                            ex2_bru_link     ;
wire [2:0]                      ex2_bru_port     ;
wire                            ex2_bru_brop     ;
wire                            ex2_bru_jrop     ;
wire                            ex2_bru_jrra     ;
wire                            ex2_bru_valid    ;
wire [`LSOC1K_PRU_HINT:0]       ex2_bru_hint     ;
wire [`GRLEN-1:0]               ex2_bru_pc       ;

wire [`GRLEN-1:0]               ex2_port0_a;
wire [`GRLEN-1:0]               ex2_port0_b;  
wire [`LSOC1K_ALU_CODE_BIT-1:0] ex2_port0_op;
wire [`GRLEN-1:0]               ex2_port0_c;
wire                            ex2_port0_double;
wire [`GRLEN-1:0]               ex1_alu0_res;
wire [`GRLEN-1:0]               ex2_port1_a;
wire [`GRLEN-1:0]               ex2_port1_b;  
wire [`LSOC1K_ALU_CODE_BIT-1:0] ex2_port1_op;
wire [`GRLEN-1:0]               ex2_port1_c;
wire                            ex2_port1_double;
wire [`GRLEN-1:0]               ex1_alu1_res;

wire [`LSOC1K_MDU_CODE_BIT-1:0] ex2_mdu_op;
wire [`GRLEN-1:0]               ex2_mdu_a;
wire [`GRLEN-1:0]               ex2_mdu_b;

wire                            ex1_bru_delay;                            
wire [`LSOC1K_BRU_CODE_BIT-1:0] ex1_bru_op;
wire [`GRLEN-1:0]               ex1_bru_a;
wire [`GRLEN-1:0]               ex1_bru_b;
wire                            ex1_bru_br_taken;
wire [`GRLEN-1:0]               ex1_bru_br_target;
wire [`LSOC1K_PRU_HINT:0]       ex1_bru_hint;
wire                            ex1_bru_link;
wire                            ex1_bru_jrra;
wire                            ex1_bru_brop;
wire                            ex1_bru_jrop;
wire [`GRLEN-1:0]               ex1_bru_offset;
wire [`GRLEN-1:0]               ex1_bru_pc;
wire [2 :0]                     ex1_bru_port;
wire                            ex1_branch_valid;

wire [5 :0]         ex1_none0_exccode;
wire [5 :0]         ex1_none1_exccode;

wire                ex2_port0_exception;
wire                ex2_port1_exception;
wire [5 :0]         ex2_port0_exccode;
wire [5 :0]         ex2_port1_exccode;
wire [`GRLEN-1:0]   ex2_none0_csr_result;
wire [`GRLEN-1:0]   ex2_none1_csr_result;
wire [`GRLEN-1:0]   ex2_none0_result;
wire [`GRLEN-1:0]   ex2_none1_result;

wire [`LSOC1K_CSR_BIT -1:0] ex2_none0_csr_addr;
wire [`LSOC1K_CSR_BIT -1:0] ex2_none1_csr_addr;

wire [`LSOC1K_CSR_CODE_BIT-1:0]ex2_none0_op;
wire [`LSOC1K_CSR_CODE_BIT-1:0]ex2_none1_op;
wire [`LSOC1K_NONE_INFO_BIT-1:0]ex2_none0_info;
wire [`LSOC1K_NONE_INFO_BIT-1:0]ex2_none1_info;

wire                ex2_lsu_ale;     
wire                ex2_lsu_adem;
wire [`GRLEN-1:0]   lsu_badvaddr;

wire                ex1_mul_ready;

//EX2
wire                ex2_allow_in;

wire [`GRLEN-1:0]   ex2_alu0_res;
wire [`GRLEN-1:0]   ex2_alu1_res;
wire [`GRLEN-1:0]   ex2_lsu_res;
wire [`GRLEN-1:0]   ex2_mul_res;
wire [`GRLEN-1:0]   ex2_div_res;

wire [`LSOC1K_CSR_BIT -1:0] wb_port0_csr_addr;
wire [`LSOC1K_CSR_BIT -1:0] wb_port1_csr_addr;

wire                wb_port0_rf_res_lsu;
wire                wb_port1_rf_res_lsu;
wire [`GRLEN-1:0]   wb_lsu_res;
wire [`GRLEN-1:0]   wb_port0_csr_result;
wire [`GRLEN-1:0]   wb_port1_csr_result;
wire                wb_port0_esubcode;
wire                wb_port1_esubcode;
wire [`GRLEN-1:0]   wb_cache_taglo;
wire [`GRLEN-1:0]   wb_cache_taghi;
wire [`GRLEN-1:0]   wb_cache_datalo;
wire [`GRLEN-1:0]   wb_cache_datahi;

wire [`LSOC1K_CSR_CODE_BIT-1:0]wb_none0_op;
wire [`LSOC1K_CSR_CODE_BIT-1:0]wb_none1_op;
wire [`LSOC1K_NONE_INFO_BIT-1:0]wb_none0_info;
wire [`LSOC1K_NONE_INFO_BIT-1:0]wb_none1_info;

//WB
wire                wb_allow_in;

wire [31:0]         wb_port0_inst;
wire [`GRLEN-1:0]   wb_port0_pc;
wire [`EX_SR-1 : 0] wb_port0_src;
wire                wb_port0_valid;
wire [4:0]          wb_port0_rf_target;
wire                wb_port0_rf_wen;
wire [`GRLEN-1:0]   wb_port0_rf_result;
wire                wb_port0_exception;
wire [5 : 0]        wb_port0_exccode;
wire                wb_port0_eret;

wire [31:0]         wb_port1_inst;
wire [`GRLEN-1:0]   wb_port1_pc;
wire [`EX_SR-1 : 0] wb_port1_src;
wire                wb_port1_valid;
wire [4:0]          wb_port1_rf_target;
wire                wb_port1_rf_wen;
wire [`GRLEN-1:0]   wb_port1_rf_result;
wire                wb_port1_exception;
wire [5 :0]         wb_port1_exccode;
wire                wb_port1_eret;

wire                wb_port2_valid;

wire                wb_port0_ll;
wire                wb_port0_sc;
wire                wb_port1_ll;
wire                wb_port1_sc;

wire                      wb_branch_link;
wire [2:0]                wb_bru_port;
wire                      wb_branch_brop;
wire                      wb_branch_jrop;
wire                      wb_branch_jrra;
wire                      wb_branch_valid;
wire [`LSOC1K_PRU_HINT:0] wb_bru_hint;
wire                      wb_bru_br_taken;
wire [`GRLEN-1:0]         wb_bru_pc;
wire [`GRLEN-1:0]         wb_bru_link_pc;

wire                      wb_valid    ;
wire                      wb_link     ;
wire [`GRLEN-1:0]         wb_link_pc  ;
wire                      wb_jrra     ;
wire                      wb_jrop     ;
wire                      wb_brop     ;
//wire                      wb_eret     ;
wire                      wb_exception;
wire [5 :0]               wb_exccode  ;
wire                      wb_esubcode ;
wire [`GRLEN-1:0]         wb_badvaddr ;
wire [31:0]               wb_badinstr ;
wire [`GRLEN-1:0]         wb_epc      ;
wire [`GRLEN-1:0]         wb_pc       ;
wire [`LSOC1K_PRU_HINT:0] wb_hint     ;
wire                      wb_taken    ;
wire                      wb_cancel   ;
wire [`GRLEN-1:0]         wb_target   ;
wire [`GRLEN-1:0]         badvaddr_ex2;
wire                      badvaddr_ex2_valid;

wire                csr_tlbp;
wire [`GRLEN-1:0]   csr_tlbop_index;
wire                csr_tlbr;

wire [`CACHE_OPNUM-1:0] cp0_cache_op_1;
wire [`CACHE_OPNUM-1:0] cp0_cache_op_2;
wire [`GRLEN-1:0]       cp0_cache_taglo;
wire [`GRLEN-1:0]       cp0_cache_taghi;
wire [`GRLEN-1:0]       cp0_cache_datalo;
wire [`GRLEN-1:0]       cp0_cache_datahi;

//csr
wire  [`GRLEN-1:0]  csr_rdata;
wire  [`LSOC1K_CSR_BIT-1 :0] csr_raddr;
wire                except_shield;
wire                int_except;
wire                cp0_status_erl;
wire                cp0_status_exl;
wire                cp0_status_bev;
wire                cp0_cause_iv;
wire  [ 2:0]        cp0_config_k0;
wire  [17:0]        cp0_ebase_exceptionbase;
wire  [`GRLEN-1:0]  cp0_epc;
wire  [`GRLEN-1:0]  eret_epc;
wire  [`GRLEN-1:0]  csr_ebase;

wire [`LSOC1K_CSR_OUTPUT_BIT-1:0] csr_output;

// tlb
wire        tlb_recv           ;
wire [`LSOC1K_TLB_CODE_BIT-1:0] tlb_op   ;
wire        tlb_finish         ;

wire [`GRLEN-1:0] tlb2cp0_index      ;
wire [`GRLEN-1:0] tlb2cp0_entryhi    ;
wire [`GRLEN-1:0] tlb2cp0_entrylo0   ;
wire [`GRLEN-1:0] tlb2cp0_entrylo1   ;
wire [`GRLEN-1:0] tlb2cp0_asid       ;
                              
wire [`GRLEN-1:0] cp02tlb_index      ;
wire [`GRLEN-1:0] cp02tlb_entryhi    ;
wire [`GRLEN-1:0] cp02tlb_entrylo0   ;
wire [`GRLEN-1:0] cp02tlb_entrylo1   ;
wire [`GRLEN-1:0] cp02tlb_asid       ;
wire [5       :0] cp02tlb_ecode      ;

wire [`GRLEN-1:0]         bru_target_input  = ex1_bru_delay ? bru_target_ex2  : bru_target ;
wire [`GRLEN-1:0]         bru_pc_input      = ex1_bru_delay ? bru_pc_ex2      : bru_pc     ;      
wire [`LSOC1K_PRU_HINT:0] bru_hint_input    = ex1_bru_delay ? bru_hint_ex2    : bru_hint   ;
wire                      bru_sign_input    = ex1_bru_delay ? bru_sign_ex2    : bru_sign   ;
wire                      bru_taken_input   = ex1_bru_delay ? bru_taken_ex2   : bru_taken  ;
wire                      bru_brop_input    = ex1_bru_delay ? bru_brop_ex2    : bru_brop   ;
wire                      bru_jrop_input    = ex1_bru_delay ? bru_jrop_ex2    : bru_jrop   ;
wire                      bru_jrra_input    = ex1_bru_delay ? bru_jrra_ex2    : bru_jrra   ;
wire                      bru_link_input    = ex1_bru_delay ? bru_link_ex2    : bru_link   ;
wire [`GRLEN-1:0]         bru_link_pc_input = ex1_bru_delay ? bru_link_pc_ex2 : bru_link_pc;
wire                      bru_cancel_input  = bru_cancel_ex2 || bru_cancel;

  // Cache Pipeline Bus
wire               data_req       ;
wire  [`GRLEN-1:0] data_pc        ;
wire               data_wr        ;
`ifdef LA64
wire  [7 :0]       data_wstrb     ;
`elsif LA32
wire  [3 :0]       data_wstrb     ;
`endif
wire  [`GRLEN-1:0] data_addr      ;
wire               data_cancel_ex2;
wire               data_cancel    ;
wire  [`GRLEN-1:0] data_wdata     ;
wire               data_recv      ;
wire               data_prefetch  ;
wire               data_ll        ;
wire               data_sc        ;

wire  [`GRLEN-1:0] data_rdata     ;
wire               data_addr_ok   ;
wire               data_data_ok   ;
wire  [ 5:0]       data_exccode   ;
wire               data_exception ;
wire  [`GRLEN-1:0] data_badvaddr  ;
wire               data_req_empty ;
wire               data_scsucceed ;

assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_REQ      ] = data_req       ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_PC       ] = data_pc        ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WR       ] = data_wr        ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WSTRB    ] = data_wstrb     ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ADDR     ] = data_addr      ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WDATA    ] = data_wdata     ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_RECV     ] = data_recv      ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_CANCEL   ] = data_cancel    ;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_EX2CANCEL] = data_cancel_ex2;
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_PREFETCH ] = data_prefetch  ; // TODO
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_LL       ] = data_ll        ; // TODO
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_SC       ] = data_sc        ; // TODO
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOM     ] = 1'b0           ; // TODO
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOMOP   ] = 5'b0           ; // TODO
assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOMSRC  ] = `GRLEN'b0          ; // TODO

assign data_rdata      = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_RDATA    ];
assign data_addr_ok    = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_ADDROK   ];
assign data_data_ok    = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_DATAOK   ];
assign data_exccode    = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_EXCCODE  ];
assign data_exception  = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_EXCEPTION];
assign data_badvaddr   = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_BADVADDR ];
assign data_req_empty  = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_REQEMPTY ];
assign data_scsucceed  = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_SCSUCCEED];

//gs232c_front gs232c_front(
//    .clock           (clk                     ),
//    .reset           (~resetn                 ),   
//    // .br_endline      (1'b0                    ),
//    .pc_init         (`GRLEN'h1c000000            ),
//
//    .br_hint         (bru_hint_input          ),
//    .br_cancel       (bru_cancel_input        ),// I, 1
//    .br_target       (bru_target_input        ),// I, 32
//    .br_taken        (bru_taken_input         ),// I, 1
//    .br_link         (bru_link_input          ),// I, 1
//    .br_jrra         (bru_jrra_input          ),// I, 1
//    .br_brop         (bru_brop_input          ),// I, 1
//    .br_jrop         (bru_jrop_input          ),// I, 1
//    .br_sign         (bru_sign_input          ),// I, 1
//    .br_pc           (bru_pc_input            ),// I, 32
//    .br_link_pc      (bru_link_pc_input[`GRLEN-1:2]),// I, 32
//
//    .wb_cancel        (wb_cancel         ),// I, 1
//    .wb_target        (wb_target         ),// I, 32
//    .wb_link          (wb_link           ),// I, 1
//    .wb_link_pc       (wb_link_pc[`GRLEN-1:2]),// I, 32
//    .wb_jrra          (wb_jrra           ),// I, 1
//    .wb_jrop          (wb_jrop           ),// I, 1
//    .wb_brop          (wb_brop           ),// I, 1
//    .wb_pc            (wb_pc             ),// I, 32
//    // .wb_endline       (1'b0              ),
//    .wb_taken         (wb_taken          ),
//
//    .inst_req         (inst_req          ),// O, 1
//    .inst_addr        (inst_addr         ),// O, 32
//    .inst_cancel      (inst_cancel       ),
//    .inst_addr_ok     (inst_addr_ok      ),// I, 1
//    .inst_valid       (inst_valid        ),// I, 8
//    .inst_count       (inst_count        ),
//    .inst_rdata       (inst_rdata        ),
//    .inst_uncache     (inst_uncache      ),// I, 1
//    .inst_ex          (inst_exception    ),// I, 1
//    .inst_exccode     (inst_exccode      ),// I, 5
//
//    .o_allow          (de2_accept         ),
//    .o_valid          ({de1_port2_valid,de1_port1_valid,de1_port0_valid}),
//    .o_port0_pc       (de1_port0_pc       ),// O, 32
//    .o_port0_inst     (de1_port0_inst     ),// O, 32
//    .o_port0_taken    (de1_port0_br_taken ),// O, 1
//    .o_port0_target   (de1_port0_br_target),// O, 30
//    .o_port0_ex       (de1_port0_exception),// O, 1
//    .o_port0_exccode  (de1_port0_exccode  ),// O, 5
//    .o_port0_hint     (de1_port0_hint     ),
//    .o_port1_pc       (de1_port1_pc       ),// O, 32
//    .o_port1_inst     (de1_port1_inst     ),// O, 32
//    .o_port1_taken    (de1_port1_br_taken ),// O, 1
//    .o_port1_target   (de1_port1_br_target),// O, 30
//    .o_port1_ex       (de1_port1_exception),// O, 1
//    .o_port1_exccode  (de1_port1_exccode  ),// O, 5
//    .o_port1_hint     (de1_port1_hint     ),
//    .o_port2_pc       (de1_port2_pc       ),// O, 32
//    .o_port2_inst     (de1_port2_inst     ),// O, 32
//    .o_port2_taken    (de1_port2_br_taken ),// O, 1
//    .o_port2_target   (de1_port2_br_target),// O, 30
//    .o_port2_ex       (de1_port2_exception),// O, 1
//    .o_port2_exccode  (de1_port2_exccode  ),// O, 5
//    .o_port2_hint     (de1_port2_hint     ),
//    
//    `LSOC1K_CONN_BHT_RAMS
//);

//lsoc1000_stage_de1 de1_stage(
    //.clk                (clk                 ),
    //.resetn             (resetn              ),
    //.allow_in           (de2_allow_in        ),
    //// port0
    //.de1_port0_valid     (de1_port0_valid    ),
    //.de1_port0_pc        (de1_port0_pc       ),
    //.de1_port0_inst      (de1_port0_inst     ),
    //.de1_port0_br_target (de1_port0_br_target),
    //.de1_port0_br_taken  (de1_port0_br_taken ),
    //.de1_port0_exception (de1_port0_exception),
    //.de1_port0_exccode   (de1_port0_exccode  ),
    //.de1_port0_hint      (de1_port0_hint     ),
    //.de1_port0_robr      (de1_port0_robr     ),
    //// port1
    //.de1_port1_valid     (de1_port1_valid    ),
    //.de1_port1_pc        (de1_port1_pc       ),
    //.de1_port1_inst      (de1_port1_inst     ),
    //.de1_port1_br_target (de1_port1_br_target),
    //.de1_port1_br_taken  (de1_port1_br_taken ),
    //.de1_port1_exception (de1_port1_exception),
    //.de1_port1_exccode   (de1_port1_exccode  ),
    //.de1_port1_hint      (de1_port1_hint     ),
    //.de1_port1_robr      (de1_port1_robr     ),
    //// port2
    //.de1_port2_valid     (de1_port2_valid    ),
    //.de1_port2_pc        (de1_port2_pc       ),
    //.de1_port2_inst      (de1_port2_inst     ),
    //.de1_port2_br_target (de1_port2_br_target),
    //.de1_port2_br_taken  (de1_port2_br_taken ),
    //.de1_port2_exception (de1_port2_exception),
    //.de1_port2_exccode   (de1_port2_exccode  ),
    //.de1_port2_hint      (de1_port2_hint     ),
    //.de1_port2_robr      (de1_port2_robr     ),
    //// port0
    //.de2_port0_valid     (de2_port0_valid    ),// O, 1
    //.de2_port0_inst      (de2_port0_inst     ),
    //.de2_port0_pc        (de2_port0_pc       ),
    //.de2_port0_br_target (de2_port0_br_target),
    //.de2_port0_br_taken  (de2_port0_br_taken ),// O, 1
    //.de2_port0_exception (de2_port0_exception),// O, 1
    //.de2_port0_exccode   (de2_port0_exccode  ),
    //.de2_port0_hint      (de2_port0_hint     ),
    //// port1
    //.de2_port1_valid     (de2_port1_valid    ),// O, 1
    //.de2_port1_inst      (de2_port1_inst     ),
    //.de2_port1_pc        (de2_port1_pc       ),
    //.de2_port1_br_target (de2_port1_br_target),
    //.de2_port1_br_taken  (de2_port1_br_taken ),// O, 1
    //.de2_port1_exception (de2_port1_exception),// O, 1
    //.de2_port1_exccode   (de2_port1_exccode  ),
    //.de2_port1_hint      (de2_port1_hint     ),
    ////port2
    //.de2_port2_valid     (de2_port2_valid    ),// O, 1
    //.de2_port2_inst      (de2_port2_inst     ),
    //.de2_port2_pc        (de2_port2_pc       ),
    //.de2_port2_br_target (de2_port2_br_target),
    //.de2_port2_br_taken  (de2_port2_br_taken ),// O, 1
    //.de2_port2_exception (de2_port2_exception),// O, 1
    //.de2_port2_hint      (de2_port2_hint     ),    
    //.de2_port2_exccode   (de2_port2_exccode  )
//);
//
//lsoc1000_stage_de2 de2_stage(
    //.clk                (clk               ),
    //.resetn             (resetn            ),
    //.exception          (wb_exception      ),
    //.eret               (wb_eret           ),
    //.int_except         (int_except        ),
    //.bru_cancel         (bru_cancel || bru_cancel_ex2),
    //.wb_cancel          (wb_cancel         ),
    //.csr_output         (csr_output        ),
    //// pipe in
    //.de2_allow_in        (de2_allow_in       ),// O, 1
    //.de2_accept          (de2_accept         ),
    //// port0
    //.de2_port0_valid     (de2_port0_valid    ),// I, 1
    //.de2_port0_pc        (de2_port0_pc       ),// I, 32
    //.de2_port0_inst      (de2_port0_inst     ),// I, 32
    //.de2_port0_br_target (de2_port0_br_target),// I, 30
    //.de2_port0_br_taken  (de2_port0_br_taken ),// I, 1
    //.de2_port0_exception (de2_port0_exception),// I, 1
    //.de2_port0_exccode   (de2_port0_exccode  ),// I, 5
    //.de2_port0_hint      (de2_port0_hint     ),
    //// port1
    //.de2_port1_valid     (de2_port1_valid    ),// I, 1
    //.de2_port1_pc        (de2_port1_pc       ),// I, 32
    //.de2_port1_inst      (de2_port1_inst     ),// I, 32
    //.de2_port1_br_target (de2_port1_br_target),// I, 30
    //.de2_port1_br_taken  (de2_port1_br_taken ),// I, 1
    //.de2_port1_exception (de2_port1_exception),// I, 1
    //.de2_port1_exccode   (de2_port1_exccode  ),// I, 5
    //.de2_port1_hint      (de2_port1_hint     ),
    //// port2
    //.de2_port2_valid     (de2_port2_valid    ),// O, 1
    //.de2_port2_inst      (de2_port2_inst     ),
    //.de2_port2_pc        (de2_port2_pc       ),
    //.de2_port2_br_target (de2_port2_br_target),
    //.de2_port2_br_taken  (de2_port2_br_taken ),// O, 1
    //.de2_port2_exception (de2_port2_exception),// O, 1
    //.de2_port2_exccode   (de2_port2_exccode  ),
    //.de2_port2_hint      (de2_port2_hint     ),
    //// barrier info
    //.data_mshr_empty     (data_req_empty    ),
    //.ex1_port0_valid     (ex1_port0_valid   ),
    //.ex1_port1_valid     (ex1_port1_valid   ),
    //.ex2_port0_valid     (ex2_port0_valid   ),
    //.ex2_port1_valid     (ex2_port1_valid   ),
    //.wb_port0_valid      (wb_port0_valid    ),
    //.wb_port1_valid      (wb_port1_valid    ),
    //// pipe out
    //.is_allow_in         (is_allow_in       ),// I, 1
    //// port0
    //.is_port0_valid      (is_port0_valid    ),// O, 1
    //.is_port0_inst       (is_port0_inst     ),// O, 32
    //.is_port0_pc         (is_port0_pc       ),// O, 32
    //.is_port0_op         (is_port0_op       ),// O, `LDECBITS
    //.is_port0_br_target  (is_port0_br_target),// O, 30
    //.is_port0_br_taken   (is_port0_br_taken ),// O, 1
    //.is_port0_exception  (is_port0_exception),// O, 1
    //.is_port0_exccode    (is_port0_exccode  ),// O, 5
    //.is_port0_hint       (is_port0_hint     ),
    //.is_port0_rf_wen     (is_port0_rf_wen   ),// O, 1
    //.is_port0_rf_target  (is_port0_rf_target),// O, 5
    //// port1
    //.is_port1_valid      (is_port1_valid    ),// O, 1
    //.is_port1_inst       (is_port1_inst     ),// O, 32
    //.is_port1_pc         (is_port1_pc       ),// O, 32
    //.is_port1_op         (is_port1_op       ),// O, `LDECBITS
    //.is_port1_br_target  (is_port1_br_target),// O, 30
    //.is_port1_br_taken   (is_port1_br_taken ),// O, 1
    //.is_port1_exception  (is_port1_exception),// O, 1
    //.is_port1_exccode    (is_port1_exccode  ),// O, 5
    //.is_port1_hint       (is_port1_hint     ),
    //.is_port1_rf_wen     (is_port1_rf_wen   ),// O, 1
    //.is_port1_rf_target  (is_port1_rf_target),// O, 5
    //// port2
    //.is_port2_valid      (is_port2_valid    ),// O, 1
    //.is_port2_app        (is_port2_app      ),
    //.is_port2_id         (is_port2_id       ),
    //.is_port2_inst       (is_port2_inst     ),// O, 32
    //.is_port2_pc         (is_port2_pc       ),// O, 32
    //.is_port2_op         (is_port2_op       ),// O, `LDECBITS
    //.is_port2_br_target  (is_port2_br_target),// O, 30
    //.is_port2_br_taken   (is_port2_br_taken ),// O, 1
    //.is_port2_exception  (is_port2_exception),// O, 1
    //.is_port2_exccode    (is_port2_exccode  ),// O, 5
    //.is_port2_hint       (is_port2_hint     )
//);

//gs232c_front gs232c_front(
cpu7_ifu_fdp cpu7_ifu_fdp(
    .clock           (clk                     ),
    .reset           (~resetn                 ),   
    // .br_endline      (1'b0                    ),
    .pc_init         (`GRLEN'h1c000000            ),

    .br_hint         (bru_hint_input          ),
    .br_cancel       (bru_cancel_input        ),// I, 1
    .br_target       (bru_target_input        ),// I, 32
    .br_taken        (bru_taken_input         ),// I, 1
    .br_link         (bru_link_input          ),// I, 1
    .br_jrra         (bru_jrra_input          ),// I, 1
    .br_brop         (bru_brop_input          ),// I, 1
    .br_jrop         (bru_jrop_input          ),// I, 1
    .br_sign         (bru_sign_input          ),// I, 1
    .br_pc           (bru_pc_input            ),// I, 32
    .br_link_pc      (bru_link_pc_input[`GRLEN-1:2]),// I, 32

    .wb_cancel        (wb_cancel         ),// I, 1
    .wb_target        (wb_target         ),// I, 32
    .wb_link          (wb_link           ),// I, 1
    .wb_link_pc       (wb_link_pc[`GRLEN-1:2]),// I, 32
    .wb_jrra          (wb_jrra           ),// I, 1
    .wb_jrop          (wb_jrop           ),// I, 1
    .wb_brop          (wb_brop           ),// I, 1
    .wb_pc            (wb_pc             ),// I, 32
    // .wb_endline       (1'b0              ),
    .wb_taken         (wb_taken          ),

    .inst_req         (inst_req          ),// O, 1
    .inst_addr        (inst_addr         ),// O, 32
    .inst_cancel      (inst_cancel       ),
    .inst_addr_ok     (inst_addr_ok      ),// I, 1
    .inst_valid       (inst_valid        ),// I, 8
    .inst_count       (inst_count        ),
    .inst_rdata       (inst_rdata        ),
    .inst_uncache     (inst_uncache      ),// I, 1
    .inst_ex          (inst_exception    ),// I, 1
    .inst_exccode     (inst_exccode      ),// I, 5

    .o_allow          (de_accept         ),
    .o_valid          ({de_port2_valid,de_port1_valid,de_port0_valid}),
    .o_port0_pc       (de_port0_pc       ),// O, 32
    .o_port0_inst     (de_port0_inst     ),// O, 32
    .o_port0_taken    (de_port0_br_taken ),// O, 1
    .o_port0_target   (de_port0_br_target),// O, 30
    .o_port0_ex       (de_port0_exception),// O, 1
    .o_port0_exccode  (de_port0_exccode  ),// O, 5
    .o_port0_hint     (de_port0_hint     ),
    .o_port1_pc       (de_port1_pc       ),// O, 32
    .o_port1_inst     (de_port1_inst     ),// O, 32
    .o_port1_taken    (de_port1_br_taken ),// O, 1
    .o_port1_target   (de_port1_br_target),// O, 30
    .o_port1_ex       (de_port1_exception),// O, 1
    .o_port1_exccode  (de_port1_exccode  ),// O, 5
    .o_port1_hint     (de_port1_hint     ),
    .o_port2_pc       (de_port2_pc       ),// O, 32
    .o_port2_inst     (de_port2_inst     ),// O, 32
    .o_port2_taken    (de_port2_br_taken ),// O, 1
    .o_port2_target   (de_port2_br_target),// O, 30
    .o_port2_ex       (de_port2_exception),// O, 1
    .o_port2_exccode  (de_port2_exccode  ),// O, 5
    .o_port2_hint     (de_port2_hint     ),
    
    `LSOC1K_CONN_BHT_RAMS
);

   
lsoc1000_stage_de de_stage(
    .clk                (clk               ),
    .resetn             (resetn            ),
    .exception          (wb_exception      ),
    .eret               (wb_eret           ),
    .int_except         (int_except        ),
    .bru_cancel         (bru_cancel || bru_cancel_ex2),
    .wb_cancel          (wb_cancel         ),
    .csr_output         (csr_output        ),
    // pipe in
    .de_allow_in        (de_allow_in       ),// O, 1
    .de_accept          (de_accept         ),
    // port0
    .de_port0_valid     (de_port0_valid    ),// I, 1
    .de_port0_pc        (de_port0_pc       ),// I, 32
    .de_port0_inst      (de_port0_inst     ),// I, 32
    .de_port0_br_target (de_port0_br_target),// I, 30
    .de_port0_br_taken  (de_port0_br_taken ),// I, 1
    .de_port0_exception (de_port0_exception),// I, 1
    .de_port0_exccode   (de_port0_exccode  ),// I, 5
    .de_port0_hint      (de_port0_hint     ),
    // port1
    .de_port1_valid     (de_port1_valid    ),// I, 1
    .de_port1_pc        (de_port1_pc       ),// I, 32
    .de_port1_inst      (de_port1_inst     ),// I, 32
    .de_port1_br_target (de_port1_br_target),// I, 30
    .de_port1_br_taken  (de_port1_br_taken ),// I, 1
    .de_port1_exception (de_port1_exception),// I, 1
    .de_port1_exccode   (de_port1_exccode  ),// I, 5
    .de_port1_hint      (de_port1_hint     ),
    // port2
    .de_port2_valid     (de_port2_valid    ),// O, 1
    .de_port2_inst      (de_port2_inst     ),
    .de_port2_pc        (de_port2_pc       ),
    .de_port2_br_target (de_port2_br_target),
    .de_port2_br_taken  (de_port2_br_taken ),// O, 1
    .de_port2_exception (de_port2_exception),// O, 1
    .de_port2_exccode   (de_port2_exccode  ),
    .de_port2_hint      (de_port2_hint     ),
    // barrier info
    .data_mshr_empty     (data_req_empty    ),
    .ex1_port0_valid     (ex1_port0_valid   ),
    .ex1_port1_valid     (ex1_port1_valid   ),
    .ex2_port0_valid     (ex2_port0_valid   ),
    .ex2_port1_valid     (ex2_port1_valid   ),
    .wb_port0_valid      (wb_port0_valid    ),
    .wb_port1_valid      (wb_port1_valid    ),
    // pipe out
    .is_allow_in         (is_allow_in       ),// I, 1
    // port0
    .is_port0_valid      (is_port0_valid    ),// O, 1
    .is_port0_inst       (is_port0_inst     ),// O, 32
    .is_port0_pc         (is_port0_pc       ),// O, 32
    .is_port0_op         (is_port0_op       ),// O, `LDECBITS
    .is_port0_br_target  (is_port0_br_target),// O, 30
    .is_port0_br_taken   (is_port0_br_taken ),// O, 1
    .is_port0_exception  (is_port0_exception),// O, 1
    .is_port0_exccode    (is_port0_exccode  ),// O, 5
    .is_port0_hint       (is_port0_hint     ),
    .is_port0_rf_wen     (is_port0_rf_wen   ),// O, 1
    .is_port0_rf_target  (is_port0_rf_target),// O, 5
    // port1
    .is_port1_valid      (is_port1_valid    ),// O, 1
    .is_port1_inst       (is_port1_inst     ),// O, 32
    .is_port1_pc         (is_port1_pc       ),// O, 32
    .is_port1_op         (is_port1_op       ),// O, `LDECBITS
    .is_port1_br_target  (is_port1_br_target),// O, 30
    .is_port1_br_taken   (is_port1_br_taken ),// O, 1
    .is_port1_exception  (is_port1_exception),// O, 1
    .is_port1_exccode    (is_port1_exccode  ),// O, 5
    .is_port1_hint       (is_port1_hint     ),
    .is_port1_rf_wen     (is_port1_rf_wen   ),// O, 1
    .is_port1_rf_target  (is_port1_rf_target),// O, 5
    // port2
    .is_port2_valid      (is_port2_valid    ),// O, 1
    .is_port2_app        (is_port2_app      ),
    .is_port2_id         (is_port2_id       ),
    .is_port2_inst       (is_port2_inst     ),// O, 32
    .is_port2_pc         (is_port2_pc       ),// O, 32
    .is_port2_op         (is_port2_op       ),// O, `LDECBITS
    .is_port2_br_target  (is_port2_br_target),// O, 30
    .is_port2_br_taken   (is_port2_br_taken ),// O, 1
    .is_port2_exception  (is_port2_exception),// O, 1
    .is_port2_exccode    (is_port2_exccode  ),// O, 5
    .is_port2_hint       (is_port2_hint     )
);

   
reg_file registers(
	.clk        (clk        ),

	.waddr1     (waddr1     ),// I, 32
	.raddr0_0   (raddr0_0   ),// I, 32
	.raddr0_1   (raddr0_1   ),// I, 32
	.wen1       (wen1       ),// I, 1
	.wdata1     (wdata1     ),// I, 32
	.rdata0_0   (rdata0_0   ),// O, 32
	.rdata0_1   (rdata0_1   ),// O, 32

	.waddr2     (waddr2     ),// I, 32
	.raddr1_0   (raddr1_0   ),// I, 32
	.raddr1_1   (raddr1_1   ),// I, 32
	.wen2       (wen2       ),// I, 1
	.wdata2     (wdata2     ),// I, 32
	.rdata1_0   (rdata1_0   ),// O, 32
	.rdata1_1   (rdata1_1   ),// O, 32

	.raddr2_0   (raddr2_0   ),// I, 32
	.raddr2_1   (raddr2_1   ),// I, 32
	.rdata2_0   (rdata2_0   ),// O, 32
	.rdata2_1   (rdata2_1   ) // O, 32
);

//lsoc1000_stage_is is_stage(
lsoc1000_stage_issue is_stage(
    .clk                (clk                ),
    .resetn             (resetn             ),
    //exception
    .exception          (wb_exception       ),
    .eret               (wb_eret            ),
    .wb_cancel          (wb_cancel || bru_cancel_ex2),
    .bru_cancel         (bru_cancel         ),
    .bru_cancel_all     (bru_cancel_all     ),
    .bru_ignore         (bru_ignore         ),
    .bru_port           (bru_port           ),
    //regiter interface
    .raddr0_0           (raddr0_0           ),
    .raddr0_1           (raddr0_1           ),
    .raddr1_0           (raddr1_0           ),
    .raddr1_1           (raddr1_1           ),
    .raddr2_0           (raddr2_0           ),
    .raddr2_1           (raddr2_1           ),
    .rdata0_0           (rdata0_0           ),
    .rdata0_1           (rdata0_1           ),
    .rdata1_0           (rdata1_0           ),
    .rdata1_1           (rdata1_1           ),
    .rdata2_0           (rdata2_0           ),
    .rdata2_1           (rdata2_1           ),
    //cp0 register interface
    .csr_raddr          (csr_raddr          ),
    .csr_rdata          (csr_rdata          ),
    // pipe in
    .is_allow_in        (is_allow_in        ),
    // port0
    .is_port0_valid     (is_port0_valid     ),
    .is_port0_pc        (is_port0_pc        ),
    .is_port0_inst      (is_port0_inst      ),
    .is_port0_op        (is_port0_op        ),
    .is_port0_br_target (is_port0_br_target ),
    .is_port0_br_taken  (is_port0_br_taken  ),
    .is_port0_exception (is_port0_exception ),
    .is_port0_exccode   (is_port0_exccode   ),
    .is_port0_hint      (is_port0_hint      ),
    .is_port0_rf_wen    (is_port0_rf_wen    ),
    .is_port0_rf_target (is_port0_rf_target ),
    // port1
    .is_port1_valid     (is_port1_valid     ),
    .is_port1_pc        (is_port1_pc        ),
    .is_port1_inst      (is_port1_inst      ),
    .is_port1_op        (is_port1_op        ),
    .is_port1_br_target (is_port1_br_target ),
    .is_port1_br_taken  (is_port1_br_taken  ),
    .is_port1_exception (is_port1_exception ),
    .is_port1_exccode   (is_port1_exccode   ),
    .is_port1_hint      (is_port1_hint      ),
    .is_port1_rf_wen    (is_port1_rf_wen    ),
    .is_port1_rf_target (is_port1_rf_target ),
    // port2
    .is_port2_valid      (is_port2_valid    ),
    .is_port2_app        (is_port2_app      ),
    .is_port2_id         (is_port2_id       ),
    .is_port2_inst       (is_port2_inst     ),
    .is_port2_pc         (is_port2_pc       ),
    .is_port2_op         (is_port2_op       ),
    .is_port2_br_target  (is_port2_br_target),
    .is_port2_br_taken   (is_port2_br_taken ),
    .is_port2_exception  (is_port2_exception),
    .is_port2_exccode    (is_port2_exccode  ),
    .is_port2_hint       (is_port2_hint     ),
    // pipe out
    .ex1_allow_in       (ex1_allow_in       ),
    .ex2_allow_in       (ex2_allow_in       ),
    // port0
    .ex1_port0_inst     (ex1_port0_inst     ),
    .ex1_port0_pc       (ex1_port0_pc       ),
    .ex1_port0_src      (ex1_port0_src      ),
    .ex1_port0_valid    (ex1_port0_valid    ),
    .ex1_port0_rf_target(ex1_port0_rf_target),
    .ex1_port0_rf_wen   (ex1_port0_rf_wen   ),
    .ex1_port0_ll       (ex1_port0_ll       ),
    .ex1_port0_sc       (ex1_port0_sc       ),
    .ex1_port0_type     (ex1_port0_type     ),
    // port1
    .ex1_port1_inst     (ex1_port1_inst     ),
    .ex1_port1_pc       (ex1_port1_pc       ),
    .ex1_port1_src      (ex1_port1_src      ),
    .ex1_port1_valid    (ex1_port1_valid    ),
    .ex1_port1_rf_target(ex1_port1_rf_target),
    .ex1_port1_rf_wen   (ex1_port1_rf_wen   ),
    .ex1_port1_ll       (ex1_port1_ll       ),
    .ex1_port1_sc       (ex1_port1_sc       ),
    .ex1_port1_type     (ex1_port1_type     ),
    // port2
    .ex1_port2_type     (ex1_port2_type     ),
    //REG
    .ex1_lsu_fw_data    (ex1_lsu_fw_data    ),
    .ex1_rdata0_0_lsu_fw(ex1_rdata0_0_lsu_fw),
    .ex1_rdata0_1_lsu_fw(ex1_rdata0_1_lsu_fw),
    .ex1_rdata1_0_lsu_fw(ex1_rdata1_0_lsu_fw),
    .ex1_rdata1_1_lsu_fw(ex1_rdata1_1_lsu_fw),
    .ex1_port0_a_lsu_fw (ex1_port0_a_lsu_fw ),
    .ex1_port0_b_lsu_fw (ex1_port0_b_lsu_fw ),
    .ex1_port1_a_lsu_fw (ex1_port1_a_lsu_fw ),
    .ex1_port1_b_lsu_fw (ex1_port1_b_lsu_fw ),
    .ex1_mdu_a_lsu_fw   (ex1_mdu_a_lsu_fw   ),
    .ex1_mdu_b_lsu_fw   (ex1_mdu_b_lsu_fw   ),
    .ex1_bru_a_lsu_fw   (ex1_bru_a_lsu_fw   ),
    .ex1_bru_b_lsu_fw   (ex1_bru_b_lsu_fw   ),
    .ex1_lsu_base_lsu_fw(ex1_lsu_base_lsu_fw),
    .ex1_lsu_offset_lsu_fw(ex1_lsu_offset_lsu_fw),
    .ex1_lsu_wdata_lsu_fw(ex1_lsu_wdata_lsu_fw),
    //ALU1
    .ex1_port0_a        (ex1_port0_a        ),
    .ex1_port0_b        (ex1_port0_b        ),   
    .ex1_port0_op       (ex1_port0_op       ),
    .ex1_port0_c        (ex1_port0_c        ),
    .ex1_port0_a_ignore (ex1_port0_a_ignore ),
    .ex1_port0_b_ignore (ex1_port0_b_ignore ),
    .ex1_port0_b_get_a  (ex1_port0_b_get_a  ),
    .ex1_port0_double   (ex1_port0_double   ),
    //ALU2
    .ex1_port1_a        (ex1_port1_a        ),
    .ex1_port1_b        (ex1_port1_b        ),
    .ex1_port1_op       (ex1_port1_op       ),
    .ex1_port1_c        (ex1_port1_c        ),
    .ex1_port1_a_ignore (ex1_port1_a_ignore ),
    .ex1_port1_b_ignore (ex1_port1_b_ignore ),
    .ex1_port1_b_get_a  (ex1_port1_b_get_a  ),
    .ex1_port1_double   (ex1_port1_double   ),
    //MDU
    .ex1_mdu_op         (ex1_mdu_op         ),
    .ex1_mdu_a          (ex1_mdu_a          ),
    .ex1_mdu_b          (ex1_mdu_b          ),   
    //LSU
    .ex1_lsu_op         (ex1_lsu_op         ), 
    .ex1_lsu_base       (ex1_lsu_base       ),
    .ex1_lsu_offset     (ex1_lsu_offset     ),
    .ex1_lsu_wdata      (ex1_lsu_wdata      ),
    //BRU
    .bru_delay          (bru_delay          ),
    .ex1_bru_delay      (ex1_bru_delay      ),
    .ex1_bru_op         (ex1_bru_op         ),
    .ex1_bru_a          (ex1_bru_a          ),
    .ex1_bru_b          (ex1_bru_b          ),
    .ex1_bru_br_taken   (ex1_bru_br_taken   ),
    .ex1_bru_br_target  (ex1_bru_br_target  ),
    .ex1_bru_hint       (ex1_bru_hint       ),
    .ex1_bru_link       (ex1_bru_link       ),
    .ex1_bru_jrra       (ex1_bru_jrra       ),
    .ex1_bru_brop       (ex1_bru_brop       ),
    .ex1_bru_jrop       (ex1_bru_jrop       ),
    .ex1_bru_offset     (ex1_bru_offset     ),
    .ex1_bru_pc         (ex1_bru_pc         ),
    .ex1_bru_port       (ex1_bru_port       ),
    .ex1_branch_valid   (ex1_branch_valid   ),
    //NONE0
    .ex1_none0_result   (ex1_none0_result   ),
    .ex1_none0_exception(ex1_none0_exception),
    .ex1_none0_csr_addr (ex1_none0_csr_addr ),
    .ex1_none0_op       (ex1_none0_op       ),
    .ex1_none0_exccode  (ex1_none0_exccode  ),
    .ex1_none0_csr_a    (ex1_none0_csr_a    ),
    .ex1_none0_csr_result(ex1_none0_csr_result),
    .ex1_none0_info     (ex1_none0_info     ),
    //NONE1
    .ex1_none1_result   (ex1_none1_result   ),
    .ex1_none1_exception(ex1_none1_exception),
    .ex1_none1_csr_addr (ex1_none1_csr_addr ),
    .ex1_none1_op       (ex1_none1_op       ),
    .ex1_none1_exccode  (ex1_none1_exccode  ),
    .ex1_none1_csr_a    (ex1_none1_csr_a    ),
    .ex1_none1_csr_result(ex1_none1_csr_result),
    .ex1_none1_info     (ex1_none1_info     ),
    //forwarding related
    .ex1_raddr0_0       (ex1_raddr0_0       ),
    .ex1_raddr0_1       (ex1_raddr0_1       ),
    .ex1_raddr1_0       (ex1_raddr1_0       ),
    .ex1_raddr1_1       (ex1_raddr1_1       ),
    .ex1_raddr2_0       (ex1_raddr2_0       ),
    .ex1_raddr2_1       (ex1_raddr2_1       ),

    .ex1_alu0_res       (ex1_alu0_res       ),
    .ex1_alu1_res       (ex1_alu1_res       ),
    .ex1_bru_res        (bru_link_pc        ),
    .ex1_none0_res      (ex1_none0_result   ),
    .ex1_none1_res      (ex1_none1_result   ),

    .ex2_port0_src       (ex2_port0_src      ),
    .ex2_port0_valid     (ex2_port0_valid    ),
    .ex2_port0_rf_target (ex2_port0_rf_target),
    .ex2_port1_src       (ex2_port1_src      ),
    .ex2_port1_valid     (ex2_port1_valid    ),
    .ex2_port1_rf_target (ex2_port1_rf_target),

    .ex2_alu0_res       (ex2_alu0_res       ),
    .ex2_alu1_res       (ex2_alu1_res       ),
    .ex2_lsu_res        (ex2_lsu_res        ),
    .ex2_bru_res        (ex2_bru_link_pc    ),
    .ex2_none0_res      (ex2_none0_result   ),
    .ex2_none1_res      (ex2_none1_result   ),
    .ex2_mul_res        (ex2_mul_res        ),
    .ex2_div_res        (ex2_div_res        )
);

wire              mul_valid    ;
wire [`GRLEN-1:0] mul_a        ;
wire [`GRLEN-1:0] mul_b        ;
wire              mul_signed   ;
wire              mul_double   ;
wire              mul_hi       ;
wire              mul_short    ;
wire              ex2_mul_ready; // multiplier removed

`ifdef LA64
mul64x64 mul(
    .clk                (clk            ),
    .rstn               (resetn         ),

    .mul_validin        (mul_valid      ),
    .ex2_allowin        (ex2_allow_in   ),
    .mul_validout       (ex2_mul_ready  ),
	.ex1_readygo        (ex1_allow_in	),
    .ex2_readygo        (ex2_allow_in   ),

    .opa                (mul_a          ),
    .opb                (mul_b          ),
    .mul_signed         (mul_signed     ),
    .mul64              (mul_double     ),
    .mul_hi             (mul_hi         ),
    .mul_short          (mul_short      ),

    .mul_res_out        (ex2_mul_res    ),
    .mul_ready          (ex1_mul_ready  )
);
`elsif LA32
wire [63:0] mul_a_input = {32'b0,mul_a};
wire [63:0] mul_b_input = {32'b0,mul_b};
wire [63:0] mul_res_output;
assign ex2_mul_res = mul_res_output[31:0];
mul64x64 mul(
    .clk                (clk            ),
    .rstn               (resetn         ),

    .mul_validin        (mul_valid      ),
    .ex2_allowin        (ex2_allow_in   ),
    .mul_validout       (ex2_mul_ready  ),
	.ex1_readygo        (ex1_allow_in	),
    .ex2_readygo        (ex2_allow_in   ),

    .opa                (mul_a_input    ),
    .opb                (mul_b_input    ),
    .mul_signed         (mul_signed     ),
    .mul64              (mul_double     ),
    .mul_hi             (mul_hi         ),
    .mul_short          (mul_short      ),

    .mul_res_out        (mul_res_output ),
    .mul_ready          (ex1_mul_ready  )
);
`endif

wire              div_valid    ;
wire [`GRLEN-1:0] div_a        ;
wire [`GRLEN-1:0] div_b        ;
wire              div_signed   ;
wire              div_double   ;
wire              div_mod      ;
wire              ex1_div_ready;

`ifdef LA32

div div(
    .div_clk            (clk          ), 
    .resetn             (resetn       ),
    .div                (div_valid    ),
    .div_signed         (div_signed   ),
    .div_mod            (div_mod      ),
    .x                  (div_a        ), 
    .y                  (div_b        ),
    .result             (ex2_div_res  ),
    .div_ready          (ex1_div_ready)
);
`endif

ex1_stage ex1_stage(
    .clk                (clk                ),
    .resetn             (resetn             ),
    //basic
    //exception
    .exception          (wb_exception       ),
    .eret               (wb_eret            ),
    .lsu_badvaddr       (lsu_badvaddr       ),
    .wb_cancel          (wb_cancel          ),
    .bru_cancel_ex2     (bru_cancel_ex2     ),
    .bru_port_ex2       (bru_port_ex2       ),
    .bru_ignore_ex2     (bru_ignore_ex2     ),
    .bru_cancel_all_ex2 (bru_cancel_all_ex2 ),
    .csr_output         (csr_output         ),
    // pipe in 
    .ex1_allow_in       (ex1_allow_in       ),
    // port0
    .ex1_port0_valid    (ex1_port0_valid    ),
    .ex1_port0_pc       (ex1_port0_pc       ),
    .ex1_port0_inst     (ex1_port0_inst     ),
    .ex1_port0_src      (ex1_port0_src      ),
    .ex1_port0_rf_target(ex1_port0_rf_target),
    .ex1_port0_rf_wen   (ex1_port0_rf_wen   ),
    .ex1_port0_ll       (ex1_port0_ll       ),
    .ex1_port0_sc       (ex1_port0_sc       ),
    .ex1_port0_type     (ex1_port0_type     ),
    // port1
    .ex1_port1_valid    (ex1_port1_valid    ),
    .ex1_port1_pc       (ex1_port1_pc       ),
    .ex1_port1_inst     (ex1_port1_inst     ),
    .ex1_port1_src      (ex1_port1_src      ),
    .ex1_port1_rf_target(ex1_port1_rf_target),
    .ex1_port1_rf_wen   (ex1_port1_rf_wen   ),
    .ex1_port1_ll       (ex1_port1_ll       ),
    .ex1_port1_sc       (ex1_port1_sc       ),
    .ex1_port1_type     (ex1_port1_type     ),
    // port2
    .ex1_port2_type     (ex1_port2_type     ),
    // pipe out
    .ex2_allow_in       (ex2_allow_in       ),
    // port0
    .ex2_port0_src      (ex2_port0_src      ),
    .ex2_port0_valid    (ex2_port0_valid    ),
    .ex2_port0_pc       (ex2_port0_pc       ),
    .ex2_port0_inst     (ex2_port0_inst     ),
    .ex2_port0_rf_target(ex2_port0_rf_target),
    .ex2_port0_rf_wen   (ex2_port0_rf_wen   ),
    .ex2_port0_ll       (ex2_port0_ll       ),
    .ex2_port0_sc       (ex2_port0_sc       ),
    .ex2_port0_type     (ex2_port0_type     ),
    // port1
    .ex2_port1_src      (ex2_port1_src      ),
    .ex2_port1_valid    (ex2_port1_valid    ),
    .ex2_port1_pc       (ex2_port1_pc       ),
    .ex2_port1_inst     (ex2_port1_inst     ),
    .ex2_port1_rf_target(ex2_port1_rf_target),
    .ex2_port1_rf_wen   (ex2_port1_rf_wen   ),
    .ex2_port1_ll       (ex2_port1_ll       ),
    .ex2_port1_sc       (ex2_port1_sc       ),
    .ex2_port1_type     (ex2_port1_type     ),
    // port2
    .ex2_port2_type     (ex2_port2_type     ),
    //REG
    .ex1_lsu_fw_data    (ex1_lsu_fw_data    ),
    .ex1_rdata0_0_lsu_fw(ex1_rdata0_0_lsu_fw),
    .ex1_rdata0_1_lsu_fw(ex1_rdata0_1_lsu_fw),
    .ex1_rdata1_0_lsu_fw(ex1_rdata1_0_lsu_fw),
    .ex1_rdata1_1_lsu_fw(ex1_rdata1_1_lsu_fw),
    .ex1_port0_a_lsu_fw (ex1_port0_a_lsu_fw ),
    .ex1_port0_b_lsu_fw (ex1_port0_b_lsu_fw ),
    .ex1_port1_a_lsu_fw (ex1_port1_a_lsu_fw ),
    .ex1_port1_b_lsu_fw (ex1_port1_b_lsu_fw ),
    .ex1_mdu_a_lsu_fw   (ex1_mdu_a_lsu_fw   ),
    .ex1_mdu_b_lsu_fw   (ex1_mdu_b_lsu_fw   ),
    .ex1_bru_a_lsu_fw   (ex1_bru_a_lsu_fw   ),
    .ex1_bru_b_lsu_fw   (ex1_bru_b_lsu_fw   ),
    .ex1_lsu_base_lsu_fw(ex1_lsu_base_lsu_fw),
    .ex1_lsu_offset_lsu_fw(ex1_lsu_offset_lsu_fw),
    .ex1_lsu_wdata_lsu_fw(ex1_lsu_wdata_lsu_fw),

    .ex2_lsu_fw_data    (ex2_lsu_fw_data    ),
    .ex2_rdata0_0_lsu_fw(ex2_rdata0_0_lsu_fw),
    .ex2_rdata0_1_lsu_fw(ex2_rdata0_1_lsu_fw),
    .ex2_rdata1_0_lsu_fw(ex2_rdata1_0_lsu_fw),
    .ex2_rdata1_1_lsu_fw(ex2_rdata1_1_lsu_fw),
    .ex2_bru_a_lsu_fw   (ex2_bru_a_lsu_fw   ),
    .ex2_bru_b_lsu_fw   (ex2_bru_b_lsu_fw   ),
    //ALU0
    .ex1_port0_a        (ex1_port0_a        ),
    .ex1_port0_b        (ex1_port0_b        ),
    .ex1_port0_op       (ex1_port0_op       ),
    .ex1_port0_c        (ex1_port0_c        ),
    .ex1_port0_double   (ex1_port0_double   ),
    .ex2_port0_a        (ex2_port0_a        ),
    .ex2_port0_b        (ex2_port0_b        ),
    .ex2_port0_c        (ex2_port0_c        ),
    .ex2_port0_op       (ex2_port0_op       ),
    .ex2_port0_double   (ex2_port0_double   ),
    .ex1_alu0_res       (ex1_alu0_res       ),
    .ex1_port0_a_ignore (ex1_port0_a_ignore ),
    .ex1_port0_b_ignore (ex1_port0_b_ignore ),
    .ex1_port0_b_get_a  (ex1_port0_b_get_a  ),
    //ALU1
    .ex1_port1_a        (ex1_port1_a        ),
    .ex1_port1_b        (ex1_port1_b        ),
    .ex1_port1_op       (ex1_port1_op       ),
    .ex1_port1_c        (ex1_port1_c        ),
    .ex1_port1_double   (ex1_port1_double   ),
    .ex2_port1_a        (ex2_port1_a        ),
    .ex2_port1_b        (ex2_port1_b        ),
    .ex2_port1_c        (ex2_port1_c        ),
    .ex2_port1_op       (ex2_port1_op       ),
    .ex2_port1_double   (ex2_port1_double   ),
    .ex1_alu1_res       (ex1_alu1_res       ),
    .ex1_port1_a_ignore (ex1_port1_a_ignore ),
    .ex1_port1_b_ignore (ex1_port1_b_ignore ),
    .ex1_port1_b_get_a  (ex1_port1_b_get_a  ),
    //MDU
    .ex1_mdu_op         (ex1_mdu_op         ),
    .ex1_mdu_a          (ex1_mdu_a          ), 
    .ex1_mdu_b          (ex1_mdu_b          ),   
    .ex2_mdu_op         (ex2_mdu_op         ),
    .ex2_mdu_a          (ex2_mdu_a          ),
    .ex2_mdu_b          (ex2_mdu_b          ),

    .mul_valid          (mul_valid          ),
    .mul_a              (mul_a              ),
    .mul_b              (mul_b              ),
    .mul_signed         (mul_signed         ),
    .mul_double         (mul_double         ),
    .mul_hi             (mul_hi             ),
    .mul_short          (mul_short          ),

    .div_valid          (div_valid          ),
    .div_a              (div_a              ),
    .div_b              (div_b              ),
    .div_signed         (div_signed         ),
    .div_double         (div_double         ),
    .div_mod            (div_mod            ),

    .ex1_mul_ready      (ex1_mul_ready      ),
    .ex2_mul_res        (ex2_mul_res        ),
    .ex1_div_ready      (ex1_div_ready      ),
    .ex2_div_res        (ex2_div_res        ),
    //BRU
    .ex1_bru_delay      (ex1_bru_delay      ),
    .ex1_bru_op         (ex1_bru_op         ),
    .ex1_bru_a          (ex1_bru_a          ),
    .ex1_bru_b          (ex1_bru_b          ),
    .ex1_bru_br_taken   (ex1_bru_br_taken   ),
    .ex1_bru_br_target  (ex1_bru_br_target  ),
    .ex1_bru_hint       (ex1_bru_hint       ),
    .ex1_bru_link       (ex1_bru_link       ),
    .ex1_bru_jrra       (ex1_bru_jrra       ),
    .ex1_bru_brop       (ex1_bru_brop       ),
    .ex1_bru_jrop       (ex1_bru_jrop       ),
    .ex1_bru_offset     (ex1_bru_offset     ),
    .ex1_bru_pc         (ex1_bru_pc         ),
    .ex1_bru_port       (ex1_bru_port       ),
    .ex1_branch_valid   (ex1_branch_valid   ),

    .bru_cancel         (bru_cancel         ),
    .bru_cancel_all     (bru_cancel_all     ),
    .bru_ignore         (bru_ignore         ),
    .bru_port           (bru_port           ),
    .bru_pc             (bru_pc             ),
    .bru_target         (bru_target         ),
    .bru_valid          (bru_valid          ),
    .bru_hint           (bru_hint           ),
    .bru_sign           (bru_sign           ),
    .bru_taken          (bru_taken          ),
    .bru_brop           (bru_brop           ),
    .bru_jrop           (bru_jrop           ),
    .bru_jrra           (bru_jrra           ),
    .bru_link           (bru_link           ),
    .bru_link_pc        (bru_link_pc        ),
    .bru_delay          (bru_delay          ),
    
    .ex2_bru_delay      (ex2_bru_delay      ),
    .ex2_bru_op         (ex2_bru_op         ),
    .ex2_bru_a          (ex2_bru_a          ),
    .ex2_bru_b          (ex2_bru_b          ),
    .ex2_bru_br_taken   (ex2_bru_br_taken   ),
    .ex2_bru_br_target  (ex2_bru_br_target  ),
    .ex2_bru_offset     (ex2_bru_offset     ),
    .ex2_bru_link_pc    (ex2_bru_link_pc    ),
    .ex2_bru_link       (ex2_bru_link       ),
    .ex2_bru_jrra       (ex2_bru_jrra       ),
    .ex2_bru_jrop       (ex2_bru_jrop       ),
    .ex2_bru_brop       (ex2_bru_brop       ),
    .ex2_bru_port       (ex2_bru_port       ),
    .ex2_bru_valid      (ex2_bru_valid      ),
    .ex2_bru_hint       (ex2_bru_hint       ),
    .ex2_bru_pc         (ex2_bru_pc         ),

    //LSU
    .ex1_lsu_op         (ex1_lsu_op         ), 
    .ex1_lsu_base       (ex1_lsu_base       ),
    .ex1_lsu_offset     (ex1_lsu_offset     ),
    .ex1_lsu_wdata      (ex1_lsu_wdata      ),
    .ex2_lsu_shift      (ex2_lsu_shift      ),
    .ex2_lsu_op         (ex2_lsu_op         ), 
    .ex2_lsu_wdata      (ex2_lsu_wdata      ),
    .ex2_lsu_recv       (ex2_lsu_recv       ),
    .ex2_lsu_ale        (ex2_lsu_ale        ),
    .ex2_lsu_adem       (ex2_lsu_adem       ),
    //NONE0
    .ex1_none0_result   (ex1_none0_result   ),
    .ex1_none0_exception(ex1_none0_exception),
    .ex1_none0_exccode  (ex1_none0_exccode  ),
    .ex1_none0_csr_result(ex1_none0_csr_result),
    .ex1_none0_csr_addr (ex1_none0_csr_addr ),
    .ex2_none0_result   (ex2_none0_result   ),
    .ex2_none0_exception(ex2_port0_exception),
    .ex2_none0_exccode  (ex2_port0_exccode  ),
    .ex1_none0_csr_a    (ex1_none0_csr_a    ),
    .ex2_none0_csr_result(ex2_none0_csr_result),
    .ex2_none0_csr_addr (ex2_none0_csr_addr ),
    .ex1_none0_op       (ex1_none0_op       ), 
    .ex2_none0_op       (ex2_none0_op       ),
    .ex1_none0_info     (ex1_none0_info     ),
    .ex2_none0_info     (ex2_none0_info     ),
    //NONE1
    .ex1_none1_result   (ex1_none1_result   ),
    .ex1_none1_exception(ex1_none1_exception),
    .ex1_none1_exccode  (ex1_none1_exccode  ),
    .ex1_none1_csr_a    (ex1_none1_csr_a    ),
    .ex1_none1_csr_result(ex1_none1_csr_result),
    .ex1_none1_csr_addr (ex1_none1_csr_addr ),
    .ex2_none1_result   (ex2_none1_result   ),
    .ex2_none1_exception(ex2_port1_exception),
    .ex2_none1_exccode  (ex2_port1_exccode  ),
    .ex2_none1_csr_result(ex2_none1_csr_result),
    .ex2_none1_csr_addr (ex2_none1_csr_addr ),
    .ex1_none1_op       (ex1_none1_op       ), 
    .ex2_none1_op       (ex2_none1_op       ),
    .ex1_none1_info     (ex1_none1_info     ),
    .ex2_none1_info     (ex2_none1_info     ),
    //memory interface
    .data_req           (data_req           ),
    .data_pc            (data_pc            ),
    .data_addr          (data_addr          ),
    .data_wr            (data_wr            ),
    .data_wstrb         (data_wstrb         ),
    .data_wdata         (data_wdata         ),
    .data_cancel        (data_cancel        ),
    .data_prefetch      (data_prefetch      ),
    .data_ll            (data_ll            ),
    .data_sc            (data_sc            ),
    .data_addr_ok       (data_addr_ok       ),
    //tlb interface
    .tlb_req            (tlb_req            ),
    .tlb_recv           (tlb_recv || cache_op_recv),
    .tlb_op             (tlb_op             ),
    .tlb_finish         (tlb_finish || cache_op_finish),
    .tlb_index          (tlb2cp0_index      ),

    .data_exception     (data_exception     ),
    .data_excode        (data_exccode       ),
    .data_badvaddr      (data_badvaddr      ),

    .cache_req          (cache_req          ),
    .cache_op           (cache_op           ),
    //forward
    .ex1_raddr0_0       (ex1_raddr0_0       ),
    .ex1_raddr0_1       (ex1_raddr0_1       ),
    .ex1_raddr1_0       (ex1_raddr1_0       ),
    .ex1_raddr1_1       (ex1_raddr1_1       ),
    .ex1_raddr2_0       (ex1_raddr2_0       ),
    .ex1_raddr2_1       (ex1_raddr2_1       ),
    
    .ex2_alu0_res       (ex2_alu0_res       ),
    .ex2_alu1_res       (ex2_alu1_res       ),
    .ex2_lsu_res        (ex2_lsu_res        ),
    .ex2_none0_res      (ex2_none0_result   ),
    .ex2_none1_res      (ex2_none1_result   )
);

ex2_stage ex2_stage(
    .clk                (clk                ),
    .resetn             (resetn             ),
    //exception
    .exception          (wb_exception       ),
    .eret               (wb_eret            ),
    .wb_cancel          (wb_cancel          ),
    // pipe in
    .ex2_allow_in       (ex2_allow_in       ),
    //port
    .ex2_port0_src      (ex2_port0_src      ),
    .ex2_port0_pc       (ex2_port0_pc       ),
    .ex2_port0_inst     (ex2_port0_inst     ),
    .ex2_port0_valid    (ex2_port0_valid    ),
    .ex2_port0_rf_target(ex2_port0_rf_target),
    .ex2_port0_rf_wen   (ex2_port0_rf_wen   ),
    .ex2_port0_exception(ex2_port0_exception),
    .ex2_port0_exccode  (ex2_port0_exccode  ),
    .ex2_port0_ll       (ex2_port0_ll       ),
    .ex2_port0_sc       (ex2_port0_sc       ),
    .ex2_port0_type     (ex2_port0_type     ),

    .ex2_port1_src      (ex2_port1_src      ),
    .ex2_port1_pc       (ex2_port1_pc       ),
    .ex2_port1_inst     (ex2_port1_inst     ),
    .ex2_port1_valid    (ex2_port1_valid    ),
    .ex2_port1_rf_target(ex2_port1_rf_target),
    .ex2_port1_rf_wen   (ex2_port1_rf_wen   ),
    .ex2_port1_exception(ex2_port1_exception),
    .ex2_port1_exccode  (ex2_port1_exccode  ),
    .ex2_port1_ll       (ex2_port1_ll       ),
    .ex2_port1_sc       (ex2_port1_sc       ),
    .ex2_port1_type     (ex2_port1_type     ),

    .ex2_port2_type     (ex2_port2_type     ),
    // pipe out
    .wb_allow_in        (wb_allow_in        ),
    // port 1
    .wb_port0_valid      (wb_port0_valid     ),
    .wb_port0_src        (wb_port0_src       ),
    .wb_port0_inst       (wb_port0_inst      ),
    .wb_port0_pc         (wb_port0_pc        ),
    .wb_port0_rf_target  (wb_port0_rf_target ),
    .wb_port0_rf_wen     (wb_port0_rf_wen    ),
    .wb_port0_rf_result  (wb_port0_rf_result ),
    .wb_port0_exception  (wb_port0_exception ),
    .wb_port0_exccode    (wb_port0_exccode   ),
    .wb_port0_eret       (wb_port0_eret      ),
    .wb_port0_csr_addr   (wb_port0_csr_addr  ),
    .wb_port0_ll         (wb_port0_ll        ),
    .wb_port0_sc         (wb_port0_sc        ),
    .wb_port0_csr_result (wb_port0_csr_result),
    .wb_port0_esubcode   (wb_port0_esubcode ),
    .wb_port0_rf_res_lsu (wb_port0_rf_res_lsu),
    // port 2
    .wb_port1_valid      (wb_port1_valid     ),
    .wb_port1_src        (wb_port1_src       ),
    .wb_port1_inst       (wb_port1_inst      ),
    .wb_port1_pc         (wb_port1_pc        ),
    .wb_port1_rf_target  (wb_port1_rf_target ),
    .wb_port1_rf_wen     (wb_port1_rf_wen    ),
    .wb_port1_rf_result  (wb_port1_rf_result ),
    .wb_port1_exception  (wb_port1_exception ),
    .wb_port1_exccode    (wb_port1_exccode   ),
    .wb_port1_eret       (wb_port1_eret      ),
    .wb_port1_csr_addr   (wb_port1_csr_addr  ),
    .wb_port1_ll         (wb_port1_ll        ),
    .wb_port1_sc         (wb_port1_sc        ),
    .wb_port1_csr_result (wb_port1_csr_result),
    .wb_port1_esubcode   (wb_port1_esubcode ),
    .wb_port1_rf_res_lsu (wb_port1_rf_res_lsu),
    .wb_port2_valid      (wb_port2_valid    ),
    //REG
    .ex2_lsu_fw_data    (ex2_lsu_fw_data    ),
    .ex2_rdata0_0_lsu_fw(ex2_rdata0_0_lsu_fw),
    .ex2_rdata0_1_lsu_fw(ex2_rdata0_1_lsu_fw),
    .ex2_rdata1_0_lsu_fw(ex2_rdata1_0_lsu_fw),
    .ex2_rdata1_1_lsu_fw(ex2_rdata1_1_lsu_fw),
    .ex2_bru_a_lsu_fw   (ex2_bru_a_lsu_fw   ),
    .ex2_bru_b_lsu_fw   (ex2_bru_b_lsu_fw   ),
    //ALU1
    .ex2_port0_a        (ex2_port0_a        ),
    .ex2_port0_b        (ex2_port0_b        ),   
    .ex2_port0_op       (ex2_port0_op       ),
    .ex2_port0_c        (ex2_port0_c        ),
    .ex2_port0_double   (ex2_port0_double   ),
    .ex2_alu0_res       (ex2_alu0_res       ),
    //ALU2
    .ex2_port1_a        (ex2_port1_a        ),
    .ex2_port1_b        (ex2_port1_b        ),   
    .ex2_port1_op       (ex2_port1_op       ),
    .ex2_port1_c        (ex2_port1_c        ),
    .ex2_port1_double   (ex2_port1_double   ),
    .ex2_alu1_res       (ex2_alu1_res       ),
    //BRANCH
    .ex2_bru_delay      (ex2_bru_delay      ),
    .ex2_bru_op         (ex2_bru_op         ),
    .ex2_bru_a          (ex2_bru_a          ),
    .ex2_bru_b          (ex2_bru_b          ),
    .ex2_bru_br_taken   (ex2_bru_br_taken   ),
    .ex2_bru_br_target  (ex2_bru_br_target  ),
    .ex2_bru_offset     (ex2_bru_offset     ),
    .ex2_bru_link_pc    (ex2_bru_link_pc    ),
    .ex2_bru_link       (ex2_bru_link       ),
    .ex2_bru_jrra       (ex2_bru_jrra       ),
    .ex2_bru_jrop       (ex2_bru_jrop       ),
    .ex2_bru_brop       (ex2_bru_brop       ),
    .ex2_bru_port       (ex2_bru_port       ),
    .ex2_bru_valid      (ex2_bru_valid      ),
    .ex2_bru_hint       (ex2_bru_hint       ),
    .ex2_bru_pc         (ex2_bru_pc         ),


    .wb_bru_link        (wb_branch_link     ),
    .wb_bru_jrra        (wb_branch_jrra     ),
    .wb_bru_jrop        (wb_branch_jrop     ),
    .wb_bru_brop        (wb_branch_brop     ),
    .wb_bru_port        (wb_bru_port        ),
    .wb_bru_valid       (wb_branch_valid    ),
    .wb_bru_hint        (wb_bru_hint        ),
    .wb_bru_br_taken    (wb_bru_br_taken    ),
    .wb_bru_pc          (wb_bru_pc          ),
    .wb_bru_link_pc     (wb_bru_link_pc     ),

    .bru_target_ex2     (bru_target_ex2     ),
    .bru_pc_ex2         (bru_pc_ex2         ),
    .bru_cancel_ex2     (bru_cancel_ex2     ),
    .bru_ignore_ex2     (bru_ignore_ex2     ),
    .bru_cancel_all_ex2 (bru_cancel_all_ex2 ),
    .bru_port_ex2       (bru_port_ex2       ),
    .bru_valid_ex2      (bru_valid_ex2      ),
    .bru_hint_ex2       (bru_hint_ex2       ),
    .bru_sign_ex2       (bru_sign_ex2       ),
    .bru_taken_ex2      (bru_taken_ex2      ),
    .bru_brop_ex2       (bru_brop_ex2       ),
    .bru_jrop_ex2       (bru_jrop_ex2       ),
    .bru_jrra_ex2       (bru_jrra_ex2       ),
    .bru_link_ex2       (bru_link_ex2       ),
    .bru_link_pc_ex2    (bru_link_pc_ex2    ),
    //LSU
    .ex2_lsu_res        (ex2_lsu_res        ),
    .wb_lsu_res         (wb_lsu_res         ),
    .ex2_lsu_ale        (ex2_lsu_ale        ),
    .ex2_lsu_adem       (ex2_lsu_adem       ),
    .ex2_lsu_shift      (ex2_lsu_shift      ),
    .ex2_lsu_op         (ex2_lsu_op         ), 
    .ex2_lsu_recv       (ex2_lsu_recv       ),
    //MDU
    .ex2_mdu_op         (ex2_mdu_op         ),
    .ex2_mdu_a          (ex2_mdu_a          ),
    .ex2_mdu_b          (ex2_mdu_b          ),
    .ex2_mul_ready      (ex2_mul_ready      ),
    .ex2_mul_res        (ex2_mul_res        ),
    .ex2_div_res        (ex2_div_res        ),
    //NONE1
    .ex2_none0_result   (ex2_none0_result   ),
    .ex2_none0_csr_addr (ex2_none0_csr_addr ),
    .ex2_none0_csr_result(ex2_none0_csr_result),
    .ex2_none0_op       (ex2_none0_op       ),
    .ex2_none0_info     (ex2_none0_info     ),
    .wb_none0_op        (wb_none0_op        ),
    .wb_none0_info      (wb_none0_info      ),
    //NONE2
    .ex2_none1_result   (ex2_none1_result   ),
    .ex2_none1_csr_addr (ex2_none1_csr_addr ),
    .ex2_none1_csr_result(ex2_none1_csr_result),
    .ex2_none1_op       (ex2_none1_op       ),
    .ex2_none1_info     (ex2_none1_info     ),
    .wb_none1_op        (wb_none1_op        ),
    .wb_none1_info      (wb_none1_info      ),
    //memory interface
    .data_recv          (data_recv          ),
    .data_scsucceed     (data_scsucceed     ),
    .data_rdata         (data_rdata         ),
    .data_data_ok       (data_data_ok       ),
    .data_exception     (data_exception     ),
    .data_excode        (data_exccode       ),
    .data_badvaddr      (data_badvaddr      ),
    .data_cancel_ex2    (data_cancel_ex2    ),
    .badvaddr_ex2       (badvaddr_ex2       ),
    .badvaddr_ex2_valid (badvaddr_ex2_valid )
);

wire [31:0] badinstr_temp;
wire [`GRLEN-1:0] wb_tlbr_entrance;

wb_stage wb_stage(
    .clk                 (clk               ),
    .resetn              (resetn            ),
    // pipe in
    .wb_allow_in         (wb_allow_in       ),
    // port 0
    .wb_port0_inst       (wb_port0_inst     ),
    .wb_port0_pc         (wb_port0_pc       ),
    .wb_port0_src        (wb_port0_src      ),
    .wb_port0_valid      (wb_port0_valid    ),
    .wb_port0_rf_target  (wb_port0_rf_target),
    .wb_port0_rf_wen     (wb_port0_rf_wen   ),
    .wb_port0_rf_result  (wb_port0_rf_result),
    .wb_port0_exception  (wb_port0_exception),
    .wb_port0_exccode    (wb_port0_exccode  ),
    .wb_port0_eret       (wb_port0_eret     ),
    .wb_port0_csr_addr   (wb_port0_csr_addr ),
    .wb_none0_op         (wb_none0_op       ),
    .wb_port0_ll         (wb_port0_ll       ),
    .wb_port0_sc         (wb_port0_sc       ),
    .wb_port0_csr_result (wb_port0_csr_result),
    .wb_port0_esubcode   (wb_port0_esubcode ),
    .wb_none0_info       (wb_none0_info     ),
    .wb_port0_rf_res_lsu (wb_port0_rf_res_lsu),
    // port 1
    .wb_port1_inst       (wb_port1_inst     ),
    .wb_port1_pc         (wb_port1_pc       ),
    .wb_port1_src        (wb_port1_src      ),
    .wb_port1_valid      (wb_port1_valid    ),
    .wb_port1_rf_target  (wb_port1_rf_target),
    .wb_port1_rf_wen     (wb_port1_rf_wen   ),
    .wb_port1_rf_result  (wb_port1_rf_result),
    .wb_port1_exception  (wb_port1_exception),
    .wb_port1_exccode    (wb_port1_exccode  ),
    .wb_port1_eret       (wb_port1_eret     ),
    .wb_port1_csr_addr   (wb_port1_csr_addr ),
    .wb_none1_op         (wb_none1_op       ),
    .wb_port1_ll         (wb_port1_ll       ),
    .wb_port1_sc         (wb_port1_sc       ),
    .wb_port1_csr_result (wb_port1_csr_result),
    .wb_port1_esubcode   (wb_port1_esubcode ),
    .wb_none1_info       (wb_none1_info     ),
    .wb_port1_rf_res_lsu (wb_port1_rf_res_lsu),
    // port 2
    .wb_port2_valid      (wb_port2_valid    ),
		// temp fake
	.wb_badinstr		 (badinstr_temp		  ),
    // lsu
    .wb_lsu_res          (wb_lsu_res        ),
    // branch 
    .wb_branch_link      (wb_branch_link    ),
    .wb_branch_jrra      (wb_branch_jrra    ),
    .wb_branch_jrop      (wb_branch_jrop    ),
    .wb_branch_brop      (wb_branch_brop    ),
    .wb_bru_port         (wb_bru_port       ),
    .wb_branch_valid     (wb_branch_valid   ),
    .wb_bru_hint         (wb_bru_hint       ),
    .wb_bru_br_taken     (wb_bru_br_taken   ),
    .wb_bru_pc           (wb_bru_pc         ),
    .wb_bru_link_pc      (wb_bru_link_pc    ),
    //tlb related
    .tlb_index_i         (`GRLEN'b0         ), // TODO
    //cache related
    .cache_taglo_i       (`GRLEN'b0         ), // TODO
    .cache_taghi_i       (`GRLEN'b0         ), // TODO
    .cache_datalo_i      (`GRLEN'b0         ), // TODO
    .cache_datahi_i      (`GRLEN'b0         ), // TODO

    .cache_op_1         (cp0_cache_op_1     ),
    .cache_op_2         (cp0_cache_op_2     ),
    .cache_taglo_o      (cp0_cache_taglo    ),
    .cache_taghi_o      (cp0_cache_taghi    ),
    .cache_datalo_o     (cp0_cache_datalo   ),
    .cache_datahi_o     (cp0_cache_datahi   ),
    //debug
    .debug0_wb_pc      (debug0_wb_pc      ),// O, 64 
    .debug0_wb_rf_wen  (debug0_wb_rf_wen  ),// O, 1  
    .debug0_wb_rf_wnum (debug0_wb_rf_wnum ),// O, 5  
    .debug0_wb_rf_wdata(debug0_wb_rf_wdata),// O, 64 
    .debug1_wb_pc      (debug1_wb_pc      ),// O, 64 
    .debug1_wb_rf_wen  (debug1_wb_rf_wen  ),// O, 1  
    .debug1_wb_rf_wnum (debug1_wb_rf_wnum ),// O, 5  
    .debug1_wb_rf_wdata(debug1_wb_rf_wdata),// O, 64
    //reg file interface
    .waddr1             (waddr1         ),
    .waddr2             (waddr2         ),  
    .wdata1             (wdata1         ),
    .wdata2             (wdata2         ),
    .wen1               (wen1           ),
    .wen2               (wen2           ),
    // cp0 registers interface
    .csr_waddr          (csr_waddr      ),
    .csr_wdata          (csr_wdata      ),
    .csr_wen            (csr_wen        ),

    .csr_tlbp           (csr_tlbp       ),
    .csr_tlbop_index    (csr_tlbop_index),
    .csr_tlbr           (csr_tlbr       ),
    
    // exception entrance calculation
    .cp0_status_exl         (cp0_status_exl         ),// I, 1
    .cp0_status_bev         (cp0_status_bev         ),// I, 1
    .cp0_cause_iv           (cp0_cause_iv           ),// I, 1
    .cp0_ebase_exceptionbase(cp0_ebase_exceptionbase),// I, 18
    .eret_epc               (eret_epc               ),// I, 32
    .wb_tlbr_entrance       (wb_tlbr_entrance       ),
    .csr_ebase              (csr_ebase              ),
    // branch update
    .wb_valid           (wb_valid       ),
    .wb_brop            (wb_brop        ),
    .wb_link            (wb_link        ),
    .wb_link_pc         (wb_link_pc     ),
    .wb_jrop            (wb_jrop        ),
    .wb_jrra            (wb_jrra        ),
    .wb_pc              (wb_pc          ),
    .wb_hint            (wb_hint        ),
    .wb_taken           (wb_taken       ),
    //exception
    .wb_cancel          (wb_cancel      ),
    .wb_target          (wb_target      ),
    .wb_exception       (wb_exception   ),
    .wb_exccode         (wb_exccode     ),
    .wb_esubcode        (wb_esubcode    ),
    .wb_eret            (wb_eret        ),
    .wb_epc             (wb_epc         ),
    .badvaddr_ex2       (badvaddr_ex2   ),
    .badvaddr_ex2_valid (badvaddr_ex2_valid),
    .lsu_badvaddr       (lsu_badvaddr   ),
    .wb_badvaddr        (wb_badvaddr    ),
    .except_shield      (except_shield  )
);

wire [`GRLEN-1:0] csr_dir_map_win0;
wire [`GRLEN-1:0] csr_dir_map_win1;
wire [`GRLEN-1:0] csr_crmd;
`ifdef LA64
  wire [       5:0] csr_pgsize_ftps;
`endif

tlb_wrapper u_tlb_wrapper(
    .clk               (clk              ),
    .reset             (~resetn          ),  

    .test_pc           (ex2_port0_pc     ),

    .tlb_req           (tlb_req          ),
    .tlb_recv          (tlb_recv         ),
    .tlb_op            (tlb_op           ),
    .invtlb_vaddr      (data_wdata       ),
    .tlb_finish        (tlb_finish       ),

    .csr_index_out     (tlb2cp0_index    ),
    .csr_entryhi_out   (tlb2cp0_entryhi  ),
    .csr_entrylo0_out  (tlb2cp0_entrylo0 ),
    .csr_entrylo1_out  (tlb2cp0_entrylo1 ),
    .csr_asid_out      (tlb2cp0_asid     ),

    .csr_index_in      (cp02tlb_index    ),
    .csr_entryhi_in    (cp02tlb_entryhi  ),
    .csr_entrylo0_in   (cp02tlb_entrylo0 ),
    .csr_entrylo1_in   (cp02tlb_entrylo1 ),
    .csr_asid_in       (cp02tlb_asid     ),
    .csr_ecode_in      (cp02tlb_ecode    ),

    .csr_CRMD_PLV      (csr_crmd[`CRMD_PLV ]),
    .csr_CRMD_DA       (csr_crmd[`CRMD_DA  ]),
    .csr_CRMD_PG       (csr_crmd[`CRMD_PG  ]),
    .csr_CRMD_DATF     (csr_crmd[`CRMD_DATF]),
    .csr_CRMD_DATM     (csr_crmd[`CRMD_DATM]),
   `ifdef LA64
    .csr_FTLBPS_FTPS   (csr_pgsize_ftps     ),
   `endif
    .csr_dir_map_win0  (csr_dir_map_win0    ),
    .csr_dir_map_win1  (csr_dir_map_win1    ),

    .c_op              (cache_op         ),

    .i_req             (inst_tlb_req     ),
    .i_vaddr           (inst_tlb_vaddr   ),
    .i_cacop_req       (inst_tlb_cacop   ),
    .i_cache_rcv       (itlb_cache_recv  ),
    .i_finish          (itlb_finish      ),
    .i_hit             (itlb_hit         ),
    .i_paddr           (itlb_paddr       ),
    .i_uncached        (itlb_uncache     ),
    .i_exccode         (itlb_exccode     ),
    
    .d_req             (data_tlb_req     ),
    .d_wr              (data_tlb_wr      ),
    .d_vaddr           (data_tlb_vaddr   ),
    .d_cache_rcv       (dtlb_cache_recv  ),
    .d_no_trans        (dtlb_no_trans    ),
    .b_p_pgcl          (dtlb_p_pgcl      ),
    .d_finish          (dtlb_finish      ),
    .d_hit             (dtlb_hit         ),
    .d_paddr           (dtlb_paddr       ),
    .d_uncached        (dtlb_uncache     ),
    .d_exccode         (dtlb_exccode     )
);

csr csr(
    .clk                (clk             ),
    .resetn             (resetn          ),
    .intrpt             (8'd0/*intrpt    */      ), // TODO
    // tlb inst
    .tlbp               (csr_tlbp        ),
    .tlbr               (csr_tlbr        ),
    .ldpte              (1'b0            ), // TODO
    .tlbrp_index        (csr_tlbop_index ),
    .tlbr_entryhi       (tlb2cp0_entryhi ),
    .tlbr_entrylo0      (tlb2cp0_entrylo0),                
    .tlbr_entrylo1      (tlb2cp0_entrylo1),
    .tlbr_asid          (tlb2cp0_asid    ),
    //cache inst
    .cache_op_1         (cp0_cache_op_1  ),
    .cache_op_2         (cp0_cache_op_2  ),
    .cache_taglo_i      (cp0_cache_taglo ),
    .cache_taghi_i      (cp0_cache_taghi ),
    .cache_datalo_i     (cp0_cache_datalo),
    .cache_datahi_i     (cp0_cache_datahi),
    // csr inst
    .rdata              (csr_rdata       ),
    .raddr              (csr_raddr       ),
    .wdata              (csr_wdata       ),
    .waddr              (csr_waddr       ),
    .wen                (csr_wen         ),
    
    .llbctl             (llbctl          ),
    // exception
    .wb_exception       (wb_exception    ),
    .wb_exccode         (wb_exccode      ),
    .wb_esubcode        (wb_esubcode     ),
    .wb_epc             (wb_epc          ),
    .wb_badvaddr        (wb_badvaddr     ),
    .wb_badinstr        (wb_badinstr     ),
    .wb_eret            (wb_eret         ),

    .csr_output         (csr_output      ),
    
    .dmw0               (csr_dir_map_win0),
    .dmw1               (csr_dir_map_win1),
    .crmd               (csr_crmd        ),
   `ifdef LA64
    .ftpgsize           (csr_pgsize_ftps ),
   `endif

    .index_out          (cp02tlb_index   ),
    .entryhi_out        (cp02tlb_entryhi ),
    .entrylo0_out       (cp02tlb_entrylo0),
    .entrylo1_out       (cp02tlb_entrylo1),
    .asid_out           (cp02tlb_asid    ),
    .ecode_out          (cp02tlb_ecode   ),

    .epc_addr_out       (cp0_epc         ),
    .eret_epc_out       (eret_epc        ),// O,32
    .shield             (except_shield   ),
    .int_except         (int_except      ),

    .status_erl         (cp0_status_erl         ),
    .status_exl         (cp0_status_exl         ),// O, 1
    .status_bev         (cp0_status_bev         ),// O, 1
    .cause_iv           (cp0_cause_iv           ),// O, 1
    .config_k0          (cp0_config_k0          ),
    .ebase_exceptionbase(cp0_ebase_exceptionbase),
    .taglo0_out         (cp0_taglo0             ),
    .taghi0_out         (cp0_taghi0             ),
    .tlbrebase          (wb_tlbr_entrance       ),
    .ebase              (csr_ebase              )
);

endmodule
