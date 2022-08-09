`include "common.vh"
`include "decoded.vh"

module tlb_wrapper
#(
    parameter IDXBITS = `TLB_IDXBITS,

    parameter GRLEN   = `GRLEN,
    parameter PABITS  = `PABITS,
    parameter VABITS  = `VABITS,
    parameter PFNBITS = `PFNBITS,
    parameter VPNBITS = `VPNBITS
)
(
    input                   clk  ,
    input                   reset,

    input     [31:0]        test_pc,

    // read from cp0      
    input  [`GRLEN-1:0]   csr_index_in   ,
    input  [`GRLEN-1:0]   csr_entryhi_in ,
    input  [`GRLEN-1:0]   csr_entrylo0_in,
    input  [`GRLEN-1:0]   csr_entrylo1_in,
    input  [`GRLEN-1:0]   csr_asid_in    ,
    input  [5       :0]   csr_ecode_in   ,

    input  [ 1:0]   csr_CRMD_PLV ,
    input           csr_CRMD_DA  ,
    input           csr_CRMD_PG  ,
    input  [ 1:0]   csr_CRMD_DATF,
    input  [ 1:0]   csr_CRMD_DATM,
    input  [`GRLEN-1:0]   csr_dir_map_win0,
    input  [`GRLEN-1:0]   csr_dir_map_win1,

    // write to cp0       
    output [`GRLEN-1:0]   csr_index_out   ,
    output [`GRLEN-1:0]   csr_entryhi_out ,
    output [`GRLEN-1:0]   csr_entrylo0_out,
    output [`GRLEN-1:0]   csr_entrylo1_out,
    output [`GRLEN-1:0]   csr_asid_out    ,
    
    // itlb search port
    input                 i_req         ,
    input   [GRLEN-1 :0]  i_vaddr       ,
    input                 i_cacop_req   ,
    input                 i_cache_rcv   ,
    output                i_finish      ,
    output                i_hit         ,
    output  [PABITS-1:0]  i_paddr       ,
    output                i_uncached    ,
    output  [ 5:0]        i_exccode     ,
    
    // dtlb search port
    input                 d_req         ,
    input                 d_wr          ,// store(write) 1 load(read) 0
    input   [GRLEN-1 :0]  d_vaddr       ,
    input                 d_cache_rcv   ,
    input                 b_p_pgcl      ,
    input                 d_no_trans    ,
    output                d_finish      ,
    output                d_hit         ,
    output  [PABITS-1:0]  d_paddr       ,
    output                d_uncached    ,
    output  [5        :0] d_exccode     ,

    input   [ 4:0]        c_op          ,

    // tlb inst signal
    input                   tlb_req     ,
    input  [`LSOC1K_TLB_CODE_BIT-1:0] tlb_op, 
    input  [31        :0]   invtlb_vaddr,
    output                  tlb_recv    ,
    output                  tlb_finish  
);

// TLB inst
wire               w_req  ;
wire [IDXBITS-1:0] w_idx  ;
wire               w_ps_4M;
wire [VPNBITS-1:0] w_vpn2 ;
wire [ 9:0]        w_asid ;
wire               w_g    ;
wire               w_p    ;
wire [PFNBITS-1:0] w_pfn0 ;
wire [PFNBITS-1:0] w_pfn1 ;
wire               w_v0   ;
wire               w_d0   ;
wire [1:0]         w_plv0 ;
wire [1:0]         w_mat0 ;
wire               w_v1   ;
wire               w_d1   ;
wire [1:0]         w_plv1 ;
wire [1:0]         w_mat1 ;


reg  [ 1:0]  op_state;
wire op_cango;
reg  [`LSOC1K_TLB_CODE_BIT-1:0] tlb_op_his;

wire op_idle   = op_state == 2'b00;
wire op_sndreq = op_state == 2'b01;
wire op_finish = op_state == 2'b10;

always @(posedge clk) begin
  if(reset)
    op_state   <= 2'b00;
  else if((op_idle || op_finish) && tlb_req) begin
    op_state   <= 2'b01;
    tlb_op_his <= tlb_op;
  end
  else if(op_cango)
    op_state   <= 2'b10;
  else if(op_finish)
    op_state   <= 2'b00;
end

assign op_cango   = op_sndreq;

assign tlb_recv   = (op_idle || op_finish) && tlb_req;
assign tlb_finish = op_finish;

wire tlbw_req  = op_sndreq & (tlb_op_his == `LSOC1K_TLB_TLBWI | tlb_op_his == `LSOC1K_TLB_TLBWR);
wire tlbr_req  = op_sndreq &  tlb_op_his == `LSOC1K_TLB_TLBR;
wire tlbp_req  = op_sndreq &  tlb_op_his == `LSOC1K_TLB_TLBP;
wire invtlb_req  = op_sndreq &  tlb_op_his == `LSOC1K_TLB_INVTLB;

  // TLBP
wire               tlbp_hit;
wire [IDXBITS-1:0] tlbp_idx;
wire [GRLEN-1:0] p_vaddr = {csr_entryhi_in[GRLEN-1:13], 13'b0};
wire [ 9:0]      p_asid  = csr_asid_in[`LSOC1K_ASID_ASID];

  // TLBR
