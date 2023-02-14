`include "common.vh"

module dcache
(
    input         clk,
    input         resetn,
    input         init_finish   ,

    output [`D_WAY_NUM-1      :0] tag_ram_en    ,
    output reg [`D_WAY_NUM-1  :0] tag_ram_clk_en,
    output [`D_WAY_NUM-1      :0] tag_ram_wen   ,
    output [`D_INDEX_LEN-1    :0] tag_ram_addr  ,
    output [`D_TAGARRAY_LEN-1 :0] tag_ram_wdata ,
    input  [`D_RAM_TAG_LEN-1  :0] tag_ram_rdata ,

    output reg                    lrud_clk_en_o  ,
    output                        lrud_en_o      ,
    output [`D_LRUD_WIDTH-1   :0] lrud_wen_o     ,
    output [`D_INDEX_LEN-1    :0] lrud_addr_o    ,
    output [`D_LRUD_WIDTH-1   :0] lrud_wdata_o   ,
    input  [`D_LRUD_WIDTH-1   :0] lrud_rdata_i   ,

    output [`D_RAM_EN_LEN-1   :0] data_ram_en       ,
    output reg [`D_WAY_NUM-1  :0] data_ram_clk_en   ,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank0,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank1,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank2,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank3,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank4,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank5,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank6,
    output [`D_RAM_WEN_LEN-1  :0] data_ram_wen_bank7,
    output [`D_RAM_ADDR_LEN-1 :0] data_ram_addr     ,
    output [`D_RAM_WDATA_LEN-1:0] data_ram_wdata    ,
    input  [`D_RAM_RDATA_LEN-1:0] data_ram_rdata    ,

    //  interact with CPU
    //-----------llsc-----------
    input                         csr_wen  ,
    input  [`LSOC1K_CSR_BIT-1 :0] csr_waddr,
    input  [`GRLEN-1          :0] csr_wdata,
    input                         wb_eret  ,
    output [`GRLEN-1          :0] llbctl   ,
    //--------sram-like---------
    input  [`PIPELINE2DCACHE_BUS_WIDTH-1:0] pipeline2dcache_bus,
    output [`DCACHE2PIPELINE_BUS_WIDTH-1:0] dcache2pipeline_bus,

    input                         tlb_req         ,

    input                         cache_op_req    ,
    input  [2                 :0] cache_op        , 
    input  [`D_TAG_LEN-1      :0] cache_op_tag    , 
    input  [`GRLEN-1          :0] cache_op_addr   ,
    output                        cache_op_addr_ok,
    output                        cache_op_ok     ,
    output                        cache_op_error  ,

    input                         icache_op_recv  ,
    input                         icache_op_finish,
    input                         icache_op_error ,
    input [5                  :0] icache_op_exccode ,
    input [`GRLEN-1           :0] icache_op_badvaddr,

    // interact with dTLB
    input  [`D_TAG_LEN-1      :0] tlb_ptag      ,
    input                         tlb_finish    ,
    input                         tlb_hit       ,
    input                         tlb_uncache   ,
    input  [5                 :0] tlb_exccode   ,
    output                        data_tlb_req  ,
    output                        data_tlb_wr   ,
    output [`GRLEN-1          :0] data_tlb_vaddr,
    output                        data_tlb_no_trans,
    output                        data_tlb_p_pgcl,
    output                        tlb_cache_recv,

    input                         ud_wr_vacancy,  // TODO:

    input                         ex_req       ,
    input  [`EX_OP_WIDTH-1    :0] ex_req_op    ,
    input  [`PABITS-1         :0] ex_req_paddr ,
    input  [9                 :0] ex_req_cpuno ,
    input  [1                 :0] ex_req_pgcl  ,
    input  [3                 :0] ex_req_dirqid,
    output                        ex_req_recv  ,

    output                        rd_req      ,
    output [`PABITS-1         :0] rd_addr     ,
    output [  3               :0] rd_id       ,
    output [  3               :0] rd_arcmd    ,
    output                        rd_uncache  ,
    input                         rd_arready  ,
    input                         ret_valid   ,
    input                         ret_last    ,
    input  [ 63               :0] ret_data    ,
    input  [  3               :0] ret_data_id ,
    input  [`STATE_LEN-1      :0] ret_rstate  ,
    input  [`SCWAY_LEN-1      :0] ret_rscway  ,

    output                        wr_req      ,
    output [`PABITS-1         :0] wr_addr     ,
    output [`D_LINE_SIZE_b-1  :0] wr_data     ,
    output [3                 :0] wr_awcmd    ,
    output [1                 :0] wr_awstate  ,
    output [3                 :0] wr_awdirqid ,
    output [3                 :0] wr_awscway  ,
    output [1                 :0] wr_pgcl     ,
    output [`WSTRB_WIDTH-1    :0] wr_uc_wstrb ,
    output [`WR_FMT_LEN-1     :0] wr_fmt      , 
    input                         wr_ready    ,
    input                         vic_not_full,
    input                         vic_empty   
);

wire   rst;
assign rst = !resetn;

//  -------------------------- BUS -------------------------
  // input
wire                    pipeline_data_req ;
wire                    pipeline_data_wr  ;
wire [`GRLEN-1      :0] pipeline_data_addr;
wire                    pipeline_prefetch ;
wire                    pipeline_ex2_cancel;

wire                    data_req      ;
wire                    data_wr       ;
wire [`WSTRB_WIDTH-1:0] data_wstrb    ;
wire [`GRLEN-1      :0] data_addr     ;
wire [`GRLEN-1      :0] data_wdata    ;
wire                    data_recv     ;
wire                    data_cancel   ;
wire                    ex2_cancel    ;
wire                    data_prefetch ;
wire [`GRLEN-1      :0] data_pc       ;
wire                    ll_req        ;
wire                    sc_req        ;
wire                    atom_req      ;
wire [ 4            :0] atom_op       ;
wire [`GRLEN-1      :0] atom_src      ;

  // output
wire [`GRLEN-1:0] data_rdata    ;
wire              data_addr_ok  ;
wire              data_data_ok  ;
wire [       5:0] data_exccode  ;
wire              data_exception;
wire [`GRLEN-1:0] data_badvaddr ;
wire              req_empty     ;
wire              sc_succeed    ;
wire              sc_fail       ;


assign pipeline_data_req   = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_REQ      ];
assign pipeline_data_wr    = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WR       ];
assign data_wstrb          = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WSTRB    ];
assign pipeline_data_addr  = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ADDR     ];
assign data_wdata          = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_WDATA    ];
assign data_recv           = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_RECV     ];
assign data_cancel         = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_CANCEL   ];
assign pipeline_ex2_cancel = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_EX2CANCEL];
assign pipeline_prefetch   = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_PREFETCH ];
assign data_pc             = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_PC       ];
assign ll_req              = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_LL       ];
assign sc_req              = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_SC       ];
assign atom_req            = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOM     ];
assign atom_op             = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOMOP   ];
assign atom_src            = pipeline2dcache_bus[`PIPELINE2DCACHE_BUS_ATOMSRC  ];

wire               prefetch_req;
wire [`PABITS-1:0] prefetch_paddr;
assign data_req      = (pipeline_data_req || prefetch_req) && init_finish && !cache_op_req;
assign data_wr       =  pipeline_data_req && pipeline_data_wr;
assign data_addr     = (pipeline_data_req || tlb_req || cache_op_req)? pipeline_data_addr : {{`GRLEN -`PABITS{1'b0}}, prefetch_paddr[`PABITS-1:13], prefetch_pgcl[0], prefetch_paddr[11:0]};
assign data_prefetch =  pipeline_prefetch || prefetch_req && !pipeline_data_req;
assign ex2_cancel    =  pipeline_ex2_cancel || sc_fail;

assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_RDATA    ] = data_rdata    ;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_ADDROK   ] = data_addr_ok  ;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_DATAOK   ] = data_data_ok  ;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_EXCCODE  ] = data_exccode  ;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_EXCEPTION] = data_exception;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_BADVADDR ] = data_badvaddr ;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_REQEMPTY ] = req_empty     ;
assign dcache2pipeline_bus[`DCACHE2PIPELINE_BUS_SCSUCCEED] = !sc_fail      ;
// -------------------------- END -------------------------


//DEBUG
reg [31:0] test_counter1;
reg [31:0] pc_record1 [31:0];
reg [31:0] wd_record1 [31:0];

always @(posedge clk) begin
  if(!resetn)
    test_counter1 <= 32'b0;
  else if(data_req && data_wr && data_addr == 32'haefc8028) begin
    test_counter1 <= test_counter1 + 32'd1;
    pc_record1[test_counter1] <= data_pc;
    wd_record1[test_counter1] <= data_wdata;
  end
end


//  ------------------ SIGNAL DECLARATION -----------------
wire st_cache_miss;
reg  ex2_cancel_his;

  // llsc
reg  llbctl_rollb;
reg  llbctl_klo;

wire llbctl_wen ;
wire llbit_set  ;
wire llbit_clear;
wire llbit_eret_clear    ;
wire llbit_write_clear   ;
wire llbit_finish_clear  ;
wire llbit_coherent_clear;
reg  [`PABITS-1:0] llsc_paddr;

  // tlb
wire tlb_valid_ret;
wire tlb_valid_finish;
wire tlb_valid_uncache;

  // cache state
reg  [ 2:0] dcache_state;
wire state_idle;
wire state_lkup;
wire state_block;
wire state_goon;
wire state_ucst;
wire state_oprd;
wire state_ophd;

wire block_release;
reg  [`D_TAG_LEN-1:0] goon_ptag;
reg                   goon_uncache;

  // req info register
reg                        data_wr_reg   ;
wire [`D_INDEX_LEN-1   :0] index         ;
wire [`D_BANK_LEN-1    :0] bank          ;
wire [`D_OFFSET_LEN-1  :0] offset        ;
reg  [`GRLEN-1         :0] data_wdata_reg;
reg  [`WSTRB_WIDTH-1   :0] data_wstrb_reg;
reg                        ll_req_reg    ;
reg                        sc_req_reg    ;
reg                        atom_req_reg  ;
reg  [ 4               :0] atom_op_reg   ;
reg  [`PABITS-1        :0] sspd_paddr    ;
reg                        req_cancel    ;

reg                        prefetch_reg  ;
reg [`PRE_PC_REF_LEN-1 :0] data_pc_reg   ;
wire                       ud_wr_req     ;

  // cache operation
reg  [`GRLEN-1         :0] cache_op_addr_his;
reg  [2                :0] cache_op_code   ;
reg  [`D_WAY_NUM-1     :0] op_wayhit_record;
reg                        op_dirty_record ;
reg  [`STATE_LEN-1     :0] op_valid_record ;

wire [`D_INDEX_LEN-1   :0] cache_op_index  ;
wire [`D_WAY_LEN-1     :0] cache_op_way    ;

wire                       op_need_wtbk    ;

wire                       ophd_finish   ;
wire                       op_wtbk_finish;
wire [`D_WAY_NUM-1     :0] op_tag_wen    ;
wire [`D_WAY_NUM-1     :0] op_tag_en     ;
wire [`D_INDEX_LEN-1   :0] op_tag_addr   ;
wire [`D_TAGARRAY_LEN-1:0] op_tag_wdata  ;
wire [`D_WAY_NUM-1     :0] op_data_en    ;
wire                       op_lrud_en    ;
wire [`D_INDEX_LEN-1   :0] op_lrud_addr  ;
wire                       op_wtbk_req   ;

  // ext req
reg [`EX_OP_WIDTH-1    :0] ex_op    ;
reg [`PABITS-1         :0] ex_paddr ;
reg [`COREID_WIDTH-1   :0] ex_cpuno ;
reg [1                 :0] ex_pgcl  ;
reg [3                 :0] ex_dirqid;
reg                        ex_dirty ;

reg [`D_WAY_NUM-1   :0] ex_wayhit_reg ;
reg [`D_WAY_NUM-1   :0] ex_mshrhit_reg;
reg [`STATE_LEN-1   :0] ex_hit_state  ;
reg [`SCWAY_LEN-1   :0] ex_hit_scway  ;

reg  [1             :0] ex_state ;
reg                     ex_rd_fin;
wire                    ex_idle  ;
wire                    ex_rdtag ;
wire                    ex_tagcmp;
wire                    ex_handle;

wire [`D_MSHR_ENTRY_NUM-1:0] ex_mshr_hit;

wire                       ex_wtbk_req   ;
wire                       ex_rdtag_ready;
wire                       ex_handle_fin ;
wire [`D_WAY_NUM-1     :0] ex_wayhit     ;

wire [`D_WAY_NUM-1     :0] ex_tag_wen  ;
wire [`D_WAY_NUM-1     :0] ex_tag_en   ;
wire [`D_INDEX_LEN-1   :0] ex_tag_addr ;
wire [`D_TAGARRAY_LEN-1:0] ex_tag_wdata;

wire [`D_WAY_NUM-1     :0] ex_data_en  ;
wire [`D_INDEX_LEN-1   :0] ex_data_addr;

wire                       ex_lrud_en  ;
wire [`D_INDEX_LEN-1   :0] ex_lrud_addr;

  // tag array
wire                  cache_miss;
wire                  cache_hit ;
wire                  store_hit ;
wire [`D_WAY_NUM-1:0] way_hit   ;
wire [`D_WAY_NUM-1:0] s_way_hit ;
wire [`STATE_LEN-1:0] line_state [`D_WAY_NUM-1:0];
wire [`SCWAY_LEN-1:0] line_scway [`D_WAY_NUM-1:0];
wire [`D_TAG_LEN-1:0] line_tag   [`D_WAY_NUM-1:0];
wire [`D_WAY_LEN-1:0] way_decode;

  // lru dirty
wire replaced_dirty;

wire [`D_WAY_NUM-1  :0] lru_new_way;
wire [`D_WAY_NUM-1  :0] lru_way_lock;
wire                    lru_new_wen;
wire                    lru_new_clr;
wire [`D_LRU_WIDTH-1:0] lru_new_lru;
wire [`D_LRU_WIDTH-1:0] lru_new_lru_bit_mask;
wire [`D_WAY_NUM-1  :0] lru_rplc_way;
wire [`D_LRU_WIDTH-1:0] lru_rdata;

wire [`D_WAY_NUM-1  :0] dirty_ram_wen;
wire [`D_WAY_NUM-1  :0] dirty_ram_wdata;
wire [`D_WAY_NUM-1  :0] dirty_rdata;

  // data array
wire [`WSTRB_WIDTH-1:0] replace_wen_bank0 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank1 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank2 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank3 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank4 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank5 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank6 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] replace_wen_bank7 [`D_WAY_NUM-1:0];

wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank0 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank1 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank2 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank3 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank4 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank5 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank6 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] wstrb_wen_bank7 [`D_WAY_NUM-1:0];

wire [`D_LINE_SIZE_b-1:0] rdata_way      [`D_WAY_NUM-1:0];
wire [`D_BANK_NUM-1   :0] data_array_en  [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank0 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank1 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank2 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank3 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank4 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank5 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank6 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1  :0] data_wen_bank7 [`D_WAY_NUM-1:0];
wire [`D_INDEX_LEN-1  :0] data_array_addr  [`D_BANK_NUM-1:0];
wire [`GRLEN-1        :0] data_array_wdata [`D_BANK_NUM-1:0];

wire  data_rd_idle;

wire [`D_BANK_NUM-1:0] data_addr_later;
wire [`D_BANK_NUM-1:0] data_addr_wr;

reg  [`D_WAY_LEN-1:0] replaced_way;
wire [`D_WAY_LEN-1:0] wtbk_way;

