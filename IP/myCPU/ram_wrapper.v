`include "common.vh"

`define FUNC_EMUL_LIB

module ram_wrapper
(
    input clk   ,
    input resetn,   //low active

    output icache_init_finish  ,
    output dcache_init_finish  ,

    `LSOC1K_DECL_BHT_RAMS_S,

    // icache ram
    input  [`I_WAY_NUM-1      :0] icache_tag_clk_en  ,
    input  [`I_WAY_NUM-1      :0] icache_tag_en      ,
    input  [`I_WAY_NUM-1      :0] icache_tag_wen     ,  // The least significant bit denote way_0
    input  [`I_INDEX_LEN-1    :0] icache_tag_addr    ,
    input  [`I_TAGARRAY_LEN-1 :0] icache_tag_wdata   ,  // valid + tag, the most significant bit denote valid bit
    output [`I_IO_TAG_LEN-1   :0] icache_tag_rdata   ,

    input                         icache_lru_clk_en  ,
    input                         icache_lru_en      ,
    input  [`I_LRU_WIDTH-1    :0] icache_lru_wen     ,
    input  [`I_INDEX_LEN-1    :0] icache_lru_addr    ,
    input  [`I_LRU_WIDTH-1    :0] icache_lru_wdata   ,
    output [`I_LRU_WIDTH-1    :0] icache_lru_rdata   ,

    input  [`I_WAY_NUM-1      :0] icache_data_clk_en ,
    input  [`I_IO_EN_LEN-1    :0] icache_data_en     ,
    input  [`I_WAY_NUM-1      :0] icache_data_wen    ,
    input  [`I_INDEX_LEN-1    :0] icache_data_addr   ,
    input  [`I_IO_WDATA_LEN-1 :0] icache_data_wdata  ,
    output [`I_IO_RDATA_LEN-1 :0] icache_data_rdata  ,

    // dcache ram
    input  [`D_WAY_NUM-1      :0] dcache_tag_clk_en  ,
    input  [`D_WAY_NUM-1      :0] dcache_tag_en      ,
    input  [`D_WAY_NUM-1      :0] dcache_tag_wen     ,  // The least significant bit denote way_0
    input  [`D_INDEX_LEN-1    :0] dcache_tag_addr    ,
    input  [`D_TAGARRAY_LEN-1 :0] dcache_tag_wdata   ,  // valid + tag, the most significant bit denote valid bit
    output [`D_RAM_TAG_LEN-1  :0] dcache_tag_rdata   ,

    input                         dcache_lrud_clk_en ,
    input                         dcache_lrud_en     ,
    input  [`D_LRUD_WIDTH-1   :0] dcache_lrud_wen    ,
    input  [`D_INDEX_LEN-1    :0] dcache_lrud_addr   ,
    input  [`D_LRUD_WIDTH-1   :0] dcache_lrud_wdata  ,
    output [`D_LRUD_WIDTH-1   :0] dcache_lrud_rdata  ,

    input  [`D_WAY_NUM-1      :0] dcache_data_clk_en   ,
    input  [`D_RAM_EN_LEN-1   :0] dcache_data_en       ,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank0,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank1,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank2,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank3,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank4,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank5,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank6,
    input  [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank7,
    input  [`D_RAM_ADDR_LEN-1 :0] dcache_data_addr     ,
    input  [`D_RAM_WDATA_LEN-1:0] dcache_data_wdata    ,
    output [`D_RAM_RDATA_LEN-1:0] dcache_data_rdata  
    );
wire rst;
assign rst = !resetn;

// bht
`LSOC1K_DECL_BHT_RAMS_CG
`ifdef FUNC_EMUL_LIB
`LSOC1K_DECL_BHT_RAMS_INS_REG
`else
`LSOC1K_DECL_BHT_RAMS_INS_RAM
`endif