wire                   r_req;
wire [IDXBITS-1    :0] r_idx;

wire [VPNBITS-1    :0] r_vpn2;
wire [9            :0] r_asid;
wire                   r_p   ;
wire                   r_g   ;
wire [5            :0] r_ps  ;
wire                   r_v0  ;
wire                   r_d0  ;
wire [1            :0] r_plv0;
wire [1            :0] r_mat0;
wire [PFNBITS-1    :0] r_pfn0;
wire                   r_v1  ;
wire                   r_d1  ;
wire [1            :0] r_plv1;
wire [1            :0] r_mat1;
wire [PFNBITS-1    :0] r_pfn1;

assign r_req = tlbr_req;
assign r_idx = csr_index_in[IDXBITS-1:0];

  // TLBW
reg [IDXBITS-1:0] random_gen;
always@(posedge clk) begin
  if(tlb_finish)
    random_gen <= random_gen + {{IDXBITS-1{1'b0}}, 1'b1};
end

assign w_req   = tlbw_req;
assign w_idx   = (tlb_op_his == `LSOC1K_TLB_TLBWI)? csr_index_in[IDXBITS-1:0] : random_gen;
assign w_vpn2  = csr_entryhi_in[VABITS-1:13];
assign w_asid  = csr_asid_in[`LSOC1K_ASID_ASID];
assign w_p     = (csr_ecode_in == `EXC_TLBR)? 1'b1 : !csr_index_in[`LSOC1K_INDEX_NP];
assign w_pfn0  = csr_entrylo0_in[`LSOC1K_TLBELO_PFN];
assign w_pfn1  = csr_entrylo1_in[`LSOC1K_TLBELO_PFN];
assign w_ps_4M =(csr_index_in[`LSOC1K_INDEX_PS] == 6'hc)? 1'b0 : 1'b1;
assign w_v0    = csr_entrylo0_in[`LSOC1K_TLBELO_V   ];
assign w_d0    = csr_entrylo0_in[`LSOC1K_TLBELO_WE  ];
assign w_plv0  = csr_entrylo0_in[`LSOC1K_TLBELO_PLV ];
assign w_mat0  = csr_entrylo0_in[`LSOC1K_TLBELO_MAT ];
assign w_v1    = csr_entrylo1_in[`LSOC1K_TLBELO_V   ];
assign w_d1    = csr_entrylo1_in[`LSOC1K_TLBELO_WE  ];
assign w_plv1  = csr_entrylo1_in[`LSOC1K_TLBELO_PLV ];
assign w_mat1  = csr_entrylo1_in[`LSOC1K_TLBELO_MAT ];
assign w_g     = csr_entrylo0_in[`LSOC1K_TLBELO_G   ] & csr_entrylo1_in[`LSOC1K_TLBELO_G   ];

  // INVTLB
// TODO;
reg [4:0] inv_op  ;
reg [9:0] inv_asid;
reg [VPNBITS-1:0] inv_vpn2;

always @(posedge clk) begin
  if(tlb_req && tlb_op == `LSOC1K_TLB_INVTLB) begin
    inv_op   <= c_op;
    inv_asid <= d_vaddr[9:0];
    inv_vpn2 <= invtlb_vaddr[GRLEN-1:13];
  end
end

assign csr_index_out    = (tlb_op_his == `LSOC1K_TLB_TLBP)? {!tlbp_hit, 1'b0, csr_index_in[29:24], 12'b0, {12-IDXBITS{1'b0}}, tlbp_idx}: // TLBP
                                                            {!r_p     , 1'b0, r_p? r_ps : csr_index_in[`LSOC1K_INDEX_PS], 12'b0, csr_index_in[11:0]}; // TLBR
assign csr_entryhi_out  = r_p? {r_vpn2, 13'b0} : csr_entryhi_in; // TLBR
assign csr_entrylo0_out = r_p? {r_pfn0, 1'b0, r_g, r_mat0, r_plv0, r_d0, r_v0} : csr_entrylo0_in; // TLBR
assign csr_entrylo1_out = r_p? {r_pfn1, 1'b0, r_g, r_mat1, r_plv1, r_d1, r_v1} : csr_entrylo1_in; // TLBR
assign csr_asid_out     = {22'b0, r_asid}; // TLBR

// L1 Search
  // inst prot
wire             i_req_l1  ;
wire [GRLEN-1:0] i_vaddr_l1;
wire             i_cacop_l1;

  // data port
wire             d_req_l1  ;
wire             d_wr_l1   ;
wire [GRLEN-1:0] d_vaddr_l1;
wire             d_recv_l1 ;

// inst Port
assign i_req_l1   = i_req;
assign i_vaddr_l1 = i_vaddr;
assign i_cacop_l1 = i_cacop_req;

// data port
assign d_req_l1   = d_req | tlbp_req;
assign d_wr_l1    = (tlbp_req)? 1'b0 : d_wr;
assign d_vaddr_l1 = (tlbp_req)? p_vaddr:
                                d_vaddr;
assign d_recv_l1  = d_cache_rcv;

// modules
tlb u_tlb(
    .clk              (clk              ),
    .reset            (reset            ),

    .test_pc          (test_pc),

    .csr_CRMD_PLV     (csr_CRMD_PLV     ),
    .csr_CRMD_DA      (csr_CRMD_DA      ),
    .csr_CRMD_PG      (csr_CRMD_PG      ),
    .csr_CRMD_DATF    (csr_CRMD_DATF    ),
    .csr_CRMD_DATM    (csr_CRMD_DATM    ),
    .csr_dir_map_win0 (csr_dir_map_win0 ),
    .csr_dir_map_win1 (csr_dir_map_win1 ),
    .csr_asid         (csr_asid_in[`LSOC1K_ASID_ASID]),

    .i_s_req          (i_req_l1         ),
    .i_s_vaddr        (i_vaddr_l1       ),
    .i_s_cacop_req    (i_cacop_l1       ),
    .i_s_cache_rcv    (i_cache_rcv      ),
    .i_s_finish_his   (i_finish         ),
    .i_s_paddr_his    (i_paddr          ),
    .i_s_hit          (i_hit            ),
    .i_s_uncached     (i_uncached       ),
    .i_s_exccode      (i_exccode        ),

    .d_s_req          (d_req_l1         ),
    .d_s_wr           (d_wr_l1          ),
    .d_s_vaddr        (d_vaddr_l1       ),
    .d_s_cache_rcv    (d_recv_l1        ),
    .d_s_no_trans     (d_no_trans       ),
    .d_s_p_pgcl       (b_p_pgcl         ),
    .d_s_finish_his   (d_finish         ),
    .d_s_paddr_his    (d_paddr          ),
    .d_s_hit          (d_hit            ),
    .d_s_uncached     (d_uncached       ),
    .d_s_exccode      (d_exccode        ),

    .tlbp_req         (tlbp_req         ),
    .tlbp_asid        (p_asid           ),
    .tlbp_hit         (tlbp_hit         ),
    .tlbp_idx         (tlbp_idx         ),

    .r_req            (r_req            ),
    .r_idx            (r_idx            ),
    .r_vpn2           (r_vpn2           ),
    .r_asid           (r_asid           ),
    .r_p              (r_p              ),
    .r_g              (r_g              ),
    .r_ps             (r_ps             ),
    .r_v0             (r_v0             ),
    .r_d0             (r_d0             ),
    .r_plv0           (r_plv0           ),
    .r_mat0           (r_mat0           ),
    .r_pfn0           (r_pfn0           ),
    .r_v1             (r_v1             ),
    .r_d1             (r_d1             ),
    .r_plv1           (r_plv1           ),
    .r_mat1           (r_mat1           ),
    .r_pfn1           (r_pfn1           ),
    
    .inv_req          (invtlb_req       ),
    .inv_op           (inv_op           ),
    .inv_asid         (inv_asid         ),
    .inv_vpn2         (inv_vpn2         ),

    .w_en             (w_req            ),
    .w_idx            (w_idx            ),
    .w_vpn2           (w_vpn2           ),
    .w_asid           (w_asid           ),
    .w_g              (w_g              ),
    .w_ps_4M          (w_ps_4M          ),
    .w_p              (w_p              ),
    .w_v0             (w_v0             ),
    .w_d0             (w_d0             ),
    .w_plv0           (w_plv0           ),
    .w_mat0           (w_mat0           ),
    .w_pfn0           (w_pfn0           ),
    .w_v1             (w_v1             ),
    .w_d1             (w_d1             ),
    .w_plv1           (w_plv1           ),
    .w_mat1           (w_mat1           ),
    .w_pfn1           (w_pfn1           )
);

endmodule
