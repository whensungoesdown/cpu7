`include "common.vh"

module icache
(
    input         clk,
    input         resetn,

    output reg [`I_WAY_NUM-1  :0] tag_clk_en_o,
    output [`I_WAY_NUM-1      :0] tag_en_o      ,
    output [`I_WAY_NUM-1      :0] tag_wen_o     ,  // The least significant bit denote way_0
    output [`I_INDEX_LEN-1    :0] tag_addr_o    ,
    output [`I_TAGARRAY_LEN-1 :0] tag_wdata_o   ,
    input  [`I_IO_TAG_LEN-1   :0] tag_rdata_i   ,

    output reg                    lru_clk_en_o  ,
    output                        lru_en_o      ,
    output [`I_LRU_WIDTH-1    :0] lru_wen_o     ,
    output [`I_INDEX_LEN-1    :0] lru_addr_o    ,
    output [`I_LRU_WIDTH-1    :0] lru_wdata_o   ,
    input  [`I_LRU_WIDTH-1    :0] lru_rdata_i   ,

    output reg [`I_WAY_NUM-1  :0] data_clk_en_o,
    output [`I_IO_EN_LEN-1    :0] data_en_o    ,
    output [`I_WAY_NUM-1      :0] data_wen_o   ,
    output [`I_INDEX_LEN-1    :0] data_addr_o  ,
    output [`I_IO_WDATA_LEN-1 :0] data_wdata_o ,
    input  [`I_IO_RDATA_LEN-1 :0] data_rdata_i ,

    //  interact with CPU
    //--------sram-like---------
    input                       inst_req      ,
    input  [`GRLEN-1        :0] inst_addr     ,
    input                       inst_cancel   ,
    output                      inst_addr_ok  ,
    output                      inst_valid    ,
    output [               1:0] inst_count    ,
    output [`INST_OUT_LEN-1 :0] inst_rdata    ,
    output                      inst_uncache  ,
    output [               5:0] inst_exccode  ,
    output                      inst_exception,

    output                      inst_tlb_req  ,
    output [`GRLEN-1        :0] inst_tlb_vaddr,
    output                      inst_tlb_cacop,

    input                       cache_op_req    ,
    input  [2               :0] cache_op        ,
    input  [`I_TAG_LEN-1    :0] cache_op_tag    ,
    input  [`GRLEN-1        :0] cache_op_addr   ,
    output                      cache_op_addr_ok,
    output                      cache_op_ok     ,
    output                      cache_op_error  ,
    output [`GRLEN-1        :0] cache_op_badvaddr,

    // interact with iTLB
    input  [`I_TAG_LEN-1    :0] tlb_ptag      ,
    input                       tlb_finish    ,
    input                       tlb_hit       ,
    input                       tlb_uncache   ,
    input  [5               :0] tlb_exccode   ,
    output                      tlb_cache_recv,

    // interact with MISS queue
    input                       ex_req        ,
    input  [ 2              :0] ex_req_op     ,
    input  [`PABITS-1       :0] ex_req_paddr  ,
    input  [9               :0] ex_req_cpuno  ,
    input  [1               :0] ex_req_pgcl   ,
    input  [3               :0] ex_req_dirqid ,
    output                      ex_req_recv   ,

    output                      rd_req     ,
    output [`PABITS-1       :0] rd_addr    ,
    output [3               :0] rd_arcmd   ,
    output                      rd_uncache ,
    input                       rd_ready   ,
    input                       ret_valid  ,
    input                       ret_last   ,
    input  [63              :0] ret_data   ,
    input  [`STATE_LEN-1    :0] ret_rstate ,
    input  [`SCWAY_LEN-1    :0] ret_rscway ,

    output                      wr_req     ,
    output [`PABITS-1       :0] wr_addr    ,
    output [`I_LINE_SIZE_b-1:0] wr_data    ,
    output [3               :0] wr_awcmd   ,
    output [1               :0] wr_awstate ,
    output [3               :0] wr_awdirqid,
    output [3               :0] wr_awscway ,
    output [1               :0] wr_pgcl    ,
    output [`WR_FMT_LEN-1   :0] wr_fmt     ,
    input                       wr_ready
);

wire rst;
assign rst = !resetn;

//  ------------------ SIGNAL DECLARATION -----------------
wire ex_wtbk_req;

// tlb
wire tlb_valid_ret;

// cache state
reg  [2:0] icache_state;
wire state_idle;
wire state_lkup;
wire state_blck;

wire state_oprd;
wire state_ophd;

wire block_release;
reg  [`I_TAG_LEN-1:0] blck_ptag;
reg                   blck_uncache;

wire                        hit_data_ok;
wire                        uncache_data_ok;
wire                        error_data_ok;
wire [`RFIL_RECORD_LEN-1:0] miss_data_ok;
reg  [`RFIL_RECORD_LEN-1:0] rfil_record;

// cache operation
reg  [`GRLEN-1      :0] cache_op_addr_his;
wire [`I_INDEX_LEN-1:0] cache_op_index;
wire [`I_WAY_LEN-1  :0] cache_op_way;
reg  [2             :0] cache_op_code;
reg  [`I_WAY_NUM-1  :0] cache_op_wayhit;

wire                    ophd_finish;
wire [`I_WAY_NUM-1  :0] op_tag_wen ;
wire [`I_WAY_NUM-1  :0] op_tag_en  ;
wire [`I_INDEX_LEN-1:0] op_tag_addr;

  // ext req
reg [ 2             :0] ex_op    ;
reg [`PABITS-1      :0] ex_paddr ;
reg [9              :0] ex_cpuno ;
reg [1              :0] ex_pgcl  ;
reg [3              :0] ex_dirqid;

reg [`I_WAY_NUM-1   :0] ex_wayhit_reg;

reg  [1             :0] ex_state ;
reg                     ex_rd_fin;
wire                    ex_idle  ;
wire                    ex_rdtag ;
wire                    ex_tagcmp;
wire                    ex_handle;

wire                    ex_handle_fin ;
wire                    ex_rdtag_ready;
wire [`I_WAY_NUM-1  :0] ex_wayhit     ;

wire [`I_WAY_NUM-1     :0] ex_tag_wen  ;
wire [`I_WAY_NUM-1     :0] ex_tag_en   ;
wire [`I_INDEX_LEN-1   :0] ex_tag_addr ;
wire [`I_TAGARRAY_LEN-1:0] ex_tag_wdata;

