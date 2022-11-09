`include "common.vh"
`include "decoded.vh"

module cpu7(
    input               clk,
    input               resetn,            //low active

    input   [7 :0]      intrpt,
    
    `LSOC1K_DECL_BHT_RAMS_M,
    
    output              inst_req      ,
    output  [ 31:0]     inst_addr     ,
    output              inst_cancel   ,
    input               inst_addr_ok  ,
    input   [127:0]     inst_rdata    ,
    input               inst_valid    ,
    input   [  1:0]     inst_count    ,
    input               inst_uncache  ,
    input   [  5:0]     inst_exccode  ,
    input               inst_exception,

    input               inst_tlb_req  ,
    input   [`GRLEN-1:0] inst_tlb_vaddr,
    input               inst_tlb_cacop,

    output [`PIPELINE2DCACHE_BUS_WIDTH-1:0] pipeline2dcache_bus,
    input  [`DCACHE2PIPELINE_BUS_WIDTH-1:0] dcache2pipeline_bus,
    output                       csr_wen  ,
    output [`LSOC1K_CSR_BIT-1:0] csr_waddr,
    output [`GRLEN-1         :0] csr_wdata,
    output                       wb_eret  ,
    input  [`GRLEN-1         :0] llbctl   ,
    
    output              tlb_req         ,
    output              cache_req       ,
    output  [4 :0]      cache_op        ,
    output [`D_TAG_LEN-1:0] cache_op_tag,
    input               cache_op_recv   ,
    input               cache_op_finish ,

    // tlb-cache interface
    output  [`PABITS-1:0]      itlb_paddr,
    output              itlb_finish,
    output              itlb_hit,
    input               itlb_cache_recv,
    output              itlb_uncache,
    output  [ 5:0]      itlb_exccode,
    
    
    output  [`PABITS-1:0]      dtlb_paddr,
    output              dtlb_finish,
    output              dtlb_hit,
    input               data_tlb_req,
    input               data_tlb_wr   ,
    input   [`GRLEN-1:0]data_tlb_vaddr,
    input               dtlb_cache_recv,
    input               dtlb_no_trans  ,
    input               dtlb_p_pgcl    ,
    output              dtlb_uncache,
    output  [ 5:0]      dtlb_exccode,

    //debug interface
    output  [`GRLEN-1:0]   debug0_wb_pc,
    output                 debug0_wb_rf_wen,
    output  [ 4:0]         debug0_wb_rf_wnum,
    output  [`GRLEN-1:0]   debug0_wb_rf_wdata,
    
    output  [`GRLEN-1:0]   debug1_wb_pc,
    output                 debug1_wb_rf_wen,
    output  [ 4:0]         debug1_wb_rf_wnum,
    output  [`GRLEN-1:0]   debug1_wb_rf_wdata
);

   wire                              ifu_exu_valid_d;
   wire [31:0]                       ifu_exu_inst_d;
   wire [`GRLEN-1:0]                 ifu_exu_pc_d;
   wire [`LSOC1K_DECODE_RES_BIT-1:0] ifu_exu_op_d;     
   wire                              ifu_exu_exception_d;
   wire [5:0]                        ifu_exu_exccode_d;
   wire [`GRLEN-3:0]                 ifu_exu_br_target_d;
   wire                              ifu_exu_br_taken_d;
   wire                              ifu_exu_rf_wen_d;     
   wire [4:0]                        ifu_exu_rf_target_d;
   wire [`LSOC1K_PRU_HINT:0]         ifu_exu_hint_d;       

   wire [31:0]                       ifu_exu_imm_shifted_d;
   wire [`GRLEN-1:0]                 ifu_exu_c_d;
   wire [`GRLEN-1:0]                 ifu_exu_br_offs;

   wire [`GRLEN-1:0]                 ifu_exu_pc_w;
   wire [`GRLEN-1:0]                 ifu_exu_pc_e;

   wire                              exu_ifu_stall_req;

   wire [`GRLEN-1:0]                 exu_ifu_brpc_e;
   wire                              exu_ifu_br_taken_e;
   
   
   // Cache Pipeline Bus
   wire               data_req       ;
   wire  [`GRLEN-1:0] data_pc        ;
   wire               data_wr        ;
   wire  [3 :0]       data_wstrb     ;
   wire  [`GRLEN-1:0] data_addr      ;
   wire               data_cancel_ex2;
   wire               data_cancel    ;
   wire  [`GRLEN-1:0] data_wdata     ;
   wire               data_recv      ;
   wire               data_prefetch  ;
   wire               data_ll        ;
   wire               data_sc        ;

   wire  [`GRLEN-1:0] data_rdata     ;
   wire               data_addr_ok   ;
   wire               data_data_ok   ;
   wire  [ 5:0]       data_exccode   ;
   wire               data_exception ;
   wire  [`GRLEN-1:0] data_badvaddr  ;
   wire               data_req_empty ;
   wire               data_scsucceed ;

      

   
   cpu7_ifu ifu(
      .clock                   (clk                ),
      .resetn                  (resetn             ),

      .pc_init                 (`GRLEN'h1c000000   ),

      .inst_addr               (inst_addr          ),
      .inst_addr_ok            (inst_addr_ok       ),
      .inst_cancel             (inst_cancel        ),
      .inst_count              (inst_count         ),
      .inst_ex                 (inst_exception     ),
      .inst_exccode            (inst_exccode       ),
      .inst_rdata              (inst_rdata         ),
      .inst_req                (inst_req           ),
      .inst_uncache            (inst_uncache       ),
      .inst_valid              (inst_valid         ),

      .exu_ifu_br_taken        (exu_ifu_br_taken_e ), // BUG, need to change name
      .exu_ifu_br_target       (exu_ifu_brpc_e     ),

      // now only have one port
      .ifu_exu_valid_d         (ifu_exu_valid_d      ),
      .ifu_exu_inst_d          (ifu_exu_inst_d       ),
      .ifu_exu_pc_d            (ifu_exu_pc_d         ),
      .ifu_exu_op_d            (ifu_exu_op_d         ),
      .ifu_exu_exception_d     (ifu_exu_exception_d  ),
      .ifu_exu_exccode_d       (ifu_exu_exccode_d    ),
      .ifu_exu_br_target_d     (ifu_exu_br_target_d  ),
      .ifu_exu_br_taken_d      (ifu_exu_br_taken_d   ),
      .ifu_exu_rf_wen_d        (ifu_exu_rf_wen_d     ),
      .ifu_exu_rf_target_d     (ifu_exu_rf_target_d  ),
      .ifu_exu_hint_d          (ifu_exu_hint_d       ),

      .ifu_exu_imm_shifted_d   (ifu_exu_imm_shifted_d),
      .ifu_exu_c_d             (ifu_exu_c_d          ),
      .ifu_exu_br_offs         (ifu_exu_br_offs      ),

      .ifu_exu_pc_w            (ifu_exu_pc_w         ),
      .ifu_exu_pc_e            (ifu_exu_pc_e         ),

      .exu_ifu_stall_req       (exu_ifu_stall_req    )

      //.exu_ifu_brpc_e          (exu_ifu_brpc_e       ),
      //.exu_ifu_br_taken_e      (exu_ifu_br_taken_e   )
      );




   

   cpu7_exu exu(
      .clk                     (clk                  ),
      .resetn                  (resetn               ),

      .ifu_exu_valid_d         (ifu_exu_valid_d      ),
      .ifu_exu_inst_d          (ifu_exu_inst_d       ),
      .ifu_exu_pc_d            (ifu_exu_pc_d         ),
      .ifu_exu_op_d            (ifu_exu_op_d         ),
      .ifu_exu_exception_d     (ifu_exu_exception_d  ),
      .ifu_exu_exccode_d       (ifu_exu_exccode_d    ),
      .ifu_exu_br_target_d     (ifu_exu_br_target_d  ),
      .ifu_exu_br_taken_d      (ifu_exu_br_taken_d   ),
      .ifu_exu_rf_wen_d        (ifu_exu_rf_wen_d     ),
      .ifu_exu_rf_target_d     (ifu_exu_rf_target_d  ),
      .ifu_exu_hint_d          (ifu_exu_hint_d       ),

      .ifu_exu_imm_shifted_d   (ifu_exu_imm_shifted_d),
      .ifu_exu_c_d             (ifu_exu_c_d          ),
      .ifu_exu_br_offs         (ifu_exu_br_offs      ),
      
      .ifu_exu_pc_w            (ifu_exu_pc_w         ),
      .ifu_exu_pc_e            (ifu_exu_pc_e         ),

      // memory interface
      .data_req                (data_req             ),
      .data_addr               (data_addr            ),
      .data_wr                 (data_wr              ),
      .data_wstrb              (data_wstrb           ),
      .data_wdata              (data_wdata           ),
      .data_prefetch           (data_prefetch        ),
      .data_ll                 (data_ll              ),
      .data_sc                 (data_sc              ),
      .data_addr_ok            (data_addr_ok         ),

      .data_recv               (data_recv            ),
      .data_scsucceed          (data_scsucceed       ),
      .data_rdata              (data_rdata           ),
      .data_exception          (data_exception       ),
      .data_excode             (data_exccode         ),
      .data_badvaddr           (data_badvaddr        ),
      .data_data_ok            (data_data_ok         ),

      .data_pc                 (data_pc              ),
      .data_cancel             (data_cancel          ),
      .data_cancel_ex2         (data_cancel_ex2      ),
      .data_req_empty          (data_req_empty       ),
      
      .exu_ifu_stall_req       (exu_ifu_stall_req    ),

      .exu_ifu_brpc_e          (exu_ifu_brpc_e       ),
      .exu_ifu_br_taken_e      (exu_ifu_br_taken_e   ),

      .debug0_wb_pc            (debug0_wb_pc         ),
      .debug0_wb_rf_wen        (debug0_wb_rf_wen     ),
      .debug0_wb_rf_wnum       (debug0_wb_rf_wnum    ),
      .debug0_wb_rf_wdata      (debug0_wb_rf_wdata   ),
      
      .debug1_wb_pc            (debug1_wb_pc         ),
      .debug1_wb_rf_wen        (debug1_wb_rf_wen     ),
      .debug1_wb_rf_wnum       (debug1_wb_rf_wnum    ),
      .debug1_wb_rf_wdata      (debug1_wb_rf_wdata   )
      );

   

   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_REQ      ] = data_req       ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_PC       ] = data_pc        ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WR       ] = data_wr        ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WSTRB    ] = data_wstrb     ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ADDR     ] = data_addr      ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WDATA    ] = data_wdata     ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_RECV     ] = data_recv      ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_CANCEL   ] = data_cancel    ;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_EX2CANCEL] = data_cancel_ex2;
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_PREFETCH ] = data_prefetch  ; // TODO
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_LL       ] = data_ll        ; // TODO
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_SC       ] = data_sc        ; // TODO
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOM     ] = 1'b0           ; // TODO
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOMOP   ] = 5'b0           ; // TODO
   assign pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOMSRC  ] = `GRLEN'b0          ; // TODO

   assign data_rdata      = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_RDATA    ];
   assign data_addr_ok    = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_ADDROK   ];
   assign data_data_ok    = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_DATAOK   ];
   assign data_exccode    = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_EXCCODE  ];
   assign data_exception  = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_EXCEPTION];
   assign data_badvaddr   = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_BADVADDR ];
   assign data_req_empty  = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_REQEMPTY ];
   assign data_scsucceed  = dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_SCSUCCEED];


   
   assign cache_op_tag = {`D_TAG_LEN{1'b0}}; // TODO

   //csr
   wire  [`GRLEN-1:0]  csr_rdata;
   wire  [`LSOC1K_CSR_BIT-1 :0] csr_raddr;
   wire                except_shield;
   wire                int_except;
   wire                cp0_status_erl;
   wire                cp0_status_exl;
   wire                cp0_status_bev;
   wire                cp0_cause_iv;
   wire  [ 2:0]        cp0_config_k0;
   wire  [17:0]        cp0_ebase_exceptionbase;
   wire  [`GRLEN-1:0]  cp0_epc;
   wire  [`GRLEN-1:0]  eret_epc;
   wire  [`GRLEN-1:0]  csr_ebase;

   wire [`LSOC1K_CSR_OUTPUT_BIT-1:0] csr_output;
   
   // tlb
   wire        tlb_recv           ;
   wire [`LSOC1K_TLB_CODE_BIT-1:0] tlb_op   ;
   wire        tlb_finish         ;

   wire [`GRLEN-1:0] tlb2cp0_index      ;
   wire [`GRLEN-1:0] tlb2cp0_entryhi    ;
   wire [`GRLEN-1:0] tlb2cp0_entrylo0   ;
   wire [`GRLEN-1:0] tlb2cp0_entrylo1   ;
   wire [`GRLEN-1:0] tlb2cp0_asid       ;
   
   wire [`GRLEN-1:0] cp02tlb_index      ;
   wire [`GRLEN-1:0] cp02tlb_entryhi    ;
   wire [`GRLEN-1:0] cp02tlb_entrylo0   ;
   wire [`GRLEN-1:0] cp02tlb_entrylo1   ;
   wire [`GRLEN-1:0] cp02tlb_asid       ;
   wire [5       :0] cp02tlb_ecode      ;
   
   wire [`GRLEN-1:0] csr_dir_map_win0;
   wire [`GRLEN-1:0] csr_dir_map_win1;
   wire [`GRLEN-1:0] csr_crmd;

   tlb_wrapper u_tlb_wrapper(
      .clk               (clk              ),
      .reset             (~resetn          ),  

      .test_pc           (ifu_exu_pc_e     ),   // test

      .tlb_req           (tlb_req          ),
      .tlb_recv          (tlb_recv         ),
      .tlb_op            (tlb_op           ),
      .invtlb_vaddr      (data_wdata       ),
      .tlb_finish        (tlb_finish       ),

      .csr_index_out     (tlb2cp0_index    ),
      .csr_entryhi_out   (tlb2cp0_entryhi  ),
      .csr_entrylo0_out  (tlb2cp0_entrylo0 ),
      .csr_entrylo1_out  (tlb2cp0_entrylo1 ),
      .csr_asid_out      (tlb2cp0_asid     ),

      .csr_index_in      (cp02tlb_index    ),
      .csr_entryhi_in    (cp02tlb_entryhi  ),
      .csr_entrylo0_in   (cp02tlb_entrylo0 ),
      .csr_entrylo1_in   (cp02tlb_entrylo1 ),
      .csr_asid_in       (cp02tlb_asid     ),
      .csr_ecode_in      (cp02tlb_ecode    ),

      .csr_CRMD_PLV      (csr_crmd[`CRMD_PLV ]),
      .csr_CRMD_DA       (csr_crmd[`CRMD_DA  ]),
      .csr_CRMD_PG       (csr_crmd[`CRMD_PG  ]),
      .csr_CRMD_DATF     (csr_crmd[`CRMD_DATF]),
      .csr_CRMD_DATM     (csr_crmd[`CRMD_DATM]),
`ifdef LA64
      .csr_FTLBPS_FTPS   (csr_pgsize_ftps     ),
`endif
      .csr_dir_map_win0  (csr_dir_map_win0    ),
      .csr_dir_map_win1  (csr_dir_map_win1    ),

      .c_op              (cache_op         ),

      .i_req             (inst_tlb_req     ),
      .i_vaddr           (inst_tlb_vaddr   ),
      .i_cacop_req       (inst_tlb_cacop   ),
      .i_cache_rcv       (itlb_cache_recv  ),
      .i_finish          (itlb_finish      ),
      .i_hit             (itlb_hit         ),
      .i_paddr           (itlb_paddr       ),
      .i_uncached        (itlb_uncache     ),
      .i_exccode         (itlb_exccode     ),
      
      .d_req             (data_tlb_req     ),
      .d_wr              (data_tlb_wr      ),
      .d_vaddr           (data_tlb_vaddr   ),
      .d_cache_rcv       (dtlb_cache_recv  ),
      .d_no_trans        (dtlb_no_trans    ),
      .b_p_pgcl          (dtlb_p_pgcl      ),
      .d_finish          (dtlb_finish      ),
      .d_hit             (dtlb_hit         ),
      .d_paddr           (dtlb_paddr       ),
      .d_uncached        (dtlb_uncache     ),
      .d_exccode         (dtlb_exccode     )
      );

   
   wire [`GRLEN-1:0] wb_tlbr_entrance;

   
   csr csr(
      .clk                (clk             ),
      .resetn             (resetn          ),
      .intrpt             (8'd0/*intrpt    */      ), // TODO
      // tlb inst
      .tlbp               (csr_tlbp        ),
      .tlbr               (csr_tlbr        ),
      .ldpte              (1'b0            ), // TODO
      .tlbrp_index        (csr_tlbop_index ),
      .tlbr_entryhi       (tlb2cp0_entryhi ),
      .tlbr_entrylo0      (tlb2cp0_entrylo0),                
      .tlbr_entrylo1      (tlb2cp0_entrylo1),
      .tlbr_asid          (tlb2cp0_asid    ),
      //cache inst
      .cache_op_1         (cp0_cache_op_1  ),
      .cache_op_2         (cp0_cache_op_2  ),
      .cache_taglo_i      (cp0_cache_taglo ),
      .cache_taghi_i      (cp0_cache_taghi ),
      .cache_datalo_i     (cp0_cache_datalo),
      .cache_datahi_i     (cp0_cache_datahi),
      // csr inst
      .rdata              (csr_rdata       ),
      .raddr              (csr_raddr       ),
      .wdata              (csr_wdata       ),
      .waddr              (csr_waddr       ),
      .wen                (csr_wen         ),
      
      .llbctl             (llbctl          ),
      // exception
      //.wb_exception       (wb_exception    ),
      //.wb_exccode         (wb_exccode      ),
      //.wb_esubcode        (wb_esubcode     ),
      //.wb_epc             (wb_epc          ),
      //.wb_badvaddr        (wb_badvaddr     ),
      //.wb_badinstr        (wb_badinstr     ),
      //.wb_eret            (wb_eret         ),

      .wb_exception       (1'b0            ),
      .wb_exccode         (6'b0            ),
      .wb_esubcode        (1'b0            ),
      .wb_epc             (`GRLEN'b0       ),
      .wb_badvaddr        (`GRLEN'b0       ),
      .wb_badinstr        (32'b0           ),
      .wb_eret            (1'b0            ),

      .csr_output         (csr_output      ),
      
      .dmw0               (csr_dir_map_win0),
      .dmw1               (csr_dir_map_win1),
      .crmd               (csr_crmd        ),
`ifdef LA64
      .ftpgsize           (csr_pgsize_ftps ),
`endif

      .index_out          (cp02tlb_index   ),
      .entryhi_out        (cp02tlb_entryhi ),
      .entrylo0_out       (cp02tlb_entrylo0),
      .entrylo1_out       (cp02tlb_entrylo1),
      .asid_out           (cp02tlb_asid    ),
      .ecode_out          (cp02tlb_ecode   ),

      .epc_addr_out       (cp0_epc         ),
      .eret_epc_out       (eret_epc        ),// O,32
      .shield             (except_shield   ),
      .int_except         (int_except      ),

      .status_erl         (cp0_status_erl         ),
      .status_exl         (cp0_status_exl         ),// O, 1
      .status_bev         (cp0_status_bev         ),// O, 1
      .cause_iv           (cp0_cause_iv           ),// O, 1
      .config_k0          (cp0_config_k0          ),
      .ebase_exceptionbase(cp0_ebase_exceptionbase),
      .taglo0_out         (cp0_taglo0             ),
      .taghi0_out         (cp0_taghi0             ),
      .tlbrebase          (wb_tlbr_entrance       ),
      .ebase              (csr_ebase              )
      );
endmodule // cpu7
