`include "common.vh"
`include "decoded.vh"


module ex1_stage(
    input               clk,
    input               resetn,
    //basic
    //exception
    input               exception,
    input               eret,
    output [`GRLEN-1:0] lsu_badvaddr,
    input               bru_cancel_ex2,
    input               bru_port_ex2,
    input               bru_ignore_ex2,
    input               bru_cancel_all_ex2,
    input               wb_cancel,
    input [`LSOC1K_CSR_OUTPUT_BIT-1:0] csr_output,
    // pipe in
    output                ex1_allow_in,
    // port0
    input                 ex1_port0_valid,
    input [`GRLEN-1:0]    ex1_port0_pc,
    input [31:0]          ex1_port0_inst,
    input [`EX_SR-1 : 0]  ex1_port0_src,
    input [4 :0]          ex1_port0_rf_target,
    input                 ex1_port0_rf_wen,
    input                 ex1_port0_ll,
    input                 ex1_port0_sc,
    input                 ex1_port0_type,
    // input                 ex1_port0_has_microop,
    // port1
    input                 ex1_port1_valid,
    input [`GRLEN-1:0]    ex1_port1_pc,
    input [31:0]          ex1_port1_inst,
    input [`EX_SR-1 : 0]  ex1_port1_src,
    input [4 :0]          ex1_port1_rf_target,
    input                 ex1_port1_rf_wen,
    input                 ex1_port1_ll,
    input                 ex1_port1_sc,
    input                 ex1_port1_type,
    // input                 ex1_port1_is_microop,
    // port2
    input                 ex1_port2_type,
    // pipe out
    input                       ex2_allow_in,
    // port0
    output                      ex2_port0_valid,
    output reg [`EX_SR-1 : 0]   ex2_port0_src,
    output reg [31:0]           ex2_port0_inst,
    output reg [`GRLEN-1:0]     ex2_port0_pc,
    output reg [4:0]            ex2_port0_rf_target,
    output reg                  ex2_port0_rf_wen,
    output reg                  ex2_port0_ll,
    output reg                  ex2_port0_sc,
    output reg                  ex2_port0_type,
    // output reg                  ex2_port0_has_microop,
    // port1
    output                      ex2_port1_valid,
    output reg [`EX_SR-1 : 0]   ex2_port1_src,
    output reg [31:0]           ex2_port1_inst,
    output reg [`GRLEN-1:0]     ex2_port1_pc,
    output reg [4:0]            ex2_port1_rf_target,
    output reg                  ex2_port1_rf_wen,
    output reg                  ex2_port1_ll,
    output reg                  ex2_port1_sc,
    output reg                  ex2_port1_type,
    // output reg                  ex2_port1_is_microop,
    // port2
    output reg                  ex2_port2_type,
    //REG
    input [`GRLEN-1:0]          ex1_lsu_fw_data,
    input                       ex1_rdata0_0_lsu_fw,
    input                       ex1_rdata0_1_lsu_fw,
    input                       ex1_rdata1_0_lsu_fw,
    input                       ex1_rdata1_1_lsu_fw,
    input                       ex1_port0_a_lsu_fw,
    input                       ex1_port0_b_lsu_fw,
    input                       ex1_port1_a_lsu_fw,
    input                       ex1_port1_b_lsu_fw,
    input                       ex1_mdu_a_lsu_fw,
    input                       ex1_mdu_b_lsu_fw,
    input                       ex1_bru_a_lsu_fw,
    input                       ex1_bru_b_lsu_fw,
    input                       ex1_lsu_base_lsu_fw,
    input                       ex1_lsu_offset_lsu_fw,
    input                       ex1_lsu_wdata_lsu_fw,

    output reg [`GRLEN-1:0]     ex2_lsu_fw_data,
    output reg                  ex2_rdata0_0_lsu_fw,
    output reg                  ex2_rdata0_1_lsu_fw,
    output reg                  ex2_rdata1_0_lsu_fw,
    output reg                  ex2_rdata1_1_lsu_fw,
    output reg                  ex2_bru_a_lsu_fw,
    output reg                  ex2_bru_b_lsu_fw,
    //ALU1
    input [`GRLEN-1:0]                    ex1_port0_a,
    input [`GRLEN-1:0]                    ex1_port0_b,
    input [`LSOC1K_ALU_CODE_BIT-1:0]      ex1_port0_op,
    input [`GRLEN-1:0]                    ex1_port0_c, 
    input                                 ex1_port0_a_ignore,
    input                                 ex1_port0_b_ignore,
    input                                 ex1_port0_b_get_a,
    input                                 ex1_port0_double,
    output reg [`GRLEN-1:0]               ex2_port0_a,
    output reg [`GRLEN-1:0]               ex2_port0_b,
    output reg [`LSOC1K_ALU_CODE_BIT-1:0] ex2_port0_op,
    output reg [`GRLEN-1:0]               ex2_port0_c,
    output reg                            ex2_port0_double,
    output [`GRLEN-1:0]                   ex1_alu0_res,
    //ALU2
    input [`GRLEN-1:0]                    ex1_port1_a,
    input [`GRLEN-1:0]                    ex1_port1_b,
    input [`LSOC1K_ALU_CODE_BIT-1:0]      ex1_port1_op,
    input [`GRLEN-1:0]                    ex1_port1_c,
    input                                 ex1_port1_a_ignore,
    input                                 ex1_port1_b_ignore,
    input                                 ex1_port1_b_get_a,
    input                                 ex1_port1_double,
    output reg [`GRLEN-1:0]               ex2_port1_a,
    output reg [`GRLEN-1:0]               ex2_port1_b,
    output reg [`LSOC1K_ALU_CODE_BIT-1:0] ex2_port1_op,
    output reg [`GRLEN-1:0]               ex2_port1_c,
    output reg                            ex2_port1_double,
    output [`GRLEN-1:0]                   ex1_alu1_res,
    //MDU
    input [`LSOC1K_MDU_CODE_BIT-1:0]      ex1_mdu_op,
    input [`GRLEN-1:0]                    ex1_mdu_a,
    input [`GRLEN-1:0]                    ex1_mdu_b,
    output reg [`LSOC1K_MDU_CODE_BIT-1:0] ex2_mdu_op,
    output reg [`GRLEN-1:0]               ex2_mdu_a,
    output reg [`GRLEN-1:0]               ex2_mdu_b,

    output                                mul_valid,
    output [`GRLEN-1:0]                   mul_a,
    output [`GRLEN-1:0]                   mul_b,
    output                                mul_signed,
    output                                mul_double,
    output                                mul_hi,
    output                                mul_short,

    output                                div_valid,
    output [`GRLEN-1:0]                   div_a,
    output [`GRLEN-1:0]                   div_b,
    output                                div_signed,
    output                                div_double,
    output                                div_mod,

    input [`GRLEN-1:0]                    ex2_mul_res,
    input [`GRLEN-1:0]                    ex2_div_res,
    input                                 ex1_mul_ready,
    input                                 ex1_div_ready,
    //BRANCH
    input                                 ex1_bru_delay,
    input [`LSOC1K_BRU_CODE_BIT-1:0]      ex1_bru_op,
    input [`GRLEN-1:0]                    ex1_bru_a,
    input [`GRLEN-1:0]                    ex1_bru_b,
    input [`GRLEN-1:0]                    ex1_bru_offset,
    input                                 ex1_bru_br_taken,
    input [`GRLEN-1:0]                    ex1_bru_br_target,
    input [`LSOC1K_PRU_HINT:0]            ex1_bru_hint,
    input                                 ex1_bru_link,
    input                                 ex1_bru_jrra,
    input                                 ex1_bru_brop,
    input                                 ex1_bru_jrop,
    input [`GRLEN-1:0]                    ex1_bru_pc,
    input [2:0]                           ex1_bru_port,
    input                                 ex1_branch_valid,

    output reg                            ex2_bru_delay,
    output reg [`LSOC1K_BRU_CODE_BIT-1:0] ex2_bru_op,
    output reg [`GRLEN-1:0]               ex2_bru_a,
    output reg [`GRLEN-1:0]               ex2_bru_b,
    output reg [`GRLEN-1:0]               ex2_bru_br_target,
    output reg [`GRLEN-1:0]               ex2_bru_offset,
    output reg                            ex2_bru_br_taken,
    output reg [`LSOC1K_PRU_HINT:0]       ex2_bru_hint,
    output reg [`GRLEN-1:0]               ex2_bru_link_pc,
    output reg                            ex2_bru_link,
    output reg                            ex2_bru_jrra,
    output reg                            ex2_bru_jrop,
    output reg                            ex2_bru_brop,
    output reg                            ex2_bru_valid,
    output reg [`GRLEN-1:0]               ex2_bru_pc,
    output reg [ 2:0]                     ex2_bru_port,

    output [`GRLEN-1:0]         bru_target,
    output [`GRLEN-1:0]         bru_pc,
    output                      bru_cancel,
    output                      bru_port,
    output                      bru_ignore,
    output                      bru_cancel_all,
    output                      bru_valid,
    output [`LSOC1K_PRU_HINT:0] bru_hint,
    output                      bru_sign,
    output                      bru_taken,
    output                      bru_brop,
    output                      bru_jrop,
    output                      bru_jrra,
    output                      bru_link,
    output [`GRLEN-1:0]         bru_link_pc,
    output                      bru_delay,
    //LSU
    input   [`LSOC1K_LSU_CODE_BIT-1:0]     ex1_lsu_op, 
    input   [`GRLEN-1:0]                   ex1_lsu_base,
    input   [`GRLEN-1:0]                   ex1_lsu_offset,
    input   [`GRLEN-1:0]                   ex1_lsu_wdata,
    output reg [2:0]                       ex2_lsu_shift,
    output reg [`LSOC1K_LSU_CODE_BIT-1:0]  ex2_lsu_op, 
    output reg [`GRLEN-1:0]                ex2_lsu_wdata,
    output reg                             ex2_lsu_recv,
    output reg                             ex2_lsu_adem,
    output reg                             ex2_lsu_ale,
    //NONE0
    input [`GRLEN-1:0]                     ex1_none0_result,
    input                                  ex1_none0_exception,
    input [`LSOC1K_CSR_BIT -1:0]           ex1_none0_csr_addr,
    input [5 :0]                           ex1_none0_exccode,
    input [`GRLEN-1:0]                     ex1_none0_csr_a,
    input [`GRLEN-1:0]                     ex1_none0_csr_result,
    input [`LSOC1K_NONE_INFO_BIT-1:0]      ex1_none0_info,
    input [`LSOC1K_CSR_CODE_BIT-1:0]       ex1_none0_op, 
    output reg                             ex2_none0_exception,
    output reg [`GRLEN-1:0]                ex2_none0_result,
    output reg [`LSOC1K_CSR_BIT -1:0]      ex2_none0_csr_addr,
    output reg [`LSOC1K_CSR_CODE_BIT-1:0]  ex2_none0_op,
    output reg [5 :0]                      ex2_none0_exccode,
    output reg [`GRLEN-1:0]                ex2_none0_csr_result,
    output reg [`LSOC1K_NONE_INFO_BIT-1:0] ex2_none0_info,
    //NONE1
    input [`GRLEN-1:0]                     ex1_none1_result,
    input                                  ex1_none1_exception,
    input [`LSOC1K_CSR_BIT -1:0]           ex1_none1_csr_addr,
    input [5 :0]                           ex1_none1_exccode,
    input [`GRLEN-1:0]                     ex1_none1_csr_a,
    input [`GRLEN-1:0]                     ex1_none1_csr_result,
    input [`LSOC1K_NONE_INFO_BIT-1:0]      ex1_none1_info,
    input [`LSOC1K_CSR_CODE_BIT-1:0]       ex1_none1_op, 
    output reg                             ex2_none1_exception,
    output reg [`GRLEN-1:0]                ex2_none1_result,
    output reg [`LSOC1K_CSR_BIT -1:0]      ex2_none1_csr_addr,
    output reg [`LSOC1K_CSR_CODE_BIT-1:0]  ex2_none1_op,
    output reg [5 :0]                      ex2_none1_exccode,
    output reg [`GRLEN-1:0]                ex2_none1_csr_result,
    output reg [`LSOC1K_NONE_INFO_BIT-1:0] ex2_none1_info,
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
    output [`GRLEN-1:0] data_pc,
    output              data_cancel,
    output              data_prefetch,
    output              data_ll,
    output              data_sc,
    input               data_addr_ok,
    //tlb interface
    output              tlb_req,
    output [`LSOC1K_TLB_CODE_BIT-1:0] tlb_op,
    input               tlb_recv,
    input               tlb_finish,
    input [`GRLEN-1:0]  tlb_index,

    input               data_exception,
    input   [ 5:0]      data_excode,
    input   [`GRLEN-1:0]data_badvaddr,

    output              cache_req,
    output [4:0]        cache_op,
    //forward
    input [4:0]         ex1_raddr0_0,
    input [4:0]         ex1_raddr0_1,
    input [4:0]         ex1_raddr1_0,
    input [4:0]         ex1_raddr1_1,
    input [4:0]         ex1_raddr2_0,
    input [4:0]         ex1_raddr2_1,

    input [`GRLEN-1:0]  ex2_alu0_res,
    input [`GRLEN-1:0]  ex2_alu1_res,
    input [`GRLEN-1:0]  ex2_lsu_res,
    input [`GRLEN-1:0]  ex2_none0_res,
    input [`GRLEN-1:0]  ex2_none1_res
);