// cache structure
wire                        cache_miss;

// tag
wire                  cache_hit;
wire [`I_WAY_NUM-1:0] way_hit;
wire [`STATE_LEN-1:0] line_state [`I_WAY_NUM-1:0];
wire [`SCWAY_LEN-1:0] line_scway [`I_WAY_NUM-1:0];
wire [`I_TAG_LEN-1:0] line_tag   [`I_WAY_NUM-1:0];

// LRU Unit
wire [`I_WAY_NUM-1  :0] lru_new_way;
wire [`I_WAY_NUM-1  :0] lru_way_lock;
wire                    lru_new_wen;
wire                    lru_new_clr;
wire [`I_LRU_WIDTH-1:0] lru_new_lru;
wire [`I_LRU_WIDTH-1:0] lru_new_lru_bit_mask;
reg  [`I_LRU_WIDTH-1:0] lru_rplc_info;
wire [`I_WAY_NUM-1  :0] lru_rplc_way;

// data array
reg  [`I_BANK_NUM-1   :0] data_clk_en [`I_WAY_NUM-1:0];
wire [`I_BANK_NUM-1   :0] data_en     [`I_WAY_NUM-1:0];
wire [`I_LINE_SIZE_b-1:0] rdata_sum   [`I_WAY_NUM-1:0];

wire [`I_BANK_NUM-1   :0] addr_sel_en;
wire [`I_BANK_NUM-1   :0] ofst_sel_en;

// inst return
wire [`INST_OUT_LEN-1 :0] data_way_sel [`I_WAY_NUM-1:0];
wire [`INST_OUT_LEN-1 :0] miss_ret_data;

// Refill
reg  [ 3:0] rfil_state;
wire        rfil_valid;
wire        rfil_idle;
wire        rfil_addr_wait;
wire        rfil_data_wait;

wire        rfil_wait_go;
wire        rfil_alloc;
wire        rfil_hit;
wire        rfil_refill;
wire        rfil_clear;
wire        rfil_new_req;

reg                      rfil_send_cpu;
reg  [`I_TAG_LEN-1   :0] rfil_ptag ;
reg  [`I_INDEX_LEN-1 :0] rfil_index;
reg  [`I_OFFSET_LEN-1:0] rfil_offset;  // uty: test
//wire  [`I_OFFSET_LEN-1:0] rfil_offset_uty;
reg                      rfil_uncache;