wire hit_ld_data_ok;
wire st_data_ok;
wire mshr_data_ok;
wire error_data_ok;

wire [`GRLEN-1:0] hit_rdata_temp;
wire [`GRLEN-1:0] hit_rdata;
wire [`GRLEN-1:0] mshr_rdata;

// wirte buffer
wire                    wr_buff_hit      ;
wire [`GRLEN-1      :0] wr_bit_mask      ;
wire                    wr_buff_valid    ;
wire                    wr_buff_release  ;
reg  [`GRLEN-1      :0] wr_buff_wdata    ;
reg  [`GRLEN-1      :0] wr_buff_wdata_src;
reg  [`GRLEN-1      :0] wr_buff_ram_wdata;


reg  [`WSTRB_WIDTH-1:0] wr_buff_wstrb  ;
reg  [`GRLEN-1      :0] wr_buff_data   ;
reg  [`D_INDEX_LEN-1:0] wr_buff_index  ;
reg  [`D_BANK_LEN-1 :0] wr_buff_bank   ;
reg  [`D_WAY_LEN-1  :0] wr_buff_way    ;
reg  [`D_TAG_LEN-1  :0] wr_buff_ptag   ;
reg                     wr_buff_atom   ;

// atom buff
wire [`GRLEN-1         :0] atom_st_data ;
wire [`ATOM_WEN_LEN-1  :0] mshr_atom_wen;

// MSHR
reg                          mshr_handle_cnt;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_idle;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_addr_wait;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_data_wait;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_handle;

reg  [ 3                 :0] mshr_state       [`D_MSHR_ENTRY_NUM-1:0];
reg                          mshr_valid       [`D_MSHR_ENTRY_NUM-1:0];
reg  [`D_TAG_LEN-1       :0] mshr_ptag        [`D_MSHR_ENTRY_NUM-1:0];
reg  [`D_INDEX_LEN-1     :0] mshr_index       [`D_MSHR_ENTRY_NUM-1:0];
reg  [`D_LINE_SIZE_b-1   :0] mshr_data        [`D_MSHR_ENTRY_NUM-1:0];
reg  [`MSHR_WSTRB_LEN-1  :0] mshr_wstrb       [`D_MSHR_ENTRY_NUM-1:0];
reg  [`MSHR_RECORD_LEN-1 :0] mshr_data_record [`D_MSHR_ENTRY_NUM-1:0];
reg                          mshr_uncache     [`D_MSHR_ENTRY_NUM-1:0];
reg  [`STATE_LEN-1       :0] mshr_rstate      [`D_MSHR_ENTRY_NUM-1:0];
reg  [`SCWAY_LEN-1       :0] mshr_rscway      [`D_MSHR_ENTRY_NUM-1:0];
reg                          mshr_exinv_hit   [`D_MSHR_ENTRY_NUM-1:0];
reg                          mshr_dirty       [`D_MSHR_ENTRY_NUM-1:0];
reg                          mshr_send_cpu    ;
reg  [`D_BANK_LEN-1      :0] mshr_rbank       ;
reg  [`MSHR_NUM_LEN-1    :0] mshr_rentry      ;
reg                          mshr_atom        ;

wire [`D_MSHR_ENTRY_NUM-1:0] mshr_hit;
wire                         mshr_empty;
wire                         mshr_full;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_alloc;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_new_req;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_new_sreq;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_new_lreq;
wire                         mshr_new_atomreq;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_clear;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_data_recv;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_empty_entry;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_sel;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_rfil;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_wtbk;

wire [`D_MSHR_ENTRY_NUM-1:0] mshr_use_darray;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_lkup_darray;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_wr_darray;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_rfil_ready;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_wait_go;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_recv_finish;
wire [`D_MSHR_ENTRY_NUM-1:0] mshr_ld_ret;

wire                         mshr_rfil_write;
wire [`D_INDEX_LEN-1     :0] mshr_use_index;

wire [`MSHR_RECORD_LEN-1 :0] mshr_recv_wen   [`D_MSHR_ENTRY_NUM-1:0];
wire [`MSHR_WSTRB_LEN-1  :0] mshr_req_wen    [`D_MSHR_ENTRY_NUM-1:0];
wire [`MSHR_WSTRB_LEN-1  :0] mshr_data_wen   [`D_MSHR_ENTRY_NUM-1:0];
wire [`D_LINE_SIZE_b-1   :0] mshr_data_wdata [`D_MSHR_ENTRY_NUM-1:0];
wire [`GRLEN-1           :0] mshr_rdata_entry[`D_MSHR_ENTRY_NUM-1:0];

  //prefetch
wire       load_ref;
wire       prefetch_recv;
wire [1:0] prefetch_pgcl;
wire       pre_req_addr_ok;
// -------------------------- END -------------------------


//  ------------------- Store Req & Addr ------------------
reg [`GRLEN-1:0] data_vaddr;
always @(posedge clk) begin
  if(data_addr_ok) begin
    data_vaddr <= data_addr;
  end
end
assign index  = data_vaddr[`D_INDEX_BITS ];
assign bank   = data_vaddr[`D_BANK_BITS  ];
assign offset = data_vaddr[`D_OFFSET_BITS];

always @(posedge clk) begin
  if(rst) begin
    data_wr_reg    <=  1'b0; // TODO remove 
    data_wdata_reg <= `GRLEN'b0;
    data_wstrb_reg <= {`WSTRB_WIDTH{1'b0}};
    prefetch_reg   <=  1'b0;
    data_pc_reg    <= `PRE_PC_REF_LEN'b0;
    ll_req_reg     <=  1'b0;
    sc_req_reg     <=  1'b0;
    atom_req_reg   <=  1'b0;
  end
  else if(data_addr_ok) begin
    data_wr_reg    <= data_wr;
    data_wdata_reg <= atom_req? atom_src : data_wdata & {`GRLEN{data_wr}};
    data_wstrb_reg <= data_wstrb & {`WSTRB_WIDTH{data_wr}};
    prefetch_reg   <= data_prefetch;
    data_pc_reg    <= data_pc[`PRE_PC_REF_LEN-1:0];
    ll_req_reg     <= ll_req;
    sc_req_reg     <= sc_req;
    atom_req_reg   <= atom_req;
    atom_op_reg    <= atom_op;
  end
end

always @(posedge clk) begin
  if(rst)
    req_cancel <= 1'b0;
  else if(data_addr_ok)
    req_cancel <= data_cancel;
end

always @(posedge clk) begin
  if(rst | tlb_finish)
    ex2_cancel_his <= 1'b0;
  else if(state_lkup && !tlb_finish && ex2_cancel)
    ex2_cancel_his <= 1'b1;
end

assign tlb_valid_finish = tlb_finish && tlb_cache_recv;

