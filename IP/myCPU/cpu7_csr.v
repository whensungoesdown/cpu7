`include "common.vh"

module cpu7_csr(
   input                                clk,
   input                                resetn,
   output [`GRLEN-1:0]                  csr_rdata,
   input  [`LSOC1K_CSR_BIT-1:0]         csr_raddr,
   input  [`GRLEN-1:0]                  csr_wdata,
   input  [`LSOC1K_CSR_BIT-1:0]         csr_waddr,
   input                                csr_wen,

   output [`GRLEN-1:0]                  csr_eentry,
   output [`GRLEN-1:0]                  csr_era,
   input                                ecl_csr_ale_e,
   input  [`GRLEN-1:0]                  ifu_exu_pc_e
   );


   wire exception;
   assign exception = ecl_csr_ale_e; // | other exception

   //
   //  CRMD
   //
   
   wire [`GRLEN-1:0]       crmd;
   wire                    crmd_wen;
   assign crmd_wen = (csr_waddr == `LSOC1K_CSR_CRMD) && csr_wen;

   
   wire                    crmd_ie;
   wire                    crmd_ie_wdata;
   wire                    crmd_ie_nxt;

   assign crmd_ie_wdata = csr_wdata[`CRMD_IE];

   dp_mux2es #(1) crmd_ie_mux(
      .dout (crmd_ie_nxt),
      .in0  (crmd_ie_wdata),
      .in1  (1'b0),
      .sel  (exception));
   
   dffe_s #(1) crmd_ie_reg (
      .din (crmd_ie_nxt),
      .en  (crmd_wen | exception),
      .clk (clk),
      .q   (crmd_ie),
      .se(), .si(), .so());
   
   wire [1:0]             crmd_plv;
   wire [1:0]             crmd_plv_wdata;
   wire [1:0]             crmd_plv_nxt;

   assign crmd_plv_wdata = csr_wdata[`CRMD_PLV];

   dp_mux2es #(2) crmd_plv_mux(
      .dout (crmd_plv_nxt),
      .in0  (crmd_plv_wdata),
      .in1  (2'b0),
      .sel  (exception));
   
   dffe_s #(2) crmd_plv_reg (
      .din (crmd_plv_nxt),
      .en  (crmd_wen | exception),
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
   wire                   prmd_pie_wdata;
   wire                   prmd_pie_nxt;
   assign prmd_pie_wdata = csr_wdata[`LSOC1K_PRMD_PIE];

   dp_mux2es #(1) prmd_pie_mux(
      .dout (prmd_pie_nxt),
      .in0  (prmd_pie_wdata),
      .in1  (crmd_ie),
      .sel  (exception));
   
   dffe_s #(1) prmd_pie_reg (
      .din (prmd_pie_nxt),
      .en  (prmd_wen | exception),
      .clk (clk),
      .q   (prmd_pie),
      .se(), .si(), .so());


   wire [1:0]             prmd_pplv;
   wire [1:0]             prmd_pplv_wdata;
   wire [1:0]             prmd_pplv_nxt;
   assign prmd_pplv_wdata = csr_wdata[`LSOC1K_PRMD_PPLV];

   dp_mux2es #(2) prmd_pplv_mux(
      .dout (prmd_pplv_nxt),
      .in0  (prmd_pplv_wdata),
      .in1  (crmd_plv),
      .sel  (exception));

   dffe_s #(2) prmd_pplv_reg (
      .din (prmd_pplv_nxt),
      .en  (prmd_wen | exception),
      .clk (clk),
      .q   (prmd_pplv),
      .se(), .si(), .so());
   

   assign prmd = {
		 29'b0,
                 prmd_pie,
                 prmd_pplv
		 };

   
   //
   //  ERA 0x6
   //

   wire [`GRLEN-1:0]       era;
   wire [`GRLEN-1:0]       era_wdata;
   wire [`GRLEN-1:0]       era_nxt;
   wire                    era_wen;

   assign era_wen = (csr_waddr == `LSOC1K_CSR_EPC) && csr_wen;  // EPC is ERA

   assign era_wdata = csr_wdata;

   // larger mux when more types of exception supported
   dp_mux2es #(`GRLEN) era_mux(
      .dout (era_nxt),
      .in0  (era_wdata),
      .in1  (ifu_exu_pc_e),
      .sel  (ecl_csr_ale_e));

   dffe_s #(`GRLEN) era_reg (
      .din (era_nxt),
      .en  (era_wen | exception),
      .clk (clk),
      .q   (era),
      .se(), .si(), .so());
   
   assign csr_era = era;

   //
   //  EENTRY 0xc
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