////// define
wire rst = !resetn;
wire lsu_finish;
reg ex1_lsu_fw_his;
reg ex1_alu0_a_fw_his,ex1_alu0_b_fw_his,ex1_alu1_a_fw_his,ex1_alu1_b_fw_his;
reg ex1_bru_a_fw_his,ex1_bru_b_fw_his;

wire r1_1_w1_fw;
wire r1_2_w1_fw;
wire r1_1_w2_fw;
wire r1_2_w2_fw;
wire r2_1_w1_fw;
wire r2_2_w1_fw;
wire r2_1_w2_fw;
wire r2_2_w2_fw;
wire r3_1_w1_fw;
wire r3_2_w1_fw;
wire r3_1_w2_fw;
wire r3_2_w2_fw;

wire r1_1_fw;
wire r1_2_fw;
wire r2_1_fw;
wire r2_2_fw;
wire r3_1_fw;
wire r3_2_fw;

wire [`GRLEN-1:0] wdata1;
wire [`GRLEN-1:0] wdata2;
wire [`GRLEN-1:0] r1_1_fw_data;
wire [`GRLEN-1:0] r1_2_fw_data;
wire [`GRLEN-1:0] r2_1_fw_data;
wire [`GRLEN-1:0] r2_2_fw_data;
wire [`GRLEN-1:0] r3_1_fw_data;
wire [`GRLEN-1:0] r3_2_fw_data;

