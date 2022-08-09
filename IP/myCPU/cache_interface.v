`include "common.vh"

module cache_interface
(
    input                      clk            ,
    input                      resetn         ,

    input [31:0] test_pc,

    // icache
    input                      i_rd_req       ,
    input  [`PABITS-1      :0] i_rd_addr      ,
    input  [  3            :0] i_rd_arcmd     ,
    input                      i_rd_uncache   ,
    output                     i_rd_ready     ,
    output                     i_ret_valid    ,
    output                     i_ret_last     ,
    output [63             :0] i_ret_data     ,
    output [`STATE_LEN-1:0] i_ret_rstate   ,
    output [`SCWAY_LEN-1:0] i_ret_rscway   ,

    input                       i_wr_req      ,
    input  [`PABITS-1       :0] i_wr_addr     ,
    input  [`I_LINE_SIZE_b-1:0] i_wr_data     ,
    input  [3               :0] i_wr_awcmd    ,
    input  [1               :0] i_wr_awstate  ,
    input  [3               :0] i_wr_awdirqid ,
    input  [3               :0] i_wr_awscway  ,
    input  [1               :0] i_wr_pgcl     ,
    input  [`WR_FMT_LEN-1:0] i_wr_fmt      ,
    output                      i_wr_ready    ,

    output                     i_ex_req       ,
    output [ 2             :0] i_ex_req_op    ,
    output [`PABITS-1      :0] i_ex_req_paddr ,
    output [9              :0] i_ex_req_cpuno ,
    output [1              :0] i_ex_req_pgcl  ,
    output [3              :0] i_ex_req_dirqid,
    input                      i_ex_req_recv  ,

    // dcache
    input                      d_rd_req       ,
    input  [`PABITS-1      :0] d_rd_addr      ,
    input  [             3 :0] d_rd_id        ,
    input  [             3 :0] d_rd_arcmd     ,
    input                      d_rd_uncache   ,
    output                     d_rd_ready     ,
    output                     d_ret_valid    ,
    output                     d_ret_last     ,
    output [63             :0] d_ret_data     ,
    output [  3            :0] d_ret_rid      ,
    output [`STATE_LEN-1:0] d_ret_rstate   ,
    output [`SCWAY_LEN-1:0] d_ret_rscway   ,

    input                       d_wr_req      ,
    input  [`PABITS-1       :0] d_wr_addr     ,
    input  [`D_LINE_SIZE_b-1:0] d_wr_data     ,
    input  [3               :0] d_wr_awcmd    ,
    input  [1               :0] d_wr_awstate  ,
    input  [3               :0] d_wr_awdirqid ,
    input  [3               :0] d_wr_awscway  ,
    input  [1               :0] d_wr_pgcl     ,
    input  [`WR_FMT_LEN-1   :0] d_wr_fmt      ,
    input  [`WSTRB_WIDTH-1  :0] d_wr_uc_wstrb ,
    output                      d_wr_ready    ,
    output                      vic_not_full  ,
    output                      vic_empty     ,

    output                    d_ex_req        ,
    output [ 2            :0] d_ex_req_op     ,
    output [`PABITS-1     :0] d_ex_req_paddr  ,
    output [9             :0] d_ex_req_cpuno  ,
    output [1             :0] d_ex_req_pgcl   ,
    output [3             :0] d_ex_req_dirqid ,
    input                     d_ex_req_recv   ,

    // inv
    input                     inv_req   ,
    input  [`PABITS-1     :0] inv_addr  ,

    //  axi_control
    //ar
    output                    arvalid ,
    input                     arready ,
    output [             3:0] arid    ,
    output [`PABITS-1     :0] araddr  ,
    output [             7:0] arlen   ,
    output [             2:0] arsize  ,
    output [             1:0] arburst ,
    output [             1:0] arlock  ,
    output [             3:0] arcache ,
    output [             2:0] arprot  ,
    output [             3:0] arcmd   ,
    output [             9:0] arcpuno ,
    //r
    input                     rrequest,
    input  [             3:0] rid     ,
    input  [            63:0] rdata   ,
    input  [             1:0] rstate  ,
    input  [             3:0] rscway  ,
    input  [             1:0] rresp   ,
    input                     rlast   ,
    input                     rvalid  ,
    output                    rready  ,
    //aw
    output [             3:0] awcmd   ,
    output [             1:0] awstate ,
    output [             3:0] awdirqid,
    output [             3:0] awscway ,
    output [             3:0] awid    ,
    output [`PABITS-1     :0] awaddr  ,
    output [             7:0] awlen   ,
    output [             2:0] awsize  ,
    output [             1:0] awburst ,
    output [             1:0] awlock  ,
    output [             3:0] awcache ,
    output [             2:0] awprot  ,
    output                    awvalid ,
    input                     awready ,
    //w
    output [             3:0] wid     ,
    output [            63:0] wdata   ,
    output [             7:0] wstrb   ,
    output                    wlast   ,
    output                    wvalid  ,
    input                     wready  ,
    //b
    input  [             3:0] bid     ,
    input  [             1:0] bresp   ,
    input                     bvalid  ,
    output                    bready
);

// TODO
reg [31:0] test_counter1;
reg [31:0] pc_record1;

always @(posedge clk) begin
  if(!resetn)
    test_counter1 <= 32'b0;
  else if(awvalid && awready && awaddr == 32'h00000040) begin
    test_counter1 <= test_counter1 + 32'd1;
    pc_record1    <= test_pc;
  end
end


reg [31:0] test_counter2;
reg [31:0] pc_record2;
always @(posedge clk) begin
  if(!resetn)
    test_counter2 <= 32'b0;
  else if(awvalid && awready && awaddr == 32'h0efc8020) begin
    test_counter2 <= test_counter2 + 32'd1;
    pc_record2    <= test_pc;
  end
end

//wire test_finish;

wire rst;
assign rst = !resetn;

// axi bus
  // ar
reg                    arvalid_reg;
reg [             3:0] arid_reg   ;
reg [`PABITS-1     :0] araddr_reg ;
reg [             7:0] arlen_reg  ;
reg [             2:0] arsize_reg ;
reg [             1:0] arburst_reg;
reg [             1:0] arlock_reg ;
reg [             3:0] arcache_reg;
reg [             2:0] arprot_reg ;
reg [             3:0] arcmd_reg  ;
reg [             9:0] arcpuno_reg;

  // r
