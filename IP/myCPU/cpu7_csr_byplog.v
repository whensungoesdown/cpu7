`include "common.vh"

module cpu7_csr_byplog(
   input  [`LSOC1K_CSR_BIT-1:0]        csr_raddr_d,
   input  [`LSOC1K_CSR_BIT-1:0]        csr_waddr_e,
   input  [`LSOC1K_CSR_BIT-1:0]        csr_waddr_m,
   input                               csr_wen_e,
   input                               csr_wen_m,
   output                              csr_mux_sel_csrrf,
   output                              csr_mux_sel_e,
   output                              csr_mux_sel_m
   );

   wire match_e;
   wire match_m;

   wire bypass_e;
   wire bypass_m;

   wire use_rf;
   wire use_e;
   wire use_m;

   assign match_e = (csr_raddr_d == csr_waddr_e);
   assign match_m = (csr_raddr_d == csr_waddr_m);
   
   assign bypass_e = csr_wen_e;
   assign bypass_m = csr_wen_m;

   assign use_e = match_e & bypass_e;
   assign use_m = match_m & bypass_m & ~use_e;
   assign use_rf = ~use_e & ~use_m;

   assign csr_mux_sel_m = use_m;
   assign csr_mux_sel_e = use_e;
   assign csr_mux_sel_csrrf = use_rf;
   
endmodule // cpu7_csr_byplog