wire change;

//alu0
wire [`GRLEN-1:0] alu0_a = ex1_port0_a_lsu_fw ? ex1_lsu_fw_data : ex1_port0_a;
wire [`GRLEN-1:0] alu0_b = ex1_port0_b_lsu_fw ? ex1_lsu_fw_data : ex1_port0_b;

alu alu0(   .a          (alu0_a),
            .b          (alu0_b),
            .double_word(ex1_port0_double),
            .alu_op     (ex1_port0_op),
            .c          (ex1_port0_c),
            .Result     (ex1_alu0_res)
        );

//alu1
wire [`GRLEN-1:0] alu1_a = ex1_port1_a_lsu_fw ? ex1_lsu_fw_data : ex1_port1_a;
wire [`GRLEN-1:0] alu1_b = ex1_port1_b_lsu_fw ? ex1_lsu_fw_data : ex1_port1_b;

alu alu1(   .a          (alu1_a),
            .b          (alu1_b),
            .double_word(ex1_port1_double),
            .alu_op     (ex1_port1_op),
            .c          (ex1_port1_c),
            .Result     (ex1_alu1_res)
        );

always @(posedge clk) begin
    if(ex1_allow_in && ex1_port0_valid) begin
        ex2_port0_op     <= ex1_port0_op;
        ex2_port0_c      <= ex1_port0_c;
        ex2_port0_double <= ex1_port0_double;
    end

    if (ex1_allow_in || rst) ex1_alu0_a_fw_his <= 1'd0;
    else if (ex2_allow_in && r1_1_fw && !ex1_port0_a_ignore) ex1_alu0_a_fw_his <= 1'd1;

    if (ex1_allow_in || rst) ex1_alu0_b_fw_his <= 1'd0;
    else if (ex2_allow_in && r1_2_fw && !ex1_port0_b_ignore) ex1_alu0_b_fw_his <= 1'd1;

    if(ex2_allow_in && !ex1_alu0_a_fw_his) ex2_port0_a <= (r1_1_fw && !ex1_port0_a_ignore) ? r1_1_fw_data : alu0_a;

    if(ex2_allow_in && !ex1_alu0_b_fw_his) ex2_port0_b <= (r1_2_fw && !ex1_port0_b_ignore) ? r1_2_fw_data : alu0_b;
end

always @(posedge clk) begin
    if(ex1_allow_in && ex1_port1_valid) begin
        ex2_port1_op     <= ex1_port1_op;
        ex2_port1_c      <= ex1_port1_c;
        ex2_port1_double <= ex1_port1_double;
    end

    if      (ex1_allow_in || rst) ex1_alu1_a_fw_his <= 1'd0;
    else if (ex2_allow_in && r2_1_fw && !ex1_port1_a_ignore) ex1_alu1_a_fw_his <= 1'd1;

    if      (ex1_allow_in || rst) ex1_alu1_b_fw_his <= 1'd0;
    else if (ex2_allow_in && r2_2_fw && !ex1_port1_b_ignore) ex1_alu1_b_fw_his <= 1'd1;

    if(ex2_allow_in && !ex1_alu1_a_fw_his) ex2_port1_a <= (r2_1_fw && !ex1_port1_a_ignore) ? r2_1_fw_data : alu1_a;

    if(ex2_allow_in && !ex1_alu1_b_fw_his) ex2_port1_b <= (r2_2_fw && !ex1_port1_b_ignore) ? r2_2_fw_data : alu1_b;
end

//lsu
wire ex1_lsu_valid = (((ex1_port0_src == `EX_LSU) && ex1_port0_valid) || //port0 & port1 share
                     ((ex1_port1_src == `EX_LSU) && ex1_port1_valid)) && !eret && !exception && !wb_cancel;
wire [`GRLEN-1:0] lsu_base = ex1_lsu_base_lsu_fw ? ex1_lsu_fw_data : ex1_lsu_base;
wire [`GRLEN-1:0] lsu_offset = ex1_lsu_offset_lsu_fw ? ex1_lsu_fw_data : ex1_lsu_offset;
wire [`GRLEN-1:0] lsu_wdata = ex1_lsu_wdata_lsu_fw ? ex1_lsu_fw_data : ex1_lsu_wdata;
assign data_pc     = ((ex1_port0_src == `EX_LSU) && ex1_port0_valid) ? ex1_port0_pc : ex1_port1_pc;
wire lsu_ale      ;
wire lsu_adem;
wire lsu_recv;
wire align_need;

