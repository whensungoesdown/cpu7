`include "common.vh"
`include "decoded.vh"

module cpu7_exu_ecl(
   input                                clk,
   input                                resetn,
   input                                ifu_exu_valid_d,
   input  [31:0]	                ifu_exu_inst_d,
   input  [`GRLEN-1:0]	                ifu_exu_pc_d,
   input  [`LSOC1K_DECODE_RES_BIT-1:0]  ifu_exu_op_d,
   input                                ifu_exu_rf_wen_d,
   input  [4:0]                         ifu_exu_rf_target_d,
   input  [31:0]                        ifu_exu_imm_shifted_d,
   input  [`GRLEN-1:0]                  ifu_exu_c_d,
   input  [`GRLEN-1:0]                  ifu_exu_br_offs,
   input  [`GRLEN-1:0]                  irf_ecl_rs1_data_d,
   input  [`GRLEN-1:0]                  irf_ecl_rs2_data_d,

   output [4:0]                         ecl_irf_rs1_d,
   output [4:0]                         ecl_irf_rs2_d,

   // alu
   output [`GRLEN-1:0]                  ecl_alu_a_e,
   output [`GRLEN-1:0]                  ecl_alu_b_e,
   output [`LSOC1K_ALU_CODE_BIT-1:0]    ecl_alu_op_e,
   output [`GRLEN-1:0]                  ecl_alu_c_e,
   output                               ecl_alu_double_word_e,
   input  [`GRLEN-1:0]                  alu_ecl_res_e,  // alu result

   // lsu
   output                               ecl_lsu_valid_e,
   output [`LSOC1K_LSU_CODE_BIT-1:0]    ecl_lsu_op_e,
   output [`GRLEN-1:0]                  ecl_lsu_base_e,
   output [`GRLEN-1:0]                  ecl_lsu_offset_e,
   output [`GRLEN-1:0]                  ecl_lsu_wdata_e,
   output [4:0]                         ecl_lsu_rd_e,
   output                               ecl_lsu_wen_e,
   input  [`GRLEN-1:0]                  lsu_ecl_rdata_m, // _m inputs are for writting to regfile
   input                                lsu_ecl_finish_m,
   input  [4:0]                         lsu_ecl_rd_m,
   input                                lsu_ecl_wen_m,
   input                                lsu_ecl_addr_ok_e, // not used
   input                                lsu_ecl_ale_e, 

   // bru
   output                               ecl_bru_valid_e,
   output [`LSOC1K_BRU_CODE_BIT-1:0]    ecl_bru_op_e,
   output [`GRLEN-1:0]                  ecl_bru_a_e,
   output [`GRLEN-1:0]                  ecl_bru_b_e,
   output [`GRLEN-1:0]                  ecl_bru_pc_e,
   output [`GRLEN-1:0]                  ecl_bru_offset_e,

   input  [`GRLEN-1:0]                  bru_ecl_brpc_e,
   input                                bru_ecl_br_taken_e,
   input  [`GRLEN-1:0]                  bru_byp_link_pc_e,
   input                                bru_ecl_wen_e,

   // mul
   output                               ecl_mul_valid_e,
   output [`GRLEN-1:0]                  byp_mul_a_e,
   output [`GRLEN-1:0]                  byp_mul_b_e,
   output                               ecl_mul_signed_e,
   output                               ecl_mul_double_e,
   output                               ecl_mul_hi_e,
   output                               ecl_mul_short_e,
   input                                mul_ecl_ready_m, // mul returns result at _m, so this is signal is unused
   input  [`GRLEN-1:0]                  mul_byp_res_m,

   // csr
   input  [`GRLEN-1:0]                  csr_byp_rdata_d,
   output [`LSOC1K_CSR_BIT-1:0]         ecl_csr_raddr_d,
   output [`LSOC1K_CSR_BIT-1:0]         ecl_csr_waddr_m,
   output [`GRLEN-1:0]                  byp_csr_wdata_m,
   output                               ecl_csr_wen_m,

   // exception
   output                               exu_ifu_except,
   output                               ecl_csr_ale_e,
   output                               ecl_csr_illinst_e,
   // ertn
   output                               exu_ifu_ertn_e,
   output                               ecl_csr_ertn_e,
   
   // ifu stall req
   output                               exu_ifu_stall_req,
   
   output [`GRLEN-1:0]                  exu_ifu_brpc_e,
   output                               exu_ifu_br_taken_e,

   output [`GRLEN-1:0]                  ecl_irf_rd_data_w,
   output                               ecl_irf_wen_w,
   output [4:0]                         ecl_irf_rd_w
   );


   wire alu_dispatch_d;
   wire bru_dispatch_d;
   wire lsu_dispatch_d;
   wire mul_dispatch_d;
   wire div_dispatch_d;
   wire none_dispatch_d;
   wire ertn_dispatch_d; //ERET


   wire inst_vld_d;
   wire kill_d;
  
 
   assign kill_d = ecl_bru_valid_e & bru_ecl_br_taken_e; // if branch is taken, kill the instruction at the pipeline _d stage.
   assign inst_vld_d = ifu_exu_valid_d & (~kill_d);


   
   //main
   assign alu_dispatch_d  = !ifu_exu_op_d[`LSOC1K_LSU_RELATED] && !ifu_exu_op_d[`LSOC1K_BRU_RELATED] && !ifu_exu_op_d[`LSOC1K_MUL_RELATED] && !ifu_exu_op_d[`LSOC1K_DIV_RELATED] && !ifu_exu_op_d[`LSOC1K_CSR_RELATED] && inst_vld_d; // && !port0_exception; // alu0 is binded to port0
   assign lsu_dispatch_d  = ifu_exu_op_d[`LSOC1K_LSU_RELATED] && inst_vld_d; // && !port0_exception;
   assign bru_dispatch_d  = ifu_exu_op_d[`LSOC1K_BRU_RELATED] && inst_vld_d; // && !port0_exception;
   assign mul_dispatch_d  = ifu_exu_op_d[`LSOC1K_MUL_RELATED] && inst_vld_d; // && !port0_exception;
   assign div_dispatch_d  = ifu_exu_op_d[`LSOC1K_DIV_RELATED] && inst_vld_d; // && !port0_exception;
   assign none_dispatch_d = (ifu_exu_op_d[`LSOC1K_CSR_RELATED] || ifu_exu_op_d[`LSOC1K_TLB_RELATED] || ifu_exu_op_d[`LSOC1K_CACHE_RELATED]) && inst_vld_d; // || port0_exception ;
   assign ertn_dispatch_d = ifu_exu_op_d[`LSOC1K_ERET] && inst_vld_d;


   ////register interface
   // common registers
   assign ecl_irf_rs1_d = ifu_exu_op_d[`LSOC1K_RD2RJ  ] ? `GET_RD(ifu_exu_inst_d) : `GET_RJ(ifu_exu_inst_d);
   assign ecl_irf_rs2_d = ifu_exu_op_d[`LSOC1K_RD_READ] ? `GET_RD(ifu_exu_inst_d) : `GET_RK(ifu_exu_inst_d);
   //assign raddr1_0 = is_port1_op[`LSOC1K_RD2RJ  ] ? `GET_RD(is_port1_inst) : `GET_RJ(is_port1_inst);
   //assign raddr1_1 = is_port1_op[`LSOC1K_RD_READ] ? `GET_RD(is_port1_inst) : `GET_RK(is_port1_inst);
   //assign raddr2_0 = port0_triple_read ? `GET_RK(is_port0_inst) : is_port2_op[`LSOC1K_RD2RJ] ? `GET_RD(is_port2_inst) : `GET_RJ(is_port2_inst);
   //assign raddr2_1 = port1_triple_read ? `GET_RK(is_port1_inst) : `GET_RD(is_port2_inst);


   wire illinst_d;
   wire illinst_e;

   // illegal instruction exception
   assign illinst_d = ifu_exu_op_d[`LSOC1K_INE] && inst_vld_d;
   
   dff_s #(1) illinst_d2e_reg (
      .din (illinst_d),
      .clk (clk),
      .q   (illinst_e),
      .se(), .si(), .so());

   assign ecl_csr_illinst_e = illinst_e;



   
   /////////////////////////
   // ALU parameters
   /////////////////////////
   
   
   wire [`LSOC1K_ALU_CODE_BIT-1:0] alu_op = ifu_exu_op_d[`LSOC1K_ALU_CODE];



   // those imm and rs1 rs2 should be handle in cpu7_exu_byp 
   
   ////ALU input
   //A:
   wire alu_a_zero = ifu_exu_op_d[`LSOC1K_LUI];// op_rdpgpr_1 || op_wrpgpr_1; //zero
   wire alu_a_pc = ifu_exu_op_d[`LSOC1K_PC_RELATED];

   //B:
   //wire alu_b_imm = ifu_exu_op_d[`LSOC1K_I5] || ifu_exu_op_d[`LSOC1K_I12] || ifu_exu_op_d[`LSOC1K_I16] || ifu_exu_op_d[`LSOC1K_I20];
   wire alu_b_imm = (ifu_exu_op_d[`LSOC1K_I5] || ifu_exu_op_d[`LSOC1K_I12] || ifu_exu_op_d[`LSOC1K_I16] || ifu_exu_op_d[`LSOC1K_I20]) & alu_dispatch_d;

   //wire ecl_alu_b_get_a = ifu_exu_op_d[`LSOC1K_ALU_CODE] == `LSOC1K_ALU_EXT;



   //assign alu_a = alu_a_pc? ifu_exu_pc_d : rdata0_0_input;
   wire [`GRLEN-1:0] alu_a_d = alu_a_pc? ifu_exu_pc_d : irf_ecl_rs1_data_d;

   //wire port0_a_lsu_fw;
   //assign port0_a_lsu_fw = !alu0_a_pc && rdata0_0_lsu_fw;

   //assign alu_b = alu_b_imm? ifu_exu_imm_shifted_d : rdata0_1_input;
   wire [`GRLEN-1:0] alu_b_d = alu_b_imm? ifu_exu_imm_shifted_d : irf_ecl_rs2_data_d;

   //wire port0_b_lsu_fw;
   //assign port0_b_lsu_fw = !alu0_b_imm && rdata0_1_lsu_fw; 


   wire alu_double_word_d = ifu_exu_op_d[`LSOC1K_DOUBLE_WORD];
   
   wire [`GRLEN-1:0] alu_a_e;
   wire [`GRLEN-1:0] alu_b_e;

   dff_s #(`GRLEN) alu_a_reg (
      .din (alu_a_d),
      .clk (clk),
      .q   (alu_a_e),
      .se(), .si(), .so());
   
   dff_s #(`GRLEN) alu_b_reg (
      .din (alu_b_d),
      .clk (clk),
      .q   (alu_b_e),
      .se(), .si(), .so());
   
   dff_s #(`LSOC1K_ALU_CODE_BIT) alu_op_reg (
      .din (alu_op),
      .clk (clk),
      .q   (ecl_alu_op_e),
      .se(), .si(), .so());

   dff_s #(`GRLEN) alu_c_reg (
      .din (ifu_exu_c_d),
      .clk (clk),
      .q   (ecl_alu_c_e),
      .se(), .si(), .so());
   
   dff_s #(1) alu_double_word_reg (
      .din (alu_double_word_d),
      .clk (clk),
      .q   (ecl_alu_double_word_e),
      .se(), .si(), .so());



   //////////////////
   //  bypass logic
   //////////////////

   wire [4:0] rs1_e;
   wire [4:0] rs2_e;

   wire [`GRLEN-1:0] byp_rs1_data_e;
   wire [`GRLEN-1:0] byp_rs2_data_e;

   wire  alu_b_imm_e;

   wire  ecl_byp_rs1_mux_sel_rf;
   wire  ecl_byp_rs1_mux_sel_m;   
   wire  ecl_byp_rs1_mux_sel_w;
   
   wire  ecl_byp_rs2_mux_sel_rf;
   wire  ecl_byp_rs2_mux_sel_m;   
   wire  ecl_byp_rs2_mux_sel_w;

   wire use_other_e;
   
   
   dff_s #(5) rs1_d2e_reg (
      .din (ecl_irf_rs1_d),
      .clk (clk),
      .q   (rs1_e),
      .se(), .si(), .so());
   
   dff_s #(5) rs2_d2e_reg (
      .din (ecl_irf_rs2_d),
      .clk (clk),
      .q   (rs2_e),
      .se(), .si(), .so());
   
   dff_s #(1) alu_b_imm_d2e_reg (
      .din (alu_b_imm),
      .clk (clk),
      .q   (alu_b_imm_e),
      .se(), .si(), .so());
   
   cpu7_exu_eclbyplog_rs1 byplog_rs1(
      .rs_e           (rs1_e[4:0]             ),
      .rd_m           (rd_m[4:0]              ),
      .rd_w           (rd_w[4:0]              ),
      .wen_m          (wen_m                  ),
      .wen_w          (wen_w                  ),

      .rs_mux_sel_rf  (ecl_byp_rs1_mux_sel_rf ),
      .rs_mux_sel_m   (ecl_byp_rs1_mux_sel_m  ),
      .rs_mux_sel_w   (ecl_byp_rs1_mux_sel_w  )
      );

   assign use_other_e = alu_b_imm_e | double_read_e;

   cpu7_exu_eclbyplog byplog_rs2(
      .rs_e           (rs2_e[4:0]             ),
      .rd_m           (rd_m[4:0]              ),
      .rd_w           (rd_w[4:0]              ),
      .wen_m          (wen_m                  ),
      .wen_w          (wen_w                  ),
      .use_other      (use_other_e            ),

      .rs_mux_sel_rf  (ecl_byp_rs2_mux_sel_rf ),
      .rs_mux_sel_m   (ecl_byp_rs2_mux_sel_m  ),
      .rs_mux_sel_w   (ecl_byp_rs2_mux_sel_w  )
      );
   
   mux3ds #(`GRLEN) mux_rs1_data (.dout(byp_rs1_data_e),
      .in0(alu_a_e),
      .in1(rd_data_m),
      .in2(ecl_irf_rd_data_w),
      .sel0(ecl_byp_rs1_mux_sel_rf),
      .sel1(ecl_byp_rs1_mux_sel_m),
      .sel2(ecl_byp_rs1_mux_sel_w)
      );

   assign ecl_alu_a_e = byp_rs1_data_e;

   mux3ds #(`GRLEN) mux_rs2_data (.dout(byp_rs2_data_e),
      .in0(alu_b_e),
      .in1(rd_data_m),
      .in2(ecl_irf_rd_data_w),
      .sel0(ecl_byp_rs2_mux_sel_rf),
      .sel1(ecl_byp_rs2_mux_sel_m),
      .sel2(ecl_byp_rs2_mux_sel_w)
      );

   assign ecl_alu_b_e = byp_rs2_data_e;


   
   
   ////////////////
   // LSU
   ///////////////

   wire lsu_valid_d;
   wire lsu_valid_e;
   
   assign lsu_valid_d = lsu_dispatch_d; // & ifu_exu_valid_d; 
   
   dff_s #(1) lsu_valid_reg (
      .din (lsu_valid_d),
      .clk (clk),
      .q   (lsu_valid_e),
      .se(), .si(), .so());
   
   assign ecl_lsu_valid_e = lsu_valid_e; 


   wire [`LSOC1K_LSU_CODE_BIT-1:0] lsu_op_d;
   wire [`LSOC1K_LSU_CODE_BIT-1:0] lsu_op_e;

   assign lsu_op_d = ifu_exu_op_d[`LSOC1K_OP_CODE];
   
   dff_s #(`LSOC1K_LSU_CODE_BIT) lsu_op_reg (
      .din (lsu_op_d),
      .clk (clk),
      .q   (lsu_op_e),
      .se(), .si(), .so());

   assign ecl_lsu_op_e = lsu_op_e;


   assign ecl_lsu_base_e = byp_rs1_data_e;
   

   wire                       double_read_d;
   wire                       double_read_e;
   wire [`GRLEN-1:0]          ifu_exu_imm_shifted_e;
   wire [`GRLEN-1:0]          lsu_offset_e;
 
   assign double_read_d = ifu_exu_op_d[`LSOC1K_DOUBLE_READ] & lsu_dispatch_d;
   
   dff_s #(1) double_read_d2e_reg (
      .din (double_read_d),
      .clk (clk),
      .q   (double_read_e),
      .se(), .si(), .so());

   dff_s #(`GRLEN) imm_shifted_d2e_reg (
      .din (ifu_exu_imm_shifted_d),
      .clk (clk),
      .q   (ifu_exu_imm_shifted_e),
      .se(), .si(), .so());

   assign lsu_offset_e = double_read_e ? byp_rs2_data_e : ifu_exu_imm_shifted_e; 
   assign ecl_lsu_offset_e = lsu_offset_e;


   assign ecl_lsu_wdata_e = byp_rs2_data_e;

   
   
   wire [4:0]               lsu_rd_d;
   wire [4:0]               lsu_rd_e;
   
   assign lsu_rd_d = ifu_exu_rf_target_d;
   
   dff_s #(5) lsu_rd_d2e_reg (
      .din (lsu_rd_d),
      .clk (clk),
      .q   (lsu_rd_e),
      .se(), .si(), .so());

   assign ecl_lsu_rd_e = lsu_rd_e;



   wire lsu_wen_d;
   wire lsu_wen_e;
   
   assign lsu_wen_d = ifu_exu_rf_wen_d;
   
   dff_s #(1) lsu_wen_d2e_reg (
      .din (lsu_wen_d),
      .clk (clk),
      .q   (lsu_wen_e),
      .se(), .si(), .so());

   assign ecl_lsu_wen_e = lsu_wen_e;

   

   //////////////////////
   // BRU
   //////////////////////

   wire bru_valid_d;
   wire bru_valid_e;

   assign bru_valid_d = bru_dispatch_d; // & ifu_exu_valid_d;

   dff_s #(1) bru_valid_d2e_reg (
      .din (bru_valid_d),
      .clk (clk),
      .q   (bru_valid_e),
      .se(), .si(), .so());

   assign ecl_bru_valid_e = bru_valid_e;



   wire [`LSOC1K_BRU_CODE_BIT-1:0] bru_op_d;
   wire [`LSOC1K_BRU_CODE_BIT-1:0] bru_op_e;

   assign bru_op_d = ifu_exu_op_d[`LSOC1K_BRU_CODE];
   
   dff_s #(`LSOC1K_BRU_CODE_BIT) bru_op_d2e_reg (
      .din (bru_op_d),
      .clk (clk),
      .q   (bru_op_e),
      .se(), .si(), .so());

   assign ecl_bru_op_e = bru_op_e;

   
   assign ecl_bru_a_e = byp_rs1_data_e;
   assign ecl_bru_b_e = byp_rs2_data_e;

   
   wire [`GRLEN-1:0] bru_pc_d;
   wire [`GRLEN-1:0] bru_pc_e;

   assign bru_pc_d = ifu_exu_pc_d;
   
   dff_s #(`GRLEN) bru_pc_d2e_reg (
      .din (bru_pc_d),
      .clk (clk),
      .q   (bru_pc_e),
      .se(), .si(), .so());

   assign ecl_bru_pc_e = bru_pc_e;

   

   wire [`GRLEN-1:0] bru_offset_d;
   wire [`GRLEN-1:0] bru_offset_e;

   assign bru_offset_d = ifu_exu_br_offs;

   dff_s #(`GRLEN) bru_offset_d2e_reg (
      .din (bru_offset_d),
      .clk (clk),
      .q   (bru_offset_e),
      .se(), .si(), .so());
 
   assign ecl_bru_offset_e = bru_offset_e;
  

   assign exu_ifu_brpc_e = bru_ecl_brpc_e;
   assign exu_ifu_br_taken_e = ecl_bru_valid_e & bru_ecl_br_taken_e;
   

   
   wire [`GRLEN-1:0] bru_link_pc_e;
   wire [`GRLEN-1:0] bru_link_pc_m;

   assign bru_link_pc_e = bru_byp_link_pc_e;
   
   dff_s #(`GRLEN) bru_link_pc_e2m_reg (
      .din (bru_link_pc_e),
      .clk (clk),
      .q   (bru_link_pc_m),
      .se(), .si(), .so());


   wire bru_wen_e;
   wire bru_wen_m;

   assign bru_wen_e = bru_ecl_wen_e;
   
   dff_s #(1) bru_wen_e2m_reg (
      .din (bru_wen_e),
      .clk (clk),
      .q   (bru_wen_m),
      .se(), .si(), .so());
   
   


   

   /////////////////////////
   // MUL
   ////////////////////////

   wire mul_wen_d;
   wire mul_wen_e;
   wire mul_wen_m;

   assign mul_wen_d = ifu_exu_rf_wen_d & mul_dispatch_d;
   
   dff_s #(1) mul_wen_d2e_reg (
      .din (mul_wen_d),
      .clk (clk),
      .q   (mul_wen_e),
      .se(), .si(), .so());
   
   dff_s #(1) mul_wen_e2m_reg (
      .din (mul_wen_e),
      .clk (clk),
      .q   (mul_wen_m),
      .se(), .si(), .so());
   

   assign byp_mul_a_e = byp_rs1_data_e;
   assign byp_mul_b_e = byp_rs2_data_e;
   
   wire mul_valid_d;
   wire mul_valid_e;
   wire mul_valid_m;

   assign mul_valid_d = mul_dispatch_d;
   
   dff_s #(1) mul_valid_d2e_reg (
      .din (mul_valid_d),
      .clk (clk),
      .q   (mul_valid_e),
      .se(), .si(), .so());
   
   assign ecl_mul_valid_e = mul_valid_e;
   
   dff_s #(1) mul_valid_e2m_reg (
      .din (mul_valid_e),
      .clk (clk),
      .q   (mul_valid_m),
      .se(), .si(), .so());
   

   wire [`LSOC1K_MDU_CODE_BIT-1:0] mul_op_d;
   assign mul_op_d = ifu_exu_op_d[`LSOC1K_MDU_CODE];

   wire mul_signed_d;
   wire mul_signed_e;

   wire mul_double_d;
   wire mul_double_e;

   wire mul_hi_d;
   wire mul_hi_e;

   wire mul_short_d;
   wire mul_short_e;
   

   assign mul_signed_d = mul_op_d == `LSOC1K_MDU_MUL_W     ||
			 mul_op_d == `LSOC1K_MDU_MULH_W    ||
			 mul_op_d == `LSOC1K_MDU_MUL_D     ||
			 mul_op_d == `LSOC1K_MDU_MULH_D    ||
			 mul_op_d == `LSOC1K_MDU_MULW_D_W  ;
   assign mul_double_d = mul_op_d == `LSOC1K_MDU_MUL_D     ||
			 mul_op_d == `LSOC1K_MDU_MULH_D    ||
			 mul_op_d == `LSOC1K_MDU_MULH_DU   ;
   assign mul_hi_d     = mul_op_d == `LSOC1K_MDU_MULH_W    ||
			 mul_op_d == `LSOC1K_MDU_MULH_WU   ||
			 mul_op_d == `LSOC1K_MDU_MULH_D    ||
			 mul_op_d == `LSOC1K_MDU_MULH_DU   ;
   assign mul_short_d  = mul_op_d == `LSOC1K_MDU_MUL_W     ||
			 mul_op_d == `LSOC1K_MDU_MULH_W    ||
			 mul_op_d == `LSOC1K_MDU_MULH_WU   ;


   dff_s #(1) mul_signed_d2e_reg (
      .din (mul_signed_d),
      .clk (clk),
      .q   (mul_signed_e),
      .se(), .si(), .so());

   assign ecl_mul_signed_e = mul_signed_e;


   dff_s #(1) mul_double_d2e_reg (
      .din (mul_double_d),
      .clk (clk),
      .q   (mul_double_e),
      .se(), .si(), .so());

   assign ecl_mul_double_e = mul_double_e;
   
   
   dff_s #(1) mul_hi_d2e_reg (
      .din (mul_hi_d),
      .clk (clk),
      .q   (mul_hi_e),
      .se(), .si(), .so());

   assign ecl_mul_hi_e = mul_hi_e;


   dff_s #(1) mul_short_d2e_reg (
      .din (mul_short_d),
      .clk (clk),
      .q   (mul_short_e),
      .se(), .si(), .so());

   assign ecl_mul_short_e = mul_short_e;



   
   ///////////////////////
   // CSR
   ///////////////////////

   //
   // csrrd
   
   wire csr_valid_d;
   wire csr_valid_e;
   wire csr_valid_m;

   assign csr_valid_d = none_dispatch_d;

   dff_s #(1) csr_valid_d2e_reg (
      .din (csr_valid_d),
      .clk (clk),
      .q   (csr_valid_e),
      .se(), .si(), .so());
   
   dff_s #(1) csr_valid_e2m_reg (
      .din (csr_valid_e),
      .clk (clk),
      .q   (csr_valid_m),
      .se(), .si(), .so());


   
   
   wire [`GRLEN-1:0]             csr_rdata_d;
   wire [`GRLEN-1:0]             csr_rdata_e;
   wire [`GRLEN-1:0]             csr_rdata_m;
   
   assign ecl_csr_raddr_d = `GET_CSR(ifu_exu_inst_d);

//   //
//   // byp logic based on csr addr
//
//   wire ecl_byp_muxcsr_sel_csrrf;
//   wire ecl_byp_muxcsr_sel_e;
//   wire ecl_byp_muxcsr_sel_m;
//
//   cpu7_csr_byplog csrbyplog(
//      .csr_raddr_d       (ecl_csr_raddr_d          ),
//      .csr_waddr_e       (csr_waddr_e              ),
//      .csr_waddr_m       (csr_waddr_m              ),
//      .csr_wen_e         (csr_wen_e                ),
//      .csr_wen_m         (csr_wen_m                ),
//      
//      .csr_mux_sel_csrrf (ecl_byp_muxcsr_sel_csrrf ),
//      .csr_mux_sel_e     (ecl_byp_muxcsr_sel_e     ),
//      .csr_mux_sel_m     (ecl_byp_muxcsr_sel_m     )
//      );
//
//   mux3ds #(`GRLEN) mux_csr_rdata(.dout(csr_rdata_d),
//      .in0(csr_byp_rdata_d),
//      .in1(csr_wdata_e),
//      .in2(csr_wdata_m),
//      .sel0(ecl_byp_muxcsr_sel_csrrf),
//      .sel1(ecl_byp_muxcsr_sel_e),
//      .sel2(ecl_byp_muxcsr_sel_m)
//      );
   
   assign csr_rdata_d = csr_byp_rdata_d;


   
   dff_s #(`GRLEN) csr_rdata_d2e_reg (
      .din (csr_rdata_d),
      .clk (clk),
      .q   (csr_rdata_e),
      .se(), .si(), .so());
   
   
   dff_s #(`GRLEN) csr_rdata_e2m_reg (
      .din (csr_rdata_e),
      .clk (clk),
      .q   (csr_rdata_m),
      .se(), .si(), .so());

   

   

   // CSR's rd follows ALU rd's datapath

   // CSR rd wen
   wire csr_rdwen_d;
   wire csr_rdwen_e;
   wire csr_rdwen_m;

   assign csr_rdwen_d = ifu_exu_rf_wen_d & none_dispatch_d;

   dff_s #(1) csr_rdwen_d2e_reg (
      .din (csr_rdwen_d),
      .clk (clk),
      .q   (csr_rdwen_e),
      .se(), .si(), .so());

   dff_s #(1) csr_rdwen_e2m_reg (
      .din (csr_rdwen_e),
      .clk (clk),
      .q   (csr_rdwen_m),
      .se(), .si(), .so());
   

   //
   // csrwr csrxchg
   
