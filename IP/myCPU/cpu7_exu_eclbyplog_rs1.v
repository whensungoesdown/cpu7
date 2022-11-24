`include "common.vh"
`include "decoded.vh"

module cpu7_exu_eclbyplog_rs1(
   input  [4:0]         rs_e,
   input  [4:0]         rd_m,
   input  [4:0]         rd_w,
   input                wen_m,
   input                wen_w,

   output               rs_mux_sel_rf,
   output               rs_mux_sel_m,
   output               rs_mux_sel_w
   );

   wire match_m;
   wire match_w;
   wire rs_is_nonzero;
   wire bypass;
   wire bypass_m;
   wire bypass_w;
   wire use_m;
   wire use_w;
   wire use_rf;
   

   assign match_m = (rs_e[4:0] == rd_m[4:0]);
   assign match_w = (rs_e[4:0] == rd_w[4:0]);

   assign rs_is_nonzero = rs_e[0]|rs_e[1]|rs_e[2]|rs_e[3]|rs_e[4];
   assign bypass = rs_is_nonzero;

   assign bypass_m = wen_m;
   assign bypass_w = wen_w;

   assign use_m = match_m & bypass_m;
   assign use_w = match_w & bypass_w & ~use_m;

   assign use_rf = ~use_w & ~use_m;

   assign rs_mux_sel_m = use_m & bypass;
   assign rs_mux_sel_w = use_w & bypass;
   assign rs_mux_sel_rf = use_rf;

   
endmodule // cpu7_exu_eclbyplog
