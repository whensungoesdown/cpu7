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
    output                       csr_wen  , // uty: todo need remove these csr_
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

   // exception
   wire [`GRLEN-1:0]                 exu_ifu_eentry;
   wire                              exu_ifu_except;
   // ertn
   wire [`GRLEN-1:0]                 exu_ifu_era;
   wire                              exu_ifu_ertn_e;
   
   
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

      // exception
      .exu_ifu_eentry          (exu_ifu_eentry       ),
      .exu_ifu_except          (exu_ifu_except       ),
      // ertn
      .exu_ifu_era             (exu_ifu_era          ),
      .exu_ifu_ertn_e          (exu_ifu_ertn_e       ),

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

      //exception
      .exu_ifu_eentry          (exu_ifu_eentry       ),
      .exu_ifu_except          (exu_ifu_except       ),
      //ertn
      .exu_ifu_era             (exu_ifu_era          ),
      .exu_ifu_ertn_e          (exu_ifu_ertn_e       ),

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



   
   //
   // a trick to get rid of the tlb and make the cache work
   //
   
   assign cache_op_tag = {`D_TAG_LEN{1'b0}}; // TODO


//   assign itlb_finish  = 1'b1;
   dff_s #(1) itlb_finish_reg (
      .din (inst_tlb_req),
      .clk (clk),
      .q   (itlb_finish),
      .se(), .si(), .so());
   assign itlb_hit     = 1'b1;
   assign itlb_uncache = 1'b0;
//   assign itlb_paddr   = inst_tlb_vaddr[`PABITS-1:0];
   dff_s #(`PABITS) itlb_paddr_reg (
      .din (inst_tlb_vaddr[`PABITS-1:0]),
      .clk (clk),
      .q   (itlb_paddr),
      .se(), .si(), .so());

   
   dff_s #(1) dtlb_finish_reg (
      .din (data_tlb_req),
      .clk (clk),
      .q   (dtlb_finish),
      .se(), .si(), .so());
//   assign dtlb_finish  = 1'b1;
   assign dtlb_hit     = 1'b1;
   assign dtlb_uncache = 1'b0;
   dff_s #(`PABITS) dtlb_paddr_reg (
      .din (data_tlb_vaddr[`PABITS-1:0]),
      .clk (clk),
      .q   (dtlb_paddr),
      .se(), .si(), .so());
   //assign dtlb_paddr   = data_tlb_vaddr[`PABITS-1:0]; 


   
endmodule // cpu7