assign data_tlb_no_trans   = pre_req_addr_ok && !pipeline_data_req;
assign data_tlb_p_pgcl     = prefetch_paddr[12];
assign data_tlb_req        = data_addr_ok || cache_op_addr_ok && cache_op[`HIT_INV_WB];
assign data_tlb_wr         = (cache_op_addr_ok)? 1'b0 : data_wr;
assign data_tlb_vaddr      = (cache_op_addr_ok)? cache_op_addr : data_addr;
assign tlb_cache_recv = data_recv || prefetch_reg || ex2_cancel || ex2_cancel_his || req_cancel || state_oprd;
assign data_exception = icache_op_finish? icache_op_error : tlb_valid_finish && !tlb_hit;
assign data_exccode   = icache_op_finish? icache_op_exccode : tlb_exccode;
assign data_badvaddr  = icache_op_finish? icache_op_badvaddr : 
                        cache_op_ok     ? cache_op_addr_his  :
                                          data_vaddr;

assign tlb_valid_ret     = tlb_valid_finish && tlb_hit && !req_cancel;
assign tlb_valid_uncache = tlb_valid_ret    && tlb_uncache;

wire preld_uncache = state_lkup && tlb_finish && prefetch_reg && tlb_uncache;
// -------------------------- END -------------------------



// ------------------------ LLB CTL -----------------------
assign llbctl = {
  `ifdef LA64
  61'b0       ,
  `elsif LA32
  29'b0       ,
  `endif
  llbctl_klo  ,
  1'b0        ,
  llbctl_rollb
};
assign llbctl_wen  = csr_wen && csr_waddr == `LSOC1K_CSR_LLBCTL;
assign llbit_set   = data_addr_ok && ll_req;

assign llbit_eret_clear     = wb_eret && !llbctl_klo;
assign llbit_write_clear    = llbctl_wen && csr_wdata[`LSOC1K_LLBCTL_WCLLB];
assign llbit_coherent_clear = ex_tagcmp && (ex_op[`INV] || ex_op[`INV_WTBK]) && llbctl_rollb &&
                              ex_paddr[`PABITS-1:`D_LINE_LEN] == llsc_paddr[`PABITS-1:`D_LINE_LEN] &&
                              ex_cpuno[`COREID_WIDTH-1:0] != `CPU_COREID;
assign llbit_finish_clear   = data_data_ok && sc_req_reg;

assign llbit_clear = llbit_eret_clear || llbit_write_clear || llbit_coherent_clear || llbit_finish_clear;

always @(posedge clk) begin
  //llbctl_rollb
  if(llbit_set) llbctl_rollb <= 1'b1;
  else if(llbit_clear) llbctl_rollb <= 1'b0;
  //llbctl_klo
  if(rst || wb_eret) llbctl_klo <= 1'b0;
  else if(llbctl_wen) llbctl_klo <= csr_wdata[`LSOC1K_LLBCTL_KLO];
end

always @(posedge clk) begin
  if(tlb_valid_finish && ll_req_reg)
    llsc_paddr <= {tlb_ptag, index[11-`D_BANK_LEN-`D_OFFSET_LEN:0], bank, offset};
end

assign sc_fail = tlb_finish && sc_req_reg && !llbctl_rollb;
assign sc_succeed = !sc_fail;
// -------------------------- END -------------------------



//  ---------------------- RAM SIGNAL ---------------------
`ifdef D_WAY_NUM4
  assign way_decode = {2{way_hit[0]}} & 2'b00 |
                      {2{way_hit[1]}} & 2'b01 |
                      {2{way_hit[2]}} & 2'b10 |
                      {2{way_hit[3]}} & 2'b11 ;
  // tag
  assign {line_state[3], line_scway[3], line_tag[3], 
          line_state[2], line_scway[2], line_tag[2],
          line_state[1], line_scway[1], line_tag[1], 
          line_state[0], line_scway[0], line_tag[0]} = tag_ram_rdata;

  // data array
  wire [`GRLEN-1:0] rdata_way0 [`D_BANK_NUM-1:0];
  wire [`GRLEN-1:0] rdata_way1 [`D_BANK_NUM-1:0];
  wire [`GRLEN-1:0] rdata_way2 [`D_BANK_NUM-1:0];
  wire [`GRLEN-1:0] rdata_way3 [`D_BANK_NUM-1:0];

  assign hit_rdata_temp = ({`GRLEN{way_hit[0]}} & rdata_way0[bank]) |
                          ({`GRLEN{way_hit[1]}} & rdata_way1[bank]) |
                          ({`GRLEN{way_hit[2]}} & rdata_way2[bank]) |
                          ({`GRLEN{way_hit[3]}} & rdata_way3[bank]) ;
  assign hit_rdata      = {
                           `ifdef LA64
                           !(wr_buff_hit & wr_buff_wstrb[7])? hit_rdata_temp[63:56] : wr_buff_data[63:56],
                           !(wr_buff_hit & wr_buff_wstrb[6])? hit_rdata_temp[55:48] : wr_buff_data[55:48],
                           !(wr_buff_hit & wr_buff_wstrb[5])? hit_rdata_temp[47:40] : wr_buff_data[47:40],
                           !(wr_buff_hit & wr_buff_wstrb[4])? hit_rdata_temp[39:32] : wr_buff_data[39:32],
                           `endif
                           !(wr_buff_hit & wr_buff_wstrb[3])? hit_rdata_temp[31:24] : wr_buff_data[31:24],
                           !(wr_buff_hit & wr_buff_wstrb[2])? hit_rdata_temp[23:16] : wr_buff_data[23:16],
                           !(wr_buff_hit & wr_buff_wstrb[1])? hit_rdata_temp[15: 8] : wr_buff_data[15: 8],
                           !(wr_buff_hit & wr_buff_wstrb[0])? hit_rdata_temp[ 7: 0] : wr_buff_data[ 7: 0]};

  assign data_rdata = (hit_ld_data_ok)? hit_rdata : mshr_rdata;

  assign data_ram_en = {data_array_en[3], data_array_en[2], data_array_en[1], data_array_en[0]};
  assign data_ram_wen_bank0 = {data_wen_bank0[3], data_wen_bank0[2], data_wen_bank0[1], data_wen_bank0[0]};
  assign data_ram_wen_bank1 = {data_wen_bank1[3], data_wen_bank1[2], data_wen_bank1[1], data_wen_bank1[0]};
  assign data_ram_wen_bank2 = {data_wen_bank2[3], data_wen_bank2[2], data_wen_bank2[1], data_wen_bank2[0]};
  assign data_ram_wen_bank3 = {data_wen_bank3[3], data_wen_bank3[2], data_wen_bank3[1], data_wen_bank3[0]};
  assign data_ram_wen_bank4 = {data_wen_bank4[3], data_wen_bank4[2], data_wen_bank4[1], data_wen_bank4[0]};
  assign data_ram_wen_bank5 = {data_wen_bank5[3], data_wen_bank5[2], data_wen_bank5[1], data_wen_bank5[0]};
  assign data_ram_wen_bank6 = {data_wen_bank6[3], data_wen_bank6[2], data_wen_bank6[1], data_wen_bank6[0]};
  assign data_ram_wen_bank7 = {data_wen_bank7[3], data_wen_bank7[2], data_wen_bank7[1], data_wen_bank7[0]};
  assign data_ram_addr  = {data_array_addr[7], data_array_addr[6], data_array_addr[5], data_array_addr[4],
                           data_array_addr[3], data_array_addr[2], data_array_addr[1], data_array_addr[0]};
  assign data_ram_wdata = {data_array_wdata[7], data_array_wdata[6], data_array_wdata[5], data_array_wdata[4],
                           data_array_wdata[3], data_array_wdata[2], data_array_wdata[1], data_array_wdata[0]};

  assign {rdata_way[3], rdata_way[2], rdata_way[1], rdata_way[0]} = data_ram_rdata;
`endif
// -------------------------- END -------------------------



//  ---------------- Look Up in Dcache Tag ----------------
assign cache_hit     =   |way_hit  && !tlb_uncache  && tlb_valid_ret;
assign store_hit     =  cache_hit  && data_wr_reg;
assign cache_miss    =(!(|way_hit) && !tlb_uncache || tlb_uncache && !data_wr_reg) && tlb_valid_ret;

`ifdef MULTI_CORE
  assign st_cache_miss =(!(|s_way_hit)) && !tlb_uncache && data_wr_reg && tlb_valid_ret;
`else
  assign st_cache_miss = 1'b0;
`endif

assign op_tag_addr  = (cache_op_addr_ok)? cache_op_addr[`D_INDEX_BITS] : cache_op_index;
assign op_tag_wdata = (cache_op_code[`IDX_ST_TAG])? {{`STATE_LEN{1'b0}}, {`SCWAY_LEN{1'b0}}, cache_op_tag} : {`D_TAGARRAY_LEN{1'b0}}; // TODO

assign ex_tag_addr  = {ex_pgcl[0], ex_paddr[11:`D_LINE_LEN]};
assign ex_tag_wdata = (ex_op[`INV_WTBK] || ex_op[`INV])?  {`D_TAGARRAY_LEN{1'b0}} : 
                                                          {`STATE_S, ex_hit_scway, ex_paddr[`D_TAG_BITS]};

`ifdef D_MSHR_ENTRY4
  assign tag_ram_addr  = (|mshr_use_darray              )? mshr_use_index          :
                         (|op_tag_en                    )? op_tag_addr             :
                         (|ex_tag_en                    )? ex_tag_addr             :
                         (state_lkup & !tlb_valid_finish)? index                   :
                                                           data_addr[`D_INDEX_BITS];

  assign tag_ram_wdata = {`D_TAGARRAY_LEN{mshr_wr_darray[0]}} & {mshr_rstate[0], mshr_rscway[0], mshr_ptag[0]} | // todo:
                         {`D_TAGARRAY_LEN{mshr_wr_darray[1]}} & {mshr_rstate[1], mshr_rscway[1], mshr_ptag[1]} |
                         {`D_TAGARRAY_LEN{mshr_wr_darray[2]}} & {mshr_rstate[2], mshr_rscway[2], mshr_ptag[2]} |
                         {`D_TAGARRAY_LEN{mshr_wr_darray[3]}} & {mshr_rstate[3], mshr_rscway[3], mshr_ptag[3]} |
                         {`D_TAGARRAY_LEN{|ex_tag_wen      }} &  ex_tag_wdata                                  |
                         {`D_TAGARRAY_LEN{|op_tag_wen      }} &  op_tag_wdata                                  ;
`endif

genvar gv_tag;
generate
  for(gv_tag = 0; gv_tag < `D_WAY_NUM; gv_tag = gv_tag + 1)
  begin : tag_module
    always @(posedge clk) begin
      if(rst)
        tag_ram_clk_en[gv_tag] <= 1'b1;
    end

    assign way_hit[gv_tag]   = line_tag[gv_tag] == tlb_ptag && line_state[gv_tag] != `STATE_I;
    assign s_way_hit[gv_tag] = line_tag[gv_tag] == tlb_ptag && line_state[gv_tag] != `STATE_E;

    assign ex_wayhit[gv_tag] = line_tag[gv_tag] == ex_paddr[`D_TAG_BITS] && line_state[gv_tag] != `STATE_I;

    assign tag_ram_en[gv_tag]  = (state_idle && data_req || state_lkup      ) || 
                                 (|mshr_wr_darray && replaced_way == gv_tag ) ||
                                 (|mshr_lkup_darray                         ) ||
                                 (op_tag_en[gv_tag]                         ) ;

    assign tag_ram_wen[gv_tag] = (|mshr_wr_darray  && replaced_way == gv_tag) ||
                                 (op_tag_wen[gv_tag]                        ) ;

    assign op_tag_en[gv_tag]   = cache_op_addr_ok && (cache_op[`IDX_INV_WB] || cache_op[`HIT_INV_WB])        ||
                                 state_oprd && (cache_op_code[`IDX_INV_WB] || cache_op_code[`HIT_INV_WB])    ||
                                 state_ophd && (cache_op_code[`IDX_INV_WB] || cache_op_code[`HIT_INV_WB]) && !ophd_finish ||
                                 op_tag_wen[gv_tag];

    assign op_tag_wen[gv_tag]  = state_ophd &&
                                 (cache_op_code[`IDX_ST_TAG] && cache_op_way == gv_tag                  ||
                                  cache_op_code[`IDX_INV_WB] && cache_op_way == gv_tag   && ophd_finish ||
                                  cache_op_code[`HIT_INV_WB] && op_wayhit_record[gv_tag] && ophd_finish );

    assign ex_tag_en[gv_tag]  = ex_rdtag_ready || ex_tag_wen[gv_tag]; // TODO
    assign ex_tag_wen[gv_tag] = ex_handle_fin && ex_wayhit_reg[gv_tag] &&
                                (ex_op[`INV_WTBK] || ex_op[`INV] || ex_op[`WTBK] && ex_hit_state == `STATE_E);
  end
endgenerate

// -------------------------- END -------------------------



// ----------------------- LRU Dirty ----------------------
reg                      lrud_wr_valid;
reg                      lrud_wr_store;
reg [`D_WAY_NUM-1    :0] lrud_wr_way  ;
reg [`D_INDEX_LEN-1  :0] lrud_wr_index;

always @(posedge clk) begin
  if(rst)
    lrud_wr_valid <= 1'b0;
  else
    lrud_wr_valid <= cache_hit;
end

always @(posedge clk) begin
  if(tlb_valid_ret)
    lrud_wr_index <= index;
end

always @(posedge clk) begin
  if(cache_hit) begin
    lrud_wr_way   <= way_hit;
    lrud_wr_store <= data_wr_reg;
  end
end

// TODO:
always @(posedge clk) begin
  if(rst)
    lrud_clk_en_o <= 1'b1;
end

assign op_lrud_en   = cache_op_addr_ok && (cache_op[`IDX_INV_WB] || cache_op[`HIT_INV_WB]) ||
                      state_oprd && cache_op_code[`HIT_INV_WB] && !tlb_finish;

assign op_lrud_addr = (cache_op_addr_ok)? cache_op_addr[`D_INDEX_BITS] : cache_op_index; // TODO

assign ex_lrud_en   = ex_rdtag_ready;
assign ex_lrud_addr = {ex_pgcl[0], ex_paddr[11:`D_LINE_LEN]};

assign lrud_en_o    = |mshr_lkup_darray || lrud_wr_valid || |mshr_rfil || state_goon || op_lrud_en || ex_lrud_en; // TODO: remove state_goon?
assign lrud_wen_o   = {dirty_ram_wen, lru_new_lru_bit_mask};
assign lrud_addr_o  = (|mshr_use_darray)? mshr_use_index :
                      (op_lrud_en      )? op_lrud_addr    :
                      (ex_lrud_en      )? ex_lrud_addr    :
                                          lrud_wr_index   ;
assign lrud_wdata_o = {dirty_ram_wdata, lru_new_lru};

`ifdef D_MSHR_ENTRY4

  `ifdef D_WAY_NUM4
    always @(posedge clk) begin
      if(rst)
        replaced_way <= 2'b0;
      else if(|mshr_sel)
        replaced_way <= {2{lru_rplc_way[3]}} & 2'b11 |
                        {2{lru_rplc_way[2]}} & 2'b10 |
                        {2{lru_rplc_way[1]}} & 2'b01 |
                        {2{lru_rplc_way[0]}} & 2'b00 ;
    end

    assign lru_new_way  = {lrud_wr_valid & lrud_wr_way[3] | (|mshr_rfil) & lru_rplc_way[3],
                           lrud_wr_valid & lrud_wr_way[2] | (|mshr_rfil) & lru_rplc_way[2],
                           lrud_wr_valid & lrud_wr_way[1] | (|mshr_rfil) & lru_rplc_way[1],
                           lrud_wr_valid & lrud_wr_way[0] | (|mshr_rfil) & lru_rplc_way[0]};
    
    wire [3:0] valid_bits = {line_state[3] != `STATE_I, line_state[2] != `STATE_I,
                             line_state[1] != `STATE_I, line_state[0] != `STATE_I};
  `endif
  // TODO:
  assign lru_way_lock  = {`D_WAY_NUM{1'b0}};
  assign lru_new_clr   = 1'b0;

  assign lru_new_wen   = lrud_wr_valid || |mshr_rfil;

  //always @(posedge clk) begin
  //  if(rst)
  //    replaced_dirty <= 1'b0;
  //  else if(|mshr_sel)
  //    replaced_dirty <= |(lru_rplc_way & dirty_rdata);
  //end
`endif
assign replaced_dirty = |(lru_rplc_way & dirty_rdata & valid_bits);

lru_unit #(
  .LRU_BITS (`D_LRU_WIDTH), 
  .WAY_N    (`D_WAY_NUM  )
) u_dlru 
(
  .new_way  (lru_new_way ),
  .way_lock (lru_way_lock),

  .new_wen  (lru_new_wen ),
  .new_clr  (lru_new_clr ),

  .new_lru          (lru_new_lru         ),
  .new_lru_bit_mask (lru_new_lru_bit_mask),

  .repl_lru         (lru_rdata   ),
  .repl_way         (lru_rplc_way)
);

assign {dirty_rdata, lru_rdata} = lrud_rdata_i;

assign dirty_ram_wen = {(lrud_wr_valid & lrud_wr_store & lrud_wr_way[3]) | (|mshr_rfil & lru_rplc_way[3]),
                        (lrud_wr_valid & lrud_wr_store & lrud_wr_way[2]) | (|mshr_rfil & lru_rplc_way[2]),
                        (lrud_wr_valid & lrud_wr_store & lrud_wr_way[1]) | (|mshr_rfil & lru_rplc_way[1]),
                        (lrud_wr_valid & lrud_wr_store & lrud_wr_way[0]) | (|mshr_rfil & lru_rplc_way[0])};

assign dirty_ram_wdata = {`D_WAY_NUM{lrud_wr_valid                 }} &  lrud_wr_way  |
                         {`D_WAY_NUM{|mshr_rfil &&  mshr_rfil_write}} &  lru_rplc_way |
                         {`D_WAY_NUM{|mshr_rfil && !mshr_rfil_write}} & ~lru_rplc_way ;
// -------------------------- END -------------------------



// ----------------- Finite State Machine -----------------
// IDLE       : 4'b0000, Non req
// LOOK UP    : 4'b0001, There's a data req, with index result generated.

assign state_idle  = dcache_state == 3'b000;
assign state_lkup  = dcache_state == 3'b001;
assign state_block = dcache_state == 3'b010;
assign state_goon  = dcache_state == 3'b011;
assign state_ucst  = dcache_state == 3'b100;
assign state_oprd  = dcache_state == 3'b110;
assign state_ophd  = dcache_state == 3'b111;

assign block_release = |mshr_clear;

always @(posedge clk) begin
  if(rst)
    dcache_state <= 3'b000;
  // ###  IDLE  ###
  else if(state_idle && (data_addr_ok || cache_op_addr_ok))
    dcache_state <= (data_addr_ok)? 3'b001 : 3'b110;

  // ### LOOK UP ###
  else if(state_lkup && (cache_miss || st_cache_miss) && !(|mshr_hit) && mshr_full && !ex2_cancel && !ex2_cancel_his && !preld_uncache)
    dcache_state <= 3'b010;
  else if(state_lkup && ud_wr_req)
    dcache_state <= 3'b100;
  else if(state_lkup && tlb_valid_finish && !data_addr_ok || state_goon || state_ophd && ophd_finish || state_ucst && wr_ready == 1'b1)
    dcache_state <= 3'b000;

  // ###  BLOCK  ###
  else if(state_block && block_release)
    dcache_state <= 3'b011;

  else if(state_oprd && (tlb_finish || !cache_op_code[`HIT_INV_WB]))
    dcache_state <= (tlb_hit || !cache_op_code[`HIT_INV_WB])? 3'b111 : 3'b000;
end

always @(posedge clk) begin
  if(cache_miss && !(|mshr_hit) && mshr_full || state_lkup && ud_wr_req) begin
    goon_ptag    <= tlb_ptag; // Goon ptag && uncache write ptag
    goon_uncache <= tlb_uncache;
  end
end
// ------------------------- END --------------------------



// --------------------- Write Buffer ---------------------
wire   wr_conflict;
assign wr_conflict = data_req && wr_buff_bank == data_addr[`D_BANK_BITS] && wr_buff_valid;

assign wr_buff_valid = |wr_buff_wstrb;
assign wr_buff_hit = {wr_buff_ptag, wr_buff_index, wr_buff_bank} == {tlb_ptag, index, bank};
assign wr_bit_mask = {
                      `ifdef LA64
                      {8{data_wstrb_reg[7]}}, {8{data_wstrb_reg[6]}}, {8{data_wstrb_reg[5]}}, {8{data_wstrb_reg[4]}},
                      `endif
                      {8{data_wstrb_reg[3]}}, {8{data_wstrb_reg[2]}}, {8{data_wstrb_reg[1]}}, {8{data_wstrb_reg[0]}}};
// TODO:
assign wr_buff_release = ((state_idle || tlb_valid_finish) && !wr_conflict || tlb_valid_finish && data_wr_reg && !wr_buff_hit || state_block) && !(|mshr_rfil);

always @(posedge clk) begin
  if(rst)
    wr_buff_wstrb <= {`WSTRB_WIDTH{1'b0}};
  else if(store_hit && !ex2_cancel && !ex2_cancel_his)
    wr_buff_wstrb <= ({`WSTRB_WIDTH{wr_buff_hit}} & wr_buff_wstrb) | data_wstrb_reg;
  else if(wr_buff_release)
    wr_buff_wstrb <= {`WSTRB_WIDTH{1'b0}};
end

always @(posedge clk) begin
  if(store_hit && !ex2_cancel && !ex2_cancel_his) begin
    wr_buff_data  <= wr_buff_wdata;
    wr_buff_index <= index;
    wr_buff_bank  <= bank;
    wr_buff_way   <= way_decode;
    wr_buff_ptag  <= tlb_ptag;
  end
end

always @(posedge clk) begin
  if(rst)
    wr_buff_atom <= 1'b0;
  else if(store_hit && !ex2_cancel && !ex2_cancel_his)
    wr_buff_atom <= atom_req_reg;
end



   // uty: test
   always @(posedge clk) begin
      wr_buff_wdata_src <= (atom_req_reg)? hit_rdata : data_wdata_reg;
      wr_buff_wdata     <= (wr_buff_data & ~wr_bit_mask & {`GRLEN{wr_buff_hit}}) | (wr_buff_wdata_src & wr_bit_mask);

      wr_buff_ram_wdata <= (wr_buff_atom)? atom_st_data : wr_buff_data;
   end
   
//assign wr_buff_wdata_src = (atom_req_reg)? hit_rdata : data_wdata_reg;
//assign wr_buff_wdata     = (wr_buff_data & ~wr_bit_mask & {`GRLEN{wr_buff_hit}}) | (wr_buff_wdata_src & wr_bit_mask);
//
//assign wr_buff_ram_wdata = (wr_buff_atom)? atom_st_data : wr_buff_data;
// ------------------------- END --------------------------



// ------------------------ ATOM --------------------------
wire [`GRLEN-1:0] atom_alu_src_a;
wire [`GRLEN-1:0] atom_alu_src_b;

assign atom_alu_src_a = mshr_valid[0]? mshr_rdata : wr_buff_data;
assign atom_alu_src_b = data_wdata_reg;

atom_alu u_atom_alu(
  .a(atom_alu_src_a   ),
  .b(atom_alu_src_b   ),
  .atom_op(atom_op_reg),
  .result(atom_st_data)
);

assign mshr_new_atomreq = mshr_alloc[0] && atom_req_reg;

`ifdef LA64
  assign mshr_atom_wen = {
    {bank, offset[2]} == 4'b1111 && mshr_atom && mshr_data_record[0][3],
    {bank, offset[2]} == 4'b1110 && mshr_atom && mshr_data_record[0][3],
    {bank, offset[2]} == 4'b1101 && mshr_atom && mshr_data_record[0][3],
    {bank, offset[2]} == 4'b1100 && mshr_atom && mshr_data_record[0][3],
    {bank, offset[2]} == 4'b1011 && mshr_atom && mshr_data_record[0][2],
    {bank, offset[2]} == 4'b1010 && mshr_atom && mshr_data_record[0][2],
    {bank, offset[2]} == 4'b1001 && mshr_atom && mshr_data_record[0][2],
    {bank, offset[2]} == 4'b1000 && mshr_atom && mshr_data_record[0][2],
    {bank, offset[2]} == 4'b0111 && mshr_atom && mshr_data_record[0][1],
    {bank, offset[2]} == 4'b0110 && mshr_atom && mshr_data_record[0][1],
    {bank, offset[2]} == 4'b0101 && mshr_atom && mshr_data_record[0][1],
    {bank, offset[2]} == 4'b0100 && mshr_atom && mshr_data_record[0][1],
    {bank, offset[2]} == 4'b0011 && mshr_atom && mshr_data_record[0][0],
    {bank, offset[2]} == 4'b0010 && mshr_atom && mshr_data_record[0][0],
    {bank, offset[2]} == 4'b0001 && mshr_atom && mshr_data_record[0][0],
    {bank, offset[2]} == 4'b0000 && mshr_atom && mshr_data_record[0][0]
  };
`elsif LA32
  assign mshr_atom_wen = {
    bank == 3'b111 && mshr_atom && mshr_data_record[0][1],
    bank == 3'b110 && mshr_atom && mshr_data_record[0][0],
    bank == 3'b101 && mshr_atom && mshr_data_record[0][1],
    bank == 3'b100 && mshr_atom && mshr_data_record[0][0],
    bank == 3'b011 && mshr_atom && mshr_data_record[0][1],
    bank == 3'b010 && mshr_atom && mshr_data_record[0][0],
    bank == 3'b001 && mshr_atom && mshr_data_record[0][1],
    bank == 3'b000 && mshr_atom && mshr_data_record[0][0]
  };
`endif
// ------------------------- END --------------------------



// ------------------------- MSHR -------------------------
`ifdef D_MSHR_ENTRY4
  assign mshr_full  =  mshr_valid[3] &  mshr_valid[2] &  mshr_valid[1] &  mshr_valid[0];
  assign mshr_empty = !mshr_valid[3] & !mshr_valid[2] & !mshr_valid[1] & !mshr_valid[0] && state_idle;

  assign mshr_empty_entry = (!mshr_valid[0])? 4'b0001:
                            (!mshr_valid[1])? 4'b0010:
                            (!mshr_valid[2])? 4'b0100:
                            (!mshr_valid[3])? 4'b1000:
                                              4'b0000;
  assign mshr_alloc = {4{((cache_miss | st_cache_miss) & state_lkup & !ex2_cancel & !ex2_cancel_his & !preld_uncache | state_goon) & !(|mshr_hit)}} & mshr_empty_entry;

  assign mshr_data_recv[0] = ret_valid && ret_data_id == 4'b0000;
  assign mshr_data_recv[1] = ret_valid && ret_data_id == 4'b0001;
  assign mshr_data_recv[2] = ret_valid && ret_data_id == 4'b0010;
  assign mshr_data_recv[3] = ret_valid && ret_data_id == 4'b0011;

  assign mshr_use_index  = {`D_INDEX_LEN{mshr_use_darray[0]}} & mshr_index[0] |
                           {`D_INDEX_LEN{mshr_use_darray[1]}} & mshr_index[1] |
                           {`D_INDEX_LEN{mshr_use_darray[2]}} & mshr_index[2] |
                           {`D_INDEX_LEN{mshr_use_darray[3]}} & mshr_index[3] ;

  assign mshr_rfil_write = mshr_rfil[0] && mshr_dirty[0] ||
                           mshr_rfil[1] && mshr_dirty[1] ||
                           mshr_rfil[2] && mshr_dirty[2] ||
                           mshr_rfil[3] && mshr_dirty[3] ;

  assign mshr_wait_go[0] = mshr_rfil_ready[0] & !(|mshr_handle); // TODO: mshr_hasin_rfil_rplc Can just only judge other ([1 2 3]) entrys
  assign mshr_wait_go[1] = mshr_rfil_ready[1] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle));
  assign mshr_wait_go[2] = mshr_rfil_ready[2] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle)) & 
                         !(mshr_rfil_ready[1] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle)));
  assign mshr_wait_go[3] = mshr_rfil_ready[3] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle)) & 
                         !(mshr_rfil_ready[1] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle))) & 
                         !(mshr_rfil_ready[2] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle)) & 
                         !(mshr_rfil_ready[1] & !(|mshr_handle) & !(mshr_rfil_ready[0] & !(|mshr_handle))));

  assign mshr_rdata      = {`GRLEN{mshr_ld_ret[3]}} & mshr_rdata_entry[3] |
                           {`GRLEN{mshr_ld_ret[2]}} & mshr_rdata_entry[2] |
                           {`GRLEN{mshr_ld_ret[1]}} & mshr_rdata_entry[1] |
                           {`GRLEN{mshr_ld_ret[0]}} & mshr_rdata_entry[0] ;

    always @(posedge clk) begin
      if(rst)
        mshr_send_cpu <= 1'b0;
      else if(|mshr_new_lreq || mshr_new_atomreq) begin
        mshr_send_cpu <= 1'b1;
        mshr_rbank    <= bank;
        mshr_rentry   <= {2{mshr_new_lreq[0]}} & 2'b00 |
                         {2{mshr_new_lreq[1]}} & 2'b01 |
                         {2{mshr_new_lreq[2]}} & 2'b10 |
                         {2{mshr_new_lreq[3]}} & 2'b11 ;
      end
      else if(mshr_data_ok)
        mshr_send_cpu <= 1'b0;
    end

    always @(posedge clk) begin
      if(rst)
        mshr_atom <= 1'b0;
      else if(mshr_new_atomreq)
        mshr_atom <= 1'b1;
      else if(|mshr_atom_wen)
        mshr_atom <= 1'b0;
    end
