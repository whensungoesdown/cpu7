`include "common.vh"

module wb_stage(
    input                  clk,
    input                  resetn,

    // pipe in
    output                 wb_allow_in,
    // port 0
    input [31:0]                      wb_port0_inst,
    input [`GRLEN-1:0]                wb_port0_pc,
    input [`EX_SR-1 : 0]              wb_port0_src,
    input                             wb_port0_valid,
    input [4:0]                       wb_port0_rf_target,
    input                             wb_port0_rf_wen,
    input [`GRLEN-1:0]                wb_port0_rf_result,
    input                             wb_port0_exception,
    input [5 :0]                      wb_port0_exccode,
    input                             wb_port0_eret,
    input [`LSOC1K_CSR_BIT -1:0]      wb_port0_csr_addr,
    input [`LSOC1K_CSR_CODE_BIT-1:0]  wb_none0_op, 
    input                             wb_port0_ll,
    input                             wb_port0_sc,
    input [`GRLEN-1:0]                wb_port0_csr_result,
    input                             wb_port0_esubcode,
    input [`LSOC1K_NONE_INFO_BIT-1:0] wb_none0_info,
    input                             wb_port0_rf_res_lsu,
    // input                           
    // port 1
    input [31:0]                      wb_port1_inst,
    input [`GRLEN-1:0]                wb_port1_pc,
    input [`EX_SR-1 : 0]              wb_port1_src,
    input                             wb_port1_valid,
    input [4:0]                       wb_port1_rf_target,
    input                             wb_port1_rf_wen,
    input [`GRLEN-1:0]                wb_port1_rf_result,
    input                             wb_port1_exception,
    input [5 :0]                      wb_port1_exccode,
    input                             wb_port1_eret,
    input [`LSOC1K_CSR_BIT -1:0]      wb_port1_csr_addr,
    input [`LSOC1K_CSR_CODE_BIT-1:0]  wb_none1_op,
    input                             wb_port1_ll,
    input                             wb_port1_sc,
    input [`GRLEN-1:0]                wb_port1_csr_result,
    input                             wb_port1_esubcode,
    input [`LSOC1K_NONE_INFO_BIT-1:0] wb_none1_info,
    input                             wb_port1_rf_res_lsu,
    // port 2
    input                      wb_port2_valid,
    // lsu
    input [`GRLEN-1:0]         wb_lsu_res,
    // branch
    input                      wb_branch_valid,
    input                      wb_branch_brop,
    input                      wb_branch_jrop,
    input                      wb_branch_jrra,
    input                      wb_branch_link,
    input [2:0]                wb_bru_port,
    input                      wb_bru_br_taken,
    input [`LSOC1K_PRU_HINT:0] wb_bru_hint,
    input [`GRLEN-1:0]         wb_bru_link_pc,
    input [`GRLEN-1:0]         wb_bru_pc,
    //tlb related
    input [`GRLEN-1:0]         tlb_index_i,

    //cache related
    input [`GRLEN-1:0]         cache_taglo_i,
    input [`GRLEN-1:0]         cache_taghi_i,
    input [`GRLEN-1:0]         cache_datalo_i,
    input [`GRLEN-1:0]         cache_datahi_i,

    output [`CACHE_OPNUM-1:0]  cache_op_1,
    output [`CACHE_OPNUM-1:0]  cache_op_2,
    output [`GRLEN-1:0]        cache_taglo_o,
    output [`GRLEN-1:0]        cache_taghi_o,
    output [`GRLEN-1:0]        cache_datalo_o,
    output [`GRLEN-1:0]        cache_datahi_o,

    //debug
    output [`GRLEN-1:0] debug0_wb_pc,
    output              debug0_wb_rf_wen,
    output [ 4:0]       debug0_wb_rf_wnum,
    output [`GRLEN-1:0] debug0_wb_rf_wdata,
    
    output [`GRLEN-1:0] debug1_wb_pc,
    output              debug1_wb_rf_wen,
    output [ 4:0]       debug1_wb_rf_wnum,
    output [`GRLEN-1:0] debug1_wb_rf_wdata,

    //reg file interface
    output [4:0]        waddr1,
    output [4:0]        waddr2,
    output [`GRLEN-1:0] wdata1,
    output [`GRLEN-1:0] wdata2,
    output              wen1,
    output              wen2,

    // cp0 registers interface
    output [`LSOC1K_CSR_BIT-1:0] csr_waddr,
    output [`GRLEN-1:0]          csr_wdata,
    output                       csr_wen,

    output                       csr_tlbp,
    output [`GRLEN-1:0]          csr_tlbop_index,
    output                       csr_tlbr,
    
    input              cp0_status_exl         ,
    input              cp0_status_bev         ,
    input              cp0_cause_iv           ,
    input [17:0]       cp0_ebase_exceptionbase,
    input [`GRLEN-1:0] eret_epc               ,
    input [`GRLEN-1:0] wb_tlbr_entrance       ,       
    input [`GRLEN-1:0] csr_ebase              ,

    //exeception
    input  [`GRLEN-1:0]         badvaddr_ex2,
    input                       badvaddr_ex2_valid,
    input  [`GRLEN-1:0]         lsu_badvaddr,
    input                       except_shield,
    output                      wb_exception,
    output                      wb_cancel,
    output [`GRLEN-1:0]         wb_target,
    output [5 :0]               wb_exccode,
    output                      wb_esubcode,
    output                      wb_eret,
    output [`GRLEN-1:0]         wb_epc,
    output [`GRLEN-1:0]         wb_badvaddr,
    output [31:0]               wb_badinstr,
    output                      wb_valid,
    output                      wb_brop,
    output                      wb_jrop,
    output                      wb_link,
    output [`GRLEN-1:0]         wb_link_pc,
    output                      wb_jrra,
    output                      wb_taken,
    output [`LSOC1K_PRU_HINT:0] wb_hint,
    output [`GRLEN-1:0]         wb_pc
);