reg [  3:0] rid_reg;
reg         rrequest_reg;
reg [ 63:0] rdata_reg;
reg [  1:0] rstate_reg;
reg [  3:0] rscway_reg;
reg         rlast_reg;
reg         rvalid_reg;

reg [  3:0] bid_reg   ;
reg         bvalid_reg;


wire d_scread_req;

/* ----------------------- axi reg ----------------------- */
always @(posedge clk) begin
  if(!rvalid) begin
    rvalid_reg   <= 1'b0;
    rlast_reg    <= 1'b0;
    rrequest_reg <= 1'b0;
  end
  else if(rvalid) begin
    rid_reg      <= rid  ;
    rrequest_reg <= rrequest;
    rdata_reg    <= rdata;
    rstate_reg   <= rstate;
    rscway_reg   <= rscway;
    rlast_reg    <= rlast;
    rvalid_reg   <= 1'b1 ;
  end
end

always @(posedge clk) begin // TODO:
    bid_reg    <= bid   ;
    bvalid_reg <= bvalid;
end
/* ------------------------- END ------------------------- */



// -------------------- victim buffer ---------------------
reg  [`VIC_ITEM_NUM-1  :0] vic_valid; //TODO: VIC_STATE
reg  [`PABITS-1        :0] vic_paddr   [`VIC_ITEM_NUM-1:0];
reg  [`D_LINE_SIZE_b-1 :0] vic_data    [`VIC_ITEM_NUM-1:0];
reg  [3                :0] vic_awcmd   [`VIC_ITEM_NUM-1:0];
reg  [1                :0] vic_awstate [`VIC_ITEM_NUM-1:0];
reg  [3                :0] vic_awdirqid[`VIC_ITEM_NUM-1:0];
reg  [3                :0] vic_awscway [`VIC_ITEM_NUM-1:0];
reg  [1                :0] vic_pgcl    [`VIC_ITEM_NUM-1:0];
reg  [`WR_FMT_LEN-1 :0] vic_wr_fmt  [`VIC_ITEM_NUM-1:0];
reg                        vic_from_i  [`VIC_ITEM_NUM-1:0];
reg  [`WSTRB_WIDTH-1   :0] vic_uc_wstrb[`VIC_ITEM_NUM-1:0];
reg  [`VIC_RECORD_LEN-1:0] vic_record;