`endif

always @(posedge clk) begin
  if(rst || |mshr_handle && mshr_handle_cnt)
    mshr_handle_cnt <= 1'b0;
  else if(|mshr_handle && !mshr_handle_cnt && (wr_ready == 1'b1 || !replaced_dirty))
    mshr_handle_cnt <= 1'b1;
end

genvar gv_mshr;
generate
  for(gv_mshr = 0; gv_mshr < `D_MSHR_ENTRY_NUM; gv_mshr = gv_mshr + 1)
  begin : gen_mshr

    assign ex_mshr_hit[gv_mshr] = mshr_valid[gv_mshr] && mshr_recv_finish[gv_mshr] && !mshr_exinv_hit[gv_mshr] && ex_tagcmp && ex_op[`INV] && ex_op[`INV_WTBK] &&
                                  mshr_index[gv_mshr] == {ex_pgcl[0], ex_paddr[11:`D_LINE_LEN]} && ex_paddr[`D_TAG_BITS] == mshr_ptag[gv_mshr];

    assign mshr_hit     [gv_mshr] = tlb_valid_finish & tlb_hit & mshr_valid[gv_mshr] & tlb_ptag == mshr_ptag[gv_mshr] & index == mshr_index[gv_mshr] & !req_cancel & !ex2_cancel & !ex2_cancel_his;
    assign mshr_clear   [gv_mshr] = mshr_handle[gv_mshr] && mshr_handle_cnt || mshr_data_wait[gv_mshr] && mshr_uncache[gv_mshr] && mshr_data_record[gv_mshr][0];
    assign mshr_new_req [gv_mshr] = mshr_alloc[gv_mshr] | mshr_hit[gv_mshr];
    assign mshr_new_sreq[gv_mshr] = mshr_new_req[gv_mshr] &  data_wr_reg;
    assign mshr_new_lreq[gv_mshr] = mshr_new_req[gv_mshr] & !data_wr_reg && !prefetch_reg;

    assign mshr_rfil[gv_mshr] = mshr_handle[gv_mshr] && !mshr_exinv_hit[gv_mshr] &&  mshr_handle_cnt;
    assign mshr_sel [gv_mshr] = mshr_handle[gv_mshr] && !mshr_exinv_hit[gv_mshr] && !mshr_handle_cnt;
    assign mshr_wtbk[gv_mshr] = mshr_sel[gv_mshr] && replaced_dirty;

    assign mshr_recv_finish[gv_mshr] = &mshr_data_record[gv_mshr];
    assign mshr_rfil_ready [gv_mshr] = mshr_recv_finish[gv_mshr] & mshr_data_wait[gv_mshr] & !wr_buff_valid &
                                       (state_idle & !data_req | state_block) & vic_not_full; 

    assign mshr_use_darray [gv_mshr] = mshr_lkup_darray[gv_mshr] | mshr_wr_darray[gv_mshr];
    assign mshr_lkup_darray[gv_mshr] = mshr_wait_go[gv_mshr];
    assign mshr_wr_darray  [gv_mshr] = mshr_rfil[gv_mshr];

  `ifdef LA64
    assign mshr_ld_ret[gv_mshr]  = ((mshr_data_record[gv_mshr][3] || &mshr_wstrb[gv_mshr][63:56] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][55:48] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b11 ||
                                    (mshr_data_record[gv_mshr][2] || &mshr_wstrb[gv_mshr][47:40] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][39:32] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b10 ||
                                    (mshr_data_record[gv_mshr][1] || &mshr_wstrb[gv_mshr][31:24] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][23:16] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b01 ||
                                    (mshr_data_record[gv_mshr][0] || &mshr_wstrb[gv_mshr][15: 8] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][ 7: 0] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b00)&&
                                     mshr_send_cpu && mshr_rentry == gv_mshr || 
                                     mshr_uncache[gv_mshr] && mshr_data_record[gv_mshr][0] && mshr_valid[gv_mshr];
  `elsif LA32
    assign mshr_ld_ret[gv_mshr]  = ((mshr_data_record[gv_mshr][3] || &mshr_wstrb[gv_mshr][31:28] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][27:24] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b11 ||
                                    (mshr_data_record[gv_mshr][2] || &mshr_wstrb[gv_mshr][23:20] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][19:16] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b10 ||
                                    (mshr_data_record[gv_mshr][1] || &mshr_wstrb[gv_mshr][15:12] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][11: 8] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b01 ||
                                    (mshr_data_record[gv_mshr][0] || &mshr_wstrb[gv_mshr][ 7: 4] && mshr_rbank[0] || &mshr_wstrb[gv_mshr][ 3: 0] && !mshr_rbank[0]) && mshr_rbank[2:1] == 2'b00)&&
                                     mshr_send_cpu && mshr_rentry == gv_mshr || 
                                     mshr_uncache[gv_mshr] && mshr_data_record[gv_mshr][0] && mshr_valid[gv_mshr];
  `endif

    assign mshr_idle     [gv_mshr] = mshr_state[gv_mshr] == 4'b0000;
    assign mshr_addr_wait[gv_mshr] = mshr_state[gv_mshr] == 4'b0001;
    assign mshr_data_wait[gv_mshr] = mshr_state[gv_mshr] == 4'b0010;
    assign mshr_handle   [gv_mshr] = mshr_state[gv_mshr] == 4'b0011;

    always@ (posedge clk) begin
      if(rst)
        mshr_state[gv_mshr] <= 4'b0;
      else if(mshr_idle[gv_mshr] && mshr_alloc[gv_mshr])
        mshr_state[gv_mshr] <= 4'b0001;
      else if(mshr_addr_wait[gv_mshr] && rd_arready && rd_id == gv_mshr)
        mshr_state[gv_mshr] <= 4'b0010;
      
      else if(mshr_data_wait[gv_mshr] && mshr_uncache[gv_mshr] && mshr_data_record[gv_mshr][0])
        mshr_state[gv_mshr] <= 4'b0000;
      else if(mshr_data_wait[gv_mshr] && mshr_wait_go[gv_mshr])
        mshr_state[gv_mshr] <= 4'b0011;

      else if(mshr_handle[gv_mshr] && mshr_handle_cnt)
        mshr_state[gv_mshr] <= 4'b0000;
    end

    always @(posedge clk) begin
      if(rst)
        mshr_valid[gv_mshr] <= 1'b0;
      else if(mshr_alloc[gv_mshr])
        mshr_valid[gv_mshr] <= 1'b1;
      else if(mshr_clear[gv_mshr])
        mshr_valid[gv_mshr] <= 1'b0;
    end

    always @(posedge clk) begin
      if(mshr_alloc[gv_mshr]) begin
        mshr_ptag [gv_mshr] <= (state_goon)? goon_ptag : tlb_ptag;
        mshr_index[gv_mshr] <=  index;
      end
    end

    always @(posedge clk) begin
      if(mshr_alloc[gv_mshr])
        mshr_exinv_hit[gv_mshr] <= 1'b0;
      else if(ex_mshr_hit[gv_mshr])
        mshr_exinv_hit[gv_mshr] <= 1'b1;
    end

    always @(posedge clk) begin
      if(rst)
        mshr_uncache[gv_mshr] <= 1'b0;
      else if(mshr_alloc[gv_mshr]) begin
        mshr_uncache[gv_mshr] <= (state_goon)? goon_uncache : tlb_uncache;
      end
    end

    always @(posedge clk) begin
      if(mshr_clear[gv_mshr])
        mshr_dirty[gv_mshr] <= 1'b0;
      if((mshr_alloc[gv_mshr] || mshr_hit[gv_mshr]) && data_wr_reg)
        mshr_dirty[gv_mshr] <= (|data_wstrb_reg);
    end

    always @(posedge clk) begin
      if(rst)
        mshr_wstrb[gv_mshr] <= {`MSHR_WSTRB_LEN{1'b0}};
      else if(mshr_alloc[gv_mshr] || mshr_hit[gv_mshr] && tlb_valid_ret)
        `ifdef LA64
        mshr_wstrb[gv_mshr] <= {{8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][63:56] | {8{bank == 3'b111}} & data_wstrb_reg, 
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][55:48] | {8{bank == 3'b110}} & data_wstrb_reg,
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][47:40] | {8{bank == 3'b101}} & data_wstrb_reg,
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][39:32] | {8{bank == 3'b100}} & data_wstrb_reg,
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][31:24] | {8{bank == 3'b011}} & data_wstrb_reg,
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][23:16] | {8{bank == 3'b010}} & data_wstrb_reg,
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][15: 8] | {8{bank == 3'b001}} & data_wstrb_reg,
                                {8{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][ 7: 0] | {8{bank == 3'b000}} & data_wstrb_reg};
        `elsif LA32
        mshr_wstrb[gv_mshr] <= {{4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][31:28] | {4{bank == 3'b111}} & data_wstrb_reg, 
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][27:24] | {4{bank == 3'b110}} & data_wstrb_reg,
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][23:20] | {4{bank == 3'b101}} & data_wstrb_reg,
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][19:16] | {4{bank == 3'b100}} & data_wstrb_reg,
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][15:12] | {4{bank == 3'b011}} & data_wstrb_reg,
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][11: 8] | {4{bank == 3'b010}} & data_wstrb_reg,
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][ 7: 4] | {4{bank == 3'b001}} & data_wstrb_reg,
                                {4{!mshr_alloc[gv_mshr]}} & mshr_wstrb[gv_mshr][ 3: 0] | {4{bank == 3'b000}} & data_wstrb_reg};
        `endif
    end
    
    `ifdef LA64
    assign mshr_rdata_entry[gv_mshr] = {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b111}} & mshr_data[gv_mshr][511:448] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b110}} & mshr_data[gv_mshr][447:384] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b101}} & mshr_data[gv_mshr][383:320] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b100}} & mshr_data[gv_mshr][319:256] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b011}} & mshr_data[gv_mshr][255:192] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b010}} & mshr_data[gv_mshr][191:128] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b001}} & mshr_data[gv_mshr][127: 64] |
                                       {64{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b000}} & mshr_data[gv_mshr][ 63:  0] |
                                       {64{ mshr_uncache[gv_mshr] &&  mshr_rbank[0]       }} & mshr_data[gv_mshr][127: 64] |
                                       {64{ mshr_uncache[gv_mshr] && !mshr_rbank[0]       }} & mshr_data[gv_mshr][ 63:  0] ;
    `elsif LA32
    assign mshr_rdata_entry[gv_mshr] = {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b111}} & mshr_data[gv_mshr][255:224] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b110}} & mshr_data[gv_mshr][223:192] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b101}} & mshr_data[gv_mshr][191:160] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b100}} & mshr_data[gv_mshr][159:128] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b011}} & mshr_data[gv_mshr][127: 96] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b010}} & mshr_data[gv_mshr][ 95: 64] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b001}} & mshr_data[gv_mshr][ 63: 32] |
                                       {32{!mshr_uncache[gv_mshr] &&  mshr_rbank == 3'b000}} & mshr_data[gv_mshr][ 31:  0] |
                                       {32{ mshr_uncache[gv_mshr] &&  mshr_rbank[0]       }} & mshr_data[gv_mshr][ 63: 32] |
                                       {32{ mshr_uncache[gv_mshr] && !mshr_rbank[0]       }} & mshr_data[gv_mshr][ 31:  0] ;
    `endif
`ifdef LA64
    assign mshr_data_wdata[gv_mshr] = {mshr_req_wen[gv_mshr][63]? data_wdata_reg[63: 56] : mshr_atom_wen[15]? atom_st_data[ 63: 56] : ret_data[127:120],
                                       mshr_req_wen[gv_mshr][62]? data_wdata_reg[55: 48] : mshr_atom_wen[15]? atom_st_data[ 55: 48] : ret_data[119:112],
                                       mshr_req_wen[gv_mshr][61]? data_wdata_reg[47: 40] : mshr_atom_wen[15]? atom_st_data[ 47: 40] : ret_data[111:104],
                                       mshr_req_wen[gv_mshr][60]? data_wdata_reg[39: 32] : mshr_atom_wen[15]? atom_st_data[ 39: 32] : ret_data[103: 96],
                                       mshr_req_wen[gv_mshr][59]? data_wdata_reg[31: 24] : mshr_atom_wen[14]? atom_st_data[ 31: 24] : ret_data[ 95: 88],
                                       mshr_req_wen[gv_mshr][58]? data_wdata_reg[23: 16] : mshr_atom_wen[14]? atom_st_data[ 23: 16] : ret_data[ 87: 80],
                                       mshr_req_wen[gv_mshr][57]? data_wdata_reg[15:  8] : mshr_atom_wen[14]? atom_st_data[ 15:  8] : ret_data[ 79: 72],
                                       mshr_req_wen[gv_mshr][56]? data_wdata_reg[ 7:  0] : mshr_atom_wen[14]? atom_st_data[  7:  0] : ret_data[ 71: 64],
                                       mshr_req_wen[gv_mshr][55]? data_wdata_reg[63: 56] : mshr_atom_wen[13]? atom_st_data[ 63: 56] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][54]? data_wdata_reg[55: 48] : mshr_atom_wen[13]? atom_st_data[ 55: 48] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][53]? data_wdata_reg[47: 40] : mshr_atom_wen[13]? atom_st_data[ 47: 40] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][52]? data_wdata_reg[39: 32] : mshr_atom_wen[13]? atom_st_data[ 39: 32] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][51]? data_wdata_reg[31: 24] : mshr_atom_wen[12]? atom_st_data[ 31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][50]? data_wdata_reg[23: 16] : mshr_atom_wen[12]? atom_st_data[ 23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][49]? data_wdata_reg[15:  8] : mshr_atom_wen[12]? atom_st_data[ 15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][48]? data_wdata_reg[ 7:  0] : mshr_atom_wen[12]? atom_st_data[  7:  0] : ret_data[  7:  0],
                                       mshr_req_wen[gv_mshr][47]? data_wdata_reg[63: 56] : mshr_atom_wen[11]? atom_st_data[ 63: 56] : ret_data[127:120],
                                       mshr_req_wen[gv_mshr][46]? data_wdata_reg[55: 48] : mshr_atom_wen[11]? atom_st_data[ 55: 48] : ret_data[119:112],
                                       mshr_req_wen[gv_mshr][45]? data_wdata_reg[47: 40] : mshr_atom_wen[11]? atom_st_data[ 47: 40] : ret_data[111:104],
                                       mshr_req_wen[gv_mshr][44]? data_wdata_reg[39: 32] : mshr_atom_wen[11]? atom_st_data[ 39: 32] : ret_data[103: 96],
                                       mshr_req_wen[gv_mshr][43]? data_wdata_reg[31: 24] : mshr_atom_wen[10]? atom_st_data[ 31: 24] : ret_data[ 95: 88],
                                       mshr_req_wen[gv_mshr][42]? data_wdata_reg[23: 16] : mshr_atom_wen[10]? atom_st_data[ 23: 16] : ret_data[ 87: 80],
                                       mshr_req_wen[gv_mshr][41]? data_wdata_reg[15:  8] : mshr_atom_wen[10]? atom_st_data[ 15:  8] : ret_data[ 79: 72],
                                       mshr_req_wen[gv_mshr][40]? data_wdata_reg[ 7:  0] : mshr_atom_wen[10]? atom_st_data[  7:  0] : ret_data[ 71: 64],
                                       mshr_req_wen[gv_mshr][39]? data_wdata_reg[63: 56] : mshr_atom_wen[ 9]? atom_st_data[ 63: 56] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][38]? data_wdata_reg[55: 48] : mshr_atom_wen[ 9]? atom_st_data[ 55: 48] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][37]? data_wdata_reg[47: 40] : mshr_atom_wen[ 9]? atom_st_data[ 47: 40] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][36]? data_wdata_reg[39: 32] : mshr_atom_wen[ 9]? atom_st_data[ 39: 32] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][35]? data_wdata_reg[31: 24] : mshr_atom_wen[ 8]? atom_st_data[ 31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][34]? data_wdata_reg[23: 16] : mshr_atom_wen[ 8]? atom_st_data[ 23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][33]? data_wdata_reg[15:  8] : mshr_atom_wen[ 8]? atom_st_data[ 15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][32]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 8]? atom_st_data[  7:  0] : ret_data[  7:  0],
                                       mshr_req_wen[gv_mshr][31]? data_wdata_reg[63: 56] : mshr_atom_wen[ 7]? atom_st_data[ 63: 56] : ret_data[127:120],
                                       mshr_req_wen[gv_mshr][30]? data_wdata_reg[55: 48] : mshr_atom_wen[ 7]? atom_st_data[ 55: 48] : ret_data[119:112],
                                       mshr_req_wen[gv_mshr][29]? data_wdata_reg[47: 40] : mshr_atom_wen[ 7]? atom_st_data[ 47: 40] : ret_data[111:104],
                                       mshr_req_wen[gv_mshr][28]? data_wdata_reg[39: 32] : mshr_atom_wen[ 7]? atom_st_data[ 39: 32] : ret_data[103: 96],
                                       mshr_req_wen[gv_mshr][27]? data_wdata_reg[31: 24] : mshr_atom_wen[ 6]? atom_st_data[ 31: 24] : ret_data[ 95: 88],
                                       mshr_req_wen[gv_mshr][26]? data_wdata_reg[23: 16] : mshr_atom_wen[ 6]? atom_st_data[ 23: 16] : ret_data[ 87: 80],
                                       mshr_req_wen[gv_mshr][25]? data_wdata_reg[15:  8] : mshr_atom_wen[ 6]? atom_st_data[ 15:  8] : ret_data[ 79: 72],
                                       mshr_req_wen[gv_mshr][24]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 6]? atom_st_data[  7:  0] : ret_data[ 71: 64],
                                       mshr_req_wen[gv_mshr][23]? data_wdata_reg[63: 56] : mshr_atom_wen[ 5]? atom_st_data[ 63: 56] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][22]? data_wdata_reg[55: 48] : mshr_atom_wen[ 5]? atom_st_data[ 55: 48] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][21]? data_wdata_reg[47: 40] : mshr_atom_wen[ 5]? atom_st_data[ 47: 40] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][20]? data_wdata_reg[39: 32] : mshr_atom_wen[ 5]? atom_st_data[ 39: 32] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][19]? data_wdata_reg[31: 24] : mshr_atom_wen[ 4]? atom_st_data[ 31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][18]? data_wdata_reg[23: 16] : mshr_atom_wen[ 4]? atom_st_data[ 23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][17]? data_wdata_reg[15:  8] : mshr_atom_wen[ 4]? atom_st_data[ 15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][16]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 4]? atom_st_data[  7:  0] : ret_data[  7:  0],
                                       mshr_req_wen[gv_mshr][15]? data_wdata_reg[63: 56] : mshr_atom_wen[ 3]? atom_st_data[ 63: 56] : ret_data[127:120],
                                       mshr_req_wen[gv_mshr][14]? data_wdata_reg[55: 48] : mshr_atom_wen[ 3]? atom_st_data[ 55: 48] : ret_data[119:112],
                                       mshr_req_wen[gv_mshr][13]? data_wdata_reg[47: 40] : mshr_atom_wen[ 3]? atom_st_data[ 47: 40] : ret_data[111:104],
                                       mshr_req_wen[gv_mshr][12]? data_wdata_reg[39: 32] : mshr_atom_wen[ 3]? atom_st_data[ 39: 32] : ret_data[103: 96],
                                       mshr_req_wen[gv_mshr][11]? data_wdata_reg[31: 24] : mshr_atom_wen[ 2]? atom_st_data[ 31: 24] : ret_data[ 95: 88],
                                       mshr_req_wen[gv_mshr][10]? data_wdata_reg[23: 16] : mshr_atom_wen[ 2]? atom_st_data[ 23: 16] : ret_data[ 87: 80],
                                       mshr_req_wen[gv_mshr][ 9]? data_wdata_reg[15:  8] : mshr_atom_wen[ 2]? atom_st_data[ 15:  8] : ret_data[ 79: 72],
                                       mshr_req_wen[gv_mshr][ 8]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 2]? atom_st_data[  7:  0] : ret_data[ 71: 64],
                                       mshr_req_wen[gv_mshr][ 7]? data_wdata_reg[63: 56] : mshr_atom_wen[ 1]? atom_st_data[ 63: 56] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][ 6]? data_wdata_reg[55: 48] : mshr_atom_wen[ 1]? atom_st_data[ 55: 48] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][ 5]? data_wdata_reg[47: 40] : mshr_atom_wen[ 1]? atom_st_data[ 47: 40] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][ 4]? data_wdata_reg[39: 32] : mshr_atom_wen[ 1]? atom_st_data[ 39: 32] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][ 3]? data_wdata_reg[31: 24] : mshr_atom_wen[ 0]? atom_st_data[ 31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][ 2]? data_wdata_reg[23: 16] : mshr_atom_wen[ 0]? atom_st_data[ 23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][ 1]? data_wdata_reg[15:  8] : mshr_atom_wen[ 0]? atom_st_data[ 15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][ 0]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 0]? atom_st_data[  7:  0] : ret_data[  7:  0]};
  `elsif LA32
    assign mshr_data_wdata[gv_mshr] = {mshr_req_wen[gv_mshr][31]? data_wdata_reg[31: 24] : mshr_atom_wen[ 7]? atom_st_data[31: 24] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][30]? data_wdata_reg[23: 16] : mshr_atom_wen[ 7]? atom_st_data[23: 16] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][29]? data_wdata_reg[15:  8] : mshr_atom_wen[ 7]? atom_st_data[15:  8] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][28]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 7]? atom_st_data[ 7:  0] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][27]? data_wdata_reg[31: 24] : mshr_atom_wen[ 6]? atom_st_data[31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][26]? data_wdata_reg[23: 16] : mshr_atom_wen[ 6]? atom_st_data[23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][25]? data_wdata_reg[15:  8] : mshr_atom_wen[ 6]? atom_st_data[15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][24]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 6]? atom_st_data[ 7:  0] : ret_data[  7:  0],
                                       mshr_req_wen[gv_mshr][23]? data_wdata_reg[31: 24] : mshr_atom_wen[ 5]? atom_st_data[31: 24] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][22]? data_wdata_reg[23: 16] : mshr_atom_wen[ 5]? atom_st_data[23: 16] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][21]? data_wdata_reg[15:  8] : mshr_atom_wen[ 5]? atom_st_data[15:  8] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][20]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 5]? atom_st_data[ 7:  0] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][19]? data_wdata_reg[31: 24] : mshr_atom_wen[ 4]? atom_st_data[31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][18]? data_wdata_reg[23: 16] : mshr_atom_wen[ 4]? atom_st_data[23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][17]? data_wdata_reg[15:  8] : mshr_atom_wen[ 4]? atom_st_data[15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][16]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 4]? atom_st_data[ 7:  0] : ret_data[  7:  0],
                                       mshr_req_wen[gv_mshr][15]? data_wdata_reg[31: 24] : mshr_atom_wen[ 3]? atom_st_data[31: 24] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][14]? data_wdata_reg[23: 16] : mshr_atom_wen[ 3]? atom_st_data[23: 16] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][13]? data_wdata_reg[15:  8] : mshr_atom_wen[ 3]? atom_st_data[15:  8] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][12]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 3]? atom_st_data[ 7:  0] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][11]? data_wdata_reg[31: 24] : mshr_atom_wen[ 2]? atom_st_data[31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][10]? data_wdata_reg[23: 16] : mshr_atom_wen[ 2]? atom_st_data[23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][ 9]? data_wdata_reg[15:  8] : mshr_atom_wen[ 2]? atom_st_data[15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][ 8]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 2]? atom_st_data[ 7:  0] : ret_data[  7:  0],
                                       mshr_req_wen[gv_mshr][ 7]? data_wdata_reg[31: 24] : mshr_atom_wen[ 1]? atom_st_data[31: 24] : ret_data[ 63: 56],
                                       mshr_req_wen[gv_mshr][ 6]? data_wdata_reg[23: 16] : mshr_atom_wen[ 1]? atom_st_data[23: 16] : ret_data[ 55: 48],
                                       mshr_req_wen[gv_mshr][ 5]? data_wdata_reg[15:  8] : mshr_atom_wen[ 1]? atom_st_data[15:  8] : ret_data[ 47: 40],
                                       mshr_req_wen[gv_mshr][ 4]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 1]? atom_st_data[ 7:  0] : ret_data[ 39: 32],
                                       mshr_req_wen[gv_mshr][ 3]? data_wdata_reg[31: 24] : mshr_atom_wen[ 0]? atom_st_data[31: 24] : ret_data[ 31: 24],
                                       mshr_req_wen[gv_mshr][ 2]? data_wdata_reg[23: 16] : mshr_atom_wen[ 0]? atom_st_data[23: 16] : ret_data[ 23: 16],
                                       mshr_req_wen[gv_mshr][ 1]? data_wdata_reg[15:  8] : mshr_atom_wen[ 0]? atom_st_data[15:  8] : ret_data[ 15:  8],
                                       mshr_req_wen[gv_mshr][ 0]? data_wdata_reg[ 7:  0] : mshr_atom_wen[ 0]? atom_st_data[ 7:  0] : ret_data[  7:  0]};
  `endif
    assign mshr_recv_wen[gv_mshr] = {mshr_data_recv[gv_mshr] & !mshr_data_record[gv_mshr][3] & mshr_data_record[gv_mshr][2],
                                     mshr_data_recv[gv_mshr] & !mshr_data_record[gv_mshr][2] & mshr_data_record[gv_mshr][1],
                                     mshr_data_recv[gv_mshr] & !mshr_data_record[gv_mshr][1] & mshr_data_record[gv_mshr][0],
                                     mshr_data_recv[gv_mshr] & !mshr_data_record[gv_mshr][0]};

    assign mshr_req_wen[gv_mshr]  = {
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b111 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b110 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b101 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b100 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b011 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b010 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b001 && data_wstrb_reg[0],
                        `ifdef LA64  mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[7],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[6],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[5],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[4],
                        `endif       mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[3],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[2],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[1],
                                     mshr_new_sreq[gv_mshr] && bank == 3'b000 && data_wstrb_reg[0]};

  `ifdef LA64
    assign mshr_data_wen[gv_mshr] = {mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][63] | mshr_req_wen[gv_mshr][63] | mshr_atom_wen[15],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][62] | mshr_req_wen[gv_mshr][62] | mshr_atom_wen[15],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][61] | mshr_req_wen[gv_mshr][61] | mshr_atom_wen[15],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][60] | mshr_req_wen[gv_mshr][60] | mshr_atom_wen[15],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][59] | mshr_req_wen[gv_mshr][59] | mshr_atom_wen[14],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][58] | mshr_req_wen[gv_mshr][58] | mshr_atom_wen[14],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][57] | mshr_req_wen[gv_mshr][57] | mshr_atom_wen[14],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][56] | mshr_req_wen[gv_mshr][56] | mshr_atom_wen[14],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][55] | mshr_req_wen[gv_mshr][55] | mshr_atom_wen[13],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][54] | mshr_req_wen[gv_mshr][54] | mshr_atom_wen[13],
                                     mshr_recop_tag_recordecv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][52] | mshr_req_wen[gv_mshr][52] | mshr_atom_wen[13],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][51] | mshr_req_wen[gv_mshr][51] | mshr_atom_wen[12],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][50] | mshr_req_wen[gv_mshr][50] | mshr_atom_wen[12],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][49] | mshr_req_wen[gv_mshr][49] | mshr_atom_wen[12],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][48] | mshr_req_wen[gv_mshr][48] | mshr_atom_wen[12],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][47] | mshr_req_wen[gv_mshr][47] | mshr_atom_wen[11],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][46] | mshr_req_wen[gv_mshr][46] | mshr_atom_wen[11],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][45] | mshr_req_wen[gv_mshr][45] | mshr_atom_wen[11],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][44] | mshr_req_wen[gv_mshr][44] | mshr_atom_wen[11],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][43] | mshr_req_wen[gv_mshr][43] | mshr_atom_wen[10],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][42] | mshr_req_wen[gv_mshr][42] | mshr_atom_wen[10],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][41] | mshr_req_wen[gv_mshr][41] | mshr_atom_wen[10],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][40] | mshr_req_wen[gv_mshr][40] | mshr_atom_wen[10],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][39] | mshr_req_wen[gv_mshr][39] | mshr_atom_wen[ 9],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][38] | mshr_req_wen[gv_mshr][38] | mshr_atom_wen[ 9],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][37] | mshr_req_wen[gv_mshr][37] | mshr_atom_wen[ 9],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][36] | mshr_req_wen[gv_mshr][36] | mshr_atom_wen[ 9],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][35] | mshr_req_wen[gv_mshr][35] | mshr_atom_wen[ 8],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][34] | mshr_req_wen[gv_mshr][34] | mshr_atom_wen[ 8],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][33] | mshr_req_wen[gv_mshr][33] | mshr_atom_wen[ 8],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][32] | mshr_req_wen[gv_mshr][32] | mshr_atom_wen[ 8],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][31] | mshr_req_wen[gv_mshr][31] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][30] | mshr_req_wen[gv_mshr][30] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][29] | mshr_req_wen[gv_mshr][29] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][28] | mshr_req_wen[gv_mshr][28] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][27] | mshr_req_wen[gv_mshr][27] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][26] | mshr_req_wen[gv_mshr][26] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][25] | mshr_req_wen[gv_mshr][25] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][24] | mshr_req_wen[gv_mshr][24] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][23] | mshr_req_wen[gv_mshr][23] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][22] | mshr_req_wen[gv_mshr][22] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][21] | mshr_req_wen[gv_mshr][21] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][20] | mshr_req_wen[gv_mshr][20] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][19] | mshr_req_wen[gv_mshr][19] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][18] | mshr_req_wen[gv_mshr][18] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][17] | mshr_req_wen[gv_mshr][17] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][16] | mshr_req_wen[gv_mshr][16] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][15] | mshr_req_wen[gv_mshr][15] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][14] | mshr_req_wen[gv_mshr][14] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][13] | mshr_req_wen[gv_mshr][13] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][12] | mshr_req_wen[gv_mshr][12] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][11] | mshr_req_wen[gv_mshr][11] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][10] | mshr_req_wen[gv_mshr][10] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 9] | mshr_req_wen[gv_mshr][ 9] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 8] | mshr_req_wen[gv_mshr][ 8] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 7] | mshr_req_wen[gv_mshr][ 7] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 6] | mshr_req_wen[gv_mshr][ 6] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 5] | mshr_req_wen[gv_mshr][ 5] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 4] | mshr_req_wen[gv_mshr][ 4] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 3] | mshr_req_wen[gv_mshr][ 3] | mshr_atom_wen[ 0],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 2] | mshr_req_wen[gv_mshr][ 2] | mshr_atom_wen[ 0],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 1] | mshr_req_wen[gv_mshr][ 1] | mshr_atom_wen[ 0],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 0] | mshr_req_wen[gv_mshr][ 0] | mshr_atom_wen[ 0]};
  `elsif LA32
    assign mshr_data_wen[gv_mshr] = {mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][31] | mshr_req_wen[gv_mshr][31] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][30] | mshr_req_wen[gv_mshr][30] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][29] | mshr_req_wen[gv_mshr][29] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][28] | mshr_req_wen[gv_mshr][28] | mshr_atom_wen[ 7],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][27] | mshr_req_wen[gv_mshr][27] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][26] | mshr_req_wen[gv_mshr][26] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][25] | mshr_req_wen[gv_mshr][25] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][3] & !mshr_wstrb[gv_mshr][24] | mshr_req_wen[gv_mshr][24] | mshr_atom_wen[ 6],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][23] | mshr_req_wen[gv_mshr][23] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][22] | mshr_req_wen[gv_mshr][22] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][21] | mshr_req_wen[gv_mshr][21] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][20] | mshr_req_wen[gv_mshr][20] | mshr_atom_wen[ 5],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][19] | mshr_req_wen[gv_mshr][19] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][18] | mshr_req_wen[gv_mshr][18] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][17] | mshr_req_wen[gv_mshr][17] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][2] & !mshr_wstrb[gv_mshr][16] | mshr_req_wen[gv_mshr][16] | mshr_atom_wen[ 4],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][15] | mshr_req_wen[gv_mshr][15] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][14] | mshr_req_wen[gv_mshr][14] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][13] | mshr_req_wen[gv_mshr][13] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][12] | mshr_req_wen[gv_mshr][12] | mshr_atom_wen[ 3],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][11] | mshr_req_wen[gv_mshr][11] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][10] | mshr_req_wen[gv_mshr][10] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][ 9] | mshr_req_wen[gv_mshr][ 9] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][1] & !mshr_wstrb[gv_mshr][ 8] | mshr_req_wen[gv_mshr][ 8] | mshr_atom_wen[ 2],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 7] | mshr_req_wen[gv_mshr][ 7] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 6] | mshr_req_wen[gv_mshr][ 6] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 5] | mshr_req_wen[gv_mshr][ 5] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 4] | mshr_req_wen[gv_mshr][ 4] | mshr_atom_wen[ 1],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 3] | mshr_req_wen[gv_mshr][ 3] | mshr_atom_wen[ 0],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 2] | mshr_req_wen[gv_mshr][ 2] | mshr_atom_wen[ 0],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 1] | mshr_req_wen[gv_mshr][ 1] | mshr_atom_wen[ 0],
                                     mshr_recv_wen[gv_mshr][0] & !mshr_wstrb[gv_mshr][ 0] | mshr_req_wen[gv_mshr][ 0] | mshr_atom_wen[ 0]};
  `endif
    always @(posedge clk) begin
      if(|mshr_data_wen[gv_mshr])
        mshr_data[gv_mshr] <= {
                               `ifdef LA64
                               mshr_data_wen[gv_mshr][63]? mshr_data_wdata[gv_mshr][511:504] : mshr_data[gv_mshr][511:504],
                               mshr_data_wen[gv_mshr][62]? mshr_data_wdata[gv_mshr][503:496] : mshr_data[gv_mshr][503:496],
                               mshr_data_wen[gv_mshr][61]? mshr_data_wdata[gv_mshr][495:488] : mshr_data[gv_mshr][495:488],
                               mshr_data_wen[gv_mshr][60]? mshr_data_wdata[gv_mshr][487:480] : mshr_data[gv_mshr][487:480],
                               mshr_data_wen[gv_mshr][59]? mshr_data_wdata[gv_mshr][479:472] : mshr_data[gv_mshr][479:472],
                               mshr_data_wen[gv_mshr][58]? mshr_data_wdata[gv_mshr][471:464] : mshr_data[gv_mshr][471:464],
                               mshr_data_wen[gv_mshr][57]? mshr_data_wdata[gv_mshr][463:456] : mshr_data[gv_mshr][463:456],
                               mshr_data_wen[gv_mshr][56]? mshr_data_wdata[gv_mshr][455:448] : mshr_data[gv_mshr][455:448],
                               mshr_data_wen[gv_mshr][55]? mshr_data_wdata[gv_mshr][447:440] : mshr_data[gv_mshr][447:440],
                               mshr_data_wen[gv_mshr][54]? mshr_data_wdata[gv_mshr][439:432] : mshr_data[gv_mshr][439:432],
                               mshr_data_wen[gv_mshr][53]? mshr_data_wdata[gv_mshr][431:424] : mshr_data[gv_mshr][431:424],
                               mshr_data_wen[gv_mshr][52]? mshr_data_wdata[gv_mshr][423:416] : mshr_data[gv_mshr][423:416],
                               mshr_data_wen[gv_mshr][51]? mshr_data_wdata[gv_mshr][415:408] : mshr_data[gv_mshr][415:408],
                               mshr_data_wen[gv_mshr][50]? mshr_data_wdata[gv_mshr][407:400] : mshr_data[gv_mshr][407:400],
                               mshr_data_wen[gv_mshr][49]? mshr_data_wdata[gv_mshr][399:392] : mshr_data[gv_mshr][399:392],
                               mshr_data_wen[gv_mshr][48]? mshr_data_wdata[gv_mshr][391:384] : mshr_data[gv_mshr][391:384],
                               mshr_data_wen[gv_mshr][47]? mshr_data_wdata[gv_mshr][383:376] : mshr_data[gv_mshr][383:376],
                               mshr_data_wen[gv_mshr][46]? mshr_data_wdata[gv_mshr][375:368] : mshr_data[gv_mshr][375:368],
                               mshr_data_wen[gv_mshr][45]? mshr_data_wdata[gv_mshr][367:360] : mshr_data[gv_mshr][367:360],
                               mshr_data_wen[gv_mshr][44]? mshr_data_wdata[gv_mshr][359:352] : mshr_data[gv_mshr][359:352],
                               mshr_data_wen[gv_mshr][43]? mshr_data_wdata[gv_mshr][351:344] : mshr_data[gv_mshr][351:344],
                               mshr_data_wen[gv_mshr][42]? mshr_data_wdata[gv_mshr][343:336] : mshr_data[gv_mshr][343:336],
                               mshr_data_wen[gv_mshr][41]? mshr_data_wdata[gv_mshr][335:328] : mshr_data[gv_mshr][335:328],
                               mshr_data_wen[gv_mshr][40]? mshr_data_wdata[gv_mshr][327:320] : mshr_data[gv_mshr][327:320],
                               mshr_data_wen[gv_mshr][39]? mshr_data_wdata[gv_mshr][319:312] : mshr_data[gv_mshr][319:312],
                               mshr_data_wen[gv_mshr][38]? mshr_data_wdata[gv_mshr][311:304] : mshr_data[gv_mshr][311:304],
                               mshr_data_wen[gv_mshr][37]? mshr_data_wdata[gv_mshr][303:296] : mshr_data[gv_mshr][303:296],
                               mshr_data_wen[gv_mshr][36]? mshr_data_wdata[gv_mshr][295:288] : mshr_data[gv_mshr][295:288],
                               mshr_data_wen[gv_mshr][35]? mshr_data_wdata[gv_mshr][287:280] : mshr_data[gv_mshr][287:280],
                               mshr_data_wen[gv_mshr][34]? mshr_data_wdata[gv_mshr][279:272] : mshr_data[gv_mshr][279:272],
                               mshr_data_wen[gv_mshr][33]? mshr_data_wdata[gv_mshr][271:264] : mshr_data[gv_mshr][271:264],
                               mshr_data_wen[gv_mshr][32]? mshr_data_wdata[gv_mshr][263:256] : mshr_data[gv_mshr][263:256],
                               `endif
                               mshr_data_wen[gv_mshr][31]? mshr_data_wdata[gv_mshr][255:248] : mshr_data[gv_mshr][255:248],
                               mshr_data_wen[gv_mshr][30]? mshr_data_wdata[gv_mshr][247:240] : mshr_data[gv_mshr][247:240],
                               mshr_data_wen[gv_mshr][29]? mshr_data_wdata[gv_mshr][239:232] : mshr_data[gv_mshr][239:232],
                               mshr_data_wen[gv_mshr][28]? mshr_data_wdata[gv_mshr][231:224] : mshr_data[gv_mshr][231:224],
                               mshr_data_wen[gv_mshr][27]? mshr_data_wdata[gv_mshr][223:216] : mshr_data[gv_mshr][223:216],
                               mshr_data_wen[gv_mshr][26]? mshr_data_wdata[gv_mshr][215:208] : mshr_data[gv_mshr][215:208],
                               mshr_data_wen[gv_mshr][25]? mshr_data_wdata[gv_mshr][207:200] : mshr_data[gv_mshr][207:200],
                               mshr_data_wen[gv_mshr][24]? mshr_data_wdata[gv_mshr][199:192] : mshr_data[gv_mshr][199:192],
                               mshr_data_wen[gv_mshr][23]? mshr_data_wdata[gv_mshr][191:184] : mshr_data[gv_mshr][191:184],
                               mshr_data_wen[gv_mshr][22]? mshr_data_wdata[gv_mshr][183:176] : mshr_data[gv_mshr][183:176],
                               mshr_data_wen[gv_mshr][21]? mshr_data_wdata[gv_mshr][175:168] : mshr_data[gv_mshr][175:168],
                               mshr_data_wen[gv_mshr][20]? mshr_data_wdata[gv_mshr][167:160] : mshr_data[gv_mshr][167:160],
                               mshr_data_wen[gv_mshr][19]? mshr_data_wdata[gv_mshr][159:152] : mshr_data[gv_mshr][159:152],
                               mshr_data_wen[gv_mshr][18]? mshr_data_wdata[gv_mshr][151:144] : mshr_data[gv_mshr][151:144],
                               mshr_data_wen[gv_mshr][17]? mshr_data_wdata[gv_mshr][143:136] : mshr_data[gv_mshr][143:136],
                               mshr_data_wen[gv_mshr][16]? mshr_data_wdata[gv_mshr][135:128] : mshr_data[gv_mshr][135:128],
                               mshr_data_wen[gv_mshr][15]? mshr_data_wdata[gv_mshr][127:120] : mshr_data[gv_mshr][127:120],
                               mshr_data_wen[gv_mshr][14]? mshr_data_wdata[gv_mshr][119:112] : mshr_data[gv_mshr][119:112],
                               mshr_data_wen[gv_mshr][13]? mshr_data_wdata[gv_mshr][111:104] : mshr_data[gv_mshr][111:104],
                               mshr_data_wen[gv_mshr][12]? mshr_data_wdata[gv_mshr][103: 96] : mshr_data[gv_mshr][103: 96],
                               mshr_data_wen[gv_mshr][11]? mshr_data_wdata[gv_mshr][ 95: 88] : mshr_data[gv_mshr][ 95: 88],
                               mshr_data_wen[gv_mshr][10]? mshr_data_wdata[gv_mshr][ 87: 80] : mshr_data[gv_mshr][ 87: 80],
                               mshr_data_wen[gv_mshr][ 9]? mshr_data_wdata[gv_mshr][ 79: 72] : mshr_data[gv_mshr][ 79: 72],
                               mshr_data_wen[gv_mshr][ 8]? mshr_data_wdata[gv_mshr][ 71: 64] : mshr_data[gv_mshr][ 71: 64],
                               mshr_data_wen[gv_mshr][ 7]? mshr_data_wdata[gv_mshr][ 63: 56] : mshr_data[gv_mshr][ 63: 56],
                               mshr_data_wen[gv_mshr][ 6]? mshr_data_wdata[gv_mshr][ 55: 48] : mshr_data[gv_mshr][ 55: 48],
                               mshr_data_wen[gv_mshr][ 5]? mshr_data_wdata[gv_mshr][ 47: 40] : mshr_data[gv_mshr][ 47: 40],
                               mshr_data_wen[gv_mshr][ 4]? mshr_data_wdata[gv_mshr][ 39: 32] : mshr_data[gv_mshr][ 39: 32],
                               mshr_data_wen[gv_mshr][ 3]? mshr_data_wdata[gv_mshr][ 31: 24] : mshr_data[gv_mshr][ 31: 24],
                               mshr_data_wen[gv_mshr][ 2]? mshr_data_wdata[gv_mshr][ 23: 16] : mshr_data[gv_mshr][ 23: 16],
                               mshr_data_wen[gv_mshr][ 1]? mshr_data_wdata[gv_mshr][ 15:  8] : mshr_data[gv_mshr][ 15:  8],
                               mshr_data_wen[gv_mshr][ 0]? mshr_data_wdata[gv_mshr][  7:  0] : mshr_data[gv_mshr][  7:  0]};
    end

    always @(posedge clk) begin
      if(mshr_alloc[gv_mshr])
        mshr_data_record[gv_mshr] <= {`MSHR_RECORD_LEN{1'b0}};
      else if(mshr_data_recv[gv_mshr])
        mshr_data_record[gv_mshr] <= {mshr_data_record[gv_mshr][2]? 1'b1 : 1'b0,
                                      mshr_data_record[gv_mshr][1]? 1'b1 : 1'b0,
                                      mshr_data_record[gv_mshr][0]? 1'b1 : 1'b0,
                                                                           1'b1};
    end

    always @(posedge clk) begin
      if(mshr_data_recv[gv_mshr] && mshr_data_record[gv_mshr][0])
        mshr_rstate[gv_mshr] <= ret_rstate;
        mshr_rscway[gv_mshr] <= ret_rscway;
    end

  end
endgenerate
// ------------------------- END --------------------------



// ------------------ Read & Write Data -------------------
assign rdata_way0[0] = rdata_way[0][`BANK0_BITS];
assign rdata_way0[1] = rdata_way[0][`BANK1_BITS];
assign rdata_way0[2] = rdata_way[0][`BANK2_BITS];
assign rdata_way0[3] = rdata_way[0][`BANK3_BITS];
assign rdata_way0[4] = rdata_way[0][`BANK4_BITS];
assign rdata_way0[5] = rdata_way[0][`BANK5_BITS];
assign rdata_way0[6] = rdata_way[0][`BANK6_BITS];
assign rdata_way0[7] = rdata_way[0][`BANK7_BITS];

assign rdata_way1[0] = rdata_way[1][`BANK0_BITS];
assign rdata_way1[1] = rdata_way[1][`BANK1_BITS];
assign rdata_way1[2] = rdata_way[1][`BANK2_BITS];
assign rdata_way1[3] = rdata_way[1][`BANK3_BITS];
assign rdata_way1[4] = rdata_way[1][`BANK4_BITS];
assign rdata_way1[5] = rdata_way[1][`BANK5_BITS];
assign rdata_way1[6] = rdata_way[1][`BANK6_BITS];
assign rdata_way1[7] = rdata_way[1][`BANK7_BITS];

assign rdata_way2[0] = rdata_way[2][`BANK0_BITS];
assign rdata_way2[1] = rdata_way[2][`BANK1_BITS];
assign rdata_way2[2] = rdata_way[2][`BANK2_BITS];
assign rdata_way2[3] = rdata_way[2][`BANK3_BITS];
assign rdata_way2[4] = rdata_way[2][`BANK4_BITS];
assign rdata_way2[5] = rdata_way[2][`BANK5_BITS];
assign rdata_way2[6] = rdata_way[2][`BANK6_BITS];
assign rdata_way2[7] = rdata_way[2][`BANK7_BITS];

assign rdata_way3[0] = rdata_way[3][`BANK0_BITS];
assign rdata_way3[1] = rdata_way[3][`BANK1_BITS];
assign rdata_way3[2] = rdata_way[3][`BANK2_BITS];
assign rdata_way3[3] = rdata_way[3][`BANK3_BITS];
assign rdata_way3[4] = rdata_way[3][`BANK4_BITS];
assign rdata_way3[5] = rdata_way[3][`BANK5_BITS];
assign rdata_way3[6] = rdata_way[3][`BANK6_BITS];
assign rdata_way3[7] = rdata_way[3][`BANK7_BITS];

assign data_rd_idle = (state_idle || state_lkup && tlb_valid_finish) && data_req && !data_wr;

genvar gv_data; // WAY index
generate
  for(gv_data = 0; gv_data < `D_WAY_NUM; gv_data = gv_data + 1)
  begin : data_module
    always @(posedge clk) begin
      if(rst)
        data_ram_clk_en[gv_data] <= 1'b1;
    end

    assign data_wen_bank0[gv_data] = replace_wen_bank0[gv_data] | wstrb_wen_bank0[gv_data];
    assign data_wen_bank1[gv_data] = replace_wen_bank1[gv_data] | wstrb_wen_bank1[gv_data];
    assign data_wen_bank2[gv_data] = replace_wen_bank2[gv_data] | wstrb_wen_bank2[gv_data];
    assign data_wen_bank3[gv_data] = replace_wen_bank3[gv_data] | wstrb_wen_bank3[gv_data];
    assign data_wen_bank4[gv_data] = replace_wen_bank4[gv_data] | wstrb_wen_bank4[gv_data];
    assign data_wen_bank5[gv_data] = replace_wen_bank5[gv_data] | wstrb_wen_bank5[gv_data];
    assign data_wen_bank6[gv_data] = replace_wen_bank6[gv_data] | wstrb_wen_bank6[gv_data];
    assign data_wen_bank7[gv_data] = replace_wen_bank7[gv_data] | wstrb_wen_bank7[gv_data];
  
    assign replace_wen_bank0[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank1[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank2[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank3[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank4[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank5[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank6[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};
    assign replace_wen_bank7[gv_data] = {`WSTRB_WIDTH{(|mshr_rfil) & replaced_way == gv_data}};

    assign wstrb_wen_bank0[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b000}} & wr_buff_wstrb;
    assign wstrb_wen_bank1[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b001}} & wr_buff_wstrb;
    assign wstrb_wen_bank2[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b010}} & wr_buff_wstrb;
    assign wstrb_wen_bank3[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b011}} & wr_buff_wstrb;
    assign wstrb_wen_bank4[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b100}} & wr_buff_wstrb;
    assign wstrb_wen_bank5[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b101}} & wr_buff_wstrb;
    assign wstrb_wen_bank6[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b110}} & wr_buff_wstrb;
    assign wstrb_wen_bank7[gv_data] = {`WSTRB_WIDTH{wr_buff_release & wr_buff_way == gv_data & wr_buff_bank == 3'b111}} & wr_buff_wstrb;

    assign op_data_en[gv_data] = state_oprd && (cache_op_code[`IDX_INV_WB] || cache_op_code[`HIT_INV_WB])    ||
                                 state_ophd && cache_op_code[`IDX_INV_WB] && cache_op_way == gv_data  ||
                                 state_ophd && cache_op_code[`HIT_INV_WB] && op_wayhit_record[gv_data];

    assign ex_data_en[gv_data] = ex_handle && (ex_op[`INV_WTBK] || ex_op[`WTBK]) && ex_wayhit_reg[gv_data] && !ex_handle_fin;

    assign data_array_en[gv_data][0] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd0                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd0                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd0                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][1] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd1                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd1                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd1                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][2] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd2                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd2                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd2                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][3] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd3                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd3                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd3                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][4] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd4                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd4                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd4                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][5] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd5                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd5                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd5                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][6] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd6                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd6                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd6                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
    assign data_array_en[gv_data][7] = (data_rd_idle && data_addr[`D_BANK_BITS] == 3'd7                ) ||
                                       (state_lkup && !tlb_valid_ret && bank == 3'd7                   ) ||
                                       (wr_buff_release && wr_buff_bank == 3'd7                        ) ||
                                       (|mshr_wr_darray && replaced_way == gv_data || |mshr_lkup_darray) ||
                                       (op_data_en[gv_data] || ex_data_en[gv_data]                     ) ;
  end
endgenerate

assign ex_data_addr = {ex_pgcl[0], ex_paddr[11:`D_LINE_LEN]};

genvar gv_addr;
generate
  for (gv_addr = 0; gv_addr < `D_BANK_NUM; gv_addr = gv_addr + 1 )
  begin : gen_addr
    assign data_addr_later[gv_addr] = state_lkup & !tlb_valid_finish;
    assign data_addr_wr[gv_addr]    = wr_buff_release && wr_buff_valid && wr_buff_bank == gv_addr;

    assign data_array_addr[gv_addr] = (|mshr_use_darray        )? mshr_use_index          :
                                      (data_addr_wr[gv_addr]   )? wr_buff_index           :
                                      (|ex_data_en             )? ex_data_addr            :
                                      (|op_data_en             )? cache_op_index          :
                                      (data_addr_later[gv_addr])? index                   :
                                                                  data_addr[`D_INDEX_BITS];
  end
endgenerate

assign data_array_wdata[0] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK0_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK0_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK0_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK0_BITS]) ;
assign data_array_wdata[1] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK1_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK1_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK1_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK1_BITS]) ;
assign data_array_wdata[2] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK2_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK2_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK2_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK2_BITS]) ;
assign data_array_wdata[3] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK3_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK3_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK3_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK3_BITS]) ;
assign data_array_wdata[4] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK4_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK4_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK4_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK4_BITS]) ;
assign data_array_wdata[5] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK5_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK5_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK5_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK5_BITS]) ;
assign data_array_wdata[6] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK6_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK6_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK6_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK6_BITS]) ;
assign data_array_wdata[7] = ({`GRLEN{wr_buff_release & wr_buff_valid}} & wr_buff_ram_wdata        ) |
                             ({`GRLEN{mshr_wr_darray[0]              }} & mshr_data[0][`BANK7_BITS]) |
                             ({`GRLEN{mshr_wr_darray[1]              }} & mshr_data[1][`BANK7_BITS]) |
                             ({`GRLEN{mshr_wr_darray[2]              }} & mshr_data[2][`BANK7_BITS]) |
                             ({`GRLEN{mshr_wr_darray[3]              }} & mshr_data[3][`BANK7_BITS]) ;

wire st_ld_conflict;
wire load_miss_exist;
//wire uncache_exist;
wire extreq_exist;
wire ucst_exist;
wire atom_exist;

assign load_miss_exist = cache_miss && !data_wr_reg || mshr_send_cpu && !mshr_data_ok;
assign st_ld_conflict  = data_wr_reg && wr_buff_valid && !wr_buff_hit && wr_buff_bank == data_addr[`D_BANK_BITS];
//assign uncache_exist   = !ud_wr_vacancy || tlb_valid_uncache && data_wr_reg;
assign extreq_exist    = ex_state != 2'b0;
assign ucst_exist      = tlb_valid_uncache && data_wr_reg;
assign atom_exist      = wr_buff_atom || mshr_atom;

assign pre_req_addr_ok = data_req && data_prefetch && (state_idle || tlb_valid_finish) &&
                         !(extreq_exist                                              ) &&
                         !(cache_op_req                                              ) &&
                         !(state_lkup && mshr_full                                   ) &&
                         !(ucst_exist                                                ) &&
                         !(|mshr_rfil                                                ) ; // TODO:

assign data_addr_ok = data_req && (state_idle || tlb_valid_finish) &&  // TODO: GOON?
                      !(extreq_exist                             ) &&
                      !(|mshr_handle || |mshr_lkup_darray        ) &&  // TODO: can ok when mshr_rfil and data_req are not in the same bank
                      !(load_miss_exist                          ) &&  // load miss TODO:remove this?
                      !(state_lkup && mshr_full                  ) &&  // To avoid two suspended req
                      !(ucst_exist                               ) &&
                      !(atom_exist                               ) &&
                      !(cache_op_req                             ) &&
                      !(st_ld_conflict                           ) ||  // store in tag compare & wr_buff valid
                      pre_req_addr_ok ;
                     // !(uncache_exist                            )    // 

assign hit_ld_data_ok = cache_hit && !data_wr_reg && !req_cancel && !prefetch_reg;
assign st_data_ok     = tlb_valid_ret && data_wr_reg;
assign mshr_data_ok   = |mshr_ld_ret;
assign error_data_ok  = tlb_valid_finish && !req_cancel && !tlb_hit;

assign data_data_ok   = hit_ld_data_ok |
                        mshr_data_ok   |
                        st_data_ok     |
                        error_data_ok  ;

assign req_empty      = mshr_empty && vic_empty;
// ------------------------- END --------------------------



// ----------------------- EXT REQ ------------------------
assign ex_req_recv = ex_req && (ex_idle || ex_handle_fin);

assign ex_rdtag_ready = ex_rdtag && !wr_buff_valid && (state_idle || !lrud_wr_valid || state_block);

assign ex_handle_fin = ex_wtbk_req && wr_ready == 1'b1;

assign ex_wtbk_req = ex_handle && (ex_op[`INV] || (ex_op[`INV_WTBK] || ex_op[`WTBK]) && (ex_rd_fin || !(|ex_wayhit_reg)));

always @(posedge clk) begin
  if(ex_req_recv) begin
    ex_op     <= ex_req_op    ;
    ex_paddr  <= ex_req_paddr ;
    ex_cpuno  <= ex_req_cpuno[`COREID_WIDTH-1:0];
    ex_pgcl   <= ex_req_pgcl  ;
    ex_dirqid <= ex_req_dirqid;
  end
end

assign ex_idle   = ex_state == 2'b00;
assign ex_rdtag  = ex_state == 2'b01;
assign ex_tagcmp = ex_state == 2'b10;
assign ex_handle = ex_state == 2'b11;

always @(posedge clk) begin
  if(rst)
    ex_state <= 2'b00;
  else if(ex_idle && ex_req)
    ex_state <= 2'b01;
  else if(ex_rdtag_ready)
    ex_state <= 2'b10;
  else if(ex_tagcmp)
    ex_state <= 2'b11;
  else if(ex_handle_fin)
    ex_state <= (ex_req)? 2'b01 : 2'b00;
end

always @(posedge clk) begin
  if(ex_tagcmp || ex_handle_fin)
    ex_rd_fin <= 1'b0;
  else if(ex_handle)
    ex_rd_fin <= 1'b1;
end

always @(posedge clk) begin
  if(ex_tagcmp) begin
    ex_wayhit_reg  <= ex_wayhit;
    ex_mshrhit_reg <= ex_mshr_hit;
    ex_dirty       <= ex_wayhit[3]   &  dirty_rdata[3] |
                      ex_wayhit[2]   &  dirty_rdata[2] |
                      ex_wayhit[1]   &  dirty_rdata[1] |
                      ex_wayhit[0]   &  dirty_rdata[0] |
                      ex_mshr_hit[3] &  mshr_dirty[3]  |
                      ex_mshr_hit[2] &  mshr_dirty[2]  |
                      ex_mshr_hit[1] &  mshr_dirty[1]  |
                      ex_mshr_hit[0] &  mshr_dirty[0]  ;
    ex_hit_state   <= {`STATE_LEN{ex_wayhit[3  ]}} & line_state[3]  |
                      {`STATE_LEN{ex_wayhit[2  ]}} & line_state[2]  |
                      {`STATE_LEN{ex_wayhit[1  ]}} & line_state[1]  |
                      {`STATE_LEN{ex_wayhit[0  ]}} & line_state[0]  |
                      {`STATE_LEN{ex_mshr_hit[3]}} & mshr_rstate[3] |
                      {`STATE_LEN{ex_mshr_hit[2]}} & mshr_rstate[2] |
                      {`STATE_LEN{ex_mshr_hit[1]}} & mshr_rstate[1] |
                      {`STATE_LEN{ex_mshr_hit[0]}} & mshr_rstate[0] ;
    ex_hit_scway   <= {`SCWAY_LEN{ex_wayhit[3]  }} & line_scway[3]  |
                      {`SCWAY_LEN{ex_wayhit[2]  }} & line_scway[2]  |
                      {`SCWAY_LEN{ex_wayhit[1]  }} & line_scway[1]  |
                      {`SCWAY_LEN{ex_wayhit[0]  }} & line_scway[0]  |
                      {`SCWAY_LEN{ex_mshr_hit[3]}} & mshr_rscway[3] |
                      {`SCWAY_LEN{ex_mshr_hit[2]}} & mshr_rscway[2] |
                      {`SCWAY_LEN{ex_mshr_hit[1]}} & mshr_rscway[1] |
                      {`SCWAY_LEN{ex_mshr_hit[0]}} & mshr_rscway[0] ;
  end
end
// ------------------------- END --------------------------



// ---------------------- cache op ------------------------
assign cache_op_addr_ok = cache_op_req && !wr_buff_valid && mshr_empty;
assign cache_op_ok      = state_ophd && ophd_finish || cache_op_error;
assign cache_op_error   = state_oprd && tlb_finish && !tlb_hit && cache_op_code[`HIT_INV_WB];

assign ophd_finish   = cache_op_code[`IDX_ST_TAG] || 
                       cache_op_code[`IDX_INV_WB] && (!op_dirty_record || !(|op_valid_record ) || op_wtbk_finish) ||
                       cache_op_code[`HIT_INV_WB] && (!op_dirty_record || !(|op_wayhit_record) || op_wtbk_finish) ;

assign op_wtbk_req    = op_need_wtbk;
assign op_wtbk_finish = op_need_wtbk && wr_ready == 1'b1;

assign op_need_wtbk  = state_ophd && (cache_op_code[`IDX_INV_WB] && op_dirty_record && |op_valid_record  ||
                                      cache_op_code[`HIT_INV_WB] && op_dirty_record && |op_wayhit_record );

always @(posedge clk) begin
  if(cache_op_addr_ok) begin
    cache_op_addr_his <= cache_op_addr; // TODO: can merge into data_vaddr ?
  	cache_op_code     <= cache_op;
  end
end

assign cache_op_index = cache_op_addr_his[`D_INDEX_BITS];
assign cache_op_way   = cache_op_addr_his[`D_WAY_BITS  ];

always @(posedge clk) begin
  if(state_oprd) begin
    op_dirty_record  <= (cache_op_code[`IDX_INV_WB])? dirty_rdata[cache_op_way] : dirty_rdata[way_decode];
    op_valid_record  <= line_state[cache_op_way];
  end

  if(state_oprd && tlb_finish) begin
    op_wayhit_record <= way_hit & {`D_WAY_NUM{!tlb_uncache}};
  end
end

// ------------------------- IO ---------------------------


// ---------------------- Prefetch ------------------------

// TODO: Add remiss in mshr

assign load_ref = tlb_finish && tlb_hit && !tlb_uncache && data_recv /*&& !data_wr_reg*/ && 
                 !prefetch_reg && !req_cancel && !ex2_cancel && !ex2_cancel_his;
assign prefetch_recv = data_req && data_prefetch && data_addr_ok;

prefetch_d u_prefetch_d
(
  .clk            (clk                          ),      
  .resetn         (resetn                       ),      
  .load_ref       (load_ref                     ),
  
  .cur_pc         (data_pc_reg                  ),
  .cur_paddr      ({tlb_ptag, index[11-`D_LINE_LEN:0], {`D_LINE_LEN{1'b0}}}),
  .cur_page_color ({1'b0, index[12 -`D_LINE_LEN]}),
  .prefetch_recv  (prefetch_recv                ),
  .prefetch_req   (prefetch_req                 ),
  .prefetch_pgcl  (prefetch_pgcl                ),
  .prefetch_paddr (prefetch_paddr               )

);
// ------------------------- IO ---------------------------



// ------------------------- IO ---------------------------
`ifdef D_MSHR_ENTRY4
  assign rd_req  = mshr_addr_wait[0] || 
                   mshr_addr_wait[1] || 
                   mshr_addr_wait[2] || 
                   mshr_addr_wait[3] ;
                   
  assign rd_addr = (mshr_addr_wait[0])? {mshr_ptag[0], mshr_index[0][11-`D_LINE_LEN:0], mshr_uncache[0]? mshr_rbank : `D_BANK_LEN'b0 ,`D_OFFSET_LEN'b0} :
                   (mshr_addr_wait[1])? {mshr_ptag[1], mshr_index[1][11-`D_LINE_LEN:0], mshr_uncache[1]? mshr_rbank : `D_BANK_LEN'b0 ,`D_OFFSET_LEN'b0} :
                   (mshr_addr_wait[2])? {mshr_ptag[2], mshr_index[2][11-`D_LINE_LEN:0], mshr_uncache[2]? mshr_rbank : `D_BANK_LEN'b0 ,`D_OFFSET_LEN'b0} :
                                        {mshr_ptag[3], mshr_index[3][11-`D_LINE_LEN:0], mshr_uncache[3]? mshr_rbank : `D_BANK_LEN'b0 ,`D_OFFSET_LEN'b0} ;

  assign rd_id   = (mshr_addr_wait[0])? 4'b0000 :
                   (mshr_addr_wait[1])? 4'b0001 :
                   (mshr_addr_wait[2])? 4'b0010 :
                                        4'b0011 ;

  assign rd_arcmd = (mshr_addr_wait[0] && !mshr_uncache[0])? (mshr_dirty[0]? `ARCMD_REQWRITE : `ARCMD_REQREAD) :
                    (mshr_addr_wait[1] && !mshr_uncache[1])? (mshr_dirty[1]? `ARCMD_REQWRITE : `ARCMD_REQREAD) :
                    (mshr_addr_wait[2] && !mshr_uncache[2])? (mshr_dirty[2]? `ARCMD_REQWRITE : `ARCMD_REQREAD) :
                                                             (mshr_dirty[3]? `ARCMD_REQWRITE : `ARCMD_REQREAD) ;

  assign rd_uncache = (mshr_addr_wait[0])?  mshr_uncache[0] :
                      (mshr_addr_wait[1])?  mshr_uncache[1] :
                      (mshr_addr_wait[2])?  mshr_uncache[2] :
                                            mshr_uncache[3] ;

  //assign rd_addr = {`PABITS{mshr_addr_wait[0]}} & {mshr_ptag[0], mshr_index[0][5:0], mshr_uncache[0]? mshr_rbank : 3'b0 ,3'b0} |
  //                 {`PABITS{mshr_addr_wait[1]}} & {mshr_ptag[1], mshr_index[1][5:0], mshr_uncache[1]? mshr_rbank : 3'b0 ,3'b0} |
  //                 {`PABITS{mshr_addr_wait[2]}} & {mshr_ptag[2], mshr_index[2][5:0], mshr_uncache[2]? mshr_rbank : 3'b0 ,3'b0} |
  //                 {`PABITS{mshr_addr_wait[3]}} & {mshr_ptag[3], mshr_index[3][5:0], mshr_uncache[3]? mshr_rbank : 3'b0 ,3'b0} ;
//
  //assign rd_id   = {4{mshr_addr_wait[0]}} & 4'b0000 |
  //                 {4{mshr_addr_wait[1]}} & 4'b0001 |
  //                 {4{mshr_addr_wait[2]}} & 4'b0010 |
  //                 {4{mshr_addr_wait[3]}} & 4'b0011 ;
//
  //assign rd_arcmd = {4{mshr_addr_wait[0] && !mshr_uncache[0]}} & (mshr_dirty[0]? `ARCMD_REQWRITE : `ARCMD_REQREAD) |
  //                  {4{mshr_addr_wait[1] && !mshr_uncache[1]}} & (mshr_dirty[1]? `ARCMD_REQWRITE : `ARCMD_REQREAD) |
  //                  {4{mshr_addr_wait[2] && !mshr_uncache[2]}} & (mshr_dirty[2]? `ARCMD_REQWRITE : `ARCMD_REQREAD) |
  //                  {4{mshr_addr_wait[3] && !mshr_uncache[3]}} & (mshr_dirty[3]? `ARCMD_REQWRITE : `ARCMD_REQREAD) ;
//
  //assign rd_uncache = mshr_addr_wait[0] &&  mshr_uncache[0] || 
  //                    mshr_addr_wait[1] &&  mshr_uncache[1] || 
  //                    mshr_addr_wait[2] &&  mshr_uncache[2] || 
  //                    mshr_addr_wait[3] &&  mshr_uncache[3] ;

  wire [1:0] way_choose;
  assign way_choose = {2{lru_rplc_way[3]}} & 2'b11 |
                      {2{lru_rplc_way[2]}} & 2'b10 |
                      {2{lru_rplc_way[1]}} & 2'b01 |
                      {2{lru_rplc_way[0]}} & 2'b00 ;

  assign wtbk_way = (state_ophd && cache_op_code[`IDX_INV_WB])?  cache_op_way :
                    (state_ophd && cache_op_code[`HIT_INV_WB])?  ({2{op_wayhit_record[3]}} & 2'b11 |
                                                                  {2{op_wayhit_record[2]}} & 2'b10 |
                                                                  {2{op_wayhit_record[1]}} & 2'b01 |
                                                                  {2{op_wayhit_record[0]}} & 2'b00 ):
                                                                 way_choose ;

  assign ud_wr_req = tlb_valid_uncache && data_wr_reg && !ex2_cancel && !ex2_cancel_his && !req_cancel;

  assign wr_req   = (|mshr_wtbk) || op_wtbk_req || ex_wtbk_req || state_ucst;

  assign wr_addr  = {`PABITS{op_wtbk_req }} & {line_tag[wtbk_way], cache_op_index[11-`D_BANK_LEN-`D_OFFSET_LEN:0], {`D_LINE_LEN{1'b0}}} |
                    {`PABITS{ex_handle   }} & {ex_paddr[`PABITS-1:`D_LINE_LEN]                                   , {`D_LINE_LEN{1'b0}}} |
                    {`PABITS{state_ucst  }} & {goon_ptag,                  index[11-`D_BANK_LEN-`D_OFFSET_LEN:0] , bank, offset       } |
                    {`PABITS{mshr_wtbk[0]}} & {line_tag[wtbk_way], mshr_index[0][11-`D_BANK_LEN-`D_OFFSET_LEN:0] , {`D_LINE_LEN{1'b0}}} |
                    {`PABITS{mshr_wtbk[1]}} & {line_tag[wtbk_way], mshr_index[1][11-`D_BANK_LEN-`D_OFFSET_LEN:0] , {`D_LINE_LEN{1'b0}}} |
                    {`PABITS{mshr_wtbk[2]}} & {line_tag[wtbk_way], mshr_index[2][11-`D_BANK_LEN-`D_OFFSET_LEN:0] , {`D_LINE_LEN{1'b0}}} |
                    {`PABITS{mshr_wtbk[3]}} & {line_tag[wtbk_way], mshr_index[3][11-`D_BANK_LEN-`D_OFFSET_LEN:0] , {`D_LINE_LEN{1'b0}}} ;

  assign wr_data  = (ex_handle && (|ex_mshrhit_reg))? (ex_mshrhit_reg[3]?  mshr_data[3]:
                                                       ex_mshrhit_reg[2]?  mshr_data[2]:
                                                       ex_mshrhit_reg[1]?  mshr_data[1]:
                                                                           mshr_data[0]):
                    `ifdef LA64
                    (state_ucst                    )?  {384'b0, {2{data_wdata_reg}}}:
                    `elsif LA32
                    (state_ucst                    )?  {128'b0, {4{data_wdata_reg}}}:
                    `endif
                                                       rdata_way[wtbk_way];

  assign wr_awcmd    = (ex_handle)? (ex_op[`INV_WTBK]? `AWCMD_INVWTBK:
                                     ex_op[`WTBK    ]? `AWCMD_WTBK   :
                                                       `AWCMD_INV   ):
                                     `AWCMD_RPLC;

  // TODO : op req
  assign wr_awstate  = (ex_handle && (ex_op[`INV_WTBK] || ex_op[`WTBK]))? (ex_dirty? `STATE_D : ex_hit_state              ) :
                       (ex_handle &&  ex_op[`INV]                      )? `STATE_I                                          :
                       (mshr_wtbk[0]                                   )? (replaced_dirty? `STATE_D : line_state[wtbk_way]) :
                       (mshr_wtbk[1]                                   )? (replaced_dirty? `STATE_D : line_state[wtbk_way]) :
                       (mshr_wtbk[2]                                   )? (replaced_dirty? `STATE_D : line_state[wtbk_way]) :
                       (mshr_wtbk[3]                                   )? (replaced_dirty? `STATE_D : line_state[wtbk_way]) :
                                                                          2'b0;
  assign wr_awscway  = {`SCWAY_LEN{ex_handle   }} & ex_hit_scway         |
                       {`SCWAY_LEN{mshr_wtbk[0]}} & line_scway[wtbk_way] |
                       {`SCWAY_LEN{mshr_wtbk[1]}} & line_scway[wtbk_way] |
                       {`SCWAY_LEN{mshr_wtbk[2]}} & line_scway[wtbk_way] |
                       {`SCWAY_LEN{mshr_wtbk[3]}} & line_scway[wtbk_way] ;

  assign wr_pgcl     = {2{ex_handle   }} &  ex_pgcl                        |
                       {2{mshr_wtbk[0]}} & {1'b0, mshr_index[wtbk_way][0]} |
                       {2{mshr_wtbk[1]}} & {1'b0, mshr_index[wtbk_way][0]} |
                       {2{mshr_wtbk[2]}} & {1'b0, mshr_index[wtbk_way][0]} |
                       {2{mshr_wtbk[3]}} & {1'b0, mshr_index[wtbk_way][0]} ;

  assign wr_uc_wstrb = data_wstrb_reg;

  assign wr_awdirqid = ex_dirqid;

  assign wr_fmt      = (ex_handle &&  ex_op[`INV])?  `WR_FMT_EXTINV :
                       (state_ucst               )?  `WR_FMT_UNCACHE:
                                                     `WR_FMT_ALLLINE;
`endif
// ------------------------- END --------------------------

endmodule
