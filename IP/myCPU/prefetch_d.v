`include "cache.vh"

module prefetch_d
#(
    parameter  WAY_NUM    =  `PRE_WAY_NUM     ,
    parameter  LINE_LEN   =  `D_LINE_LEN      ,
    parameter  REQ_Q_LEN  =  `PRE_REQ_QLEN    ,

    parameter  PC_LEN     =  `PRE_PC_REF_LEN  ,
    parameter  ENTRY_IDX  =  `PRE_PC_INDEX_LEN,
    parameter  ENTRY_NUM  = (1 << ENTRY_IDX  ),
    parameter  TAG_LEN    = (PC_LEN-ENTRY_IDX),
    parameter  STRIDE_LEN =  `PRE_STRIDE_LEN
)
(
    input                    clk           ,
    input                    resetn        ,

    input                    load_ref      ,

    input      [PC_LEN-1 :0] cur_pc        ,
    input      [`PABITS-1:0] cur_paddr     ,
    input      [1        :0] cur_page_color,

    input                    prefetch_recv ,
    output                   prefetch_req  ,
    output     [1        :0] prefetch_pgcl ,
    output     [`PABITS-1:0] prefetch_paddr
);
wire rst;
assign rst = !resetn;

// todo: prefetch in the same page
// todo: add prefetch req queue

localparam IDLE   = 2'b00;
localparam FIRST  = 2'b01;
localparam SECOND = 2'b10;
localparam STEADY = 2'b11;

wire [WAY_NUM-1   :0] pre_way_hit    ;
wire [1           :0] pre_way_state  [WAY_NUM-1:0];
wire [`PABITS-1-LINE_LEN:0] pre_way_paddr  [WAY_NUM-1:0];
wire [STRIDE_LEN-1:0] pre_way_stride [WAY_NUM-1:0];

wire [ENTRY_IDX-1   :0] wr_index  ;
wire [WAY_NUM-1     :0] state_we  ;
wire [WAY_NUM-1     :0] pc_we     ;
wire [WAY_NUM-1     :0] paddr_we  ;
wire [WAY_NUM-1     :0] stride_we ;
wire [1             :0] state_w   ;
wire [TAG_LEN-1     :0] pc_w      ;
wire [`PABITS-1-LINE_LEN:0] paddr_w   ;
wire [STRIDE_LEN-1  :0] stride_w  ;
wire [WAY_NUM-1     :0] wr_flag   ;
wire [WAY_NUM-1     :0] rplc_flag ;

wire                    pre_hit   ;
wire [1             :0] his_state ;
wire [`PABITS-1-LINE_LEN:0] his_paddr ;
wire [STRIDE_LEN-1  :0] his_stride;
wire [`PABITS-1-LINE_LEN:0] cur_stride ;
wire [STRIDE_LEN-1  :0] real_stride;
wire                    prefetch_trigger;
wire                    same_line;
wire                    same_page;
wire [`PABITS-1-LINE_LEN:0] push_paddr;

wire [ENTRY_IDX-1:0] lru_r_index;
wire [5          :0] lru_r_data ;
wire                 lru_wen    ;
wire [ENTRY_IDX-1:0] lru_w_index;
wire [5          :0] lru_w_data ;

   // uty: test
