`include "common.vh"


module core_top
(
    input         aclk,
    input         aresetn, 

    input  [7 :0] intrpt,

    //  axi_control
    //ar
    output [ 3:0] arid   ,
    output [31:0] araddr ,
    output [ 3:0] arlen  ,
    output [ 2:0] arsize ,
    output [ 1:0] arburst,
    output [ 1:0] arlock ,
    output [ 3:0] arcache,
    output [ 2:0] arprot ,
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
    output [ 3:0] awid   ,
    output [31:0] awaddr ,
    output [ 3:0] awlen  ,
    output [ 2:0] awsize ,
    output [ 1:0] awburst,
    output [ 1:0] awlock ,
    output [ 3:0] awcache,
    output [ 2:0] awprot ,
    output        awvalid,
    input         awready,
    //w
    output [ 3:0] wid    ,
    output [63:0] wdata  ,
    output [ 7:0] wstrb  ,
    output        wlast  ,
    output        wvalid ,
    input         wready ,
    //b
    input  [ 3:0] bid    ,
    input  [ 1:0] bresp  ,
    input         bvalid ,
    output        bready ,

    //debug interface
    output [`GRLEN-1:0] debug0_wb_pc      ,
    output              debug0_wb_rf_wen  ,
    output [4 :0]       debug0_wb_rf_wnum ,
    output [`GRLEN-1:0] debug0_wb_rf_wdata,
    
    output [`GRLEN-1:0] debug1_wb_pc      ,
    output              debug1_wb_rf_wen  ,
    output [4 :0]       debug1_wb_rf_wnum ,
    output [`GRLEN-1:0] debug1_wb_rf_wdata
);
// TODO
wire [ 3:0] arcmd   ;
wire [ 9:0] arcpuno ;
wire [ 3:0] awcmd   ;
wire [ 1:0] awstate ;
wire [ 3:0] awdirqid;
wire [ 3:0] awscway ;

wire icache_init_finish;
wire dcache_init_finish;

`LSOC1K_DECL_BHT_RAMS_T

// icache ram
wire [`I_WAY_NUM-1        :0] icache_tag_clk_en;
wire [`I_WAY_NUM-1        :0] icache_tag_en   ;
wire [`I_WAY_NUM-1        :0] icache_tag_wen  ;
wire [`I_INDEX_LEN-1   :0] icache_tag_addr ;
wire [`I_TAGARRAY_LEN-1   :0] icache_tag_wdata;
wire [`I_IO_TAG_LEN-1  :0] icache_tag_rdata;

wire                          icache_lru_clk_en;
wire                          icache_lru_en   ;
wire [`I_LRU_WIDTH-1      :0] icache_lru_wen  ;
wire [`I_INDEX_LEN-1   :0] icache_lru_addr ;
wire [`I_LRU_WIDTH-1      :0] icache_lru_wdata;
wire [`I_LRU_WIDTH-1      :0] icache_lru_rdata;

wire [`I_WAY_NUM-1        :0] icache_data_clk_en;
wire [`I_IO_EN_LEN-1   :0] icache_data_en   ;
wire [`I_WAY_NUM-1        :0] icache_data_wen  ;
wire [`I_INDEX_LEN-1   :0] icache_data_addr ;
wire [`I_IO_WDATA_LEN-1:0] icache_data_wdata;
wire [`I_IO_RDATA_LEN-1:0] icache_data_rdata;

// dcache ram
wire [`D_WAY_NUM-1         :0] dcache_tag_clk_en;
wire [`D_WAY_NUM-1         :0] dcache_tag_en   ;
wire [`D_WAY_NUM-1         :0] dcache_tag_wen  ;
wire [`D_INDEX_LEN-1    :0] dcache_tag_addr ;
wire [`D_TAGARRAY_LEN-1    :0] dcache_tag_wdata;
wire [`D_RAM_TAG_LEN-1  :0] dcache_tag_rdata;

wire                           dcache_lrud_clk_en;
wire                           dcache_lrud_en    ;
wire[`D_LRUD_WIDTH-1       :0] dcache_lrud_wen   ;
wire[`D_INDEX_LEN-1     :0] dcache_lrud_addr  ;
wire[`D_LRUD_WIDTH-1       :0] dcache_lrud_wdata ;
wire[`D_LRUD_WIDTH-1       :0] dcache_lrud_rdata ;

wire [`D_WAY_NUM-1         :0] dcache_data_clk_en   ;
wire [`D_RAM_EN_LEN-1   :0] dcache_data_en       ;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank0;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank1;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank2;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank3;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank4;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank5;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank6;
wire [`D_RAM_WEN_LEN-1  :0] dcache_data_wen_bank7;
wire [`D_RAM_ADDR_LEN-1 :0] dcache_data_addr     ;
wire [`D_RAM_WDATA_LEN-1:0] dcache_data_wdata    ;
wire [`D_RAM_RDATA_LEN-1:0] dcache_data_rdata    ;


wire cpu_clk;
wire cpu_aresetn;
wire ram_wrapper_clk;
wire ram_wrapper_aresetn;

assign cpu_clk = aclk;
assign cpu_aresetn = aresetn;

assign ram_wrapper_clk = aclk;
assign ram_wrapper_aresetn = aresetn;

wire [`PABITS-1:0] p_araddr;
wire [`PABITS-1:0] p_awaddr;
`ifdef LA64
  assign araddr = {24'b0, p_araddr};
  assign awaddr = {24'b0, p_awaddr};
`elsif LA32
  //assign araddr = {3'b0,p_araddr[28:0]};
  //assign awaddr = {3'b0,p_awaddr[28:0]};
  assign araddr = p_araddr[31:0];
  assign awaddr = p_awaddr[31:0];
`endif

mycpu_top cpu(
    .intrpt  (intrpt		 ),   //high active

    .aclk    (cpu_clk    ),
    .aresetn (cpu_aresetn),   //low active

    //axi
    //ar
    .arid    (arid       ),
    .araddr  (p_araddr   ), // 48  paddr length
    .arlen   (arlen      ),
    .arsize  (arsize     ),
    .arburst (arburst    ),
    .arlock  (arlock     ),
    .arcache (arcache    ),
    .arprot  (arprot     ),
    .arcmd   (arcmd      ),
    .arcpuno (arcpuno    ),
    .arvalid (arvalid    ),
    .arready (arready    ),
    //r
    .rid     (rid        ),
    .rdata   (rdata      ),
    .rresp   (rresp      ),
    .rlast   (rlast      ),
    .rvalid  (rvalid     ),
    .rready  (rready     ),
    //aw           
    .awcmd   (awcmd      ),
    .awstate (awstate    ),
    .awdirqid(awdirqid   ),
    .awscway (awscway    ),
    .awid    (awid       ),
    .awaddr  (p_awaddr   ), // 48  paddr length
    .awlen   (awlen      ), 
    .awsize  (awsize     ),
    .awburst (awburst    ),
    .awlock  (awlock     ),
    .awcache (awcache    ),
    .awprot  (awprot     ),
    .awvalid (awvalid    ),
    .awready (awready    ),
    //w          
    .wid     (wid        ),
    .wdata   (wdata      ),
    .wstrb   (wstrb      ),
    .wlast   (wlast      ),
    .wvalid  (wvalid     ),
    .wready  (wready     ),
    //b              
    .bid     (bid        ),
    .bresp   (bresp      ),
    .bvalid  (bvalid     ),
    .bready  (bready     ),

    `LSOC1K_CONN_BHT_RAMS,
    
    // icache ram
    .icache_init_finish       (icache_init_finish     ),

    .icache_tag_clk_en_o      (icache_tag_clk_en      ),
    .icache_tag_en_o          (icache_tag_en          ),
    .icache_tag_wen_o         (icache_tag_wen         ),
    .icache_tag_addr_o        (icache_tag_addr        ),
    .icache_tag_wdata_o       (icache_tag_wdata       ),
    .icache_tag_rdata_i       (icache_tag_rdata       ),

    .icache_lru_clk_en_o      (icache_lru_clk_en      ),
    .icache_lru_en_o          (icache_lru_en          ),
    .icache_lru_wen_o         (icache_lru_wen         ),
    .icache_lru_addr_o        (icache_lru_addr        ),
    .icache_lru_wdata_o       (icache_lru_wdata       ),
    .icache_lru_rdata_i       (icache_lru_rdata       ),

    .icache_data_clk_en_o     (icache_data_clk_en     ),
    .icache_data_en_o         (icache_data_en         ),
    .icache_data_wen_o        (icache_data_wen        ),
    .icache_data_addr_o       (icache_data_addr       ),
    .icache_data_wdata_o      (icache_data_wdata      ),
    .icache_data_rdata_i      (icache_data_rdata      ),

    // dcache ram
    .dcache_init_finish       (dcache_init_finish     ),

    .dcache_tag_clk_en_o      (dcache_tag_clk_en      ),
    .dcache_tag_en_o          (dcache_tag_en          ),
    .dcache_tag_wen_o         (dcache_tag_wen         ),
    .dcache_tag_addr_o        (dcache_tag_addr        ),
    .dcache_tag_wdata_o       (dcache_tag_wdata       ),
    .dcache_tag_rdata_i       (dcache_tag_rdata       ),

    .dcache_lrud_clk_en_o     (dcache_lrud_clk_en     ),
    .dcache_lrud_en_o         (dcache_lrud_en         ),
    .dcache_lrud_wen_o        (dcache_lrud_wen        ),
    .dcache_lrud_addr_o       (dcache_lrud_addr       ),
    .dcache_lrud_wdata_o      (dcache_lrud_wdata      ),
    .dcache_lrud_rdata_i      (dcache_lrud_rdata      ),

    .dcache_data_en_o         (dcache_data_en         ),
    .dcache_data_clk_en_o     (dcache_data_clk_en     ),
    .dcache_data_wen_bank0_o  (dcache_data_wen_bank0  ),
    .dcache_data_wen_bank1_o  (dcache_data_wen_bank1  ),
    .dcache_data_wen_bank2_o  (dcache_data_wen_bank2  ),
    .dcache_data_wen_bank3_o  (dcache_data_wen_bank3  ),
    .dcache_data_wen_bank4_o  (dcache_data_wen_bank4  ),
    .dcache_data_wen_bank5_o  (dcache_data_wen_bank5  ),
    .dcache_data_wen_bank6_o  (dcache_data_wen_bank6  ),
    .dcache_data_wen_bank7_o  (dcache_data_wen_bank7  ),
    .dcache_data_addr_o       (dcache_data_addr       ),
    .dcache_data_wdata_o      (dcache_data_wdata      ),
    .dcache_data_rdata_i      (dcache_data_rdata      ),

    //debug interface
    .debug0_wb_pc      (debug0_wb_pc      ),// O, 64 
    .debug0_wb_rf_wen  (debug0_wb_rf_wen  ),// O, 4  
    .debug0_wb_rf_wnum (debug0_wb_rf_wnum ),// O, 5  
    .debug0_wb_rf_wdata(debug0_wb_rf_wdata),// O, 64 
    .debug1_wb_pc      (debug1_wb_pc      ),// O, 64 
    .debug1_wb_rf_wen  (debug1_wb_rf_wen  ),// O, 4  
    .debug1_wb_rf_wnum (debug1_wb_rf_wnum ),// O, 5  
    .debug1_wb_rf_wdata(debug1_wb_rf_wdata) // O, 64 
);