//   wire [`LSOC1K_CSR_OP_BIT-1:0] csr_op_d;
//
//   assign csr_op_d = ifu_exu_op_d[`LSOC1K_CSR_XCHG ] ? `LSOC1K_CSR_CSRXCHG :
//		     ifu_exu_op_d[`LSOC1K_CSR_WRITE] ? `LSOC1K_CSR_CSRWR   :
//		     ifu_exu_op_d[`LSOC1K_CSR_READ ] ? `LSOC1K_CSR_CSRRD   :
//		     `LSOC1K_CSR_IDLE    ;
   
   wire csr_xchg_d;
   wire csr_xchg_e;
   
   wire [`GRLEN-1:0] csr_mask_e;
   
   assign csr_xchg_d = ifu_exu_op_d[`LSOC1K_CSR_XCHG];
   
   dff_s #(1) csr_xchg_d2e_reg (
      .din (csr_xchg_d),
      .clk (clk),
      .q   (csr_xchg_e),
      .se(), .si(), .so());
   
   assign csr_mask_e = byp_rs1_data_e;


   wire [`GRLEN-1:0] csr_wdata_e;
   wire [`GRLEN-1:0] csr_wdata_m;
   
   //assign csr_wdata_e = byp_rs2_data_e;
   assign csr_wdata_e = csr_xchg_e ? (csr_mask_e & byp_rs2_data_e) : byp_rs2_data_e;
   
   dff_s #(`GRLEN) csr_wdata_e2m_reg (
      .din (csr_wdata_e),
      .clk (clk),
      .q   (csr_wdata_m),
      .se(), .si(), .so());

   assign byp_csr_wdata_m = csr_wdata_m;
   

   // csr wen
   wire csr_wen_d;
   wire csr_wen_e;
   wire csr_wen_m;

   assign csr_wen_d = (ifu_exu_op_d[`LSOC1K_CSR_XCHG] | ifu_exu_op_d[`LSOC1K_CSR_WRITE]) & csr_valid_d;
   
   dff_s #(1) csr_wen_d2e_reg (
      .din (csr_wen_d),
      .clk (clk),
      .q   (csr_wen_e),
      .se(), .si(), .so());

   dff_s #(1) csr_wen_e2m_reg (
      .din (csr_wen_e),
      .clk (clk),
      .q   (csr_wen_m),
      .se(), .si(), .so());

   assign ecl_csr_wen_m = csr_wen_m;
   
   
   // waddr is the same as raddr
   wire [`LSOC1K_CSR_BIT-1:0]    csr_waddr_d;
   wire [`LSOC1K_CSR_BIT-1:0]    csr_waddr_e;
   wire [`LSOC1K_CSR_BIT-1:0]    csr_waddr_m;
   
   assign csr_waddr_d = `GET_CSR(ifu_exu_inst_d);

   dff_s #(`LSOC1K_CSR_BIT) csr_waddr_d2e_reg (
      .din (csr_waddr_d),
      .clk (clk),
      .q   (csr_waddr_e),
      .se(), .si(), .so());
   
   dff_s #(`LSOC1K_CSR_BIT) csr_waddr_e2m_reg (
      .din (csr_waddr_e),
      .clk (clk),
      .q   (csr_waddr_m),
      .se(), .si(), .so());

   assign ecl_csr_waddr_m = csr_waddr_m;
   
   


   //
   // csr stall req
   
   wire csr_stall_req;
   wire csr_stall_req_next;

   assign csr_stall_req_next = (csr_wen_d) | (csr_stall_req & ~csr_wen_m);
   
   dffr_s #(1) csr_stall_req_reg (
      .din (csr_stall_req_next),
      .clk (clk),
      .q   (csr_stall_req),
      .se(), .si(), .so(), .rst (~resetn));

   


   
   
   ///////////////////////
   // ALU
   ///////////////////////

   ////
   //  rf_target rd_data rf_wen
   //  only for ALU instructions
   //
   wire [4:0] rf_target_e;
   wire [4:0] rf_target_m;
   
   dff_s #(5) rd_d2e_reg (
      .din (ifu_exu_rf_target_d),
      .clk (clk),
      .q   (rf_target_e),
      .se(), .si(), .so());
   
   dff_s #(5) rd_e2m_reg (
      .din (rf_target_e),
      .clk (clk),
      .q   (rf_target_m),
      .se(), .si(), .so());

  
   //
   // rf_wen, only for ALU instructions
   
   wire alu_wen_d;
   wire alu_wen_e;
   wire alu_wen_m;
   
   assign alu_wen_d = ifu_exu_rf_wen_d & alu_dispatch_d;
   
   dff_s #(1) alu_wen_d2e_reg (
      .din (alu_wen_d),
      .clk (clk),
      .q   (alu_wen_e),
      .se(), .si(), .so());
   
   dff_s #(1) alu_wen_e2m_reg (
      .din (alu_wen_e),
      .clk (clk),
      .q   (alu_wen_m),
      .se(), .si(), .so());

   //
   // alu_res_m, only for ALU instructions

   wire [`GRLEN-1:0] alu_res_m;

   dff_s #(`GRLEN) rd_data_e2m_reg (
      .din (alu_ecl_res_e),
      .clk (clk),
      .q   (alu_res_m),
      .se(), .si(), .so());




   

   ////////////////////////////////////
   // rd wen rd_data MUX
   ////////////////////////////////////
   
   //
   //  rd mux
   //
   // Instructions other than ALU have longer pipeline.
   // they should maintain their own rd and mux them here at _m
   // ALU instructions take exactly 5 cyclc.
   //
   // BRU and MUL share ALU's rd because they exactly follow the 5 stage pipeline.
   // LSU takes uncertain cycles. It keeps record of its own rd.
   //

   wire [4:0] rd_m;
   wire [4:0] rd_w;
   
   dp_mux2es #(5) rd_mux(
      .dout (rd_m),
      .in0  (rf_target_m),
      .in1  (lsu_ecl_rd_m),
      .sel  (lsu_ecl_finish_m));
   
   dff_s #(5) rd_m2w_reg (
      .din (rd_m),
      .clk (clk),
      .q   (rd_w),
      .se(), .si(), .so());

   assign ecl_irf_rd_w = rd_w;

  
   //
   // wen mux
   //
   
   wire wen_m;
   wire wen_w;
   
