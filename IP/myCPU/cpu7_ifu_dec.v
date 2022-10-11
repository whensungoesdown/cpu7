`include "common.vh"
`include "decoded.vh"

module cpu7_ifu_dec(
   input  wire                         clk,
   input  wire                         resetn,
   // pipe in
   //    output wire                         de_allow_in,
   //    output wire [ 2:0]                  de_accept,
   // port0
   input  wire                         de_port0_valid,
   input  wire [`GRLEN-1:0]            de_port0_pc,
   input  wire [31:0]                  de_port0_inst,
   input  wire [`GRLEN-3:0]            de_port0_br_target,
   input  wire                         de_port0_br_taken,
   input  wire                         de_port0_exception,
   input  wire [5 :0]                  de_port0_exccode,
   input  wire [`LSOC1K_PRU_HINT-1:0]  de_port0_hint,

   input  wire                              int_except,
   // port0
   output wire                              is_port0_valid,
   output wire [31:0]                       is_port0_inst,
   output wire [`GRLEN-1:0]                 is_port0_pc,
   output wire [`LSOC1K_DECODE_RES_BIT-1:0] is_port0_op,
   output wire                              is_port0_exception,
   output wire [5 :0]                       is_port0_exccode,
   output wire [`GRLEN-3:0]                 is_port0_br_target,
   output wire                              is_port0_br_taken,
   output wire                              is_port0_rf_wen,
   output wire [4:0]                        is_port0_rf_target,
   output wire [`LSOC1K_PRU_HINT-1:0]       is_port0_hint
   );


// define
wire rst = !resetn;
wire [`LSOC1K_DECODE_RES_BIT-1:0] port0_op;

////func
decoder port0_decoder(.inst(is_port0_inst), .res(port0_op)); //decode the inst

//reg file related
wire rf_wen0 = port0_op[`LSOC1K_GR_WEN];

wire [4:0] waddr0 = (port0_op[`LSOC1K_BRU_RELATED] && (port0_op[`LSOC1K_BRU_CODE] == `LSOC1K_BRU_BL)) ? 5'd1 : `GET_RD(is_port0_inst);

//// crash check
// exception
//wire port0_fpd = !csr_output[`LSOC1K_CSR_OUTPUT_EUEN_FPE] && port0_op[`LSOC1K_FLOAT];
//
//`ifdef LA64
//wire port0_ipe = ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd1) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL1] && port0_op[`LSOC1K_RDTIME]) ||
//                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd2) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL2] && port0_op[`LSOC1K_RDTIME]) ||
//                 ((csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd3) && csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL3] && port0_op[`LSOC1K_RDTIME]) ;
//`elsif LA32
//wire port0_ipe = 1'B0;//(csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] != 2'd0) && (port0_op[`LSOC1K_CSR_READ] || port0_op[`LSOC1K_CACHE_RELATED] || port0_op[`LSOC1K_TLB_RELATED] || port0_op[`LSOC1K_WAIT] || port0_op[`LSOC1K_ERET]);
//
//`endif


// uty: review
// here, port0_exception and port0_excccode both use de_port0_exception
// it may actually need to use is_port0_exception instead
// wait until debugging exception code
   
//wire port0_exception = de_port0_exception   || port0_op[`LSOC1K_SYSCALL] || port0_op[`LSOC1K_BREAK ] || port0_op[`LSOC1K_INE] ||
//                       port0_fpd || port0_ipe || int_except;
wire port0_exception = de_port0_exception   || port0_op[`LSOC1K_SYSCALL] || port0_op[`LSOC1K_BREAK ] || port0_op[`LSOC1K_INE] || int_except;
   
//
//wire [5:0] port0_exccode = int_except                ? `EXC_INT          :
//                           de_port0_exception       ? de_port0_exccode : 
//                           port0_op[`LSOC1K_SYSCALL] ? `EXC_SYS          :
//                           port0_op[`LSOC1K_BREAK  ] ? `EXC_BRK          :
//                           port0_op[`LSOC1K_INE    ] ? `EXC_INE          :
//                           port0_fpd                 ? `EXC_FPD          :
//                                                       6'd0              ;
wire [5:0] port0_exccode = int_except                ? `EXC_INT          :
                           de_port0_exception       ? de_port0_exccode : 
                           port0_op[`LSOC1K_SYSCALL] ? `EXC_SYS          :
                           port0_op[`LSOC1K_BREAK  ] ? `EXC_BRK          :
                           port0_op[`LSOC1K_INE    ] ? `EXC_INE          :
                                                       6'd0              ;
   
//assign de_allow_in = is_allow_in || bru_cancel || exception || eret;
//assign de_accept   = {0, 0, de_allow_in};



   dff_s #(1) port0_valid_reg (
      .din (de_port0_valid),
      .clk (clk),
      .q   (is_port0_valid),
      .se(), .si(), .so());

   dffe_s #(`GRLEN) port0_pc_reg (
      .din (de_port0_pc),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_pc),
      .se(), .si(), .so());

   dffe_s #(32) port0_inst_reg (
      .din (de_port0_inst),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_inst),
      .se(), .si(), .so());

   dffe_s #(`GRLEN-2) port0_br_target_reg (
      .din (de_port0_br_target),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_br_target),
      .se(), .si(), .so());
      
   dffe_s #(1) port0_br_taken_reg (
      .din (de_port0_br_taken),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_br_taken),
      .se(), .si(), .so());

   dffe_s #(1) port0_exception_reg (
      .din (de_port0_exception),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_exception),
      .se(), .si(), .so());
      
   dffe_s #(6) port0_exccode_reg (
      .din (de_port0_exccode),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_exccode),
      .se(), .si(), .so());

   dffe_s #(`LSOC1K_PRU_HINT) port0_hint_reg (
      .din (de_port0_hint),
      .en  (de_port0_valid),
      .clk (clk),
      .q   (is_port0_hint),
      .se(), .si(), .so());

   assign is_port0_op = port0_op;
   assign is_port0_rf_wen = rf_wen0;
   assign is_port0_rf_target = {5{rf_wen0}}&waddr0;




   
// basic
always @(posedge clk) begin
    if (rst)
    begin
//	is_port0_br_taken    <= 1'd0;
//        is_port0_exception   <= 1'd0;
//        is_port0_exccode     <= 6'd0;
//        is_port0_rf_wen      <= 1'd0;
//
//        is_port1_br_taken    <= 1'd0;
//        is_port1_exception   <= 1'd0;
//        is_port1_exccode     <= 6'd0;
//        is_port1_rf_wen      <= 1'd0;
//
//        is_port2_br_taken    <= 1'd0;
//        is_port2_exception   <= 1'd0;
//        is_port2_exccode     <= 6'd0;
    end
//    else
//    if (de_allow_in)
//    begin
//    end

end


//   assign is_port0_valid = valid0;  
//   assign is_port1_valid = 1'b0;  
//   assign is_port2_valid = 1'b0;  

endmodule // cpu7_ifu_dec