// icache
reg [`I_INDEX_LEN-1:0] ic_init_count;
reg ic_init_finish;
always @(posedge clk) begin
  if(rst)
    ic_init_count <= {`I_INDEX_LEN{1'b0}};
  else if(ic_init_count != {`I_INDEX_LEN{1'b1}})
    ic_init_count <= ic_init_count + 1'b1;
end
always @(posedge clk) begin
  if(rst)
    ic_init_finish <= 1'b0;
  else if(ic_init_count == {`I_INDEX_LEN{1'b1}})
    ic_init_finish <= 1'b1;
end

assign icache_init_finish = ic_init_finish;

wire                    real_ic_lru_clk_en;
wire                    real_ic_lru_en    ;
wire [`I_LRU_WIDTH-1:0] real_ic_lru_wen   ;
wire [`I_INDEX_LEN-1:0] real_ic_lru_addr  ;
wire [`I_LRU_WIDTH-1:0] real_ic_lru_wdata ;

wire [`I_TAGARRAY_LEN-1:0] i_tag_rdata  [`I_WAY_NUM-1:0]; // valid + ptag
wire [7                :0] i_data_en    [`I_WAY_NUM-1:0];
wire [`I_WAY_NUM-1     :0] i_data_wen;
wire [`I_INDEX_LEN-1   :0] i_data_addr;
wire [`GRLEN-1         :0] i_data_wdata [7:0];
wire [`I_LINE_SIZE_b-1 :0] i_rdata_sum  [`I_WAY_NUM-1:0];

`ifdef I_WAY_NUM4
  assign icache_tag_rdata = {i_tag_rdata[3], i_tag_rdata[2], i_tag_rdata[1], i_tag_rdata[0]};

  assign {i_data_en[3], i_data_en[2], i_data_en[1], i_data_en[0]} = icache_data_en;
  assign i_data_wen  = icache_data_wen;
  assign i_data_addr = icache_data_addr;
  assign {i_data_wdata[7], i_data_wdata[6], i_data_wdata[5], i_data_wdata[4],
          i_data_wdata[3], i_data_wdata[2], i_data_wdata[1], i_data_wdata[0]} = icache_data_wdata;
  assign icache_data_rdata = {i_rdata_sum[3], i_rdata_sum[2], i_rdata_sum[1], i_rdata_sum[0]};
`endif
  
  // tag
wire [`I_WAY_NUM-1     :0] real_ic_tag_clk_en;
wire [`I_WAY_NUM-1     :0] real_ic_tag_en    ;
wire [`I_WAY_NUM-1     :0] real_ic_tag_wen   ;
wire [`I_INDEX_LEN-1   :0] real_ic_tag_addr  ;
wire [`I_TAGARRAY_LEN-1:0] real_ic_tag_wdata ;

assign real_ic_tag_clk_en = {`I_WAY_NUM{ic_init_finish}} & icache_tag_clk_en | {`I_WAY_NUM{!ic_init_finish}};
assign real_ic_tag_en     = {`I_WAY_NUM{ic_init_finish}} & icache_tag_en     | {`I_WAY_NUM{!ic_init_finish}};
assign real_ic_tag_wen    = {`I_WAY_NUM{ic_init_finish}} & icache_tag_wen    | {`I_WAY_NUM{!ic_init_finish}};
assign real_ic_tag_addr   = {`I_INDEX_LEN{ ic_init_finish}} & icache_tag_addr|
                            {`I_INDEX_LEN{!ic_init_finish}} & ic_init_count  ;
assign real_ic_tag_wdata  = {`I_TAGARRAY_LEN{ ic_init_finish}} & icache_tag_wdata;

wire [`I_WAY_NUM-1:0] itag_clk;
genvar gv_itag_ram;
generate
  for(gv_itag_ram = 0; gv_itag_ram < `I_WAY_NUM; gv_itag_ram = gv_itag_ram + 1)
  begin : itag_ram

    cg_cell_wrap u_itag_cell_wrap  (.clock_in(clk), .enable(real_ic_tag_clk_en[gv_itag_ram]), .test_enable(1'b0), .clock_out(itag_clk[gv_itag_ram]));

    `ifdef FUNC_EMUL_LIB
    icache_tag_reg u_icache_tag(
      .clka  (itag_clk[gv_itag_ram]       ),
      .rst   (rst                         ),
      .ena   (real_ic_tag_en[gv_itag_ram] ), 
      .wea   (real_ic_tag_wen[gv_itag_ram]), 
      .addra (real_ic_tag_addr            ), 
      .dina  (real_ic_tag_wdata           ), 
      .douta (i_tag_rdata[gv_itag_ram]    )
    );
    `else
    cache_tag_ram u_icache_rag(
      .clka  (itag_clk[gv_itag_ram]       ), 
      .ena   (real_ic_tag_en[gv_itag_ram] ), 
      .wea   (real_ic_tag_wen[gv_itag_ram]), 
      .addra (real_ic_tag_addr            ), 
      .dina  (real_ic_tag_wdata           ), 
      .douta (i_tag_rdata[gv_itag_ram]    )
    );
    `endif
  end
endgenerate

assign real_ic_lru_clk_en = ic_init_finish & icache_lru_clk_en | !ic_init_finish;
assign real_ic_lru_en     = ic_init_finish & icache_lru_en     | !ic_init_finish;
assign real_ic_lru_wen    = {`I_LRU_WIDTH{ic_init_finish}} & icache_lru_wen | {`I_LRU_WIDTH{!ic_init_finish}};
assign real_ic_lru_wdata  = {`I_LRU_WIDTH{ic_init_finish}} & icache_lru_wdata; // {6'b000_00_0} for init
assign real_ic_lru_addr   = {`I_INDEX_LEN{ ic_init_finish}} & icache_lru_addr|
                            {`I_INDEX_LEN{!ic_init_finish}} & ic_init_count  ;
  // lru
wire ilru_clk;
cg_cell_wrap u_ilru_cell_wrap  (.clock_in(clk), .enable(real_ic_lru_clk_en), .test_enable(1'b0), .clock_out(ilru_clk));

`ifdef FUNC_EMUL_LIB
icache_lru_reg u_icache_lru
(
    .clka  (ilru_clk         ),
    .rst   (rst              ),
    .ena   (real_ic_lru_en   ),
    .wea   (real_ic_lru_wen  ),
    .addra (real_ic_lru_addr ),
    .dina  (real_ic_lru_wdata),
    .douta (icache_lru_rdata )
);
`else
icache_lru_ram u_icache_lru
(
    .clka  (ilru_clk         ),
    .ena   (real_ic_lru_en   ),
    .wea   (real_ic_lru_wen  ),
    .addra (real_ic_lru_addr ),
    .dina  (real_ic_lru_wdata),
    .douta (icache_lru_rdata )
);
`endif

  // data array
wire [`I_WAY_NUM-1  :0] real_ic_data_clk_en;
wire [7             :0] real_ic_data_en [`I_WAY_NUM-1:0];
wire [`I_WAY_NUM-1  :0] real_ic_data_wen  ;
wire [`I_INDEX_LEN-1:0] real_ic_data_addr ;
wire [`GRLEN-1      :0] real_ic_data_wdata [7:0];

assign real_ic_data_clk_en = {`I_WAY_NUM{ ic_init_finish}} & icache_data_clk_en | {`I_WAY_NUM{!ic_init_finish}};
assign real_ic_data_wen    = {`I_WAY_NUM{ ic_init_finish}} & i_data_wen         | {`I_WAY_NUM{!ic_init_finish}};
assign real_ic_data_addr   = {`I_INDEX_LEN{ ic_init_finish}} & i_data_addr  |
                             {`I_INDEX_LEN{!ic_init_finish}} & ic_init_count;

genvar gv_ic_data_init;
generate
  for(gv_ic_data_init = 0; gv_ic_data_init < 8; gv_ic_data_init = gv_ic_data_init + 1)
  begin : idata_init
    assign real_ic_data_wdata[gv_ic_data_init] = {`GRLEN{ic_init_finish}} & i_data_wdata[gv_ic_data_init];
  end
endgenerate

wire [`I_WAY_NUM-1:0] i_data_clk;
genvar gv_idata_ram;
generate 
  for(gv_idata_ram = 0; gv_idata_ram < `I_WAY_NUM; gv_idata_ram = gv_idata_ram + 1)
  begin : icache_data_module
    assign real_ic_data_en[gv_idata_ram]  = {8{ic_init_finish}} & i_data_en[gv_idata_ram] | {8{!ic_init_finish}};

    cg_cell_wrap u_idata_cell_wrap (.clock_in(clk), .enable(real_ic_data_clk_en[gv_idata_ram]), .test_enable(1'b0), .clock_out(i_data_clk[gv_idata_ram]));

    `ifdef FUNC_EMUL_LIB
    icache_data_reg u_idata_bank0(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][0]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[0]), .douta(i_rdata_sum[gv_idata_ram][`BANK0_BITS]));
    icache_data_reg u_idata_bank1(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][1]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[1]), .douta(i_rdata_sum[gv_idata_ram][`BANK1_BITS]));
    icache_data_reg u_idata_bank2(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][2]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[2]), .douta(i_rdata_sum[gv_idata_ram][`BANK2_BITS]));
    icache_data_reg u_idata_bank3(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][3]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[3]), .douta(i_rdata_sum[gv_idata_ram][`BANK3_BITS]));
    icache_data_reg u_idata_bank4(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][4]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[4]), .douta(i_rdata_sum[gv_idata_ram][`BANK4_BITS]));
    icache_data_reg u_idata_bank5(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][5]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[5]), .douta(i_rdata_sum[gv_idata_ram][`BANK5_BITS]));
    icache_data_reg u_idata_bank6(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][6]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[6]), .douta(i_rdata_sum[gv_idata_ram][`BANK6_BITS]));
    icache_data_reg u_idata_bank7(.clka(i_data_clk[gv_idata_ram]), .rst(rst), .ena(real_ic_data_en[gv_idata_ram][7]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[7]), .douta(i_rdata_sum[gv_idata_ram][`BANK7_BITS]));
    `else
    icache_data_ram u_idata_bank0(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][0]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[0]), .douta(i_rdata_sum[gv_idata_ram][`BANK0_BITS]));
    icache_data_ram u_idata_bank1(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][1]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[1]), .douta(i_rdata_sum[gv_idata_ram][`BANK1_BITS]));
    icache_data_ram u_idata_bank2(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][2]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[2]), .douta(i_rdata_sum[gv_idata_ram][`BANK2_BITS]));
    icache_data_ram u_idata_bank3(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][3]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[3]), .douta(i_rdata_sum[gv_idata_ram][`BANK3_BITS]));
    icache_data_ram u_idata_bank4(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][4]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[4]), .douta(i_rdata_sum[gv_idata_ram][`BANK4_BITS]));
    icache_data_ram u_idata_bank5(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][5]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[5]), .douta(i_rdata_sum[gv_idata_ram][`BANK5_BITS]));
    icache_data_ram u_idata_bank6(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][6]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[6]), .douta(i_rdata_sum[gv_idata_ram][`BANK6_BITS]));
    icache_data_ram u_idata_bank7(.clka(i_data_clk[gv_idata_ram]), .ena(real_ic_data_en[gv_idata_ram][7]), .wea(real_ic_data_wen[gv_idata_ram]), .addra(real_ic_data_addr), .dina(real_ic_data_wdata[7]), .douta(i_rdata_sum[gv_idata_ram][`BANK7_BITS]));
    `endif
  end
endgenerate


// dcache
reg [`D_INDEX_LEN-1:0] dc_init_count;
reg dc_init_finish;
always @(posedge clk) begin
  if(rst)
    dc_init_count <= {`D_INDEX_LEN{1'b0}};
  else if(dc_init_count != {`D_INDEX_LEN{1'b1}})
    dc_init_count <= dc_init_count + 1'b1;
end
always @(posedge clk) begin
  if(rst)
    dc_init_finish <= 1'b0;
  else if(dc_init_count == {`D_INDEX_LEN{1'b1}})
    dc_init_finish <= 1'b1;
end

assign dcache_init_finish = dc_init_finish;

wire                       real_dc_lrud_clk_en;
wire                       real_dc_lrud_en    ;
wire [`D_LRUD_WIDTH-1  :0] real_dc_lrud_wen   ;
wire [`D_INDEX_LEN-1:0] real_dc_lrud_addr  ;
wire [`D_LRUD_WIDTH-1  :0] real_dc_lrud_wdata ;

wire [`D_TAGARRAY_LEN-1:0] d_tag_rdata      [`D_WAY_NUM-1:0]; // valid + ptag
wire [7                :0] d_data_en        [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank0 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank1 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank2 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank3 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank4 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank5 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank6 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1   :0] d_data_wen_bank7 [`D_WAY_NUM-1:0];
wire [`D_INDEX_LEN-1   :0] d_data_addr      [           7:0];
wire [`GRLEN-1         :0] d_data_wdata     [           7:0];
wire [`D_LINE_SIZE_b-1 :0] d_rdata_sum      [`D_WAY_NUM-1:0];

`ifdef D_WAY_NUM4
  assign dcache_tag_rdata = {d_tag_rdata[3], d_tag_rdata[2], d_tag_rdata[1], d_tag_rdata[0]};

  assign {d_data_en[3], d_data_en[2], d_data_en[1], d_data_en[0]} = dcache_data_en;

  assign {d_data_wen_bank0[3], d_data_wen_bank0[2], d_data_wen_bank0[1], d_data_wen_bank0[0]} = dcache_data_wen_bank0;
  assign {d_data_wen_bank1[3], d_data_wen_bank1[2], d_data_wen_bank1[1], d_data_wen_bank1[0]} = dcache_data_wen_bank1;
  assign {d_data_wen_bank2[3], d_data_wen_bank2[2], d_data_wen_bank2[1], d_data_wen_bank2[0]} = dcache_data_wen_bank2;
  assign {d_data_wen_bank3[3], d_data_wen_bank3[2], d_data_wen_bank3[1], d_data_wen_bank3[0]} = dcache_data_wen_bank3;
  assign {d_data_wen_bank4[3], d_data_wen_bank4[2], d_data_wen_bank4[1], d_data_wen_bank4[0]} = dcache_data_wen_bank4;
  assign {d_data_wen_bank5[3], d_data_wen_bank5[2], d_data_wen_bank5[1], d_data_wen_bank5[0]} = dcache_data_wen_bank5;
  assign {d_data_wen_bank6[3], d_data_wen_bank6[2], d_data_wen_bank6[1], d_data_wen_bank6[0]} = dcache_data_wen_bank6;
  assign {d_data_wen_bank7[3], d_data_wen_bank7[2], d_data_wen_bank7[1], d_data_wen_bank7[0]} = dcache_data_wen_bank7;
  
  assign {d_data_addr[7], d_data_addr[6], d_data_addr[5], d_data_addr[4],
          d_data_addr[3], d_data_addr[2], d_data_addr[1], d_data_addr[0]} = dcache_data_addr;

  assign {d_data_wdata[7], d_data_wdata[6], d_data_wdata[5], d_data_wdata[4],
          d_data_wdata[3], d_data_wdata[2], d_data_wdata[1], d_data_wdata[0]} = dcache_data_wdata;

  assign dcache_data_rdata = {d_rdata_sum[3], d_rdata_sum[2], d_rdata_sum[1], d_rdata_sum[0]};
`endif

// dcache ram
  // tag array
wire [`D_WAY_NUM-1     :0] real_dc_tag_clk_en;
wire [`D_WAY_NUM-1     :0] real_dc_tag_en    ;
wire [`D_WAY_NUM-1     :0] real_dc_tag_wen   ;
wire [`D_INDEX_LEN-1   :0] real_dc_tag_addr  ;
wire [`D_TAGARRAY_LEN-1:0] real_dc_tag_wdata ;

assign real_dc_tag_clk_en = {`D_WAY_NUM{ dc_init_finish}} & dcache_tag_clk_en | {`D_WAY_NUM{!dc_init_finish}};
assign real_dc_tag_en     = {`D_WAY_NUM{ dc_init_finish}} & dcache_tag_en     | {`D_WAY_NUM{!dc_init_finish}};
assign real_dc_tag_wen    = {`D_WAY_NUM{ dc_init_finish}} & dcache_tag_wen    | {`D_WAY_NUM{!dc_init_finish}};
assign real_dc_tag_addr   = {`D_INDEX_LEN{ dc_init_finish}} & dcache_tag_addr | 
                            {`D_INDEX_LEN{!dc_init_finish}} & dc_init_count   ;
assign real_dc_tag_wdata  = {`D_TAGARRAY_LEN{ dc_init_finish}} & dcache_tag_wdata;

wire [`D_WAY_NUM-1:0] dtag_clk;
genvar gv_dtag_ram;
generate
  for(gv_dtag_ram = 0; gv_dtag_ram < `D_WAY_NUM; gv_dtag_ram = gv_dtag_ram + 1)
  begin : dtag_ram

    cg_cell_wrap u_dtag_cell_wrap  (.clock_in(clk), .enable(real_dc_tag_clk_en[gv_dtag_ram]), .test_enable(1'b0), .clock_out(dtag_clk[gv_dtag_ram]));

  `ifdef FUNC_EMUL_LIB
    dcache_tag_reg u_dcache_tag(
        .clka  (dtag_clk[gv_dtag_ram]       ),
        .rst   (rst                         ),
        .ena   (real_dc_tag_en[gv_dtag_ram] ),
        .wea   (real_dc_tag_wen[gv_dtag_ram]),
        .addra (real_dc_tag_addr            ),
        .dina  (real_dc_tag_wdata           ),
        .douta (d_tag_rdata[gv_dtag_ram]    )
    );
  `else
    cache_tag_ram u_dcache_tag(
        .clka  (dtag_clk[gv_dtag_ram]      ),
        .ena   (real_dc_tag_en[gv_dtag_ram] ),
        .wea   (real_dc_tag_wen[gv_dtag_ram]),
        .addra (real_dc_tag_addr            ),
        .dina  (real_dc_tag_wdata           ),
        .douta (d_tag_rdata[gv_dtag_ram]    )
    );
  `endif
  end
endgenerate

assign real_dc_lrud_clk_en = dc_init_finish & dcache_lrud_clk_en | !dc_init_finish;
assign real_dc_lrud_en     = dc_init_finish & dcache_lrud_en     | !dc_init_finish;
assign real_dc_lrud_wen    = {`D_LRUD_WIDTH{dc_init_finish}} & dcache_lrud_wen | {`D_LRUD_WIDTH{!dc_init_finish}};
assign real_dc_lrud_addr   = {`D_INDEX_LEN{ dc_init_finish}} & dcache_lrud_addr|
                             {`D_INDEX_LEN{!dc_init_finish}} & dc_init_count   ;
assign real_dc_lrud_wdata  = {`D_LRUD_WIDTH{dc_init_finish}} & dcache_lrud_wdata; // {4'b0, 6'b000_00_0} for init
  // lru
wire dlrud_clk;
cg_cell_wrap u_dlru_cell_wrap  (.clock_in(clk), .enable(real_dc_lrud_clk_en), .test_enable(1'b0), .clock_out(dlrud_clk));

`ifdef FUNC_EMUL_LIB
dcache_lrud_reg u_dcache_lrud
(
    .clka  (dlrud_clk         ),
    .rst   (rst               ),
    .ena   (real_dc_lrud_en   ),
    .wea   (real_dc_lrud_wen  ),
    .addra (real_dc_lrud_addr ),
    .dina  (real_dc_lrud_wdata),
    .douta (dcache_lrud_rdata )
);
`else
dcache_lrud_ram u_dcache_lrud
(
    .clka  (dlrud_clk         ),
    .ena   (real_dc_lrud_en   ),
    .wea   (real_dc_lrud_wen  ),
    .addra (real_dc_lrud_addr ),
    .dina  (real_dc_lrud_wdata),
    .douta (dcache_lrud_rdata )
);
`endif

  // data array
wire [`D_WAY_NUM-1  :0] real_dc_data_clk_en;
wire [7             :0] real_dc_data_en        [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank0 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank1 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank2 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank3 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank4 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank5 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank6 [`D_WAY_NUM-1:0];
wire [`WSTRB_WIDTH-1:0] real_dc_data_wen_bank7 [`D_WAY_NUM-1:0];
wire [`D_INDEX_LEN-1:0] real_dc_data_addr      [           7:0];
wire [`GRLEN-1      :0] real_dc_data_wdata     [           7:0];

assign real_dc_data_clk_en = {`D_WAY_NUM{ dc_init_finish}} & dcache_data_clk_en | {`D_WAY_NUM{!dc_init_finish}};

genvar gv_dc_data_init;
generate
  for(gv_dc_data_init = 0; gv_dc_data_init < 8; gv_dc_data_init = gv_dc_data_init + 1)
  begin : ddata_init
    assign real_dc_data_addr[gv_dc_data_init]  = {`D_INDEX_LEN{ dc_init_finish}} & d_data_addr[gv_dc_data_init]| 
                                                 {`D_INDEX_LEN{!dc_init_finish}} & dc_init_count               ;
    assign real_dc_data_wdata[gv_dc_data_init] = {`GRLEN{dc_init_finish}} & d_data_wdata[gv_dc_data_init];
  end
endgenerate


wire [`D_WAY_NUM-1:0] d_data_clk;
genvar gv_ddata_ram;
generate
  for(gv_ddata_ram = 0; gv_ddata_ram < `D_WAY_NUM; gv_ddata_ram = gv_ddata_ram + 1)
  begin : dcache_data_module
    assign real_dc_data_en[gv_ddata_ram]        = {8{ dc_init_finish}} & d_data_en[gv_ddata_ram] | {8{!dc_init_finish}};

    assign real_dc_data_wen_bank0[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank0[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank1[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank1[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank2[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank2[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank3[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank3[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank4[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank4[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank5[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank5[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank6[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank6[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};
    assign real_dc_data_wen_bank7[gv_ddata_ram] = {`WSTRB_WIDTH{dc_init_finish}} & d_data_wen_bank7[gv_ddata_ram] | {`WSTRB_WIDTH{!dc_init_finish}};


    cg_cell_wrap u_ddata_cell_wrap (.clock_in(clk), .enable(real_dc_data_clk_en[gv_ddata_ram]), .test_enable(1'b0), .clock_out(d_data_clk[gv_ddata_ram]));

    `ifdef FUNC_EMUL_LIB
    dcache_data_reg u_ddata_bank0(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][0]), .wea(real_dc_data_wen_bank0[gv_ddata_ram]), .addra(real_dc_data_addr[0]), .dina(real_dc_data_wdata[0]), .douta(d_rdata_sum[gv_ddata_ram][`BANK0_BITS]));
    dcache_data_reg u_ddata_bank1(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][1]), .wea(real_dc_data_wen_bank1[gv_ddata_ram]), .addra(real_dc_data_addr[1]), .dina(real_dc_data_wdata[1]), .douta(d_rdata_sum[gv_ddata_ram][`BANK1_BITS]));
    dcache_data_reg u_ddata_bank2(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][2]), .wea(real_dc_data_wen_bank2[gv_ddata_ram]), .addra(real_dc_data_addr[2]), .dina(real_dc_data_wdata[2]), .douta(d_rdata_sum[gv_ddata_ram][`BANK2_BITS]));
    dcache_data_reg u_ddata_bank3(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][3]), .wea(real_dc_data_wen_bank3[gv_ddata_ram]), .addra(real_dc_data_addr[3]), .dina(real_dc_data_wdata[3]), .douta(d_rdata_sum[gv_ddata_ram][`BANK3_BITS]));
    dcache_data_reg u_ddata_bank4(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][4]), .wea(real_dc_data_wen_bank4[gv_ddata_ram]), .addra(real_dc_data_addr[4]), .dina(real_dc_data_wdata[4]), .douta(d_rdata_sum[gv_ddata_ram][`BANK4_BITS]));
    dcache_data_reg u_ddata_bank5(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][5]), .wea(real_dc_data_wen_bank5[gv_ddata_ram]), .addra(real_dc_data_addr[5]), .dina(real_dc_data_wdata[5]), .douta(d_rdata_sum[gv_ddata_ram][`BANK5_BITS]));
    dcache_data_reg u_ddata_bank6(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][6]), .wea(real_dc_data_wen_bank6[gv_ddata_ram]), .addra(real_dc_data_addr[6]), .dina(real_dc_data_wdata[6]), .douta(d_rdata_sum[gv_ddata_ram][`BANK6_BITS]));
    dcache_data_reg u_ddata_bank7(.clka(d_data_clk[gv_ddata_ram]), .rst(rst), .ena(real_dc_data_en[gv_ddata_ram][7]), .wea(real_dc_data_wen_bank7[gv_ddata_ram]), .addra(real_dc_data_addr[7]), .dina(real_dc_data_wdata[7]), .douta(d_rdata_sum[gv_ddata_ram][`BANK7_BITS]));
    `else
    dcache_data_ram u_ddata_bank0(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][0]), .wea(real_dc_data_wen_bank0[gv_ddata_ram]), .addra(real_dc_data_addr[0]), .dina(real_dc_data_wdata[0]), .douta(d_rdata_sum[gv_ddata_ram][`BANK0_BITS]));
    dcache_data_ram u_ddata_bank1(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][1]), .wea(real_dc_data_wen_bank1[gv_ddata_ram]), .addra(real_dc_data_addr[1]), .dina(real_dc_data_wdata[1]), .douta(d_rdata_sum[gv_ddata_ram][`BANK1_BITS]));
    dcache_data_ram u_ddata_bank2(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][2]), .wea(real_dc_data_wen_bank2[gv_ddata_ram]), .addra(real_dc_data_addr[2]), .dina(real_dc_data_wdata[2]), .douta(d_rdata_sum[gv_ddata_ram][`BANK2_BITS]));
    dcache_data_ram u_ddata_bank3(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][3]), .wea(real_dc_data_wen_bank3[gv_ddata_ram]), .addra(real_dc_data_addr[3]), .dina(real_dc_data_wdata[3]), .douta(d_rdata_sum[gv_ddata_ram][`BANK3_BITS]));
    dcache_data_ram u_ddata_bank4(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][4]), .wea(real_dc_data_wen_bank4[gv_ddata_ram]), .addra(real_dc_data_addr[4]), .dina(real_dc_data_wdata[4]), .douta(d_rdata_sum[gv_ddata_ram][`BANK4_BITS]));
    dcache_data_ram u_ddata_bank5(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][5]), .wea(real_dc_data_wen_bank5[gv_ddata_ram]), .addra(real_dc_data_addr[5]), .dina(real_dc_data_wdata[5]), .douta(d_rdata_sum[gv_ddata_ram][`BANK5_BITS]));
    dcache_data_ram u_ddata_bank6(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][6]), .wea(real_dc_data_wen_bank6[gv_ddata_ram]), .addra(real_dc_data_addr[6]), .dina(real_dc_data_wdata[6]), .douta(d_rdata_sum[gv_ddata_ram][`BANK6_BITS]));
    dcache_data_ram u_ddata_bank7(.clka(d_data_clk[gv_ddata_ram]), .ena(real_dc_data_en[gv_ddata_ram][7]), .wea(real_dc_data_wen_bank7[gv_ddata_ram]), .addra(real_dc_data_addr[7]), .dina(real_dc_data_wdata[7]), .douta(d_rdata_sum[gv_ddata_ram][`BANK7_BITS]));
    `endif
  end
endgenerate

endmodule

module cg_cell_wrap(
  input clock_in,
  input enable, 
  input test_enable,
  output clock_out
);

`ifdef FUNC_EMUL_LIB
reg lat_en /*verilator clock_enable*/;
//always_latch begin
always @* begin
if (clock_in == 1'b0) begin
    lat_en = enable | test_enable;
end
end

//assign clock_out = lat_en & clock_in;
assign clock_out = clock_in;
`endif

endmodule



`ifdef FUNC_EMUL_LIB
module bht_sp_reg
#(
    parameter width=16,
    parameter depth=6
)
(
    input                      clka ,
    input                      rst  ,
    input                      ena  ,
    input  [width-1:0] wea  ,
    input  [depth-1:0] addra,
    input  [width-1:0] dina ,
    output [width-1:0] douta
);
reg [width-1:0] item_entry [(1<<depth)-1:0];
reg [width-1:0] item_rdata;
assign douta = item_rdata;
always @(posedge clka) begin
  if(rst)
    item_rdata <= {width{1'b0}};
  else if(ena)
  begin
    if(|wea) begin
        item_entry[addra] <= dina&wea|item_entry[addra]&~wea;
    end
    else begin
        item_rdata <= item_entry[addra];
    end
  end
end
endmodule

// icache
  // tag
module icache_tag_reg(
  input                        clka ,
  input                        rst  ,
  input                        ena  ,
  input                        wea  ,
  input  [`I_INDEX_LEN-1   :0] addra,
  input  [`I_TAGARRAY_LEN-1:0] dina ,
  output [`I_TAGARRAY_LEN-1:0] douta
);

reg [`I_TAGARRAY_LEN-1:0] item_entry [`I_SET_NUM-1:0];
reg [`I_TAGARRAY_LEN-1:0] item_rdata;
assign douta = item_rdata;

always @(posedge clka) begin
  if(rst)
    item_rdata <= {`I_TAGARRAY_LEN{1'b0}};
  else if(ena)
    item_rdata <= item_entry[addra];
  end

genvar gv_item_reg;
generate
  for(gv_item_reg = 0; gv_item_reg < `I_SET_NUM; gv_item_reg = gv_item_reg + 1)
  begin : itag_ram
    always @(posedge clka) begin
      if(wea && addra == gv_item_reg)
        item_entry[gv_item_reg] <= dina;
 end
  end
endgenerate
endmodule

  // ilru
module icache_lru_reg (
  input                     clka ,
  input                     rst  ,
  input                     ena  ,
  input  [`I_LRU_WIDTH-1:0] wea  ,
  input  [`I_INDEX_LEN-1:0] addra,
  input  [`I_LRU_WIDTH-1:0] dina ,
  output [`I_LRU_WIDTH-1:0] douta
);

reg [`I_LRU_WIDTH-1:0] item_entry [`I_SET_NUM-1:0];
reg [`I_LRU_WIDTH-1:0] item_rdata;
assign douta = item_rdata;

always @(posedge clka) begin
  if(rst)
    item_rdata <= {`I_LRU_WIDTH{1'b0}};
  else if(ena)
    item_rdata <= item_entry[addra];
end

genvar gv_item_reg;
generate
  for(gv_item_reg = 0; gv_item_reg < `I_SET_NUM; gv_item_reg = gv_item_reg + 1)
  begin : ilru_ram
    always @(posedge clka) begin
      if(|wea && addra == gv_item_reg)
        `ifdef I_WAY_NUM4
          item_entry[gv_item_reg] <= {wea[5]? dina[5] : item_entry[gv_item_reg][5],
                                      wea[4]? dina[4] : item_entry[gv_item_reg][4],
                                      wea[3]? dina[3] : item_entry[gv_item_reg][3],
                                      wea[2]? dina[2] : item_entry[gv_item_reg][2],
                                      wea[1]? dina[1] : item_entry[gv_item_reg][1],
                                      wea[0]? dina[0] : item_entry[gv_item_reg][0]};
        `endif
    end
  end
endgenerate
endmodule

// idata
module icache_data_reg(
  input                     clka ,
  input                     rst  ,
  input                     ena  ,
  input                     wea  ,
  input  [`I_INDEX_LEN-1:0] addra,
  input  [`GRLEN-1      :0] dina ,
  output [`GRLEN-1      :0] douta
);

reg [`GRLEN-1:0] item_entry [`I_SET_NUM-1:0];
reg [`GRLEN-1:0] item_rdata;
assign douta = item_rdata;

always @(posedge clka) begin
  if(rst)
    item_rdata <= {`GRLEN{1'b0}};
  else if(ena)
    item_rdata <= item_entry[addra];
end

genvar gv_item_reg;
generate
  for(gv_item_reg = 0; gv_item_reg < `I_SET_NUM; gv_item_reg = gv_item_reg + 1)
  begin : idata_ram
    always @(posedge clka) begin
      if(wea && addra == gv_item_reg)
        item_entry[gv_item_reg] <= dina;
  end
  end
endgenerate
endmodule


// dcache
  // tag
module dcache_tag_reg (
  input                        clka ,
  input                        rst  ,
  input                        ena  ,
  input                        wea  ,
  input  [`D_INDEX_LEN-1   :0] addra,
  input  [`D_TAGARRAY_LEN-1:0] dina ,
  output [`D_TAGARRAY_LEN-1:0] douta
);

reg [`D_TAGARRAY_LEN-1:0] item_entry [`D_SET_NUM-1:0];
reg [`D_TAGARRAY_LEN-1:0] item_rdata;
assign douta = item_rdata;

always @(posedge clka) begin
  if(rst)
    item_rdata <= {`D_TAGARRAY_LEN{1'b0}};
  else if(ena)
    item_rdata <= item_entry[addra];
end

genvar gv_item_reg;
generate
  for(gv_item_reg = 0; gv_item_reg < `D_SET_NUM; gv_item_reg = gv_item_reg + 1)
  begin : dtag_ram
    always @(posedge clka) begin
      if(wea && addra == gv_item_reg)
        item_entry[gv_item_reg] <= dina;
    end
  end
endgenerate

//DEBUG
wire [`D_TAGARRAY_LEN-1:0] test_tag_0   = item_entry[1];

endmodule

  // dlrud
module dcache_lrud_reg (
  input                      clka ,
  input                      rst  ,
  input                      ena  ,
  input  [`D_LRUD_WIDTH-1:0] wea  ,
  input  [`D_INDEX_LEN-1 :0] addra,
  input  [`D_LRUD_WIDTH-1:0] dina ,
  output [`D_LRUD_WIDTH-1:0] douta
);

reg [`D_LRUD_WIDTH-1:0] item_entry [`D_SET_NUM-1:0];
reg [`D_LRUD_WIDTH-1:0] item_rdata;
assign douta = item_rdata;

always @(posedge clka) begin
  if(rst)
    item_rdata <= {`D_LRUD_WIDTH{1'b0}};
  else if(ena)
    item_rdata <= item_entry[addra];
end

genvar gv_item_reg;
generate
  for(gv_item_reg = 0; gv_item_reg < `D_SET_NUM; gv_item_reg = gv_item_reg + 1)
  begin : dlrud_ram
    always @(posedge clka) begin
      if(|wea && addra == gv_item_reg)
        `ifdef D_WAY_NUM4
          item_entry[gv_item_reg] <= {wea[9]? dina[9] : item_entry[gv_item_reg][9],
                                      wea[8]? dina[8] : item_entry[gv_item_reg][8],
                                      wea[7]? dina[7] : item_entry[gv_item_reg][7],
                                      wea[6]? dina[6] : item_entry[gv_item_reg][6],
                                      wea[5]? dina[5] : item_entry[gv_item_reg][5],
                                      wea[4]? dina[4] : item_entry[gv_item_reg][4],
                                      wea[3]? dina[3] : item_entry[gv_item_reg][3],
                                      wea[2]? dina[2] : item_entry[gv_item_reg][2],
                                      wea[1]? dina[1] : item_entry[gv_item_reg][1],
                                      wea[0]? dina[0] : item_entry[gv_item_reg][0]};
        `endif
    end
  end
endgenerate

//DEBUG
wire [`D_LRUD_WIDTH-1:0] test_lrud_0   = item_entry[1];

endmodule

// ddata
module dcache_data_reg(
  input                     clka ,
  input                     rst  ,
  input                     ena  ,
  input  [`WSTRB_WIDTH-1:0] wea  ,
  input  [`D_INDEX_LEN-1:0] addra,
  input  [`GRLEN-1      :0] dina ,
  output [`GRLEN-1      :0] douta
);

reg [`GRLEN-1:0] item_entry [`D_SET_NUM-1:0];
reg [`GRLEN-1:0] item_rdata;
assign douta = item_rdata;

always @(posedge clka) begin
  if(rst)
    item_rdata <= {`GRLEN{1'b0}};
  else if(ena)
    item_rdata <= item_entry[addra];
end

genvar gv_item_reg;
generate
  for(gv_item_reg = 0; gv_item_reg < `D_SET_NUM; gv_item_reg = gv_item_reg + 1)
  begin : ddata_ram
    always @(posedge clka) begin
      if((|wea) && addra == gv_item_reg)
        item_entry[gv_item_reg] <= {
                                    `ifdef LA64
                                    (wea[7])? dina[63:56] : item_entry[gv_item_reg][63:56],
                                    (wea[6])? dina[55:48] : item_entry[gv_item_reg][55:48],
                                    (wea[5])? dina[47:40] : item_entry[gv_item_reg][47:40],
                                    (wea[4])? dina[39:32] : item_entry[gv_item_reg][39:32],
                                    `endif
                                    (wea[3])? dina[31:24] : item_entry[gv_item_reg][31:24],
                                    (wea[2])? dina[23:16] : item_entry[gv_item_reg][23:16],
                                    (wea[1])? dina[15: 8] : item_entry[gv_item_reg][15: 8],
                                    (wea[0])? dina[ 7: 0] : item_entry[gv_item_reg][ 7: 0]};
    end
  end
endgenerate

//DEBUG
wire [`GRLEN-1:0] test_data_0   = item_entry[1];

endmodule
`endif
