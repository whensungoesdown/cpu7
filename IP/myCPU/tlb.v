`include "common.vh"

module tlb
#(
    parameter          IDXBITS = `TLB_IDXBITS,
    parameter          ENTRIES = `TLB_ENTRIES,

    parameter          GRLEN   = `GRLEN ,
    parameter          VABITS  = `VABITS,
    parameter          PABITS  = `PABITS,
    parameter          PFNBITS = `PFNBITS,
    parameter          VPNBITS = `VPNBITS
)
(
    input                clk        ,
    input                reset      ,
    input         [31:0] test_pc    ,


    // TLB entry search result
    input  [ 1:0]          csr_CRMD_PLV    ,
    input                  csr_CRMD_DA     ,
    input                  csr_CRMD_PG     ,
    input  [ 1:0]          csr_CRMD_DATF   ,
    input  [ 1:0]          csr_CRMD_DATM   ,
    input  [`GRLEN-1:0]    csr_dir_map_win0,
    input  [`GRLEN-1:0]    csr_dir_map_win1,
    input  [ 9:0]          csr_asid        ,

    input                   i_s_req       ,
    input  [GRLEN-1 :0]     i_s_vaddr     ,
    input                   i_s_cacop_req ,
    input                   i_s_cache_rcv ,
    output reg              i_s_finish_his,
    output reg [PABITS-1:0] i_s_paddr_his ,
//    output [PABITS-1:0]     i_s_paddr_uty ,
    output                  i_s_hit       ,
    output                  i_s_uncached  ,
    output     [ 5:0]       i_s_exccode   ,

    input                   d_s_req       ,
    input                   d_s_wr        ,
    input  [GRLEN-1 :0]     d_s_vaddr     ,
    input                   d_s_cache_rcv ,
    input                   d_s_no_trans  ,
    input                   d_s_p_pgcl    ,
    output reg              d_s_finish_his,
    output reg [PABITS-1:0] d_s_paddr_his ,
    output                  d_s_hit       ,
    output                  d_s_uncached  ,
    output     [ 5:0]       d_s_exccode   ,

    // TLBP
    input                    tlbp_req ,
    input  [ 9:0]            tlbp_asid,
    output                   tlbp_hit,
    output reg [IDXBITS-1:0] tlbp_idx,

    // TLBR
    input                    r_req,
    input  [IDXBITS-1    :0] r_idx,

    output reg [VPNBITS-1    :0] r_vpn2,
    output reg [9            :0] r_asid,
    output reg                   r_p   ,
    output reg                   r_g   ,
    output reg [5            :0] r_ps  ,
    output reg                   r_v0  ,
    output reg                   r_d0  ,
    output reg [1            :0] r_plv0,
    output reg [1            :0] r_mat0,
    output reg [PFNBITS-1    :0] r_pfn0,
    output reg                   r_v1  ,
    output reg                   r_d1  ,
    output reg [1            :0] r_plv1,
    output reg [1            :0] r_mat1,
    output reg [PFNBITS-1    :0] r_pfn1,

    // INVTLB
    input                inv_req   ,
    input  [4:0]         inv_op    ,
    input  [9:0]         inv_asid  ,
    input  [VPNBITS-1:0] inv_vpn2  ,

    // TLB entry write              
    input                w_en      ,
    input  [IDXBITS-1:0] w_idx     ,
    input  [VPNBITS-1:0] w_vpn2    ,
    input  [ 9:0]        w_asid    ,
    input                w_ps_4M   ,
    input                w_p       ,
    input                w_g       ,
    input                w_v0      ,
    input                w_d0      ,
    input  [1:0]         w_plv0    ,
    input  [1:0]         w_mat0    ,
    input  [PFNBITS-1:0] w_pfn0    ,
    input                w_v1      ,
    input                w_d1      ,
    input  [1:0]         w_plv1    ,
    input  [1:0]         w_mat1    ,
    input  [PFNBITS-1:0] w_pfn1     
);

/*reg test_flag1;
always @(posedge clk) begin 
  if(reset)
    test_flag1 <= 1'b0;
  else if(w_en && w_vpn2 == 19'h000c6)
    test_flag1 <= 1'b1;
end

reg test_flag2;
always @(posedge clk) begin 
  if(reset)
    test_flag2 <= 1'b0;
  else if(w_en && w_pfn0 == 24'h617272)
    test_flag2 <= 1'b1;
end

reg test_flag3;
always @(posedge clk) begin 
  if(reset)
    test_flag3 <= 1'b0;
  else if(w_en && w_pfn1 == 24'h662e00)
    test_flag3 <= 1'b1;
end*/
 
