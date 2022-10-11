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

   input  wire           exu_ifu_br_cancel,
   input  wire [31:0]    exu_ifu_br_target,

   
   // port0
   output wire                              port0_valid,
   output wire [31:0]                       port0_inst,
   output wire [`GRLEN-1:0]                 port0_pc,
   output wire [`LSOC1K_DECODE_RES_BIT-1:0] port0_op,
   output wire                              port0_exception,
   output wire [5 :0]                       port0_exccode,
   output wire [`GRLEN-3:0]                 port0_br_target,
   output wire                              port0_br_taken,
   output wire                              port0_rf_wen,
   output wire [4:0]                        port0_rf_target,
   output wire [`LSOC1K_PRU_HINT-1:0]       port0_hint
   );

   wire                             de_port0_valid;
   wire [`GRLEN-1:0]                de_port0_pc;
   wire [31:0]                      de_port0_inst;
   wire                             de_port0_br_taken;
   wire [`GRLEN-3:0]                de_port0_br_target;  
   wire                             de_port0_exception;
   wire [5:0]                       de_port0_exccode;
   wire [`LSOC1K_PRU_HINT-1:0]      de_port0_hint;

   cpu7_ifu_fdp fdp(
      .clock            (clock             ),
      .reset            (~resetn           ),

      .pc_init          (pc_init           ),

      .br_cancel        (exu_ifu_br_cancel ),
      .br_target        (exu_ifu_br_target ),

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

      .o_port0_valid    (de_port0_valid    ),
      .o_port0_pc       (de_port0_pc       ),
      .o_port0_inst     (de_port0_inst     ),
      .o_port0_taken    (de_port0_br_taken ),
      .o_port0_target   (de_port0_br_target),
      .o_port0_ex       (de_port0_exception),
      .o_port0_exccode  (de_port0_exccode  ),
      .o_port0_hint     (de_port0_hint     )
      );


   cpu7_ifu_dec dec(
      .clk                   (clock             ),
      .resetn                (resetn            ),

      // output  de_allow_in,
      // output de_accept

      .de_port0_valid        (de_port0_valid     ),
      .de_port0_pc           (de_port0_pc        ),
      .de_port0_inst         (de_port0_inst      ),
      .de_port0_br_target    (de_port0_br_target ),
      .de_port0_br_taken     (de_port0_br_taken  ),
      .de_port0_exception    (de_port0_exception ),
      .de_port0_exccode      (de_port0_exccode   ),
      .de_port0_hint         (de_port0_hint      ),

      .int_except            (1'b0               ), // test
      
      .is_port0_valid        (port0_valid        ),
      .is_port0_inst         (port0_inst         ),
      .is_port0_pc           (port0_pc           ),
      .is_port0_op           (port0_op           ),
      .is_port0_exception    (port0_exception    ),
      .is_port0_exccode      (port0_exccode      ),
      .is_port0_br_target    (port0_br_target    ),
      .is_port0_br_taken     (port0_br_taken     ),
      .is_port0_rf_wen       (port0_rf_wen       ),
      .is_port0_rf_target    (port0_rf_target    ),
      .is_port0_hint         (port0_hint         )
      );
   
endmodule // cpu7_ifu
