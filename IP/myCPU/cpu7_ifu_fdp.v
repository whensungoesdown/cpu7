`include "common.vh"
 
module cpu7_ifu_fdp(
   input  wire         clock          ,
   input  wire         reset          ,
   input  wire [31 :0] pc_init        ,

   // group inst
   output wire [31 :0] inst_addr      ,
   input  wire         inst_addr_ok   ,
   output wire         inst_cancel    ,
   input  wire [1  :0] inst_count     ,
   input  wire         inst_ex        ,
   input  wire [5  :0] inst_exccode   ,
   input  wire [127:0] inst_rdata     ,
   output wire         inst_req       ,
   input  wire         inst_uncache   ,
   input  wire         inst_valid     ,

   input  wire         br_taken       ,
   input  wire [31 :0] br_target      ,

   // group o
   output wire                        fdp_dec_valid  ,
   output wire                        fdp_dec_ex     ,
   output wire [5  :0]                fdp_dec_exccode,
   output wire [`LSOC1K_PRU_HINT-1:0] fdp_dec_hint   ,
   output wire [31 :0]                fdp_dec_inst   ,
   output wire [31 :0]                fdp_dec_pc     ,
   output wire                        fdp_dec_taken  ,
   output wire [29 :0]                fdp_dec_target ,
   
   output wire [`GRLEN-1:0]           ifu_exu_pc_w   ,
   output wire [`GRLEN-1:0]           ifu_exu_pc_e   ,

   input  wire                        exu_ifu_stall_req
   );



   wire [31:0] pc_bf;
   wire [31:0] pc_f;
   wire [31:0] pcinc_f;

   wire [31:0] inst;


   wire ifu_pcbf_sel_init_bf_l;
   wire ifu_pcbf_sel_old_bf_l;
   wire ifu_pcbf_sel_pcinc_bf_l;
   wire ifu_pcbf_sel_brpc_bf_l;

   //.o_valid          ({de1_port2_valid,de1_port1_valid,de1_port0_valid}),
   // only use port0
   //assign o_valid = 3'b001;
//   dff_s #(3) ovalid_reg (
//      .din (3'b001 & {3{inst_valid}}),
//      .clk (clock),
//      .q   (o_valid),
//      .se(), .si(), .so());

//   assign o_valid = {0, 0, inst_valid};
      

   // let the later stage ignore the prediction, stall pipeline until the branch
   // is calculated
   assign fdp_dec_taken = 1'b0;
   assign fdp_dec_target = 30'b0;

   assign fdp_dec_ex = inst_ex;
   assign fdp_dec_exccode = inst_exccode;

   // if exu ask ifu to stall, the pc_bf takes bc_f and the instruction passed
   // down the pipe should be invalid
   //assign fdp_dec_valid = inst_valid;
   assign fdp_dec_valid = inst_valid & ~exu_ifu_stall_req & ~br_taken; // pc_f shoudl not be passed to pc_d if a branch is taken at _e.


   //===================================================
   // PC Datapath
   //===================================================

   wire [`GRLEN-1:0] pc_d;
   wire [`GRLEN-1:0] pc_e;
   wire [`GRLEN-1:0] pc_m;
   wire [`GRLEN-1:0] pc_w;
   
   
   // pc_before_fetch
   assign inst_addr = pc_bf;


   // set pc_f to pc_bf when the fetch is success
   //wire pc_bf2f_en = inst_valid;
   
   dff_s #(32) pc_reg (
      .din (pc_bf),
      .clk (clock),
      .q   (pc_f),
//      .en  (pc_bf2f_en),
      .se(), .si(), .so());


//   // en could be pc_bf_en, pc_bf_go
//   dffe_s #(32) pc_reg (
//      .din (pc_bf),
//      .en  (inst_addr_ok),
//      .clk (clock),
//      .q   (pc_f),
//      .se(), .si(), .so());
   

   
   assign fdp_dec_pc = pc_f; 
