`include "common.vh"
`include "decoded.vh"

module lsoc1000_stage_issue(
    input                       clk,
    input                       resetn,
    //exception
    input                       exception,
    input                       eret,
    input                       bru_cancel,
    input                       bru_cancel_all,
    input                       bru_ignore,
    input                       bru_port,
    input                       wb_cancel,
    //register interface
    output [ 4:0]               raddr0_0,
    output [ 4:0]               raddr0_1,
    output [ 4:0]               raddr1_0,
    output [ 4:0]               raddr1_1,
    output [ 4:0]               raddr2_0,
    output [ 4:0]               raddr2_1,            
    input  [`GRLEN-1:0]         rdata0_0,
    input  [`GRLEN-1:0]         rdata0_1,
    input  [`GRLEN-1:0]         rdata1_0,
    input  [`GRLEN-1:0]         rdata1_1,
    input  [`GRLEN-1:0]         rdata2_0,
    input  [`GRLEN-1:0]         rdata2_1,
    //cp0 register interface
    output [`LSOC1K_CSR_BIT-1:0] csr_raddr,
    input  [`GRLEN-1:0]          csr_rdata,
    // pipe in
    output                             is_allow_in,
    // port0
    input                              is_port0_valid,
    input [`GRLEN-1:0]                 is_port0_pc,
    input [31:0]                       is_port0_inst,
    input [`LSOC1K_DECODE_RES_BIT-1:0] is_port0_op,
    input [`GRLEN-3:0]                 is_port0_br_target,
    input                              is_port0_br_taken,
    input                              is_port0_exception,
    input [5 :0]                       is_port0_exccode,
    input                              is_port0_rf_wen,
    input [4:0]                        is_port0_rf_target,
    input [`LSOC1K_PRU_HINT:0]         is_port0_hint,
    // input                              is_port0_has_microop,
    // port1
    input                              is_port1_valid,
    input [`GRLEN-1:0]                 is_port1_pc,
    input [31:0]                       is_port1_inst,
    input [`LSOC1K_DECODE_RES_BIT-1:0] is_port1_op,
    input [`GRLEN-3:0]                 is_port1_br_target,
    input                              is_port1_br_taken,
    input                              is_port1_exception,
    input [5 :0]                       is_port1_exccode,
    input                              is_port1_rf_wen,
    input [4:0]                        is_port1_rf_target,
    input [`LSOC1K_PRU_HINT:0]         is_port1_hint,
    // input                              is_port1_is_microop,
    // port2
    input                              is_port2_valid,
    input                              is_port2_app,
    input                              is_port2_id,
    input [`GRLEN-1:0]                 is_port2_pc,
    input [31:0]                       is_port2_inst,
    input [`LSOC1K_DECODE_RES_BIT-1:0] is_port2_op,
    input [`GRLEN-3:0]                 is_port2_br_target,
    input                              is_port2_br_taken,
    input                              is_port2_exception,
    input [5 :0]                       is_port2_exccode,
    input [`LSOC1K_PRU_HINT:0]         is_port2_hint,
    // pipe out
    input                               ex1_allow_in,
    input                               ex2_allow_in,
    // port0
    output reg [31:0]                   ex1_port0_inst,
    output reg [`GRLEN-1:0]             ex1_port0_pc,
    output reg [`EX_SR-1 : 0]           ex1_port0_src,
    output                              ex1_port0_valid,
    output reg [4:0]                    ex1_port0_rf_target,
    output reg                          ex1_port0_rf_wen,
    output reg                          ex1_port0_ll,
    output reg                          ex1_port0_sc,
    output reg                          ex1_port0_type,
    // output reg                          ex1_port0_has_microop,
    // port1
    output reg [31:0]                   ex1_port1_inst,
    output reg [`GRLEN-1:0]             ex1_port1_pc,
    output reg [`EX_SR-1 : 0]           ex1_port1_src,
    output                              ex1_port1_valid,
    output reg [4:0]                    ex1_port1_rf_target,
    output reg                          ex1_port1_rf_wen, 
    output reg                          ex1_port1_ll,
    output reg                          ex1_port1_sc,
    output reg                          ex1_port1_type,
    // output reg                          ex1_port1_is_microop,
    // port2
    output reg                          ex1_port2_type,
    //REG
    output reg [`GRLEN-1:0]             ex1_lsu_fw_data,
    output reg                          ex1_rdata0_0_lsu_fw,
    output reg                          ex1_rdata0_1_lsu_fw,
    output reg                          ex1_rdata1_0_lsu_fw,
    output reg                          ex1_rdata1_1_lsu_fw,
//    output reg                          ex1_port0_a_lsu_fw,
    output                              ex1_port0_a_lsu_fw,
    output reg                          ex1_port0_b_lsu_fw,
    output reg                          ex1_port1_a_lsu_fw,
    output reg                          ex1_port1_b_lsu_fw,
    output reg                          ex1_mdu_a_lsu_fw,
    output reg                          ex1_mdu_b_lsu_fw,
    output reg                          ex1_bru_a_lsu_fw,
    output reg                          ex1_bru_b_lsu_fw,
    output reg                          ex1_lsu_base_lsu_fw,
    output reg                          ex1_lsu_offset_lsu_fw,
    output reg                          ex1_lsu_wdata_lsu_fw,


   
    //ALU1
//    output reg [`GRLEN-1:0]               ex1_port0_a,
//    output reg [`GRLEN-1:0]               ex1_port0_b,   
//    output reg [`LSOC1K_ALU_CODE_BIT-1:0] ex1_port0_op,
//    output reg [`LSOC1K_ALU_C_BIT-1:0]    ex1_port0_c,
//    output reg                            ex1_port0_a_ignore,
//    output reg                            ex1_port0_b_ignore,
//    output reg                            ex1_port0_b_get_a,
//    output reg                            ex1_port0_double,
//    //ALU2
//    output reg [`GRLEN-1:0]               ex1_port1_a,
//    output reg [`GRLEN-1:0]               ex1_port1_b,
//    output reg [`LSOC1K_ALU_CODE_BIT-1:0] ex1_port1_op,
//    output reg [`LSOC1K_ALU_C_BIT-1:0]    ex1_port1_c,
//    output reg                            ex1_port1_a_ignore,
//    output reg                            ex1_port1_b_ignore,
//    output reg                            ex1_port1_b_get_a,
//    output reg                            ex1_port1_double,

    output [`GRLEN-1:0]               ex1_port0_a,
    output [`GRLEN-1:0]               ex1_port0_b,   
    output [`LSOC1K_ALU_CODE_BIT-1:0] ex1_port0_op,
    output [`LSOC1K_ALU_C_BIT-1:0]    ex1_port0_c,
    output                            ex1_port0_a_ignore,
    output                            ex1_port0_b_ignore,
    output                            ex1_port0_b_get_a,
    output                            ex1_port0_double,
    //ALU2
    output [`GRLEN-1:0]               ex1_port1_a,
    output [`GRLEN-1:0]               ex1_port1_b,
    output [`LSOC1K_ALU_CODE_BIT-1:0] ex1_port1_op,
    output [`LSOC1K_ALU_C_BIT-1:0]    ex1_port1_c,
    output                            ex1_port1_a_ignore,
    output                            ex1_port1_b_ignore,
    output                            ex1_port1_b_get_a,
    output                            ex1_port1_double,
   
    //BRU
    input                                 bru_delay,
    output reg                            ex1_bru_delay,
    output reg [`LSOC1K_BRU_CODE_BIT-1:0] ex1_bru_op,
    output reg [`GRLEN-1:0]               ex1_bru_a,
    output reg [`GRLEN-1:0]               ex1_bru_b,
    output reg                            ex1_bru_br_taken,
    output reg [`GRLEN-1:0]               ex1_bru_br_target,
    output reg [`LSOC1K_PRU_HINT:0]       ex1_bru_hint,
    output reg                            ex1_bru_link,
    output reg                            ex1_bru_jrra,
    output reg                            ex1_bru_brop,
    output reg                            ex1_bru_jrop,
    output reg [`GRLEN-1:0]               ex1_bru_offset,
    output reg [`GRLEN-1:0]               ex1_bru_pc,
    output reg [ 2:0]                     ex1_bru_port,
    output reg                            ex1_branch_valid,
    //MDU
    output reg [`LSOC1K_MDU_CODE_BIT-1:0] ex1_mdu_op,
    output reg [`GRLEN-1:0]               ex1_mdu_a,
    output reg [`GRLEN-1:0]               ex1_mdu_b,
    //LSU
    output reg [`LSOC1K_LSU_CODE_BIT-1:0] ex1_lsu_op, 
    output reg [`GRLEN-1:0]               ex1_lsu_base,
    output reg [`GRLEN-1:0]               ex1_lsu_offset,
    output reg [`GRLEN-1:0]               ex1_lsu_wdata,
    //NONE0
    output reg [`GRLEN-1:0]                ex1_none0_result,
    output reg                             ex1_none0_exception,
    output reg [`LSOC1K_CSR_BIT-1:0]       ex1_none0_csr_addr,
    output reg [`LSOC1K_CSR_CODE_BIT-1:0]  ex1_none0_op,
    output reg [5 :0]                      ex1_none0_exccode,
    output reg [`GRLEN-1:0]                ex1_none0_csr_a,
    output reg [`GRLEN-1:0]                ex1_none0_csr_result,
    output reg [`LSOC1K_NONE_INFO_BIT-1:0] ex1_none0_info,
    //NONE1
    output reg [`GRLEN-1:0]                ex1_none1_result,
    output reg                             ex1_none1_exception,
    output reg [`LSOC1K_CSR_BIT-1:0]       ex1_none1_csr_addr,
    output reg [`LSOC1K_CSR_CODE_BIT-1:0]  ex1_none1_op,
    output reg [5 :0]                      ex1_none1_exccode,
    output reg [`GRLEN-1:0]                ex1_none1_csr_a,
    output reg [`GRLEN-1:0]                ex1_none1_csr_result,
    output reg [`LSOC1K_NONE_INFO_BIT-1:0] ex1_none1_info,
    //forwarding related
    output reg [4:0]            ex1_raddr0_0,
    output reg [4:0]            ex1_raddr0_1,
    output reg [4:0]            ex1_raddr1_0,
    output reg [4:0]            ex1_raddr1_1,
    output reg [4:0]            ex1_raddr2_0,
    output reg [4:0]            ex1_raddr2_1,

    input   [`GRLEN-1:0]        ex1_alu0_res,
    input   [`GRLEN-1:0]        ex1_alu1_res,
    input   [`GRLEN-1:0]        ex1_bru_res,
    input   [`GRLEN-1:0]        ex1_none0_res,
    input   [`GRLEN-1:0]        ex1_none1_res,

    input [`EX_SR-1 : 0]        ex2_port0_src,
    input                       ex2_port0_valid,
    input [4:0]                 ex2_port0_rf_target,
    input [`EX_SR-1 : 0]        ex2_port1_src,
    input                       ex2_port1_valid,
    input [4:0]                 ex2_port1_rf_target,

    input   [`GRLEN-1:0]        ex2_alu0_res,
    input   [`GRLEN-1:0]        ex2_alu1_res,
    input   [`GRLEN-1:0]        ex2_lsu_res,
    input   [`GRLEN-1:0]        ex2_bru_res,
    input   [`GRLEN-1:0]        ex2_none0_res,
    input   [`GRLEN-1:0]        ex2_none1_res,
    input   [`GRLEN-1:0]        ex2_mul_res,
    input   [`GRLEN-1:0]        ex2_div_res
);

wire rst = !resetn;

////// define
wire allow_in;
wire port0_triple_read;
wire port1_triple_read;

wire port0_dispatch; //whether inst ready to dispatch
wire port1_dispatch; 

wire port0_alu_dispatch, port0_bru_dispatch, port0_lsu_dispatch, port0_mul_dispatch, port0_div_dispatch, port0_none_dispatch;
wire port1_alu_dispatch, port1_bru_dispatch, port1_lsu_dispatch, port1_mul_dispatch, port1_div_dispatch, port1_none_dispatch;

reg  port0_valid;
reg  port1_valid;

wire [`GRLEN-1:0] rdata0_0_input, rdata0_1_input;
wire [`GRLEN-1:0] rdata1_0_input, rdata1_1_input;
wire [`GRLEN-1:0] rdata2_0_input, rdata2_1_input;

wire [`EX_SR-1 : 0] port0_sr_ur;
wire [`EX_SR-1 : 0] port1_sr_ur;

//forwarding related
wire r1_1_w1_fw_ex1, r1_2_w1_fw_ex1, r1_1_w2_fw_ex1, r1_2_w2_fw_ex1;
wire r2_1_w1_fw_ex1, r2_2_w1_fw_ex1, r2_1_w2_fw_ex1, r2_2_w2_fw_ex1;
wire r3_1_w1_fw_ex1, r3_2_w1_fw_ex1, r3_1_w2_fw_ex1, r3_2_w2_fw_ex1;
wire r1_1_w1_fw_ex2, r1_2_w1_fw_ex2, r1_1_w2_fw_ex2, r1_2_w2_fw_ex2;
wire r2_1_w1_fw_ex2, r2_2_w1_fw_ex2, r2_1_w2_fw_ex2, r2_2_w2_fw_ex2;
wire r3_1_w1_fw_ex2, r3_2_w1_fw_ex2, r3_1_w2_fw_ex2, r3_2_w2_fw_ex2;

wire r1_1_fw_ex1, r1_2_fw_ex1;
wire r2_1_fw_ex1, r2_2_fw_ex1;
wire r3_1_fw_ex1, r3_2_fw_ex1;
wire r1_1_fw_ex2, r1_2_fw_ex2;
wire r2_1_fw_ex2, r2_2_fw_ex2;
wire r3_1_fw_ex2, r3_2_fw_ex2;

wire [`GRLEN-1:0] wdata1_ex1, wdata1_ex2;
wire [`GRLEN-1:0] wdata2_ex1, wdata2_ex2;
wire [`GRLEN-1:0] r1_1_fw_data_ex1, r1_2_fw_data_ex1;
wire [`GRLEN-1:0] r2_1_fw_data_ex1, r2_2_fw_data_ex1;
wire [`GRLEN-1:0] r3_1_fw_data_ex1, r3_2_fw_data_ex1;
wire [`GRLEN-1:0] r1_1_fw_data_ex2, r1_2_fw_data_ex2;
wire [`GRLEN-1:0] r2_1_fw_data_ex2, r2_2_fw_data_ex2;
wire [`GRLEN-1:0] r3_1_fw_data_ex2, r3_2_fw_data_ex2;

wire is_port0_type,is_port1_type;
wire port0_type_upgrade,port1_type_upgrade,port2_type_upgrade;
wire type_crash;

wire rdata0_0_lsu_fw;
wire rdata0_1_lsu_fw;
wire rdata1_0_lsu_fw;
wire rdata1_1_lsu_fw;
wire rdata2_0_lsu_fw;
wire rdata2_1_lsu_fw;

wire [5 :0] port0_exccode = is_port0_exception? is_port0_exccode: 6'd0;
wire [5 :0] port1_exccode = is_port1_exception? is_port1_exccode: 6'd0;

wire [`GRLEN-1:0] cpucfg_res;

////// func


// uty: test alu
   
////alu op:
//always @(posedge clk) begin //alu op push
//    if (rst)                                    ex1_port0_op <= `LSOC1K_ALU_CODE_BIT'd0;
//    else if (port0_alu_dispatch && is_allow_in) ex1_port0_op <= is_port0_op[`LSOC1K_ALU_CODE];
//end
//
////always @(posedge clk) begin 
////    if (rst)                                    ex1_port1_op <= `LSOC1K_ALU_CODE_BIT'd0;
////    else if (port1_alu_dispatch && is_allow_in) ex1_port1_op <= is_port1_op[`LSOC1K_ALU_CODE];
////end

   dffre_s #(`LSOC1K_ALU_CODE_BIT) port0_op_reg (
      .din (is_port0_op[`LSOC1K_ALU_CODE]),
      .rst (rst),
      .en  (port0_alu_dispatch && is_allow_in),
      .clk (clk),
      .q   (ex1_port0_op),
      .se(), .si(), .so());

////ALU input judge:
//A:
wire alu0_a_zero = is_port0_op[`LSOC1K_LUI];// op_rdpgpr_1 || op_wrpgpr_1; //zero
//wire alu1_a_zero = is_port1_op[`LSOC1K_LUI];// op_rdpgpr_2 || op_wrpgpr_2; 

wire alu0_a_pc = is_port0_op[`LSOC1K_PC_RELATED];
//wire alu1_a_pc = is_port1_op[`LSOC1K_PC_RELATED];

//B:
wire alu0_b_imm = is_port0_op[`LSOC1K_I5] || is_port0_op[`LSOC1K_I12] || is_port0_op[`LSOC1K_I16] || is_port0_op[`LSOC1K_I20];
//wire alu1_b_imm = is_port1_op[`LSOC1K_I5] || is_port1_op[`LSOC1K_I12] || is_port1_op[`LSOC1K_I16] || is_port1_op[`LSOC1K_I20];

wire alu0_b_get_a = is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT;
//wire alu1_b_get_a = is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT;

//immediate operater prepare
wire [ 4:0] port0_i5  = `GET_I5(is_port0_inst);
//wire [ 4:0] port1_i5  = `GET_I5(is_port1_inst);
wire [ 5:0] port0_i6  = `GET_I6(is_port0_inst);
//wire [ 5:0] port1_i6  = `GET_I6(is_port1_inst);
wire [11:0] port0_i12 = `GET_I12(is_port0_inst);
//wire [11:0] port1_i12 = `GET_I12(is_port1_inst);
wire [13:0] port0_i14 = `GET_I14(is_port0_inst);
//wire [13:0] port1_i14 = `GET_I14(is_port1_inst);
wire [15:0] port0_i16 = `GET_I16(is_port0_inst);
//wire [15:0] port1_i16 = `GET_I16(is_port1_inst);
wire [19:0] port0_i20 = `GET_I20(is_port0_inst);
//wire [19:0] port1_i20 = `GET_I20(is_port1_inst);

`ifdef LA64
wire [63:0] port0_i5_u  = {59'b0,port0_i5};
wire [63:0] port1_i5_u  = {59'b0,port1_i5};
wire [63:0] port0_i6_u  = {58'b0,port0_i6};
wire [63:0] port1_i6_u  = {58'b0,port1_i6};
wire [63:0] port0_i12_u = {52'b0,port0_i12};
wire [63:0] port1_i12_u = {52'b0,port1_i12};
wire [63:0] port0_i12_s = {{52{port0_i12[11]}},port0_i12};
wire [63:0] port1_i12_s = {{52{port1_i12[11]}},port1_i12};
wire [63:0] port0_i14_s = {{50{port0_i14[13]}},port0_i14};
wire [63:0] port1_i14_s = {{50{port1_i14[13]}},port1_i14};
wire [63:0] port0_i16_s = {{48{port0_i16[15]}},port0_i16};
wire [63:0] port1_i16_s = {{48{port1_i16[15]}},port1_i16};
wire [63:0] port0_i20_s = {{44{port0_i20[19]}},port0_i20};
wire [63:0] port1_i20_s = {{44{port1_i20[19]}},port1_i20};

wire [63:0] port0_i5_i = is_port0_op[`LSOC1K_DOUBLE_WORD] ? port0_i6_u : port0_i5_u;
wire [63:0] port1_i5_i = is_port1_op[`LSOC1K_DOUBLE_WORD] ? port1_i6_u : port1_i5_u;
wire [63:0] port0_i12_i = is_port0_op[`LSOC1K_UNSIGN] ? port0_i12_u : port0_i12_s;
wire [63:0] port1_i12_i = is_port1_op[`LSOC1K_UNSIGN] ? port1_i12_u : port1_i12_s;

wire [63:0] port0_imm = is_port0_op[`LSOC1K_I5 ] ? port0_i5_i  :
                        is_port0_op[`LSOC1K_I12] ? port0_i12_i :
                        is_port0_op[`LSOC1K_I14] ? port0_i14_s :
                        is_port0_op[`LSOC1K_I16] ? port0_i16_s :
                        is_port0_op[`LSOC1K_I20] ? port0_i20_s :
                        64'b0;
wire [63:0] port1_imm = is_port1_op[`LSOC1K_I5 ] ? port1_i5_i  :
                        is_port1_op[`LSOC1K_I12] ? port1_i12_i :
                        is_port1_op[`LSOC1K_I14] ? port1_i14_s :
                        is_port1_op[`LSOC1K_I16] ? port1_i16_s :
                        is_port1_op[`LSOC1K_I20] ? port1_i20_s :
                        64'b0;

wire [63:0] port0_imm_shifted = is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_2  ? {port0_imm[61:0], 2'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_12 ? {port0_imm[51:0],12'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_16 ? {port0_imm[47:0],16'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_18 ? {port0_imm[45:0],18'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_32 ? {port0_imm[31:0],32'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_52 ? {port0_imm[11:0],52'b0} :
                                port0_imm;
wire [63:0] port1_imm_shifted = is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_2  ? {port1_imm[61:0], 2'b0} :
                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_12 ? {port1_imm[51:0],12'b0} :
                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_16 ? {port1_imm[47:0],16'b0} :
                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_18 ? {port1_imm[45:0],18'b0} :
                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_32 ? {port1_imm[31:0],32'b0} :
                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_52 ? {port1_imm[11:0],52'b0} :
                                port1_imm;
`elsif LA32
wire [31:0] port0_i5_u  = {27'b0,port0_i5};
//wire [31:0] port1_i5_u  = {27'b0,port1_i5};
wire [31:0] port0_i6_u  = {26'b0,port0_i6};
//wire [31:0] port1_i6_u  = {26'b0,port1_i6};
wire [31:0] port0_i12_u = {20'b0,port0_i12};
//wire [31:0] port1_i12_u = {20'b0,port1_i12};
wire [31:0] port0_i12_s = {{20{port0_i12[11]}},port0_i12};
//wire [31:0] port1_i12_s = {{20{port1_i12[11]}},port1_i12};
wire [31:0] port0_i14_s = {{18{port0_i14[13]}},port0_i14};
//wire [31:0] port1_i14_s = {{18{port1_i14[13]}},port1_i14};
wire [31:0] port0_i16_s = {{16{port0_i16[15]}},port0_i16};
//wire [31:0] port1_i16_s = {{16{port1_i16[15]}},port1_i16};
wire [31:0] port0_i20_s = {{12{port0_i20[19]}},port0_i20};
//wire [31:0] port1_i20_s = {{12{port1_i20[19]}},port1_i20};

wire [31:0] port0_i5_i = is_port0_op[`LSOC1K_DOUBLE_WORD] ? port0_i6_u : port0_i5_u;
//wire [31:0] port1_i5_i = is_port1_op[`LSOC1K_DOUBLE_WORD] ? port1_i6_u : port1_i5_u;
wire [31:0] port0_i12_i = is_port0_op[`LSOC1K_UNSIGN] ? port0_i12_u : port0_i12_s;
//wire [31:0] port1_i12_i = is_port1_op[`LSOC1K_UNSIGN] ? port1_i12_u : port1_i12_s;

wire [31:0] port0_imm = is_port0_op[`LSOC1K_I5 ] ? port0_i5_i  :
                        is_port0_op[`LSOC1K_I12] ? port0_i12_i :
                        is_port0_op[`LSOC1K_I14] ? port0_i14_s :
                        is_port0_op[`LSOC1K_I16] ? port0_i16_s :
                        is_port0_op[`LSOC1K_I20] ? port0_i20_s :
                        32'b0;
//wire [31:0] port1_imm = is_port1_op[`LSOC1K_I5 ] ? port1_i5_i  :
//                        is_port1_op[`LSOC1K_I12] ? port1_i12_i :
//                        is_port1_op[`LSOC1K_I14] ? port1_i14_s :
//                        is_port1_op[`LSOC1K_I16] ? port1_i16_s :
//                        is_port1_op[`LSOC1K_I20] ? port1_i20_s :
//                        32'b0;

wire [31:0] port0_imm_shifted = is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_2  ? {port0_imm[29:0], 2'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_12 ? {port0_imm[19:0],12'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_16 ? {port0_imm[15:0],16'b0} :
                                is_port0_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_18 ? {port0_imm[13:0],18'b0} :
                                port0_imm;
//wire [31:0] port1_imm_shifted = is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_2  ? {port1_imm[29:0], 2'b0} :
//                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_12 ? {port1_imm[19:0],12'b0} :
//                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_16 ? {port1_imm[15:0],16'b0} :
//                                is_port1_op[`LSOC1K_IMM_SHIFT] == `LSOC1K_IMM_SHIFT_18 ? {port1_imm[13:0],18'b0} :
//                                port1_imm;
`endif

////ALU operater push
//A:
//always @(posedge clk) begin
//    if(port0_alu_dispatch && is_allow_in) begin
//        ex1_port0_a <= alu0_a_pc   ? is_port0_pc :
//                      rdata0_0_input;
//        ex1_port0_a_lsu_fw <= !alu0_a_pc && rdata0_0_lsu_fw;
//    end
//end


   wire [`GRLEN-1:0] port0_a;
   assign port0_a = alu0_a_pc? is_port0_pc : rdata0_0_input;

   dffe_s #(`GRLEN) port0_a_reg (
      .din (port0_a),
      .en  (port0_alu_dispatch && is_allow_in),
      .clk (clk),
      .q   (ex1_port0_a),
      .se(), .si(), .so());

   
   wire port0_a_lsu_fw;
   assign port0_a_lsu_fw = !alu0_a_pc && rdata0_0_lsu_fw;
   
   dffe_s #(1) port0_a_lsu_fw_reg (
      .din (port0_a_lsu_fw),
      .en  (port0_alu_dispatch && is_allow_in),
      .clk (clk),
      .q   (ex1_port0_a_lsu_fw),
      .se(), .si(), .so());

//always @(posedge clk) begin
//    if(port1_alu_dispatch && is_allow_in) begin
//        ex1_port1_a <= alu1_a_pc   ? is_port1_pc :
//                      rdata1_0_input;
//        ex1_port1_a_lsu_fw <= !alu1_a_pc && rdata1_0_lsu_fw;
//    end
//end

//B:
//always @(posedge clk) begin
//    if(port0_alu_dispatch && is_allow_in) begin
//        ex1_port0_b <= alu0_b_imm ? port0_imm_shifted :
//                       rdata0_1_input;
//        ex1_port0_b_lsu_fw <= !alu0_b_imm && rdata0_1_lsu_fw;
//    end
//end

   wire [`GRLEN-1:0] port0_b;
   assign port0_b = alu0_b_imm? port0_imm_shifted : rdata0_1_input;

   dffe_s #(`GRLEN) port0_b_reg (
      .din (port0_b),
      .en  (port0_alu_dispatch && is_allow_in),
      .clk (clk),
      .q   (ex1_port0_b),
      .se(), .si(), .so());

   wire port0_b_lsu_fw;
   assign port0_b_lsu_fw = !alu0_b_imm && rdata0_1_lsu_fw;
   
   dffe_s #(1) port0_b_lsu_fw_reg (
      .din (port0_b_lsu_fw),
      .en  (port0_alu_dispatch && is_allow_in),
      .clk (clk),
      .q   (ex1_port0_b_lsu_fw),
      .se(), .si(), .so());

//always @(posedge clk) begin
//    if(port1_alu_dispatch && is_allow_in) begin
//        ex1_port1_b <= alu1_b_imm ? port1_imm_shifted :
//                      rdata1_1_input;
//        ex1_port1_b_lsu_fw <= !alu1_b_imm && rdata1_1_lsu_fw;
//    end
//end

//C:
//always @(posedge clk) begin
//    if(port0_alu_dispatch && is_allow_in) begin
//        `ifdef LA64
//        ex1_port0_c <=(is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_L || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_T) ? {63'd0,!is_port0_op[`LSOC1K_UNSIGN]} :
//                      (is_port0_op[`LSOC1K_SA] || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ALIGN) ? {61'd0,`GET_SA(is_port0_inst)} :
//                      (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_INS) ? {52'd0,`GET_MSLSBD(is_port0_inst)} :
//                      (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ROT) ? port0_imm :
//                      port0_imm;
//        `elsif LA32
//        ex1_port0_c <=(is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_L || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_T) ? {31'd0,!is_port0_op[`LSOC1K_UNSIGN]} :
//                      (is_port0_op[`LSOC1K_SA] || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ALIGN) ? {29'd0,`GET_SA(is_port0_inst)} :
//                      (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_INS) ? {20'd0,`GET_MSLSBD(is_port0_inst)} :
//                      (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ROT) ? port0_imm :
//                      port0_imm;
//        `endif
//    end
//end


   wire [`GRLEN-1:0] port0_c;
   `ifdef LA64
   assign port0_c = (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_L || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_T) ? {63'd0,!is_port0_op[`LSOC1K_UNSIGN]} :
		    (is_port0_op[`LSOC1K_SA] || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ALIGN) ? {61'd0,`GET_SA(is_port0_inst)} :
		    (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_INS) ? {52'd0,`GET_MSLSBD(is_port0_inst)} :
		    (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ROT) ? port0_imm :
		    port0_imm;
   `elsif LA32
   assign port0_c = (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_L || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_T) ? {31'd0,!is_port0_op[`LSOC1K_UNSIGN]} :
		    (is_port0_op[`LSOC1K_SA] || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ALIGN) ? {29'd0,`GET_SA(is_port0_inst)} :
		    (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT || is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_INS) ? {20'd0,`GET_MSLSBD(is_port0_inst)} :
		    (is_port0_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ROT) ? port0_imm :
		    port0_imm;
   `endif

   
   dffe_s #(1) port0_c_reg (
      .din (port0_c),
      .en  (port0_alu_dispatch && is_allow_in),
      .clk (clk),
      .q   (ex1_port0_c),
      .se(), .si(), .so());


   

//always @(posedge clk) begin
//    if(port1_alu_dispatch && is_allow_in) begin
//        `ifdef LA64
//        ex1_port1_c <=(is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_L || is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_T) ? {63'd0,!is_port1_op[`LSOC1K_UNSIGN]} :
//                      (is_port1_op[`LSOC1K_SA] || is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ALIGN) ? {61'd0,`GET_SA(is_port1_inst)} :
//                      (is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT || is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_INS) ? {52'd0,`GET_MSLSBD(is_port1_inst)} :
//                      (is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ROT) ? port1_imm :
//                      port1_imm;
//        `elsif LA32
//        ex1_port1_c <=(is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_L || is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_COUNT_T) ? {31'd0,!is_port1_op[`LSOC1K_UNSIGN]} :
//                      (is_port1_op[`LSOC1K_SA] || is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ALIGN) ? {29'd0,`GET_SA(is_port1_inst)} :
//                      (is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT || is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_INS) ? {20'd0,`GET_MSLSBD(is_port1_inst)} :
//                      (is_port1_op[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_ROT) ? port1_imm :
//                      port1_imm;
//        `endif
//    end
//end

//always @(posedge clk) begin
//    if(is_allow_in) begin
//        ex1_port0_a_ignore <= alu0_a_pc || alu0_a_zero;
//        ex1_port0_b_ignore <= alu0_b_imm;
////        ex1_port1_a_ignore <= alu1_a_pc || alu1_a_zero;
////        ex1_port1_b_ignore <= alu1_b_imm;
//        ex1_port0_b_get_a  <= alu0_b_get_a;
////        ex1_port1_b_get_a  <= alu1_b_get_a;
//        ex1_port0_double   <= is_port0_op[`LSOC1K_DOUBLE_WORD];
////        ex1_port1_double   <= is_port1_op[`LSOC1K_DOUBLE_WORD];
//    end
//end

   wire port0_a_ignore;
   assign port0_a_ignore = alu0_a_pc || alu0_a_zero;

   dffe_s #(1) port0_a_ignore_reg (
      .din (port0_a_ignore),
      .en  (is_allow_in),
      .clk (clk),
      .q   (ex1_port0_a_ignore),
      .se(), .si(), .so());

   
   dffe_s #(1) port0_b_ignore_reg (
      .din (alu0_b_imm),
      .en  (is_allow_in),
      .clk (clk),
      .q   (ex1_port0_b_ignore),
      .se(), .si(), .so());
   
   dffe_s #(1) port0_b_get_a_reg (
      .din (alu0_b_get_a),
      .en  (is_allow_in),
      .clk (clk),
      .q   (ex1_port0_b_get_a),
      .se(), .si(), .so());
   
   dffe_s #(1) port0_double_reg (
      .din (is_port0_op[`LSOC1K_DOUBLE_WORD]),
      .en  (is_allow_in),
      .clk (clk),
      .q   (ex1_port0_double),
      .se(), .si(), .so());
   
// uty: try alu first 

////LSU operater push
//LSU
wire lsu_dispatch        = port0_lsu_dispatch || port1_lsu_dispatch;
assign port0_triple_read = is_port0_op[`LSOC1K_TRIPLE_READ] && is_port0_valid;
assign port1_triple_read = is_port1_op[`LSOC1K_TRIPLE_READ] && is_port1_valid;
wire port0_double_read   = is_port0_op[`LSOC1K_DOUBLE_READ] && is_port0_valid;
wire port1_double_read   = is_port1_op[`LSOC1K_DOUBLE_READ] && is_port1_valid;

always @(posedge clk) begin
    if(lsu_dispatch && is_allow_in) begin
        //ex1_lsu_base          <= port0_lsu_dispatch ? rdata0_0_input : rdata1_0_input;
        //ex1_lsu_offset        <= port0_lsu_dispatch ? (port0_double_read ? rdata0_1_input : port0_triple_read ? rdata2_0_input : port0_imm_shifted) : (port1_double_read ? rdata1_1_input : port1_triple_read ? rdata2_1_input : port1_imm_shifted);
        //ex1_lsu_wdata         <= port0_lsu_dispatch ? rdata0_1_input : rdata1_1_input;
       
        ex1_lsu_base          <= rdata0_0_input;
        ex1_lsu_offset        <= port0_double_read ? rdata0_1_input : port0_triple_read ? rdata2_0_input : port0_imm_shifted;
        ex1_lsu_wdata         <= rdata0_1_input;
       
        ex1_lsu_base_lsu_fw   <= port0_lsu_dispatch && rdata0_0_lsu_fw || port1_lsu_dispatch && rdata1_0_lsu_fw;
        ex1_lsu_offset_lsu_fw <= port0_lsu_dispatch && (port0_double_read && rdata0_1_lsu_fw || port0_triple_read && rdata2_0_lsu_fw) ||
                                 port1_lsu_dispatch && (port1_double_read && rdata1_1_lsu_fw || port1_triple_read && rdata2_1_lsu_fw);
        ex1_lsu_wdata_lsu_fw  <= port0_lsu_dispatch && rdata0_1_lsu_fw || port1_lsu_dispatch && rdata1_1_lsu_fw;
        //ex1_lsu_op            <= port0_lsu_dispatch ? is_port0_op[`LSOC1K_OP_CODE] : is_port1_op[`LSOC1K_OP_CODE];
        ex1_lsu_op            <= is_port0_op[`LSOC1K_OP_CODE];
    end
end

////register interface
// common registers
assign raddr0_0 = is_port0_op[`LSOC1K_RD2RJ  ] ? `GET_RD(is_port0_inst) : `GET_RJ(is_port0_inst);
assign raddr0_1 = is_port0_op[`LSOC1K_RD_READ] ? `GET_RD(is_port0_inst) : `GET_RK(is_port0_inst);
assign raddr1_0 = is_port1_op[`LSOC1K_RD2RJ  ] ? `GET_RD(is_port1_inst) : `GET_RJ(is_port1_inst);
assign raddr1_1 = is_port1_op[`LSOC1K_RD_READ] ? `GET_RD(is_port1_inst) : `GET_RK(is_port1_inst);
assign raddr2_0 = port0_triple_read ? `GET_RK(is_port0_inst) : is_port2_op[`LSOC1K_RD2RJ] ? `GET_RD(is_port2_inst) : `GET_RJ(is_port2_inst);
assign raddr2_1 = port1_triple_read ? `GET_RK(is_port1_inst) : `GET_RD(is_port2_inst);

wire tlb_related_0 = is_port0_op[`LSOC1K_TLB_RELATED];
wire tlb_related_1 = is_port1_op[`LSOC1K_TLB_RELATED];

wire csr_related_0 = is_port0_op[`LSOC1K_CSR_RELATED];
wire csr_related_1 = is_port1_op[`LSOC1K_CSR_RELATED];

// csr
assign csr_raddr = (is_port0_op[`LSOC1K_RDTIME] && is_port0_valid) ? `LSOC1K_CSR_TID : (csr_related_0 && is_port0_valid) ? `GET_CSR(is_port0_inst) : `GET_CSR(is_port1_inst);

////MDU operater push
always @(posedge clk) begin 
    if((port0_mul_dispatch || port1_mul_dispatch || port0_div_dispatch || port1_div_dispatch) && is_allow_in) begin
        ex1_mdu_op <= (port0_mul_dispatch || port0_div_dispatch) ? is_port0_op[`LSOC1K_MDU_CODE] : is_port1_op[`LSOC1K_MDU_CODE];
        ex1_mdu_a  <= (port0_mul_dispatch || port0_div_dispatch) ? rdata0_0_input : rdata1_0_input;
        ex1_mdu_b  <= (port0_mul_dispatch || port0_div_dispatch) ? rdata0_1_input : rdata1_1_input;
        ex1_mdu_a_lsu_fw <= (port0_mul_dispatch || port0_div_dispatch) && rdata0_0_lsu_fw || (port1_mul_dispatch || port1_div_dispatch) && rdata1_0_lsu_fw;
        ex1_mdu_b_lsu_fw <= (port0_mul_dispatch || port0_div_dispatch) && rdata0_1_lsu_fw || (port1_mul_dispatch || port1_div_dispatch) && rdata1_1_lsu_fw;
    end
end

////BRU operater push
wire branch_dispatch   = port0_bru_dispatch || port1_bru_dispatch;

wire [15:0] port0_offset16 = `GET_OFFSET16(is_port0_inst);
wire [15:0] port1_offset16 = `GET_OFFSET16(is_port1_inst);
wire [15:0] port2_offset16 = `GET_OFFSET16(is_port2_inst);
wire [20:0] port0_offset21 = `GET_OFFSET21(is_port0_inst);
wire [20:0] port1_offset21 = `GET_OFFSET21(is_port1_inst);
wire [20:0] port2_offset21 = `GET_OFFSET21(is_port2_inst);
wire [25:0] port0_offset26 = `GET_OFFSET26(is_port0_inst);
wire [25:0] port1_offset26 = `GET_OFFSET26(is_port1_inst);
wire [25:0] port2_offset26 = `GET_OFFSET26(is_port2_inst);

`ifdef LA64
wire [63:0] port0_offset = is_port0_op[`LSOC1K_RD_READ    ] ? {{46{port0_offset16[15]}},port0_offset16,2'b0} :
                           is_port0_op[`LSOC1K_HIGH_TARGET] ? {{36{port0_offset26[25]}},port0_offset26,2'b0} :
                                                              {{41{port0_offset21[20]}},port0_offset21,2'b0} ;
wire [63:0] port1_offset = is_port1_op[`LSOC1K_RD_READ    ] ? {{46{port1_offset16[15]}},port1_offset16,2'b0} :
                           is_port1_op[`LSOC1K_HIGH_TARGET] ? {{36{port1_offset26[25]}},port1_offset26,2'b0} :
                                                              {{41{port1_offset21[20]}},port1_offset21,2'b0} ;
wire [63:0] port2_offset = is_port2_op[`LSOC1K_RD_READ    ] ? {{46{port2_offset16[15]}},port2_offset16,2'b0} :
                           is_port2_op[`LSOC1K_HIGH_TARGET] ? {{36{port2_offset26[25]}},port2_offset26,2'b0} :
                                                              {{41{port2_offset21[20]}},port2_offset21,2'b0} ;
`elsif LA32
wire [31:0] port0_offset = is_port0_op[`LSOC1K_RD_READ    ] ? {{14{port0_offset16[15]}},port0_offset16,2'b0} :
                           is_port0_op[`LSOC1K_HIGH_TARGET] ? {{ 4{port0_offset26[25]}},port0_offset26,2'b0} :
                                                              {{ 9{port0_offset21[20]}},port0_offset21,2'b0} ;
wire [31:0] port1_offset = is_port1_op[`LSOC1K_RD_READ    ] ? {{14{port1_offset16[15]}},port1_offset16,2'b0} :
                           is_port1_op[`LSOC1K_HIGH_TARGET] ? {{ 4{port1_offset26[25]}},port1_offset26,2'b0} :
                                                              {{ 9{port1_offset21[20]}},port1_offset21,2'b0} ;
wire [31:0] port2_offset = is_port2_op[`LSOC1K_RD_READ    ] ? {{14{port2_offset16[15]}},port2_offset16,2'b0} :
                           is_port2_op[`LSOC1K_HIGH_TARGET] ? {{ 4{port2_offset26[25]}},port2_offset26,2'b0} :
                                                              {{ 9{port2_offset21[20]}},port2_offset21,2'b0} ;
`endif

wire port0_bru_related = is_port0_op[`LSOC1K_BRU_RELATED];
wire port1_bru_related = is_port1_op[`LSOC1K_BRU_RELATED];
wire port2_bru_related = is_port2_op[`LSOC1K_BRU_RELATED];

wire is_port0_link = (((is_port0_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (is_port0_rf_target == 5'd1)) || (is_port0_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_BL)) && port0_bru_related;
wire is_port1_link = (((is_port1_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (is_port1_rf_target == 5'd1)) || (is_port1_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_BL)) && port1_bru_related;
wire is_port0_jrra = ((is_port0_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (raddr0_0 == 5'd1)) && port0_bru_related;
wire is_port1_jrra = ((is_port1_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (raddr1_0 == 5'd1)) && port1_bru_related;
wire is_port2_jrra = ((is_port2_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (raddr2_0 == 5'd1)) && port2_bru_related;
wire is_port0_jrop = (is_port0_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (raddr0_0 != 5'd1)&& port0_bru_related;
wire is_port1_jrop = (is_port1_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (raddr1_0 != 5'd1)&& port1_bru_related;
wire is_port2_jrop = (is_port2_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_JR) && (raddr2_0 != 5'd1)&& port2_bru_related;
wire is_port0_brop = (is_port0_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_JR) && (is_port0_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_BL) && (is_port0_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_IDLE) && port0_bru_related;
wire is_port1_brop = (is_port1_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_JR) && (is_port1_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_BL) && (is_port1_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_IDLE) && port1_bru_related;
wire is_port2_brop = (is_port2_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_JR) && (is_port2_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_BL) && (is_port2_op[`LSOC1K_BRU_CODE] != `LSOC1K_BRU_IDLE) && port2_bru_related;

always @(posedge clk) begin
    if (rst) begin
        ex1_bru_br_taken  <= 1'b0;
        ex1_bru_link      <= 1'b0;
        ex1_bru_jrra      <= 1'b0;
        ex1_bru_brop      <= 1'b0;
        ex1_bru_jrop      <= 1'b0;
    end
    else if(/*(port0_bru_dispatch || port1_bru_dispatch) &&*/ is_allow_in) begin
        ex1_bru_op        <= is_port2_valid ? is_port2_op[`LSOC1K_BRU_CODE] : port0_bru_dispatch ? is_port0_op[`LSOC1K_BRU_CODE] : is_port1_op[`LSOC1K_BRU_CODE];
        ex1_bru_a         <= is_port2_valid ? rdata2_0_input               : port0_bru_dispatch ? rdata0_0_input                    : rdata1_0_input;
        ex1_bru_b         <= is_port2_valid ? rdata2_1_input               : port0_bru_dispatch ? rdata0_1_input                    : rdata1_1_input;
        ex1_bru_br_taken  <= is_port2_valid ? is_port2_br_taken            : port0_bru_dispatch ? is_port0_br_taken                 : is_port1_br_taken;
        ex1_bru_br_target <= is_port2_valid ? {is_port2_br_target,2'b0}    : port0_bru_dispatch ? {is_port0_br_target,2'b0}         : {is_port1_br_target,2'b0};
        ex1_bru_hint      <= is_port2_valid ? is_port2_hint                : port0_bru_dispatch ? is_port0_hint                     : is_port1_hint;
        ex1_bru_offset    <= is_port2_valid ? port2_offset                 : port0_bru_dispatch ? port0_offset                      : port1_offset;
        ex1_bru_pc        <= is_port2_valid ? is_port2_pc                  : port0_bru_dispatch ? is_port0_pc                       : is_port1_pc;
        ex1_bru_a_lsu_fw  <= is_port2_valid && rdata2_0_lsu_fw || port0_bru_dispatch && rdata0_0_lsu_fw || port1_bru_dispatch && rdata1_0_lsu_fw;
        ex1_bru_b_lsu_fw  <= is_port2_valid && rdata2_1_lsu_fw || port0_bru_dispatch && rdata0_1_lsu_fw || port1_bru_dispatch && rdata1_1_lsu_fw;
        ex1_bru_port[1]   <= is_port2_id || port1_bru_dispatch;
        ex1_bru_port[2]   <= is_port2_app && is_port2_valid;
    end

    if(allow_in) begin
        ex1_branch_valid  <= ((port0_sr_ur == `EX_BRU && is_port0_valid) || (port1_sr_ur == `EX_BRU && is_port1_valid) || is_port2_valid) && !type_crash && !bru_cancel;
        ex1_bru_delay     <= bru_delay;
        ex1_bru_link      <= is_port2_valid ? 1'b0          : port0_bru_dispatch ? (is_port0_link && is_port0_valid) : (is_port1_link && is_port1_valid);
        ex1_bru_jrra      <= is_port2_valid ? is_port2_jrra : port0_bru_dispatch ? is_port0_jrra                     : is_port1_jrra;
        ex1_bru_brop      <= is_port2_valid ? is_port2_brop : port0_bru_dispatch ? is_port0_brop                     : is_port1_brop;
        ex1_bru_jrop      <= is_port2_valid ? is_port2_jrop : port0_bru_dispatch ? is_port0_jrop                     : is_port1_jrop;
    end
end

////NONE operater push
wire port0_csr_write   = is_port0_op[`LSOC1K_CSR_WRITE] || is_port0_op[`LSOC1K_CACHE_RELATED];
wire port0_csr_read    = is_port0_op[`LSOC1K_CSR_READ ] || is_port0_op[`LSOC1K_ERET]         || is_port0_op[`LSOC1K_CACHE_RELATED]; // raddr or waddr refers to cp0 regs
wire port1_csr_write   = (is_port1_op[`LSOC1K_CSR_WRITE] || is_port1_op[`LSOC1K_CACHE_RELATED]) && !is_port0_op[`LSOC1K_RDTIME];
wire port1_csr_read    = is_port1_op[`LSOC1K_CSR_READ ] || is_port1_op[`LSOC1K_ERET]         || is_port1_op[`LSOC1K_CACHE_RELATED];

wire port0_csr_roll_back = is_port0_valid && ( port0_csr_write ||
                                               is_port0_op[`LSOC1K_TLB_RELATED] || 
                                               is_port0_op[`LSOC1K_IBAR]);
wire port1_csr_roll_back = is_port1_valid && port1_csr_write; 

wire [`LSOC1K_CSR_OP_BIT-1:0] port0_csr_op = is_port0_op[`LSOC1K_CSR_XCHG ] ? `LSOC1K_CSR_CSRXCHG :
                                             is_port0_op[`LSOC1K_CSR_WRITE] ? `LSOC1K_CSR_CSRWR   :
                                             is_port0_op[`LSOC1K_CSR_READ ] ? `LSOC1K_CSR_CSRRD   :
                                                                              `LSOC1K_CSR_IDLE    ;

wire [`LSOC1K_CSR_OP_BIT-1:0] port1_csr_op = is_port1_op[`LSOC1K_CSR_XCHG ] ? `LSOC1K_CSR_CSRXCHG :
                                             is_port1_op[`LSOC1K_CSR_WRITE] ? `LSOC1K_CSR_CSRWR   :
                                             is_port1_op[`LSOC1K_CSR_READ ] ? `LSOC1K_CSR_CSRRD   :
                                                                              `LSOC1K_CSR_IDLE    ;
always @(posedge clk) begin
    if (rst) begin
        ex1_none0_exception <= 1'd0;
        ex1_none0_exccode   <= 6'b0;
    end
    else if(is_allow_in)
    begin
        ex1_none0_exccode                     <= port0_exccode;
        ex1_none0_exception                   <= is_port0_exception && is_port0_valid;
        `ifdef LA64
        ex1_none0_result                      <= (is_port0_op[`LSOC1K_RDTIME] && is_port0_valid) ? timer : csr_rdata;
        `elsif LA32
        ex1_none0_result                      <= (is_port0_op[`LSOC1K_RDTIME] && is_port0_valid) ? (is_port0_op[`LSOC1K_HIGH_TARGET] ? timer[63:32] : timer[31:0]) : csr_rdata;
        `endif
        ex1_none0_csr_a                       <= rdata0_0_input;
        ex1_none0_csr_result                  <= is_port0_op[`LSOC1K_CPUCFG] ? cpucfg_res : rdata0_1_input;
        ex1_none0_csr_addr                    <= `GET_CSR(is_port0_inst);
        ex1_none0_op[`LSOC1K_CSR_VALID]       <= is_port0_op[`LSOC1K_CSR_READ] || is_port0_op[`LSOC1K_CSR_WRITE];
        ex1_none0_op[`LSOC1K_TLB_VALID]       <= tlb_related_0;
        ex1_none0_op[`LSOC1K_CACHE_VALID]     <= is_port0_op[`LSOC1K_CACHE_RELATED];
        ex1_none0_op[`LSOC1K_CSR_OP]          <= tlb_related_0 ? is_port0_op[`LSOC1K_TLB_CODE] : // TODO:
                                                 (csr_related_0 && is_port0_valid) ? port0_csr_op :
                                                 `LSOC1K_CSR_IDLE;
        ex1_none0_info[`LSOC1K_CSR_ROLL_BACK] <= port0_csr_roll_back;
        ex1_none0_info[`LSOC1K_CSR_EXCPT    ] <= //is_port0_op[`LSOC1K_DBGCALL] ? `LSOC1K_CSR_DBCALL        :
                                                 is_port0_op[`LSOC1K_ERET   ] ? `LSOC1K_CSR_ERET          :
                                                                                `LSOC1K_CSR_EXCPT_BIT'b00 ;
        ex1_none0_info[`LSOC1K_MICROOP      ] <= is_port0_op[`LSOC1K_RDTIME] && is_port0_valid;
    end
end

////NONE1 operater push
always @(posedge clk) begin
    if (rst) begin
        ex1_none1_exception <= 1'd0;
        ex1_none1_exccode   <= 6'b0;
    end
    else if(is_allow_in)
    begin
        ex1_none1_exccode                     <= port1_exccode;
        ex1_none1_exception                   <= is_port1_exception && is_port1_valid && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid);
        ex1_none1_result                      <= csr_rdata;
        ex1_none1_csr_a                       <= rdata1_0_input;
        ex1_none1_csr_result                  <= rdata1_1_input;
        ex1_none1_csr_addr                    <= `GET_CSR(is_port1_inst);
        ex1_none1_op[`LSOC1K_CSR_VALID]       <= is_port1_op[`LSOC1K_CSR_READ] || is_port1_op[`LSOC1K_CSR_WRITE];
        ex1_none1_op[`LSOC1K_TLB_VALID]       <= tlb_related_1;
        ex1_none1_op[`LSOC1K_CACHE_VALID]     <= is_port1_op[`LSOC1K_CACHE_RELATED];
        ex1_none1_op[`LSOC1K_CSR_OP]          <= tlb_related_1 ? is_port1_op[`LSOC1K_TLB_CODE] : // TODO:
                                                 (csr_related_1 && is_port1_valid) && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid) ? port1_csr_op : 
                                                 `LSOC1K_CSR_IDLE;
        ex1_none1_info[`LSOC1K_CSR_ROLL_BACK] <= port1_csr_roll_back;
        ex1_none1_info[`LSOC1K_CSR_EXCPT    ] <= //is_port1_op[`LSOC1K_DBGCALL] ? `LSOC1K_CSR_DBCALL        :
                                                 is_port1_op[`LSOC1K_ERET   ] ? `LSOC1K_CSR_ERET          :
                                                                                `LSOC1K_CSR_EXCPT_BIT'b00 ;
        ex1_none1_info[`LSOC1K_MICROOP      ] <= is_port0_op[`LSOC1K_RDTIME] && is_port0_valid;
    end
end

////// basic
always @(posedge clk) begin 
    if (rst) begin
        ex1_port0_ll <= 1'd0;
        ex1_port0_sc <= 1'd0;
        ex1_port1_ll <= 1'd0;
        ex1_port1_sc <= 1'd0;
    end
    else if (is_allow_in) begin
        ex1_port0_inst      <= is_port0_inst;
        ex1_port1_inst      <= is_port1_inst;
        ex1_port0_pc        <= is_port0_pc;
        ex1_port1_pc        <= is_port1_pc;
        ex1_port0_src       <= port0_sr_ur;
        ex1_port1_src       <= port1_sr_ur;
    end
end

assign port0_sr_ur =    port0_alu_dispatch   ? `EX_ALU0  :
                        port0_bru_dispatch   ? `EX_BRU   :
                        (port0_lsu_dispatch && !tlb_related_0)   ? `EX_LSU   :
                        port0_mul_dispatch   ? `EX_MUL   :
                        port0_div_dispatch   ? `EX_DIV   :
                        port0_none_dispatch  ? `EX_NONE0 :
                                               `EX_SR'd0 ;

assign port1_sr_ur =    (is_port0_op[`LSOC1K_RDTIME] && is_port0_valid) ? `EX_NONE1 :
                        port1_alu_dispatch   ? `EX_ALU1  :
                        port1_bru_dispatch   ? `EX_BRU   :
                        (port1_lsu_dispatch && !tlb_related_1) ? `EX_LSU   :
                        port1_mul_dispatch   ? `EX_MUL   :
                        port1_div_dispatch   ? `EX_DIV   :
                        port1_none_dispatch  ? `EX_NONE1 :
                                               `EX_SR'd0 ;

////valid
always @(posedge clk) begin // internal valid
    if (rst || eret || exception || wb_cancel || bru_cancel_all) port0_valid <= 1'd0;
    else if (allow_in)                                           port0_valid <= is_port0_valid && !type_crash && !bru_cancel && !bru_cancel_all;

    if (rst || eret || exception || wb_cancel || (bru_cancel && !bru_ignore && !bru_port) || bru_cancel_all) port1_valid <= 1'd0;
    else if (allow_in)                                                                                       port1_valid <= is_port1_valid && !type_crash && !bru_cancel && !((bru_cancel && !bru_ignore) || bru_cancel_all);

    if (rst || eret || exception || wb_cancel) ex1_bru_port[0] <= 1'd0;
    else if(allow_in)                          ex1_bru_port[0] <= is_port2_valid && !type_crash && !bru_cancel;
end

////dispatch
wire port0_exception = is_port0_exception || is_port0_op[`LSOC1K_IBAR] || is_port0_op[`LSOC1K_SYSCALL] || is_port0_op[`LSOC1K_BREAK] || is_port0_op[`LSOC1K_ERET];

//main
assign port0_alu_dispatch  = !is_port0_op[`LSOC1K_LSU_RELATED] && !is_port0_op[`LSOC1K_BRU_RELATED] && !is_port0_op[`LSOC1K_MUL_RELATED] && !is_port0_op[`LSOC1K_DIV_RELATED] && !is_port0_op[`LSOC1K_CSR_RELATED] && !port0_exception; // alu0 is binded to port0
assign port0_lsu_dispatch  = is_port0_op[`LSOC1K_LSU_RELATED] && is_port0_valid && !port0_exception;
assign port0_bru_dispatch  = is_port0_op[`LSOC1K_BRU_RELATED] && is_port0_valid && !port0_exception;
assign port0_mul_dispatch  = is_port0_op[`LSOC1K_MUL_RELATED] && is_port0_valid && !port0_exception;
assign port0_div_dispatch  = is_port0_op[`LSOC1K_DIV_RELATED] && is_port0_valid && !port0_exception;
assign port0_none_dispatch = (is_port0_op[`LSOC1K_CSR_RELATED] || is_port0_op[`LSOC1K_TLB_RELATED] || is_port0_op[`LSOC1K_CACHE_RELATED]) && is_port0_valid || port0_exception ;

assign port1_alu_dispatch  = !is_port1_op[`LSOC1K_LSU_RELATED] && !is_port1_op[`LSOC1K_BRU_RELATED] && !is_port1_op[`LSOC1K_MUL_RELATED] && !is_port1_op[`LSOC1K_DIV_RELATED] && !is_port1_op[`LSOC1K_CSR_RELATED] && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid); // alu1 is binded to port1
assign port1_lsu_dispatch  = is_port1_op[`LSOC1K_LSU_RELATED] && is_port1_valid && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid);
assign port1_bru_dispatch  = is_port1_op[`LSOC1K_BRU_RELATED] && is_port1_valid && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid);
assign port1_mul_dispatch  = is_port1_op[`LSOC1K_MUL_RELATED] && is_port1_valid && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid);
assign port1_div_dispatch  = is_port1_op[`LSOC1K_DIV_RELATED] && is_port1_valid && !(is_port0_op[`LSOC1K_RDTIME] && is_port0_valid);
assign port1_none_dispatch = (is_port1_op[`LSOC1K_CSR_RELATED] || is_port1_op[`LSOC1K_TLB_RELATED] || is_port1_op[`LSOC1K_CACHE_RELATED]) && is_port1_valid || is_port1_exception || (is_port0_op[`LSOC1K_RDTIME] && is_port0_valid);

assign port0_dispatch = port0_alu_dispatch || port0_lsu_dispatch || port0_bru_dispatch || port0_mul_dispatch || port0_div_dispatch || port0_none_dispatch;
assign port1_dispatch = port1_alu_dispatch || port1_lsu_dispatch || port1_bru_dispatch || port1_mul_dispatch || port1_div_dispatch || port1_none_dispatch;

assign allow_in = (port0_dispatch || !is_port0_valid) && (port1_dispatch || !is_port1_valid) && ex1_allow_in;
assign is_allow_in = allow_in && !type_crash;

//valid output
assign ex1_port0_valid = port0_valid;
assign ex1_port1_valid = port1_valid;

////forwarding related
//inst type
assign is_port0_type = is_port0_op[`LSOC1K_MUL_RELATED  ] ||
                       is_port0_op[`LSOC1K_DIV_RELATED  ] ||
                       is_port0_op[`LSOC1K_CACHE_RELATED] ||
                       is_port0_op[`LSOC1K_CSR_RELATED  ] ||
                       is_port0_op[`LSOC1K_LSU_RELATED  ] ;

assign is_port1_type = is_port1_op[`LSOC1K_MUL_RELATED  ] ||
                       is_port1_op[`LSOC1K_DIV_RELATED  ] ||
                       is_port1_op[`LSOC1K_CACHE_RELATED] ||
                       is_port1_op[`LSOC1K_CSR_RELATED  ] ||
                       is_port1_op[`LSOC1K_LSU_RELATED  ] ;

always @(posedge clk) begin
    if(is_allow_in) begin
        ex1_port0_type <= is_port0_type || port0_type_upgrade;
        ex1_port1_type <= is_port1_type || port1_type_upgrade;
        ex1_port2_type <= port2_type_upgrade;
    end
end

//store related info
always @(posedge clk) begin // register file write wen info
    if (rst) begin
        ex1_port0_rf_wen    <= 1'd0;
        ex1_port1_rf_wen    <= 1'd0;
        ex1_port0_rf_target <= 5'd0;
        ex1_port1_rf_target <= 5'd0;
    end
    else if (allow_in) begin
        ex1_port0_rf_wen    <= is_port0_rf_wen && is_port0_valid;
        ex1_port1_rf_wen    <= is_port1_rf_wen && is_port1_valid;
        ex1_port0_rf_target <= (is_port0_valid && !type_crash) ? is_port0_rf_target : 5'd0;
        ex1_port1_rf_target <= (is_port1_valid && !type_crash) ? is_port1_rf_target : 5'd0;
        ex1_raddr0_0        <= raddr0_0;
        ex1_raddr0_1        <= raddr0_1;
        ex1_raddr1_0        <= raddr1_0;
        ex1_raddr1_1        <= raddr1_1;
        ex1_raddr2_0        <= raddr2_0;
        ex1_raddr2_1        <= raddr2_1;
    end
end

////forwarding check
wire raddr0_0_valid = is_port0_op[`LSOC1K_RJ_READ] || is_port0_op[`LSOC1K_RD2RJ  ];
wire raddr0_1_valid = is_port0_op[`LSOC1K_RK_READ] || is_port0_op[`LSOC1K_RD_READ];
wire raddr1_0_valid = is_port1_op[`LSOC1K_RJ_READ] || is_port1_op[`LSOC1K_RD2RJ  ];
wire raddr1_1_valid = is_port1_op[`LSOC1K_RK_READ] || is_port1_op[`LSOC1K_RD_READ];
wire raddr2_0_valid = is_port2_op[`LSOC1K_RJ_READ] || is_port2_op[`LSOC1K_RD2RJ  ] || is_port0_op[`LSOC1K_TRIPLE_READ];
wire raddr2_1_valid = is_port2_op[`LSOC1K_RK_READ] || is_port2_op[`LSOC1K_RD_READ] || is_port1_op[`LSOC1K_TRIPLE_READ];

// EX1
assign r1_1_w1_fw_ex1 = raddr0_0_valid && (raddr0_0 == ex1_port0_rf_target) && (ex1_port0_rf_target != 5'd0);
assign r1_2_w1_fw_ex1 = raddr0_1_valid && (raddr0_1 == ex1_port0_rf_target) && (ex1_port0_rf_target != 5'd0);
assign r1_1_w2_fw_ex1 =	raddr0_0_valid && (raddr0_0 == ex1_port1_rf_target) && (ex1_port1_rf_target != 5'd0);
assign r1_2_w2_fw_ex1 = raddr0_1_valid && (raddr0_1 == ex1_port1_rf_target) && (ex1_port1_rf_target != 5'd0);

assign r2_1_w1_fw_ex1 =	raddr1_0_valid && (raddr1_0 == ex1_port0_rf_target) && (ex1_port0_rf_target != 5'd0);
assign r2_2_w1_fw_ex1 =	raddr1_1_valid && (raddr1_1 == ex1_port0_rf_target) && (ex1_port0_rf_target != 5'd0);
assign r2_1_w2_fw_ex1 =	raddr1_0_valid && (raddr1_0 == ex1_port1_rf_target) && (ex1_port1_rf_target != 5'd0);
assign r2_2_w2_fw_ex1 =	raddr1_1_valid && (raddr1_1 == ex1_port1_rf_target) && (ex1_port1_rf_target != 5'd0);

assign r3_1_w1_fw_ex1 =	raddr2_0_valid && (raddr2_0 == ex1_port0_rf_target) && (ex1_port0_rf_target != 5'd0);
assign r3_2_w1_fw_ex1 =	raddr2_1_valid && (raddr2_1 == ex1_port0_rf_target) && (ex1_port0_rf_target != 5'd0);
assign r3_1_w2_fw_ex1 =	raddr2_0_valid && (raddr2_0 == ex1_port1_rf_target) && (ex1_port1_rf_target != 5'd0);
assign r3_2_w2_fw_ex1 =	raddr2_1_valid && (raddr2_1 == ex1_port1_rf_target) && (ex1_port1_rf_target != 5'd0);

assign r1_1_fw_ex1 = r1_1_w1_fw_ex1 || r1_1_w2_fw_ex1;	// read port need forwarding
assign r1_2_fw_ex1 = r1_2_w1_fw_ex1 || r1_2_w2_fw_ex1;
assign r2_1_fw_ex1 = r2_1_w1_fw_ex1 || r2_1_w2_fw_ex1;
assign r2_2_fw_ex1 = r2_2_w1_fw_ex1 || r2_2_w2_fw_ex1;
assign r3_1_fw_ex1 = r3_1_w1_fw_ex1 || r3_1_w2_fw_ex1;
assign r3_2_fw_ex1 = r3_2_w1_fw_ex1 || r3_2_w2_fw_ex1;

assign wdata1_ex1 = ({`GRLEN{ex1_port0_src == `EX_ALU0  }} & ex1_alu0_res  ) |
                    ({`GRLEN{ex1_port0_src == `EX_BRU   }} & ex1_bru_res   ) |
                    ({`GRLEN{ex1_port0_src == `EX_NONE0 }} & ex1_none0_res ) ;

assign wdata2_ex1 = ({`GRLEN{ex1_port1_src == `EX_ALU1  }} & ex1_alu1_res  ) |
                    ({`GRLEN{ex1_port1_src == `EX_BRU   }} & ex1_bru_res   ) |
                    ({`GRLEN{ex1_port1_src == `EX_NONE1 }} & ex1_none1_res ) ;

assign r1_1_fw_data_ex1 = r1_1_w2_fw_ex1 ? wdata2_ex1 : wdata1_ex1;	// forwarding data
assign r1_2_fw_data_ex1 = r1_2_w2_fw_ex1 ? wdata2_ex1 : wdata1_ex1;
assign r2_1_fw_data_ex1 = r2_1_w2_fw_ex1 ? wdata2_ex1 : wdata1_ex1;
assign r2_2_fw_data_ex1 = r2_2_w2_fw_ex1 ? wdata2_ex1 : wdata1_ex1;
assign r3_1_fw_data_ex1 = r3_1_w2_fw_ex1 ? wdata2_ex1 : wdata1_ex1;
assign r3_2_fw_data_ex1 = r3_2_w2_fw_ex1 ? wdata2_ex1 : wdata1_ex1;

wire r1_w1_fw = r1_1_w1_fw_ex1 || r1_2_w1_fw_ex1;
wire r2_w1_fw = r2_1_w1_fw_ex1 || r2_2_w1_fw_ex1;
wire r3_w1_fw = r3_1_w1_fw_ex1 || r3_2_w1_fw_ex1;
wire r1_w2_fw = r1_1_w2_fw_ex1 || r1_2_w2_fw_ex1;
wire r2_w2_fw = r2_1_w2_fw_ex1 || r2_2_w2_fw_ex1;
wire r3_w2_fw = r3_1_w2_fw_ex1 || r3_2_w2_fw_ex1;


// type inherit
assign port0_type_upgrade = (r1_w1_fw && ex1_port0_type) || (r1_w2_fw && ex1_port1_type);
assign port1_type_upgrade = (r2_w1_fw && ex1_port0_type) || (r2_w2_fw && ex1_port1_type);
assign port2_type_upgrade = (r3_w1_fw && ex1_port0_type) || (r3_w2_fw && ex1_port1_type);
wire port0_type_crash     = is_port0_valid && ((is_port0_type && ex1_port0_type && r1_w1_fw && ex1_port0_valid) || (is_port0_type && ex1_port1_type && r1_w2_fw && ex1_port1_valid));
wire port1_type_crash     = is_port1_valid && ((is_port1_type && ex1_port0_type && r2_w1_fw && ex1_port0_valid) || (is_port1_type && ex1_port1_type && r2_w2_fw && ex1_port1_valid));
wire port2_type_crash     = (is_port0_valid && port0_triple_read && ((ex1_port0_type && r3_1_w1_fw_ex1 && ex1_port0_valid) || (ex1_port1_type && r3_1_w2_fw_ex1 && ex1_port1_valid))) || 
                            (is_port1_valid && port1_triple_read && ((ex1_port0_type && r3_2_w1_fw_ex1 && ex1_port0_valid) || (ex1_port1_type && r3_2_w2_fw_ex1 && ex1_port1_valid)));
assign type_crash         = port0_type_crash || port1_type_crash || port2_type_crash;

// EX2
assign r1_1_w1_fw_ex2 =	raddr0_0_valid && (raddr0_0 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0) && ex2_port0_valid;
assign r1_2_w1_fw_ex2 = raddr0_1_valid && (raddr0_1 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0) && ex2_port0_valid;
assign r1_1_w2_fw_ex2 =	raddr0_0_valid && (raddr0_0 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0) && ex2_port1_valid;
assign r1_2_w2_fw_ex2 = raddr0_1_valid && (raddr0_1 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0) && ex2_port1_valid;

assign r2_1_w1_fw_ex2 =	raddr1_0_valid && (raddr1_0 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0) && ex2_port0_valid;
assign r2_2_w1_fw_ex2 =	raddr1_1_valid && (raddr1_1 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0) && ex2_port0_valid;
assign r2_1_w2_fw_ex2 =	raddr1_0_valid && (raddr1_0 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0) && ex2_port1_valid;
assign r2_2_w2_fw_ex2 =	raddr1_1_valid && (raddr1_1 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0) && ex2_port1_valid;

assign r3_1_w1_fw_ex2 =	raddr2_0_valid && (raddr2_0 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0) && ex2_port0_valid;
assign r3_2_w1_fw_ex2 =	raddr2_1_valid && (raddr2_1 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0) && ex2_port0_valid;
assign r3_1_w2_fw_ex2 =	raddr2_0_valid && (raddr2_0 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0) && ex2_port1_valid;
assign r3_2_w2_fw_ex2 =	raddr2_1_valid && (raddr2_1 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0) && ex2_port1_valid;

assign r1_1_fw_ex2 = r1_1_w1_fw_ex2 || r1_1_w2_fw_ex2;	// read port need forwarding
assign r1_2_fw_ex2 = r1_2_w1_fw_ex2 || r1_2_w2_fw_ex2;
assign r2_1_fw_ex2 = r2_1_w1_fw_ex2 || r2_1_w2_fw_ex2;
assign r2_2_fw_ex2 = r2_2_w1_fw_ex2 || r2_2_w2_fw_ex2;
assign r3_1_fw_ex2 = r3_1_w1_fw_ex2 || r3_1_w2_fw_ex2;
assign r3_2_fw_ex2 = r3_2_w1_fw_ex2 || r3_2_w2_fw_ex2;

assign wdata1_ex2 = ({`GRLEN{ex2_port0_src == `EX_ALU0   }} & ex2_alu0_res  ) |
                    ({`GRLEN{ex2_port0_src == `EX_BRU    }} & ex2_bru_res   ) |
                    ({`GRLEN{ex2_port0_src == `EX_NONE0  }} & ex2_none0_res ) |
                    ({`GRLEN{ex2_port0_src == `EX_DIV    }} & ex2_div_res   ) |
                    ({`GRLEN{ex2_port0_src == `EX_MUL    }} & ex2_mul_res   ) ;

assign wdata2_ex2 = ({`GRLEN{ex2_port1_src == `EX_ALU1   }} & ex2_alu1_res  ) |
                    ({`GRLEN{ex2_port1_src == `EX_BRU    }} & ex2_bru_res   ) |
                    ({`GRLEN{ex2_port1_src == `EX_NONE1  }} & ex2_none1_res ) |
                    ({`GRLEN{ex2_port1_src == `EX_DIV    }} & ex2_div_res   ) |
                    ({`GRLEN{ex2_port1_src == `EX_MUL    }} & ex2_mul_res   ) ;

assign r1_1_fw_data_ex2 = r1_1_w2_fw_ex2 ? wdata2_ex2 : wdata1_ex2;	// forwarding data
assign r1_2_fw_data_ex2 = r1_2_w2_fw_ex2 ? wdata2_ex2 : wdata1_ex2;
assign r2_1_fw_data_ex2 = r2_1_w2_fw_ex2 ? wdata2_ex2 : wdata1_ex2;
assign r2_2_fw_data_ex2 = r2_2_w2_fw_ex2 ? wdata2_ex2 : wdata1_ex2;
assign r3_1_fw_data_ex2 = r3_1_w2_fw_ex2 ? wdata2_ex2 : wdata1_ex2;
assign r3_2_fw_data_ex2 = r3_2_w2_fw_ex2 ? wdata2_ex2 : wdata1_ex2;

assign rdata0_0_input = ({`GRLEN{ r1_1_fw_ex1               }} & r1_1_fw_data_ex1) |
                        ({`GRLEN{!r1_1_fw_ex1 &  r1_1_fw_ex2}} & r1_1_fw_data_ex2) |
                        ({`GRLEN{!r1_1_fw_ex1 & !r1_1_fw_ex2}} & rdata0_0        ) ;
assign rdata0_1_input = ({`GRLEN{ r1_2_fw_ex1               }} & r1_2_fw_data_ex1) |
                        ({`GRLEN{!r1_2_fw_ex1 &  r1_2_fw_ex2}} & r1_2_fw_data_ex2) |
                        ({`GRLEN{!r1_2_fw_ex1 & !r1_2_fw_ex2}} & rdata0_1        ) ;
assign rdata1_0_input = ({`GRLEN{ r2_1_fw_ex1               }} & r2_1_fw_data_ex1) |
                        ({`GRLEN{!r2_1_fw_ex1 &  r2_1_fw_ex2}} & r2_1_fw_data_ex2) |
                        ({`GRLEN{!r2_1_fw_ex1 & !r2_1_fw_ex2}} & rdata1_0        ) ;
assign rdata1_1_input = ({`GRLEN{ r2_2_fw_ex1               }} & r2_2_fw_data_ex1) |
                        ({`GRLEN{!r2_2_fw_ex1 &  r2_2_fw_ex2}} & r2_2_fw_data_ex2) |
                        ({`GRLEN{!r2_2_fw_ex1 & !r2_2_fw_ex2}} & rdata1_1        ) ;
assign rdata2_0_input = ({`GRLEN{ r3_1_fw_ex1               }} & r3_1_fw_data_ex1) |
                        ({`GRLEN{!r3_1_fw_ex1 &  r3_1_fw_ex2}} & r3_1_fw_data_ex2) |
                        ({`GRLEN{!r3_1_fw_ex1 & !r3_1_fw_ex2}} & rdata2_0        ) ;
assign rdata2_1_input = ({`GRLEN{ r3_2_fw_ex1               }} & r3_2_fw_data_ex1) |
                        ({`GRLEN{!r3_2_fw_ex1 &  r3_2_fw_ex2}} & r3_2_fw_data_ex2) |
                        ({`GRLEN{!r3_2_fw_ex1 & !r3_2_fw_ex2}} & rdata2_1        ) ;

assign rdata0_0_lsu_fw = !r1_1_fw_ex1 && r1_1_fw_ex2 && ((r1_1_w2_fw_ex2 && (ex2_port1_src == `EX_LSU)) || (!r1_1_w2_fw_ex2 && (ex2_port0_src == `EX_LSU)));
assign rdata0_1_lsu_fw = !r1_2_fw_ex1 && r1_2_fw_ex2 && ((r1_2_w2_fw_ex2 && (ex2_port1_src == `EX_LSU)) || (!r1_2_w2_fw_ex2 && (ex2_port0_src == `EX_LSU)));
assign rdata1_0_lsu_fw = !r2_1_fw_ex1 && r2_1_fw_ex2 && ((r2_1_w2_fw_ex2 && (ex2_port1_src == `EX_LSU)) || (!r2_1_w2_fw_ex2 && (ex2_port0_src == `EX_LSU)));
assign rdata1_1_lsu_fw = !r2_2_fw_ex1 && r2_2_fw_ex2 && ((r2_2_w2_fw_ex2 && (ex2_port1_src == `EX_LSU)) || (!r2_2_w2_fw_ex2 && (ex2_port0_src == `EX_LSU)));
assign rdata2_0_lsu_fw = !r3_1_fw_ex1 && r3_1_fw_ex2 && ((r3_1_w2_fw_ex2 && (ex2_port1_src == `EX_LSU)) || (!r3_1_w2_fw_ex2 && (ex2_port0_src == `EX_LSU)));
assign rdata2_1_lsu_fw = !r3_2_fw_ex1 && r3_2_fw_ex2 && ((r3_2_w2_fw_ex2 && (ex2_port1_src == `EX_LSU)) || (!r3_2_w2_fw_ex2 && (ex2_port0_src == `EX_LSU)));

always @(posedge clk) begin
    if (is_allow_in) begin
        ex1_lsu_fw_data     <= ex2_lsu_res;
        ex1_rdata0_0_lsu_fw <= rdata0_0_lsu_fw;
        ex1_rdata0_1_lsu_fw <= rdata0_1_lsu_fw;
        ex1_rdata1_0_lsu_fw <= rdata1_0_lsu_fw;
        ex1_rdata1_1_lsu_fw <= rdata1_1_lsu_fw;
    end
end

// cpucfg
wire [`GRLEN-1:0] cpucfg0  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg1  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg2  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg3  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg4  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg5  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg6  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg7  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg8  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg9  = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg10 = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg11 = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg12 = `GRLEN'b0;
wire [`GRLEN-1:0] cpucfg13 = `GRLEN'b0;

assign      cpucfg_res = {`GRLEN{raddr0_0 == 5'd0 }} & cpucfg0  |
                         {`GRLEN{raddr0_0 == 5'd1 }} & cpucfg1  |
                         {`GRLEN{raddr0_0 == 5'd2 }} & cpucfg2  |
                         {`GRLEN{raddr0_0 == 5'd3 }} & cpucfg3  |
                         {`GRLEN{raddr0_0 == 5'd4 }} & cpucfg4  |
                         {`GRLEN{raddr0_0 == 5'd5 }} & cpucfg5  |
                         {`GRLEN{raddr0_0 == 5'd6 }} & cpucfg6  |
                         {`GRLEN{raddr0_0 == 5'd7 }} & cpucfg7  |
                         {`GRLEN{raddr0_0 == 5'd8 }} & cpucfg8  |
                         {`GRLEN{raddr0_0 == 5'd9 }} & cpucfg9  |
                         {`GRLEN{raddr0_0 == 5'd10}} & cpucfg10 |
                         {`GRLEN{raddr0_0 == 5'd11}} & cpucfg11 |
                         {`GRLEN{raddr0_0 == 5'd12}} & cpucfg12 |
                         {`GRLEN{raddr0_0 == 5'd13}} & cpucfg13 ;

// stall counter
reg [31:0] is_stall_cnt;
reg [31:0] is_stall_typecrash_cnt;
reg [31:0] brop_cnt;
reg [31:0] bru_cnt;
wire stall_happen   = !is_allow_in && ex1_allow_in;
wire stall_typecrash= stall_happen && type_crash;

always @(posedge clk) begin
    if (rst)                  is_stall_cnt <= 32'd0;
    else if (stall_happen)    is_stall_cnt <= is_stall_cnt + 32'd1;

    if (rst)                  is_stall_typecrash_cnt <= 32'd0;
    else if (stall_typecrash) is_stall_typecrash_cnt <= is_stall_typecrash_cnt + 32'd1;

    if (rst)                  brop_cnt <= 32'd0;
    else if ((is_port0_brop && is_port0_valid || is_port1_brop && is_port1_valid || is_port2_brop && is_port2_valid) && !wb_cancel && !bru_cancel && is_allow_in) brop_cnt <= brop_cnt + 32'd1;

    if (rst)                  bru_cnt <= 32'd0;
    else if ((port0_bru_related && is_port0_valid || port1_bru_related && is_port1_valid || port2_bru_related && is_port2_valid) && !wb_cancel && !bru_cancel && is_allow_in) bru_cnt <= bru_cnt + 32'd1;
end


//temp counter
reg [63:0] timer;
always @(posedge clk) begin
    if (rst)      timer <= 64'd0;
    else if (clk) timer <= timer +64'd1;
end

endmodule