lsu_s1 lsu_s1(
    .clk            (clk                    ),
    .resetn         (resetn                 ),

    .valid          (ex1_lsu_valid          ),
    .lsu_op         (ex1_lsu_op             ), 
    .base           (lsu_base               ), 
    .offset         (lsu_offset             ),
    .wdata          (lsu_wdata              ),
    .tlb_req        ((ex1_none0_op[`LSOC1K_TLB_VALID] && ex1_port0_valid) || (ex1_none1_op[`LSOC1K_TLB_VALID] && ex1_port1_valid)),
    .data_exception (data_exception         ),
    .data_badvaddr  (data_badvaddr          ),
    .tlb_finish     (tlb_finish             ),

    .data_req       (data_req               ),
    .data_addr      (data_addr              ),
    .data_addr_ok   (data_addr_ok           ),
    .data_wr        (data_wr                ),
    .data_wstrb     (data_wstrb             ),
    .data_wdata     (data_wdata             ),
    .data_prefetch  (data_prefetch          ),
    .data_ll        (data_ll                ),
    .data_sc        (data_sc                ),

    .lsu_finish     (lsu_finish             ),
    .lsu_ale        (lsu_ale                ),
    .lsu_adem       (lsu_adem               ),
    .lsu_recv       (lsu_recv               ),

    .csr_output     (csr_output             ),
    .change         (ex1_allow_in           ),
    .eret           (eret                   ),
    .exception      (exception || wb_cancel ),
    .badvaddr       (lsu_badvaddr           )
);

always @(posedge clk) begin
    if (rst) begin
        ex2_lsu_ale   <= 1'd0;
        ex2_lsu_adem  <= 1'd0;
    end
    else if (ex1_allow_in) begin
        ex2_lsu_ale   <= lsu_ale;
        ex2_lsu_adem  <= lsu_adem;
        ex2_lsu_op    <= ex1_lsu_op; 
        ex2_lsu_wdata <= ex1_lsu_wdata_lsu_fw ? ex1_lsu_fw_data : ex1_lsu_wdata;
        ex2_lsu_shift <= data_addr[2:0];
    end

    // if(data_addr_ok) begin
    //     ex2_lsu_op    <= ex1_lsu_op; 
    //     ex2_lsu_shift <= data_addr[2:0];
    // end
end

always @(posedge clk) begin
    if      (rst         ) ex2_lsu_recv  <= 1'd0    ;
    else if (ex1_allow_in) ex2_lsu_recv  <= lsu_recv;
    else if (ex2_allow_in) ex2_lsu_recv  <= 1'd0    ;
end

