`define LSOC1K_BHT_TBL0_RAM_DEPTH 6
`define LSOC1K_BHT_TBL1_RAM_DEPTH 8
`define LSOC1K_BHT_TBL1_TAG_WIDTH 8
`define LSOC1K_DECL_BHT_RAMS_M \
    output wire [`LSOC1K_BHT_TBL0_RAM_DEPTH-1:0] bht_cnt0_hi_a    ,\
    output wire         bht_cnt0_hi_ce   ,\
    output wire         bht_cnt0_hi_en   ,\
    input  wire [16-1:0] bht_cnt0_hi_rd   ,\
    output wire [16-1:0] bht_cnt0_hi_wd   ,\
    output wire [16-1:0] bht_cnt0_hi_we   ,\
    output wire [`LSOC1K_BHT_TBL0_RAM_DEPTH-1:0] bht_cnt0_lo_a    ,\
    output wire         bht_cnt0_lo_ce   ,\
    output wire         bht_cnt0_lo_en   ,\
    input  wire [16-1:0] bht_cnt0_lo_rd   ,\
    output wire [16-1:0] bht_cnt0_lo_wd   ,\
    output wire [16-1:0] bht_cnt0_lo_we   ,\
    output wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_tag1_a       ,\
    output wire         bht_tag1_ce      ,\
    output wire         bht_tag1_en      ,\
    input  wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_rd      ,\
    output wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_wd      ,\
    output wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_we      ,\
    output wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_cnt1_hi_a    ,\
    output wire         bht_cnt1_hi_ce   ,\
    output wire         bht_cnt1_hi_en   ,\
    input  wire [4-1:0] bht_cnt1_hi_rd   ,\
    output wire [4-1:0] bht_cnt1_hi_wd   ,\
    output wire [4-1:0] bht_cnt1_hi_we   ,\
    output wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_cnt1_lo_a    ,\
    output wire         bht_cnt1_lo_ce   ,\
    output wire         bht_cnt1_lo_en   ,\
    input  wire [4-1:0] bht_cnt1_lo_rd   ,\
    output wire [4-1:0] bht_cnt1_lo_wd   ,\
    output wire [4-1:0] bht_cnt1_lo_we
