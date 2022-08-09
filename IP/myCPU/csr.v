`include "common.vh"

module csr(
    input               clk,
    input               resetn,
    
    input  [7       :0] intrpt,
    // tlb inst 
    input               tlbp         ,
    input               tlbr         ,
    input               ldpte        ,
    input  [`GRLEN-1:0] tlbrp_index  ,
    input  [`GRLEN-1:0] tlbr_entryhi ,
    input  [`GRLEN-1:0] tlbr_entrylo1,
    input  [`GRLEN-1:0] tlbr_entrylo0,
    input  [`GRLEN-1:0] tlbr_asid    ,

    // cache inst
    input  [ 1      :0] cache_op_1    ,
    input  [ 1      :0] cache_op_2    ,
    input  [`GRLEN-1:0] cache_taglo_i ,
    input  [`GRLEN-1:0] cache_taghi_i ,
    input  [`GRLEN-1:0] cache_datalo_i,
    input  [`GRLEN-1:0] cache_datahi_i,
    
    // csrrd/wr/xchg
    output [`GRLEN-1         :0] rdata,
    input  [`LSOC1K_CSR_BIT-1:0] raddr,
    input  [`GRLEN-1         :0] wdata,
    input  [`LSOC1K_CSR_BIT-1:0] waddr,
    input                        wen  ,

    input  [`GRLEN-1          :0] llbctl,

    // wb_exception commit
    input                wb_exception,
    input   [5       :0] wb_exccode  ,
    input                wb_esubcode,
    input   [`GRLEN-1:0] wb_epc      ,
    input   [`GRLEN-1:0] wb_badvaddr ,
    input   [31      :0] wb_badinstr ,
    input                wb_eret     ,

    // output
    output [`LSOC1K_CSR_OUTPUT_BIT-1:0] csr_output,
    output [`GRLEN-1                :0] dmw0      ,
    output [`GRLEN-1                :0] dmw1      ,
    output [`GRLEN-1                :0] crmd      ,
  `ifdef GS264C_64BIT
    output [ 5                      :0] ftpgsize  ,
  `endif

    output  [`GRLEN-1:0] epc_addr_out,
    output  [`GRLEN-1:0] eret_epc_out,
    output               shield      ,
    output               int_except  ,
    output  reg          status_erl  ,
    output  reg          status_exl  ,
    output  reg          status_bev  , 
    output  reg          cause_iv    ,
    output  reg [ 2:0]   config_k0   ,
    output  reg [17:0]   ebase_exceptionbase,
    output  [`GRLEN-1:0] index_out   ,
    output  [`GRLEN-1:0] entryhi_out ,
    output  [`GRLEN-1:0] entrylo0_out,
    output  [`GRLEN-1:0] entrylo1_out,
    output  [`GRLEN-1:0] asid_out    ,
    output  [5       :0] ecode_out   ,
    `ifdef GS264C_64BIT
    output  [ 3      :0] rbits_out   ,
    output               istlbr_out  ,
    `endif
    output  [`GRLEN-1:0] taglo0_out  ,
    output  [`GRLEN-1:0] taghi0_out  ,
    output  [`GRLEN-1:0] tlbrebase   ,
    output  [`GRLEN-1:0] ebase   
);
// define
reg  [`GRLEN-1:0] epc;
wire [63:0] cause;
wire [63:0] status;
reg  [`GRLEN-1:0] badvaddr;

wire rst = !resetn;

wire tlb_refill    = wb_exception && wb_exccode == `EXC_TLBR;
wire cache_error   = wb_exception && wb_exccode == `EXC_ERROR;

