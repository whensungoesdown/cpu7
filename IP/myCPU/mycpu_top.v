`include "common.vh"

module mycpu_top (
    input [7:0] intrpt,   //high active

    input aclk,
    input aresetn,   //low active

    //axi
    //ar
    output [ 3:0] arid   ,
    output [`PABITS-1:0] araddr , // 40  paddr length
    output [ 3:0] arlen  ,
    output [ 2:0] arsize ,
    output [ 1:0] arburst,
    output [ 1:0] arlock ,
    output [ 3:0] arcache,
    output [ 2:0] arprot ,
    output [ 3:0] arcmd  ,
    output [ 9:0] arcpuno,
    output        arvalid,
    input         arready,
    //r              
    input  [ 3:0] rid    ,
    input  [63:0] rdata  ,
    input  [ 1:0] rresp  ,
    input         rlast  ,
    input         rvalid ,
    output        rready ,
    //aw     
    output [ 3:0] awcmd   ,
    output [ 1:0] awstate ,
    output [ 3:0] awdirqid,
    output [ 3:0] awscway ,
    output [ 3:0] awid   ,
    output [`PABITS-1:0] awaddr , // 40  paddr length
    output [ 3:0] awlen  , 
    output [ 2:0] awsize ,
    output [ 1:0] awburst,
    output [ 1:0] awlock ,
    output [ 3:0] awcache,
    output [ 2:0] awprot ,
    output        awvalid,
    input         awready,
    //w          
    output [  3:0] wid    ,
    output [63 :0] wdata  ,
    output [  7:0] wstrb  ,
    output         wlast  ,
    output         wvalid ,
    input          wready ,
    //b              
    input  [ 3:0] bid    ,
    input  [ 1:0] bresp  ,
    input         bvalid ,
    output        bready ,

    `LSOC1K_DECL_BHT_RAMS_M,
    
    // icache ram
    input                           icache_init_finish,

    output [`I_WAY_NUM-1        :0] icache_tag_clk_en_o,
    output [`I_WAY_NUM-1        :0] icache_tag_en_o   ,
    output [`I_WAY_NUM-1        :0] icache_tag_wen_o  ,
    output [`I_INDEX_LEN-1      :0] icache_tag_addr_o ,
    output [`I_TAGARRAY_LEN-1   :0] icache_tag_wdata_o,
    input  [`I_IO_TAG_LEN-1  :0] icache_tag_rdata_i,

    output                          icache_lru_clk_en_o  ,
    output                          icache_lru_en_o      ,
    output [`I_LRU_WIDTH-1      :0] icache_lru_wen_o     ,
    output [`I_INDEX_LEN-1      :0] icache_lru_addr_o    ,
    output [`I_LRU_WIDTH-1      :0] icache_lru_wdata_o   ,
    input  [`I_LRU_WIDTH-1      :0] icache_lru_rdata_i   ,

    output [`I_WAY_NUM-1        :0] icache_data_clk_en_o ,
    output [`I_IO_EN_LEN-1   :0] icache_data_en_o     ,
    output [`I_WAY_NUM-1        :0] icache_data_wen_o    ,
    output [`I_INDEX_LEN-1      :0] icache_data_addr_o   ,
    output [`I_IO_WDATA_LEN-1:0] icache_data_wdata_o  ,
    input  [`I_IO_RDATA_LEN-1:0] icache_data_rdata_i  ,

    // dcache ram
    input                           dcache_init_finish,

    output [`D_WAY_NUM-1         :0] dcache_tag_clk_en_o,
    output [`D_WAY_NUM-1         :0] dcache_tag_en_o   ,
    output [`D_WAY_NUM-1         :0] dcache_tag_wen_o  ,
    output [`D_INDEX_LEN-1    :0] dcache_tag_addr_o ,
    output [`D_TAGARRAY_LEN-1    :0] dcache_tag_wdata_o,
    input  [`D_RAM_TAG_LEN-1  :0] dcache_tag_rdata_i,

    output                           dcache_lrud_clk_en_o  ,
    output                           dcache_lrud_en_o      ,
    output [`D_LRUD_WIDTH-1      :0] dcache_lrud_wen_o     ,
    output [`D_INDEX_LEN-1    :0] dcache_lrud_addr_o    ,
    output [`D_LRUD_WIDTH-1      :0] dcache_lrud_wdata_o   ,
    input  [`D_LRUD_WIDTH-1      :0] dcache_lrud_rdata_i   ,

    output [`D_WAY_NUM-1         :0] dcache_data_clk_en_o   ,
    output [`D_RAM_EN_LEN-1   :0] dcache_data_en_o       ,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank0_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank1_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank2_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank3_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank4_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank5_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank6_o,
    output [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank7_o,
    output [`D_RAM_ADDR_LEN-1 :0] dcache_data_addr_o     ,
    output [`D_RAM_WDATA_LEN-1:0] dcache_data_wdata_o    ,
    input  [`D_RAM_RDATA_LEN-1:0] dcache_data_rdata_i    ,

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
    wire data_cache;
    
    wire [3:0] arlen_h;
    wire [3:0] awlen_h;

    wire                  tlb_req         ;
    // cache op
      // Cache req
    wire                  cache_req       ;
    wire [ 4          :0] cache_op        ;
    wire [`D_TAG_LEN-1:0] cache_op_tag    ;
    wire [`GRLEN-1    :0] cache_op_addr   ;
    wire                  cache_op_addr_ok;
    wire                  cache_op_ok     ;
    wire                  cache_op_exception;
      // iCache req
    wire       icache_op_req    ;
    wire [2:0] icache_op        ;
    wire       icache_op_addr_ok;
    wire       icache_op_ok     ;
    wire       icache_op_error  ;
    wire [5:0] icache_op_exccode;
    wire [`GRLEN-1:0] icache_op_badvaddr;

      // dCache req
    wire       dcache_op_req    ;
    wire [2:0] dcache_op        ;
    wire       dcache_op_addr_ok;
    wire       dcache_op_ok     ;
    wire       dcache_op_error  ;

    // TODO:
    assign icache_op_req               = cache_req     && cache_op[2:0] == 3'b000;
    assign icache_op[`IDX_ST_TAG]      = cache_op[4:3] == 2'b00;
    assign icache_op[`IDX_INV]         = cache_op[4:3] == 2'b01 || cache_op[4:3] == 2'b11;
    assign icache_op[`HIT_INV]         = cache_op[4:3] == 2'b10; // Regard cache_op[4:3] == 2'b11 as HIT_INV now!!!

    // TODO:
    assign dcache_op_req               = cache_req     && cache_op[2:0] != 3'b000;//cache_op[2:0] == 3'b001; // Only look at op[0] now!!!
    assign dcache_op[`IDX_ST_TAG]      = cache_op[4:3] == 2'b00 && cache_op[2:0] == 3'b001;
    assign dcache_op[`IDX_INV_WB]      = (cache_op[4:3] == 2'b01 || cache_op[4:3] == 2'b11) && cache_op[2:0] == 3'b001 || cache_op[2:0] != 3'b001;//cache_op[4:3] == 2'b01;
    assign dcache_op[`HIT_INV_WB]      = cache_op[4:3] == 2'b10 && cache_op[2:0] == 3'b001;

    assign cache_op_addr               = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ADDR     ];

    assign cache_op_addr_ok            = icache_op_addr_ok | dcache_op_addr_ok;
    assign cache_op_ok                 = icache_op_ok      | dcache_op_ok;

    assign icache_op_exccode           = (cpu_inst_exccode == `EXC_PIF)? `EXC_PIL : cpu_inst_exccode;

    // cpu cache req
      // icache req
    wire         cpu_inst_req      ;
    wire [`GRLEN-1:0] cpu_inst_addr     ;
    wire         cpu_inst_cancel   ;
    wire         cpu_inst_addr_ok  ;
    wire [127:0] cpu_inst_rdata    ;
    wire         cpu_inst_recv     ;
    wire         cpu_inst_valid    ;
    wire [  1:0] cpu_inst_count    ;
    wire         cpu_inst_uncache  ;
    wire         cpu_inst_exception;
    wire [  5:0] cpu_inst_exccode  ;
    
    wire         cpu_inst_tlb_req  ;
    wire [`GRLEN-1:0] cpu_inst_tlb_vaddr;
    wire         cpu_inst_tlb_cacop;

    wire                       csr_wen  ;
    wire [`LSOC1K_CSR_BIT-1:0] csr_waddr;
    wire [`GRLEN-1         :0] csr_wdata;
    wire                       wb_eret  ;
    wire [`GRLEN-1         :0] llbctl   ;
    wire [`PIPELINE2DCACHE_BUS_WIDTH-1:0] pipeline2dcache_bus;
    wire [`DCACHE2PIPELINE_BUS_WIDTH-1:0] dcache2pipeline_bus;

    // interface
      // dcache
    wire                     d_rd_req    ;
    wire [`PABITS-1      :0] d_rd_addr   ;
    wire [             3 :0] d_rd_id     ;
    wire [             3 :0] d_rd_arcmd  ;
    wire                     d_rd_uncache;
    wire                     d_rd_ready  ;
    wire                     d_ret_valid ;
    wire                     d_ret_last  ;
    wire [ 63            :0] d_ret_data  ;
    wire [  3            :0] d_ret_rid   ;
    wire [  1            :0] d_ret_rstate;
    wire [  3            :0] d_ret_rscway;

    wire                    d_wr_req     ;
    wire [`PABITS-1     :0] d_wr_addr    ;
    wire [`D_LINE_SIZE_b-1:0] d_wr_data    ;
    wire [3             :0] d_wr_awcmd   ;
    wire [1             :0] d_wr_awstate ;
    wire [3             :0] d_wr_awdirqid;
    wire [3             :0] d_wr_awscway ;
    wire [1             :0] d_wr_pgcl    ;
    wire [`WSTRB_WIDTH-1:0] d_wr_uc_wstrb;
    wire [`WR_FMT_LEN-1 :0] d_wr_fmt   ;
    wire                    d_wr_ready   ;
    wire                    vic_not_full ;
    wire                    vic_empty    ;

      // icache
    wire                    i_rd_req   ;
    wire [`PABITS-1     :0] i_rd_addr  ;
    wire [3             :0] i_rd_arcmd ;
    wire                    i_rd_uncache;
    wire                    i_rd_ready ;
    wire                    i_ret_valid;
    wire                    i_ret_last ;
    wire [ 63           :0] i_ret_data ;
    wire [  1           :0] i_ret_rstate;
    wire [  3           :0] i_ret_rscway;

    wire                    i_wr_req     ;
    wire [`PABITS-1     :0] i_wr_addr    ;
    wire [`I_LINE_SIZE_b-1:0] i_wr_data    ;
    wire [3             :0] i_wr_awcmd   ;
    wire [1             :0] i_wr_awstate ;
    wire [3             :0] i_wr_awdirqid;
    wire [3             :0] i_wr_awscway ;
    wire [1             :0] i_wr_pgcl    ;
    wire [`WR_FMT_LEN-1:0] i_wr_fmt   ;
    wire                    i_wr_ready   ;

    wire                    dcache_ud_req ;
    wire                    dcache_ud_wr  ;
    wire [`PABITS-1     :0] dcache_ud_addr;
    wire [3             :0] dcache_ud_id  ;
    wire [7             :0] dcache_ud_wstrb;
    wire [63            :0] dcache_ud_wdata;
    wire                    dcache_ud_addr_ok;
    wire                    dcache_ud_vacancy;

    // itlb
    wire        itlb_finish    ;
    wire        itlb_hit       ;
    wire [`PABITS-1:0] itlb_paddr;
    wire        itlb_cache_recv;
    wire        itlb_uncache   ;
    wire [ 5:0] itlb_exccode   ;
    
    // dtlb
    wire        dtlb_finish    ;
    wire        dtlb_hit       ;
    wire [`PABITS-1:0] dtlb_paddr;
    wire        dtlb_cache_recv;
    wire        dtlb_no_trans  ;
    wire        dtlb_p_pgcl    ;
    wire        data_tlb_req   ;
    wire        data_tlb_wr        ;
    wire [`GRLEN-1:0] data_tlb_vaddr     ;
    wire        dtlb_uncache   ;
    wire [ 5:0] dtlb_exccode   ;
 
    // ex req
    wire                     i_ex_req       ;
    wire [ 2             :0] i_ex_req_op    ;
    wire [`PABITS-1      :0] i_ex_req_paddr ;
    wire [9              :0] i_ex_req_cpuno ;
    wire [1              :0] i_ex_req_pgcl  ;
    wire [3              :0] i_ex_req_dirqid;
    wire                     i_ex_req_recv  ;

    wire                     d_ex_req       ;
    wire [ 2             :0] d_ex_req_op    ;
    wire [`PABITS-1      :0] d_ex_req_paddr ;
    wire [9              :0] d_ex_req_cpuno ;
    wire [1              :0] d_ex_req_pgcl  ;
    wire [3              :0] d_ex_req_dirqid;
    wire                     d_ex_req_recv  ;

   // uty: test
   cpu7 cpu(
//    lsoc1000_mainpipe cpu(
        .clk              (aclk                 ),
        .resetn           (aresetn              ),
        .intrpt						(intrpt		            ),

        `LSOC1K_CONN_BHT_RAMS,

        .inst_req         (cpu_inst_req         ),
        .inst_addr        (cpu_inst_addr        ),
        .inst_cancel      (cpu_inst_cancel      ),
        .inst_addr_ok     (cpu_inst_addr_ok     ),
        .inst_rdata       (cpu_inst_rdata       ),
        .inst_valid       (cpu_inst_valid       ),
        .inst_count       (cpu_inst_count       ),
        .inst_uncache     (cpu_inst_uncache     ),
        .inst_exccode     (cpu_inst_exccode     ),
        .inst_exception   (cpu_inst_exception   ),

        .inst_tlb_req     (cpu_inst_tlb_req     ),
        .inst_tlb_vaddr   (cpu_inst_tlb_vaddr   ),
        .inst_tlb_cacop   (cpu_inst_tlb_cacop   ),

        .pipeline2dcache_bus (pipeline2dcache_bus),
        .dcache2pipeline_bus (dcache2pipeline_bus),
        .csr_wen             (csr_wen            ),
        .csr_waddr           (csr_waddr          ),
        .csr_wdata           (csr_wdata          ),
        .wb_eret             (wb_eret            ),
        .llbctl              (llbctl             ),

        .tlb_req          (tlb_req              ),
        .cache_req        (cache_req            ),
        .cache_op         (cache_op             ),
        .cache_op_tag     (cache_op_tag         ),
        .cache_op_recv    (cache_op_addr_ok     ),
        .cache_op_finish  (cache_op_ok          ),

        .itlb_paddr       (itlb_paddr           ),// O, 48
        .itlb_exccode     (itlb_exccode         ),// O, 5
        .itlb_finish      (itlb_finish          ),// O, 1
        .itlb_hit         (itlb_hit             ),// O, 1
        .itlb_uncache     (itlb_uncache         ),// O, 1
        .itlb_cache_recv  (itlb_cache_recv      ),// I, 1

        .dtlb_paddr       (dtlb_paddr           ),// O, 32
        .dtlb_exccode     (dtlb_exccode         ),// O, 5
        .dtlb_finish      (dtlb_finish          ),// O, 1
        .dtlb_hit         (dtlb_hit             ),// O, 1
        .dtlb_uncache     (dtlb_uncache         ),// O, 1、
        .data_tlb_req     (data_tlb_req         ),
        .data_tlb_wr      (data_tlb_wr          ),
        .data_tlb_vaddr   (data_tlb_vaddr       ),
        .dtlb_cache_recv  (dtlb_cache_recv      ),// I, 1
        .dtlb_no_trans    (dtlb_no_trans        ),
        .dtlb_p_pgcl      (dtlb_p_pgcl          ),
        
        .debug0_wb_pc      (debug0_wb_pc        ),// O, 64 
        .debug0_wb_rf_wen  (debug0_wb_rf_wen    ),// O, 1  
        .debug0_wb_rf_wnum (debug0_wb_rf_wnum   ),// O, 5  
        .debug0_wb_rf_wdata(debug0_wb_rf_wdata  ),// O, 64 
        .debug1_wb_pc      (debug1_wb_pc        ),// O, 64 
        .debug1_wb_rf_wen  (debug1_wb_rf_wen    ),// O, 1  
        .debug1_wb_rf_wnum (debug1_wb_rf_wnum   ),// O, 5  
        .debug1_wb_rf_wdata(debug1_wb_rf_wdata  ) // O, 64 
    );

    cache_interface u_cache_interface
    (
        ////basic
        .clk              (aclk               ), 
        .resetn           (aresetn            ), 

        .test_pc (debug0_wb_pc),

         // icache
        .i_rd_req         (i_rd_req           ),
        .i_rd_addr        (i_rd_addr          ),
        .i_rd_arcmd       (i_rd_arcmd         ),
        .i_rd_uncache     (i_rd_uncache       ),
        .i_rd_ready       (i_rd_ready         ),
        .i_ret_valid      (i_ret_valid        ),
        .i_ret_last       (i_ret_last         ),
        .i_ret_data       (i_ret_data         ),
        .i_ret_rstate     (i_ret_rstate       ),
        .i_ret_rscway     (i_ret_rscway       ),

        .i_wr_req         (i_wr_req           ),
        .i_wr_addr        (i_wr_addr          ),
        .i_wr_data        (i_wr_data          ),
        .i_wr_awcmd       (i_wr_awcmd         ),
        .i_wr_awstate     (i_wr_awstate       ),
        .i_wr_awdirqid    (i_wr_awdirqid      ),
        .i_wr_awscway     (i_wr_awscway       ),
        .i_wr_pgcl        (i_wr_pgcl          ),
        .i_wr_fmt         (i_wr_fmt           ),
        .i_wr_ready       (i_wr_ready         ),

        .i_ex_req         (i_ex_req           ),
        .i_ex_req_op      (i_ex_req_op        ),
        .i_ex_req_paddr   (i_ex_req_paddr     ),
        .i_ex_req_cpuno   (i_ex_req_cpuno     ),
        .i_ex_req_pgcl    (i_ex_req_pgcl      ),
        .i_ex_req_dirqid  (i_ex_req_dirqid    ),
        .i_ex_req_recv    (i_ex_req_recv      ),

        // dcache
        .d_rd_req         (d_rd_req           ),
        .d_rd_addr        (d_rd_addr          ),
        .d_rd_id          (d_rd_id            ),
        .d_rd_arcmd       (d_rd_arcmd         ),
        .d_rd_uncache     (d_rd_uncache       ),
        .d_rd_ready       (d_rd_ready         ),
        .d_ret_valid      (d_ret_valid        ),
        .d_ret_last       (d_ret_last         ),
        .d_ret_data       (d_ret_data         ),
        .d_ret_rid        (d_ret_rid          ),
        .d_ret_rstate     (d_ret_rstate       ),
        .d_ret_rscway     (d_ret_rscway       ),

        .d_wr_req         (d_wr_req           ),
        .d_wr_addr        (d_wr_addr          ),
        .d_wr_data        (d_wr_data          ),
        .d_wr_awcmd       (d_wr_awcmd         ),
        .d_wr_awstate     (d_wr_awstate       ),
        .d_wr_awdirqid    (d_wr_awdirqid      ),
        .d_wr_awscway     (d_wr_awscway       ),
        .d_wr_pgcl        (d_wr_pgcl          ),
        .d_wr_uc_wstrb    (d_wr_uc_wstrb      ),
        .d_wr_fmt         (d_wr_fmt           ),
        .d_wr_ready       (d_wr_ready         ),
        .vic_not_full     (vic_not_full       ),
        .vic_empty        (vic_empty          ),

        .d_ex_req         (d_ex_req           ),
        .d_ex_req_op      (d_ex_req_op        ),
        .d_ex_req_paddr   (d_ex_req_paddr     ),
        .d_ex_req_cpuno   (d_ex_req_cpuno     ),
        .d_ex_req_pgcl    (d_ex_req_pgcl      ),
        .d_ex_req_dirqid  (d_ex_req_dirqid    ),
        .d_ex_req_recv    (d_ex_req_recv      ),

        .inv_req     ( 1'b0),
        .inv_addr    (`PABITS'b0),

        //  axi_control
        // ar
        .arid         (arid    ),
        .araddr       (araddr  ),
        .arlen        ({arlen_h, arlen}),
        .arsize       (arsize  ),
        .arburst      (arburst ),
        .arlock       (arlock  ),
        .arcache      (arcache ),
        .arprot       (arprot  ),
        .arcmd        (arcmd   ),
        .arcpuno      (arcpuno ),
        .arvalid      (arvalid ),
        .arready      (arready ),
        //r              
        .rrequest     (1'b0    ),
        .rid          (rid     ),
        .rdata        (rdata   ),
        .rstate       (2'b0    ),
        .rscway       (4'b0    ),
        .rresp        (rresp   ),
        .rlast        (rlast   ),
        .rvalid       (rvalid  ),
        .rready       (rready  ),
        //aw               
        .awcmd        (awcmd   ),
        .awstate      (awstate ),
        .awdirqid     (awdirqid),
        .awscway      (awscway ),
        .awid         (awid    ),
        .awaddr       (awaddr  ),
        .awlen        ({awlen_h, awlen}),
        .awsize       (awsize  ),
        .awburst      (awburst ),
        .awlock       (awlock  ),
        .awcache      (awcache ),
        .awprot       (awprot  ),
        .awvalid      (awvalid ),
        .awready      (awready ),
        //w               
        .wid          (wid     ),
        .wdata        (wdata   ),
        .wstrb        (wstrb   ),
        .wlast        (wlast   ),
        .wvalid       (wvalid  ),
        .wready       (wready  ),
        //b              
        .bid          (bid     ),
        .bresp        (bresp   ),
        .bvalid       (bvalid  ),
        .bready       (bready  )
    );

    //dcache
    dcache u_dcache
    (
        .clk(aclk), 
        .resetn(aresetn), 

        .init_finish      (dcache_init_finish),

        .tlb_req          (tlb_req             ),

        .cache_op_req     (dcache_op_req       ),
        .cache_op         (dcache_op           ),
        .cache_op_tag     (cache_op_tag        ),
        .cache_op_addr    (cache_op_addr       ),
        .cache_op_addr_ok (dcache_op_addr_ok   ),
        .cache_op_ok      (dcache_op_ok        ),
        .cache_op_error   (dcache_op_error     ),

        .icache_op_recv     (icache_op_addr_ok ),
        .icache_op_finish   (icache_op_ok      ),
        .icache_op_error    (icache_op_error   ),
        .icache_op_exccode  (icache_op_exccode ),
        .icache_op_badvaddr (icache_op_badvaddr),

        .tlb_ptag          (dtlb_paddr[`D_TAG_BITS]),
        .tlb_finish        (dtlb_finish         ),
        .tlb_hit           (dtlb_hit            ),
        .tlb_uncache       (dtlb_uncache        ),
        .tlb_exccode       (dtlb_exccode        ),
        .data_tlb_no_trans (dtlb_no_trans       ),
        .data_tlb_p_pgcl   (dtlb_p_pgcl         ),
        .data_tlb_req      (data_tlb_req        ),
        .data_tlb_wr       (data_tlb_wr         ),
        .data_tlb_vaddr    (data_tlb_vaddr      ),
        .tlb_cache_recv    (dtlb_cache_recv     ),

        .ud_wr_vacancy    (1'b1                ), // TODO:

        ////cpu_control
        //---------------llsc----------------
        .csr_wen             (csr_wen            ),
        .csr_waddr           (csr_waddr          ),
        .csr_wdata           (csr_wdata          ),
        .wb_eret             (wb_eret            ),
        .llbctl              (llbctl             ),
        //------data request interface-------
        .pipeline2dcache_bus (pipeline2dcache_bus),
        .dcache2pipeline_bus (dcache2pipeline_bus),

        .rd_req            (d_rd_req                 ),
        .rd_addr           (d_rd_addr                ),
        .rd_id             (d_rd_id                  ),
        .rd_arcmd          (d_rd_arcmd               ),
        .rd_uncache        (d_rd_uncache             ),
        .rd_arready        (d_rd_ready               ),
        .ret_valid         (d_ret_valid              ),
        .ret_last          (d_ret_last               ),
        .ret_data          (d_ret_data               ),
        .ret_data_id       (d_ret_rid                ),
        .ret_rstate        (d_ret_rstate             ),
        .ret_rscway        (d_ret_rscway             ),

        .wr_req            (d_wr_req                 ),
        .wr_addr           (d_wr_addr                ),
        .wr_data           (d_wr_data                ),
        .wr_awcmd          (d_wr_awcmd               ),
        .wr_awstate        (d_wr_awstate             ),
        .wr_awdirqid       (d_wr_awdirqid            ),
        .wr_awscway        (d_wr_awscway             ),
        .wr_pgcl           (d_wr_pgcl                ),
        .wr_uc_wstrb       (d_wr_uc_wstrb            ),
        .wr_fmt            (d_wr_fmt                 ),
        .wr_ready          (d_wr_ready               ),
        .vic_not_full      (vic_not_full             ),
        .vic_empty         (vic_empty                ),

        .ex_req            (d_ex_req                 ),
        .ex_req_op         (d_ex_req_op              ),
        .ex_req_paddr      (d_ex_req_paddr           ),
        .ex_req_cpuno      (d_ex_req_cpuno           ),
        .ex_req_pgcl       (d_ex_req_pgcl            ),
        .ex_req_dirqid     (d_ex_req_dirqid          ),
        .ex_req_recv       (d_ex_req_recv            ),

        // ram signal
        .tag_ram_clk_en      (dcache_tag_clk_en_o    ),
        .tag_ram_en          (dcache_tag_en_o        ),
        .tag_ram_wen         (dcache_tag_wen_o       ),
        .tag_ram_addr        (dcache_tag_addr_o      ),
        .tag_ram_wdata       (dcache_tag_wdata_o     ),
        .tag_ram_rdata       (dcache_tag_rdata_i     ),

        .lrud_clk_en_o       (dcache_lrud_clk_en_o   ),
        .lrud_en_o           (dcache_lrud_en_o       ),
        .lrud_wen_o          (dcache_lrud_wen_o      ),
        .lrud_addr_o         (dcache_lrud_addr_o     ),
        .lrud_wdata_o        (dcache_lrud_wdata_o    ),
        .lrud_rdata_i        (dcache_lrud_rdata_i    ),

        .data_ram_clk_en     (dcache_data_clk_en_o   ),
        .data_ram_en         (dcache_data_en_o       ),
        .data_ram_wen_bank0  (dcache_data_wen_bank0_o),
        .data_ram_wen_bank1  (dcache_data_wen_bank1_o),
        .data_ram_wen_bank2  (dcache_data_wen_bank2_o),
        .data_ram_wen_bank3  (dcache_data_wen_bank3_o),
        .data_ram_wen_bank4  (dcache_data_wen_bank4_o),
        .data_ram_wen_bank5  (dcache_data_wen_bank5_o),
        .data_ram_wen_bank6  (dcache_data_wen_bank6_o),
        .data_ram_wen_bank7  (dcache_data_wen_bank7_o),
        .data_ram_addr       (dcache_data_addr_o     ),
        .data_ram_wdata      (dcache_data_wdata_o    ),
        .data_ram_rdata      (dcache_data_rdata_i    )
    );

    icache u_icache
    (
        .clk(aclk),   
        .resetn(aresetn),   

        .cache_op_req     (icache_op_req       ),
        .cache_op         (icache_op           ),
        .cache_op_tag     (cache_op_tag        ),
        .cache_op_addr    (cache_op_addr       ),
        .cache_op_addr_ok (icache_op_addr_ok   ),
        .cache_op_ok      (icache_op_ok        ),
        .cache_op_error   (icache_op_error     ),
        .cache_op_badvaddr(icache_op_badvaddr  ),

        .tlb_ptag         (itlb_paddr[`I_TAG_BITS]),
        .tlb_finish       (itlb_finish         ), 
        .tlb_hit          (itlb_hit            ), 
        .tlb_cache_recv   (itlb_cache_recv     ),
        .tlb_uncache      (itlb_uncache        ), 
        .tlb_exccode      (itlb_exccode        ),

        ////cpu_control
        //------inst request interface-------
        .inst_req          (cpu_inst_req & icache_init_finish),
        .inst_addr         (cpu_inst_addr      ),
        .inst_cancel       (cpu_inst_cancel    ),
        .inst_addr_ok      (cpu_inst_addr_ok   ),
        .inst_rdata        (cpu_inst_rdata     ),
        .inst_valid        (cpu_inst_valid     ),
        .inst_count        (cpu_inst_count     ),
        .inst_uncache      (cpu_inst_uncache   ),
        .inst_exccode      (cpu_inst_exccode   ),
        .inst_exception    (cpu_inst_exception ),

        .inst_tlb_req      (cpu_inst_tlb_req   ),
        .inst_tlb_vaddr    (cpu_inst_tlb_vaddr ),
        .inst_tlb_cacop    (cpu_inst_tlb_cacop ),

        // interact with MISS queue
        .rd_req            (i_rd_req           ),
        .rd_addr           (i_rd_addr          ),
        .rd_arcmd          (i_rd_arcmd         ),
        .rd_uncache        (i_rd_uncache       ),
        .rd_ready          (i_rd_ready         ),
        .ret_valid         (i_ret_valid        ),
        .ret_last          (i_ret_last         ),
        .ret_data          (i_ret_data         ),
        .ret_rstate        (i_ret_rstate       ),
        .ret_rscway        (i_ret_rscway       ),

        .wr_req            (i_wr_req           ),
        .wr_addr           (i_wr_addr          ),
        .wr_data           (i_wr_data          ),
        .wr_awcmd          (i_wr_awcmd         ),
        .wr_awstate        (i_wr_awstate       ),
        .wr_awdirqid       (i_wr_awdirqid      ),
        .wr_awscway        (i_wr_awscway       ),
        .wr_pgcl           (i_wr_pgcl          ),
        .wr_fmt            (i_wr_fmt           ),
        .wr_ready          (i_wr_ready         ),

        .ex_req            (i_ex_req           ),
        .ex_req_op         (i_ex_req_op        ),
        .ex_req_paddr      (i_ex_req_paddr     ),
        .ex_req_cpuno      (i_ex_req_cpuno     ),
        .ex_req_pgcl       (i_ex_req_pgcl      ),
        .ex_req_dirqid     (i_ex_req_dirqid    ),
        .ex_req_recv       (i_ex_req_recv      ),

        // ram signal
        .tag_clk_en_o      (icache_tag_clk_en_o  ),
        .tag_en_o          (icache_tag_en_o      ),
        .tag_wen_o         (icache_tag_wen_o     ),
        .tag_addr_o        (icache_tag_addr_o    ),
        .tag_wdata_o       (icache_tag_wdata_o   ),
        .tag_rdata_i       (icache_tag_rdata_i   ),

        .lru_clk_en_o      (icache_lru_clk_en_o  ),
        .lru_en_o          (icache_lru_en_o      ),
        .lru_wen_o         (icache_lru_wen_o     ),
        .lru_addr_o        (icache_lru_addr_o    ),
        .lru_wdata_o       (icache_lru_wdata_o   ),
        .lru_rdata_i       (icache_lru_rdata_i   ),

        .data_clk_en_o     (icache_data_clk_en_o ),
        .data_en_o         (icache_data_en_o     ),
        .data_wen_o        (icache_data_wen_o    ),
        .data_addr_o       (icache_data_addr_o   ),
        .data_wdata_o      (icache_data_wdata_o  ),
        .data_rdata_i      (icache_data_rdata_i  )
    );

endmodule