`define LSOC1K_DECL_BHT_RAMS_T \
    wire [`LSOC1K_BHT_TBL0_RAM_DEPTH-1:0] bht_cnt0_hi_a ;\
    wire         bht_cnt0_hi_ce;\
    wire         bht_cnt0_hi_en;\
    wire [16-1:0] bht_cnt0_hi_rd;\
    wire [16-1:0] bht_cnt0_hi_wd;\
    wire [16-1:0] bht_cnt0_hi_we;\
    wire [`LSOC1K_BHT_TBL0_RAM_DEPTH-1:0] bht_cnt0_lo_a ;\
    wire         bht_cnt0_lo_ce;\
    wire         bht_cnt0_lo_en;\
    wire [16-1:0] bht_cnt0_lo_rd;\
    wire [16-1:0] bht_cnt0_lo_wd;\
    wire [16-1:0] bht_cnt0_lo_we;\
    wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_tag1_a    ;\
    wire         bht_tag1_ce   ;\
    wire         bht_tag1_en   ;\
    wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_rd   ;\
    wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_wd   ;\
    wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_we   ;\
    wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_cnt1_hi_a ;\
    wire         bht_cnt1_hi_ce;\
    wire         bht_cnt1_hi_en;\
    wire [4-1:0] bht_cnt1_hi_rd;\
    wire [4-1:0] bht_cnt1_hi_wd;\
    wire [4-1:0] bht_cnt1_hi_we;\
    wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_cnt1_lo_a ;\
    wire         bht_cnt1_lo_ce;\
    wire         bht_cnt1_lo_en;\
    wire [4-1:0] bht_cnt1_lo_rd;\
    wire [4-1:0] bht_cnt1_lo_wd;\
    wire [4-1:0] bht_cnt1_lo_we;
`define LSOC1K_DECL_BHT_RAMS_S \
    input  wire [`LSOC1K_BHT_TBL0_RAM_DEPTH-1:0] bht_cnt0_hi_a    ,\
    input  wire         bht_cnt0_hi_ce   ,\
    input  wire         bht_cnt0_hi_en   ,\
    output wire [16-1:0] bht_cnt0_hi_rd   ,\
    input  wire [16-1:0] bht_cnt0_hi_wd   ,\
    input  wire [16-1:0] bht_cnt0_hi_we   ,\
    input  wire [`LSOC1K_BHT_TBL0_RAM_DEPTH-1:0] bht_cnt0_lo_a    ,\
    input  wire         bht_cnt0_lo_ce   ,\
    input  wire         bht_cnt0_lo_en   ,\
    output wire [16-1:0] bht_cnt0_lo_rd   ,\
    input  wire [16-1:0] bht_cnt0_lo_wd   ,\
    input  wire [16-1:0] bht_cnt0_lo_we   ,\
    input  wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_tag1_a       ,\
    input  wire         bht_tag1_ce      ,\
    input  wire         bht_tag1_en      ,\
    output wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_rd      ,\
    input  wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_wd      ,\
    input  wire [4*`LSOC1K_BHT_TBL1_TAG_WIDTH-1:0] bht_tag1_we      ,\
    input  wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_cnt1_hi_a    ,\
    input  wire         bht_cnt1_hi_ce   ,\
    input  wire         bht_cnt1_hi_en   ,\
    output wire [4-1:0] bht_cnt1_hi_rd   ,\
    input  wire [4-1:0] bht_cnt1_hi_wd   ,\
    input  wire [4-1:0] bht_cnt1_hi_we   ,\
    input  wire [`LSOC1K_BHT_TBL1_RAM_DEPTH-1:0] bht_cnt1_lo_a    ,\
    input  wire         bht_cnt1_lo_ce   ,\
    input  wire         bht_cnt1_lo_en   ,\
    output wire [4-1:0] bht_cnt1_lo_rd   ,\
    input  wire [4-1:0] bht_cnt1_lo_wd   ,\
    input  wire [4-1:0] bht_cnt1_lo_we
`define LSOC1K_CONN_BHT_RAMS \
    .bht_cnt0_hi_a (bht_cnt0_hi_a ),\
    .bht_cnt0_hi_ce(bht_cnt0_hi_ce),\
    .bht_cnt0_hi_en(bht_cnt0_hi_en),\
    .bht_cnt0_hi_rd(bht_cnt0_hi_rd),\
    .bht_cnt0_hi_wd(bht_cnt0_hi_wd),\
    .bht_cnt0_hi_we(bht_cnt0_hi_we),\
    .bht_cnt0_lo_a (bht_cnt0_lo_a ),\
    .bht_cnt0_lo_ce(bht_cnt0_lo_ce),\
    .bht_cnt0_lo_en(bht_cnt0_lo_en),\
    .bht_cnt0_lo_rd(bht_cnt0_lo_rd),\
    .bht_cnt0_lo_wd(bht_cnt0_lo_wd),\
    .bht_cnt0_lo_we(bht_cnt0_lo_we),\
    .bht_tag1_a    (bht_tag1_a    ),\
    .bht_tag1_ce   (bht_tag1_ce   ),\
    .bht_tag1_en   (bht_tag1_en   ),\
    .bht_tag1_rd   (bht_tag1_rd   ),\
    .bht_tag1_wd   (bht_tag1_wd   ),\
    .bht_tag1_we   (bht_tag1_we   ),\
    .bht_cnt1_hi_a (bht_cnt1_hi_a ),\
    .bht_cnt1_hi_ce(bht_cnt1_hi_ce),\
    .bht_cnt1_hi_en(bht_cnt1_hi_en),\
    .bht_cnt1_hi_rd(bht_cnt1_hi_rd),\
    .bht_cnt1_hi_wd(bht_cnt1_hi_wd),\
    .bht_cnt1_hi_we(bht_cnt1_hi_we),\
    .bht_cnt1_lo_a (bht_cnt1_lo_a ),\
    .bht_cnt1_lo_ce(bht_cnt1_lo_ce),\
    .bht_cnt1_lo_en(bht_cnt1_lo_en),\
    .bht_cnt1_lo_rd(bht_cnt1_lo_rd),\
    .bht_cnt1_lo_wd(bht_cnt1_lo_wd),\
    .bht_cnt1_lo_we(bht_cnt1_lo_we)
`define LSOC1K_DECL_BHT_RAMS_CG \
    wire bht_cnt0_hi_clock;\
    wire bht_cnt0_lo_clock;\
    wire bht_tag1_clock   ;\
    wire bht_cnt1_hi_clock;\
    wire bht_cnt1_lo_clock;\
    cg_cell_wrap u_bht_cnt0_hi_cell_wrap  (.clock_in(clk), .enable(bht_cnt0_hi_ce), .test_enable(1'b0), .clock_out(bht_cnt0_hi_clock));\
    cg_cell_wrap u_bht_cnt0_lo_cell_wrap  (.clock_in(clk), .enable(bht_cnt0_lo_ce), .test_enable(1'b0), .clock_out(bht_cnt0_lo_clock));\
    cg_cell_wrap u_bht_tag1_cell_wrap     (.clock_in(clk), .enable(bht_tag1_ce   ), .test_enable(1'b0), .clock_out(bht_tag1_clock   ));\
    cg_cell_wrap u_bht_cnt1_hi_cell_wrap  (.clock_in(clk), .enable(bht_cnt1_hi_ce), .test_enable(1'b0), .clock_out(bht_cnt1_hi_clock));\
    cg_cell_wrap u_bht_cnt1_lo_cell_wrap  (.clock_in(clk), .enable(bht_cnt1_lo_ce), .test_enable(1'b0), .clock_out(bht_cnt1_lo_clock));

`define LSOC1K_DECL_BHT_RAMS_INS_REG \
bht_sp_reg#(.width(16),.depth(`LSOC1K_BHT_TBL0_RAM_DEPTH)) u_bht_cnt0_hi_reg(\
    .clka  (bht_cnt0_hi_clock),\
    .rst   (rst              ),\
    .ena   (bht_cnt0_hi_en   ),\
    .wea   (bht_cnt0_hi_we   ),\
    .addra (bht_cnt0_hi_a    ),\
    .dina  (bht_cnt0_hi_wd   ),\
    .douta (bht_cnt0_hi_rd   ));\
bht_sp_reg#(.width(16),.depth(`LSOC1K_BHT_TBL0_RAM_DEPTH)) u_bht_cnt0_lo_reg(\
    .clka  (bht_cnt0_lo_clock),\
    .rst   (rst              ),\
    .ena   (bht_cnt0_lo_en   ),\
    .wea   (bht_cnt0_lo_we   ),\
    .addra (bht_cnt0_lo_a    ),\
    .dina  (bht_cnt0_lo_wd   ),\
    .douta (bht_cnt0_lo_rd   ));\
