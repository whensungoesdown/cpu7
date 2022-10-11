`include "decoded.vh"

// ALU module
module lsu_s1(
  input               clk,
  input               resetn,

  input               valid,
  input [`LSOC1K_LSU_CODE_BIT-1:0]lsu_op, 
  input [`GRLEN-1:0]  base,
  input [`GRLEN-1:0]  offset,
  input [`GRLEN-1:0]  wdata,

  input               tlb_req,
  input               data_exception,
  input   [`GRLEN-1:0]data_badvaddr,
  input               tlb_finish,

  //memory interface
  output              data_req,
  output [`GRLEN-1:0] data_addr,
  output              data_wr,
  `ifdef LA64
  output [ 7:0]       data_wstrb,
  `elsif LA32
  output [ 3:0]       data_wstrb,
  `endif
  output [`GRLEN-1:0] data_wdata,
  output              data_prefetch,
  output              data_ll,
  output              data_sc,
  input               data_addr_ok,

//result
  output              lsu_finish,
  output              lsu_ale,
  output              lsu_adem,
  output              lsu_recv,

  input [`LSOC1K_CSR_OUTPUT_BIT-1:0] csr_output,
  input                              change,
  input                              eret,
  input                              exception,
  output reg [`GRLEN-1:0]            badvaddr
);

wire rst = !resetn;

//define
wire lsu_except;
reg res_valid;

// LSUop decoder
wire lsu_am    = lsu_op == `LSOC1K_LSU_AMSWAP_W    || lsu_op == `LSOC1K_LSU_AMSWAP_D    || lsu_op == `LSOC1K_LSU_AMADD_W     || lsu_op == `LSOC1K_LSU_AMADD_D     ||
                 lsu_op == `LSOC1K_LSU_AMAND_W     || lsu_op == `LSOC1K_LSU_AMAND_D     || lsu_op == `LSOC1K_LSU_AMOR_W      || lsu_op == `LSOC1K_LSU_AMOR_D      ||
                 lsu_op == `LSOC1K_LSU_AMXOR_W     || lsu_op == `LSOC1K_LSU_AMXOR_D     || lsu_op == `LSOC1K_LSU_AMMAX_W     || lsu_op == `LSOC1K_LSU_AMMAX_D     ||
                 lsu_op == `LSOC1K_LSU_AMMIN_W     || lsu_op == `LSOC1K_LSU_AMMIN_D     || lsu_op == `LSOC1K_LSU_AMMAX_WU    || lsu_op == `LSOC1K_LSU_AMMAX_DU    ||
                 lsu_op == `LSOC1K_LSU_AMMIN_WU    || lsu_op == `LSOC1K_LSU_AMMIN_DU    || lsu_op == `LSOC1K_LSU_AMSWAP_DB_W || lsu_op == `LSOC1K_LSU_AMSWAP_DB_D ||
                 lsu_op == `LSOC1K_LSU_AMADD_DB_W  || lsu_op == `LSOC1K_LSU_AMADD_DB_D  || lsu_op == `LSOC1K_LSU_AMAND_DB_W  || lsu_op == `LSOC1K_LSU_AMAND_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMOR_DB_W   || lsu_op == `LSOC1K_LSU_AMOR_DB_D   || lsu_op == `LSOC1K_LSU_AMXOR_DB_W  || lsu_op == `LSOC1K_LSU_AMXOR_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_W  || lsu_op == `LSOC1K_LSU_AMMAX_DB_D  || lsu_op == `LSOC1K_LSU_AMMIN_DB_W  || lsu_op == `LSOC1K_LSU_AMMIN_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_WU || lsu_op == `LSOC1K_LSU_AMMAX_DB_DU || lsu_op == `LSOC1K_LSU_AMMIN_DB_WU || lsu_op == `LSOC1K_LSU_AMMIN_DB_DU ;

wire lsu_am_lw = lsu_op == `LSOC1K_LSU_AMSWAP_W    || lsu_op == `LSOC1K_LSU_AMADD_W     ||
                 lsu_op == `LSOC1K_LSU_AMAND_W     || lsu_op == `LSOC1K_LSU_AMOR_W      ||
                 lsu_op == `LSOC1K_LSU_AMXOR_W     || lsu_op == `LSOC1K_LSU_AMMAX_W     ||
                 lsu_op == `LSOC1K_LSU_AMMIN_W     || lsu_op == `LSOC1K_LSU_AMMAX_WU    ||
                 lsu_op == `LSOC1K_LSU_AMMIN_WU    || lsu_op == `LSOC1K_LSU_AMSWAP_DB_W ||
                 lsu_op == `LSOC1K_LSU_AMADD_DB_W  || lsu_op == `LSOC1K_LSU_AMAND_DB_W  ||
                 lsu_op == `LSOC1K_LSU_AMOR_DB_W   || lsu_op == `LSOC1K_LSU_AMXOR_DB_W  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_W  || lsu_op == `LSOC1K_LSU_AMMIN_DB_W  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_WU || lsu_op == `LSOC1K_LSU_AMMIN_DB_WU ;

wire lsu_am_ld = lsu_op == `LSOC1K_LSU_AMSWAP_D    || lsu_op == `LSOC1K_LSU_AMADD_D     ||
                 lsu_op == `LSOC1K_LSU_AMAND_D     || lsu_op == `LSOC1K_LSU_AMOR_D      ||
                 lsu_op == `LSOC1K_LSU_AMXOR_D     || lsu_op == `LSOC1K_LSU_AMMAX_D     ||
                 lsu_op == `LSOC1K_LSU_AMMIN_D     || lsu_op == `LSOC1K_LSU_AMMAX_DU    ||
                 lsu_op == `LSOC1K_LSU_AMMIN_DU    || lsu_op == `LSOC1K_LSU_AMSWAP_DB_D ||
                 lsu_op == `LSOC1K_LSU_AMADD_DB_D  || lsu_op == `LSOC1K_LSU_AMAND_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMOR_DB_D   || lsu_op == `LSOC1K_LSU_AMXOR_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_D  || lsu_op == `LSOC1K_LSU_AMMIN_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_DU || lsu_op == `LSOC1K_LSU_AMMIN_DB_DU ;

wire lsu_am_sw = lsu_op == `LSOC1K_LSU_AMSWAP_W    || lsu_op == `LSOC1K_LSU_AMADD_W     ||
                 lsu_op == `LSOC1K_LSU_AMAND_W     || lsu_op == `LSOC1K_LSU_AMOR_W      ||
                 lsu_op == `LSOC1K_LSU_AMXOR_W     || lsu_op == `LSOC1K_LSU_AMMAX_W     ||
                 lsu_op == `LSOC1K_LSU_AMMIN_W     || lsu_op == `LSOC1K_LSU_AMMAX_WU    ||
                 lsu_op == `LSOC1K_LSU_AMMIN_WU    || lsu_op == `LSOC1K_LSU_AMSWAP_DB_W ||
                 lsu_op == `LSOC1K_LSU_AMADD_DB_W  || lsu_op == `LSOC1K_LSU_AMAND_DB_W  ||
                 lsu_op == `LSOC1K_LSU_AMOR_DB_W   || lsu_op == `LSOC1K_LSU_AMXOR_DB_W  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_W  || lsu_op == `LSOC1K_LSU_AMMIN_DB_W  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_WU || lsu_op == `LSOC1K_LSU_AMMIN_DB_WU ;

wire lsu_am_sd = lsu_op == `LSOC1K_LSU_AMSWAP_D    || lsu_op == `LSOC1K_LSU_AMADD_D     ||
                 lsu_op == `LSOC1K_LSU_AMAND_D     || lsu_op == `LSOC1K_LSU_AMOR_D      ||
                 lsu_op == `LSOC1K_LSU_AMXOR_D     || lsu_op == `LSOC1K_LSU_AMMAX_D     ||
                 lsu_op == `LSOC1K_LSU_AMMIN_D     || lsu_op == `LSOC1K_LSU_AMMAX_DU    ||
                 lsu_op == `LSOC1K_LSU_AMMIN_DU    || lsu_op == `LSOC1K_LSU_AMSWAP_DB_D ||
                 lsu_op == `LSOC1K_LSU_AMADD_DB_D  || lsu_op == `LSOC1K_LSU_AMAND_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMOR_DB_D   || lsu_op == `LSOC1K_LSU_AMXOR_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_D  || lsu_op == `LSOC1K_LSU_AMMIN_DB_D  ||
                 lsu_op == `LSOC1K_LSU_AMMAX_DB_DU || lsu_op == `LSOC1K_LSU_AMMIN_DB_DU ;

wire lsu_llw   = lsu_op == `LSOC1K_LSU_LL_W;
wire lsu_lld   = lsu_op == `LSOC1K_LSU_LL_D;
wire lsu_scw   = lsu_op == `LSOC1K_LSU_SC_W;
wire lsu_scd   = lsu_op == `LSOC1K_LSU_SC_D;

wire lsu_lw    = lsu_op == `LSOC1K_LSU_LD_W  || lsu_op == `LSOC1K_LSU_LDX_W  || lsu_op == `LSOC1K_LSU_LDGT_W || lsu_op == `LSOC1K_LSU_LDLE_W || lsu_op == `LSOC1K_LSU_IOCSRRD_W;
wire lsu_lwu   = lsu_op == `LSOC1K_LSU_LD_WU || lsu_op == `LSOC1K_LSU_LDX_WU ;
wire lsu_sw    = lsu_op == `LSOC1K_LSU_ST_W  || lsu_op == `LSOC1K_LSU_STX_W  || lsu_op == `LSOC1K_LSU_STGT_W || lsu_op == `LSOC1K_LSU_STLE_W || lsu_op == `LSOC1K_LSU_IOCSRWR_W ||
                 lsu_am_sw;
wire lsu_lb    = lsu_op == `LSOC1K_LSU_LD_B  || lsu_op == `LSOC1K_LSU_LDX_B  || lsu_op == `LSOC1K_LSU_LDGT_B || lsu_op == `LSOC1K_LSU_LDLE_B || lsu_op == `LSOC1K_LSU_IOCSRRD_B ||
                 lsu_op == `LSOC1K_LSU_PRELD || lsu_op == `LSOC1K_LSU_PRELDX ;
wire lsu_lbu   = lsu_op == `LSOC1K_LSU_LD_BU || lsu_op == `LSOC1K_LSU_LDX_BU ;
wire lsu_lh    = lsu_op == `LSOC1K_LSU_LD_H  || lsu_op == `LSOC1K_LSU_LDX_H  || lsu_op == `LSOC1K_LSU_LDGT_H || lsu_op == `LSOC1K_LSU_LDLE_H || lsu_op == `LSOC1K_LSU_IOCSRRD_H;
wire lsu_ld    = lsu_op == `LSOC1K_LSU_LD_D  || lsu_op == `LSOC1K_LSU_LDX_D  || lsu_op == `LSOC1K_LSU_LDGT_D || lsu_op == `LSOC1K_LSU_LDLE_D || lsu_op == `LSOC1K_LSU_IOCSRRD_D;
wire lsu_lhu   = lsu_op == `LSOC1K_LSU_LD_HU || lsu_op == `LSOC1K_LSU_LDX_HU ;
wire lsu_sb    = lsu_op == `LSOC1K_LSU_ST_B  || lsu_op == `LSOC1K_LSU_STX_B  || lsu_op == `LSOC1K_LSU_STGT_B || lsu_op == `LSOC1K_LSU_STLE_B || lsu_op == `LSOC1K_LSU_IOCSRWR_B;
wire lsu_sh    = lsu_op == `LSOC1K_LSU_ST_H  || lsu_op == `LSOC1K_LSU_STX_H  || lsu_op == `LSOC1K_LSU_STGT_H || lsu_op == `LSOC1K_LSU_STLE_H || lsu_op == `LSOC1K_LSU_IOCSRWR_H;
wire lsu_sd    = lsu_op == `LSOC1K_LSU_ST_D  || lsu_op == `LSOC1K_LSU_STX_D  || lsu_op == `LSOC1K_LSU_STGT_D || lsu_op == `LSOC1K_LSU_STLE_D || lsu_op == `LSOC1K_LSU_IOCSRWR_D ||
                 lsu_am_sd;

wire lsu_gt    = lsu_op == `LSOC1K_LSU_LDGT_W || lsu_op == `LSOC1K_LSU_LDGT_B || lsu_op == `LSOC1K_LSU_LDGT_H || lsu_op == `LSOC1K_LSU_LDGT_D ||
                 lsu_op == `LSOC1K_LSU_STGT_W || lsu_op == `LSOC1K_LSU_STGT_B || lsu_op == `LSOC1K_LSU_STGT_H || lsu_op == `LSOC1K_LSU_STGT_D ;
wire lsu_le    = lsu_op == `LSOC1K_LSU_LDLE_W || lsu_op == `LSOC1K_LSU_LDLE_B || lsu_op == `LSOC1K_LSU_LDLE_H || lsu_op == `LSOC1K_LSU_LDLE_D ||
                 lsu_op == `LSOC1K_LSU_STLE_W || lsu_op == `LSOC1K_LSU_STLE_B || lsu_op == `LSOC1K_LSU_STLE_H || lsu_op == `LSOC1K_LSU_STLE_D ;

wire lsu_idle  = lsu_op == `LSOC1K_LSU_IDLE;

//func
wire [`GRLEN-1:0] target      = base + offset;
wire [ 2:0] shift             = target[2:0];
wire kernel_mapped            = target[31:29] == 3'b111;
wire supervisor_mapped        = target[31:29] == 3'b110;
wire kernel_unmapped_uncached = target[31:29] == 3'b101;
wire kernel_unmapped          = target[31:29] == 3'b100;
wire user_mapped              = target[31] == 1'b0;

wire  lsu_wr = lsu_sw || lsu_sb || lsu_sh || lsu_scw || lsu_scd || lsu_sd;

assign data_req   = valid && !lsu_except && !eret && !exception && !res_valid && !tlb_req && !(lsu_op == `LSOC1K_LSU_IDLE);   // withdraw require when exception happens
assign data_addr  = target;
assign data_wr    = lsu_wr;

`ifdef LA64
assign data_wstrb = {8{lsu_sd||lsu_scd}} & (8'b11111111         ) |
                    {8{lsu_sw||lsu_scw}} & (8'b00001111 << shift) |
                    {8{lsu_sh         }} & (8'b00000011 << shift) |
                    {8{lsu_sb         }} & (8'b00000001 << shift) ;
`elsif LA32
assign data_wstrb = {4{lsu_sw||lsu_scw}} & (4'b1111              ) |
                    {4{lsu_sh         }} & (4'b0011 << shift[1:0]) |
                    {4{lsu_sb         }} & (4'b0001 << shift[1:0]) ;
`endif

`ifdef LA64
assign data_wdata = {64{lsu_sd||lsu_scd||tlb_req}} & {wdata} |
                    {64{lsu_sw||lsu_scw         }} & {wdata[31:0], wdata[31:0]} |
                    {64{lsu_sh                  }} & {wdata[15:0], wdata[15:0], wdata[15:0], wdata[15:0]} |
                    {64{lsu_sb                  }} & {wdata[7 :0], wdata[7 :0], wdata[7 :0], wdata[7 :0], wdata[7:0], wdata[7:0], wdata[7:0], wdata[7:0]};
`elsif LA32
assign data_wdata = {32{lsu_sw||lsu_scw||tlb_req}} & {wdata[31:0]} |
                    {32{lsu_sh                  }} & {wdata[15:0], wdata[15:0]} |
                    {32{lsu_sb                  }} & {wdata[7:0], wdata[7:0], wdata[7:0], wdata[7:0]};
`endif

assign data_prefetch = lsu_op == `LSOC1K_LSU_PRELD || lsu_op == `LSOC1K_LSU_PRELDX;
assign data_ll       = lsu_llw || lsu_lld;
assign data_sc       = lsu_scw || lsu_scd;
 
// except
wire lsu_load = lsu_ld || lsu_lw || lsu_llw || lsu_lld || lsu_lb  || lsu_lbu || lsu_lh || lsu_lhu || lsu_ld || lsu_lwu;
wire lsu_store= lsu_sb || lsu_sh || lsu_sd  || lsu_sw  || lsu_scw || lsu_scd;

wire am_addr_align_exc = (lsu_am_lw || lsu_am_sw || lsu_llw || lsu_scw) && target[1:0] != 2'd0 ||
                         (lsu_am_ld || lsu_am_sd || lsu_lld || lsu_scd) && target[2:0] != 3'd0 ;

wire cm_addr_align_exc = (lsu_ld||lsu_sd         ) && target[2:0] != 3'd0 || 
                         (lsu_lw||lsu_lwu||lsu_sw) && target[1:0] != 2'd0 || 
                         (lsu_lh||lsu_lhu||lsu_sh) && target[0]   != 1'd0 ; 

wire plv_0 = csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd0;
wire plv_1 = csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd1;
wire plv_2 = csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd2;
wire plv_3 = csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV] == 2'd3;

`ifdef LA64
wire align_check = csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL0] && plv_0 ||
                   csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL1] && plv_1 ||
                   csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL2] && plv_2 ||
                   csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL3] && plv_3 ;
`elsif LA32
wire align_check = 1'b1;
`endif

wire   lsu_bce      = 1'b0; // TODO
assign lsu_ale      = am_addr_align_exc || align_check && cm_addr_align_exc;
assign lsu_adem     = 1'b0;
assign lsu_except   = lsu_adem || lsu_ale || lsu_bce;

// signal process
always @(posedge clk) begin
    if (rst || change)                                       res_valid <= 1'd0;
    else if(data_addr_ok || lsu_except || exception || eret) res_valid <= valid;                          
end

assign lsu_finish = data_addr_ok || res_valid || (lsu_op == `LSOC1K_LSU_IDLE);

reg addr_ok_his;
always @(posedge clk) begin
    if (rst || change)    addr_ok_his <= 1'd0;
    else if(data_addr_ok) addr_ok_his <= 1'd1;
end

assign lsu_recv = addr_ok_his || data_addr_ok;

// badvaddr
reg  badvaddr_allow;
wire badvaddr_update = (lsu_except && valid) || (data_exception && tlb_finish);

always @(posedge clk) begin
    if (rst || exception)     badvaddr_allow <= 1'd1;
    else if(badvaddr_update)  badvaddr_allow <= 1'd0;
end

always @(posedge clk) if (badvaddr_update && badvaddr_allow) badvaddr <= tlb_finish ? data_badvaddr : target;

endmodule