//   dp_mux2es #(1) wen_mux(
//      .dout (wen_m),
//      .in0  (alu_wen_m),
//      .in1  (lsu_ecl_wen_m),
//      .sel  (lsu_ecl_finish_m));
   
   // set the wen if any module claims it
   assign wen_m = alu_wen_m | (lsu_ecl_wen_m & lsu_ecl_finish_m) | bru_wen_m | mul_wen_m | csr_rdwen_m;
   
   dff_s #(1) wen_m2w_reg (
      .din (wen_m),
      .clk (clk),
      .q   (wen_w),
      .se(), .si(), .so());

   assign ecl_irf_wen_w = wen_w;
   

   //
   // rd_data mux
   //
   
   wire [`GRLEN-1:0] rd_data_m;
   wire [`GRLEN-1:0] rd_data_w;
   

   wire rddata_sel_alu_res_m_l;
   wire rddata_sel_lsu_res_m_l;
   wire rddata_sel_bru_res_m_l;
   wire rddata_sel_mul_res_m_l;
   wire rddata_sel_csr_res_m_l;

   // uty: todo
   // alu better has a valid signal
   assign rddata_sel_alu_res_m_l = (lsu_ecl_finish_m | bru_wen_m | mul_valid_m | csr_valid_m); // default is alu resulst if no other module claims it
   assign rddata_sel_lsu_res_m_l = ~lsu_ecl_finish_m;
   assign rddata_sel_bru_res_m_l = ~bru_wen_m;   // bru's rd go with ALU's
   assign rddata_sel_mul_res_m_l = ~mul_valid_m; // mul's rd go with ALU's
   assign rddata_sel_csr_res_m_l = ~csr_valid_m; // csr's rd go with ALU's

   // maybe too much fan out? make it 4ds+3ds when adding div 
   dp_mux5ds #(`GRLEN) rd_data_mux(.dout  (rd_data_m),
                          .in0   (alu_res_m),
                          .in1   (lsu_ecl_rdata_m),
                          .in2   (bru_link_pc_m),
                          .in3   (mul_byp_res_m),
                          .in4   (csr_rdata_m),
                          .sel0_l (rddata_sel_alu_res_m_l),
                          .sel1_l (rddata_sel_lsu_res_m_l),
                          .sel2_l (rddata_sel_bru_res_m_l),
                          .sel3_l (rddata_sel_mul_res_m_l),
                          .sel4_l (rddata_sel_csr_res_m_l));
   
   
   dff_s #(`GRLEN) rd_data_w_reg (
      .din (rd_data_m),
      .clk (clk),
      .q   (rd_data_w),
      .se(), .si(), .so());

   assign ecl_irf_rd_data_w = rd_data_w;


   /////////////////////
   // stall IFU logic
   ////////////////////

   //
   // BRU also stalls IFU for one cycle, but it does not signal exu_ifu_stall_req,
   // becasue it involves pc_ logic, and changes control flow.
   // 

   
   //
   // lsu stall request
   //
   
   wire lsu_stall_req;
   wire lsu_stall_req_next;

   //
   // lsu_dispatch_d is the staring signal
   // lsu_ecl_finish_m ends it
   //
   assign lsu_stall_req_next =  (lsu_dispatch_d) | (lsu_stall_req & ~lsu_ecl_finish_m); 
   
   dffr_s #(1) lsu_stall_req_reg (
      .din (lsu_stall_req_next),
      .clk (clk),
      .q   (lsu_stall_req),
      .se(), .si(), .so(), .rst (~resetn));




   
   //
   // excetpion
   //

   assign exu_ifu_except = lsu_ecl_ale_e | ecl_csr_illinst_e;
   assign ecl_csr_ale_e = lsu_ecl_ale_e;
   

   //
   // exu_ifu_stall_req
   //
   assign exu_ifu_stall_req = lsu_stall_req_next | csr_stall_req_next;
   


   //
   // ernt (eret) 
   //

   wire ertn_valid_d;
   wire ertn_valid_e;

   assign ertn_valid_d = ertn_dispatch_d;
   
   dff_s #(1) ertn_valid_d2e_reg (
      .din (ertn_valid_d),
      .clk (clk),
      .q   (ertn_valid_e),
      .se(), .si(), .so());
   
   assign exu_ifu_ertn_e = ertn_valid_e;
   assign ecl_csr_ertn_e = ertn_valid_e;
   
endmodule // cpu7_exu_ecl
