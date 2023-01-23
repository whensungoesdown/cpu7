`include "common.vh"
`include "decoded.vh"

module cpu7_ifu(
   input  wire           clock,
   input  wire           resetn,
   input  wire [31:0]    pc_init,

   // group inst
   output wire [31:0]    inst_addr,
   input  wire           inst_addr_ok,
   output wire           inst_cancel,
   input  wire [1:0]     inst_count,
   input  wire           inst_ex,
   input  wire [5:0]     inst_exccode,
   input  wire [127:0]   inst_rdata,
   output wire           inst_req,
   input  wire           inst_uncache,
   input  wire           inst_valid,

   input  wire           exu_ifu_br_taken,
   input  wire [31:0]    exu_ifu_br_target,

   // exception
   input  wire [`GRLEN-1:0]                 exu_ifu_eentry,
   input  wire                              exu_ifu_except,
   // ertn
   input  wire [`GRLEN-1:0]                 exu_ifu_era,
   input  wire                              exu_ifu_ertn_e,
   
   // port0
   output wire                              ifu_exu_valid_d,
   output wire [31:0]                       ifu_exu_inst_d,
   output wire [`GRLEN-1:0]                 ifu_exu_pc_d,
   output wire [`LSOC1K_DECODE_RES_BIT-1:0] ifu_exu_op_d,
   output wire                              ifu_exu_exception_d,
   output wire [5 :0]                       ifu_exu_exccode_d,
   output wire [`GRLEN-3:0]                 ifu_exu_br_target_d,
   output wire                              ifu_exu_br_taken_d,
   output wire                              ifu_exu_rf_wen_d,
   output wire [4:0]                        ifu_exu_rf_target_d,
   output wire [`LSOC1K_PRU_HINT-1:0]       ifu_exu_hint_d,

   output wire [31:0]                       ifu_exu_imm_shifted_d,
   output wire [`GRLEN-1:0]                 ifu_exu_c_d,
   output wire [`GRLEN-1:0]                 ifu_exu_br_offs,

   output wire [`GRLEN-1:0]                 ifu_exu_pc_w,
   output wire [`GRLEN-1:0]                 ifu_exu_pc_e,

   input  wire                              exu_ifu_stall_req
   );

   wire                             fdp_dec_valid;
   wire [`GRLEN-1:0]                fdp_dec_pc;
   wire [31:0]                      fdp_dec_inst;
   wire                             fdp_dec_br_taken;
   wire [`GRLEN-3:0]                fdp_dec_br_target;  
   wire                             fdp_dec_exception;
   wire [5:0]                       fdp_dec_exccode;
   wire [`LSOC1K_PRU_HINT-1:0]      fdp_dec_hint;

   cpu7_ifu_fdp fdp(
      .clock            (clock             ),
      .reset            (~resetn           ),

      .pc_init          (pc_init           ),

      .br_taken         (exu_ifu_br_taken  ),
      .br_target        (exu_ifu_br_target ),

      // exception
      .exu_ifu_eentry   (exu_ifu_eentry    ),
      .exu_ifu_except   (exu_ifu_except    ),
      // ertn
      .exu_ifu_era      (exu_ifu_era       ),
      .exu_ifu_ertn_e   (exu_ifu_ertn_e    ),

      .inst_req         (inst_req          ),
      .inst_addr        (inst_addr         ),
      .inst_cancel      (inst_cancel       ),
      .inst_addr_ok     (inst_addr_ok      ),
      .inst_valid       (inst_valid        ),
      .inst_count       (inst_count        ),
      .inst_rdata       (inst_rdata        ),
      .inst_uncache     (inst_uncache      ),
      .inst_ex          (inst_ex           ),
      .inst_exccode     (inst_exccode      ),

      .fdp_dec_valid    (fdp_dec_valid     ),
      .fdp_dec_pc       (fdp_dec_pc        ),
      .fdp_dec_inst     (fdp_dec_inst      ),
      .fdp_dec_taken    (fdp_dec_br_taken  ),
      .fdp_dec_target   (fdp_dec_br_target ),
      .fdp_dec_ex       (fdp_dec_exception ),
      .fdp_dec_exccode  (fdp_dec_exccode   ),
      .fdp_dec_hint     (fdp_dec_hint      ),

      .ifu_exu_pc_w     (ifu_exu_pc_w      ),
      .ifu_exu_pc_e     (ifu_exu_pc_e      ),

      .exu_ifu_stall_req(exu_ifu_stall_req )
      );


   cpu7_ifu_dec dec(
      .clk                   (clock             ),
      .resetn                (resetn            ),

      // output  de_allow_in,
      // output de_accept

      .fdp_dec_valid        (fdp_dec_valid       ),
      .fdp_dec_pc           (fdp_dec_pc          ),
      .fdp_dec_inst         (fdp_dec_inst        ),
      .fdp_dec_br_target    (fdp_dec_br_target   ),
      .fdp_dec_br_taken     (fdp_dec_br_taken    ),
      .fdp_dec_exception    (fdp_dec_exception   ),
      .fdp_dec_exccode      (fdp_dec_exccode     ),
      .fdp_dec_hint         (fdp_dec_hint        ),

      .int_except           (1'b0                ), // test
      
      .ifu_exu_valid_d      (ifu_exu_valid_d     ),
      .ifu_exu_inst_d       (ifu_exu_inst_d      ),
      .ifu_exu_pc_d         (ifu_exu_pc_d        ),
      .ifu_exu_op_d         (ifu_exu_op_d        ),
      .ifu_exu_exception_d  (ifu_exu_exception_d ),
      .ifu_exu_exccode_d    (ifu_exu_exccode_d   ),
      .ifu_exu_br_target_d  (ifu_exu_br_target_d ),
      .ifu_exu_br_taken_d   (ifu_exu_br_taken_d  ),
      .ifu_exu_rf_wen_d     (ifu_exu_rf_wen_d    ),
      .ifu_exu_rf_target_d  (ifu_exu_rf_target_d ),
      .ifu_exu_hint_d       (ifu_exu_hint_d      )
      );

   // cpu7_ifu_imd, decode offset imm
   cpu7_ifu_imd imd(
      .ifu_exu_inst_d        (ifu_exu_inst_d        ),
      .ifu_exu_op_d          (ifu_exu_op_d          ),
      .ifu_exu_imm_shifted_d (ifu_exu_imm_shifted_d ),
      .ifu_exu_c_d           (ifu_exu_c_d           ),
      .ifu_exu_br_offs       (ifu_exu_br_offs       )
      );
   
endmodule // cpu7_ifu