`ifdef GS264C_64BIT
  wire page_except   = wb_exception /*&& wb_exccode ==*/ && !(tlb_refill || cache_error); // TODO
`else
  wire page_except   = wb_exception && (wb_exccode == `EXC_PIL || wb_exccode == `EXC_PIS || wb_exccode == `EXC_PIF ||
                                        wb_exccode == `EXC_PWE || wb_exccode == `EXC_PPI || tlb_refill );
`endif

`ifdef GS264C_64BIT
  wire common_except = wb_exception && !(tlb_refill || cache_error);
`else
  wire common_except = wb_exception;
`endif

wire [1:0] eret_plv  = `ifdef GS264C_64BIT
                       errctl_iserr   ? errctl_pplv  :
                       tlbrepc_istlbr ? tlbrprmd_pplv:
                       `endif
                                        prmd_pplv    ;

wire       eret_ie   = `ifdef GS264C_64BIT
                       errctl_iserr   ? errctl_pie   :
                       tlbrepc_istlbr ? tlbrprmd_pie :
                       `endif
                                        prmd_pie     ;
`ifdef GS264C_64BIT
wire       eret_we   = errctl_iserr   ? errctl_pwe   :
                       tlbrepc_istlbr ? tlbrprmd_pwe :
                                        prmd_pwe     ;
`endif

wire       eret_da   = `ifdef GS264C_64BIT
                       errctl_iserr   ? errctl_pda   :
                       tlbrepc_istlbr ? 1'b0         :
                       `else
                       estat_ecode == 6'h3f ? 1'b0   :
                       `endif
                                        crmd_da      ;

wire       eret_pg   = `ifdef GS264C_64BIT
                       errctl_iserr   ? errctl_ppg   :
                       tlbrepc_istlbr ? 1'b1         :
                       `else
                       estat_ecode == 6'h3f ? 1'b1   :
                       `endif
                                        crmd_pg      ;

wire [1:0] eret_datf = `ifdef GS264C_64BIT
                       errctl_iserr   ? errctl_pdatf :
                       `endif
                                        crmd_datf    ;

wire [1:0] eret_datm = `ifdef GS264C_64BIT
                       errctl_iserr   ? errctl_pdatm :
                       `endif
                                        crmd_datm    ;

// CRMD 0x0_0_0
reg [1:0] crmd_plv;
reg       crmd_ie;
reg       crmd_da;
reg       crmd_pg;
reg [1:0] crmd_datf;
reg [1:0] crmd_datm;
reg       crmd_we;
assign crmd = {
  `ifdef GS264C_64BIT
    32'b0,    //63:32
    22'b0,    //31:10
    crmd_we  ,//9
  `else
    23'b0,    //31:9
  `endif
    crmd_datm,//8:7
    crmd_datf,//6:5
    crmd_pg,  //4
    crmd_da,  //3
    crmd_ie,  //2
    crmd_plv  //1:0
};
wire crmd_wen = wen && waddr == `LSOC1K_CSR_CRMD;
always @(posedge clk) begin
    //crmd_plv
    if (rst || wb_exception) crmd_plv <= 2'b0;
    else if (wb_eret) crmd_plv <= eret_plv;
    else if (crmd_wen) crmd_plv <= wdata[`CRMD_PLV];
    //crmd_ie
    if (rst) crmd_ie <= 1'b0;
    else if (wb_exception) crmd_ie <= 1'b0;
    else if (wb_eret) crmd_ie <= eret_ie;
    else if (crmd_wen) crmd_ie <= wdata[`CRMD_IE];
    //crmd_da
    if (rst || tlb_refill) crmd_da <= 1'b1;
    else if (wb_eret) crmd_da <= eret_da;
    else if (crmd_wen) crmd_da <= wdata[`CRMD_DA];
    //crmd_pg
    if (rst || tlb_refill) crmd_pg <= 1'b0;
    else if (wb_eret) crmd_pg <= eret_pg;
    else if (crmd_wen) crmd_pg <= wdata[`CRMD_PG];
    //crmd_datf
    if (rst || cache_error) crmd_datf <= 2'b0;
    else if(wb_eret) crmd_datf <= eret_datf;
    //else if (crmd_wen) crmd_datf <= (wdata[`CRMD_PG])? 2'b01 : wdata[`CRMD_DATF]; //TODO
    else if (crmd_wen) crmd_datf <= wdata[`CRMD_DATF];
    //crmd_datm
    if (rst || cache_error) crmd_datm <= 2'b0;
    else if(wb_eret) crmd_datm <= eret_datm;
    //else if (crmd_wen) crmd_datm <= (wdata[`CRMD_PG])? 2'b01 : wdata[`CRMD_DATM]; //TODO
    else if (crmd_wen) crmd_datm <= wdata[`CRMD_DATM];
  `ifdef GS264C_64BIT
    //crmd_we
    if (rst || wb_exception) crmd_we <= 1'b0;
    else if (wb_eret) crmd_we <= eret_we;
    else if (crmd_wen) crmd_we <= wdata[`CRMD_WE];
  `endif
end

// PRMD 0x0_0_1
reg [1:0] prmd_pplv;
reg       prmd_pie;
reg       prmd_pwe;
wire [`GRLEN-1:0] prmd = {
  `ifdef GS264C_64BIT
    32'b0,     //63:32
    28'b0,     //31:4
    prmd_pwe,  //3
  `else
    29'b0,
  `endif
    prmd_pie,  //2
    prmd_pplv  //1:0
};
wire prmd_wen = wen && waddr == `LSOC1K_CSR_PRMD;
always @(posedge clk) begin
    //prmd_pplv
    if (common_except) prmd_pplv <= crmd_plv;
    else if (prmd_wen) prmd_pplv <= wdata[`LSOC1K_PRMD_PPLV];
    //prmd_pie
    if (common_except) prmd_pie <= crmd_ie;
    else if (prmd_wen) prmd_pie <= wdata[`LSOC1K_PRMD_PIE];
  `ifdef GS264C_64BIT
    //prmd_pwe
    if (common_except) prmd_pwe <= crmd_we;
    else if (prmd_wen) prmd_pwe <= wdata[`LSOC1K_PRMD_PWE];
  `endif
end

// EUEN 0X0_0_2
reg euen_bte;
reg euen_asxe;
reg euen_sxe;
reg euen_fpe;
wire [`GRLEN-1:0] euen = {
  `ifdef GS264C_64BIT
    32'b0, //63:32
    28'b0, //31:4
    euen_bte,
    euen_asxe,
    euen_sxe,
  `else
    31'b0,
  `endif
    euen_fpe
};
wire euen_wen = wen && waddr == `LSOC1K_CSR_EUEN;
always @(posedge clk) begin
  `ifdef GS264C_64BIT
    //euen_bte
    if (rst) euen_bte <= 1'b0;  // TODO: whether need to rst
    else if (euen_wen) euen_bte <= wdata[`LSOC1K_EUEN_BTE];
    //euen_asxe
    if (rst) euen_asxe <= 1'b0;  // TODO: whether need to rst
    else if (euen_wen) euen_asxe <= wdata[`LSOC1K_EUEN_ASXE];
    //euen_sxe
    if (rst) euen_sxe <= 1'b0;  // TODO: whether need to rst
    else if (euen_wen) euen_sxe <= wdata[`LSOC1K_EUEN_SXE];
  `endif
    //euen_fpe
    if (rst) euen_fpe <= 1'b0;  // TODO: whether need to rst
    else if (euen_wen) euen_fpe <= wdata[`LSOC1K_EUEN_FPE];
end

`ifdef GS264C_64BIT
// TODO: 
// TODO: initialize?
// MISC 0x0_0_3
reg misc_va32l1;
reg misc_va32l2;
reg misc_va32l3;
reg misc_drdtl1;
reg misc_drdtl2;
reg misc_drdtl3;
reg misc_rpcntl1;
reg misc_rpcntl2;
reg misc_rpcntl3;
reg misc_alcl0;
reg misc_alcl1;
reg misc_alcl2;
reg misc_alcl3;
reg misc_dwpl0;
reg misc_dwpl1;
reg misc_dwpl2;
wire [63:0] misc = {
    32'b0,        //63:32
    13'b0,        //31:19
    misc_dwpl2,   //18
    misc_dwpl1,   //17
    misc_dwpl0,   //16
    misc_alcl3,   //15
    misc_alcl2,   //14
    misc_alcl1,   //13
    misc_alcl0,   //12
    misc_rpcntl3, //11
    misc_rpcntl2, //10
    misc_rpcntl1, //9
    1'b0,         //8
    misc_drdtl3,  //7
    misc_drdtl2,  //6
    misc_drdtl1,  //5
    1'b0,         //4
    misc_va32l3,  //3
    misc_va32l2,  //2
    misc_va32l1,  //1
    1'b0          //0
};
wire misc_wen = wen && waddr == `LSOC1K_CSR_MISC;
always @(posedge clk) begin
    //VA32L1
    if(rst) misc_va32l1 <= 1'b0;
    else if(misc_wen) misc_va32l1 <= wdata[`LSOC1K_MISC_VA32L1];
    //VA32L2
    if(rst) misc_va32l2 <= 1'b0;
    else if(misc_wen) misc_va32l2 <= wdata[`LSOC1K_MISC_VA32L2];
    //VA32L3
    if(rst) misc_va32l3 <= 1'b0;
    else if(misc_wen) misc_va32l3 <= wdata[`LSOC1K_MISC_VA32L3];
    //DRDTL1
    if(rst) misc_drdtl1 <= 1'b0;
    else if(misc_wen) misc_drdtl1 <= wdata[`LSOC1K_MISC_DRDTL1];
    //DRDTL2
    if(rst) misc_drdtl2 <= 1'b0;
    else if(misc_wen) misc_drdtl2 <= wdata[`LSOC1K_MISC_DRDTL2];
    //DRDTL3
    if(rst) misc_drdtl3 <= 1'b0;
    else if(misc_wen) misc_drdtl3 <= wdata[`LSOC1K_MISC_DRDTL3];
    //RPCNTL1
    if(rst) misc_rpcntl1 <= 1'b0;
    else if(misc_wen) misc_rpcntl1 <= wdata[`LSOC1K_MISC_RPCNTL1];
    //RPCNTL2
    if(rst) misc_rpcntl2 <= 1'b0;
    else if(misc_wen) misc_rpcntl2 <= wdata[`LSOC1K_MISC_RPCNTL2];
    //RPCNTL3
    if(rst) misc_rpcntl3 <= 1'b0;
    else if(misc_wen) misc_rpcntl3 <= wdata[`LSOC1K_MISC_RPCNTL3];
    //ALCL0
    if(rst) misc_alcl0 <= 1'b0;
    else if(misc_wen) misc_alcl0 <= wdata[`LSOC1K_MISC_ALCL0];
    //ALCL1
    if(rst) misc_alcl1 <= 1'b0;
    else if(misc_wen) misc_alcl1 <= wdata[`LSOC1K_MISC_ALCL1];
    //ALCL2
    if(rst) misc_alcl2 <= 1'b0;
    else if(misc_wen) misc_alcl2 <= wdata[`LSOC1K_MISC_ALCL2];
    //ALCL3
    if(rst) misc_alcl3 <= 1'b0;
    else if(misc_wen) misc_alcl3 <= wdata[`LSOC1K_MISC_ALCL3];
    //DWPL0
    if(rst) misc_dwpl0 <= 1'b0;
    else if(misc_wen) misc_dwpl0 <= wdata[`LSOC1K_MISC_DWPL0];
    //DWPL1
    if(rst) misc_dwpl1 <= 1'b0;
    else if(misc_wen) misc_dwpl1 <= wdata[`LSOC1K_MISC_DWPL1];
    //DWPL2
    if(rst) misc_dwpl2 <= 1'b0;
    else if(misc_wen) misc_dwpl2 <= wdata[`LSOC1K_MISC_DWPL2];
end
`endif

// ECTL 0x0_0_4
reg [12:0] ectl_lie;
reg [ 2:0] ectl_vs;
wire [`GRLEN-1:0] ectl = {
  `ifdef GS264C_64BIT
    32'b0,    //63:32
    13'b0,    //31:19
    ectl_vs,  //18:16
    3'b0,     //15:13
  `else
    19'b0,    //31:13
  `endif
    ectl_lie  //12: 0
};
wire ectl_wen = wen && waddr == `LSOC1K_CSR_ECTL;
always @(posedge clk) begin
  `ifdef GS264C_64BIT
    //ectl_vs
    if (rst) ectl_vs <= 3'b0;
    else if (ectl_wen) ectl_vs <= wdata[`LSOC1K_ECTL_VS];
  `endif
    //ectl_lie
    if (rst) ectl_lie <= 13'b0;
    else if (ectl_wen) ectl_lie <= wdata[`LSOC1K_ECTL_LIE];
end

wire ti_happen = (tval_timeval == `GRLEN'0) && tcfg_en && crmd_ie;
wire ticlr_wen = wen && waddr == `LSOC1K_CSR_TICLR;
wire ti_clear = ticlr_wen && wdata[`LSOC1K_TICLR_CLR];


// ESTAT 0x0_0_5
reg [12:0] estat_is;
reg [ 5:0] estat_ecode;
reg [ 8:0] estat_esubcode;
wire [`GRLEN-1:0] estat = {
  `ifdef GS264C_64BIT
    32'b0,          //63:32
  `endif
    1'b0,           //31
    estat_esubcode, //30:22
    estat_ecode,    //21:16
    3'b0,           //15:13
    estat_is[12:2], //12:2
    estat_is[1:0]   //1:0
};
wire estat_wen = wen && waddr == `LSOC1K_CSR_ESTAT;
always @(posedge clk) begin
    //estat_is[1:0]
    if (rst) estat_is[1:0] <= 2'b0;
    else if (estat_wen) estat_is[1:0] <= wdata[`LSOC1K_ESTAT_SIS];

    // TODO:
    //estat_is[12:2]
    //estat_is
    // IPI 
    if (rst) estat_is[12] <= 1'b0;
    // TI
    if (rst||ti_clear) estat_is[11] <= 1'b0;
    else if (ti_happen) estat_is[11] <= 1'b1;

    if (rst) estat_is[10:2] <= 11'b0;
    else estat_is[10:2] <= {intrpt,1'd0};

    // TODO:
    //estat_ecode
    if (rst) estat_ecode <= 6'h0;
    else if(wb_exception) estat_ecode <= wb_exccode;

    // TODO:
    //estat_esubcode
    if (rst) estat_esubcode <= 9'b0;
    else if(wb_exception) estat_esubcode <= {8'b0,wb_esubcode};
end


// EPC 0x0_0_6
wire epc_wen = wen && waddr == `LSOC1K_CSR_EPC;
always @(posedge clk) begin
    if  (common_except)  epc <= wb_epc;
    else if(epc_wen)     epc <= wdata;
end

// BADV 0x0_0_7
reg [`GRLEN-1:0] badv;
wire badv_wen = wen && waddr == `LSOC1K_CSR_BADV;
always @(posedge clk) begin
    if (common_except) badv <= wb_badvaddr;
    else if (badv_wen) badv <= wdata;
end

`ifdef GS264C_64BIT
// BADI 0x0_0_8
reg [31:0] badi_inst;
wire [63:0] badi = {
    32'b0,
    badi_inst
};
wire badi_wen = wen && waddr == `LSOC1K_CSR_BADI;
always @(posedge clk) begin
    if (common_except) badi_inst <= wb_badinstr;
    else if (badi_wen) badi_inst <= wdata[`LSOC1K_BADI_INST];
end
`endif

// EBase 0x0_0_C
`ifdef GS264C_64BIT
  reg [51:0] ebase_ebase;
`else
  reg [25:0] ebase_ebase;
`endif
assign ebase = {
    ebase_ebase, //63:12
  `ifdef GS264C_64BIT
    12'b0  //11:0
  `else
    6'b0
  `endif
};
wire ebase_wen = wen && waddr == `LSOC1K_CSR_EBASE;
always @(posedge clk) begin
    //ebase_ebase
  `ifdef GS264C_64BIT
    if (rst) ebase_ebase <= 52'b0;
  `else
    if (rst) ebase_ebase <= 26'b0;
  `endif
    else if (ebase_wen) ebase_ebase<= wdata[`LSOC1K_EBASE_EBASE];
end

// TLBIDX 0x0_1_0
reg [`TLB_IDXBITS-1:0] tlbidx_index;
reg [ 5:0] tlbidx_ps;
reg        tlbidx_np;
wire [`GRLEN-1:0] tlbidx = {
  `ifdef GS264C_64BIT
    32'b0,                   // 63:32
  `endif
    tlbidx_np,               // 31
    1'b0,                    // 30
    tlbidx_ps,               // 29:24
    8'b0,                    // 23:16
    {16-`TLB_IDXBITS{1'b0}}, // 15:`TLB_IDXBITS
    tlbidx_index             // `TLB_IDXBITS-1: 0
};
wire index_wen = wen && waddr == `LSOC1K_CSR_INDEX;
always @(posedge clk) begin
    // tlbidx_index
    if (rst) tlbidx_index <= 12'b0;
    else if(tlbp) tlbidx_index <= tlbrp_index[`LSOC1K_INDEX_NP]? tlbidx_index : tlbrp_index[`LSOC1K_INDEX_INDEX];
    else if(index_wen) tlbidx_index <= wdata[`LSOC1K_INDEX_INDEX];
    // tlbidx_ps
    if (rst) tlbidx_ps <= 6'b0;
    else if(tlbr     ) tlbidx_ps <= tlbrp_index[`LSOC1K_INDEX_PS];
    else if(index_wen) tlbidx_ps <= wdata[`LSOC1K_INDEX_PS];
    // tlbidx_np
    if (rst) tlbidx_np <= 1'b0;
    else if(tlbp|tlbr) tlbidx_np <= tlbrp_index[`LSOC1K_INDEX_NP];
    else if(index_wen) tlbidx_np <= wdata[`LSOC1K_INDEX_NP];
end

// TLBEHI 0x0_1_1
`ifdef GS264C_64BIT
reg  [`VABITS-14:0] tlbehi_vpn2;
wire [63-`VABITS:0] tlbehi_signext;
wire [63:0] tlbehi = {
    tlbehi_signext,// 63:48
    tlbehi_vpn2,   // 47:13
    13'b0          // 12:0
};
assign tlbehi_signext = {64-`VABITS{tlbehi_vpn2[`VABITS-14]}};
`else
reg  [18:0] tlbehi_vpn2;
wire [31:0] tlbehi = {
    tlbehi_vpn2,   // 31:13
    13'b0          // 12:0
};
`endif

wire tlbehi_wen = wen && waddr == `LSOC1K_CSR_TLBEHI;
always @(posedge clk) begin
    //tlbehi_vpn2
  `ifdef GS264C_64BIT
    if (rst) tlbehi_vpn2 <= {`VABITS-13{1'b0}};
  `else
    if (rst) tlbehi_vpn2 <= 19'b0;
  `endif
    else if(tlbr) tlbehi_vpn2 <= tlbr_entryhi[`LSOC1K_TLBEHI_VPN2];
    else if(page_except) tlbehi_vpn2 <= wb_badvaddr[`LSOC1K_TLBEHI_VPN2];
    else if (tlbehi_wen) tlbehi_vpn2<= wdata[`LSOC1K_TLBEHI_VPN2];
end


// TLBELO0 0x0_1_2
reg        tlbelo0_v   ;
reg        tlbelo0_we  ;
reg [ 1:0] tlbelo0_plv ;
reg [ 1:0] tlbelo0_mat ;
reg        tlbelo0_g   ;
`ifdef GS264C_64BIT
reg [`PABITS-13:0] tlbelo0_pfn;
reg        tlbelo0_nr  ;
reg        tlbelo0_nx  ;
reg        tlbelo0_rplv;
wire [60-`PABITS:0] tlbelo0_zeroext = {61-`PABITS{1'b0}};
`else
reg [23:0] tlbelo0_pfn;
`endif
wire [`GRLEN-1:0] tlbelo0 = {
  `ifdef GS264C_64BIT
    tlbelo0_rplv,  // 63
    tlbelo0_nx  ,  // 62
    tlbelo0_nr  ,  // 61
    tlbelo0_zeroext,  // 60:PABITS
    tlbelo0_pfn ,  // PABITS-1:12
    5'b0        ,  // 11: 7  
  `else
    tlbelo0_pfn ,  // 31: 8
    1'b0        ,  // 7
  `endif
    tlbelo0_g   ,  //  6
    tlbelo0_mat ,  //  5: 4
    tlbelo0_plv ,  //  3: 2
    tlbelo0_we  ,  //  1
    tlbelo0_v      //  0
};
wire tlbelo0_wen = wen && waddr == `LSOC1K_CSR_TLBELO0;
always @(posedge clk) begin
    // tlbelo0_v
    if(rst) tlbelo0_v <= 1'b0;
    else if(tlbr) tlbelo0_v <= tlbr_entrylo0[`LSOC1K_TLBELO_V];
    else if(tlbelo0_wen) tlbelo0_v <= wdata[`LSOC1K_TLBELO_V];
    // tlbelo0_we
    if(rst) tlbelo0_we <= 1'b0;
    else if(tlbr) tlbelo0_we <= tlbr_entrylo0[`LSOC1K_TLBELO_WE];
    else if(tlbelo0_wen) tlbelo0_we <= wdata[`LSOC1K_TLBELO_WE];
    // tlbelo0_plv
    if(rst) tlbelo0_plv <= 2'b0;
    else if(tlbr) tlbelo0_plv <= tlbr_entrylo0[`LSOC1K_TLBELO_PLV];
    else if(tlbelo0_wen) tlbelo0_plv <= wdata[`LSOC1K_TLBELO_PLV];
    // tlbelo0_mat
    if(rst) tlbelo0_mat <= 2'b0;
    else if(tlbr) tlbelo0_mat <= tlbr_entrylo0[`LSOC1K_TLBELO_MAT];
    else if(tlbelo0_wen) tlbelo0_mat <= wdata[`LSOC1K_TLBELO_MAT];
    // tlbelo0_g
    if(rst) tlbelo0_g <= 1'b0;
    else if(tlbr) tlbelo0_g <= tlbr_entrylo0[`LSOC1K_TLBELO_G];
    else if(tlbelo0_wen) tlbelo0_g <= wdata[`LSOC1K_TLBELO_G];
    // tlbelo0_pfn
  `ifdef GS264C_64BIT
    if(rst) tlbelo0_pfn <= {`PABITS-12{1'b0}};
  `else
    if(rst) tlbelo0_pfn <= 24'b0;
  `endif
    else if(tlbr) tlbelo0_pfn <= tlbr_entrylo0[`LSOC1K_TLBELO_PFN];
    else if(tlbelo0_wen) tlbelo0_pfn <= wdata[`LSOC1K_TLBELO_PFN];
  `ifdef GS264C_64BIT
    // tlbelo0_nr
    if(rst) tlbelo0_nr <= 1'b0;
    else if(tlbr) tlbelo0_nr <= tlbr_entrylo0[`LSOC1K_TLBELO_NR];
    else if(tlbelo0_wen) tlbelo0_nr <= wdata[`LSOC1K_TLBELO_NR];
    // tlbelo0_nx
    if(rst) tlbelo0_nx <= 1'b0;
    else if(tlbr) tlbelo0_nx <= tlbr_entrylo0[`LSOC1K_TLBELO_NX];
    else if(tlbelo0_wen) tlbelo0_nx <= wdata[`LSOC1K_TLBELO_NX];
    // tlbelo0_rplv
    if(rst) tlbelo0_rplv <= 1'b0;
    else if(tlbr) tlbelo0_rplv <= tlbr_entrylo0[`LSOC1K_TLBELO_RPLV];
    else if(tlbelo0_wen) tlbelo0_rplv <= wdata[`LSOC1K_TLBELO_RPLV];
  `endif 
end

// Entrylo1 0x0_1_3
reg        tlbelo1_v   ;
reg        tlbelo1_we  ;
reg [ 1:0] tlbelo1_plv ;
reg [ 1:0] tlbelo1_mat ;
reg        tlbelo1_g   ;
`ifdef GS264C_64BIT
reg [`PABITS-13:0] tlbelo1_pfn;
reg        tlbelo1_nr  ;
reg        tlbelo1_nx  ;
reg        tlbelo1_rplv;
wire [60-`PABITS:0] tlbelo1_zeroext  = {61-`PABITS{1'b0}};
`else
reg [23:0] tlbelo1_pfn;
`endif
wire [`GRLEN-1:0] tlbelo1 = {
  `ifdef GS264C_64BIT
    tlbelo1_rplv,  // 63
    tlbelo1_nx  ,  // 62
    tlbelo1_nr  ,  // 61
    tlbelo1_zeroext,  // 60:PABITS
    tlbelo1_pfn ,  // PABITS-1:12
    5'b0        ,  // 11: 7
  `else    
    tlbelo1_pfn ,  // 31: 8
    1'b0        ,  // 7
  `endif
    tlbelo1_g   ,  //  6
    tlbelo1_mat ,  //  5: 4
    tlbelo1_plv ,  //  3: 2
    tlbelo1_we  ,  //  1
    tlbelo1_v      //  0
};
wire tlbelo1_wen = wen && waddr == `LSOC1K_CSR_TLBELO1;
always @(posedge clk) begin
    // tlbelo1_v
    if(rst) tlbelo1_v <= 1'b0;
    else if(tlbr) tlbelo1_v <= tlbr_entrylo1[`LSOC1K_TLBELO_V];
    else if(tlbelo1_wen) tlbelo1_v <= wdata[`LSOC1K_TLBELO_V];
    // tlbelo1_we
    if(rst) tlbelo1_we <= 1'b0;
    else if(tlbr) tlbelo1_we <= tlbr_entrylo1[`LSOC1K_TLBELO_WE];
    else if(tlbelo1_wen) tlbelo1_we <= wdata[`LSOC1K_TLBELO_WE];
    // tlbelo1_plv
    if(rst) tlbelo1_plv <= 2'b0;
    else if(tlbr) tlbelo1_plv <= tlbr_entrylo1[`LSOC1K_TLBELO_PLV];
    else if(tlbelo1_wen) tlbelo1_plv <= wdata[`LSOC1K_TLBELO_PLV];
    // tlbelo1_mat
    if(rst) tlbelo1_mat <= 2'b0;
    else if(tlbr) tlbelo1_mat <= tlbr_entrylo1[`LSOC1K_TLBELO_MAT];
    else if(tlbelo1_wen) tlbelo1_mat <= wdata[`LSOC1K_TLBELO_MAT];
    // tlbelo1_g
    if(rst) tlbelo1_g <= 1'b0;
    else if(tlbr) tlbelo1_g <= tlbr_entrylo1[`LSOC1K_TLBELO_G];
    else if(tlbelo1_wen) tlbelo1_g <= wdata[`LSOC1K_TLBELO_G];
    // tlbelo1_pfn
  `ifdef GS264C_64BIT
    if(rst) tlbelo1_pfn <= {`PABITS-12{1'b0}};
  `else
    if(rst) tlbelo1_pfn <= 24'b0;
  `endif
    else if(tlbr) tlbelo1_pfn <= tlbr_entrylo1[`LSOC1K_TLBELO_PFN];
    else if(tlbelo1_wen) tlbelo1_pfn <= wdata[`LSOC1K_TLBELO_PFN];
  `ifdef GS264C_64BIT
    // tlbelo1_nr
    if(rst) tlbelo1_nr <= 1'b0;
    else if(tlbr) tlbelo1_nr <= tlbr_entrylo1[`LSOC1K_TLBELO_NR];
    else if(tlbelo1_wen) tlbelo1_nr <= wdata[`LSOC1K_TLBELO_NR];
    // tlbelo1_nx
    if(rst) tlbelo1_nx <= 1'b0;
    else if(tlbr) tlbelo1_nx <= tlbr_entrylo1[`LSOC1K_TLBELO_NX];
    else if(tlbelo1_wen) tlbelo1_nx <= wdata[`LSOC1K_TLBELO_NX];
    // tlbelo1_rplv
    if(rst) tlbelo1_rplv <= 1'b0;
    else if(tlbr) tlbelo1_rplv <= tlbr_entrylo1[`LSOC1K_TLBELO_RPLV];
    else if(tlbelo1_wen) tlbelo1_rplv <= wdata[`LSOC1K_TLBELO_RPLV];
  `endif
end

// ASID 0x0_1_8
reg  [ 9:0] asid_asid;
wire [ 7:0] asid_asidbits;
wire [`GRLEN-1:0] asid = {
  `ifdef GS264C_64BIT
    32'b0        ,  // 63:32
  `endif
    8'b0         ,  // 31:24
    asid_asidbits,  // 23:16
    6'b0         ,  // 15:10
    asid_asid       //  9: 0
};
wire asid_wen = wen && waddr == `LSOC1K_CSR_ASID;
always @(posedge clk) begin
    // asid_asid
    if(rst          ) asid_asid <= 10'hf;
    else if(tlbr    ) asid_asid <= tlbr_asid[`LSOC1K_ASID_ASID];
    else if(asid_wen) asid_asid <= wdata[`LSOC1K_ASID_ASID];
end
assign asid_asidbits = 8'ha; // reset to 8'hf for rand_tester

// PGDL 0x0_1_9
reg  [`GRLEN-13:0] pgdl_base;
wire [`GRLEN-1:0] pgdl = {
    pgdl_base, // 63:11
    12'b0      // 11: 0
};
wire pgdl_wen = wen && waddr == `LSOC1K_CSR_PGDL;
always @(posedge clk) begin
    // pgdl_base
    if(pgdl_wen) pgdl_base <= wdata[`LSOC1K_PGDL_BASE];
end

// PGDH 0x0_1_A
reg  [`GRLEN-13:0] pgdh_base;
wire [`GRLEN-1:0] pgdh = {
    pgdh_base, // 63:11
    12'b0      // 11: 0
};
wire pgdh_wen = wen && waddr == `LSOC1K_CSR_PGDH;
always @(posedge clk) begin
    // pgdh_base
    if(pgdh_wen) pgdh_base <= wdata[`LSOC1K_PGDH_BASE];
end

// PGD 0x0_1_B
`ifdef GS264C_64BIT
wire [`GRLEN-1:0] badvaddr_current = tlbrepc_istlbr ? tlbrbadv : badv;
`else
wire [`GRLEN-1:0] badvaddr_current = badv;
`endif 
wire [`GRLEN-1:0] pgd = badvaddr_current[`GRLEN-1] ? pgdh : pgdl;

`ifdef GS264C_64BIT
// PWCL 0x0_1_C
reg  [4:0] pwcl_ptbase;
reg  [4:0] pwcl_ptwidth;
reg  [4:0] pwcl_dir1_base;
reg  [4:0] pwcl_dir1_width;
reg  [4:0] pwcl_dir2_base;
reg  [4:0] pwcl_dir2_width;
reg  [1:0] pwcl_ptewidth;
wire [63:0] pwcl = {
    32'd0,          // 63:32
    pwcl_ptewidth,  // 31:30
    pwcl_dir2_width,// 29:25
    pwcl_dir2_base, // 24:20
    pwcl_dir1_width,// 19:15
    pwcl_dir1_base, // 14:10
    pwcl_ptwidth,   //  9: 5
    pwcl_ptbase     //  4: 0
};
wire pwcl_wen = wen && waddr == `LSOC1K_CSR_PWCL;
always @(posedge clk) begin
    // pwcl_ptbase
    if(pwcl_wen) pwcl_ptbase <= wdata[`LSOC1K_PWCL_PTBASE];
    // pwcl_ptwidth
    if(pwcl_wen) pwcl_ptwidth <= wdata[`LSOC1K_PWCL_PTWIDTH];
    // pwcl_dir1_base
    if(pwcl_wen) pwcl_dir1_base <= wdata[`LSOC1K_PWCL_DIR1_BASE];
    // pwcl_dir1_width
    if(pwcl_wen) pwcl_dir1_width <= wdata[`LSOC1K_PWCL_DIR1_WIDTH];
    // pwcl_dir2_base
    if(pwcl_wen) pwcl_dir2_base <= wdata[`LSOC1K_PWCL_DIR2_BASE];
    // pwcl_dir2_width
    if(pwcl_wen) pwcl_dir2_width <= wdata[`LSOC1K_PWCL_DIR2_WIDTH];
    // pwcl_ptewidth
    if(pwcl_wen) pwcl_ptewidth <= wdata[`LSOC1K_PWCL_PTEWIDTH];
end
`endif

`ifdef GS264C_64BIT
//PWCH 0x0_1_D
reg  [4:0] pwch_ptbase;
reg  [4:0] pwch_ptwidth;
reg  [4:0] pwch_dir1_base;
reg  [4:0] pwch_dir1_width;
reg  [4:0] pwch_dir2_base;
reg  [4:0] pwch_dir2_width;
reg  [1:0] pwch_ptewidth;
wire [63:0] pwch = {
    32'd0,          // 63:32
    pwch_ptewidth,  // 31:30
    pwch_dir2_width,// 29:25
    pwch_dir2_base, // 24:20
    pwch_dir1_width,// 19:15
    pwch_dir1_base, // 14:10
    pwch_ptwidth,   //  9: 5
    pwch_ptbase     //  4: 0
};
wire pwch_wen = wen && waddr == `LSOC1K_CSR_PWCH;
always @(posedge clk) begin
    // pwch_ptbase
    if(pwch_wen) pwch_ptbase <= wdata[`LSOC1K_PWCH_PTBASE];
    // pwch_ptwidth
    if(pwch_wen) pwch_ptwidth <= wdata[`LSOC1K_PWCH_PTWIDTH];
    // pwch_dir1_base
    if(pwch_wen) pwch_dir1_base <= wdata[`LSOC1K_PWCH_DIR1_BASE];
    // pwch_dir1_width
    if(pwch_wen) pwch_dir1_width <= wdata[`LSOC1K_PWCH_DIR1_WIDTH];
    // pwch_dir2_base
    if(pwch_wen) pwch_dir2_base <= wdata[`LSOC1K_PWCH_DIR2_BASE];
    // pwch_dir2_width
    if(pwch_wen) pwch_dir2_width <= wdata[`LSOC1K_PWCH_DIR2_WIDTH];
    // pwch_ptewidth
    if(pwch_wen) pwch_ptewidth <= wdata[`LSOC1K_PWCH_PTEWIDTH];
end
`endif

`ifdef GS264C_64BIT
// FTLB PageSize 0x0_1_E
reg  [ 5:0] stlbps_ps;
wire [57:0] stlbps_zeroext;
wire [63:0] stlbps = {
    stlbps_zeroext, //63:6
    stlbps_ps       // 5:0
};
wire pgsize_wen = wen && waddr == `LSOC1K_CSR_STLBPS;
always @(posedge clk) begin
    //stlbps_ps
    if (rst) stlbps_ps <= 6'he;  // reset to 6'he for rand test
    else if (pgsize_wen) stlbps_ps <= wdata[`LSOC1K_STLBPS_PS];
end
assign stlbps_zeroext = 58'b0;
assign ftpgsize = stlbps_ps;
`endif

`ifdef GS264C_64BIT
// RVACFG 0x0_1_F
reg [3:0] rvacfg_rbits;
wire [63:0] rvacfg = {
    32'b0,       //64:32
    28'b0,       //31: 4
    rvacfg_rbits // 3: 0
};
wire rvacfg_wen = wen && waddr == `LSOC1K_CSR_RVACFG;
always @(posedge clk) begin
    //rvacfg_rbits
    if(rst) rvacfg_rbits <= 4'b0;
    else if(rvacfg_wen) rvacfg_rbits <= wdata[`LSOC1K_RVACFG_RBITS];
end
`endif

// CPUNUM 0x0_2_0
wire [8:0] cpunum_coreid = 9'd0;
wire [`GRLEN-1:0] cpunum = {
  `ifdef GS264C_64BIT
    32'b0,         //64:32
  `endif
    23'b0,         //31: 9
    cpunum_coreid  // 8: 0
};

`ifdef GS264C_64BIT
// PRCFG1 0x0_2_1
wire [14:0] prcfg1_content;
wire [63:0] prcfg1 = {
    32'b0,         //64:32
    17'b0,         //31:15
    prcfg1_content //14: 0
};
assign prcfg1_content[`LSOC1K_PRCFG1_SAVENUM  ] = 4'd8; 
assign prcfg1_content[`LSOC1K_PRCFG1_TIMERBITS] = 8'd0; //TODO
assign prcfg1_content[`LSOC1K_PRCFG1_VSMAX    ] = 3'd0; //TODO

// PRCFG2 0x0_2_2
wire [63:0] prcfg2 = 64'h7000; //TODO

// PRCFG3 0x0_2_3
wire [25:0] prcfg3_content;
wire [63:0] prcfg3 = {
    32'b0,         //64:32
    6'b0,          //31:26
    prcfg3_content //25: 0
};
assign prcfg3_content[`LSOC1K_PRCFG3_TLBTYPE    ] = 4'd2;
assign prcfg3_content[`LSOC1K_PRCFG3_MTLBENTRIES] = `VTLB_ENTRIES - 1;
assign prcfg3_content[`LSOC1K_PRCFG3_STLBWAYS   ] = `FTLB_WAYS - 1;
assign prcfg3_content[`LSOC1K_PRCFG3_STLBSETS   ] = `FTLB_SET_LEN;
`endif

// SAVE0 0x0_3_0
reg [`GRLEN-1:0] save0;
wire save0_wen = wen && waddr == `LSOC1K_CSR_SAVE0;
always @(posedge clk) begin
    if  (save0_wen) save0 <= wdata;
end

// SAVE1 0x0_3_1
reg [`GRLEN-1:0] save1;
wire save1_wen = wen && waddr == `LSOC1K_CSR_SAVE1;
always @(posedge clk) begin
    if  (save1_wen) save1 <= wdata;
end

// SAVE2 0x0_3_2
reg [`GRLEN-1:0] save2;
wire save2_wen = wen && waddr == `LSOC1K_CSR_SAVE2;
always @(posedge clk) begin
    if  (save2_wen) save2 <= wdata;
end

// SAVE3 0x0_3_3
reg [`GRLEN-1:0] save3;
wire save3_wen = wen && waddr == `LSOC1K_CSR_SAVE3;
always @(posedge clk) begin
    if  (save3_wen) save3 <= wdata;
end

`ifdef GS264C_64BIT
// SAVE4 0x0_3_4
reg [63:0] save4;
wire save4_wen = wen && waddr == `LSOC1K_CSR_SAVE4;
always @(posedge clk) begin
    if  (save4_wen) save4 <= wdata;
end

// SAVE5 0x0_3_5
reg [63:0] save5;
wire save5_wen = wen && waddr == `LSOC1K_CSR_SAVE5;
always @(posedge clk) begin
    if  (save5_wen) save5 <= wdata;
end

// SAVE6 0x0_3_6
reg [63:0] save6;
wire save6_wen = wen && waddr == `LSOC1K_CSR_SAVE6;
always @(posedge clk) begin
    if  (save6_wen) save6 <= wdata;
end

// SAVE7 0x0_3_7
reg [63:0] save7;
wire save7_wen = wen && waddr == `LSOC1K_CSR_SAVE7;
always @(posedge clk) begin
    if  (save7_wen) save7 <= wdata;
end
`endif

// TID 0x0_4_0
reg [31:0] tid_tid;
wire [`GRLEN-1:0] tid = {
  `ifdef GS264C_64BIT
    {32{tid_tid[31]}}, //63:32
  `endif
    tid_tid            //31: 0
};
wire tid_wen = wen && waddr == `LSOC1K_CSR_TID;
always @(posedge clk) begin
    if  (tid_wen) tid_tid <= wdata[`LSOC1K_TID_TID];
end

// TCFG 0x0_4_1
reg tcfg_en;
reg tcfg_periodic;
reg [`GRLEN-3:0] tcfg_initval;
wire [`GRLEN-1:0] tcfg = {
    tcfg_initval,  //GRLEN-1:2
    tcfg_periodic, //   1
    tcfg_en        //   0
};
wire tcfg_wen = wen && waddr == `LSOC1K_CSR_TCFG;
always @(posedge clk) begin
    // tcfg_en
    if(rst) tcfg_en <= 1'b0;
    else if(tcfg_wen) tcfg_en <= wdata[`LSOC1K_TCFG_EN];
    else if(ti_happen && !tcfg_periodic) tcfg_en <= 1'b0;
    // periodic
    if(tcfg_wen) tcfg_periodic <= wdata[`LSOC1K_TCFG_PERIODIC];
    // initval
    if(tcfg_wen) tcfg_initval <= wdata[`LSOC1K_TCFG_INITVAL];
end

// TVAL 0x0_4_2
reg [`GRLEN-1:0] tval_timeval;
wire [`GRLEN-1:0] tval = {
    tval_timeval   //31: 0
};
wire tval_wen = wen && waddr == `LSOC1K_CSR_TVAL;
always @(posedge clk) begin
    if(rst) tval_timeval <= 32'h00000040;
    else if (tcfg_wen) tval_timeval <= {tcfg_initval,2'b0};
    else if (tcfg_periodic && (tval_timeval == `GRLEN'0)) tval_timeval <= {tcfg_initval,2'b0};
    else if (tcfg_en && (tval_timeval != `GRLEN'0)) tval_timeval <= tval_timeval - `GRLEN'd1;
    else if (!tcfg_periodic && ti_happen) tval_timeval <= `GRLEN'd0-`GRLEN'd1;
end

`ifdef GS264C_64BIT
// CNTC 0x0_4_3
reg [63:0] cntc_compensation;
wire [63:0] cntc = {
    cntc_compensation   //31: 0
};
wire cntc_wen = wen && waddr == `LSOC1K_CSR_CNTC;
always @(posedge clk) begin
    if  (cntc_wen) cntc_compensation <= wdata[`LSOC1K_CNTC_COMPENSATION];
end
`endif

// TICLR 0x0_4_4
wire [`GRLEN-1:0] ticlr = `GRLEN'b0;

`ifdef GS264C_64BIT
// IMPCTL1
wire [63:0] impctl1;

// IMPCTL2
wire [63:0] impctl2;
`endif

// CTAG
wire [`GRLEN-1:0] ctag; // TODO

`ifdef GS264C_64BIT
  // TLB Refill Base 0x0_8_8
  reg  [`PABITS-13:0] tlbrebase_ebase;
  wire [63-`PABITS:0] tlbrebase_zeroext;
  assign tlbrebase = {
      tlbrebase_zeroext, //63:PABITS
      tlbrebase_ebase,   //PABITS-1:12
      12'b0              //11: 0
  };
  wire tlbrebase_wen = wen && waddr == `LSOC1K_CSR_TLBREBASE;
  always @(posedge clk) begin
      //tlbrebase_ebase
      if (rst) tlbrebase_ebase <= {`PABITS-12{1'b0}};
      else if (tlbrebase_wen) tlbrebase_ebase <= wdata[`LSOC1K_TLBREBASE_EBASE];
  end
  assign tlbrebase_zeroext = {64-`PABITS{1'b0}};
`else
  // TLB Refill Base 0x0_8_8
  reg  [`GRLEN-7:0] tlbrebase_ebase;
  assign tlbrebase = {
      tlbrebase_ebase,   //GRLEN-1:6
      6'b0               //5: 0
  };
  wire tlbrebase_wen = wen && waddr == `LSOC1K_CSR_TLBREBASE;
  always @(posedge clk) begin
      //tlbrebase_ebase
      if (rst) tlbrebase_ebase <= {`GRLEN-6{1'b0}};
      else if (tlbrebase_wen) tlbrebase_ebase <= wdata[`LSOC1K_TLBREBASE_EBASE];
  end
`endif

`ifdef GS264C_64BIT
// TLBRBADV 0x0_8_9
reg [63:0] tlbrbadv;

wire tlbrbadv_wen = wen && waddr == `LSOC1K_CSR_TLBRBADV;
always @(posedge clk) begin
    //badv
    if (tlbrbadv_wen) tlbrbadv <= wdata;
    else if (tlb_refill) tlbrbadv <= wb_badvaddr;
end

// TLBREPC 0x0_8_A
reg        tlbrepc_istlbr;
reg [61:0] tlbrepc_epc;
wire [63:0] tlbrepc = {
    tlbrepc_epc,
    1'b0,
    tlbrepc_istlbr
};
wire tlbrepc_wen = wen && waddr == `LSOC1K_CSR_TLBREPC;
always @(posedge clk) begin
    // epc
    if  (tlb_refill) tlbrepc_epc <= wb_epc[`LSOC1K_TLBREPC_EPC];
    else if(tlbrepc_wen) tlbrepc_epc <= wdata[`LSOC1K_TLBREPC_EPC];

    // istlbr
    if  (tlb_refill) tlbrepc_istlbr <= 1'b1;
    else if(rst || wb_eret) tlbrepc_istlbr <= 1'b0;
    else if(tlbrepc_wen) tlbrepc_istlbr <= wdata[`LSOC1K_TLBREPC_ISTLBR];
end

// TLBRSAVE 0x0_8_B
reg [63:0] tlbrsave;
wire tlbrsave_wen = wen && waddr == `LSOC1K_CSR_TLBRSAVE;
always @(posedge clk) begin
    //save
    if (tlbrsave_wen) tlbrsave <= wdata;
end

// TLBRELO0 0x0_8_C
reg        tlbrelo0_v   ;
reg        tlbrelo0_we  ;
reg [ 1:0] tlbrelo0_plv ;
reg [ 1:0] tlbrelo0_mat ;
reg        tlbrelo0_g   ;
reg [`PABITS-13:0] tlbrelo0_pfn;
reg        tlbrelo0_nr  ;
reg        tlbrelo0_nx  ;
reg        tlbrelo0_rplv;
wire [60-`PABITS:0] tlbrelo0_zeroext;
wire [63:0] tlbrelo0 = {
    tlbrelo0_rplv,  // 63
    tlbrelo0_nx  ,  // 62
    tlbrelo0_nr  ,  // 61
    tlbrelo0_zeroext,  // 60:PABITS
    tlbrelo0_pfn ,  // PABITS-1:12
    5'b0         ,  // 11: 7
    tlbrelo0_g   ,  //  6
    tlbrelo0_mat ,  //  5: 4
    tlbrelo0_plv ,  //  3: 2
    tlbrelo0_we  ,  //  1
    tlbrelo0_v      //  0
};
wire tlbrelo0_wen = wen && waddr == `LSOC1K_CSR_TLBRELO0;
always @(posedge clk) begin
    // tlbrelo0_v
    if(rst) tlbrelo0_v <= 1'b0;
    else if(ldpte) tlbrelo0_v <= tlbr_entrylo0[`LSOC1K_TLBELO_V];  // TODO
    else if(tlbrelo0_wen) tlbrelo0_v <= wdata[`LSOC1K_TLBELO_V];
    // tlbrelo0_we
    if(rst) tlbrelo0_we <= 1'b0;
    else if(ldpte) tlbrelo0_we <= tlbr_entrylo0[`LSOC1K_TLBELO_WE];
    else if(tlbrelo0_wen) tlbrelo0_we <= wdata[`LSOC1K_TLBELO_WE];
    // tlbrelo0_plv
    if(rst) tlbrelo0_plv <= 2'b0;
    else if(ldpte) tlbrelo0_plv <= tlbr_entrylo0[`LSOC1K_TLBELO_PLV];
    else if(tlbrelo0_wen) tlbrelo0_plv <= wdata[`LSOC1K_TLBELO_PLV];
    // tlbrelo0_mat
    if(rst) tlbrelo0_mat <= 2'b0;
    else if(ldpte) tlbrelo0_mat <= tlbr_entrylo0[`LSOC1K_TLBELO_MAT];
    else if(tlbrelo0_wen) tlbrelo0_mat <= wdata[`LSOC1K_TLBELO_MAT];
    // tlbrelo0_g
    if(rst) tlbrelo0_g <= 1'b0;
    else if(ldpte) tlbrelo0_g <= tlbr_entrylo0[`LSOC1K_TLBELO_G];
    else if(tlbrelo0_wen) tlbrelo0_g <= wdata[`LSOC1K_TLBELO_G];
    // tlbrelo0_pfn
    if(rst) tlbrelo0_pfn <= {`PABITS-12{1'b0}};
    else if(ldpte) tlbrelo0_pfn <= tlbr_entrylo0[`LSOC1K_TLBELO_PFN];
    else if(tlbrelo0_wen) tlbrelo0_pfn <= wdata[`LSOC1K_TLBELO_PFN];
    // tlbrelo0_nr
    if(rst) tlbrelo0_nr <= 1'b0;
    else if(ldpte) tlbrelo0_nr <= tlbr_entrylo0[`LSOC1K_TLBELO_NR];
    else if(tlbrelo0_wen) tlbrelo0_nr <= wdata[`LSOC1K_TLBELO_NR];
    // tlbrelo0_nx
    if(rst) tlbrelo0_nx <= 1'b0;
    else if(ldpte) tlbrelo0_nx <= tlbr_entrylo0[`LSOC1K_TLBELO_NX];
    else if(tlbrelo0_wen) tlbrelo0_nx <= wdata[`LSOC1K_TLBELO_NX];
    // tlbrelo0_rplv
    if(rst) tlbrelo0_rplv <= 1'b0;
    else if(ldpte) tlbrelo0_rplv <= tlbr_entrylo0[`LSOC1K_TLBELO_RPLV];
    else if(tlbrelo0_wen) tlbrelo0_rplv <= wdata[`LSOC1K_TLBELO_RPLV];
end
assign tlbrelo0_zeroext = {61-`PABITS{1'b0}};

// TLBRELO1 0x0_8_D
reg        tlbrelo1_v   ;
reg        tlbrelo1_we  ;
reg [ 1:0] tlbrelo1_plv ;
reg [ 1:0] tlbrelo1_mat ;
reg        tlbrelo1_g   ;
reg [`PABITS-13:0] tlbrelo1_pfn;
reg        tlbrelo1_nr  ;
reg        tlbrelo1_nx  ;
reg        tlbrelo1_rplv;
wire [60-`PABITS:0] tlbrelo1_zeroext;
wire [63:0] tlbrelo1 = {
    tlbrelo1_rplv,  // 63
    tlbrelo1_nx  ,  // 62
    tlbrelo1_nr  ,  // 61
    tlbrelo1_zeroext,  // 60:PABITS
    tlbrelo1_pfn ,  // PABITS-1:12
    5'b0         ,  // 11: 7
    tlbrelo1_g   ,  //  6
    tlbrelo1_mat ,  //  5: 4
    tlbrelo1_plv ,  //  3: 2
    tlbrelo1_we  ,  //  1
    tlbrelo1_v      //  0
};
wire tlbrelo1_wen = wen && waddr == `LSOC1K_CSR_TLBRELO1;
always @(posedge clk) begin
    // tlbrelo1_v
    if(rst) tlbrelo1_v <= 1'b0;
    else if(ldpte) tlbrelo1_v <= tlbr_entrylo1[`LSOC1K_TLBELO_V];  // TODO
    else if(tlbrelo1_wen) tlbrelo1_v <= wdata[`LSOC1K_TLBELO_V];
    // tlbrelo1_we
    if(rst) tlbrelo1_we <= 1'b0;
    else if(ldpte) tlbrelo1_we <= tlbr_entrylo1[`LSOC1K_TLBELO_WE];
    else if(tlbrelo1_wen) tlbrelo1_we <= wdata[`LSOC1K_TLBELO_WE];
    // tlbrelo1_plv
    if(rst) tlbrelo1_plv <= 2'b0;
    else if(ldpte) tlbrelo1_plv <= tlbr_entrylo1[`LSOC1K_TLBELO_PLV];
    else if(tlbrelo1_wen) tlbrelo1_plv <= wdata[`LSOC1K_TLBELO_PLV];
    // tlbrelo1_mat
    if(rst) tlbrelo1_mat <= 2'b0;
    else if(ldpte) tlbrelo1_mat <= tlbr_entrylo1[`LSOC1K_TLBELO_MAT];
    else if(tlbrelo1_wen) tlbrelo1_mat <= wdata[`LSOC1K_TLBELO_MAT];
    // tlbrelo1_g
    if(rst) tlbrelo1_g <= 1'b0;
    else if(ldpte) tlbrelo1_g <= tlbr_entrylo1[`LSOC1K_TLBELO_G];
    else if(tlbrelo1_wen) tlbrelo1_g <= wdata[`LSOC1K_TLBELO_G];
    // tlbrelo1_pfn
    if(rst) tlbrelo1_pfn <= {`PABITS-12{1'b0}};
    else if(ldpte) tlbrelo1_pfn <= tlbr_entrylo1[`LSOC1K_TLBELO_PFN];
    else if(tlbrelo1_wen) tlbrelo1_pfn <= wdata[`LSOC1K_TLBELO_PFN];
    // tlbrelo1_nr
    if(rst) tlbrelo1_nr <= 1'b0;
    else if(ldpte) tlbrelo1_nr <= tlbr_entrylo1[`LSOC1K_TLBELO_NR];
    else if(tlbrelo1_wen) tlbrelo1_nr <= wdata[`LSOC1K_TLBELO_NR];
    // tlbrelo1_nx
    if(rst) tlbrelo1_nx <= 1'b0;
    else if(ldpte) tlbrelo1_nx <= tlbr_entrylo1[`LSOC1K_TLBELO_NX];
    else if(tlbrelo1_wen) tlbrelo1_nx <= wdata[`LSOC1K_TLBELO_NX];
    // tlbrelo1_rplv
    if(rst) tlbrelo1_rplv <= 1'b0;
    else if(ldpte) tlbrelo1_rplv <= tlbr_entrylo1[`LSOC1K_TLBELO_RPLV];
    else if(tlbrelo1_wen) tlbrelo1_rplv <= wdata[`LSOC1K_TLBELO_RPLV];
end
assign tlbrelo1_zeroext = {61-`PABITS{1'b0}};

// TLBREHI 0x0_8_E
reg  [`VABITS-14:0] tlbrehi_vpn2;
wire [63-`VABITS:0] tlbrehi_signext;
wire [63:0] tlbrehi = {
    tlbrehi_signext,// 63:48
    tlbrehi_vpn2,   // 47:13
    13'b0          // 12:0
};
wire tlbrehi_wen = wen && waddr == `LSOC1K_CSR_TLBREHI;
always @(posedge clk) begin
    //tlbrehi_vpn2
    if (rst) tlbrehi_vpn2 <= {`VABITS-13{1'b0}};
    else if(tlb_refill) tlbrehi_vpn2 <= wb_badvaddr[`LSOC1K_TLBEHI_VPN2];
    else if (tlbrehi_wen) tlbrehi_vpn2<= wdata[`LSOC1K_TLBEHI_VPN2];
end
assign tlbrehi_signext = {64-`VABITS{tlbrehi_vpn2[`VABITS-14]}};

// TLBRPRMD 0x0_8_F
reg [1:0] tlbrprmd_pplv;
reg       tlbrprmd_pie;
reg       tlbrprmd_pwe;
wire [63:0] tlbrprmd = {
    32'b0,     //63:32
    27'b0,     //31:5
    tlbrprmd_pwe,  //4
    1'b0,
    tlbrprmd_pie,  //2
    tlbrprmd_pplv  //1:0
};
wire tlbrprmd_wen = wen && waddr == `LSOC1K_CSR_TLBRPRMD;
always @(posedge clk) begin
    //pwe
    if (tlb_refill) tlbrprmd_pwe <= crmd_we;
    else if (tlbrprmd_wen) tlbrprmd_pwe <= wdata[`LSOC1K_TLBRPRMD_PWE];
    //pie
    if (tlb_refill) tlbrprmd_pie <= crmd_ie;
    else if (tlbrprmd_wen) tlbrprmd_pie <= wdata[`LSOC1K_TLBRPRMD_PIE];
    //pplv
    if (tlb_refill) tlbrprmd_pplv <= crmd_plv;
    else if (tlbrprmd_wen) tlbrprmd_pplv <= wdata[`LSOC1K_TLBRPRMD_PPLV];
end
`endif

`ifdef GS264C_64BIT
// ERRCTL 0x0_9_0
reg       errctl_iserr;
reg       errctl_repairable;
reg [1:0] errctl_pplv;
reg       errctl_pie;
reg       errctl_pwe;
reg       errctl_pda;
reg       errctl_ppg;
reg [1:0] errctl_pdatf;
reg [1:0] errctl_pdatm;
reg [7:0] errctl_cause;
wire [63:0] errctl = {
    32'b0,        // 64:32
    8'b0,         // 31:24
    errctl_cause, // 23:16
    3'b0,         // 15:13
    errctl_pdatm, // 12:11
    errctl_pdatf, // 10:9
    errctl_ppg,  // 8
    errctl_pda,  // 7
    errctl_pwe,  // 6
    1'b0,        // 5
    errctl_pie,  // 4
    errctl_pplv, // 3:2
    errctl_repairable, // 1
    errctl_iserr // 0
};
wire errctl_wen = wen && waddr == `LSOC1K_CSR_ERRCTL;
always @(posedge clk) begin
    //IsERR
    if(rst || wb_eret) errctl_iserr <= 1'b0;
    else if(cache_error) errctl_iserr <= 1'b1;
    //Repairable
    if(rst) errctl_repairable <= 1'b0; //TODO
    //PPLV
    if(cache_error) errctl_pplv <= crmd_plv;
    else if(errctl_wen) errctl_pplv <= wdata[`LSOC1K_ERRCTL_PPLV];
    //PIE
    if(cache_error) errctl_pie <= crmd_ie;
    else if(errctl_wen) errctl_pie <= wdata[`LSOC1K_ERRCTL_PIE];
    //PWE
    if(cache_error) errctl_pwe <= crmd_we;
    else if(errctl_wen) errctl_pwe <= wdata[`LSOC1K_ERRCTL_PWE];
    //PDA
    if(cache_error) errctl_pda <= crmd_da;
    else if(errctl_wen) errctl_pda <= wdata[`LSOC1K_ERRCTL_PDA];
    //PPG
    if(cache_error) errctl_ppg <= crmd_pg;
    else if(errctl_wen) errctl_ppg <= wdata[`LSOC1K_ERRCTL_PPG];
    //PDATF
    if(cache_error) errctl_pdatf <= crmd_datf;
    else if(errctl_wen) errctl_pdatf <= wdata[`LSOC1K_ERRCTL_PDATF];
    //PDATF
    if(cache_error) errctl_pdatm <= crmd_datm;
    else if(errctl_wen) errctl_pdatm <= wdata[`LSOC1K_ERRCTL_PDATM];
    //Cause
    if(rst) errctl_cause <= 8'h1;
end

// ERRINFO1 0x0_9_1
wire [63:0] errinfo1;

// ERRINFO2 0x0_9_2
wire [63:0] errinfo2;

// ERREBASE 0x0_9_3
reg  [`PABITS-13:0] errebase_ebase;
wire [63-`PABITS:0] errebase_zeroext;
wire [63:0] errebase = {
    errebase_zeroext, //63:PABITS
    errebase_ebase,   //PABITS-1:12
    12'b0             //11:0
};
wire errebase_wen = wen && waddr == `LSOC1K_CSR_ERREBASE;
always @(posedge clk) begin
    //errebase_ebase
    if(rst) errebase_ebase <= {`PABITS-12{1'b0}};
    else if(errebase_wen) errebase_ebase <= wdata[`LSOC1K_ERREBASE_EBASE];
end
assign errebase_zeroext = {64-`PABITS{1'b0}};

// ERREPC 0x0_9_4
reg [63:0] errepc_epc;
wire [63:0] errepc = {
    errepc_epc // 63:0
};
wire errepc_wen = wen && waddr == `LSOC1K_CSR_ERREPC;
always @(posedge clk) begin
    // epc
    if  (cache_error) errepc_epc <= wb_epc[`LSOC1K_ERREPC_EPC];
    else if(errepc_wen) errepc_epc <= wdata[`LSOC1K_ERREPC_EPC];
end

// ERRSAVE 0x0_9_5
reg [63:0] errsave_data;
wire [63:0] errsave = {
    errsave_data // 63:0
};
wire errsave_wen = wen && waddr == `LSOC1K_CSR_ERRSAVE;
always @(posedge clk) begin
    // errsave_data
    if(errsave_wen) errsave_data <= wdata;
end
`endif

// DMW0 0x1_8_0
reg       dmw0_plv0;
reg       dmw0_plv3;
reg [1:0] dmw0_mat;
`ifdef GS264C_64BIT
  reg       dmw0_plv1;
  reg       dmw0_plv2;
  reg [7:0] dmw0_vseg;
`else
  reg [2:0] dmw0_pseg;
  reg [2:0] dmw0_vseg;
`endif

assign dmw0 = {
    dmw0_vseg, //63:56 or //31:28
    `ifdef GS264C_64BIT
      50'b0    , //55:6
    `else
      1'b0     ,
      dmw0_pseg, //27:24
      19'b0    , //23:6
    `endif
    dmw0_mat , //5:4
    dmw0_plv3, //3
    `ifdef GS264C_64BIT
      dmw0_plv2, //2
      dmw0_plv1, //1
    `else
      2'b0     ,
    `endif
    dmw0_plv0  //0
};
wire dmw0_wen = wen && waddr == `LSOC1K_CSR_DMW0;
always @(posedge clk) begin
    //dmw0_plv0
    if (rst) dmw0_plv0 <= 1'b0;
    else if (dmw0_wen) dmw0_plv0 <= wdata[`LSOC1K_DMW_PLV0];
  `ifdef GS264C_64BIT
    //dmw0_plv1
    if (rst) dmw0_plv1 <= 1'b0;
    else if (dmw0_wen) dmw0_plv1 <= wdata[`LSOC1K_DMW_PLV1];
    //dmw0_plv2
    if (rst) dmw0_plv2 <= 1'b0;
    else if (dmw0_wen) dmw0_plv2 <= wdata[`LSOC1K_DMW_PLV2];
  `endif
    //dmw0_plv3
    if (rst) dmw0_plv3 <= 1'b0;
    else if (dmw0_wen) dmw0_plv3 <= wdata[`LSOC1K_DMW_PLV3];
    //dmw0_mat
    if (rst) dmw0_mat <= 2'b0;
    else if (dmw0_wen) dmw0_mat <= wdata[`LSOC1K_DMW_MAT];
    `ifdef GS264C_64BIT
      //dmw0_vseg
      if (rst) dmw0_vseg <= 8'b0;
      else if (dmw0_wen) dmw0_vseg <= wdata[`LSOC1K_DMW_VSEG];
    `else
      //dmw0_pseg
      if (rst) dmw0_pseg <= 3'b0;
      else if (dmw0_wen) dmw0_pseg <= wdata[`LSOC1K_DMW_PSEG];

      //dmw0_vseg
      if (rst) dmw0_vseg <= 3'b0;
      else if (dmw0_wen) dmw0_vseg <= wdata[`LSOC1K_DMW_VSEG];
    `endif
end

// DMW1 0x1_8_1
reg       dmw1_plv0;
reg       dmw1_plv3;
reg [1:0] dmw1_mat;
`ifdef GS264C_64BIT
  reg       dmw1_plv1;
  reg       dmw1_plv2;
  reg [7:0] dmw1_vseg;
`else
  reg [2:0] dmw1_pseg;
  reg [2:0] dmw1_vseg;
`endif
assign dmw1 = {
    dmw1_vseg, //63:56 or //31:28
    `ifdef GS264C_64BIT
      50'b0    , //55:6
    `else
      1'b0     ,
      dmw1_pseg, //27:24
      19'b0    , //23:6
    `endif
    dmw1_mat , //5:4
    dmw1_plv3, //3
    `ifdef GS264C_64BIT
      dmw1_plv2, //2
      dmw1_plv1, //1
    `else
      2'b0     ,
    `endif
    dmw1_plv0  //0
};
wire dmw1_wen = wen && waddr == `LSOC1K_CSR_DMW1;
always @(posedge clk) begin
    //dmw1_plv0
    if (rst) dmw1_plv0 <= 1'b0;
    else if (dmw1_wen) dmw1_plv0 <= wdata[`LSOC1K_DMW_PLV0];
  `ifdef GS264C_64BIT
    //dmw1_plv1
    if (rst) dmw1_plv1 <= 1'b0;
    else if (dmw1_wen) dmw1_plv1 <= wdata[`LSOC1K_DMW_PLV1];
    //dmw1_plv2
    if (rst) dmw1_plv2 <= 1'b0;
    else if (dmw1_wen) dmw1_plv2 <= wdata[`LSOC1K_DMW_PLV2];
  `endif
    //dmw1_plv3
    if (rst) dmw1_plv3 <= 1'b0;
    else if (dmw1_wen) dmw1_plv3 <= wdata[`LSOC1K_DMW_PLV3];
    //dmw1_mat
    if (rst) dmw1_mat <= 2'b0;
    else if (dmw1_wen) dmw1_mat <= wdata[`LSOC1K_DMW_MAT];
    `ifdef GS264C_64BIT
      //dmw1_vseg
      if (rst) dmw1_vseg <= 8'b0;
      else if (dmw1_wen) dmw1_vseg <= wdata[`LSOC1K_DMW_VSEG];
    `else
      //dmw1_pseg
      if (rst) dmw1_pseg <= 3'b0;
      else if (dmw1_wen) dmw1_pseg <= wdata[`LSOC1K_DMW_PSEG];

      //dmw1_vseg
      if (rst) dmw1_vseg <= 3'b0;
      else if (dmw1_wen) dmw1_vseg <= wdata[`LSOC1K_DMW_VSEG];
    `endif
end

`ifdef GS264C_64BIT
// PMCFG0 0x2_0_0
reg [9:0] pmcfg0_event;
reg       pmcfg0_plv0;
reg       pmcfg0_plv1;
reg       pmcfg0_plv2;
reg       pmcfg0_plv3;
reg       pmcfg0_ie;
wire [63:0] pmcfg0 = {
    43'b0       , //63:21
    pmcfg0_ie   , //20
    pmcfg0_plv3 , //19
    pmcfg0_plv2 , //18
    pmcfg0_plv1 , //17
    pmcfg0_plv0 , //16
    6'b0        , //15:10
    pmcfg0_event  //9:0
};
wire pmcfg0_wen = wen && waddr == `LSOC1K_CSR_PMCFG0;
always @(posedge clk) begin
    //pmcfg0_event
    if(rst) pmcfg0_event <= 10'h0;
    else if(pmcfg0_wen) pmcfg0_event <= wdata[`LSOC1K_PMCFG_EVENT];
    //pmcfg0_plv0
    if(rst) pmcfg0_plv0 <= 1'b0;
    else if(pmcfg0_wen) pmcfg0_plv0 <= wdata[`LSOC1K_PMCFG_PLV0];
    //pmcfg0_plv1
    if(rst) pmcfg0_plv1 <= 1'b0;
    else if(pmcfg0_wen) pmcfg0_plv1 <= wdata[`LSOC1K_PMCFG_PLV1];
    //pmcfg0_plv2
    if(rst) pmcfg0_plv2 <= 1'b0;
    else if(pmcfg0_wen) pmcfg0_plv2 <= wdata[`LSOC1K_PMCFG_PLV2];
    //pmcfg0_plv3
    if(rst) pmcfg0_plv3 <= 1'b0;
    else if(pmcfg0_wen) pmcfg0_plv3 <= wdata[`LSOC1K_PMCFG_PLV3];
    //pmcfg0_ie
    if(rst) pmcfg0_ie <= 1'b0;
    else if(pmcfg0_wen) pmcfg0_ie <= wdata[`LSOC1K_PMCFG_IE];
end

// PMCNT0 0x2_0_1
reg [63:0] pmcnt0_count;
wire [63:0] pmcnt0 = {
    pmcnt0_count // 63:0
};
wire pmcnt0_wen = wen && waddr == `LSOC1K_CSR_PMCNT0;
always @(posedge clk) begin
    //pmcnt0_count
    if(rst) pmcnt0_count <= 64'b0;
    else if(pmcnt0_wen) pmcnt0_count <= wdata[`LSOC1K_PMCNT_COUNT];
end
`endif


// Status (12, 0)
reg status_cu1;
reg status_rw;
reg [7:0] status_im;
reg status_um;
reg status_ie;

assign status = {
	  32'd0,
    2'd0,
    1'd0,       // 29
    // status_cu1, // 29
    status_rw, // 28
    5'd0,
    status_bev, // 22
    // 1'd1,    // 22 TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    6'd0,
    status_im,  // 15:8
    3'd0,
    status_um,  // 4
    1'b0,
    status_erl, // 2
    status_exl, // 1
    status_ie   // 0
};
    
wire status_wen = 1'b0;

wire eret_clear_erl =  status_erl && wb_eret;
wire eret_clear_exl = !status_erl && wb_eret;

always @(posedge clk) begin
    // // CU1
    // if (!resetn) status_cu1 <= 1'b0;
    // else if (status_wen) status_cu1 <= wdata[`STATUS_CU1];
    // else if (status_wen) status_cu1 <= wdata[`STATUS_CU1];
    // RW
    if (!resetn) status_rw <= 1'b0;
    else if (status_wen) status_rw <= wdata[`STATUS_RW];
    // BEV
    if (!resetn) status_bev <= 1'b1;
    else if (status_wen) status_bev <= wdata[`STATUS_BEV];
    // IM
    if (!resetn) status_im <= 8'd0;
    else if (status_wen) status_im <= wdata[`STATUS_IM];
    // UM
    if (!resetn) status_um <= 1'b0;
    else if (status_wen) status_um <= wdata[`STATUS_UM];
    // ERL
    if (!resetn) status_erl <= 1'b1;
    else if (eret_clear_erl) status_erl <= 1'b0;
    else if (status_wen) status_erl <= wdata[`STATUS_ERL];
    // EXL
    if (!resetn || eret_clear_exl) status_exl <= 1'b0;
    else if (wb_exception) status_exl <= 1'b1;
    else if (status_wen) status_exl <= wdata[`STATUS_EXL];
    // IE
    if (!resetn) status_ie <= 1'b1;
    else if (status_wen) status_ie <= wdata[`STATUS_IE];
end

wire [1:0] status_ksu = status[4:3];

// Cause (13, 0)
reg cause_bd;
reg cause_ti;
reg [1:0] cause_ce;
reg [5:0] cause_ip7_2;
reg [1:0] cause_ip1_0;
reg [4:0] cause_exccode;
assign cause = {
    32'd0,
    cause_bd,       // 31
    cause_ti,       // 30
    cause_ce,       // 29:28
    4'd0,
    cause_iv,       // 23
    7'd0,
    cause_ip7_2,    // 15:10
    cause_ip1_0,    // 9:8
    1'd0,
    cause_exccode,  // 6:2
    2'd0
};
    
wire cause_wen = 1'b0;
always @(posedge clk) begin
    // BD
    if (!resetn) cause_bd <= 1'b0;
    else if (wb_exception && !status_exl) cause_bd <= 1'b0;
    // TI
    if (!resetn) cause_ti <= 1'b0;
    // else cause_ti <= timer_int;
    // CE
    if (!resetn) cause_ce <= 2'd0;
    // else if (exception_commit) cause_ce <= commit_ce;
    // IV
    if (!resetn) cause_iv <= 1'b0;
    else if (cause_wen) cause_iv <= wdata[`CAUSE_IV];
    // IP
    //cause_ip7_2 <= hw_int; //TODO!!!!!!!!!!!!!!!!!!!!!!!!>????????????????????????????
    cause_ip7_2 <= 6'd0;
    if (!resetn) cause_ip1_0 <= 2'd0;
    else if (cause_wen) cause_ip1_0 <= wdata[`CAUSE_IP1_0];
    // ExcCode
    if (!resetn) cause_exccode <= 5'd0;
    else if (wb_exception) cause_exccode <= wb_exccode==`EXC_INT ? 5'd0/*`EXC_TLBL*/:
                                            wb_exccode==`EXC_INT ? 5'd0/*`EXC_TLBS*/:
                                            wb_exccode[4:0];
end

// TagLo0(28,0)
reg [23:0] taglo0_ptaglo;
reg [ 1:0] taglo0_pstate;
reg        taglo0_l;
reg        taglo0_p;
wire [63:0] taglo0 ={
		32'd0,
    taglo0_ptaglo,           // 31:8 
    taglo0_pstate,           //  7:6
    taglo0_l,                //  5
    4'b0,                    //  4:1
    taglo0_p                 //  0
};

wire taglo0_wen =1'b0;
always @(posedge clk) begin
    //taglo0_ptaglo
    if (!resetn)          taglo0_ptaglo <= 24'd0;
    else if (taglo0_wen) taglo0_ptaglo <= wdata[`TAGLO0_PTAGLO];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taglo0_ptaglo <= cache_taglo_i[`TAGLO0_PTAGLO];
    //taglo0_pstate
    if (!resetn)          taglo0_pstate <= 2'd0;
    else if (taglo0_wen) taglo0_pstate <= wdata[`TAGLO0_PSTATE];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taglo0_pstate <= cache_taglo_i[`TAGLO0_PSTATE];
    //taglo0_l
    if (!resetn)          taglo0_l <= 1'd0;
    else if (taglo0_wen) taglo0_l <= wdata[`TAGLO0_L];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taglo0_l <= cache_taglo_i[`TAGLO0_L];
    //taglo0_p
    if (!resetn)          taglo0_p <= 1'd0;
    else if (taglo0_wen) taglo0_p <= wdata[`TAGLO0_P];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taglo0_p <= cache_taglo_i[`TAGLO0_P];
end

// TagHi0(29,0)
reg [23:0] taghi0_ptaglo;
reg [ 1:0] taghi0_pstate;
reg        taghi0_l;
reg        taghi0_p;
wire [63:0] taghi0 ={
		32'd0,
    taghi0_ptaglo,           // 31:8 
    taghi0_pstate,           //  7:6
    taghi0_l,                //  5
    4'b0,                    //  4:1
    taghi0_p                 //  0
};

wire taghi0_wen = 1'b0;
always @(posedge clk) begin
    //taghi0_ptaglo
    if (!resetn)          taghi0_ptaglo <= 24'd0;
    else if (taghi0_wen) taghi0_ptaglo <= wdata[`TAGHI0_PTAGLO];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taghi0_ptaglo <= cache_taghi_i[`TAGHI0_PTAGLO];
    //taghi0_pstate
    if (!resetn)          taghi0_pstate <= 2'd0;
    else if (taghi0_wen) taghi0_pstate <= wdata[`TAGHI0_PSTATE];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taghi0_pstate <= cache_taghi_i[`TAGHI0_PSTATE];
    //taghi0_l
    if (!resetn)           taghi0_l <= 1'd0;
    else if (taghi0_wen)  taghi0_l <= wdata[`TAGHI0_L];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taghi0_l <= cache_taghi_i[`TAGHI0_L];
    //taghi0_p
    if (!resetn)           taghi0_p <= 1'd0;
    else if (taghi0_wen)  taghi0_p <= wdata[`TAGHI0_P];
    else if (cache_op_1[`CACHE_TAG] || cache_op_2[`CACHE_TAG]) taghi0_p <= cache_taghi_i[`TAGHI0_P];
end

//// read/write interface
assign rdata =  {`GRLEN{raddr == `LSOC1K_CSR_CRMD      }} & crmd      |
                {`GRLEN{raddr == `LSOC1K_CSR_PRMD      }} & prmd      |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_MISC      }} & misc      |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_EUEN      }} & euen      |
                {`GRLEN{raddr == `LSOC1K_CSR_ECTL      }} & ectl      |
                {`GRLEN{raddr == `LSOC1K_CSR_ESTAT     }} & estat     |
                {`GRLEN{raddr == `LSOC1K_CSR_EPC       }} & epc       |
                {`GRLEN{raddr == `LSOC1K_CSR_BADV      }} & badv      |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_BADI      }} & badi      |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_EBASE     }} & ebase     |
                {`GRLEN{raddr == `LSOC1K_CSR_INDEX     }} & tlbidx    |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBEHI    }} & tlbehi    |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBELO0   }} & tlbelo0   |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBELO1   }} & tlbelo1   |
                {`GRLEN{raddr == `LSOC1K_CSR_ASID      }} & asid      |
                {`GRLEN{raddr == `LSOC1K_CSR_PGDL      }} & pgdl      |
                {`GRLEN{raddr == `LSOC1K_CSR_PGDH      }} & pgdh      |
                {`GRLEN{raddr == `LSOC1K_CSR_PGD       }} & pgd       |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_PWCL      }} & pwcl      |
                {`GRLEN{raddr == `LSOC1K_CSR_PWCH      }} & pwch      |
                {`GRLEN{raddr == `LSOC1K_CSR_STLBPS    }} & stlbps    |
                {`GRLEN{raddr == `LSOC1K_CSR_RVACFG    }} & rvacfg    |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_CPUNUM    }} & cpunum    |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_PRCFG1    }} & prcfg1    |
                {`GRLEN{raddr == `LSOC1K_CSR_PRCFG2    }} & prcfg2    |
                {`GRLEN{raddr == `LSOC1K_CSR_PRCFG3    }} & prcfg3    |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE0     }} & save0     |
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE1     }} & save1     |
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE2     }} & save2     |
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE3     }} & save3     |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE4     }} & save4     |
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE5     }} & save5     |
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE6     }} & save6     |
                {`GRLEN{raddr == `LSOC1K_CSR_SAVE7     }} & save7     |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_TID       }} & tid       |
                {`GRLEN{raddr == `LSOC1K_CSR_TCFG      }} & tcfg      |
                {`GRLEN{raddr == `LSOC1K_CSR_TVAL      }} & tval      |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_CNTC      }} & cntc      |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_TICLR     }} & ticlr     |
                {`GRLEN{raddr == `LSOC1K_CSR_LLBCTL    }} & llbctl    |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBREBASE }} & tlbrebase |
                `ifdef GS264C_64BIT
                {`GRLEN{raddr == `LSOC1K_CSR_TLBRBADV  }} & tlbrbadv  |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBREPC   }} & tlbrepc   |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBRSAVE  }} & tlbrsave  |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBRELO0  }} & tlbrelo0  |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBRELO1  }} & tlbrelo1  |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBREHI   }} & tlbrehi   |
                {`GRLEN{raddr == `LSOC1K_CSR_TLBRPRMD  }} & tlbrprmd  |
                {`GRLEN{raddr == `LSOC1K_CSR_ERRCTL    }} & errctl    |
                {`GRLEN{raddr == `LSOC1K_CSR_ERRINFO1  }} & errinfo1  |
                {`GRLEN{raddr == `LSOC1K_CSR_ERRINFO2  }} & errinfo2  |
                {`GRLEN{raddr == `LSOC1K_CSR_ERREBASE  }} & errebase  |
                {`GRLEN{raddr == `LSOC1K_CSR_ERREPC    }} & errepc    |
                {`GRLEN{raddr == `LSOC1K_CSR_ERRSAVE   }} & errsave   |
                `endif
                {`GRLEN{raddr == `LSOC1K_CSR_DMW0      }} & dmw0      |
                {`GRLEN{raddr == `LSOC1K_CSR_DMW1      }} & dmw1      |
                                                        `GRLEN'd0     ;
                    
//output
assign csr_output[`LSOC1K_CSR_OUTPUT_CRMD_PLV   ] = crmd_plv   ;
assign csr_output[`LSOC1K_CSR_OUTPUT_EUEN_FPE   ] = euen_fpe   ;
assign csr_output[`LSOC1K_CSR_OUTPUT_EUEN_SXE   ] = euen_sxe   ;
assign csr_output[`LSOC1K_CSR_OUTPUT_EUEN_ASXE  ] = euen_asxe  ;
assign csr_output[`LSOC1K_CSR_OUTPUT_EUEN_BTE   ] = euen_bte   ;
`ifdef GS264C_64BIT
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL1] = misc_drdtl1;
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL2] = misc_drdtl2;
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_DRDTL3] = misc_drdtl3;
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL0 ] = misc_alcl0 ;
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL1 ] = misc_alcl1 ;
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL2 ] = misc_alcl2 ;
assign csr_output[`LSOC1K_CSR_OUTPUT_MISC_ALCL3 ] = misc_alcl3 ;
`endif

assign epc_addr_out = epc;
`ifdef GS264C_64BIT
  assign eret_epc_out = tlbrepc_istlbr ? {tlbrepc_epc,2'b0} : epc;
`else
  assign eret_epc_out = epc;
`endif
assign shield       = 1'b0;//status_exl || !status_ie;
assign int_except   = |(estat_is & ectl_lie) && crmd_ie;

`ifdef GS264C_64BIT
  assign entryhi_out    = tlbrepc_istlbr ? tlbrehi : tlbehi;
  assign entrylo0_out   = tlbrepc_istlbr ? tlbrelo0 : tlbelo0;
  assign entrylo1_out   = tlbrepc_istlbr ? tlbrelo1 : tlbelo1;
  assign rbits_out      = rvacfg_rbits;
  assign istlbr_out     = tlbrepc_istlbr;
`else
  assign entryhi_out    = tlbehi;
  assign entrylo0_out   = tlbelo0;
  assign entrylo1_out   = tlbelo1;
`endif
assign index_out        = tlbidx;
assign asid_out         = asid;
assign ecode_out        = estat_ecode;
assign taglo0_out       = taglo0[`GRLEN-1:0]; //TODO
assign taghi0_out       = taghi0[`GRLEN-1:0]; //TODO

// TODO: REMOVE!!!
reg [63:0] tlbrbadv;

endmodule
