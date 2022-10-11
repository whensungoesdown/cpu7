`include "common.vh"

// ALU module
module lsu_s2(
  input               clk,
  input               resetn,

  input               valid,
  input [`LSOC1K_LSU_CODE_BIT-1:0]lsu_op,
  input               lsu_recv,
  input [ 2:0]        lsu_shift,

  //cached memory interface
  output              data_recv,
  input               data_scsucceed,
  input   [`GRLEN-1:0]data_rdata,
  input               data_exception,
  input   [ 5:0]      data_excode,
  input   [`GRLEN-1:0]data_badvaddr,
  input               data_data_ok,

//result
  output [`GRLEN-1:0] read_result,
  output              lsu_res_valid,

  input               change,
  input               exception,
  output reg [`GRLEN-1:0]   badvaddr,
  output              badvaddr_valid
);

wire rst = !resetn;

//define
reg [ 3:0] work_state;
reg [`PABITS-1:0] addr_reg;
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

wire lsu_llw   = lsu_op == `LSOC1K_LSU_LL_W;
wire lsu_lld   = lsu_op == `LSOC1K_LSU_LL_D;
wire lsu_scw   = lsu_op == `LSOC1K_LSU_SC_W;
wire lsu_scd   = lsu_op == `LSOC1K_LSU_SC_D;

wire lsu_lw    = lsu_op == `LSOC1K_LSU_LD_W  || lsu_op == `LSOC1K_LSU_LDX_W  || lsu_op == `LSOC1K_LSU_LDGT_W || lsu_op == `LSOC1K_LSU_LDLE_W || lsu_op == `LSOC1K_LSU_IOCSRRD_W ||
                 lsu_am_lw || lsu_llw;
wire lsu_lwu   = lsu_op == `LSOC1K_LSU_LD_WU || lsu_op == `LSOC1K_LSU_LDX_WU ;
wire lsu_sw    = lsu_op == `LSOC1K_LSU_ST_W  || lsu_op == `LSOC1K_LSU_STX_W  || lsu_op == `LSOC1K_LSU_STGT_W || lsu_op == `LSOC1K_LSU_STLE_W || lsu_op == `LSOC1K_LSU_IOCSRWR_W ||
                 lsu_scw;
wire lsu_lb    = lsu_op == `LSOC1K_LSU_LD_B  || lsu_op == `LSOC1K_LSU_LDX_B  || lsu_op == `LSOC1K_LSU_LDGT_B || lsu_op == `LSOC1K_LSU_LDLE_B || lsu_op == `LSOC1K_LSU_IOCSRRD_B;
wire lsu_lbu   = lsu_op == `LSOC1K_LSU_LD_BU || lsu_op == `LSOC1K_LSU_LDX_BU ;
wire lsu_lh    = lsu_op == `LSOC1K_LSU_LD_H  || lsu_op == `LSOC1K_LSU_LDX_H  || lsu_op == `LSOC1K_LSU_LDGT_H || lsu_op == `LSOC1K_LSU_LDLE_H || lsu_op == `LSOC1K_LSU_IOCSRRD_H;
wire lsu_ld    = lsu_op == `LSOC1K_LSU_LD_D  || lsu_op == `LSOC1K_LSU_LDX_D  || lsu_op == `LSOC1K_LSU_LDGT_D || lsu_op == `LSOC1K_LSU_LDLE_D || lsu_op == `LSOC1K_LSU_IOCSRRD_D ||
                 lsu_am_ld || lsu_lld;
wire lsu_lhu   = lsu_op == `LSOC1K_LSU_LD_HU || lsu_op == `LSOC1K_LSU_LDX_HU ;
wire lsu_sb    = lsu_op == `LSOC1K_LSU_ST_B  || lsu_op == `LSOC1K_LSU_STX_B  || lsu_op == `LSOC1K_LSU_STGT_B || lsu_op == `LSOC1K_LSU_STLE_B || lsu_op == `LSOC1K_LSU_IOCSRWR_B;
wire lsu_sh    = lsu_op == `LSOC1K_LSU_ST_H  || lsu_op == `LSOC1K_LSU_STX_H  || lsu_op == `LSOC1K_LSU_STGT_H || lsu_op == `LSOC1K_LSU_STLE_H || lsu_op == `LSOC1K_LSU_IOCSRWR_H;
wire lsu_sd    = lsu_op == `LSOC1K_LSU_ST_D  || lsu_op == `LSOC1K_LSU_STX_D  || lsu_op == `LSOC1K_LSU_STGT_D || lsu_op == `LSOC1K_LSU_STLE_D || lsu_op == `LSOC1K_LSU_IOCSRWR_D ||
                 lsu_scd;

wire lsu_gt    = lsu_op == `LSOC1K_LSU_LDGT_W || lsu_op == `LSOC1K_LSU_LDGT_B || lsu_op == `LSOC1K_LSU_LDGT_H || lsu_op == `LSOC1K_LSU_LDGT_D ||
                 lsu_op == `LSOC1K_LSU_STGT_W || lsu_op == `LSOC1K_LSU_STGT_B || lsu_op == `LSOC1K_LSU_STGT_H || lsu_op == `LSOC1K_LSU_STGT_D ;
wire lsu_le    = lsu_op == `LSOC1K_LSU_LDLE_W || lsu_op == `LSOC1K_LSU_LDLE_B || lsu_op == `LSOC1K_LSU_LDLE_H || lsu_op == `LSOC1K_LSU_LDLE_D ||
                 lsu_op == `LSOC1K_LSU_STLE_W || lsu_op == `LSOC1K_LSU_STLE_B || lsu_op == `LSOC1K_LSU_STLE_H || lsu_op == `LSOC1K_LSU_STLE_D ;

wire prefetch = lsu_op == `LSOC1K_LSU_PRELD || lsu_op == `LSOC1K_LSU_PRELDX;

wire lsu_load = lsu_lw || lsu_llw || lsu_lld || lsu_lb  || lsu_lbu || lsu_lh || lsu_lhu;
wire lsu_store= lsu_sb || lsu_sh  || lsu_sw  || lsu_scw || lsu_scd;

wire [2 :0] shift = lsu_shift;

wire  lsu_wr = lsu_sw || lsu_sb || lsu_sh || lsu_scw || lsu_scd || lsu_sd;

assign data_recv  = lsu_recv && !res_valid;

//result process
wire [`GRLEN-1:0] data_rdata_input = data_rdata;

