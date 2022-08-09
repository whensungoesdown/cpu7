module gs232c_front(
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
// group bt
wire        bt_brop      ;
wire [3 :0] bt_brops     ;
wire        bt_cancel    ;
wire [15:0] bt_hint      ;
wire        bt_jrop      ;
wire [31:0] bt_pc        ;
wire [31:0] bt_target    ;
// group pr
wire [29:0] pr_base      ;
wire        pr_brop      ;
wire [3 :0] pr_brops     ;
wire [3 :0] pr_brops_raw ;
wire        pr_cancel    ;
wire [1 :0] pr_dofs      ;
wire [15:0] pr_hint      ;
wire        pr_jrop      ;
wire        pr_jrra      ;
wire        pr_link      ;
wire [29:0] pr_link_pc   ;
wire [31:0] pr_pc        ;
wire        pr_taken     ;
wire [3 :0] pr_takens    ;
wire [31:0] pr_target    ;
wire        pr_valid     ;
wire [3 :0] bht_hint     ;
wire [3 :0] bht_taken    ;
wire [3 :0] jtb_jrops    ;
wire [29:0] jtb_target   ;
wire [29:0] ra           ;
wire [7 :0] raminit_index;
wire        raminit_valid;
wire        pc_go        ;
// group fe
wire [31:0] fe_cur       ;
wire        fe_go        ;
wire [15:0] fe_hint      ;
wire        fe_is_seq    ;
wire [29:0] fe_seq       ;
wire [29:0] fe_target    ;
wire        fe_valid     ;
wire        iq_cancel    ;
wire        iq_go        ;
wire [29:0] jhr_last_br  ;
wire [29:0] jhr_last_pr  ;
wire [63:0] jhr_path_br  ;
wire [63:0] jhr_path_bt  ;
wire [24:0] bhr_br       ;
wire [20:0] bhr_bt       ;
wire        buf_cancel   ;
gs232c_raminit
#(
    .n(8)
)
init
(
    .clock(clock        ),// I, 1
    .reset(reset        ),// I, 1
    .index(raminit_index),// O, n
    .valid(raminit_valid) // O, 1
);
gs232c_pipe_pc pipe_pc
(
    .clock    (clock    ),// I, 1 
    .reset    (reset    ),// I, 1 
    .bt_cancel(bt_cancel),// I, 1 
    .bt_target(bt_target),// I, 32
    .bt_pc    (bt_pc    ),// O, 32
    .bt_hint  (bt_hint  ),// I, 16
    .pr_cancel(pr_cancel),// I, 1 
    .pr_target(pr_target),// I, 32
    .br_cancel(br_cancel),// I, 1 
    .br_target(br_target),// I, 32
    .wb_cancel(wb_cancel),// I, 1 
    .wb_target(wb_target),// I, 32
    .pc_go    (pc_go    ),// I, 1 
    .pc_init  (pc_init  ),// I, 32
    .fe_go    (fe_go    ),// I, 1 
    .fe_cur   (fe_cur   ),// O, 32
    .fe_valid (fe_valid ),// O, 1 
    .fe_seq   (fe_seq   ),// O, 30
    .fe_target(fe_target),// O, 30
    .fe_is_seq(fe_is_seq),// O, 1 
    .fe_hint  (fe_hint  ),// O, 16
    .iq_cancel(iq_cancel),// I, 1 
    .inst_addr(inst_addr) // O, 32
);
gs232c_jhr jhr_maintainer
(
    .clock     (clock      ),// I, 1 
    .reset     (reset      ),// I, 1 
    .hr_path_br(jhr_path_br),// O, 64
    .hr_path_bt(jhr_path_bt),// O, 64
    .hr_last_pr(jhr_last_pr),// O, 30
    .hr_last_br(jhr_last_br),// O, 30
    .pc_go     (pc_go      ),// I, 1 
    .bt_target (bt_target  ),// I, 32
    .bt_jrop   (bt_jrop    ),// I, 1 
    .pr_cancel (pr_cancel  ),// I, 1 
    .pr_target (pr_target  ),// I, 32
    .pr_jrop   (pr_jrop    ),// I, 1 
    .br_cancel (br_cancel  ),// I, 1 
    .br_target (br_target  ),// I, 32
    .br_jrop   (br_jrop    ),// I, 1 
    .wb_cancel (wb_cancel  ),// I, 1 
    .wb_jrop   (wb_jrop    ) // I, 1 
);
gs232c_bhr bhr_maintainer
(
    .clock    (clock    ),// I, 1 
    .reset    (reset    ),// I, 1 
    .pc_go    (pc_go    ),// I, 1 
    .bt_brop  (bt_brop  ),// I, 1 
    .bt_brops (bt_brops ),// I, 4 
    .pr_cancel(pr_cancel),// I, 1 
    .pr_brop  (pr_brop  ),// I, 1 
    .pr_valid (pr_valid ),// I, 1 
    .pr_brops (pr_brops ),// I, 4 
    .br_cancel(br_cancel),// I, 1 
    .br_brop  (br_brop  ),// I, 1 
    .br_taken (br_taken ),// I, 1 
    .wb_cancel(wb_cancel),// I, 1 
    .wb_brop  (wb_brop  ),// I, 1 
    .wb_taken (wb_taken ),// I, 1 
    .hr_bt    (bhr_bt   ),// O, 21
    .hr_br    (bhr_br   ) // O, 25
);
gs232c_btb btb_tbl
(
    .clock        (clock        ),// I, 1 
    .reset        (reset        ),// I, 1 
    .raminit_index(raminit_index),// I, 8 
    .raminit_valid(raminit_valid),// I, 1 
    .iq_go        (iq_go        ),// I, 1 
    .iq_cancel    (iq_cancel    ),// I, 1 
    .bt_cancel    (bt_cancel    ),// O, 1 
    .bt_target    (bt_target    ),// O, 32
    .bt_pc        (bt_pc        ),// I, 32
    .bt_jrop      (bt_jrop      ),// O, 1 
    .bt_brop      (bt_brop      ),// O, 1 
    .bt_brops     (bt_brops     ),// O, 4 
    .bt_hint      (bt_hint      ),// O, 16
    .pr_cancel    (pr_cancel    ),// I, 1 
    .pr_target    (pr_target    ),// I, 32
    .pr_brop      (pr_brop      ),// I, 1 
    .pr_jrop      (pr_jrop      ),// I, 1 
    .pr_jrra      (pr_jrra      ),// I, 1 
    .pr_link      (pr_link      ),// I, 1 
    .pr_taken     (pr_taken     ),// I, 1 
    .pr_link_pc   (pr_link_pc   ),// I, 30
    .pr_pc        (pr_pc        ),// I, 32
    .pr_valid     (pr_valid     ),// I, 1 
    .pr_dofs      (pr_dofs      ),// I, 2 
    .pr_base      (pr_base      ),// I, 30
    .pr_brops     (pr_brops     ),// I, 4 
    .pr_brops_raw (pr_brops_raw ),// I, 4 
    .pr_takens    (pr_takens    ),// I, 4 
    .pr_hint      (pr_hint      ),// I, 16
    .ra           (ra           ) // I, 30
);
gs232c_bht bht_tbl
(
    .clock         (clock         ),// I, 1 
    .reset         (reset         ),// I, 1 
    .bt_pc         (bt_pc         ),// I, 32
    .pc_go         (pc_go         ),// I, 1 
    .iq_go         (iq_go         ),// I, 1 
    .br_cancel     (br_cancel     ),// I, 1 
    .br_brop       (br_brop       ),// I, 1 
    .br_taken      (br_taken      ),// I, 1 
    .br_sign       (br_sign       ),// I, 1 
    .br_pc         (br_pc         ),// I, 32
    .br_target     (br_target     ),// I, 32
    .br_hint       (br_hint       ),// I, 5 
    .pr_cancel     (pr_cancel     ),// I, 1 
    .buf_cancel    (buf_cancel    ),// I, 1 
    .o_taken       (bht_taken     ),// O, 4 
    .o_hint        (bht_hint      ),// O, 4 
    .raminit_index (raminit_index ),// I, 8 
    .raminit_valid (raminit_valid ),// I, 1 
    .tbl_tag1_ce   (bht_tag1_ce   ),// O, 1 
    .tbl_tag1_en   (bht_tag1_en   ),// O, 1 
    .tbl_tag1_a    (bht_tag1_a    ),// O, 8 
    .tbl_tag1_rd   (bht_tag1_rd   ),// I, 32
    .tbl_tag1_we   (bht_tag1_we   ),// O, 32
    .tbl_tag1_wd   (bht_tag1_wd   ),// O, 32
    .tbl_cnt1_hi_ce(bht_cnt1_hi_ce),// O, 1 
    .tbl_cnt1_hi_en(bht_cnt1_hi_en),// O, 1 
    .tbl_cnt1_hi_a (bht_cnt1_hi_a ),// O, 8 
    .tbl_cnt1_hi_rd(bht_cnt1_hi_rd),// I, 4 
    .tbl_cnt1_hi_we(bht_cnt1_hi_we),// O, 4 
    .tbl_cnt1_hi_wd(bht_cnt1_hi_wd),// O, 4 
    .tbl_cnt1_lo_ce(bht_cnt1_lo_ce),// O, 1 
    .tbl_cnt1_lo_en(bht_cnt1_lo_en),// O, 1 
    .tbl_cnt1_lo_a (bht_cnt1_lo_a ),// O, 8 
    .tbl_cnt1_lo_rd(bht_cnt1_lo_rd),// I, 4 
    .tbl_cnt1_lo_we(bht_cnt1_lo_we),// O, 4 
    .tbl_cnt1_lo_wd(bht_cnt1_lo_wd),// O, 4 
    .tbl_cnt0_hi_ce(bht_cnt0_hi_ce),// O, 1 
    .tbl_cnt0_hi_en(bht_cnt0_hi_en),// O, 1 
    .tbl_cnt0_hi_a (bht_cnt0_hi_a ),// O, 6 
    .tbl_cnt0_hi_rd(bht_cnt0_hi_rd),// I, 8 
    .tbl_cnt0_hi_we(bht_cnt0_hi_we),// O, 8 
    .tbl_cnt0_hi_wd(bht_cnt0_hi_wd),// O, 8 
    .tbl_cnt0_lo_ce(bht_cnt0_lo_ce),// O, 1 
    .tbl_cnt0_lo_en(bht_cnt0_lo_en),// O, 1 
    .tbl_cnt0_lo_a (bht_cnt0_lo_a ),// O, 6 
    .tbl_cnt0_lo_rd(bht_cnt0_lo_rd),// I, 8 
    .tbl_cnt0_lo_we(bht_cnt0_lo_we),// O, 8 
    .tbl_cnt0_lo_wd(bht_cnt0_lo_wd),// O, 8 
    .bhr_bt        (bhr_bt        ),// I, 21
    .bhr_br        (bhr_br        ) // I, 25
);
gs232c_jtb jtb_tbl
(
    .clock        (clock        ),// I, 1 
    .reset        (reset        ),// I, 1 
    .bt_pc        (bt_pc        ),// I, 32
    .pc_go        (pc_go        ),// I, 1 
    .iq_go        (iq_go        ),// I, 1 
    .pr_cancel    (pr_cancel    ),// I, 1 
    .buf_cancel   (buf_cancel   ),// I, 1 
    .br_cancel    (br_cancel    ),// I, 1 
    .br_jrop      (br_jrop      ),// I, 1 
    .br_pc        (br_pc        ),// I, 32
    .br_target    (br_target    ),// I, 32
    .br_hint      (br_hint      ),// I, 5 
    .o_jrops      (jtb_jrops    ),// I, 4 
    .o_target     (jtb_target   ),// O, 30
    .raminit_index(raminit_index),// I, 8 
    .raminit_valid(raminit_valid),// I, 1 
    .jhr_path_br  (jhr_path_br  ),// I, 64
    .jhr_path_bt  (jhr_path_bt  ),// I, 64
    .jhr_last_pr  (jhr_last_pr  ),// I, 30
    .jhr_last_br  (jhr_last_br  ) // I, 30
);
gs232c_ras ras
(
    .clock        (clock        ),// I, 1 
    .reset        (reset        ),// I, 1 
    .raminit_valid(raminit_valid),// I, 1 
    .pr_jrra      (pr_jrra      ),// I, 1 
    .pr_link      (pr_link      ),// I, 1 
    .pr_link_pc   (pr_link_pc   ),// I, 30
    .br_cancel    (br_cancel    ),// I, 1 
    .br_jrra      (br_jrra      ),// I, 1 
    .br_link      (br_link      ),// I, 1 
    .br_link_pc   (br_link_pc   ),// I, 30
    .wb_cancel    (wb_cancel    ),// I, 1 
    .wb_jrra      (wb_jrra      ),// I, 1 
    .wb_link      (wb_link      ),// I, 1 
    .wb_link_pc   (wb_link_pc   ),// I, 30
    .ra           (ra           ) // O, 30
);
gs232c_inst_queue inst_queue
(
    .clock          (clock          ),// I, 1  
    .reset          (reset          ),// I, 1  
    .pc_go          (pc_go          ),// O, 1  
    .raminit_valid  (raminit_valid  ),// I, 1  
    .fe_go          (fe_go          ),// O, 1  
    .fe_cur         (fe_cur         ),// I, 32 
    .fe_valid       (fe_valid       ),// I, 1  
    .fe_seq         (fe_seq         ),// I, 30 
    .fe_target      (fe_target      ),// I, 30 
    .fe_is_seq      (fe_is_seq      ),// I, 1  
    .fe_hint        (fe_hint        ),// I, 16 
    .iq_go          (iq_go          ),// O, 1  
    .iq_cancel      (iq_cancel      ),// O, 1  
    .inst_req       (inst_req       ),// O, 1  
    .inst_addr_ok   (inst_addr_ok   ),// I, 1  
    .inst_cancel    (inst_cancel    ),// O, 1  
    .inst_valid     (inst_valid     ),// I, 1  
    .inst_count     (inst_count     ),// I, 2  
    .inst_rdata     (inst_rdata     ),// I, 128
    .inst_uncache   (inst_uncache   ),// I, 1  
    .inst_ex        (inst_ex        ),// I, 1  
    .inst_exccode   (inst_exccode   ),// I, 6  
    .o_allow        (o_allow        ),// I, 3  
    .o_valid        (o_valid        ),// O, 3  
    .o_port0_pc     (o_port0_pc     ),// O, 32 
    .o_port0_target (o_port0_target ),// O, 30 
    .o_port0_inst   (o_port0_inst   ),// O, 32 
    .o_port0_taken  (o_port0_taken  ),// O, 1  
    .o_port0_ex     (o_port0_ex     ),// O, 1  
    .o_port0_exccode(o_port0_exccode),// O, 6  
    .o_port0_hint   (o_port0_hint   ),// O, 5  
    .o_port1_pc     (o_port1_pc     ),// O, 32 
    .o_port1_target (o_port1_target ),// O, 30 
    .o_port1_inst   (o_port1_inst   ),// O, 32 
    .o_port1_taken  (o_port1_taken  ),// O, 1  
    .o_port1_ex     (o_port1_ex     ),// O, 1  
    .o_port1_exccode(o_port1_exccode),// O, 6  
    .o_port1_hint   (o_port1_hint   ),// O, 5  
    .o_port2_pc     (o_port2_pc     ),// O, 32 
    .o_port2_target (o_port2_target ),// O, 30 
    .o_port2_inst   (o_port2_inst   ),// O, 32 
    .o_port2_taken  (o_port2_taken  ),// O, 1  
    .o_port2_ex     (o_port2_ex     ),// O, 1  
    .o_port2_exccode(o_port2_exccode),// O, 6  
    .o_port2_hint   (o_port2_hint   ),// O, 5  
    .pr_cancel      (pr_cancel      ),// O, 1  
    .pr_target      (pr_target      ),// O, 32 
    .pr_brop        (pr_brop        ),// O, 1  
    .pr_jrop        (pr_jrop        ),// O, 1  
    .pr_jrra        (pr_jrra        ),// O, 1  
    .pr_link        (pr_link        ),// O, 1  
    .pr_taken       (pr_taken       ),// O, 1  
    .pr_link_pc     (pr_link_pc     ),// O, 30 
    .pr_pc          (pr_pc          ),// O, 32 
    .pr_valid       (pr_valid       ),// O, 1  
    .pr_dofs        (pr_dofs        ),// O, 2  
    .pr_base        (pr_base        ),// O, 30 
    .pr_brops       (pr_brops       ),// O, 4  
    .pr_brops_raw   (pr_brops_raw   ),// O, 4  
    .pr_takens      (pr_takens      ),// O, 4  
    .pr_hint        (pr_hint        ),// O, 16 
    .br_cancel      (br_cancel      ),// I, 1  
    .wb_cancel      (wb_cancel      ),// I, 1  
    .ra             (ra             ),// I, 30 
    .bht_taken      (bht_taken      ),// I, 4  
    .bht_hint       (bht_hint       ),// I, 4  
    .jtb_jrops      (jtb_jrops      ),// O, 4  
    .jtb_target     (jtb_target     ),// I, 30 
    .buf_cancel     (buf_cancel     ) // O, 1  
);
gs232c_monitor monitor
(
    .clock          (clock          ),// I, 1 
    .reset          (reset          ),// I, 1 
    .pr_cancel      (pr_cancel      ),// I, 1 
    .pr_target      (pr_target      ),// I, 32
    .pr_brop        (pr_brop        ),// I, 1 
    .pr_jrop        (pr_jrop        ),// I, 1 
    .pr_jrra        (pr_jrra        ),// I, 1 
    .pr_link        (pr_link        ),// I, 1 
    .pr_taken       (pr_taken       ),// I, 1 
    .pr_link_pc     (pr_link_pc     ),// I, 30
    .pr_pc          (pr_pc          ),// I, 32
    .pr_valid       (pr_valid       ),// I, 1 
    .pr_dofs        (pr_dofs        ),// I, 2 
    .pr_base        (pr_base        ),// I, 30
    .pr_brops       (pr_brops       ),// I, 4 
    .pr_brops_raw   (pr_brops_raw   ),// I, 4 
    .pr_takens      (pr_takens      ),// I, 4 
    .pr_hint        (pr_hint        ),// I, 16
    .br_cancel      (br_cancel      ),// I, 1 
    .br_target      (br_target      ),// I, 32
    .br_brop        (br_brop        ),// I, 1 
    .br_jrop        (br_jrop        ),// I, 1 
    .br_jrra        (br_jrra        ),// I, 1 
    .br_link        (br_link        ),// I, 1 
    .br_taken       (br_taken       ),// I, 1 
    .br_link_pc     (br_link_pc     ),// I, 30
    .br_pc          (br_pc          ),// I, 32
    .br_hint        (br_hint        ),// I, 5 
    .br_sign        (br_sign        ),// I, 1 
    .wb_cancel      (wb_cancel      ),// I, 1 
    .wb_target      (wb_target      ),// I, 32
    .wb_brop        (wb_brop        ),// I, 1 
    .wb_jrop        (wb_jrop        ),// I, 1 
    .wb_jrra        (wb_jrra        ),// I, 1 
    .wb_link        (wb_link        ),// I, 1 
    .wb_taken       (wb_taken       ),// I, 1 
    .wb_link_pc     (wb_link_pc     ),// I, 30
    .wb_pc          (wb_pc          ),// I, 32
    .o_allow        (o_allow        ),// I, 3 
    .o_valid        (o_valid        ),// I, 3 
    .o_port0_pc     (o_port0_pc     ),// I, 32
    .o_port0_target (o_port0_target ),// I, 30
    .o_port0_inst   (o_port0_inst   ),// I, 32
    .o_port0_taken  (o_port0_taken  ),// I, 1 
    .o_port0_ex     (o_port0_ex     ),// I, 1 
    .o_port0_exccode(o_port0_exccode),// I, 6 
    .o_port0_hint   (o_port0_hint   ),// I, 5 
    .o_port1_pc     (o_port1_pc     ),// I, 32
    .o_port1_target (o_port1_target ),// I, 30
    .o_port1_inst   (o_port1_inst   ),// I, 32
    .o_port1_taken  (o_port1_taken  ),// I, 1 
    .o_port1_ex     (o_port1_ex     ),// I, 1 
    .o_port1_exccode(o_port1_exccode),// I, 6 
    .o_port1_hint   (o_port1_hint   ),// I, 5 
    .o_port2_pc     (o_port2_pc     ),// I, 32
    .o_port2_target (o_port2_target ),// I, 30
    .o_port2_inst   (o_port2_inst   ),// I, 32
    .o_port2_taken  (o_port2_taken  ),// I, 1 
    .o_port2_ex     (o_port2_ex     ),// I, 1 
    .o_port2_exccode(o_port2_exccode),// I, 6 
    .o_port2_hint   (o_port2_hint   ) // I, 5 
);
endmodule // gs232c_front