////// define
wire port0_exception;
wire port1_exception;
wire port0_eret;
wire port1_eret;

wire              wb_refill  ;
wire              wb_cacheerr;
wire              wb_intr    ;
wire              wb_other   ;
wire [`GRLEN-1:0] ex_entrance;

// for rand_test
wire       port0_fail   = (wb_none0_info[`LSOC1K_CSR_ROLL_BACK] || wb_port0_exception || wb_port0_eret) && wb_port0_valid;
wire       port1_fail   = (wb_none1_info[`LSOC1K_CSR_ROLL_BACK] || wb_port1_exception || wb_port1_eret) && wb_port1_valid;

wire       port0_submit = wb_port0_valid && !wb_port0_exception;
wire       port1_submit = wb_port1_valid && !wb_port1_exception && !port0_fail ;//&& !wb_none1_info[`LSOC1K_MICROOP];
wire       port2_submit = wb_port2_valid && !(port0_fail && (wb_bru_port[1] || wb_bru_port[2]))
                          && !(port1_fail && wb_bru_port[2]);

wire [1:0] port0_submit_num = {1'b0,port0_submit};
wire [1:0] port1_submit_num = //{1'b0,port1_submit};
                              (port1_submit && port2_submit) ? 2'b10 :
                              (port1_submit || port2_submit) ? 2'b01 :
                                                               2'b00 ;

// ll sc
reg ll_bit;
wire port0_sc_commit = 1'b0;//wb_port0_sc && wb_port0_valid;
wire port1_sc_commit = 1'b0;//wb_port1_sc && wb_port1_valid;
wire ll_commit = (wb_port0_ll && wb_port0_valid) || (wb_port1_ll && wb_port1_valid);
wire sc_commit = port0_sc_commit || port1_sc_commit;

always @(posedge clk) begin
	if(!resetn || sc_commit || wb_eret)
    begin    
        ll_bit <= 1'd0;
    end
    else if(ll_commit)
    begin    
        ll_bit <= 1'd1;
    end
end

////func
// common regs
assign waddr1 = wb_port0_rf_target;
assign wen1   = wb_port0_rf_wen && port0_submit; // not cp0 related
`ifdef LA64
assign wdata1 = wb_port0_rf_res_lsu ? wb_lsu_res : port0_sc_commit ? {63'd0,ll_bit} : wb_port0_rf_result;
`elsif LA32
assign wdata1 = wb_port0_rf_res_lsu ? wb_lsu_res : port0_sc_commit ? {31'd0,ll_bit} : wb_port0_rf_result;
`endif

assign waddr2 = wb_port1_rf_target;
assign wen2   = wb_port1_rf_wen && port1_submit; // not cp0 related
`ifdef LA64
assign wdata2 = wb_port1_rf_res_lsu ? wb_lsu_res : port1_sc_commit ? {63'd0,ll_bit} : wb_port1_rf_result;
`elsif LA32
assign wdata2 = wb_port1_rf_res_lsu ? wb_lsu_res : port1_sc_commit ? {31'd0,ll_bit} : wb_port1_rf_result;
`endif

// cp0 regs
wire [`LSOC1K_CSR_BIT-1:0] csr_waddr0 = wb_port0_csr_addr; // addr,sel
wire                       csr_wen0   = (wb_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_CSR_CSRXCHG || wb_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_CSR_CSRWR) && port0_submit;
wire [`GRLEN-1:0]          csr_wdata0 = wb_port0_csr_result;

wire [`LSOC1K_CSR_BIT-1:0] csr_waddr1 = wb_port1_csr_addr;
wire                       csr_wen1   = (wb_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_CSR_CSRXCHG || wb_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_CSR_CSRWR) && port1_submit;
wire [`GRLEN-1:0]          csr_wdata1 = wb_port1_csr_result;

assign csr_waddr = csr_wen0 ? csr_waddr0 : csr_waddr1;
assign csr_wen   = csr_wen0 || csr_wen1;
assign csr_wdata = csr_wen0 ? csr_wdata0 : csr_wdata1;

wire port0_tlbp = wb_port0_valid && wb_none0_op[`LSOC1K_TLB_VALID] && wb_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBP;
wire port1_tlbp = wb_port1_valid && wb_none1_op[`LSOC1K_TLB_VALID] && wb_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBP;
wire port0_tlbr = wb_port0_valid && wb_none0_op[`LSOC1K_TLB_VALID] && wb_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBR;
wire port1_tlbr = wb_port1_valid && wb_none1_op[`LSOC1K_TLB_VALID] && wb_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBR;

assign csr_tlbp = port0_tlbp || port1_tlbp;
assign csr_tlbr = port0_tlbr || port1_tlbr;
assign csr_tlbop_index = (port0_tlbr || port0_tlbp) ? wb_port0_csr_result : wb_port1_csr_result;

assign cache_op_1[`CACHE_TAG ] = wb_port0_valid && (wb_port0_inst[20:18] == 3'b001);
assign cache_op_1[`CACHE_DATA] = wb_port0_valid && (wb_port0_inst[20:18] == 3'b001);
assign cache_op_2[`CACHE_TAG ] = wb_port1_valid && (wb_port1_inst[20:18] == 3'b001);
assign cache_op_2[`CACHE_DATA] = wb_port1_valid && (wb_port1_inst[20:18] == 3'b001);
assign cache_taglo_o = cache_taglo_i;
assign cache_taghi_o = cache_taghi_i;
assign cache_datalo_o= cache_datalo_i;
assign cache_datahi_o= cache_datahi_i;

//// wb_exception
reg  [1:0] state_cur  ;
wire [1:0] state_next ;

wire [1:0] state_idle ;
wire [1:0] state_wait ;
wire [1:0] state_queue;

wire       state_cur_idle;
wire       state_cur_wait;
wire       state_cur_queue;

wire       state_next_idle;
wire       state_next_wait;
wire       state_next_queue;

wire       token_branch;
wire       token_valid ;

wire       action_commit;

assign state_idle  = 2'b00;
assign state_wait  = 2'b01;
assign state_queue = 2'b10;
assign token_valid  = wb_port0_valid || wb_port1_valid;
assign token_branch = 
    wb_branch_valid 
    && wb_allow_in
    && !(wb_bru_port[0] ? !wb_port0_valid || port1_eret || port1_exception : 
                             !wb_port1_valid || port0_eret || port0_exception);
assign state_cur_idle  = state_cur == state_idle;
assign state_cur_wait  = state_cur == state_wait;
assign state_cur_queue = state_cur == state_queue;
assign state_next = 
     {2{state_next_wait}} &state_wait
    |{2{state_next_queue}}&state_queue;
assign state_next_queue = 
    state_cur_wait && token_valid && token_branch
    || state_cur_queue && token_branch;
assign state_next_wait = 
    state_cur_idle && token_branch 
    || state_cur_wait && token_valid && token_branch
    || state_cur_wait && !token_valid 
    || state_cur_queue && token_branch;
assign action_commit = 
    state_cur_idle && token_branch
    || state_cur_wait && token_valid 
    || state_cur_queue;
    
wire [`GRLEN-1:0] wb_branch_brpc;
wire [`GRLEN-1:0] wb_branch_link_pc;
assign wb_branch_brpc  = wb_bru_pc;
assign wb_branch_link_pc = wb_bru_link_pc;
always @(posedge clk) begin
    if(!resetn || wb_exception || wb_eret)
    begin
        state_cur <= state_idle;
    end
    else if(state_cur_queue || token_valid)
    begin
        state_cur <= state_next;
    end
end
assign port0_exception = wb_port0_exception && wb_port0_valid && wb_allow_in;
assign port1_exception = wb_port1_exception && wb_port1_valid && wb_allow_in;
wire   port0_roll_back = wb_none0_info[`LSOC1K_CSR_ROLL_BACK] && wb_port0_valid && wb_allow_in;
wire   port1_roll_back = wb_none1_info[`LSOC1K_CSR_ROLL_BACK] && wb_port1_valid && wb_allow_in;
assign port0_eret      = wb_port0_eret && wb_port0_valid && wb_allow_in;
assign port1_eret      = wb_port1_eret && wb_port1_valid && wb_allow_in;

assign wb_refill       = wb_exccode == `EXC_TLBR;
assign wb_cacheerr     = wb_exccode == 6'h1e;
assign wb_intr         = wb_exccode == 6'h00;
assign wb_other        = !wb_refill && !wb_cacheerr && !wb_intr;
assign wb_valid        = action_commit ;
assign wb_jrop         = wb_branch_jrop && wb_port2_valid;
assign wb_brop         = wb_branch_brop && wb_port2_valid;
assign wb_jrra         = wb_branch_jrra && wb_port2_valid;
assign wb_link         = wb_branch_link && wb_port2_valid;
assign wb_pc           = wb_branch_brpc;
assign wb_link_pc      = wb_bru_link_pc;
assign wb_hint         = wb_bru_hint;
assign wb_taken        = wb_bru_br_taken;
assign wb_exception    = port0_exception || port1_exception;
assign wb_eret         = (port0_eret || port1_eret) && !wb_exception;
assign wb_epc          = !port0_exception ? wb_port1_pc : wb_port0_pc;
assign wb_exccode      = port0_exception ? wb_port0_exccode : wb_port1_exccode;
assign wb_esubcode     = port0_exception ? wb_port0_esubcode: wb_port1_esubcode;
assign wb_cancel       = (port0_exception || port0_eret || port0_roll_back) || 
                         (port1_exception || port1_eret || port1_roll_back) ;
assign ex_entrance   = 
     wb_refill ? wb_tlbr_entrance : csr_ebase;
    // ({32{wb_cacheerr && !cp0_status_bev}}                  &{3'b101,cp0_ebase_exceptionbase[16:0],12'h100}
    // |{32{wb_cacheerr && cp0_status_bev}}                   & 32'hbfc00300
    // |{32{wb_intr && !cp0_status_bev && !cp0_cause_iv}}     &{2'b10,cp0_ebase_exceptionbase,12'h180}
    // |{32{wb_intr && !cp0_status_bev && cp0_cause_iv}}      &{2'b10,cp0_ebase_exceptionbase,12'h200}
    // |{32{wb_intr && cp0_status_bev && !cp0_cause_iv}}      & 32'hbfc00380
    // |{32{wb_intr && cp0_status_bev && cp0_cause_iv}}       & 32'hbfc00400
    // |{32{wb_other && !cp0_status_bev}}                     & {2'b10,cp0_ebase_exceptionbase,12'h180}
    // |{32{wb_other && cp0_status_bev}}                      & 32'hbfc00380);
assign wb_target = port0_exception ? ex_entrance                 :
                   port0_roll_back ? {wb_port0_pc + `GRLEN'b100} :
                   port1_exception ? ex_entrance                 : 
                   port1_roll_back ? {wb_port1_pc + `GRLEN'b100} :
                                                         eret_epc;
// badvaddr
assign wb_badvaddr = port0_exception ? (({`GRLEN{wb_port0_src == `EX_LSU}} & (badvaddr_ex2_valid ? badvaddr_ex2 : lsu_badvaddr)) | ({`GRLEN{wb_port0_src == `EX_NONE0}} & wb_port0_pc)) : 
                                       (({`GRLEN{wb_port1_src == `EX_LSU}} & (badvaddr_ex2_valid ? badvaddr_ex2 : lsu_badvaddr)) | ({`GRLEN{wb_port1_src == `EX_NONE1}} & wb_port1_pc)) ;
assign wb_badinstr = port0_exception ? wb_port0_inst : wb_port1_inst;

//basic
assign wb_allow_in = 1'b1;

// debug
assign debug0_wb_pc       = wb_port0_pc;
assign debug1_wb_pc       = wb_port1_pc;
assign debug0_wb_rf_wnum  = wb_port0_rf_target;
assign debug1_wb_rf_wnum  = wb_port1_rf_target;
assign debug0_wb_rf_wdata = wdata1;
assign debug1_wb_rf_wdata = wdata2;
assign debug0_wb_rf_wen   = wen1 && wb_port0_valid;
assign debug1_wb_rf_wen   = wen2 && wb_port1_valid;

// performance counter
reg [31:0]  wb_issue_num;
reg [31:0]  wb_dualissue_num;

always @(posedge clk) begin 
    //issue num                                                   
    if (!resetn) wb_issue_num <= 32'd0;
    else if (wb_port0_valid || wb_port1_valid) wb_issue_num <= wb_issue_num + 32'd1;      
    //dual issue num                                             
    if (!resetn) wb_dualissue_num <= 32'd0;
    else if (wb_port0_valid && wb_port1_valid) wb_dualissue_num <= wb_dualissue_num + 32'd1;
end

reg [31:0] wb_debug_counter;
reg [31:0] wb_dynamic_inst_cnt;
wire debug_trigger = (wb_port0_pc == `GRLEN'h001c8e68 && wb_port0_valid) ||
                     (wb_port1_pc == `GRLEN'h001c8e68 && wb_port1_valid);

always @(posedge clk) begin
    if (!resetn)            wb_debug_counter <= 32'd0;
    else if (debug_trigger) wb_debug_counter <= wb_debug_counter + 32'd1;

    if (!resetn)            wb_dynamic_inst_cnt <= 32'd0;
    else if (wb_port0_valid && wb_port1_valid && wb_port2_valid) wb_dynamic_inst_cnt <= wb_dynamic_inst_cnt + 32'd3;
    else if (wb_port0_valid && wb_port1_valid || wb_port0_valid && wb_port2_valid || wb_port1_valid && wb_port2_valid) wb_dynamic_inst_cnt <= wb_dynamic_inst_cnt + 32'd2;
    else if (wb_port0_valid || wb_port1_valid || wb_port2_valid) wb_dynamic_inst_cnt <= wb_dynamic_inst_cnt + 32'd1;
end

endmodule