bht_sp_reg#(.width(4*`LSOC1K_BHT_TBL1_TAG_WIDTH),.depth(`LSOC1K_BHT_TBL1_RAM_DEPTH)) u_bht_tag1_reg(\
    .clka  (bht_tag1_clock   ),\
    .rst   (rst              ),\
    .ena   (bht_tag1_en      ),\
    .wea   (bht_tag1_we      ),\
    .addra (bht_tag1_a       ),\
    .dina  (bht_tag1_wd      ),\
    .douta (bht_tag1_rd      ));\
bht_sp_reg#(.width(4),.depth(`LSOC1K_BHT_TBL1_RAM_DEPTH)) u_bht_cnt1_hi_reg(\
    .clka  (bht_cnt1_hi_clock),\
    .rst   (rst              ),\
    .ena   (bht_cnt1_hi_en   ),\
    .wea   (bht_cnt1_hi_we   ),\
    .addra (bht_cnt1_hi_a    ),\
    .dina  (bht_cnt1_hi_wd   ),\
    .douta (bht_cnt1_hi_rd   ));\
bht_sp_reg#(.width(4),.depth(`LSOC1K_BHT_TBL1_RAM_DEPTH)) u_bht_cnt1_lo_reg(\
    .clka  (bht_cnt1_lo_clock),\
    .rst   (rst             ),\
    .ena   (bht_cnt1_lo_en   ),\
    .wea   (bht_cnt1_lo_we   ),\
    .addra (bht_cnt1_lo_a    ),\
    .dina  (bht_cnt1_lo_wd   ),\
    .douta (bht_cnt1_lo_rd   ));
`define LSOC1K_DECL_BHT_RAMS_INS_RAM \
bht_cnt_bit_ram u_bht_cnt0_hi_ram(\
    .clka  (bht_cnt0_hi_clock),\
    .rst   (rst              ),\
    .ena   (bht_cnt0_hi_en   ),\
    .wea   (bht_cnt0_hi_we   ),\
    .addra (bht_cnt0_hi_a    ),\
    .dina  (bht_cnt0_hi_wd   ),\
    .douta (bht_cnt0_hi_rd   ));\
bht_cnt_bit_ram u_bht_cnt0_lo_ram(\
    .clka  (bht_cnt0_lo_clock),\
    .rst   (rst              ),\
    .ena   (bht_cnt0_lo_en   ),\
    .wea   (bht_cnt0_lo_we   ),\
    .addra (bht_cnt0_lo_a    ),\
    .dina  (bht_cnt0_lo_wd   ),\
    .douta (bht_cnt0_lo_rd   ));\
bht_tag_8_6_ram u_bht_tag1_ram(\
    .clka  (bht_tag1_clock   ),\
    .rst   (rst              ),\
    .ena   (bht_tag1_en      ),\
    .wea   (bht_tag1_we      ),\
    .addra (bht_tag1_a       ),\
    .dina  (bht_tag1_wd      ),\
    .douta (bht_tag1_rd      ));\
bht_cnt_bit_ram u_bht_cnt1_hi_ram(\
    .clka  (bht_cnt1_hi_clock),\
    .rst   (rst              ),\
    .ena   (bht_cnt1_hi_en   ),\
    .wea   (bht_cnt1_hi_we   ),\
    .addra (bht_cnt1_hi_a    ),\
    .dina  (bht_cnt1_hi_wd   ),\
    .douta (bht_cnt1_hi_rd   ));\
bht_cnt_bit_ram u_bht_cnt1_lo_ram(\
    .clka  (bht_cnt1_lo_clock),\
    .rst   (rst             ),\
    .ena   (bht_cnt1_lo_en   ),\
    .wea   (bht_cnt1_lo_we   ),\
    .addra (bht_cnt1_lo_a    ),\
    .dina  (bht_cnt1_lo_wd   ),\
    .douta (bht_cnt1_lo_rd   ));