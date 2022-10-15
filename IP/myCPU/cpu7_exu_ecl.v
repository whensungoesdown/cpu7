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
   input  [`GRLEN-1:0]                  irf_ecl_rs1_data_d,
   input  [`GRLEN-1:0]                  irf_ecl_rs2_data_d,
   input  [`GRLEN-1:0]                  alu_ecl_res_e,  // alu result

   output [4:0]                         ecl_irf_rs1_d,
   output [4:0]                         ecl_irf_rs2_d,
   output [`GRLEN-1:0]                  ecl_alu_a_e,
   output [`GRLEN-1:0]                  ecl_alu_b_e,
   output [`LSOC1K_ALU_CODE_BIT-1-1:0]  ecl_alu_op_e,
   output [`GRLEN-1:0]                  ecl_alu_c_e,
   output                               ecl_alu_double_word_e,
   output [`GRLEN-1:0]                  ecl_irf_rd_data_w,
   output                               ecl_irf_wen_w,
   output [4:0]                         ecl_irf_rd_w
   );


   ////register interface
   // common registers
   assign ecl_irf_rs1_d = ifu_exu_op_d[`LSOC1K_RD2RJ  ] ? `GET_RD(ifu_exu_inst_d) : `GET_RJ(ifu_exu_inst_d);
   assign ecl_irf_rs2_d = ifu_exu_op_d[`LSOC1K_RD_READ] ? `GET_RD(ifu_exu_inst_d) : `GET_RK(ifu_exu_inst_d);
   //assign raddr1_0 = is_port1_op[`LSOC1K_RD2RJ  ] ? `GET_RD(is_port1_inst) : `GET_RJ(is_port1_inst);
   //assign raddr1_1 = is_port1_op[`LSOC1K_RD_READ] ? `GET_RD(is_port1_inst) : `GET_RK(is_port1_inst);
   //assign raddr2_0 = port0_triple_read ? `GET_RK(is_port0_inst) : is_port2_op[`LSOC1K_RD2RJ] ? `GET_RD(is_port2_inst) : `GET_RJ(is_port2_inst);
   //assign raddr2_1 = port1_triple_read ? `GET_RK(is_port1_inst) : `GET_RD(is_port2_inst);


   
   
   wire [`LSOC1K_ALU_CODE_BIT-1:0] alu_op = ifu_exu_op_d[`LSOC1K_ALU_CODE];



   // those imm and rs1 rs2 should be handle in cpu7_exu_byp 
   
   ////ALU input
   //A:
   wire alu_a_zero = ifu_exu_op_d[`LSOC1K_LUI];// op_rdpgpr_1 || op_wrpgpr_1; //zero
   wire alu_a_pc = ifu_exu_op_d[`LSOC1K_PC_RELATED];

   //B:
   wire alu_b_imm = ifu_exu_op_d[`LSOC1K_I5] || ifu_exu_op_d[`LSOC1K_I12] || ifu_exu_op_d[`LSOC1K_I16] || ifu_exu_op_d[`LSOC1K_I20];

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
   

   dff_s #(`GRLEN) alu_a_reg (
      .din (alu_a_d),
      .clk (clk),
      .q   (ecl_alu_a_e),
      .se(), .si(), .so());
   
   dff_s #(`GRLEN) alu_b_reg (
      .din (alu_b_d),
      .clk (clk),
      .q   (ecl_alu_b_e),
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


   ////
   //  rd rd_data wen
   //
   wire [4:0] rd_e;
   wire [4:0] rd_m;
   wire [4:0] rd_w;
   
   dff_s #(5) rd_e_reg (
      .din (ifu_exu_rf_target_d),
      .clk (clk),
      .q   (rd_e),
      .se(), .si(), .so());
   
   dff_s #(5) rd_m_reg (
      .din (rd_e),
      .clk (clk),
      .q   (rd_m),
      .se(), .si(), .so());
   
   dff_s #(5) rd_w_reg (
      .din (rd_m),
      .clk (clk),
      .q   (rd_w),
      .se(), .si(), .so());

   assign ecl_irf_rd_w = rd_w;

  
   wire [4:0] wen_d;
   wire [4:0] wen_e;
   wire [4:0] wen_m;
   wire [4:0] wen_w;

   assign wen_d = ifu_exu_rf_wen_d & ifu_exu_valid_d;
   
   dff_s #(1) wen_e_reg (
      .din (wen_d),
      .clk (clk),
      .q   (wen_e),
      .se(), .si(), .so());
   
   dff_s #(1) wen_m_reg (
      .din (wen_e),
      .clk (clk),
      .q   (wen_m),
      .se(), .si(), .so());
   
   dff_s #(1) wen_w_reg (
      .din (wen_m),
      .clk (clk),
      .q   (wen_w),
      .se(), .si(), .so());

   assign ecl_irf_wen_w = wen_w;
   

   
   wire [`GRLEN-1:0] rd_data_m;
   wire [`GRLEN-1:0] rd_data_w;
   
   dff_s #(`GRLEN) rd_data_m_reg (
      .din (alu_ecl_res_e),
      .clk (clk),
      .q   (rd_data_m),
      .se(), .si(), .so());
   
   dff_s #(`GRLEN) rd_data_w_reg (
      .din (rd_data_m),
      .clk (clk),
      .q   (rd_data_w),
      .se(), .si(), .so());

   assign ecl_irf_rd_data_w = rd_data_w;

endmodule // cpu7_exu_ecl