wire [4:0] align_mode;

assign align_mode[0] = !(lsu_scw || lsu_scd) && (lsu_ld||lsu_lld);
assign align_mode[1] = !(lsu_scw || lsu_scd) && (lsu_lw||lsu_llw||lsu_lwu);
assign align_mode[2] = !(lsu_scw || lsu_scd) && (lsu_lh||lsu_lhu);
assign align_mode[3] = !(lsu_scw || lsu_scd) && (lsu_lb||lsu_lbu);
assign align_mode[4] = !(lsu_scw || lsu_scd) && (lsu_lbu||lsu_lhu||lsu_lwu);


`ifdef LA64
wire [63:0] lsu_align_res=({64{shift == 3'b000 &&                   align_mode[0]}} & data_rdata_input) | // ld.d
                          ({64{shift == 3'b000 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[ 7]}},data_rdata_input[ 7: 0]}) | // ld.b
                          ({64{shift == 3'b001 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[15]}},data_rdata_input[15: 8]}) |
                          ({64{shift == 3'b010 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[23]}},data_rdata_input[23:16]}) |
                          ({64{shift == 3'b011 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[31]}},data_rdata_input[31:24]}) |
                          ({64{shift == 3'b100 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[39]}},data_rdata_input[39:32]}) |
                          ({64{shift == 3'b101 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[47]}},data_rdata_input[47:40]}) |
                          ({64{shift == 3'b110 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[55]}},data_rdata_input[55:48]}) |
                          ({64{shift == 3'b111 && !align_mode[4] && align_mode[3]}} & {{56{data_rdata_input[63]}},data_rdata_input[63:56]}) |
                          ({64{shift == 3'b000 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[ 7: 0]}) |
                          ({64{shift == 3'b001 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[15: 8]}) |
                          ({64{shift == 3'b010 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[23:16]}) |
                          ({64{shift == 3'b011 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[31:24]}) |
                          ({64{shift == 3'b100 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[39:32]}) |
                          ({64{shift == 3'b101 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[47:40]}) |
                          ({64{shift == 3'b110 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[55:48]}) |
                          ({64{shift == 3'b111 &&  align_mode[4] && align_mode[3]}} & {56'd0,data_rdata_input[63:56]}) |
                          ({64{shift == 3'b000 && !align_mode[4] && align_mode[2]}} & {{48{data_rdata_input[15]}},data_rdata_input[15: 0]}) | // ld.h
                          ({64{shift == 3'b010 && !align_mode[4] && align_mode[2]}} & {{48{data_rdata_input[31]}},data_rdata_input[31:16]}) |
                          ({64{shift == 3'b100 && !align_mode[4] && align_mode[2]}} & {{48{data_rdata_input[47]}},data_rdata_input[47:32]}) |
                          ({64{shift == 3'b110 && !align_mode[4] && align_mode[2]}} & {{48{data_rdata_input[63]}},data_rdata_input[63:48]}) |
                          ({64{shift == 3'b000 &&  align_mode[4] && align_mode[2]}} & {48'd0,data_rdata_input[15: 0]}) |
                          ({64{shift == 3'b010 &&  align_mode[4] && align_mode[2]}} & {48'd0,data_rdata_input[31:16]}) |
                          ({64{shift == 3'b100 &&  align_mode[4] && align_mode[2]}} & {48'd0,data_rdata_input[47:32]}) |
                          ({64{shift == 3'b110 &&  align_mode[4] && align_mode[2]}} & {48'd0,data_rdata_input[63:48]}) |
                          ({64{shift == 3'b000 && !align_mode[4] && align_mode[1]}} & {{32{data_rdata_input[31]}},data_rdata_input[31: 0]}) | // ld.w
                          ({64{shift == 3'b100 && !align_mode[4] && align_mode[1]}} & {{32{data_rdata_input[63]}},data_rdata_input[63:32]}) |
                          ({64{shift == 3'b000 &&  align_mode[4] && align_mode[1]}} & {32'd0,data_rdata_input[31: 0]}) |
                          ({64{shift == 3'b100 &&  align_mode[4] && align_mode[1]}} & {32'd0,data_rdata_input[63:32]}) |
                          ({64{!align_mode[4] && !align_mode[3] && !align_mode[2] && !align_mode[1]}} & {63'd0,data_scsucceed}) ;
`elsif LA32
wire [31:0] lsu_align_res=({32{shift[1:0] == 2'b00 && !align_mode[4] && align_mode[3]}} & {{24{data_rdata_input[ 7]}},data_rdata_input[ 7: 0]}) | // ld.b
                          ({32{shift[1:0] == 2'b01 && !align_mode[4] && align_mode[3]}} & {{24{data_rdata_input[15]}},data_rdata_input[15: 8]}) |
                          ({32{shift[1:0] == 2'b10 && !align_mode[4] && align_mode[3]}} & {{24{data_rdata_input[23]}},data_rdata_input[23:16]}) |
                          ({32{shift[1:0] == 2'b11 && !align_mode[4] && align_mode[3]}} & {{24{data_rdata_input[31]}},data_rdata_input[31:24]}) |
                          ({32{shift[1:0] == 2'b00 &&  align_mode[4] && align_mode[3]}} & {24'd0,data_rdata_input[ 7: 0]}) |
                          ({32{shift[1:0] == 2'b01 &&  align_mode[4] && align_mode[3]}} & {24'd0,data_rdata_input[15: 8]}) |
                          ({32{shift[1:0] == 2'b10 &&  align_mode[4] && align_mode[3]}} & {24'd0,data_rdata_input[23:16]}) |
                          ({32{shift[1:0] == 2'b11 &&  align_mode[4] && align_mode[3]}} & {24'd0,data_rdata_input[31:24]}) |
                          ({32{shift[1:0] == 2'b00 && !align_mode[4] && align_mode[2]}} & {{16{data_rdata_input[15]}},data_rdata_input[15: 0]}) | // ld.h
                          ({32{shift[1:0] == 2'b10 && !align_mode[4] && align_mode[2]}} & {{16{data_rdata_input[31]}},data_rdata_input[31:16]}) |
                          ({32{shift[1:0] == 2'b00 &&  align_mode[4] && align_mode[2]}} & {16'd0,data_rdata_input[15: 0]}) |
                          ({32{shift[1:0] == 2'b10 &&  align_mode[4] && align_mode[2]}} & {16'd0,data_rdata_input[31:16]}) |
                          ({32{shift[1:0] == 2'b00 && !align_mode[4] && align_mode[1]}} & data_rdata_input[31: 0]) | // ld.w|
                          ({32{shift[1:0] == 2'b00 &&  align_mode[4] && align_mode[1]}} & data_rdata_input[31: 0]) |
                          ({32{!align_mode[4] && !align_mode[3] && !align_mode[2] && !align_mode[1]}} & {31'd0,data_scsucceed}) ;
`endif

assign read_result   = lsu_align_res; // ensure that read_result always display valid data regardless of data_data_ok

// signal process
always @(posedge clk) begin
    if     (rst || change) res_valid <= 1'd0;
    else if(data_data_ok || prefetch || data_exception) res_valid <= 1'd1;                          
end

assign lsu_res_valid = data_data_ok || data_exception || res_valid || prefetch || !valid || (lsu_op == `LSOC1K_LSU_IDLE);

// badvaddr
reg  badvaddr_allow;
wire badvaddr_update = data_exception && valid;

always @(posedge clk) begin
    if (rst || exception)     badvaddr_allow <= 1'd1;
    else if(badvaddr_update)  badvaddr_allow <= 1'd0;
end
always @(posedge clk) if (badvaddr_update && badvaddr_allow) badvaddr <= data_badvaddr;

assign badvaddr_valid = !badvaddr_allow;

endmodule


/// lsu
// wire [7 :0] rdata_b     = wb_align_res >> (8 * wb_align_shift);
// wire [15:0] rdata_h     = wb_align_res >> (8 * wb_align_shift);
// wire [31:0] rdata_w     = wb_align_res >> (8 * wb_align_shift);
// wire [63:0] rdata_b_sx  = {{56{rdata_b[7]}}, rdata_b};
// wire [63:0] rdata_b_zx  = {56'd0, rdata_b};
// wire [63:0] rdata_h_sx  = {{48{rdata_h[15]}}, rdata_h};
// wire [63:0] rdata_h_zx  = {48'd0, rdata_h};
// wire [63:0] rdata_w_sx  = {{32{rdata_w[31]}}, rdata_w};
// wire [63:0] rdata_w_zx  = {32'd0, rdata_w};

// wire [63:0] rdata_b_res = {64{!wb_align_mode[4]}} & rdata_b_sx |
//                           {64{ wb_align_mode[4]}} & rdata_b_zx ;
    
// wire [63:0] rdata_h_res = {64{!wb_align_mode[4]}} & rdata_h_sx |
//                           {64{ wb_align_mode[4]}} & rdata_h_zx ;

// wire [63:0] rdata_w_res = {64{!wb_align_mode[4]}} & rdata_w_sx |
//                           {64{ wb_align_mode[4]}} & rdata_w_zx ;

// wire [63:0] lsu_align_res = {64{wb_align_mode[1]}} & rdata_w_res  |
//                             {64{wb_align_mode[2]}} & rdata_h_res  |
//                             {64{wb_align_mode[3]}} & rdata_b_res  ;

// wire [63:0] rdata_b_sx  = ({64{wb_align_shift == 3'b000}} & {{56{wb_align_res[ 7]}},wb_align_res[ 7: 0]}) |
//                           ({64{wb_align_shift == 3'b001}} & {{56{wb_align_res[15]}},wb_align_res[15: 8]}) |
//                           ({64{wb_align_shift == 3'b010}} & {{56{wb_align_res[23]}},wb_align_res[23:16]}) |
//                           ({64{wb_align_shift == 3'b011}} & {{56{wb_align_res[31]}},wb_align_res[31:24]}) |
//                           ({64{wb_align_shift == 3'b100}} & {{56{wb_align_res[39]}},wb_align_res[39:32]}) |
//                           ({64{wb_align_shift == 3'b101}} & {{56{wb_align_res[47]}},wb_align_res[47:40]}) |
//                           ({64{wb_align_shift == 3'b110}} & {{56{wb_align_res[55]}},wb_align_res[55:48]}) |
//                           ({64{wb_align_shift == 3'b111}} & {{56{wb_align_res[63]}},wb_align_res[63:56]}) ;
// wire [63:0] rdata_b_zx  = ({64{wb_align_shift == 3'b000}} & {56'd0,wb_align_res[ 7: 0]}) |
//                           ({64{wb_align_shift == 3'b001}} & {56'd0,wb_align_res[15: 8]}) |
//                           ({64{wb_align_shift == 3'b010}} & {56'd0,wb_align_res[23:16]}) |
//                           ({64{wb_align_shift == 3'b011}} & {56'd0,wb_align_res[31:24]}) |
//                           ({64{wb_align_shift == 3'b100}} & {56'd0,wb_align_res[39:32]}) |
//                           ({64{wb_align_shift == 3'b101}} & {56'd0,wb_align_res[47:40]}) |
//                           ({64{wb_align_shift == 3'b110}} & {56'd0,wb_align_res[55:48]}) |
//                           ({64{wb_align_shift == 3'b111}} & {56'd0,wb_align_res[63:56]}) ;
// wire [63:0] rdata_h_sx  = ({64{wb_align_shift == 3'b000}} & {{48{wb_align_res[15]}},wb_align_res[15: 0]}) |
//                           ({64{wb_align_shift == 3'b010}} & {{48{wb_align_res[31]}},wb_align_res[31:16]}) |
//                           ({64{wb_align_shift == 3'b100}} & {{48{wb_align_res[47]}},wb_align_res[47:32]}) |
//                           ({64{wb_align_shift == 3'b110}} & {{48{wb_align_res[63]}},wb_align_res[63:48]}) ;
// wire [63:0] rdata_h_zx  = ({64{wb_align_shift == 3'b000}} & {48'd0,wb_align_res[15: 0]}) |
//                           ({64{wb_align_shift == 3'b010}} & {48'd0,wb_align_res[31:16]}) |
//                           ({64{wb_align_shift == 3'b100}} & {48'd0,wb_align_res[47:32]}) |
//                           ({64{wb_align_shift == 3'b110}} & {48'd0,wb_align_res[63:48]}) ;
// wire [63:0] rdata_w_sx  = ({64{wb_align_shift == 3'b000}} & {{32{wb_align_res[31]}},wb_align_res[31: 0]}) |
//                           ({64{wb_align_shift == 3'b100}} & {{32{wb_align_res[63]}},wb_align_res[63:32]}) ;
// wire [63:0] rdata_w_zx  = ({64{wb_align_shift == 3'b000}} & {32'd0,wb_align_res[31: 0]}) |
//                           ({64{wb_align_shift == 3'b100}} & {32'd0,wb_align_res[63:32]}) ;

// wire [63:0] rdata_b_res = ({64{wb_align_shift == 3'b000 && !wb_align_mode[4]}} & {{56{wb_align_res[ 7]}},wb_align_res[ 7: 0]}) |
//                           ({64{wb_align_shift == 3'b001 && !wb_align_mode[4]}} & {{56{wb_align_res[15]}},wb_align_res[15: 8]}) |
//                           ({64{wb_align_shift == 3'b010 && !wb_align_mode[4]}} & {{56{wb_align_res[23]}},wb_align_res[23:16]}) |
//                           ({64{wb_align_shift == 3'b011 && !wb_align_mode[4]}} & {{56{wb_align_res[31]}},wb_align_res[31:24]}) |
//                           ({64{wb_align_shift == 3'b100 && !wb_align_mode[4]}} & {{56{wb_align_res[39]}},wb_align_res[39:32]}) |
//                           ({64{wb_align_shift == 3'b101 && !wb_align_mode[4]}} & {{56{wb_align_res[47]}},wb_align_res[47:40]}) |
//                           ({64{wb_align_shift == 3'b110 && !wb_align_mode[4]}} & {{56{wb_align_res[55]}},wb_align_res[55:48]}) |
//                           ({64{wb_align_shift == 3'b111 && !wb_align_mode[4]}} & {{56{wb_align_res[63]}},wb_align_res[63:56]}) |
//                           ({64{wb_align_shift == 3'b000 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[ 7: 0]}) |
//                           ({64{wb_align_shift == 3'b001 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[15: 8]}) |
//                           ({64{wb_align_shift == 3'b010 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[23:16]}) |
//                           ({64{wb_align_shift == 3'b011 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[31:24]}) |
//                           ({64{wb_align_shift == 3'b100 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[39:32]}) |
//                           ({64{wb_align_shift == 3'b101 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[47:40]}) |
//                           ({64{wb_align_shift == 3'b110 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[55:48]}) |
//                           ({64{wb_align_shift == 3'b111 &&  wb_align_mode[4]}} & {56'd0,wb_align_res[63:56]}) ;

// wire [63:0] rdata_h_res = ({64{wb_align_shift == 3'b000 && !wb_align_mode[4]}} & {{48{wb_align_res[15]}},wb_align_res[15: 0]}) |
//                           ({64{wb_align_shift == 3'b010 && !wb_align_mode[4]}} & {{48{wb_align_res[31]}},wb_align_res[31:16]}) |
//                           ({64{wb_align_shift == 3'b100 && !wb_align_mode[4]}} & {{48{wb_align_res[47]}},wb_align_res[47:32]}) |
//                           ({64{wb_align_shift == 3'b110 && !wb_align_mode[4]}} & {{48{wb_align_res[63]}},wb_align_res[63:48]}) |
//                           ({64{wb_align_shift == 3'b000 &&  wb_align_mode[4]}} & {48'd0,wb_align_res[15: 0]}) |
//                           ({64{wb_align_shift == 3'b010 &&  wb_align_mode[4]}} & {48'd0,wb_align_res[31:16]}) |
//                           ({64{wb_align_shift == 3'b100 &&  wb_align_mode[4]}} & {48'd0,wb_align_res[47:32]}) |
//                           ({64{wb_align_shift == 3'b110 &&  wb_align_mode[4]}} & {48'd0,wb_align_res[63:48]}) ;

// wire [63:0] rdata_w_res = ({64{wb_align_shift == 3'b000 && !wb_align_mode[4]}} & {{32{wb_align_res[31]}},wb_align_res[31: 0]}) |
//                           ({64{wb_align_shift == 3'b100 && !wb_align_mode[4]}} & {{32{wb_align_res[63]}},wb_align_res[63:32]}) |
//                           ({64{wb_align_shift == 3'b000 &&  wb_align_mode[4]}} & {32'd0,wb_align_res[31: 0]}) |
//                           ({64{wb_align_shift == 3'b100 &&  wb_align_mode[4]}} & {32'd0,wb_align_res[63:32]}) ;