ram_wrapper u_ram_wrapper
(
    .clk                      (ram_wrapper_clk        ),
    .resetn                   (ram_wrapper_aresetn    ),   //low active
    .icache_init_finish       (icache_init_finish     ),
    .dcache_init_finish       (dcache_init_finish     ),

    `LSOC1K_CONN_BHT_RAMS,

    // icache ram
    .icache_tag_clk_en        (icache_tag_clk_en      ),
    .icache_tag_en            (icache_tag_en          ),
    .icache_tag_wen           (icache_tag_wen         ),
    .icache_tag_addr          (icache_tag_addr        ),
    .icache_tag_wdata         (icache_tag_wdata       ),
    .icache_tag_rdata         (icache_tag_rdata       ),

    .icache_lru_clk_en        (icache_lru_clk_en      ),
    .icache_lru_en            (icache_lru_en          ),
    .icache_lru_wen           (icache_lru_wen         ),
    .icache_lru_addr          (icache_lru_addr        ),
    .icache_lru_wdata         (icache_lru_wdata       ),
    .icache_lru_rdata         (icache_lru_rdata       ),

    .icache_data_clk_en       (icache_data_clk_en     ),
    .icache_data_en           (icache_data_en         ),
    .icache_data_wen          (icache_data_wen        ),
    .icache_data_addr         (icache_data_addr       ),
    .icache_data_wdata        (icache_data_wdata      ),
    .icache_data_rdata        (icache_data_rdata      ),

    // dcache ram
    .dcache_tag_clk_en        (dcache_tag_clk_en      ),
    .dcache_tag_en            (dcache_tag_en          ),
    .dcache_tag_wen           (dcache_tag_wen         ),
    .dcache_tag_addr          (dcache_tag_addr        ),
    .dcache_tag_wdata         (dcache_tag_wdata       ),
    .dcache_tag_rdata         (dcache_tag_rdata       ),

    .dcache_lrud_clk_en       (dcache_lrud_clk_en     ),
    .dcache_lrud_en           (dcache_lrud_en         ),
    .dcache_lrud_wen          (dcache_lrud_wen        ),
    .dcache_lrud_addr         (dcache_lrud_addr       ),
    .dcache_lrud_wdata        (dcache_lrud_wdata      ),
    .dcache_lrud_rdata        (dcache_lrud_rdata      ),

    .dcache_data_clk_en       (dcache_data_clk_en     ),
    .dcache_data_en           (dcache_data_en         ),
    .dcache_data_wen_bank0    (dcache_data_wen_bank0  ),
    .dcache_data_wen_bank1    (dcache_data_wen_bank1  ),
    .dcache_data_wen_bank2    (dcache_data_wen_bank2  ),
    .dcache_data_wen_bank3    (dcache_data_wen_bank3  ),
    .dcache_data_wen_bank4    (dcache_data_wen_bank4  ),
    .dcache_data_wen_bank5    (dcache_data_wen_bank5  ),
    .dcache_data_wen_bank6    (dcache_data_wen_bank6  ),
    .dcache_data_wen_bank7    (dcache_data_wen_bank7  ),
    .dcache_data_addr         (dcache_data_addr       ),
    .dcache_data_wdata        (dcache_data_wdata      ),
    .dcache_data_rdata        (dcache_data_rdata      )
);

endmodule
