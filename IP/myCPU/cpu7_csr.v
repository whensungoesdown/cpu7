`include "common.vh"

module cpu7_csr(
   input                                clk,
   input                                resetn,
   output [`GRLEN-1:0]                  csr_rdata,
   input  [`LSOC1K_CSR_BIT-1:0]         csr_raddr,
   input  [`GRLEN-1:0]                  csr_wdata,
   input  [`LSOC1K_CSR_BIT-1:0]         csr_waddr,
   input                                csr_wen,

   output [`GRLEN-1:0]                  csr_eentry
   );



   //
   //  CRMD
   //
   
   wire [`GRLEN-1:0]       crmd;
   wire                    crmd_wen;
   assign crmd_wen = (csr_waddr == `LSOC1K_CSR_CRMD) && csr_wen;

   
   wire                    crmd_ie;
   wire                    crmd_ie_nxt;

   assign crmd_ie_nxt = csr_wdata[`CRMD_IE];

   dffe_s #(1) crmd_ie_reg (
      .din (crmd_ie_nxt),
      .en  (crmd_wen),
      .clk (clk),
      .q   (crmd_ie),
      .se(), .si(), .so());
   
   wire [1:0]             crmd_plv;
   wire [1:0]             crmd_plv_nxt;

   assign crmd_plv_nxt = csr_wdata[`CRMD_PLV];
   
   dffe_s #(2) crmd_plv_reg (
      .din (crmd_plv_nxt),
      .en  (crmd_wen),
      .clk (clk),
      .q   (crmd_plv),
      .se(), .si(), .so());

   
   assign crmd = {
		 29'b0,
		 crmd_ie,
		 crmd_plv
		 };


   //
   //  PRMD
   //

   wire [`GRLEN-1:0]      prmd;
   wire                   prmd_wen;
   assign prmd_wen = (csr_waddr == `LSOC1K_CSR_PRMD) && csr_wen;

   wire                   prmd_pie;
   wire                   prmd_pie_nxt;
   assign prmd_pie_nxt = csr_wdata[`LSOC1K_PRMD_PIE];

   dffe_s #(1) prmd_pie_reg (
      .din (prmd_pie_nxt),
      .en  (prmd_wen),
      .clk (clk),
      .q   (prmd_pie),
      .se(), .si(), .so());

   wire [1:0]             prmd_pplv;
   wire [1:0]             prmd_pplv_nxt;
   assign prmd_pplv_nxt = csr_wdata[`LSOC1K_PRMD_PPLV];

   dffe_s #(2) prmd_pplv_reg (
      .din (prmd_pplv_nxt),
      .en  (prmd_wen),
      .clk (clk),
      .q   (prmd_pplv),
      .se(), .si(), .so());
   

   assign prmd = {
		 29'b0,
                 prmd_pie,
                 prmd_pplv
		 };

   
   //
   //  ERA
   //

   wire [`GRLEN-1:0]       era;
   wire [`GRLEN-1:0]       era_nxt;
   wire                    era_wen;

   assign era_nxt = csr_wdata;
   assign era_wen = (csr_waddr == `LSOC1K_CSR_EPC) && csr_wen;  // EPC is ERA


   dffe_s #(`GRLEN) era_reg (
      .din (era_nxt),
      .en  (era_wen),
      .clk (clk),
      .q   (era),
      .se(), .si(), .so());
   

   //
   //  EENTRY
   //

   wire [`GRLEN-1:0]       eentry;
   wire [`GRLEN-1:0]       eentry_nxt;
   wire                    eentry_wen;

   assign eentry_nxt = csr_wdata;
   assign eentry_wen = (csr_waddr == `LSOC1K_CSR_EBASE) && csr_wen; // EBASE is EENTRY

   dffe_s #(`GRLEN) eentry_reg (
      .din (eentry_nxt),
      .en  (eentry_wen),
      .clk (clk),
      .q   (eentry),
      .se(), .si(), .so());

   assign csr_eentry = eentry;

   
   assign csr_rdata = {`GRLEN{csr_raddr == `LSOC1K_CSR_CRMD}}  & crmd   |
		      {`GRLEN{csr_raddr == `LSOC1K_CSR_PRMD}}  & prmd   |
		      {`GRLEN{csr_raddr == `LSOC1K_CSR_EPC}}   & era    |
		      {`GRLEN{csr_raddr == `LSOC1K_CSR_EBASE}} & eentry |
		      `GRLEN'b0;

endmodule // cpu7_csr