reg [31:0] test_counter1;
reg [31:0] test_counter2;
reg [31:0] pc_record1;
reg [31:0] pc_record2;

always @(posedge clk) begin
  if(reset)
    test_counter1 <= 32'b0;
  else if(d_s_finish_his && d_s_cache_rcv && d_s_wr_his && d_s_paddr_his == 32'h00000040) begin
    test_counter1 <= test_counter1 + 32'd1;
    pc_record1    <= test_pc;
  end
end

always @(posedge clk) begin
  if(reset)
    test_counter2 <= 32'b0;
  else if(d_s_finish_his && d_s_cache_rcv && d_s_wr_his && d_s_paddr_his == 32'h00000044) begin
    test_counter2 <= test_counter2 + 32'd1;
    pc_record2    <= test_pc;
  end
end


/* --------------------- i_s_port ---------------------*/
reg        i_s_hit_his;
reg        i_s_v_his  ;
reg [ 1:0] i_s_plv_his;
reg [ 1:0] i_s_mat_his;
reg        i_s_adef_his;

reg        i_s_cacop_his;
reg        i_s_cacop_adef_his;

wire i_unmapped_search;
wire i_dir_map_win_hit;
wire i_dir_map_win0_hit;
wire i_dir_map_win1_hit;

wire  [ENTRIES-1:0] itlb_vpn2_hit;
wire  [ENTRIES-1:0] itlb_hit;
wire  [VPNBITS-1:0] i_s_vpn2 = i_s_vaddr[VABITS-1:13];
wire                i_s_ps;
wire  [PFNBITS-1:0] i_s_pfn;
wire  [PABITS-1 :0] i_s_paddr;
wire                i_s_v;
wire  [ 1       :0] i_s_plv;
wire  [ 1       :0] i_s_mat;

wire   i_plv_error        = i_s_plv_his  < csr_CRMD_PLV;
wire   i_adef_error       = i_s_vaddr[1:0] != 2'b00 || csr_CRMD_PLV != 2'b00 && i_s_vaddr[GRLEN-1];

wire   i_cacop_adef_error = csr_CRMD_PLV != 2'b00 && i_s_vaddr[GRLEN-1];

assign i_unmapped_search  = csr_CRMD_DA | i_dir_map_win_hit;
assign i_dir_map_win_hit  = i_dir_map_win0_hit | i_dir_map_win1_hit;
assign i_dir_map_win0_hit = csr_CRMD_PG & i_s_vaddr[`LSOC1K_DMW_VSEG] == csr_dir_map_win0[`LSOC1K_DMW_VSEG] & csr_dir_map_win0[{3'b0,csr_CRMD_PLV}];
assign i_dir_map_win1_hit = csr_CRMD_PG & i_s_vaddr[`LSOC1K_DMW_VSEG] == csr_dir_map_win1[`LSOC1K_DMW_VSEG] & csr_dir_map_win1[{3'b0,csr_CRMD_PLV}];


// uty: test
//assign i_s_paddr_uty = i_s_vaddr[PABITS-1:0];

always @(posedge clk) begin
  if(i_s_req && i_unmapped_search) begin
    i_s_hit_his   <= 1'b1;
    i_s_paddr_his <= (csr_CRMD_DA       )? i_s_vaddr[PABITS-1:0]:
                     (i_dir_map_win0_hit)? {csr_dir_map_win0[`LSOC1K_DMW_PSEG], i_s_vaddr[28:0]}:
                                           {csr_dir_map_win1[`LSOC1K_DMW_PSEG], i_s_vaddr[28:0]};
    i_s_v_his     <= 1'b1;
    i_s_plv_his   <= 2'd3;
    i_s_mat_his   <= (csr_CRMD_DA       )? csr_CRMD_DATF:
                     (i_dir_map_win0_hit)? csr_dir_map_win0[`LSOC1K_DMW_MAT]:
                     (i_dir_map_win1_hit)? csr_dir_map_win1[`LSOC1K_DMW_MAT]:
                                           2'b0;
    i_s_adef_his  <= i_adef_error;
    i_s_cacop_his <= i_s_cacop_req;
    i_s_cacop_adef_his <= i_cacop_adef_error;
  end
  else if(i_s_req) begin
    i_s_hit_his   <= |itlb_hit;
    i_s_paddr_his <= i_s_paddr;
    i_s_v_his     <= i_s_v    ;
    i_s_plv_his   <= i_s_plv  ;
    i_s_mat_his   <= i_s_mat  ;
    i_s_adef_his  <= i_adef_error;
    i_s_cacop_his <= i_s_cacop_req;
    i_s_cacop_adef_his <= i_cacop_adef_error;
  end
end

wire [5:0] i_srch_exccode  = ( i_s_adef_his              )?   `EXC_ADEF:
                             (!i_s_hit_his               )?   `EXC_TLBR:
                             ( i_s_hit_his & !i_s_v_his  )?   `EXC_PIF :
                             ( i_s_hit_his &  i_plv_error)?   `EXC_PPI :
                                                              `EXC_NONE;

wire [5:0] i_s_cacop_exccode = (i_s_cacop_adef_his         )? `EXC_ADEM :
                               (!i_s_hit_his               )? `EXC_TLBR :
                               ( i_s_hit_his & !i_s_v_his  )? `EXC_PIL  :
                               ( i_s_hit_his &  i_plv_error)? `EXC_PPI  :
                                                              `EXC_NONE ;

assign i_s_exccode = (i_s_cacop_his)? i_s_cacop_exccode : i_srch_exccode;

assign i_s_uncached = i_s_mat_his == 2'd0;
assign i_s_hit      = i_s_hit_his && i_s_exccode == `EXC_NONE;

always @(posedge clk) begin
  if(reset)
    i_s_finish_his <= 1'b0;
  else if(i_s_req)
    i_s_finish_his <= 1'b1;
  else if(i_s_cache_rcv)
    i_s_finish_his <= 1'b0;
end

// entry search
wire [IDXBITS-1:0] i_sel;
generate
  if(ENTRIES == 8) begin: itlbhit_sel_8
  assign i_sel = {3{itlb_hit[0]}} & 3'd0 |
                 {3{itlb_hit[1]}} & 3'd1 |
                 {3{itlb_hit[2]}} & 3'd2 |
                 {3{itlb_hit[3]}} & 3'd3 |
                 {3{itlb_hit[4]}} & 3'd4 |
                 {3{itlb_hit[5]}} & 3'd5 |
                 {3{itlb_hit[6]}} & 3'd6 |
                 {3{itlb_hit[7]}} & 3'd7 ;
  end
  else if(ENTRIES == 32) begin: itlbhit_sel_32
  assign i_sel = {5{itlb_hit[ 0]}} & 5'd0  |
                 {5{itlb_hit[ 1]}} & 5'd1  |
                 {5{itlb_hit[ 2]}} & 5'd2  |
                 {5{itlb_hit[ 3]}} & 5'd3  |
                 {5{itlb_hit[ 4]}} & 5'd4  |
                 {5{itlb_hit[ 5]}} & 5'd5  |
                 {5{itlb_hit[ 6]}} & 5'd6  |
                 {5{itlb_hit[ 7]}} & 5'd7  |
                 {5{itlb_hit[ 8]}} & 5'd8  |
                 {5{itlb_hit[ 9]}} & 5'd9  |
                 {5{itlb_hit[10]}} & 5'd10 |
                 {5{itlb_hit[11]}} & 5'd11 |
                 {5{itlb_hit[12]}} & 5'd12 |
                 {5{itlb_hit[13]}} & 5'd13 |
                 {5{itlb_hit[14]}} & 5'd14 |
                 {5{itlb_hit[15]}} & 5'd15 |
                 {5{itlb_hit[16]}} & 5'd16 |
                 {5{itlb_hit[17]}} & 5'd17 |
                 {5{itlb_hit[18]}} & 5'd18 |
                 {5{itlb_hit[19]}} & 5'd19 |
                 {5{itlb_hit[20]}} & 5'd20 |
                 {5{itlb_hit[21]}} & 5'd21 |
                 {5{itlb_hit[22]}} & 5'd22 |
                 {5{itlb_hit[23]}} & 5'd23 |
                 {5{itlb_hit[24]}} & 5'd24 |
                 {5{itlb_hit[25]}} & 5'd25 |
                 {5{itlb_hit[26]}} & 5'd26 |
                 {5{itlb_hit[27]}} & 5'd27 |
                 {5{itlb_hit[28]}} & 5'd28 |
                 {5{itlb_hit[29]}} & 5'd29 |
                 {5{itlb_hit[30]}} & 5'd30 |
                 {5{itlb_hit[31]}} & 5'd31 ;
  end
endgenerate

wire i_s_odd_page;
assign i_s_odd_page = i_s_ps? i_s_vaddr[22] : i_s_vaddr[12]; // 0-even 1-odd

assign i_s_ps    = tlb_ps_4M[i_sel];
assign i_s_pfn   = (!i_s_odd_page)? tlb_pfn0[i_sel] : tlb_pfn1[i_sel];
assign i_s_paddr = i_s_ps? {i_s_pfn[PFNBITS-5:10], i_s_vaddr[21:0]} : {i_s_pfn[PFNBITS-5:0], i_s_vaddr[11:0]};
assign i_s_v     = (!i_s_odd_page)? tlb_v0[i_sel]   : tlb_v1[i_sel];
assign i_s_plv   = (!i_s_odd_page)? tlb_plv0[i_sel] : tlb_plv1[i_sel];
assign i_s_mat   = (!i_s_odd_page)? tlb_mat0[i_sel] : tlb_mat1[i_sel];

genvar gv_itlb;
generate
  for(gv_itlb = 0; gv_itlb < ENTRIES; gv_itlb = gv_itlb + 1)
  begin : gen_itlb
    assign itlb_vpn2_hit[gv_itlb] = (tlb_ps_4M[gv_itlb])? i_s_vpn2[VPNBITS-1:10] == tlb_vpn2[gv_itlb][VPNBITS-1:10]:
                                                          i_s_vpn2 == tlb_vpn2[gv_itlb];
    assign itlb_hit[gv_itlb] = tlb_p[gv_itlb] && itlb_vpn2_hit[gv_itlb] && 
                              (tlb_g[gv_itlb] || csr_asid == tlb_asid[gv_itlb]);
  end
endgenerate
/* ----------------------- end ------------------------*/

/* --------------------- d_s_port ---------------------*/
reg        d_s_wr_his ;
reg        d_s_hit_his;
reg        d_s_v_his  ;
reg        d_s_d_his  ;
reg [ 1:0] d_s_plv_his;
reg [ 1:0] d_s_mat_his;
reg        d_s_adem_his;

wire d_unmapped_search;
wire d_dir_map_win_hit;
wire d_dir_map_win0_hit;
wire d_dir_map_win1_hit;

wire  [ENTRIES-1:0] tlb_phit;
wire  [ENTRIES-1:0] dtlb_vpn2_hit;
wire  [ENTRIES-1:0] dtlb_hit;
wire  [VPNBITS-1:0] d_s_vpn2 = d_s_vaddr[VABITS-1:13];
wire                d_s_ps;
wire  [PFNBITS-1:0] d_s_pfn;
wire  [PABITS-1 :0] d_s_paddr;
wire                d_s_v;
wire                d_s_d;
wire  [ 1       :0] d_s_plv;
wire  [ 1       :0] d_s_mat;

wire   d_plv_error        = d_s_plv_his  < csr_CRMD_PLV;
wire   d_adem_error       = csr_CRMD_PLV != 2'b00 && d_s_vaddr[GRLEN-1];

assign d_unmapped_search  = csr_CRMD_DA | d_dir_map_win_hit;
assign d_dir_map_win_hit  = d_dir_map_win0_hit | d_dir_map_win1_hit;
assign d_dir_map_win0_hit = csr_CRMD_PG & d_s_vaddr[`LSOC1K_DMW_VSEG] == csr_dir_map_win0[`LSOC1K_DMW_VSEG] & csr_dir_map_win0[{3'b0,csr_CRMD_PLV}];
assign d_dir_map_win1_hit = csr_CRMD_PG & d_s_vaddr[`LSOC1K_DMW_VSEG] == csr_dir_map_win1[`LSOC1K_DMW_VSEG] & csr_dir_map_win1[{3'b0,csr_CRMD_PLV}];

always @(posedge clk) begin
  if(reset) // TODO
    d_s_wr_his <= 1'b0;
  else if(d_s_req)
    d_s_wr_his <= d_s_wr;
end

always @(posedge clk) begin
  if(reset) begin // TODO:
    d_s_hit_his   <=  1'b0;
    d_s_paddr_his <= {PABITS{1'b0}};
    d_s_v_his     <=  1'b0;
    d_s_d_his     <=  1'b0;
    d_s_plv_his   <=  2'd3;
    d_s_mat_his   <=  2'b0;
    d_s_adem_his  <=  1'b0;
  end
  else if(d_s_req && (d_s_no_trans || d_unmapped_search)) begin
    d_s_hit_his   <= 1'b1;
    d_s_paddr_his <= (d_s_no_trans               )? {d_s_vaddr[PABITS-1:13], d_s_p_pgcl, d_s_vaddr[11:0]}:
                     (csr_CRMD_DA                )? d_s_vaddr[PABITS-1:0]:
                     (d_dir_map_win0_hit         )? {csr_dir_map_win0[`LSOC1K_DMW_PSEG], d_s_vaddr[28:0]}:
                                                    {csr_dir_map_win1[`LSOC1K_DMW_PSEG], d_s_vaddr[28:0]};
    d_s_v_his     <= 1'b1;
    d_s_d_his     <= 1'b1;
    d_s_plv_his   <= 2'd3;
    d_s_mat_his   <= (d_s_no_trans      )? 2'b1:
                     (csr_CRMD_DA       )? csr_CRMD_DATM:
                     (d_dir_map_win0_hit)? csr_dir_map_win0[`LSOC1K_DMW_MAT]:
                     (d_dir_map_win1_hit)? csr_dir_map_win1[`LSOC1K_DMW_MAT]:
                                           2'b0;
    tlbp_idx      <= d_sel      ;
    d_s_adem_his  <= d_adem_error;
  end
  else if(d_s_req) begin
    d_s_hit_his   <= |dtlb_hit  ;
    d_s_paddr_his <= d_s_paddr  ;
    d_s_v_his     <= d_s_v      ;
    d_s_d_his     <= d_s_d      ;
    d_s_plv_his   <= d_s_plv    ;
    d_s_mat_his   <= d_s_mat    ;
    tlbp_idx      <= d_sel      ;
    d_s_adem_his  <= d_adem_error;
  end
end

assign d_s_exccode = (d_s_adem_his                           )? `EXC_ADEM :
                     (!d_s_hit_his                           )? `EXC_TLBR :
                     ( d_s_hit_his & !d_s_wr_his & !d_s_v_his)? `EXC_PIL  :
                     ( d_s_hit_his &  d_s_wr_his & !d_s_v_his)? `EXC_PIS  :
                     ( d_s_hit_his &  d_plv_error            )? `EXC_PPI  :
                     ( d_s_hit_his &  d_s_wr_his & !d_s_d_his)? `EXC_PWE  :
                                                                `EXC_NONE ;
assign d_s_uncached = d_s_mat_his == 2'd0;
assign d_s_hit      = d_s_hit_his && d_s_exccode == `EXC_NONE;

always @(posedge clk) begin
  if(reset)
    d_s_finish_his <= 1'b0;
  else if(d_s_req)
    d_s_finish_his <= 1'b1;
  else if(d_s_cache_rcv)
    d_s_finish_his <= 1'b0;
end

// entry search
wire [IDXBITS-1:0] d_sel;
generate
  if(ENTRIES == 8) begin: dtlbhit_sel_8
  assign d_sel = {3{dtlb_hit[0]}} & 3'd0 |
                 {3{dtlb_hit[1]}} & 3'd1 |
                 {3{dtlb_hit[2]}} & 3'd2 |
                 {3{dtlb_hit[3]}} & 3'd3 |
                 {3{dtlb_hit[4]}} & 3'd4 |
                 {3{dtlb_hit[5]}} & 3'd5 |
                 {3{dtlb_hit[6]}} & 3'd6 |
                 {3{dtlb_hit[7]}} & 3'd7 ;
  end
  else if(ENTRIES == 32) begin: dtlbhit_sel_32
  assign d_sel = {5{dtlb_hit[ 0]}} & 5'd0  |
                 {5{dtlb_hit[ 1]}} & 5'd1  |
                 {5{dtlb_hit[ 2]}} & 5'd2  |
                 {5{dtlb_hit[ 3]}} & 5'd3  |
                 {5{dtlb_hit[ 4]}} & 5'd4  |
                 {5{dtlb_hit[ 5]}} & 5'd5  |
                 {5{dtlb_hit[ 6]}} & 5'd6  |
                 {5{dtlb_hit[ 7]}} & 5'd7  |
                 {5{dtlb_hit[ 8]}} & 5'd8  |
                 {5{dtlb_hit[ 9]}} & 5'd9  |
                 {5{dtlb_hit[10]}} & 5'd10 |
                 {5{dtlb_hit[11]}} & 5'd11 |
                 {5{dtlb_hit[12]}} & 5'd12 |
                 {5{dtlb_hit[13]}} & 5'd13 |
                 {5{dtlb_hit[14]}} & 5'd14 |
                 {5{dtlb_hit[15]}} & 5'd15 |
                 {5{dtlb_hit[16]}} & 5'd16 |
                 {5{dtlb_hit[17]}} & 5'd17 |
                 {5{dtlb_hit[18]}} & 5'd18 |
                 {5{dtlb_hit[19]}} & 5'd19 |
                 {5{dtlb_hit[20]}} & 5'd20 |
                 {5{dtlb_hit[21]}} & 5'd21 |
                 {5{dtlb_hit[22]}} & 5'd22 |
                 {5{dtlb_hit[23]}} & 5'd23 |
                 {5{dtlb_hit[24]}} & 5'd24 |
                 {5{dtlb_hit[25]}} & 5'd25 |
                 {5{dtlb_hit[26]}} & 5'd26 |
                 {5{dtlb_hit[27]}} & 5'd27 |
                 {5{dtlb_hit[28]}} & 5'd28 |
                 {5{dtlb_hit[29]}} & 5'd29 |
                 {5{dtlb_hit[30]}} & 5'd30 |
                 {5{dtlb_hit[31]}} & 5'd31 ;
  end
endgenerate

wire d_s_odd_page;
assign d_s_odd_page = d_s_ps? d_s_vaddr[22] : d_s_vaddr[12]; // 0-even 1-odd

assign d_s_ps    = tlb_ps_4M[d_sel];
assign d_s_pfn   = (!d_s_odd_page)? tlb_pfn0[d_sel] : tlb_pfn1[d_sel];
assign d_s_paddr = d_s_ps? {d_s_pfn[PFNBITS-5:10], d_s_vaddr[21:0]} : {d_s_pfn[PFNBITS-5:0], d_s_vaddr[11:0]};
assign d_s_v     = (!d_s_odd_page)? tlb_v0[d_sel]   : tlb_v1[d_sel];
assign d_s_d     = (!d_s_odd_page)? tlb_d0[d_sel]   : tlb_d1[d_sel];
assign d_s_plv   = (!d_s_odd_page)? tlb_plv0[d_sel] : tlb_plv1[d_sel];
assign d_s_mat   = (!d_s_odd_page)? tlb_mat0[d_sel] : tlb_mat1[d_sel];

genvar gv_dtlb;
generate
  for(gv_dtlb = 0; gv_dtlb < ENTRIES; gv_dtlb = gv_dtlb + 1)
  begin : gen_dtlb
    assign dtlb_vpn2_hit[gv_dtlb] = tlb_p[gv_dtlb] && (
                                    (tlb_ps_4M[gv_dtlb])? d_s_vpn2[VPNBITS-1:10] == tlb_vpn2[gv_dtlb][VPNBITS-1:10]:
                                                         d_s_vpn2 == tlb_vpn2[gv_dtlb]);
    assign dtlb_hit[gv_dtlb] = dtlb_vpn2_hit[gv_dtlb] && 
                              (tlb_g[gv_dtlb] || csr_asid == tlb_asid[gv_dtlb]);

    assign tlb_phit[gv_dtlb] = dtlb_vpn2_hit[gv_dtlb] && 
                              (tlb_g[gv_dtlb] || tlbp_asid == tlb_asid[gv_dtlb]);
  end
endgenerate
/* ----------------------- end ------------------------*/



/* --------------------- TLB inst ---------------------*/
  // TLBP
reg tlbp_hit_his;
always @(posedge clk) begin
  if(reset)
    tlbp_hit_his <= 1'b0;
  else if(tlbp_req)
    tlbp_hit_his <= |tlb_phit;
end

assign tlbp_hit = tlbp_hit_his;

  // TLBR
always @(posedge clk) begin
  if(r_req) begin
    r_p    <= tlb_p   [r_idx];
    r_vpn2 <= tlb_vpn2[r_idx];
    r_g    <= tlb_g   [r_idx];
    r_pfn0 <= tlb_pfn0[r_idx];
    r_mat0 <= tlb_mat0[r_idx];
    r_plv0 <= tlb_plv0[r_idx];
    r_d0   <= tlb_d0  [r_idx];
    r_v0   <= tlb_v0  [r_idx];
    r_pfn1 <= tlb_pfn1[r_idx];
    r_mat1 <= tlb_mat1[r_idx];
    r_plv1 <= tlb_plv1[r_idx];
    r_d1   <= tlb_d1  [r_idx];
    r_v1   <= tlb_v1  [r_idx];
    r_asid <= tlb_asid[r_idx];
    r_ps   <= tlb_ps_4M[r_idx]? 6'd22 : 6'd12;
  end
end

  // INVTLB
wire [ENTRIES-1:0] inv_hit;
/* ----------------------- end ------------------------*/



/* ----------------------- TLB ------------------------*/

reg                 tlb_p      [ENTRIES-1:0];
reg                 tlb_g      [ENTRIES-1:0];
reg [9:0]           tlb_asid   [ENTRIES-1:0];
reg                 tlb_ps_4M  [ENTRIES-1:0]; // 0: 4KB, 1:4MB
reg [VPNBITS-1:0]   tlb_vpn2   [ENTRIES-1:0];
reg                 tlb_v0     [ENTRIES-1:0];
reg                 tlb_d0     [ENTRIES-1:0];
reg [1:0]           tlb_mat0   [ENTRIES-1:0];
reg [1:0]           tlb_plv0   [ENTRIES-1:0];
reg [PFNBITS-1:0]   tlb_pfn0   [ENTRIES-1:0];
reg                 tlb_v1     [ENTRIES-1:0];
reg                 tlb_d1     [ENTRIES-1:0];
reg [1:0]           tlb_mat1   [ENTRIES-1:0];
reg [1:0]           tlb_plv1   [ENTRIES-1:0];
reg [PFNBITS-1:0]   tlb_pfn1   [ENTRIES-1:0];

genvar gv_tlb;
generate
  for(gv_tlb = 0; gv_tlb < ENTRIES; gv_tlb = gv_tlb + 1)
  begin : gen_tlb
    assign inv_hit[gv_tlb] = inv_op == 5'd0 || inv_op == 5'd1 ||
                             inv_op == 5'd2 &&  tlb_g[gv_tlb] ||
                             inv_op == 5'd3 && !tlb_g[gv_tlb] ||
                             inv_op == 5'd4 && !tlb_g[gv_tlb] && tlb_asid[gv_tlb] == inv_asid  ||
                             inv_op == 5'd5 && !tlb_g[gv_tlb] && tlb_asid[gv_tlb] == inv_asid  && tlb_vpn2[gv_tlb] == inv_vpn2 ||
                             inv_op == 5'd6 && (tlb_g[gv_tlb] || tlb_asid[gv_tlb] == inv_asid) && tlb_vpn2[gv_tlb] == inv_vpn2 ;

    always @(posedge clk) begin
      if(reset)
        tlb_p    [gv_tlb] <= 1'b0;
      else if(inv_req && inv_hit[gv_tlb])
        tlb_p    [gv_tlb] <= 1'b0;
      else if(w_en && w_idx == gv_tlb) begin
        tlb_p    [gv_tlb] <= w_p    ;
        tlb_g    [gv_tlb] <= w_g    ;
        tlb_asid [gv_tlb] <= w_asid ;
        tlb_ps_4M[gv_tlb] <= w_ps_4M;
        tlb_vpn2 [gv_tlb] <= w_vpn2 ;
        tlb_v0   [gv_tlb] <= w_v0   ;
        tlb_d0   [gv_tlb] <= w_d0   ;
        tlb_plv0 [gv_tlb] <= w_plv0 ;
        tlb_mat0 [gv_tlb] <= w_mat0 ;
        tlb_pfn0 [gv_tlb] <= w_pfn0 ;
        tlb_v1   [gv_tlb] <= w_v1   ;
        tlb_d1   [gv_tlb] <= w_d1   ;
        tlb_plv1 [gv_tlb] <= w_plv1 ;
        tlb_mat1 [gv_tlb] <= w_mat1 ;
        tlb_pfn1 [gv_tlb] <= w_pfn1 ;
      end
    end
  end
endgenerate
/* ----------------------- end ------------------------*/

endmodule