assign data_cancel = bru_cancel & ((!ex1_bru_port[1] & !ex1_bru_port[2]) || ((ex1_port1_src == `EX_LSU) && ex1_port1_valid && ex1_bru_port[1])) || bru_cancel_ex2;

//branch
reg first_trial;

wire port0_branch_valid  = ex1_port0_src == `EX_BRU && ex1_port0_valid;
wire port1_branch_valid  = ex1_port1_src == `EX_BRU && ex1_port1_valid;
wire branch_valid        = port0_branch_valid || port1_branch_valid || ex1_bru_port[0];
wire port0_cancel_allow  = (ex1_port0_src == `EX_BRU && ex1_port0_valid) && !ex1_port0_type && !ex1_bru_delay;
wire port1_cancel_allow  = (ex1_port1_src == `EX_BRU && ex1_port1_valid) && !ex1_port1_type && !ex1_bru_delay;
wire port2_cancel_allow  = ex1_bru_port[0]                               && !ex1_port2_type && !ex1_bru_delay;
wire cancel_allow        = (port0_cancel_allow || port1_cancel_allow || port2_cancel_allow) && first_trial;
assign bru_port          = port1_branch_valid;
wire [31:0] ex1_bru_inst = port0_branch_valid ? ex1_port0_inst  : ex1_port1_inst;
wire [`GRLEN-1:0] bru_a  = ex1_bru_a_lsu_fw   ? ex1_lsu_fw_data : ex1_bru_a     ;
wire [`GRLEN-1:0] bru_b  = ex1_bru_b_lsu_fw   ? ex1_lsu_fw_data : ex1_bru_b     ;
assign bru_delay         = branch_valid && !(port0_cancel_allow || port1_cancel_allow || port2_cancel_allow);

always @(posedge clk) begin
    if(ex1_allow_in) first_trial <= 1'b1;
    else first_trial <= 1'b0;    
end

branch branch(
    .branch_valid (branch_valid     ),
    .branch_a     (bru_a            ),
    .branch_b     (bru_b            ),
    .branch_op    (ex1_bru_op       ),
    .branch_pc    (ex1_bru_pc       ),
    .branch_inst  (ex1_bru_inst     ),
    .branch_taken (ex1_bru_br_taken ),
    .branch_target(ex1_bru_br_target),
    .branch_offset(ex1_bru_offset   ),
    .cancel_allow (cancel_allow     ),
    // pc interface
    .bru_cancel   (bru_cancel       ),
    .bru_target   (bru_target       ),
    .bru_valid    (bru_valid        ),
    .bru_taken    (bru_taken        ),
    .bru_link_pc  (bru_link_pc      ),
    .bru_pc       (bru_pc           )
);

always @(posedge clk) begin
    if (rst) begin
        ex2_bru_link     <= 1'b0;
        ex2_bru_jrra     <= 1'b0;
        ex2_bru_jrop     <= 1'b0;
        ex2_bru_brop     <= 1'b0;
        ex2_bru_valid    <= 1'b0;
        ex2_bru_br_taken <= 1'b0;
    end
    else if (ex1_allow_in) begin
        ex2_bru_link_pc   <= bru_link_pc      ;
        ex2_bru_link      <= ex1_bru_link     ;
        ex2_bru_jrra      <= ex1_bru_jrra     ;
        ex2_bru_jrop      <= ex1_bru_jrop     ;
        ex2_bru_brop      <= ex1_bru_brop     ;
        ex2_bru_valid     <= branch_valid     ;
        ex2_bru_port[1]   <= ex1_bru_port[1]  ;
        ex2_bru_port[2]   <= ex1_bru_port[2]  ;
        ex2_bru_pc        <= ex1_bru_pc       ;
        ex2_bru_br_taken  <= ex1_bru_br_taken ;
        ex2_bru_hint      <= ex1_bru_hint     ;
        ex2_bru_op        <= ex1_bru_op       ;
        ex2_bru_br_target <= ex1_bru_br_target;
        ex2_bru_offset    <= ex1_bru_offset   ;
        ex2_bru_delay     <= ex1_bru_delay    ;
    end

    if (ex1_allow_in || rst) ex1_bru_a_fw_his <= 1'd0;
    else if (ex2_allow_in && ((ex1_bru_port[0] && r3_1_fw) || (port0_branch_valid && r1_1_fw) || r2_1_fw )) ex1_bru_a_fw_his <= 1'd1;

    if (ex1_allow_in || rst) ex1_bru_b_fw_his <= 1'd0;
    else if (ex2_allow_in && ((ex1_bru_port[0] && r3_2_fw) || (port0_branch_valid && r1_2_fw) || r2_2_fw )) ex1_bru_b_fw_his <= 1'd1;

    if (ex2_allow_in && !ex1_bru_a_fw_his) ex2_bru_a <= ex1_bru_port[0] ? (r3_1_fw ? r3_1_fw_data : bru_a) : port0_branch_valid ? (r1_1_fw ? r1_1_fw_data : bru_a) : (r2_1_fw ? r2_1_fw_data : bru_a);
    if (ex2_allow_in && !ex1_bru_b_fw_his) ex2_bru_b <= ex1_bru_port[0] ? (r3_2_fw ? r3_2_fw_data : bru_b) : port0_branch_valid ? (r1_2_fw ? r1_2_fw_data : bru_b) : (r2_2_fw ? r2_2_fw_data : bru_b);
end

assign bru_hint = ex1_bru_hint;
assign bru_sign = ex1_bru_offset[`GRLEN-1];
assign bru_brop = ex1_bru_brop && branch_valid && cancel_allow;
assign bru_jrop = ex1_bru_jrop && branch_valid && cancel_allow;
assign bru_jrra = ex1_bru_jrra && branch_valid && cancel_allow;
assign bru_link = ex1_bru_link && branch_valid && cancel_allow;

wire port0_cancel     = (ex1_port0_src == `EX_BRU) && ex1_port0_valid && bru_cancel; // used to differ compact branch with branch in WB
assign bru_cancel_all = bru_cancel && ex1_bru_port[0] && !ex1_bru_port[1] && !ex1_bru_port[2];
assign bru_ignore     = ex1_bru_port[2];

//mdu
always @(posedge clk) begin
    if (ex1_allow_in) begin
        ex2_mdu_op <= ex1_mdu_op;
        ex2_mdu_a  <= ex1_mdu_a_lsu_fw ? ex1_lsu_fw_data : ex1_mdu_a;
        ex2_mdu_b  <= ex1_mdu_b_lsu_fw ? ex1_lsu_fw_data : ex1_mdu_b;
    end
end

assign mul_valid  = (((ex1_port0_src == `EX_MUL) && ex1_port0_valid) ||
                     ((ex1_port1_src == `EX_MUL) && ex1_port1_valid)) ;
assign mul_a      = ex1_mdu_a_lsu_fw ? ex1_lsu_fw_data : ex1_mdu_a;
assign mul_b      = ex1_mdu_b_lsu_fw ? ex1_lsu_fw_data : ex1_mdu_b;
assign mul_signed = ex1_mdu_op == `LSOC1K_MDU_MUL_W     ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_W    ||
                    ex1_mdu_op == `LSOC1K_MDU_MUL_D     ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_D    ||
                    ex1_mdu_op == `LSOC1K_MDU_MULW_D_W  ;
assign mul_double = ex1_mdu_op == `LSOC1K_MDU_MUL_D     ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_D    ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_DU   ;
assign mul_hi     = ex1_mdu_op == `LSOC1K_MDU_MULH_W    ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_WU   ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_D    ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_DU   ;
assign mul_short  = ex1_mdu_op == `LSOC1K_MDU_MUL_W     ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_W    ||
                    ex1_mdu_op == `LSOC1K_MDU_MULH_WU   ;

assign div_valid  = (((ex1_port0_src == `EX_DIV) && ex1_port0_valid) ||
                     ((ex1_port1_src == `EX_DIV) && ex1_port1_valid)) ;
assign div_a      = ex1_mdu_a_lsu_fw ? ex1_lsu_fw_data : ex1_mdu_a;
assign div_b      = ex1_mdu_b_lsu_fw ? ex1_lsu_fw_data : ex1_mdu_b;
assign div_signed = ex1_mdu_op == `LSOC1K_MDU_DIV_W     ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_W     ||
                    ex1_mdu_op == `LSOC1K_MDU_DIV_D     ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_D     ;
assign div_double = ex1_mdu_op == `LSOC1K_MDU_DIV_D     ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_D     ||
                    ex1_mdu_op == `LSOC1K_MDU_DIV_DU    ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_DU    ;
assign div_mod    = ex1_mdu_op == `LSOC1K_MDU_MOD_W     ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_WU    ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_D     ||
                    ex1_mdu_op == `LSOC1K_MDU_MOD_DU    ;

//none
wire [`GRLEN-1:0] port0_csrxchg_result;
wire [`GRLEN-1:0] port1_csrxchg_result;

wire [`GRLEN-1:0] none0_csr_a      = ex1_rdata0_0_lsu_fw ? ex1_lsu_fw_data : ex1_none0_csr_a     ;
wire [`GRLEN-1:0] none0_csr_result = ex1_rdata0_1_lsu_fw ? ex1_lsu_fw_data : ex1_none0_csr_result;
wire [`GRLEN-1:0] none1_csr_a      = ex1_rdata1_0_lsu_fw ? ex1_lsu_fw_data : ex1_none1_csr_a     ;
wire [`GRLEN-1:0] none1_csr_result = ex1_rdata1_1_lsu_fw ? ex1_lsu_fw_data : ex1_none1_csr_result;

generate
    genvar i;
    for (i=0; i<`GRLEN; i=i+1) begin: csr_xchg
        assign port0_csrxchg_result[i] = none0_csr_a[i] ? none0_csr_result[i] : ex1_none0_result[i];
        assign port1_csrxchg_result[i] = none1_csr_a[i] ? none1_csr_result[i] : ex1_none1_result[i];
    end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        ex2_none0_exception <= 1'd0;
        ex2_none0_exccode   <= 6'd0;
        ex2_none1_exception <= 1'd0;
        ex2_none1_exccode   <= 6'd0;
    end
    else if(ex1_allow_in && (ex1_port0_valid || ex1_port1_valid)) begin
        ex2_none0_result     <= ex1_none0_result;
        ex2_none0_exception  <= ex1_none0_exception || (ex1_none0_op[`LSOC1K_CACHE_VALID] && ex1_port0_valid && tlb_finish && data_exception);
        ex2_none0_csr_addr   <= ex1_none0_csr_addr;
        ex2_none0_op         <= ex1_none0_op;
        ex2_none0_exccode    <= ex1_none0_exception ? ex1_none0_exccode : data_excode;
        ex2_none0_csr_result <= (ex1_none0_op[`LSOC1K_CSR_VALID] && ex1_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_CSR_CSRXCHG) ? port0_csrxchg_result :
                                (ex1_none0_op[`LSOC1K_TLB_VALID] && (ex1_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBP ||
                                                                     ex1_none0_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBR )) ? tlb_index : 
                                                                                                                           none0_csr_result;
        ex2_none0_info       <= ex1_none0_info;
        
        ex2_none1_result     <= ex1_none1_result;
        ex2_none1_exception  <= ex1_none1_exception || (ex1_none1_op[`LSOC1K_CACHE_VALID] && ex1_port1_valid && tlb_finish && data_exception);
        ex2_none1_csr_addr   <= ex1_none1_csr_addr;
        ex2_none1_op         <= ex1_none1_op;
        ex2_none1_exccode    <= ex1_none1_exccode ? ex1_none1_exccode : data_excode;
        ex2_none1_csr_result <= (ex1_none1_op[`LSOC1K_CSR_VALID] && ex1_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_CSR_CSRXCHG) ? port1_csrxchg_result :
                                (ex1_none1_op[`LSOC1K_TLB_VALID] && (ex1_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBP ||
                                                                     ex1_none1_op[`LSOC1K_CSR_OP] == `LSOC1K_TLB_TLBR )) ? tlb_index : 
                                                                                                                           none1_csr_result;
        ex2_none1_info       <= ex1_none1_info;
    end
end

//tlb
reg tlb_first_trial; // cache op uses this too
always @(posedge clk) begin
    if(ex1_allow_in  ) tlb_first_trial <= 1'b1;
    else if (tlb_recv) tlb_first_trial <= 1'b0;    
end

reg [1:0] tlb_workstate; // cache op uses this too
always @(posedge clk) begin
    if      (rst || tlb_finish                ) tlb_workstate <= 2'd0;
    else if ((tlb_req || cache_req)&& tlb_recv) tlb_workstate <= 2'd1;
end

wire tlb_allow_in = (tlb_workstate == 2'd0 && !tlb_req && !cache_req) || (tlb_workstate == 2'd1 && tlb_finish);

wire port0_tlb_req = ex1_none0_op[`LSOC1K_TLB_VALID] && ex1_port0_valid && tlb_first_trial && !ex1_none0_exception;
wire port1_tlb_req = ex1_none1_op[`LSOC1K_TLB_VALID] && ex1_port1_valid && tlb_first_trial && !(ex1_none0_exception && ex1_port0_valid) && !ex1_none1_exception; //not need to consider (!eret && !exception && !wb_cancel), because the pipe is flushed 

wire port0_cache_req = ex1_none0_op[`LSOC1K_CACHE_VALID] && ex1_port0_valid && tlb_first_trial && !ex1_none0_exception;
wire port1_cache_req = ex1_none1_op[`LSOC1K_CACHE_VALID] && ex1_port1_valid && tlb_first_trial && !(ex1_none0_exception && ex1_port0_valid) && !ex1_none1_exception; //not need to consider (!eret && !exception && !wb_cancel), because the pipe is flushed 

assign tlb_req   = port0_tlb_req || port1_tlb_req;
assign cache_req = port0_cache_req || port1_cache_req;
assign tlb_op    = port1_tlb_req ? ex1_none1_op[`LSOC1K_CSR_OP] :
                                  ex1_none0_op[`LSOC1K_CSR_OP] ;

assign cache_op = (port1_tlb_req || port1_cache_req) ? ex1_port1_inst[4:0] : //invtlb also uses this port
                                                       ex1_port0_inst[4:0] ;

//////basic
assign change =     
    ((((ex1_port0_src == `EX_LSU) && ex1_port0_valid) || ((ex1_port1_src == `EX_LSU) && ex1_port1_valid)) ? lsu_finish    : 1'd1) &&
    ((((ex1_port0_src == `EX_MUL) && ex1_port0_valid) || ((ex1_port1_src == `EX_MUL) && ex1_port1_valid)) ? ex1_mul_ready : 1'd1) &&
    ((((ex1_port0_src == `EX_DIV) && ex1_port0_valid) || ((ex1_port1_src == `EX_DIV) && ex1_port1_valid)) ? ex1_div_ready : 1'd1) ;
assign ex1_allow_in = ex2_allow_in && change && tlb_allow_in;
always @(posedge clk) begin
    if (rst) begin
        ex2_port0_rf_target <= 5'd0;
        ex2_port0_rf_wen    <= 1'd0;
        ex2_port0_ll        <= 1'd0;
        ex2_port0_sc        <= 1'd0;

        ex2_port1_rf_target <= 5'd0;
        ex2_port1_rf_wen    <= 1'd0;
        ex2_port1_ll        <= 1'd0;
        ex2_port1_sc        <= 1'd0;
    end
    else if(ex1_allow_in) begin
        ex2_port0_src       <= ex1_port0_src;
        ex2_port0_inst      <= ex1_port0_inst;
        ex2_port0_pc        <= ex1_port0_pc;
        ex2_port0_rf_target <= ex1_port0_valid ? ex1_port0_rf_target : 5'd0;
        ex2_port0_rf_wen    <= ex1_port0_rf_wen;
        ex2_port0_ll        <= ex1_port0_ll;
        ex2_port0_sc        <= ex1_port0_sc;

        ex2_port1_src       <= ex1_port1_src;
        ex2_port1_inst      <= ex1_port1_inst;
        ex2_port1_pc        <= ex1_port1_pc;
        ex2_port1_rf_target <= ex1_port1_valid ? ex1_port1_rf_target : 5'd0;
        ex2_port1_rf_wen    <= ex1_port1_rf_wen;
        ex2_port1_ll        <= ex1_port1_ll;
        ex2_port1_sc        <= ex1_port1_sc;
    end
end

reg port0_valid;
reg port1_valid;

always @(posedge clk) begin // internal valid
    if      (rst || eret || exception || wb_cancel || bru_cancel_all_ex2) port0_valid <= 1'd0;
    else if (ex1_allow_in                                               ) port0_valid <= ex1_port0_valid && !bru_cancel_all && !bru_cancel_ex2;
    else if (ex2_allow_in                                               ) port0_valid <= 1'd0;
end

always @(posedge clk) begin // internal valid
    if      (rst || eret || exception || wb_cancel || (bru_cancel_ex2 && !bru_port_ex2 && !bru_ignore_ex2) || bru_cancel_all_ex2) port1_valid <= 1'd0;
    else if (ex1_allow_in) port1_valid <= ex1_port1_valid && !bru_cancel_all  && !(port0_cancel || (bru_cancel && ex1_bru_port[0] && !bru_ignore)) && !bru_cancel_ex2;
    else if (ex2_allow_in) port1_valid <= 1'd0;
end

always @(posedge clk) begin
    if     (rst || eret || exception || wb_cancel) ex2_bru_port[0] <= 1'b0;
    else if(ex1_allow_in                         ) ex2_bru_port[0] <= ex1_bru_port[0] && !bru_cancel_ex2;
    else if(ex2_allow_in                         ) ex2_bru_port[0] <= 1'b0;
end

assign ex2_port0_valid = port0_valid;
assign ex2_port1_valid = port1_valid;

////forwarding related
//forwarding check
assign r1_1_w1_fw =	ex2_port0_valid && (ex1_raddr0_0 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0);
assign r1_2_w1_fw = ex2_port0_valid && (ex1_raddr0_1 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0);
assign r1_1_w2_fw =	ex2_port1_valid && (ex1_raddr0_0 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0);
assign r1_2_w2_fw = ex2_port1_valid && (ex1_raddr0_1 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0);

assign r2_1_w1_fw =	ex2_port0_valid && (ex1_raddr1_0 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0);
assign r2_2_w1_fw =	ex2_port0_valid && (ex1_raddr1_1 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0);
assign r2_1_w2_fw =	ex2_port1_valid && (ex1_raddr1_0 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0);
assign r2_2_w2_fw =	ex2_port1_valid && (ex1_raddr1_1 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0);

assign r3_1_w1_fw =	ex2_port0_valid && (ex1_raddr2_0 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0);
assign r3_2_w1_fw =	ex2_port0_valid && (ex1_raddr2_1 == ex2_port0_rf_target) && (ex2_port0_rf_target != 5'd0);
assign r3_1_w2_fw =	ex2_port1_valid && (ex1_raddr2_0 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0);
assign r3_2_w2_fw =	ex2_port1_valid && (ex1_raddr2_1 == ex2_port1_rf_target) && (ex2_port1_rf_target != 5'd0);

assign r1_1_fw = r1_1_w1_fw || r1_1_w2_fw;	// read port need forwarding
assign r1_2_fw = r1_2_w1_fw || r1_2_w2_fw;
assign r2_1_fw = r2_1_w1_fw || r2_1_w2_fw;
assign r2_2_fw = r2_2_w1_fw || r2_2_w2_fw;
assign r3_1_fw = r3_1_w1_fw || r3_1_w2_fw;
assign r3_2_fw = r3_2_w1_fw || r3_2_w2_fw;

assign wdata1 = ({`GRLEN{ex2_port0_src == `EX_ALU0   }} & ex2_alu0_res   ) |
                ({`GRLEN{ex2_port0_src == `EX_BRU    }} & ex2_bru_link_pc) |
                ({`GRLEN{ex2_port0_src == `EX_NONE0  }} & ex2_none0_res  ) |
                ({`GRLEN{ex2_port0_src == `EX_MUL    }} & ex2_mul_res    ) |
                ({`GRLEN{ex2_port0_src == `EX_DIV    }} & ex2_div_res    ) ;

assign wdata2 = ({`GRLEN{ex2_port1_src == `EX_ALU1   }} & ex2_alu1_res   ) |
                ({`GRLEN{ex2_port1_src == `EX_BRU    }} & ex2_bru_link_pc) |
                ({`GRLEN{ex2_port1_src == `EX_NONE1  }} & ex2_none1_res  ) |
                ({`GRLEN{ex2_port1_src == `EX_MUL    }} & ex2_mul_res    ) |
                ({`GRLEN{ex2_port1_src == `EX_DIV    }} & ex2_div_res    ) ;

assign r1_1_fw_data = r1_1_w2_fw ? wdata2 : wdata1;	// forwarding data
assign r1_2_fw_data = r1_2_w2_fw ? wdata2 : wdata1;
assign r2_1_fw_data = r2_1_w2_fw ? wdata2 : wdata1;
assign r2_2_fw_data = r2_2_w2_fw ? wdata2 : wdata1;
assign r3_1_fw_data = r3_1_w2_fw ? wdata2 : wdata1;
assign r3_2_fw_data = r3_2_w2_fw ? wdata2 : wdata1;

wire rdata0_0_lsu_fw = r1_1_fw && ((r1_1_w2_fw && (ex2_port1_src == `EX_LSU)) || (!r1_1_w2_fw && (ex2_port0_src == `EX_LSU)));
wire rdata0_1_lsu_fw = r1_2_fw && ((r1_2_w2_fw && (ex2_port1_src == `EX_LSU)) || (!r1_2_w2_fw && (ex2_port0_src == `EX_LSU)));
wire rdata1_0_lsu_fw = r2_1_fw && ((r2_1_w2_fw && (ex2_port1_src == `EX_LSU)) || (!r2_1_w2_fw && (ex2_port0_src == `EX_LSU)));
wire rdata1_1_lsu_fw = r2_2_fw && ((r2_2_w2_fw && (ex2_port1_src == `EX_LSU)) || (!r2_2_w2_fw && (ex2_port0_src == `EX_LSU)));
wire rdata2_0_lsu_fw = r3_1_fw && ((r3_1_w2_fw && (ex2_port1_src == `EX_LSU)) || (!r3_1_w2_fw && (ex2_port0_src == `EX_LSU)));
wire rdata2_1_lsu_fw = r3_2_fw && ((r3_2_w2_fw && (ex2_port1_src == `EX_LSU)) || (!r3_2_w2_fw && (ex2_port0_src == `EX_LSU)));

always @(posedge clk) begin
    if (ex1_allow_in) begin
        ex2_port0_type      <= ex1_port0_type;
        ex2_port1_type      <= ex1_port1_type;
        ex2_port2_type      <= ex1_port2_type;
    end
end

always @(posedge clk) begin
    if      (ex1_allow_in || rst) ex1_lsu_fw_his <= 1'd0;
    else if (ex2_allow_in       ) ex1_lsu_fw_his <= 1'd1;

    if (!ex1_lsu_fw_his && ex2_allow_in) begin
        ex2_lsu_fw_data     <= ex2_lsu_res;
    end

    if (ex2_allow_in && !ex1_lsu_fw_his) begin
        ex2_rdata0_0_lsu_fw <= rdata0_0_lsu_fw && (r1_1_fw && !ex1_port0_a_ignore);
        ex2_rdata0_1_lsu_fw <= rdata0_1_lsu_fw && (r1_2_fw && !ex1_port0_b_ignore);
        ex2_rdata1_0_lsu_fw <= rdata1_0_lsu_fw && (r2_1_fw && !ex1_port1_a_ignore);
        ex2_rdata1_1_lsu_fw <= rdata1_1_lsu_fw && (r2_2_fw && !ex1_port1_b_ignore);
        ex2_bru_a_lsu_fw    <= (ex1_bru_port[0] && rdata2_0_lsu_fw) || (ex1_port0_src == `EX_BRU && ex1_port0_valid) && rdata0_0_lsu_fw || (ex1_port1_src == `EX_BRU && ex1_port1_valid) && rdata1_0_lsu_fw;
        ex2_bru_b_lsu_fw    <= (ex1_bru_port[0] && rdata2_1_lsu_fw) || (ex1_port0_src == `EX_BRU && ex1_port0_valid) && rdata0_1_lsu_fw || (ex1_port1_src == `EX_BRU && ex1_port1_valid) && rdata1_1_lsu_fw;
    end
end

// stall counter
reg [31:0] ex1_stall_cnt;
reg [31:0] ex1_stall_lsu_cnt;
reg [31:0] ex1_bru_cnt;

wire stall_happen = !ex1_allow_in && ex2_allow_in;
wire stall_lsu    = stall_happen && (((ex1_port0_src == `EX_LSU) && ex1_port0_valid) || ((ex1_port1_src == `EX_LSU) && ex1_port1_valid)) && !lsu_finish;

always @(posedge clk) begin
    if (rst)               ex1_stall_cnt <= 32'd0;
    else if (stall_happen) ex1_stall_cnt <= ex1_stall_cnt + 32'd1;
end

always @(posedge clk) begin
    if (rst)            ex1_stall_lsu_cnt <= 32'd0;
    else if (stall_lsu) ex1_stall_lsu_cnt <= ex1_stall_lsu_cnt + 32'd1;
end

always @(posedge clk) begin
    if (rst)                               ex1_bru_cnt <= 32'd0;
    else if (branch_valid && ex1_allow_in) ex1_bru_cnt <= ex1_bru_cnt + 32'd1;
end

reg [31:0] debug_pc [31:0];
reg [31:0] debug_va [31:0];
reg [4:0] debug_pointer;
wire debug_cond = (data_addr == 32'h00000630);
wire debug_trigger = debug_cond && (data_wr == 1'b1) && (data_addr_ok && data_req);
always @(posedge clk) begin
    if (rst) begin
        debug_pointer <= 5'b0;
        debug_pc[0] <= 32'b0;
        debug_pc[1] <= 32'b0;
        debug_pc[2] <= 32'b0;
        debug_pc[3] <= 32'b0;
        debug_pc[4] <= 32'b0;
        debug_pc[5] <= 32'b0;
        debug_pc[6] <= 32'b0;
        debug_pc[7] <= 32'b0;
        debug_pc[8] <= 32'b0;
        debug_pc[9] <= 32'b0;
        debug_pc[10] <= 32'b0;
        debug_pc[11] <= 32'b0;
        debug_pc[12] <= 32'b0;
        debug_pc[13] <= 32'b0;
        debug_pc[14] <= 32'b0;
        debug_pc[15] <= 32'b0;
        debug_pc[16] <= 32'b0;
        debug_pc[17] <= 32'b0;
        debug_pc[18] <= 32'b0;
        debug_pc[19] <= 32'b0;
        debug_pc[20] <= 32'b0;
        debug_pc[21] <= 32'b0;
        debug_pc[22] <= 32'b0;
        debug_pc[23] <= 32'b0;
        debug_pc[24] <= 32'b0;
        debug_pc[25] <= 32'b0;
        debug_pc[26] <= 32'b0;
        debug_pc[27] <= 32'b0;
        debug_pc[28] <= 32'b0;
        debug_pc[29] <= 32'b0;
        debug_pc[30] <= 32'b0;
        debug_pc[31] <= 32'b0;
        debug_va[0] <= 32'b0;
        debug_va[1] <= 32'b0;
        debug_va[2] <= 32'b0;
        debug_va[3] <= 32'b0;
        debug_va[4] <= 32'b0;
        debug_va[5] <= 32'b0;
        debug_va[6] <= 32'b0;
        debug_va[7] <= 32'b0;
        debug_va[8] <= 32'b0;
        debug_va[9] <= 32'b0;
        debug_va[10] <= 32'b0;
        debug_va[11] <= 32'b0;
        debug_va[12] <= 32'b0;
        debug_va[13] <= 32'b0;
        debug_va[14] <= 32'b0;
        debug_va[15] <= 32'b0;
        debug_va[16] <= 32'b0;
        debug_va[17] <= 32'b0;
        debug_va[18] <= 32'b0;
        debug_va[19] <= 32'b0;
        debug_va[20] <= 32'b0;
        debug_va[21] <= 32'b0;
        debug_va[22] <= 32'b0;
        debug_va[23] <= 32'b0;
        debug_va[24] <= 32'b0;
        debug_va[25] <= 32'b0;
        debug_va[26] <= 32'b0;
        debug_va[27] <= 32'b0;
        debug_va[28] <= 32'b0;
        debug_va[29] <= 32'b0;
        debug_va[30] <= 32'b0;
        debug_va[31] <= 32'b0;
    end
    else if (debug_trigger) begin
        debug_va[debug_pointer] <= data_wdata;
        debug_pc[debug_pointer] <= ex1_port0_pc;
        debug_pointer <= debug_pointer + 5'd1;
    end
end


endmodule