wire [`BUS_DATA_WIDTH-1:0] vic_data_array [`VIC_RECORD_LEN-1:0];

wire                     vic_push;
wire                     vic_pop;
reg  [`VIC_ITEM_BIT-1:0] vic_pop_p;
reg  [`VIC_ITEM_BIT-1:0] vic_push_p;

wire [`VIC_ITEM_NUM-1:0] vic_hit;
wire                     vic_vacancy;

assign vic_push      = (d_wr_req || i_wr_req) && vic_vacancy;
assign vic_pop       = bvalid_reg && bid_reg == 4'b1111;

always @(posedge clk) begin
  if(rst)			
    vic_pop_p <= {`VIC_ITEM_BIT{1'b0}};
  else if(vic_pop)
    vic_pop_p <= vic_pop_p + 1'd1;
end

always @(posedge clk) begin
  if(rst)
  	vic_push_p <= {`VIC_ITEM_BIT{1'b0}};
  else if(vic_push)
    vic_push_p <= vic_push_p + 1'd1;
end

genvar gv_vic;
generate
  for(gv_vic = 0; gv_vic < `VIC_ITEM_NUM; gv_vic = gv_vic + 1)
  begin: vic_buff

    always @(posedge clk) begin
      if(rst)
        vic_valid[gv_vic] <= 1'b0;
      else if(vic_push && vic_push_p == gv_vic)
        vic_valid[gv_vic] <= 1'b1;
      else if(vic_pop  && vic_pop_p  == gv_vic)
        vic_valid[gv_vic] <= 1'b0;
    end

    always @(posedge clk) begin
      if(vic_push && vic_push_p == gv_vic) begin
        vic_paddr   [gv_vic] <= (d_wr_req)? d_wr_addr     : i_wr_addr           ;
        vic_awcmd   [gv_vic] <= (d_wr_req)? d_wr_awcmd    : i_wr_awcmd          ;
        vic_awstate [gv_vic] <= (d_wr_req)? d_wr_awstate  : i_wr_awstate        ;
        vic_awdirqid[gv_vic] <= (d_wr_req)? d_wr_awdirqid : i_wr_awdirqid       ;
        vic_awscway [gv_vic] <= (d_wr_req)? d_wr_awscway  : i_wr_awscway        ;
        vic_pgcl    [gv_vic] <= (d_wr_req)? d_wr_pgcl     : i_wr_pgcl           ;
        vic_wr_fmt  [gv_vic] <= (d_wr_req)? d_wr_fmt      : i_wr_fmt            ;
        vic_uc_wstrb[gv_vic] <= (d_wr_req)? d_wr_uc_wstrb : {`WSTRB_WIDTH{1'b0}};
        vic_from_i  [gv_vic] <= !d_wr_req;
        vic_data    [gv_vic] <= d_wr_data;
      end
    end

    // todo: i_rd_req?
    // TODO: what if d_req hit vic?
    assign vic_hit[gv_vic] = vic_valid[gv_vic] && 
                             vic_paddr[gv_vic][`PABITS-1:`I_OFFSET_LEN + 2] == d_rd_addr[`PABITS-1:`I_OFFSET_LEN + 2];
  end
endgenerate

always @(posedge clk) begin
  if(rst || vic_pop)
    vic_record <= {`VIC_RECORD_LEN{1'b0}};
  else if(wready && wvalid && wid == 4'b1111) begin
    vic_record[3] <= vic_record[2]? 1'b1 : 1'b0;
    vic_record[2] <= vic_record[1]? 1'b1 : 1'b0;
    vic_record[1] <= vic_record[0]? 1'b1 : 1'b0;
    vic_record[0] <=                1'b1       ;
  end
end

reg  vic_data_all_recv;
always @(posedge clk) begin
  if(rst)
    vic_data_all_recv <= 1'b0;
  else if(wlast && wready && wvalid && wid == 4'b1111)
    vic_data_all_recv <= 1'b1;
  else if(vic_pop)
    vic_data_all_recv <= 1'b0;
end

reg  vic_addr_arrived;
always @(posedge clk) begin
  if(rst)
    vic_addr_arrived <= 1'b0;
  else if(awvalid && awready && awid == 4'b1111)
    vic_addr_arrived <= 1'b1;
  else if(vic_pop)
    vic_addr_arrived <= 1'b0;
end

`ifdef VIC_ITEM2
  assign vic_not_full = vic_valid == 2'b00 || (vic_valid == 2'b01 || vic_valid == 2'b10) /*&& !(d_wr_req || i_wr_req)*/; // TODO !!!!!!
  assign vic_vacancy  = !(&vic_valid) || (&vic_valid) && vic_pop;
  assign vic_empty    = vic_valid == 2'b00;
`endif

`ifdef LA64
  assign vic_data_array[0] = vic_data[vic_pop_p][127:  0];
  assign vic_data_array[1] = vic_data[vic_pop_p][255:128];
  assign vic_data_array[2] = vic_data[vic_pop_p][383:256];
  assign vic_data_array[3] = vic_data[vic_pop_p][511:384];
`elsif LA32
  assign vic_data_array[0] = vic_data[vic_pop_p][ 63:  0];
  assign vic_data_array[1] = vic_data[vic_pop_p][127: 64];
  assign vic_data_array[2] = vic_data[vic_pop_p][191:128];
  assign vic_data_array[3] = vic_data[vic_pop_p][255:192];
`endif
// ------------------------- END --------------------------



// ---------------------- i/d cache -----------------------
  // icache
assign i_rd_ready  = i_rd_req && arready && !d_scread_req;

// TODO:
assign i_ret_valid = (rvalid_reg && (rid_reg == 4'b0111 || rid_reg == 4'b1001));

assign i_ret_last  = (rvalid_reg && rid_reg == 4'b0111)?  rlast_reg:
                     (rvalid_reg && rid_reg == 4'b1001)?  1'b1     :
                                                          1'b0     ;

assign i_ret_data  = (rvalid_reg && rid_reg == 4'b0111)?  rdata_reg: // TODO:
                     /*(rvalid_reg && rid_reg == 4'b1001)?*/  rdata_reg;

assign i_wr_ready  = vic_vacancy && !d_wr_req;

// TODO:
assign i_ret_rstate = 2'b01;
assign i_ret_rscway = 4'b0000;

  // dcache
assign d_wr_ready = vic_vacancy;

assign d_rd_ready  = d_scread_req && arready;

// TODO TEST
assign d_ret_valid = /*test_finish? 1'b0 : */(rvalid_reg && rid_reg[3:2] == 2'b00);
                     
assign d_ret_last  = (rvalid_reg && rid_reg[3:2] == 2'b00)?  rlast_reg     :
                                                             1'b0          ;

assign d_ret_data  = /*(rvalid_reg && rid_reg[3:2] == 2'b00)?*/ rdata_reg; // TODO

assign d_ret_rid   = /*(rvalid_reg && rid_reg[3:2] == 2'b00)?*/  rid_reg; // TODO
// TODO:
assign d_ret_rstate = 2'b01;
assign d_ret_rscway = 4'b0000;
// ------------------------- END --------------------------



// ------------------------- AXI --------------------------
assign d_scread_req = d_rd_req && !(|vic_hit);
  // ar
assign arvalid  = i_rd_req || d_scread_req;

// data    : 4'b00**
// inst    : 4'b0111
// uncache : d: 4'b1000   i: 4'b1001
// prefetch: d: 4'b11**   i: 4'b010*
assign arid     = (d_scread_req)? d_rd_id :
                                  4'b0111 ;

assign araddr   = (d_scread_req)? d_rd_addr:
                                  i_rd_addr;

assign arlen    = (d_scread_req)? (d_rd_uncache? 8'b0000 : 8'b0011):
                                  (i_rd_uncache? 8'b0000 : 8'b0011);

`ifdef LA64
  assign arsize   = (d_scread_req && d_rd_uncache)? 3'b100:
                    (i_rd_req     && i_rd_uncache)? 3'b010:
                                                    3'b100;
`elsif LA32
  assign arsize   = (d_scread_req && d_rd_uncache)? 3'b010:
                    (i_rd_req     && i_rd_uncache)? 3'b010:
                                                    3'b011;
`endif

assign arburst  = 2'b01;
assign arlock   = 2'b00;
assign arcache  = 4'b0000;
assign arprot   = (d_scread_req)?  3'b000:
                                   3'b100;
// TODO:
assign arcmd   = (d_scread_req)?  d_rd_arcmd:
                                  i_rd_arcmd;
assign arcpuno = 10'b0;

  // r
assign rready   = 1'b1; // TODO

  // aw
assign awcmd    = vic_awcmd[vic_pop_p];
//2'b00-Invalid
//2'b01-Shared
//2'b10-Exclusive
//2'b11-Dirty
assign awstate  = vic_awstate [vic_pop_p];
assign awdirqid = vic_awdirqid[vic_pop_p];
assign awscway  = vic_awscway [vic_pop_p];

assign awid     = 4'b1111;

assign awaddr   =  vic_paddr[vic_pop_p];
assign awlen    = (vic_wr_fmt[vic_pop_p] == `WR_FMT_ALLLINE)?  8'b011 : 8'b000;

`ifdef LA64
  assign awsize   = (vic_wr_fmt[vic_pop_p] == `WR_FMT_ALLLINE)?  3'b011 : 3'b000;
`elsif LA32
  assign awsize   = (vic_wr_fmt[vic_pop_p] == `WR_FMT_ALLLINE)?  3'b011 : 3'b000;
`endif

assign awburst  = 2'b01;
assign awlock   = vic_pgcl[vic_pop_p];
assign awcache  = 4'b0000;
assign awprot   = {2'b00, vic_from_i[vic_pop_p]};
assign awvalid  = vic_valid[vic_pop_p] && !vic_addr_arrived;

  // w
assign wid      = 4'b1111;

`ifdef LA64
  assign wdata    = ({128{!vic_record[0]                }} & vic_data_array[0]) |
                    ({128{!vic_record[1] & vic_record[0]}} & vic_data_array[1]) |
                    ({128{!vic_record[2] & vic_record[1]}} & vic_data_array[2]) |
                    ({128{!vic_record[3] & vic_record[2]}} & vic_data_array[3]) ;

  assign wstrb    = (vic_wr_fmt[vic_pop_p] == `WR_FMT_UNCACHE)?  {{8{ vic_paddr[vic_pop_p][3]}} & vic_uc_wstrb[vic_pop_p], 
                                                                  {8{!vic_paddr[vic_pop_p][3]}} & vic_uc_wstrb[vic_pop_p]}:
                                                                  16'b1111_1111_1111_1111;
`elsif LA32
  assign wdata    = ({64{!vic_record[0]                }} & vic_data_array[0]) |
                    ({64{!vic_record[1] & vic_record[0]}} & vic_data_array[1]) |
                    ({64{!vic_record[2] & vic_record[1]}} & vic_data_array[2]) |
                    ({64{!vic_record[3] & vic_record[2]}} & vic_data_array[3]) ;
  assign wstrb    = (vic_wr_fmt[vic_pop_p] == `WR_FMT_UNCACHE)?  {{4{vic_paddr[vic_pop_p][2] == 1'b1}} & vic_uc_wstrb[vic_pop_p], 
                                                                  {4{vic_paddr[vic_pop_p][2] == 1'b0}} & vic_uc_wstrb[vic_pop_p]}:
                                                                  8'b1111_1111;
`endif

assign wlast    = vic_valid[vic_pop_p] && vic_wr_fmt[vic_pop_p] == `WR_FMT_ALLLINE && vic_record == 4'b0111|| 
                  vic_valid[vic_pop_p] && vic_wr_fmt[vic_pop_p] == `WR_FMT_UNCACHE                         ||
                  vic_valid[vic_pop_p] && vic_wr_fmt[vic_pop_p] == `WR_FMT_EXTINV                          ;

assign wvalid   = vic_valid[vic_pop_p] && !vic_data_all_recv;

  // b
assign bready   = 1'b1;
// ------------------------- END --------------------------



// ----------------------- Ex Req -------------------------
// TODO:
assign d_ex_req               = 1'b0;//rrequest_reg && !rdata_reg[64];
assign d_ex_req_op[`INV_WTBK] = 1'b0;//rdata_reg[68:65] == 4'b1000;
assign d_ex_req_op[`WTBK]     = 1'b0;//rdata_reg[68:65] == 4'b1001;
assign d_ex_req_op[`INV]      = 1'b0;//rdata_reg[68:65] == 4'b1010;
assign d_ex_req_paddr         = {`PABITS{1'b0}};//rdata_reg[`PABITS-1:0];
assign d_ex_req_cpuno         = 10'b0;//rdata_reg[78:69];
assign d_ex_req_pgcl          = 2'b0;//rdata_reg[80:79];
assign d_ex_req_dirqid        = 4'b0;//rid_reg[3:0];
// TODO:
assign i_ex_req               = 1'b0;//rrequest_reg &&  rdata_reg[64];
assign i_ex_req_op[`INV_WTBK] = 1'b0;//rdata_reg[68:65] == 4'b1000;
assign i_ex_req_op[`WTBK]     = 1'b0;//rdata_reg[68:65] == 4'b1001;
assign i_ex_req_op[`INV]      = 1'b0;//rdata_reg[68:65] == 4'b1010;
assign i_ex_req_paddr         = {`PABITS{1'b0}};//rdata_reg[`PABITS-1:0];
assign i_ex_req_cpuno         = 10'b0;//rdata_reg[78:69];
assign i_ex_req_pgcl          = 2'b0;//rdata_reg[80:79];
assign i_ex_req_dirqid        = 4'b0;//rid_reg[3:0];
// ------------------------- END --------------------------

// TEST
//wire start = vic_valid[0] == 1'b1 && vic_paddr[0] == 32'h3fb9b000 && vic_data[0][127:96] == 32'hffffffff ||
//             vic_valid[1] == 1'b1 && vic_paddr[1] == 32'h3fb9b000 && vic_data[1][127:96] == 32'hffffffff ;
//
//reg test_trigger;
//always @(posedge clk) begin
//  if(rst)
//    test_trigger <= 1'b0;
//  else if(start)
//    test_trigger <= 1'b1;
//end
//
//reg record;
//always @(posedge clk) begin
//  if(rst)
//    record <= 1'b0;
//  else if(test_finish)
//    record <= 1'b1;
//end
//
//assign test_finish = test_trigger &&
//                  (vic_valid[0] == 1'b1 && vic_paddr[0] == 32'h3fb9b000 && vic_data[0][127:96] != 32'hffffffff ||
//                   vic_valid[1] == 1'b1 && vic_paddr[1] == 32'h3fb9b000 && vic_data[1][127:96] != 32'hffffffff );
endmodule