//   dff_s #(32) pcport0_reg (
//      .din (pc_f),
//      .clk (clock),
//      .q   (fdp_dec_pc),
//      .se(), .si(), .so());

   // pc_d_reg???cpu7_ifu_dec??????port0_pc_reg?????????
   //  ????????????????????????????????????
   // chiplab??????????????????paterson???????????????????????????????????????????????????????????????????????????
   // ??????opensparc T1????????????pc????????????????????????????????????????????????sparc_ifu_fdp???
   // ??????????????????opensparc???pc??????????????????????????????????????????writeback????????????pc???debug port
   // ????????????pc????????????????????????????????????
   // ??????????????????????????????????????????ifu??????dec???????????????cycle??????cycle??????????????????
   // ??????exu??????valid?????????wen????????????????????????????????????????????????????????????????????????????????????wb rd
   // ??????????????????
   // ??????????????????lsu???????????????valid????????????????????????????????????opensparc???????????????kill??????
   // ???????????????????????????


   //wire pc_f2d_en = ~exu_ifu_stall_req; 
   wire pc_f2d_en = fdp_dec_valid; 
   
   dffe_s #(`GRLEN) pc_f2d_reg (
      .din (pc_f),
      .clk (clock),
      .q   (pc_d),
      .en  (pc_f2d_en), 
      .se(), .si(), .so());
   
   dff_s #(`GRLEN) pc_d2e_reg (
      .din (pc_d),
      .clk (clock),
      .q   (pc_e),
      .se(), .si(), .so());

   dff_s #(`GRLEN) pc_e2m_reg (
      .din (pc_e),
      .clk (clock),
      .q   (pc_m),
      .se(), .si(), .so());

   assign ifu_exu_pc_e = pc_e;
   
   dff_s #(`GRLEN) pc_m2w_reg (
      .din (pc_m),
      .clk (clock),
      .q   (pc_w),
      .se(), .si(), .so());

   assign ifu_exu_pc_w = pc_w;

   
   assign pcinc_f[1:0] = pc_f[1:0];

   cpu7_ifu_incr30 pc_inc (
      .a     (pc_f[31:2]),
      .a_inc (pcinc_f[31:2]),
      .ofl   ()); // overflow output
      
   
   

   // for now, pc only +4
   //assign pc_bf = pc_inc_f;

//   dp_mux2es #(32) pcbf_mux(
//      .dout (pc_bf),
//      .in0  (pc_f),
//      .in1  (pcinc_f),
//      .sel  (inst_addr_ok)); // 1=pcinc_f,  instruction read in

   assign inst_req = ~reset;

   // when branch taken, inst_cancel need to be signal
   // so that the new target instruction can be fetched instead of the one previously requested
   assign inst_cancel = br_taken;

   assign ifu_pcbf_sel_init_bf_l = ~reset;
   // use inst_valid instead of inst_addr_ok, should name it fcl_fdp_pcbf_sel_old_l_bf
   //assign ifu_pcbf_sel_old_bf_l = inst_valid || reset || br_taken;
   assign ifu_pcbf_sel_old_bf_l = (inst_valid || reset || br_taken) & (~exu_ifu_stall_req);
   
   //assign ifu_pcbf_sel_pcinc_bf_l = ~(inst_valid && ~br_taken);  /// ??? br_taken never comes along with inst_valid, br_taken_e
   assign ifu_pcbf_sel_pcinc_bf_l = ~(inst_valid && ~br_taken) | exu_ifu_stall_req;  /// ??? br_taken never comes along with inst_valid, br_taken_e
   //assign ifu_pcbf_sel_pcinc_bf_l = ~inst_valid;
   assign ifu_pcbf_sel_brpc_bf_l = ~br_taken; 
   //assign ifu_pcbf_sel_brpc_bf_l = 1'b1;
   

   dp_mux4ds #(32) pcbf_mux(
      .dout (pc_bf),
      .in0  (pc_init),
      .in1  (pc_f),
      .in2  (pcinc_f),
      .in3  (br_target),
      .sel0_l (ifu_pcbf_sel_init_bf_l),
      .sel1_l (ifu_pcbf_sel_old_bf_l), 
      .sel2_l (ifu_pcbf_sel_pcinc_bf_l),
      .sel3_l (ifu_pcbf_sel_brpc_bf_l));
      

   //===================================================
   // Fetched Instruction Datapath
   //===================================================
   
   assign inst = inst_rdata[31:0];

   assign fdp_dec_inst = inst;
   
//   dff_s #(32) inst_reg (
//      .din (inst),
//      .clk (clock),
//      .q   (fdp_dec_inst),
//      .se(), .si(), .so());


//   dff_s #(32) nir_reg (
//      .din (),
//      .clk (clock),
//      .q   (),
//      .se(), .si(), so());


   assign fdp_dec_hint = `LSOC1K_PRU_HINT'b0;
   
endmodule // cpu7_ifu_fdp