reg  [31             :0] rfil_data [`LINE_INST_NUM-1:0];
reg  [`STATE_LEN-1   :0] rfil_rstate;
reg  [`SCWAY_LEN-1   :0] rfil_rscway;
// -------------------------- END -------------------------



//  ------------------- Store Req & Addr ------------------
reg  inst_cancel_reg; // TODO: We can cencel request at lkup_state

// uty: test
reg  [`I_INDEX_LEN-1 :0] index ;
reg  [`I_OFFSET_LEN-1:0] offset;

always @(posedge clk) begin
  if(rst) begin
    index   <= {`I_INDEX_LEN {1'b0}};  // TODO: remove rst ?
    offset  <= {`I_OFFSET_LEN{1'b0}};
  end
  else if(inst_addr_ok) begin  // uty: test
  //else begin
    index   <= inst_addr[`I_INDEX_BITS];
    offset  <= inst_addr[`I_OFFSET_BITS];
  end
end
//wire  [`I_INDEX_LEN-1 :0] index ;
//wire  [`I_OFFSET_LEN-1:0] offset;
//
//assign index = inst_addr[`I_INDEX_BITS];
//assign offset = inst_addr[`I_OFFSET_BITS];



always @(posedge clk) begin
  if(rst)
    inst_cancel_reg <= 1'b0;
  else if(inst_cancel)
    inst_cancel_reg <= 1'b1;
  else if(inst_addr_ok)
    inst_cancel_reg <= 1'b0;
end

assign inst_tlb_req        = inst_addr_ok || cache_op_addr_ok && cache_op[`HIT_INV];
assign inst_tlb_vaddr      = cache_op_addr_ok? cache_op_addr : inst_addr;
assign inst_tlb_cacop      = cache_op_addr_ok && cache_op[`HIT_INV];

assign tlb_cache_recv      = tlb_finish;
assign inst_exception      = tlb_finish &&!tlb_hit;
assign inst_uncache        = inst_valid && rfil_uncache;
assign inst_exccode        = tlb_exccode;

assign tlb_valid_ret = tlb_finish && tlb_hit;
// -------------------------- END -------------------------


`ifdef I_WAY_NUM4
  // tag
  assign {line_state[3], line_scway[3], line_tag[3], 
          line_state[2], line_scway[2], line_tag[2], 
          line_state[1], line_scway[1], line_tag[1], 
          line_state[0], line_scway[0], line_tag[0]} = tag_rdata_i;

  // data array
  assign data_en_o = {data_en[3], data_en[2], data_en[1], data_en[0]};
  assign {rdata_sum[3], rdata_sum[2], rdata_sum[1], rdata_sum[0]} = data_rdata_i;
`endif

//  ---------------- Look Up in Icache Tag ----------------
assign cache_hit   =   |way_hit && !tlb_uncache  && tlb_valid_ret;
assign cache_miss  =(!(|way_hit) || tlb_uncache) && tlb_valid_ret;

assign ex_tag_addr  = {ex_pgcl[0], ex_paddr[11:`I_OFFSET_LEN + 2]};
assign ex_tag_wdata = {`I_TAGARRAY_LEN{1'b0}};

assign op_tag_addr = (cache_op_addr_ok)? cache_op_addr[`I_INDEX_BITS] : cache_op_index;


assign tag_addr_o  = (rfil_refill              )?  rfil_index              :
                     (|op_tag_en               )?  op_tag_addr             :
                     (|ex_tag_en               )?  ex_tag_addr             :
                     (state_lkup && !tlb_finish)?  index                   :
                                                   inst_addr[`I_INDEX_BITS];

assign tag_wdata_o ={`I_TAGARRAY_LEN{rfil_refill                                                       }} & {rfil_rstate, rfil_rscway, rfil_ptag} | 
                    {`I_TAGARRAY_LEN{state_ophd &&  cache_op_code[`IDX_ST_TAG]                         }} & {{`STATE_LEN{1'b0}}, {`SCWAY_LEN{1'b0}}, cache_op_tag} | // TODO
                    {`I_TAGARRAY_LEN{state_ophd && (cache_op_code[`IDX_INV] || cache_op_code[`HIT_INV])}} & {`I_TAGARRAY_LEN{1'b0}              } |
                    {`I_TAGARRAY_LEN{|ex_tag_wen                                                       }} & {`I_TAGARRAY_LEN{1'b0}              } ;
 
genvar gv_tag;
generate
  for(gv_tag = 0; gv_tag < `I_WAY_NUM; gv_tag = gv_tag + 1)
  begin : tag_module
    always @(posedge clk) begin
      if(rst)
        tag_clk_en_o[gv_tag] <= 1'b1;
    end
    //always @(posedge clk) begin
    //  if(rst)
    //    tag_clk_en_o[gv_tag] <= 1'b1;
    //  else if(state_recv && ret_valid && rfil_record[2])
    //    tag_clk_en_o[gv_tag] <= 1'b1;
    //  else if(state_lkup && cache_miss && !(!tlb_hit || cache_op_busy))
    //    tag_clk_en_o[gv_tag] <= 1'b0;
    //end

    assign way_hit  [gv_tag] = line_tag[gv_tag] == tlb_ptag && line_state[gv_tag] != `STATE_I;
    assign ex_wayhit[gv_tag] = line_tag[gv_tag] == ex_paddr[`I_TAG_BITS] && line_state[gv_tag] != `STATE_I;

    assign tag_en_o[gv_tag]  = (state_idle && inst_req             ) ||
                               (state_lkup                         ) ||
                               (rfil_refill && lru_rplc_way[gv_tag]) ||
                               (op_tag_en[gv_tag]                  ) ;

    assign tag_wen_o[gv_tag] = (rfil_refill  && lru_rplc_way[gv_tag]) ||
                               (op_tag_wen[gv_tag]                ) ;
  
    assign op_tag_en[gv_tag]  = cache_op_req  && state_idle && cache_op[`HIT_INV]    || 
                                state_oprd && !tlb_finish && cache_op_code[`HIT_INV] ||
                                op_tag_wen[gv_tag];

    assign op_tag_wen[gv_tag] = state_ophd && 
                                ((cache_op_code[`IDX_ST_TAG] || cache_op_code[`IDX_INV]) && cache_op_way == gv_tag ||
                                  cache_op_code[`HIT_INV] && cache_op_wayhit[gv_tag]);

    assign ex_tag_en [gv_tag] = ex_rdtag_ready || ex_tag_wen[gv_tag];
    assign ex_tag_wen[gv_tag] = ex_handle_fin  && ex_wayhit_reg[gv_tag] && ex_op[`INV];
  end
endgenerate
// -------------------------- END -------------------------



// ----------------------- LRU Unit -----------------------
always @(posedge clk) begin
  if(rst)
    lru_clk_en_o <= 1'b1;
end
//always @(posedge clk) begin
//  if(rst)
//    lru_clk_en_o <= 1'b1;
//  else if(state_recv && ret_valid && rfil_record[2])
//    lru_clk_en_o <= 1'b1;
//  else if(state_lkup && cache_miss && tlb_hit && !cache_op_busy)
//    lru_clk_en_o <= 1'b0;
//end

reg                    lru_en_valid;
reg [`I_INDEX_LEN-1:0] lru_rw_index;
// LRU Read
always @(posedge clk) begin
  if(rst)
    lru_en_valid <= 1'b0;
  else if(rfil_alloc)
    lru_en_valid <= (state_blck)? !blck_uncache : !tlb_uncache;
  else
    lru_en_valid <= 1'b0;
end

reg store_lru;
always @(posedge clk) begin
  store_lru      <= lru_en_valid;
end

always @(posedge clk) begin
  if(rst) // TODO: remove
    lru_rplc_info <= {`I_LRU_WIDTH{1'b0}};
  else if(store_lru)
    lru_rplc_info <= lru_rdata_i;
end

always @(posedge clk) begin
  if(tlb_valid_ret)
    lru_rw_index <= index;
end

// LRU Write
reg                  lru_wr_valid;
reg [`I_WAY_NUM-1:0] lru_wr_way  ;

always @(posedge clk) begin
  if(rst)
    lru_wr_valid <= 1'b0;
  else
    lru_wr_valid <= cache_hit;
end

always @(posedge clk) begin
  if(cache_hit) begin
    lru_wr_way   <= way_hit;
  end
end

// TODO: hit inv change lru state
`ifdef I_LRU_REPLACE
  assign lru_en_o    = lru_en_valid || lru_wr_valid || rfil_refill;
  assign lru_wen_o   = lru_new_lru_bit_mask;
  assign lru_addr_o  = (rfil_refill)? rfil_index : lru_rw_index;
  assign lru_wdata_o = lru_new_lru;

  `ifdef I_WAY_NUM4
    assign lru_new_way  = {lru_wr_valid & lru_wr_way[3] | rfil_refill & lru_rplc_way[3],
                           lru_wr_valid & lru_wr_way[2] | rfil_refill & lru_rplc_way[2],
                           lru_wr_valid & lru_wr_way[1] | rfil_refill & lru_rplc_way[1],
                           lru_wr_valid & lru_wr_way[0] | rfil_refill & lru_rplc_way[0]};
  `endif

  // TODO:
  assign lru_way_lock = {`I_WAY_NUM{1'b0}};
  // TODO:
  assign lru_new_clr  = 1'b0;

  assign lru_new_wen  = lru_wr_valid || rfil_refill;
  
lru_unit #(
  .LRU_BITS (`I_LRU_WIDTH), 
  .WAY_N    (`I_WAY_NUM  )
) u_ilru
(
  .new_way  (lru_new_way ),
  .way_lock (lru_way_lock),

  .new_wen  (lru_new_wen ),
  .new_clr  (lru_new_clr ),

  .new_lru          (lru_new_lru         ),
  .new_lru_bit_mask (lru_new_lru_bit_mask),

  .repl_lru         (lru_rplc_info),
  .repl_way         (lru_rplc_way )
);
`endif
// ------------------------- END --------------------------



// ----------------- Finite State Machine -----------------
// 4'b0000 : IDLE   : There's no inst req
// 4'b0001 : LOOK UP: There's an inst req, waiting for index result

assign state_idle = icache_state == 3'b000;
assign state_lkup = icache_state == 3'b001;
assign state_blck = icache_state == 3'b010;

assign state_oprd = icache_state == 3'b100;
assign state_ophd = icache_state == 3'b101;

assign ophd_finish = 1'b1;

assign block_release = rfil_clear;

always @(posedge clk) begin
  if(rst)
    icache_state <= 3'b000;
  // ###  IDLE  ###
  else if(state_idle && inst_addr_ok || cache_op_addr_ok) 
    icache_state <= (cache_op_req)? 3'b100 : 3'b001;

  // ### LOOK UP ###
  else if(state_lkup && cache_miss && !rfil_hit && rfil_valid)
    icache_state <= 3'b010;
  else if(state_lkup && tlb_finish && !inst_addr_ok || state_blck && block_release || state_ophd && ophd_finish)
    icache_state <= 3'b000;

  else if (state_oprd && (tlb_finish || !cache_op_code[`HIT_INV]))
    icache_state <= (tlb_hit || !cache_op_code[`HIT_INV])? 3'b101 : 3'b000;
end

always @(posedge clk) begin
  if(state_lkup && cache_miss && !rfil_hit) begin
    blck_ptag    <= tlb_ptag;
    blck_uncache <= tlb_uncache;
  end
end
// ------------------------- END --------------------------



// ----------------- Read Data From Cache -----------------
`ifdef LA64
  assign addr_sel_en[0] = inst_addr[5:3] == 3'b000;
  assign addr_sel_en[1] = inst_addr[5:4] == 2'b00;
  assign addr_sel_en[2] = inst_addr[5:2] == 4'b0001 || inst_addr[5:3] == 3'b001 || inst_addr[5:3] == 3'b010;
  assign addr_sel_en[3] = inst_addr[5:2] == 4'b0011 || inst_addr[5:3] == 3'b010 || inst_addr[5:3] == 3'b011;
  assign addr_sel_en[4] = inst_addr[5:2] == 4'b0101 || inst_addr[5:3] == 3'b011 || inst_addr[5:3] == 3'b100;
  assign addr_sel_en[5] = inst_addr[5:2] == 4'b0111 || inst_addr[5:3] == 3'b100 || inst_addr[5:3] == 3'b101;
  assign addr_sel_en[6] = inst_addr[5:2] == 4'b1001 || inst_addr[5:3] == 3'b101 || inst_addr[5:3] == 3'b110;
  assign addr_sel_en[7] = inst_addr[5:2] == 4'b1011 || inst_addr[5:3] == 3'b110 || inst_addr[5:3] == 3'b111;
  
  assign ofst_sel_en[0] = offset[3:1] == 3'b000;
  assign ofst_sel_en[1] = offset[3:2] == 2'b00;
  assign ofst_sel_en[2] = offset      == 4'b0001 || offset[3:1] == 3'b001 || offset[3:1] == 3'b010;
  assign ofst_sel_en[3] = offset      == 4'b0011 || offset[3:1] == 3'b010 || offset[3:1] == 3'b011;
  assign ofst_sel_en[4] = offset      == 4'b0101 || offset[3:1] == 3'b011 || offset[3:1] == 3'b100;
  assign ofst_sel_en[5] = offset      == 4'b0111 || offset[3:1] == 3'b100 || offset[3:1] == 3'b101;
  assign ofst_sel_en[6] = offset      == 4'b1001 || offset[3:1] == 3'b101 || offset[3:1] == 3'b110;
  assign ofst_sel_en[7] = offset      == 4'b1011 || offset[3:1] == 3'b110 || offset[3:1] == 3'b111;

  assign data_wdata_o = {rfil_data[15], rfil_data[14], rfil_data[13], rfil_data[12],
                         rfil_data[11], rfil_data[10], rfil_data[ 9], rfil_data[ 8],
                         rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4],
                         rfil_data[ 3], rfil_data[ 2], rfil_data[ 1], rfil_data[ 0]};

  assign miss_ret_data = {`INST_OUT_LEN{                          rfil_uncache}} & {32'b0        , 32'b0        , 32'b0        , rfil_data[ 0]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0000 & !rfil_uncache}} & {rfil_data[ 3], rfil_data[ 2], rfil_data[ 1], rfil_data[ 0]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0001 & !rfil_uncache}} & {rfil_data[ 4], rfil_data[ 3], rfil_data[ 2], rfil_data[ 1]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0010 & !rfil_uncache}} & {rfil_data[ 5], rfil_data[ 4], rfil_data[ 3], rfil_data[ 2]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0011 & !rfil_uncache}} & {rfil_data[ 6], rfil_data[ 5], rfil_data[ 4], rfil_data[ 3]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0100 & !rfil_uncache}} & {rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0101 & !rfil_uncache}} & {rfil_data[ 8], rfil_data[ 7], rfil_data[ 6], rfil_data[ 5]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0110 & !rfil_uncache}} & {rfil_data[ 9], rfil_data[ 8], rfil_data[ 7], rfil_data[ 6]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b0111 & !rfil_uncache}} & {rfil_data[10], rfil_data[ 9], rfil_data[ 8], rfil_data[ 7]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1000 & !rfil_uncache}} & {rfil_data[11], rfil_data[10], rfil_data[ 9], rfil_data[ 8]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1001 & !rfil_uncache}} & {rfil_data[12], rfil_data[11], rfil_data[10], rfil_data[ 9]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1010 & !rfil_uncache}} & {rfil_data[13], rfil_data[12], rfil_data[11], rfil_data[10]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1011 & !rfil_uncache}} & {rfil_data[14], rfil_data[13], rfil_data[12], rfil_data[11]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1100 & !rfil_uncache}} & {rfil_data[15], rfil_data[14], rfil_data[13], rfil_data[12]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1101 & !rfil_uncache}} & {32'b0        , rfil_data[15], rfil_data[14], rfil_data[13]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1110 & !rfil_uncache}} & {32'b0        , 32'b0        , rfil_data[15], rfil_data[14]} |
                         {`INST_OUT_LEN{rfil_offset == 4'b1111 & !rfil_uncache}} & {32'b0        , 32'b0        , 32'b0        , rfil_data[15]} ;
`elsif LA32
  assign addr_sel_en[0] = inst_addr[4:2] == 3'b000 ;
  assign addr_sel_en[1] = inst_addr[4:3] == 2'b00  ;
  assign addr_sel_en[2] = inst_addr[4:3] == 2'b00  || inst_addr[4:2] == 3'b010;
  assign addr_sel_en[3] = inst_addr[4  ] == 1'b0   ;
  assign addr_sel_en[4] = inst_addr[4:2] == 3'b001 || inst_addr[4:3] == 2'b01 || inst_addr[4:2] == 3'b100;
  assign addr_sel_en[5] = inst_addr[4:3] == 2'b01  || inst_addr[4:3] == 2'b10 ;
  assign addr_sel_en[6] = inst_addr[4:2] == 3'b011 || inst_addr[4:3] == 2'b10 || inst_addr[4:2] == 3'b110;
  assign addr_sel_en[7] = inst_addr[4  ] == 1'b1   ;
  
  assign ofst_sel_en[0] = offset      == 3'b000 ;
  assign ofst_sel_en[1] = offset[2:1] == 2'b00  ;
  assign ofst_sel_en[2] = offset[2:1] == 2'b00  || offset      == 3'b010;
  assign ofst_sel_en[3] = offset[2  ] == 1'b0   ;
  assign ofst_sel_en[4] = offset      == 3'b001 || offset[2:1] == 2'b01 || offset == 3'b100;
  assign ofst_sel_en[5] = offset[2:1] == 2'b01  || offset[2:1] == 2'b10 ;
  assign ofst_sel_en[6] = offset      == 3'b011 || offset[2:1] == 2'b10 || offset == 3'b110;
  assign ofst_sel_en[7] = offset[2  ] == 1'b1   ;

  assign data_wdata_o = {rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4],
                         rfil_data[ 3], rfil_data[ 2], rfil_data[ 1], rfil_data[ 0]};

  // uty: test		 
  assign miss_ret_data = {`INST_OUT_LEN{                         rfil_uncache}} & {32'b0        , 32'b0        , 32'b0        , rfil_data[ 0]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b000 & !rfil_uncache}} & {rfil_data[ 3], rfil_data[ 2], rfil_data[ 1], rfil_data[ 0]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b001 & !rfil_uncache}} & {rfil_data[ 4], rfil_data[ 3], rfil_data[ 2], rfil_data[ 1]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b010 & !rfil_uncache}} & {rfil_data[ 5], rfil_data[ 4], rfil_data[ 3], rfil_data[ 2]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b011 & !rfil_uncache}} & {rfil_data[ 6], rfil_data[ 5], rfil_data[ 4], rfil_data[ 3]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b100 & !rfil_uncache}} & {rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b101 & !rfil_uncache}} & {32'b0        , rfil_data[ 7], rfil_data[ 6], rfil_data[ 5]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b110 & !rfil_uncache}} & {32'b0        , 32'b0        , rfil_data[ 7], rfil_data[ 6]} |
                         {`INST_OUT_LEN{rfil_offset == 3'b111 & !rfil_uncache}} & {32'b0        , 32'b0        , 32'b0        , rfil_data[ 7]} ;

//  assign miss_ret_data = {`INST_OUT_LEN{                         rfil_uncache}} & {32'b0        , 32'b0        , 32'b0        , rfil_data[ 0]} |
//                         {`INST_OUT_LEN{offset == 3'b000 & !rfil_uncache}} & {rfil_data[ 3], rfil_data[ 2], rfil_data[ 1], rfil_data[ 0]} |
//                         {`INST_OUT_LEN{offset == 3'b001 & !rfil_uncache}} & {rfil_data[ 4], rfil_data[ 3], rfil_data[ 2], rfil_data[ 1]} |
//                         {`INST_OUT_LEN{offset == 3'b010 & !rfil_uncache}} & {rfil_data[ 5], rfil_data[ 4], rfil_data[ 3], rfil_data[ 2]} |
//                         {`INST_OUT_LEN{offset == 3'b011 & !rfil_uncache}} & {rfil_data[ 6], rfil_data[ 5], rfil_data[ 4], rfil_data[ 3]} |
//                         {`INST_OUT_LEN{offset == 3'b100 & !rfil_uncache}} & {rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4]} |
//                         {`INST_OUT_LEN{offset == 3'b101 & !rfil_uncache}} & {32'b0        , rfil_data[ 7], rfil_data[ 6], rfil_data[ 5]} |
//                         {`INST_OUT_LEN{offset == 3'b110 & !rfil_uncache}} & {32'b0        , 32'b0        , rfil_data[ 7], rfil_data[ 6]} |
//                         {`INST_OUT_LEN{offset == 3'b111 & !rfil_uncache}} & {32'b0        , 32'b0        , 32'b0        , rfil_data[ 7]} ;
`endif

assign data_addr_o = (rfil_refill              )?  rfil_index              :
                     (state_lkup && !tlb_finish)?  index                   :
                                                   inst_addr[`I_INDEX_BITS];

genvar gv_data; // WAY index
generate
  for(gv_data = 0; gv_data < `I_WAY_NUM; gv_data = gv_data + 1)
  begin : data_module
    always @(posedge clk) begin
      if(rst)
        data_clk_en_o[gv_data] <= 1'b1;
    end
    //always @(posedge clk) begin
    //  if(rst)
    //    data_clk_en_o[gv_data] <= 1'b1;
    //  else if(state_recv && ret_valid && rfil_record[2])
    //    data_clk_en_o[gv_data] <= 1'b1;
    //  else if(state_lkup && cache_miss && tlb_hit && !cache_op_busy)
    //    data_clk_en_o[gv_data] <= 1'b0;
    //end

    assign data_en[gv_data][0] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[0]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[0]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][1] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[1]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[1]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][2] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[2]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[2]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][3] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[3]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[3]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][4] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[4]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[4]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][5] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[5]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[5]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][6] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[6]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[6]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;
    assign data_en[gv_data][7] = ((state_idle || state_lkup && tlb_finish) && inst_req && addr_sel_en[7]) ||
                                 (state_lkup && !tlb_finish && ofst_sel_en[7]                           ) ||
                                 (data_wen_o[gv_data]                                                   ) ;

    assign data_wen_o[gv_data] = rfil_refill && lru_rplc_way[gv_data];

    `ifdef LA64
      assign data_way_sel[gv_data] = {`INST_OUT_LEN{offset == 4'b0000}} & {rdata_sum[gv_data][`I_WORD3_BITS ], rdata_sum[gv_data][`I_WORD2_BITS ], rdata_sum[gv_data][`I_WORD1_BITS ], rdata_sum[gv_data][`I_WORD0_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0001}} & {rdata_sum[gv_data][`I_WORD4_BITS ], rdata_sum[gv_data][`I_WORD3_BITS ], rdata_sum[gv_data][`I_WORD2_BITS ], rdata_sum[gv_data][`I_WORD1_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0010}} & {rdata_sum[gv_data][`I_WORD5_BITS ], rdata_sum[gv_data][`I_WORD4_BITS ], rdata_sum[gv_data][`I_WORD3_BITS ], rdata_sum[gv_data][`I_WORD2_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0011}} & {rdata_sum[gv_data][`I_WORD6_BITS ], rdata_sum[gv_data][`I_WORD5_BITS ], rdata_sum[gv_data][`I_WORD4_BITS ], rdata_sum[gv_data][`I_WORD3_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0100}} & {rdata_sum[gv_data][`I_WORD7_BITS ], rdata_sum[gv_data][`I_WORD6_BITS ], rdata_sum[gv_data][`I_WORD5_BITS ], rdata_sum[gv_data][`I_WORD4_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0101}} & {rdata_sum[gv_data][`I_WORD8_BITS ], rdata_sum[gv_data][`I_WORD7_BITS ], rdata_sum[gv_data][`I_WORD6_BITS ], rdata_sum[gv_data][`I_WORD5_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0110}} & {rdata_sum[gv_data][`I_WORD9_BITS ], rdata_sum[gv_data][`I_WORD8_BITS ], rdata_sum[gv_data][`I_WORD7_BITS ], rdata_sum[gv_data][`I_WORD6_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b0111}} & {rdata_sum[gv_data][`I_WORD10_BITS], rdata_sum[gv_data][`I_WORD9_BITS ], rdata_sum[gv_data][`I_WORD8_BITS ], rdata_sum[gv_data][`I_WORD7_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b1000}} & {rdata_sum[gv_data][`I_WORD11_BITS], rdata_sum[gv_data][`I_WORD10_BITS], rdata_sum[gv_data][`I_WORD9_BITS ], rdata_sum[gv_data][`I_WORD8_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b1001}} & {rdata_sum[gv_data][`I_WORD12_BITS], rdata_sum[gv_data][`I_WORD11_BITS], rdata_sum[gv_data][`I_WORD10_BITS], rdata_sum[gv_data][`I_WORD9_BITS ]}|
                                     {`INST_OUT_LEN{offset == 4'b1010}} & {rdata_sum[gv_data][`I_WORD13_BITS], rdata_sum[gv_data][`I_WORD12_BITS], rdata_sum[gv_data][`I_WORD11_BITS], rdata_sum[gv_data][`I_WORD10_BITS]}|
                                     {`INST_OUT_LEN{offset == 4'b1011}} & {rdata_sum[gv_data][`I_WORD14_BITS], rdata_sum[gv_data][`I_WORD13_BITS], rdata_sum[gv_data][`I_WORD12_BITS], rdata_sum[gv_data][`I_WORD11_BITS]}|
                                     {`INST_OUT_LEN{offset == 4'b1100}} & {rdata_sum[gv_data][`I_WORD15_BITS], rdata_sum[gv_data][`I_WORD14_BITS], rdata_sum[gv_data][`I_WORD13_BITS], rdata_sum[gv_data][`I_WORD12_BITS]}|
                                     {`INST_OUT_LEN{offset == 4'b1101}} & {                        {32{1'b0}}, rdata_sum[gv_data][`I_WORD15_BITS], rdata_sum[gv_data][`I_WORD14_BITS], rdata_sum[gv_data][`I_WORD13_BITS]}|
                                     {`INST_OUT_LEN{offset == 4'b1110}} & {                        {32{1'b0}},                         {32{1'b0}}, rdata_sum[gv_data][`I_WORD15_BITS], rdata_sum[gv_data][`I_WORD14_BITS]}|
                                     {`INST_OUT_LEN{offset == 4'b1111}} & {                        {32{1'b0}},                         {32{1'b0}},                         {32{1'b0}}, rdata_sum[gv_data][`I_WORD15_BITS]};
     `elsif LA32
        assign data_way_sel[gv_data] = {`INST_OUT_LEN{offset == 3'b000}} & {rdata_sum[gv_data][`I_WORD3_BITS ], rdata_sum[gv_data][`I_WORD2_BITS ], rdata_sum[gv_data][`I_WORD1_BITS ], rdata_sum[gv_data][`I_WORD0_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b001}} & {rdata_sum[gv_data][`I_WORD4_BITS ], rdata_sum[gv_data][`I_WORD3_BITS ], rdata_sum[gv_data][`I_WORD2_BITS ], rdata_sum[gv_data][`I_WORD1_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b010}} & {rdata_sum[gv_data][`I_WORD5_BITS ], rdata_sum[gv_data][`I_WORD4_BITS ], rdata_sum[gv_data][`I_WORD3_BITS ], rdata_sum[gv_data][`I_WORD2_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b011}} & {rdata_sum[gv_data][`I_WORD6_BITS ], rdata_sum[gv_data][`I_WORD5_BITS ], rdata_sum[gv_data][`I_WORD4_BITS ], rdata_sum[gv_data][`I_WORD3_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b100}} & {rdata_sum[gv_data][`I_WORD7_BITS ], rdata_sum[gv_data][`I_WORD6_BITS ], rdata_sum[gv_data][`I_WORD5_BITS ], rdata_sum[gv_data][`I_WORD4_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b101}} & {                        {32{1'b0}}, rdata_sum[gv_data][`I_WORD7_BITS ], rdata_sum[gv_data][`I_WORD6_BITS ], rdata_sum[gv_data][`I_WORD5_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b110}} & {                        {32{1'b0}},                         {32{1'b0}}, rdata_sum[gv_data][`I_WORD7_BITS ], rdata_sum[gv_data][`I_WORD6_BITS ]}|
                                       {`INST_OUT_LEN{offset == 3'b111}} & {                        {32{1'b0}},                         {32{1'b0}},                         {32{1'b0}}, rdata_sum[gv_data][`I_WORD7_BITS ]};
     `endif
  end
endgenerate



assign inst_rdata = {`INST_OUT_LEN{tlb_finish & way_hit[0]        }} & data_way_sel[0] |
                    {`INST_OUT_LEN{tlb_finish & way_hit[1]        }} & data_way_sel[1] |
                    {`INST_OUT_LEN{tlb_finish & way_hit[2]        }} & data_way_sel[2] |
                    {`INST_OUT_LEN{tlb_finish & way_hit[3]        }} & data_way_sel[3] |
                    {`INST_OUT_LEN{|miss_data_ok | uncache_data_ok}} & miss_ret_data   ;


wire [1:0] hit_count;
wire [1:0] miss_count;
`ifdef LA64
  assign hit_count  = offset     [3:2] == 2'b11 ? ~offset     [1:0] : 2'b11;
  assign miss_count = rfil_offset[3:2] == 2'b11 ? ~rfil_offset[1:0] : 2'b11;

  assign miss_data_ok[0] = rfil_send_cpu & rfil_offset == 4'b0000 & rfil_record[0];
  assign miss_data_ok[1] = rfil_send_cpu & (rfil_offset == 4'b0001 | rfil_offset == 4'b0010 | rfil_offset == 4'b0011 | rfil_offset == 4'b0100) & rfil_record[1];
  assign miss_data_ok[2] = rfil_send_cpu & (rfil_offset == 4'b0101 | rfil_offset == 4'b0110 | rfil_offset == 4'b0111 | rfil_offset == 4'b1000) & rfil_record[2];
  assign miss_data_ok[3] = rfil_send_cpu & (rfil_offset == 4'b1001 | rfil_offset == 4'b1010 | rfil_offset == 4'b1011 | rfil_offset[3:2] == 2'b11) & rfil_record[3];
`elsif LA32
  assign hit_count  = offset     [2] == 1'b1 ? ~offset     [1:0] : 2'b11;
  assign miss_count = rfil_offset[2] == 1'b1 ? ~rfil_offset[1:0] : 2'b11;

  // uty: test
  assign miss_data_ok[0] = rfil_send_cpu &  rfil_offset == 3'b000 & rfil_record[1];
  assign miss_data_ok[1] = rfil_send_cpu & (rfil_offset == 3'b001  || rfil_offset == 3'b010) & rfil_record[2];
  assign miss_data_ok[2] = rfil_send_cpu & (rfil_offset[2] == 1'b1 || rfil_offset == 3'b011) & rfil_record[3];
  assign miss_data_ok[3] = rfil_send_cpu & (rfil_offset[2] == 1'b1 || rfil_offset == 3'b011) & rfil_record[3];

//  assign miss_data_ok[0] = (rfil_offset_uty == 3'b000  || rfil_offset_uty == 3'b001) & rfil_record[0];
//  assign miss_data_ok[1] = (rfil_offset_uty == 3'b010  || rfil_offset_uty == 3'b011) & rfil_record[1];
//  assign miss_data_ok[2] = (rfil_offset_uty == 3'b100  || rfil_offset_uty == 3'b101) & rfil_record[2];
//  assign miss_data_ok[3] = (rfil_offset_uty == 3'b110  || rfil_offset_uty == 3'b111) & rfil_record[3];

`endif

assign inst_count = (uncache_data_ok)? 2'b00 : ({2{|hit_data_ok}} & hit_count | {2{|miss_data_ok}} & miss_count);

assign inst_addr_ok = inst_req && !cache_op_req && (!rfil_send_cpu || |miss_data_ok || uncache_data_ok) &&
                      (state_idle || tlb_finish && cache_hit);

assign hit_data_ok     = cache_hit;
assign error_data_ok   = tlb_finish && !tlb_hit;
assign uncache_data_ok = rfil_send_cpu && rfil_uncache & rfil_record[0];

wire imm_cancel;
assign imm_cancel = inst_cancel && !inst_req;
assign inst_valid = (hit_data_ok | error_data_ok | uncache_data_ok | |miss_data_ok) && !imm_cancel && !inst_cancel_reg;

// ------------------------- END --------------------------



// ---------------------- Fetch Data ----------------------
assign rfil_valid     = rfil_state != 4'b0000;
assign rfil_idle      = rfil_state == 4'b0000;
assign rfil_addr_wait = rfil_state == 4'b0001;
assign rfil_data_wait = rfil_state == 4'b0010;

// uty: test
assign rfil_hit     = rfil_valid && tlb_ptag == rfil_ptag && index == rfil_index && tlb_finish && state_lkup;
//assign rfil_hit     = rfil_valid && tlb_ptag == rfil_ptag && index == rfil_index && tlb_finish;

assign rfil_alloc   = rfil_idle && state_lkup && cache_miss && !rfil_hit || rfil_refill && state_blck;

assign rfil_wait_go = rfil_data_wait && rfil_record[`RFIL_RECORD_LEN-1] && (state_idle & !inst_req | state_blck) &&
                      !lru_en_valid && !lru_wr_valid;

assign rfil_refill  = rfil_wait_go;

assign rfil_clear  = rfil_refill || rfil_data_wait && rfil_uncache && rfil_record[0];

assign rfil_new_req = (rfil_alloc | rfil_hit);

always@ (posedge clk) begin
  if(rst)
    rfil_state <= 4'b0000;
  else if(rfil_alloc) // TODO: can cancel if cancel occur!
    rfil_state <= 4'b0001;
  else if(rfil_addr_wait && rd_ready)
    rfil_state <= 4'b0010;
  
  else if(rfil_data_wait && rfil_uncache && rfil_record[0])
    rfil_state <= 4'b0000;
  else if(rfil_wait_go)
    rfil_state <= 4'b0000;
end

// Send CPU Flag
always @(posedge clk) begin
  if(rst)
    rfil_send_cpu <= 1'b0;
  else if(|miss_data_ok || uncache_data_ok)
    rfil_send_cpu <= rfil_new_req;
  else if(rfil_new_req) 
    rfil_send_cpu <= 1'b1;
end

// ptag index index
always @(posedge clk) begin
  if(rfil_new_req) begin
    rfil_ptag   <= (state_blck)? blck_ptag : tlb_ptag;
    rfil_index  <= index;
    rfil_offset <= offset;   
  end
end

//assign rfil_offset_uty = inst_addr[`I_OFFSET_BITS]; // uty: tet

// cache or uncache
always @(posedge clk) begin
  if(uncache_data_ok) // TODO: remove?
    rfil_uncache <= 1'b0;
  else if(rfil_alloc)
    rfil_uncache <= (state_blck)? blck_uncache : tlb_uncache;
end


always @(posedge clk) begin
  if(ret_valid) begin
  `ifdef LA64
    {rfil_data[15], rfil_data[14], rfil_data[13], rfil_data[12]} <= (!rfil_record[3] & rfil_record[2])? ret_data        : {rfil_data[15], rfil_data[14], rfil_data[13], rfil_data[12]};
    {rfil_data[11], rfil_data[10], rfil_data[ 9], rfil_data[ 8]} <= (!rfil_record[2] & rfil_record[1])? ret_data        : {rfil_data[11], rfil_data[10], rfil_data[ 9], rfil_data[ 8]};
    {rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4]} <= (!rfil_record[1] & rfil_record[0])? ret_data        : {rfil_data[ 7], rfil_data[ 6], rfil_data[ 5], rfil_data[ 4]};
    {rfil_data[ 3], rfil_data[ 2], rfil_data[ 1]               } <= (!rfil_record[0]                 )? ret_data[127:32]: {rfil_data[ 3], rfil_data[ 2], rfil_data[ 1]               };
  `elsif LA32
    {rfil_data[ 7], rfil_data[ 6]} <= (!rfil_record[3] & rfil_record[2])? ret_data       : {rfil_data[ 7], rfil_data[ 6]};
    {rfil_data[ 5], rfil_data[ 4]} <= (!rfil_record[2] & rfil_record[1])? ret_data       : {rfil_data[ 5], rfil_data[ 4]};
    {rfil_data[ 3], rfil_data[ 2]} <= (!rfil_record[1] & rfil_record[0])? ret_data       : {rfil_data[ 3], rfil_data[ 2]};
    {rfil_data[ 1]               } <= (!rfil_record[0]                 )? ret_data[63:32]: {rfil_data[ 1]               };
  `endif
  end
end

always @(posedge clk) begin
  if(ret_valid & !rfil_record[0])
  `ifdef LA64
    rfil_data[ 0] <= {32{!rfil_uncache | rfil_offset[1:0] == 2'b00}} & ret_data[ 31: 0] |
                     {32{ rfil_uncache & rfil_offset[1:0] == 2'b01}} & ret_data[ 63:32] |
                     {32{ rfil_uncache & rfil_offset[1:0] == 2'b10}} & ret_data[ 95:64] |
                     {32{ rfil_uncache & rfil_offset[1:0] == 2'b11}} & ret_data[127:96] ;
  `elsif LA32
    rfil_data[ 0] <= {32{!rfil_uncache | rfil_offset[0] == 1'b0}} & ret_data[ 31: 0] |
                     {32{ rfil_uncache & rfil_offset[0] == 1'b1}} & ret_data[ 63:32] ;
  `endif
                    
end

always @(posedge clk) begin
  // uty: test
  if((!rfil_uncache && rfil_record[`RFIL_RECORD_LEN-1] && rfil_refill || rfil_uncache && rfil_record[0]) || rfil_alloc)
  //if((!rfil_uncache && rfil_record[`RFIL_RECORD_LEN-1] || rfil_uncache && rfil_record[0]) || rfil_alloc)
    rfil_record <= {`RFIL_RECORD_LEN{1'b0}};
  else if(rfil_data_wait && ret_valid) begin
    rfil_record[3] <= rfil_record[2]? 1'b1 : 1'b0;
    rfil_record[2] <= rfil_record[1]? 1'b1 : 1'b0;
    rfil_record[1] <= rfil_record[0]? 1'b1 : 1'b0;
    rfil_record[0] <=                 1'b1       ;
  end
end

always @(posedge clk) begin
  if(ret_valid && rfil_record[0]) begin
    rfil_rstate <= ret_rstate;
    rfil_rscway <= ret_rscway;
  end
end
// ------------------------- END --------------------------



// ----------------------- Cache OP -----------------------
assign cache_op_addr_ok = state_idle && cache_op_req;
assign cache_op_ok      = state_ophd || cache_op_error;
assign cache_op_error   = state_oprd && tlb_finish && !tlb_hit && cache_op_code[`HIT_INV];
assign cache_op_badvaddr = cache_op_addr_his;

always @(posedge clk) begin
  if(cache_op_addr_ok) begin
    cache_op_addr_his <= cache_op_addr;
  	cache_op_code     <= cache_op;
  end
end

assign cache_op_index = cache_op_addr_his[`I_INDEX_BITS];
assign cache_op_way   = cache_op_addr_his[`I_WAY_BITS];

always @(posedge clk) begin
  if(state_oprd && tlb_finish)
    cache_op_wayhit <= way_hit;
end

// ------------------------- END --------------------------



// ----------------------- EXT REQ ------------------------
assign ex_req_recv = ex_req && (ex_idle || ex_handle_fin);
assign ex_rdtag_ready = ex_rdtag && (state_idle || tlb_finish);

assign ex_handle_fin = ex_wtbk_req && wr_ready;
assign ex_wtbk_req   = ex_handle;

always @(posedge clk) begin
  if(ex_req_recv) begin
    ex_op     <= ex_req_op    ;
    ex_paddr  <= ex_req_paddr ;
    ex_cpuno  <= ex_req_cpuno ;
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
  if(ex_tagcmp)
    ex_wayhit_reg  <= ex_wayhit;
end

// ------------------------- END --------------------------



// ------------------------- IO ---------------------------
assign rd_req     = rfil_addr_wait;
assign rd_addr    = (rfil_uncache)? {rfil_ptag, rfil_index[9-`I_OFFSET_LEN:0], rfil_offset     , 2'b0}: 
                                    {rfil_ptag, rfil_index[9-`I_OFFSET_LEN:0], `I_OFFSET_LEN'b0, 2'b0};
assign rd_uncache =  rfil_uncache;

assign wr_req      = ex_wtbk_req;
assign wr_addr     = {`PABITS{1'b0}};
assign wr_data     = {`I_LINE_SIZE_b{1'b0}};
assign wr_awcmd    = `AWCMD_INV;
assign wr_awstate  =  2'b00;
assign wr_awdirqid =  ex_dirqid;
assign wr_awscway  = 4'b0;
assign wr_pgcl     = ex_pgcl;
assign wr_fmt      = `WR_FMT_ALLLINE;
// ------------------------- END --------------------------
endmodule
