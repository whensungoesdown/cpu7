`include "common.vh"

module cpu7_exu(

   input                                clk,
   input                                resetn,

   input                                ifu_exu_valid_d,
   input  [`GRLEN-1:0]                  ifu_exu_pc_d,
   input  [31:0]	                ifu_exu_inst_d,
   input  [`LSOC1K_DECODE_RES_BIT-1:0]  ifu_exu_op_d,
   input  [`GRLEN-3:0]                  ifu_exu_br_target_d,
   input                                ifu_exu_br_taken_d,
   input                                ifu_exu_exception_d,
   input  [5:0]                         ifu_exu_exccode_d,
   input                                ifu_exu_rf_wen_d,
   input  [4:0]                         ifu_exu_rf_target_d,
   input  [`LSOC1K_PRU_HINT:0]          ifu_exu_hint_d,

   input  [31:0]                        ifu_exu_imm_shifted_d,
   input  [`GRLEN-1:0]                  ifu_exu_c_d,

   input  [`GRLEN-1:0]                  ifu_exu_pc_w,

   
   //debug interface
   output [`GRLEN-1:0]                  debug0_wb_pc,
   output                               debug0_wb_rf_wen,
   output [ 4:0]                        debug0_wb_rf_wnum,
   output [`GRLEN-1:0]                  debug0_wb_rf_wdata,

   output [`GRLEN-1:0]                  debug1_wb_pc,
   output                               debug1_wb_rf_wen,
   output [ 4:0]                        debug1_wb_rf_wnum,
   output [`GRLEN-1:0]                  debug1_wb_rf_wdata
   );


   wire [4:0]                           ecl_irf_rs1_d;
   wire [4:0]                           ecl_irf_rs2_d;
   wire [`GRLEN-1:0]                    irf_ecl_rs1_data_d;
   wire [`GRLEN-1:0]                    irf_ecl_rs2_data_d;
   
   
   wire [`GRLEN-1:0]                    ecl_alu_a_e;
   wire [`GRLEN-1:0]                    ecl_alu_b_e;
   wire [`GRLEN-1:0]                    ecl_alu_c_e;
   wire [`LSOC1K_ALU_CODE_BIT-1:0]      ecl_alu_op_e;
   wire                                 ecl_alu_double_word_e;
   wire [`GRLEN-1:0]                    alu_ecl_res_e;

   wire [`GRLEN-1:0]                    ecl_irf_rd_data_w;
   wire [4:0]                           ecl_irf_rd_w; // derived from ifu_exu_rf_target_d
   wire                                 ecl_irf_wen_w;



   wire [`GRLEN-1:0] dumb_rdata1_0;
   wire [`GRLEN-1:0] dumb_rdata1_1;
   wire [`GRLEN-1:0] dumb_rdata2_0;
   wire [`GRLEN-1:0] dumb_rdata2_1;
   
   reg_file registers(
        .clk        (clk                  ),

        .waddr1     (ecl_irf_rd_w         ),// I, 5
        .raddr0_0   (ecl_irf_rs1_d        ),// I, 5
        .raddr0_1   (ecl_irf_rs2_d        ),// I, 5
        .wen1       (ecl_irf_wen_w        ),// I, 1
        .wdata1     (ecl_irf_rd_data_w    ),// I, 32
        .rdata0_0   (irf_ecl_rs1_data_d   ),// O, 32
        .rdata0_1   (irf_ecl_rs2_data_d   ),// O, 32

      
        .waddr2     (5'b0       ),// I, 5
        .raddr1_0   (5'b0       ),// I, 32
        .raddr1_1   (5'b0       ),// I, 32
        .wen2       (1'b0       ),// I, 1
        .wdata2     (32'b0      ),// I, 32
        .rdata1_0   (dumb_rdata1_0   ),// O, 32
        .rdata1_1   (dumb_rdata1_1   ),// O, 32

        .raddr2_0   (5'b0       ),// I, 5
        .raddr2_1   (5'b0   ),// I, 5
        .rdata2_0   (dumb_rdata2_0   ),// O, 32
        .rdata2_1   (dumb_rdata2_1   ) // O, 32
      
//        .waddr2     (waddr2     ),// I, 32
//        .raddr1_0   (raddr1_0   ),// I, 32
//        .raddr1_1   (raddr1_1   ),// I, 32
//        .wen2       (wen2       ),// I, 1
//        .wdata2     (wdata2     ),// I, 32
//        .rdata1_0   (rdata1_0   ),// O, 32
//        .rdata1_1   (rdata1_1   ),// O, 32
//
//        .raddr2_0   (raddr2_0   ),// I, 32
//        .raddr2_1   (raddr2_1   ),// I, 32
//        .rdata2_0   (rdata2_0   ),// O, 32
//        .rdata2_1   (rdata2_1   ) // O, 32
      );

   // cpu7_exu_byp
   
   cpu7_exu_ecl ecl(
      .clk                      (clk                 ),
      .resetn                   (resetn              ),
      .ifu_exu_valid_d          (ifu_exu_valid_d     ),
      .ifu_exu_inst_d           (ifu_exu_inst_d      ),
      .ifu_exu_op_d             (ifu_exu_op_d        ),
      .ifu_exu_pc_d             (ifu_exu_pc_d        ),
      .ifu_exu_rf_wen_d         (ifu_exu_rf_wen_d    ),
      .ifu_exu_rf_target_d      (ifu_exu_rf_target_d ),
      .ifu_exu_imm_shifted_d    (ifu_exu_imm_shifted_d),
      .ifu_exu_c_d              (ifu_exu_c_d         ),
      .irf_ecl_rs1_data_d       (irf_ecl_rs1_data_d  ),
      .irf_ecl_rs2_data_d       (irf_ecl_rs2_data_d  ),

      .alu_ecl_res_e            (alu_ecl_res_e       ),

      .ecl_irf_rs1_d            (ecl_irf_rs1_d       ),
      .ecl_irf_rs2_d            (ecl_irf_rs2_d       ),
      .ecl_alu_a_e              (ecl_alu_a_e         ),
      .ecl_alu_b_e              (ecl_alu_b_e         ),
      .ecl_alu_op_e             (ecl_alu_op_e        ),
      .ecl_alu_c_e              (ecl_alu_c_e         ),
      .ecl_alu_double_word_e    (ecl_alu_double_word_e),

      .ecl_irf_rd_data_w        (ecl_irf_rd_data_w   ),
      .ecl_irf_rd_w             (ecl_irf_rd_w        ),
      .ecl_irf_wen_w            (ecl_irf_wen_w       )
      );



   // alu's result should pass to cpu7_exu_byp
   // now send it to ecl, ecl store is to the consequent
   // pipeline registers, then write back to rf  
   
   // alu
   alu alu(   
      .a                        (ecl_alu_a_e          ),
      .b                        (ecl_alu_b_e          ),
      .double_word              (ecl_alu_double_word_e),
      .alu_op                   (ecl_alu_op_e         ),
      .c                        (ecl_alu_c_e          ),
      .Result                   (alu_ecl_res_e        )
      );

   
   // wrong test
   assign debug0_wb_pc = ifu_exu_pc_w;
   assign debug0_wb_rf_wen = ecl_irf_wen_w;
   assign debug0_wb_rf_wnum = ecl_irf_rd_w;
   assign debug0_wb_rf_wdata = ecl_irf_rd_data_w;  
   
//   assign debug0_wb_pc = `GRLEN'b0;
//   assign debug0_wb_rf_wen = 1'b0;
//   assign debug0_wb_rf_wnum = 5'b0;
//   assign debug0_wb_rf_wdata = `GRLEN'b0;
//
//   assign debug1_wb_pc = `GRLEN'b0;
//   assign debug1_wb_rf_wen = 1'b0;
//   assign debug1_wb_rf_wnum = 5'b0;
//   assign debug1_wb_rf_wdata = `GRLEN'b0;

endmodule // cpu7_exu