//assign same_page   = push_paddr[`PABITS-1:12] == cur_paddr[`PABITS-1:12];
assign same_page   = push_paddr[`PABITS-1-LINE_LEN:12] == cur_paddr[`PABITS-1:12];
assign same_line   = cur_paddr[`PABITS-1:LINE_LEN] == his_paddr;
assign cur_stride  = cur_paddr[`PABITS-1:LINE_LEN] -  his_paddr;
assign real_stride = (  &cur_stride[`PABITS-1-LINE_LEN:STRIDE_LEN] ||
                      &(~cur_stride[`PABITS-1-LINE_LEN:STRIDE_LEN] ))? cur_stride[STRIDE_LEN-1:0] :
                                                                      {STRIDE_LEN{1'b0}};

assign prefetch_trigger = load_ref && his_state == STEADY && real_stride == his_stride && !same_line && same_page;


assign push_paddr = {cur_paddr[`PABITS-1:LINE_LEN] + {{`PABITS-STRIDE_LEN-LINE_LEN-1{his_stride[STRIDE_LEN-1]}}, his_stride[STRIDE_LEN-2:0]}}; // todo:??

reg [2             :0] pre_q_head;
reg                    pre_q_valid [REQ_Q_LEN-1:0];
reg [1             :0] pre_q_pgcl  [REQ_Q_LEN-1:0];
reg [`PABITS-1-LINE_LEN:0] pre_q_paddr [REQ_Q_LEN-1:0];
wire [2:0] empty_entry;

assign prefetch_req   = pre_q_valid[pre_q_head];
assign prefetch_pgcl  = pre_q_pgcl [pre_q_head];
assign prefetch_paddr = {pre_q_paddr[pre_q_head], {LINE_LEN{1'b0}}};

always @(posedge clk) begin
  if(rst)
    pre_q_head <= 3'b0;
  else if(prefetch_recv)
    pre_q_head <= pre_q_head + 3'b1;
end

assign empty_entry = (!pre_q_valid[pre_q_head     ])? pre_q_head      :
                     (!pre_q_valid[pre_q_head+3'd1])? pre_q_head+3'd1 :
                     (!pre_q_valid[pre_q_head+3'd2])? pre_q_head+3'd2 :
                     (!pre_q_valid[pre_q_head+3'd3])? pre_q_head+3'd3 :
                     (!pre_q_valid[pre_q_head+3'd4])? pre_q_head+3'd4 :
                     (!pre_q_valid[pre_q_head+3'd5])? pre_q_head+3'd5 :
                     (!pre_q_valid[pre_q_head+3'd6])? pre_q_head+3'd6 :
                     (!pre_q_valid[pre_q_head+3'd7])? pre_q_head+3'd7 :
                                                      pre_q_head      ;

genvar gv_preq;
generate
  for(gv_preq = 0; gv_preq < REQ_Q_LEN; gv_preq = gv_preq + 1)
  begin : pre_q
    always @(posedge clk) begin
      if(rst)
        pre_q_valid[gv_preq] <= 1'b0;
      else if(prefetch_trigger && empty_entry == gv_preq)
        pre_q_valid[gv_preq] <= 1'b1;
      else if(prefetch_recv && pre_q_head == gv_preq)
        pre_q_valid[gv_preq] <= 1'b0;
    end


    always @(posedge clk) begin
      if(prefetch_trigger && empty_entry == gv_preq) begin
        pre_q_pgcl[gv_preq]  <= cur_page_color;
        pre_q_paddr[gv_preq] <= push_paddr;
      end
    end

  end
endgenerate


generate
  if(WAY_NUM == 4)
  begin
    assign pre_hit    = pre_way_hit[0] |
                        pre_way_hit[1] |
                        pre_way_hit[2] |
                        pre_way_hit[3] ;

    assign his_state  = {2{pre_way_hit[0]}} & pre_way_state[0] |
                        {2{pre_way_hit[1]}} & pre_way_state[1] |
                        {2{pre_way_hit[2]}} & pre_way_state[2] |
                        {2{pre_way_hit[3]}} & pre_way_state[3] ;

    assign his_paddr  = {`PABITS-LINE_LEN{pre_way_hit[0]}} & pre_way_paddr[0] |
                        {`PABITS-LINE_LEN{pre_way_hit[1]}} & pre_way_paddr[1] |
                        {`PABITS-LINE_LEN{pre_way_hit[2]}} & pre_way_paddr[2] |
                        {`PABITS-LINE_LEN{pre_way_hit[3]}} & pre_way_paddr[3] ;

    assign his_stride = {STRIDE_LEN{pre_way_hit[0]}} & pre_way_stride[0] |
                        {STRIDE_LEN{pre_way_hit[1]}} & pre_way_stride[1] |
                        {STRIDE_LEN{pre_way_hit[2]}} & pre_way_stride[2] |
                        {STRIDE_LEN{pre_way_hit[3]}} & pre_way_stride[3] ;

    assign state_we  = {4{load_ref && 
                         (his_state == IDLE                                              || // miss or real IDLE
                          his_state == FIRST  && !same_line                              ||
                          his_state == SECOND && !same_line                              ||
                          his_state == STEADY && !same_line && real_stride != his_stride)}} & wr_flag;

    assign pc_we     = {4{load_ref && his_state == IDLE}} & wr_flag;
    assign paddr_we  = {4{load_ref && !same_line       }} & wr_flag;
    assign stride_we = {4{load_ref && !same_line       }} & wr_flag;
  end
endgenerate

assign wr_flag   = (pre_hit)? pre_way_hit : rplc_flag;
assign wr_index  = cur_pc[ENTRY_IDX-1:0];
assign state_w   = (his_state   == IDLE                                  )?  FIRST  :
                   (his_state   == FIRST      && !same_line              )?  SECOND : // TODO: First goto IDLE?
                   (real_stride != his_stride && !same_line || 
                    real_stride == his_stride && !same_line && !same_page)?  IDLE   : STEADY;

assign pc_w      = cur_pc[PC_LEN-1:ENTRY_IDX];
assign paddr_w   = cur_paddr[`PABITS-1:LINE_LEN];
assign stride_w  = real_stride;

genvar gv_prefetch;
generate
  for (gv_prefetch = 0; gv_prefetch < WAY_NUM; gv_prefetch = gv_prefetch + 1) 
  begin: prefetch

    prefetch_his_table u_pre_his_table(
      .clk           (clk                        ),
      .resetn        (resetn                     ),
  
      .wr_index      (wr_index                   ),
      .state_we      (state_we [gv_prefetch]     ),
      .pc_we         (pc_we    [gv_prefetch]     ),
      .paddr_we      (paddr_we [gv_prefetch]     ),
      .stride_we     (stride_we[gv_prefetch]     ),
      .state_w       (state_w                    ),
      .pc_w          (pc_w                       ),
      .paddr_w       (paddr_w                    ),
      .stride_w      (stride_w                   ),

      .cur_pc        (cur_pc                     ),
      .hit           (pre_way_hit[gv_prefetch]   ),
      .hit_state     (pre_way_state[gv_prefetch] ),
      .hit_paddr     (pre_way_paddr[gv_prefetch] ),
      .hit_stride    (pre_way_stride[gv_prefetch])
    );

  end
endgenerate

assign lru_r_index = wr_index;

assign lru_wen     = load_ref && (!same_line && his_state != IDLE || his_state == IDLE);
assign lru_w_index = wr_index;

wire [5:0] lru_bit_mask;
wire [5:0] lru_wdata_tmp;

assign lru_bit_mask =  {6{wr_flag[0]}} & 6'b111000 |
                       {6{wr_flag[1]}} & 6'b100110 |
                       {6{wr_flag[2]}} & 6'b010101 |
                       {6{wr_flag[3]}} & 6'b001011 ;

assign lru_wdata_tmp  = {{3{wr_flag[0]}}, {2{wr_flag[1]}}, wr_flag[2]};
assign lru_w_data     = lru_bit_mask & lru_wdata_tmp | lru_r_data & ~lru_bit_mask;

 assign rplc_flag[0] = !lru_r_data[5] && !lru_r_data[4] && !lru_r_data[3];
 assign rplc_flag[1] =  lru_r_data[5] && !lru_r_data[2] && !lru_r_data[1];
 assign rplc_flag[2] =  lru_r_data[4] &&  lru_r_data[2] && !lru_r_data[0];
 assign rplc_flag[3] = !(!lru_r_data[5] && !lru_r_data[4] && !lru_r_data[3] ||
                          lru_r_data[5] && !lru_r_data[2] && !lru_r_data[1] ||
                          lru_r_data[4] &&  lru_r_data[2] && !lru_r_data[0] );

prefetch_lru u_prefetch_lru
(
  .clk       (clk        ),
  .resetn    (resetn     ),

  .r_index   (lru_r_index),
  .r_lru     (lru_r_data ),
  .w_en      (lru_wen    ),
  .w_index   (lru_w_index),
  .w_lru     (lru_w_data )
);

endmodule


module prefetch_his_table
#(
    parameter  PC_LEN     =  10,
    parameter  ENTRY_IDX  =   4,
    parameter  ENTRY_NUM  = (1 << ENTRY_IDX  ),
    parameter  TAG_LEN    = (PC_LEN-ENTRY_IDX),
    parameter  STRIDE_LEN =   5
)
(
    input                          clk       ,
    input                          resetn    ,

    input  [PC_LEN           -1:0] cur_pc    ,
    input                          state_we  ,
    input                          pc_we     ,
    input                          paddr_we  ,
    input                          stride_we ,
    
    input  [ENTRY_IDX-1        :0] wr_index  ,
    input  [1                  :0] state_w   ,
    input  [TAG_LEN-1          :0] pc_w      ,
    input  [`PABITS-7          :0] paddr_w   , 
    input  [STRIDE_LEN-1       :0] stride_w  ,

    output                         hit       ,
    output [1                  :0] hit_state ,
    output [`PABITS-7          :0] hit_paddr ,
    output [STRIDE_LEN-1       :0] hit_stride  
);
wire rst;
assign rst = !resetn;

