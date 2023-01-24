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
   input  [`LSOC1K_PRU_HINT-1:0]        ifu_exu_hint_d,

   input  [31:0]                        ifu_exu_imm_shifted_d,
   input  [`GRLEN-1:0]                  ifu_exu_c_d,
   input  [`GRLEN-1:0]                  ifu_exu_br_offs,

   input  [`GRLEN-1:0]                  ifu_exu_pc_w,
   input  [`GRLEN-1:0]                  ifu_exu_pc_e,

   // memory interface  E M
   output                               data_req,
   output [`GRLEN-1:0]                  data_addr,
   output                               data_wr,
   output [3:0]                         data_wstrb,
   output [`GRLEN-1:0]                  data_wdata,
   output                               data_prefetch,
   output                               data_ll,
   output                               data_sc,
   input                                data_addr_ok,
   
   output                               data_recv,
   input                                data_scsucceed,
   input  [`GRLEN-1:0]                  data_rdata,
   input                                data_exception,
   input  [5:0]                         data_excode,
   input  [`GRLEN-1:0]                  data_badvaddr,
   input                                data_data_ok,

   output [`GRLEN-1:0]                  data_pc,
   output                               data_cancel,
   output                               data_cancel_ex2,
   input                                data_req_empty,

   output                               exu_ifu_stall_req,
   output [`GRLEN-1:0]                  exu_ifu_brpc_e,
   output                               exu_ifu_br_taken_e,

   // exception
   output [`GRLEN-1:0]                  exu_ifu_eentry,
   output                               exu_ifu_except,
   // ertn
   output [`GRLEN-1:0]                  exu_ifu_era,
   output                               exu_ifu_ertn_e,
   
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
   
   
   // alu
   wire [`GRLEN-1:0]                    ecl_alu_a_e;
   wire [`GRLEN-1:0]                    ecl_alu_b_e;
   wire [`GRLEN-1:0]                    ecl_alu_c_e;
   wire [`LSOC1K_ALU_CODE_BIT-1:0]      ecl_alu_op_e;
   wire                                 ecl_alu_double_word_e;
   wire [`GRLEN-1:0]                    alu_ecl_res_e;


   // lsu
   wire                                 ecl_lsu_valid_e;
   wire [`LSOC1K_LSU_CODE_BIT-1:0]      ecl_lsu_op_e;
   wire [`GRLEN-1:0]                    ecl_lsu_base_e;
   wire [`GRLEN-1:0]                    ecl_lsu_offset_e;
   wire [`GRLEN-1:0]                    ecl_lsu_wdata_e;

   
   wire [`GRLEN-1:0]                    ecl_irf_rd_data_w;
   wire [4:0]                           ecl_irf_rd_w; // derived from ifu_exu_rf_target_d
   wire                                 ecl_irf_wen_w;


   // bru
   wire                                 ecl_bru_valid_e;
   wire [`LSOC1K_BRU_CODE_BIT-1:0]      ecl_bru_op_e;
   wire [`GRLEN-1:0]                    ecl_bru_a_e;       
   wire [`GRLEN-1:0]                    ecl_bru_b_e;
   wire [`GRLEN-1:0]                    ecl_bru_pc_e;
   wire [`GRLEN-1:0]                    ecl_bru_offset_e;

   wire [`GRLEN-1:0]                    bru_ecl_brpc_e;    
   wire                                 bru_ecl_br_taken_e;  
   wire [`GRLEN-1:0]                    bru_byp_link_pc_e;
   wire                                 bru_ecl_wen_e;


   // mul
   wire [`GRLEN-1:0] byp_mul_a_e;
   wire [`GRLEN-1:0] byp_mul_b_e;
   wire              ecl_mul_signed_e;
   wire              ecl_mul_double_e;
   wire              ecl_mul_hi_e;
   wire              ecl_mul_short_e;
   wire              ecl_mul_valid_e;
   wire              mul_ecl_64ready;
   wire              mul_ecl_32ready;
   wire [`GRLEN-1:0] mul_byp_res_m;


   // csr
   wire [`GRLEN-1:0]            csr_byp_rdata_d;
   wire [`LSOC1K_CSR_BIT-1:0]   ecl_csr_raddr_d;
   wire [`LSOC1K_CSR_BIT-1:0]   ecl_csr_waddr_m;
   wire [`GRLEN-1:0]            byp_csr_wdata_m;
   wire                         ecl_csr_wen_m;
   wire                         ecl_csr_ale_e;
   wire                         ecl_csr_illinst_e;
   wire                         ecl_csr_ertn_e;


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

   wire [4:0]                   ecl_lsu_rd_e;
   wire                         ecl_lsu_wen_e;
   
   wire                         lsu_ecl_addr_ok_e;
   wire [`GRLEN-1:0]            lsu_ecl_rdata_m;
   wire                         lsu_ecl_finish_m;
   wire [4:0]                   lsu_ecl_rd_m;
   wire                         lsu_ecl_wen_m;

   wire                         lsu_ecl_ale_e;
   
   
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
      .ifu_exu_br_offs          (ifu_exu_br_offs     ),
      .irf_ecl_rs1_data_d       (irf_ecl_rs1_data_d  ),
      .irf_ecl_rs2_data_d       (irf_ecl_rs2_data_d  ),


      .ecl_irf_rs1_d            (ecl_irf_rs1_d       ),
      .ecl_irf_rs2_d            (ecl_irf_rs2_d       ),


      // alu
      .ecl_alu_a_e              (ecl_alu_a_e         ),
      .ecl_alu_b_e              (ecl_alu_b_e         ),
      .ecl_alu_op_e             (ecl_alu_op_e        ),
      .ecl_alu_c_e              (ecl_alu_c_e         ),
      .ecl_alu_double_word_e    (ecl_alu_double_word_e),
      .alu_ecl_res_e            (alu_ecl_res_e       ),

      // lsu
      .ecl_lsu_valid_e          (ecl_lsu_valid_e     ),
      .ecl_lsu_op_e             (ecl_lsu_op_e        ),
      .ecl_lsu_base_e           (ecl_lsu_base_e      ),
      .ecl_lsu_offset_e         (ecl_lsu_offset_e    ),
      .ecl_lsu_wdata_e          (ecl_lsu_wdata_e     ),
      .ecl_lsu_rd_e             (ecl_lsu_rd_e        ),
      .ecl_lsu_wen_e            (ecl_lsu_wen_e       ),
      .lsu_ecl_rdata_m          (lsu_ecl_rdata_m     ),
      .lsu_ecl_finish_m         (lsu_ecl_finish_m    ),
      .lsu_ecl_rd_m             (lsu_ecl_rd_m        ),
      .lsu_ecl_wen_m            (lsu_ecl_wen_m       ),
      .lsu_ecl_addr_ok_e        (lsu_ecl_addr_ok_e   ),
      .lsu_ecl_ale_e            (lsu_ecl_ale_e       ),

      // bru
      .ecl_bru_valid_e          (ecl_bru_valid_e     ),
      .ecl_bru_op_e             (ecl_bru_op_e        ),
      .ecl_bru_a_e              (ecl_bru_a_e         ),
      .ecl_bru_b_e              (ecl_bru_b_e         ),
      .ecl_bru_pc_e             (ecl_bru_pc_e        ),
      .ecl_bru_offset_e         (ecl_bru_offset_e    ),
      .bru_ecl_brpc_e           (bru_ecl_brpc_e      ),
      .bru_ecl_br_taken_e       (bru_ecl_br_taken_e  ),
      .bru_byp_link_pc_e        (bru_byp_link_pc_e   ),
      .bru_ecl_wen_e            (bru_ecl_wen_e       ),

      // mul
      .ecl_mul_valid_e          (ecl_mul_valid_e     ),
      .byp_mul_a_e              (byp_mul_a_e         ),
      .byp_mul_b_e              (byp_mul_b_e         ),
      .ecl_mul_signed_e         (ecl_mul_signed_e    ),
      .ecl_mul_double_e         (ecl_mul_double_e    ),
      .ecl_mul_hi_e             (ecl_mul_hi_e        ),
      .ecl_mul_short_e          (ecl_mul_short_e     ),
      .mul_ecl_ready_m          (mul_ecl_32ready     ),
      .mul_byp_res_m            (mul_byp_res_m       ),

      // csr
      .csr_byp_rdata_d          (csr_byp_rdata_d     ),
      .ecl_csr_raddr_d          (ecl_csr_raddr_d     ),
      .ecl_csr_waddr_m          (ecl_csr_waddr_m     ),
      .byp_csr_wdata_m          (byp_csr_wdata_m     ),
      .ecl_csr_wen_m            (ecl_csr_wen_m       ),

      .exu_ifu_except           (exu_ifu_except      ),
      .ecl_csr_ale_e            (ecl_csr_ale_e       ),
      .ecl_csr_illinst_e        (ecl_csr_illinst_e   ),
      
      .exu_ifu_ertn_e           (exu_ifu_ertn_e      ),
      .ecl_csr_ertn_e           (ecl_csr_ertn_e      ),
      
      .exu_ifu_stall_req        (exu_ifu_stall_req   ),

      .exu_ifu_brpc_e           (exu_ifu_brpc_e      ),
      .exu_ifu_br_taken_e       (exu_ifu_br_taken_e  ),   

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



   cpu7_lsu lsu(
      .clk                      (clk                   ),
      .resetn                   (resetn                ),

      .valid_e                  (ecl_lsu_valid_e       ),
      .lsu_op                   (ecl_lsu_op_e          ),
      .base                     (ecl_lsu_base_e        ),
      .offset                   (ecl_lsu_offset_e      ),
      .wdata                    (ecl_lsu_wdata_e       ),
      .ecl_lsu_rd_e             (ecl_lsu_rd_e          ),
      .ecl_lsu_wen_e            (ecl_lsu_wen_e         ),

      // memory interface
      .data_req                 (data_req              ),
      .data_addr                (data_addr             ),
      .data_wr                  (data_wr               ),
      .data_wstrb               (data_wstrb            ),
      .data_wdata               (data_wdata            ),
      .data_prefetch            (data_prefetch         ),
      .data_ll                  (data_ll               ),
      .data_sc                  (data_sc               ),
      .data_addr_ok             (data_addr_ok          ),

      .data_recv                (data_recv             ),
      .data_scsucceed           (data_scsucceed        ),
      .data_rdata               (data_rdata            ),
      .data_exception           (data_exception        ),
      .data_excode              (data_excode           ),
      .data_badvaddr            (data_badvaddr         ),
      .data_data_ok             (data_data_ok          ),


      // lsu output
      .lsu_addr_finish          (lsu_ecl_addr_ok_e     ),
      .read_result_m            (lsu_ecl_rdata_m       ), //lsu_byp_rdata_m
      .lsu_finish_m             (lsu_ecl_finish_m      ),
      .lsu_ecl_rd_m             (lsu_ecl_rd_m          ),
      .lsu_ecl_wen_m            (lsu_ecl_wen_m         ),
      // currently, no signal represets for store success
      .lsu_ecl_ale_e            (lsu_ecl_ale_e         )   // align exception
      );

   assign data_pc = ifu_exu_pc_e;
   assign data_cancel = 1'b0;
   assign data_cancel_ex2 = 1'b0;


   //
   // BRU
   //
   
   branch bru (
      .branch_valid             (ecl_bru_valid_e        ),
      .branch_op                (ecl_bru_op_e           ),
      .branch_a                 (ecl_bru_a_e            ),
      .branch_b                 (ecl_bru_b_e            ),
      .branch_pc                (ecl_bru_pc_e           ),
      .branch_offset            (ecl_bru_offset_e       ),

      .bru_target               (bru_ecl_brpc_e         ),
      .bru_taken                (bru_ecl_br_taken_e     ),
      .bru_link_pc              (bru_byp_link_pc_e      ),
      .bru_wen                  (bru_ecl_wen_e          )
      ); 
   

   wire [63:0] mul_a_input = {32'b0, byp_mul_a_e};
   wire [63:0] mul_b_input = {32'b0, byp_mul_b_e};
   wire [63:0] mul_res_output;
   assign mul_byp_res_m = mul_res_output[31:0];
   
   mul64x64 mul(
      .clk                (clk            ),
      .rstn               (resetn         ),

//      .mul_validin        (mul_valid      ),
//      .ex2_allowin        (ex2_allow_in   ),
//      .mul_validout       (ex2_mul_ready  ),
//      .ex1_readygo        (ex1_allow_in   ),
//      .ex2_readygo        (ex2_allow_in   ),
      
      .mul_validin        (ecl_mul_valid_e  ),
      .ex2_allowin        (1'b1             ),
      .mul_validout       (mul_ecl_64ready  ),
      .ex1_readygo        (1'b1             ),
      .ex2_readygo        (1'b1             ),

      .opa                (mul_a_input      ),
      .opb                (mul_b_input      ),
      .mul_signed         (ecl_mul_signed_e ),
      .mul64              (ecl_mul_double_e ),
      .mul_hi             (ecl_mul_hi_e     ),
      .mul_short          (ecl_mul_short_e  ),

      .mul_res_out        (mul_res_output   ),
      .mul_ready          (mul_ecl_32ready  )
      );



   //
   // CSR
   //

   cpu7_csr csr(
      .clk               (clk               ),
      .resetn            (resetn            ),
      .csr_rdata         (csr_byp_rdata_d   ),
      .csr_raddr         (ecl_csr_raddr_d   ),
      .csr_waddr         (ecl_csr_waddr_m   ),
      .csr_wdata         (byp_csr_wdata_m   ),
      .csr_wen           (ecl_csr_wen_m     ),

      .csr_eentry        (exu_ifu_eentry    ),
      .csr_era           (exu_ifu_era       ),

      .ecl_csr_ale_e     (ecl_csr_ale_e     ),
      .ecl_csr_illinst_e (ecl_csr_illinst_e ),
      .ifu_exu_pc_e      (ifu_exu_pc_e      ),
      .ecl_csr_ertn_e    (ecl_csr_ertn_e    )
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
