`include "common.vh"

module cpu7_csr(
   input                                clk,
   input                                resetn,
   output [`GRLEN-1:0]                  csr_rdata,
   input  [`LSOC1K_CSR_BIT-1:0]         csr_raddr,
   input  [`GRLEN-1:0]                  csr_wdata,
   input  [`LSOC1K_CSR_BIT-1:0]         csr_waddr,
   input                                csr_wen
   );

   wire [`GRLEN-1:0]       crmd;
   wire                    crmd_ie;
   wire                    crmd_ie_nxt;
   wire                    crmd_wen;

   assign crmd_ie_nxt = csr_wdata[`CRMD_IE];
   assign crmd_wen = (csr_waddr == `LSOC1K_CSR_CRMD) && csr_wen;

   dffe_s #(1) crmd_ie_reg (
      .din (crmd_ie_nxt),
      .en  (crmd_wen),
      .clk (clk),
      .q   (crmd_ie),
      .se(), .si(), .so());
   
   assign crmd = {
		 29'b0,
		 crmd_ie,
		 2'd0      // crmd_plv
		 };






   assign csr_rdata = {`GRLEN{csr_raddr == `LSOC1K_CSR_CRMD}} & crmd  |
			`GRLEN'b0;

endmodule // cpu7_csr
