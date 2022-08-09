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
    // group br
    input  wire         br_brop        ,
    input  wire         br_cancel      ,
    input  wire [4  :0] br_hint        ,
    input  wire         br_jrop        ,
    input  wire         br_jrra        ,
    input  wire         br_link        ,
    input  wire [29 :0] br_link_pc     ,
    input  wire [31 :0] br_pc          ,
    input  wire         br_sign        ,
    input  wire         br_taken       ,
    input  wire [31 :0] br_target      ,
    // group wb
    input  wire         wb_brop        ,
    input  wire         wb_cancel      ,
    input  wire         wb_jrop        ,
    input  wire         wb_jrra        ,
    input  wire         wb_link        ,
    input  wire [29 :0] wb_link_pc     ,
    input  wire [31 :0] wb_pc          ,
    input  wire         wb_taken       ,
    input  wire [31 :0] wb_target      ,
    // group o
    input  wire [2  :0] o_allow        ,
    output wire         o_port0_ex     ,
    output wire [5  :0] o_port0_exccode,
    output wire [4  :0] o_port0_hint   ,
    output wire [31 :0] o_port0_inst   ,
    output wire [31 :0] o_port0_pc     ,
    output wire         o_port0_taken  ,
    output wire [29 :0] o_port0_target ,
    output wire         o_port1_ex     ,
    output wire [5  :0] o_port1_exccode,
    output wire [4  :0] o_port1_hint   ,
    output wire [31 :0] o_port1_inst   ,
    output wire [31 :0] o_port1_pc     ,
    output wire         o_port1_taken  ,
    output wire [29 :0] o_port1_target ,
    output wire         o_port2_ex     ,
    output wire [5  :0] o_port2_exccode,
    output wire [4  :0] o_port2_hint   ,
    output wire [31 :0] o_port2_inst   ,
    output wire [31 :0] o_port2_pc     ,
    output wire         o_port2_taken  ,
    output wire [29 :0] o_port2_target ,
    output wire [2  :0] o_valid        ,
    // group bht_tag1
    output wire [7  :0] bht_tag1_a     ,
    output wire         bht_tag1_ce    ,
    output wire         bht_tag1_en    ,
    input  wire [31 :0] bht_tag1_rd    ,
    output wire [31 :0] bht_tag1_wd    ,
    output wire [31 :0] bht_tag1_we    ,
    // group bht_cnt1_hi
    output wire [7  :0] bht_cnt1_hi_a  ,
    output wire         bht_cnt1_hi_ce ,
    output wire         bht_cnt1_hi_en ,
    input  wire [3  :0] bht_cnt1_hi_rd ,
    output wire [3  :0] bht_cnt1_hi_wd ,
    output wire [3  :0] bht_cnt1_hi_we ,
    // group bht_cnt1_lo
    output wire [7  :0] bht_cnt1_lo_a  ,
    output wire         bht_cnt1_lo_ce ,
    output wire         bht_cnt1_lo_en ,
    input  wire [3  :0] bht_cnt1_lo_rd ,
    output wire [3  :0] bht_cnt1_lo_wd ,
    output wire [3  :0] bht_cnt1_lo_we ,
    // group bht_cnt0_hi
    output wire [5  :0] bht_cnt0_hi_a  ,
    output wire         bht_cnt0_hi_ce ,
    output wire         bht_cnt0_hi_en ,
    input  wire [7  :0] bht_cnt0_hi_rd ,
    output wire [7  :0] bht_cnt0_hi_wd ,
    output wire [7  :0] bht_cnt0_hi_we ,
    // group bht_cnt0_lo
    output wire [5  :0] bht_cnt0_lo_a  ,
    output wire         bht_cnt0_lo_ce ,
    output wire         bht_cnt0_lo_en ,
    input  wire [7  :0] bht_cnt0_lo_rd ,
    output wire [7  :0] bht_cnt0_lo_wd ,
    output wire [7  :0] bht_cnt0_lo_we  
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
   assign o_valid = {0, 0, inst_valid};
      

   // let the later stage ignore the prediction, stall pipeline until the branch
   // is calculated
   assign o_port0_taken = 1'b0;
   assign o_port0_target = 30'b0;

   assign o_port0_ex = inst_ex;
   assign o_port0_exccode = inst_exccode;



   //===================================================
   // PC Datapath
   //===================================================

   // pc_before_fetch
   assign inst_addr = pc_bf;

   
   dff_s #(32) pc_reg (
      .din (pc_bf),
      .clk (clock),
      .q   (pc_f),
      .se(), .si(), .so());


//   // en could be pc_bf_en, pc_bf_go
//   dffe_s #(32) pc_reg (
//      .din (pc_bf),
//      .en  (inst_addr_ok),
//      .clk (clock),
//      .q   (pc_f),
//      .se(), .si(), .so());
   

   
   assign o_port0_pc = pc_f; 
//   dff_s #(32) pcport0_reg (
//      .din (pc_f),
//      .clk (clock),
//      .q   (o_port0_pc),
//      .se(), .si(), .so());
   

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

   // uty: test
   // try inst_cancel
   assign inst_cancel = br_cancel;

   assign ifu_pcbf_sel_init_bf_l = ~reset;
   // use inst_valid instead of inst_addr_ok, should name it fcl_fdp_pcbf_sel_old_l_bf
   assign ifu_pcbf_sel_old_bf_l = inst_valid || reset || br_cancel;
   assign ifu_pcbf_sel_pcinc_bf_l = ~(inst_valid && ~br_cancel);  /// ??? br_cancel never comes along with inst_valid, br_cancel_e
   //assign ifu_pcbf_sel_pcinc_bf_l = ~inst_valid;
   // br_cancel is a weird, when it is 1, the br_target is the next pc and branch is taken
   assign ifu_pcbf_sel_brpc_bf_l = ~br_cancel; 
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

   assign o_port0_inst = inst;
   
//   dff_s #(32) inst_reg (
//      .din (inst),
//      .clk (clock),
//      .q   (o_port0_inst),
//      .se(), .si(), .so());


//   dff_s #(32) nir_reg (
//      .din (),
//      .clk (clock),
//      .q   (),
//      .se(), .si(), so());

endmodule // cpu7_front