wire [ENTRY_IDX-1:0] r_index;

reg  [1             :0] state      [ENTRY_NUM-1:0];
reg  [TAG_LEN-1     :0] pc_his     [ENTRY_NUM-1:0];
reg  [`PABITS-7     :0] paddr_his  [ENTRY_NUM-1:0];
reg  [STRIDE_LEN-1  :0] stride_his [ENTRY_NUM-1:0];


assign r_index    = cur_pc[ENTRY_IDX-1:0];
assign hit        = cur_pc[PC_LEN-1:ENTRY_IDX] == pc_his[r_index] && |state[r_index];
assign hit_state  = state[r_index];
assign hit_paddr  = paddr_his[r_index];
assign hit_stride = stride_his[r_index];

genvar gv_hit_table;
generate
  for(gv_hit_table = 0; gv_hit_table < ENTRY_NUM; gv_hit_table = gv_hit_table + 1)
  begin : prefetch_hit_table
    
    always @(posedge clk) begin
      if(rst)
        state[gv_hit_table] <= 2'b0;
      else if (state_we && gv_hit_table == wr_index)
        state[gv_hit_table] <= state_w;
    end

    always @(posedge clk) begin
      if(pc_we && gv_hit_table == wr_index)
        pc_his[gv_hit_table] <= pc_w;
    end

    always @(posedge clk) begin
      if(paddr_we && gv_hit_table == wr_index)
        paddr_his[gv_hit_table] <= paddr_w;
    end

    always @(posedge clk) begin
      if(stride_we && gv_hit_table == wr_index)
        stride_his[gv_hit_table] <= stride_w;
    end
  end
endgenerate

endmodule


module prefetch_lru
(
  input        clk    ,
  input        resetn ,
  input  [3:0] r_index,
  output [5:0] r_lru  ,

  input        w_en   ,
  input  [3:0] w_index,
  input  [5:0] w_lru
);
wire rst;
assign rst = !resetn;

reg [5:0] lru_record [15:0];

assign r_lru = lru_record[r_index];

genvar gv_prelru;
generate
  for(gv_prelru = 0; gv_prelru < 16; gv_prelru = gv_prelru + 1)
  begin : prelru

    always @(posedge clk) begin
      if(rst)
        lru_record[gv_prelru] <= 6'b0;
      else if(w_en && w_index == gv_prelru)
        lru_record[gv_prelru] <= w_lru;

    end
  end
endgenerate

endmodule
