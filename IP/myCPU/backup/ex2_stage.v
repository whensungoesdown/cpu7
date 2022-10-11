`include "common.vh"
`include "decoded.vh"

module ex2_stage(
    input               clk,
    input               resetn,
    //basic

    //exception
    input               exception,
    input               eret,
    input               wb_cancel,
    // pipe in
    output                 ex2_allow_in,
    // port 0
    input  [`EX_SR-1 : 0]  ex2_port0_src,
    input  [`GRLEN-1:0]    ex2_port0_pc,
    input  [31:0]          ex2_port0_inst,
    input                  ex2_port0_valid,
    input  [4 :0]          ex2_port0_rf_target,
    input                  ex2_port0_rf_wen,
    input                  ex2_port0_exception,
    input  [5 :0]          ex2_port0_exccode,
    input                  ex2_port0_ll,
    input                  ex2_port0_sc,
    input                  ex2_port0_type,
    // input                  ex2_port0_has_microop,
    // port 1
    input  [`EX_SR-1 : 0]  ex2_port1_src,
    input  [`GRLEN-1:0]    ex2_port1_pc,
    input  [31:0]          ex2_port1_inst,
    input                  ex2_port1_valid,
    input  [4 :0]          ex2_port1_rf_target,
    input                  ex2_port1_rf_wen,
    input                  ex2_port1_exception,
    input  [5 :0]          ex2_port1_exccode,
    input                  ex2_port1_ll,
    input                  ex2_port1_sc,
    input                  ex2_port1_type,
    // input                  ex2_port1_is_microop,
    // port 2
    input                  ex2_port2_type,
    // pipe out
    input                  wb_allow_in,
    // port 0
    output reg                        wb_port0_valid,
    output reg [`EX_SR-1 : 0]         wb_port0_src,
    output reg [31:0]                 wb_port0_inst,
    output reg [`GRLEN-1:0]           wb_port0_pc,
    output reg [4:0]                  wb_port0_rf_target,
    output reg                        wb_port0_rf_wen,
    output reg [`GRLEN-1:0]           wb_port0_rf_result,
    output reg                        wb_port0_rf_res_lsu,
    output reg                        wb_port0_exception,
    output reg [5 :0]                 wb_port0_exccode,
    output reg                        wb_port0_eret,
    output reg [`LSOC1K_CSR_BIT -1:0] wb_port0_csr_addr,
    output reg                        wb_port0_ll,
    output reg                        wb_port0_sc,
    output reg [`GRLEN-1:0]           wb_port0_csr_result,
    output reg                        wb_port0_esubcode,
    // output reg                        wb_port0_has_microop,
    // port 1
    output reg                        wb_port1_valid,
    output reg [`EX_SR-1 : 0]         wb_port1_src,
    output reg [31:0]                 wb_port1_inst,
    output reg [`GRLEN-1:0]           wb_port1_pc,
    output reg [4:0]                  wb_port1_rf_target,
    output reg                        wb_port1_rf_wen,
    output reg [`GRLEN-1:0]           wb_port1_rf_result,
    output reg                        wb_port1_rf_res_lsu,
    output reg                        wb_port1_exception,
    output reg [5 :0]                 wb_port1_exccode,
    output reg                        wb_port1_eret,
    output reg [`LSOC1K_CSR_BIT -1:0] wb_port1_csr_addr,
    output reg                        wb_port1_ll,
    output reg                        wb_port1_sc,
    output reg [`GRLEN-1:0]           wb_port1_csr_result,
    output reg                        wb_port1_esubcode,
    // output reg                        wb_porti_is_microop,
    // port 2
    output reg                        wb_port2_valid,
    //REG
    input [`GRLEN-1:0]                ex2_lsu_fw_data,
    input                             ex2_rdata0_0_lsu_fw,
    input                             ex2_rdata0_1_lsu_fw,
    input                             ex2_rdata1_0_lsu_fw,
    input                             ex2_rdata1_1_lsu_fw,
    input                             ex2_bru_a_lsu_fw,
    input                             ex2_bru_b_lsu_fw,
    //ALU1
    input   [`GRLEN-1:0]                ex2_port0_a,
    input   [`GRLEN-1:0]                ex2_port0_b,
    input   [`LSOC1K_ALU_CODE_BIT-1:0]  ex2_port0_op,
    input   [`GRLEN-1:0]                ex2_port0_c,
    input                               ex2_port0_double,
    output  [`GRLEN-1:0]                ex2_alu0_res,
    //ALU2
    input   [`GRLEN-1:0]                ex2_port1_a,
    input   [`GRLEN-1:0]                ex2_port1_b,
    input   [`LSOC1K_ALU_CODE_BIT-1:0]  ex2_port1_op,
    input   [`GRLEN-1:0]                ex2_port1_c,
    input                               ex2_port1_double,
    output  [`GRLEN-1:0]                ex2_alu1_res,
    //BRANCH
    input                            ex2_bru_delay,
    input [`LSOC1K_BRU_CODE_BIT-1:0] ex2_bru_op,
    input [`GRLEN-1:0]               ex2_bru_a,
    input [`GRLEN-1:0]               ex2_bru_b,
    input                            ex2_bru_br_taken,
    input [`GRLEN-1:0]               ex2_bru_br_target,
    input [`GRLEN-1:0]               ex2_bru_offset,
    input [`LSOC1K_PRU_HINT:0]       ex2_bru_hint,
    input [`GRLEN-1:0]               ex2_bru_link_pc,
    input                            ex2_bru_link,
    input                            ex2_bru_brop,
    input                            ex2_bru_jrop,
    input                            ex2_bru_jrra,
    input [ 2:0]                     ex2_bru_port,
    input                            ex2_bru_valid,
    input [`GRLEN-1:0]               ex2_bru_pc,
    output reg [`LSOC1K_PRU_HINT:0]  wb_bru_hint,
    output reg                       wb_bru_link,
    output reg                       wb_bru_brop,
    output reg                       wb_bru_jrop,
    output reg                       wb_bru_jrra,
    output reg [2:0]                 wb_bru_port,
    output reg                       wb_bru_valid,
    output reg                       wb_bru_br_taken,
    output reg [`GRLEN-1:0]          wb_bru_pc,
    output reg [`GRLEN-1:0]          wb_bru_link_pc,

    output [`GRLEN-1:0]         bru_target_ex2,
    output [`GRLEN-1:0]         bru_pc_ex2,
    output                      bru_cancel_ex2,
    output                      bru_cancel_all_ex2,
    output                      bru_ignore_ex2,
    output                      bru_port_ex2,
    output                      bru_valid_ex2,
    output [`LSOC1K_PRU_HINT:0] bru_hint_ex2,
    output                      bru_sign_ex2,
    output                      bru_taken_ex2,
    output                      bru_brop_ex2,
    output                      bru_jrop_ex2,
    output                      bru_jrra_ex2,
    output                      bru_link_ex2,
    output [`GRLEN-1:0]         bru_link_pc_ex2,
    //LSU
    output [`GRLEN-1:0]                ex2_lsu_res,
    output reg [`GRLEN-1:0]            wb_lsu_res,
    input                              ex2_lsu_ale,
    input                              ex2_lsu_adem,
    input [`LSOC1K_LSU_CODE_BIT-1:0]   ex2_lsu_op,
    input                              ex2_lsu_recv,
    input [2 :0]                       ex2_lsu_shift,
    //MDU
    input [`LSOC1K_MDU_CODE_BIT-1:0] ex2_mdu_op,
    input [`GRLEN-1:0]               ex2_mdu_a,
    input [`GRLEN-1:0]               ex2_mdu_b,
    input                            ex2_mul_ready,
    input [`GRLEN-1:0]               ex2_mul_res,
    `ifdef LA64
    output [`GRLEN-1:0]              ex2_div_res,
    `elsif LA32
    input [`GRLEN-1:0]               ex2_div_res,
    `endif
    //NONE0
    input [`GRLEN-1:0]                      ex2_none0_result,
    input [`LSOC1K_CSR_BIT -1:0]            ex2_none0_csr_addr,
    input [`GRLEN-1:0]                      ex2_none0_csr_result,
    input [`LSOC1K_NONE_INFO_BIT-1:0]       ex2_none0_info,
    input [`LSOC1K_CSR_CODE_BIT-1:0]        ex2_none0_op, 
    output reg [`LSOC1K_CSR_CODE_BIT-1:0]   wb_none0_op,
    output reg [`LSOC1K_NONE_INFO_BIT-1:0]  wb_none0_info,
    //NONE1
    input [`GRLEN-1:0]                      ex2_none1_result,
    input [`LSOC1K_CSR_BIT -1:0]            ex2_none1_csr_addr,
    input [`GRLEN-1:0]                      ex2_none1_csr_result,
    input [`LSOC1K_NONE_INFO_BIT-1:0]       ex2_none1_info,
    input [`LSOC1K_CSR_CODE_BIT-1:0]        ex2_none1_op, 
    output reg [`LSOC1K_CSR_CODE_BIT-1:0]   wb_none1_op,
    output reg [`LSOC1K_NONE_INFO_BIT-1:0]  wb_none1_info,
    //memory interface
    output              data_recv,
    input               data_scsucceed,
    input  [`GRLEN-1:0] data_rdata,
    input               data_data_ok,
    input               data_exception,
    input  [ 5:0]       data_excode,
    input  [`GRLEN-1:0] data_badvaddr,
    output              data_cancel_ex2,
    output [`GRLEN-1:0] badvaddr_ex2,
    output              badvaddr_ex2_valid
);

//temp
wire ex2_alu0_valid;
wire ex2_alu1_valid;
wire ex2_none0_valid;
wire ex2_none1_valid;

////// define
wire    rst = !resetn;
wire    lsu_res_valid;
wire    change;
wire    allow_in_temp;

wire       port0_exception;
wire [5:0] port0_exccode  ;
wire       port0_ale      ;
wire       port0_adem     ;
wire       port0_int      ;
wire       port1_exception;
wire [5:0] port1_exccode  ;
wire       port1_ale      ;
wire       port1_adem     ;
wire       port1_int      ;

//alu0
wire [`GRLEN-1:0] alu_port0_a = ex2_rdata0_0_lsu_fw ? ex2_lsu_fw_data : ex2_port0_a;
wire [`GRLEN-1:0] alu_port0_b = ex2_rdata0_1_lsu_fw ? ex2_lsu_fw_data : ex2_port0_b;

alu alu0(   .a          (alu_port0_a     ),
            .b          (alu_port0_b     ),
            .alu_op     (ex2_port0_op    ),
            .c          (ex2_port0_c     ),
            .double_word(ex2_port0_double),
            .Result     (ex2_alu0_res    )
        );

assign ex2_alu0_valid = ex2_port0_valid && (ex2_port0_src == `EX_ALU0);

//alu1
wire [`GRLEN-1:0] alu_port1_a = ex2_rdata1_0_lsu_fw ? ex2_lsu_fw_data : ex2_port1_a;
wire [`GRLEN-1:0] alu_port1_b = ex2_rdata1_1_lsu_fw ? ex2_lsu_fw_data : ex2_port1_b;

alu alu1(   .a          (alu_port1_a     ),
            .b          (alu_port1_b     ), 
            .alu_op     (ex2_port1_op    ),
            .c          (ex2_port1_c     ),
            .double_word(ex2_port1_double),
            .Result     (ex2_alu1_res    )
        );

assign ex2_alu1_valid = ex2_port1_valid && (ex2_port1_src == `EX_ALU1);

//lsu
wire lsu_valid = (((ex2_port0_src == `EX_LSU) && (ex2_port0_valid)) || //port0 & port1 share
                 ((ex2_port1_src == `EX_LSU) && (ex2_port1_valid))) && 
                 !eret && !exception && !wb_cancel && !ex2_lsu_ale;

lsu_s2 lsu_s2(
    .clk                (clk                        ),
    .resetn             (resetn                     ),

    .valid              (lsu_valid                  ),
    .lsu_op             (ex2_lsu_op                 ),
    .lsu_recv           (ex2_lsu_recv               ),
    .lsu_shift          (ex2_lsu_shift              ),

    .data_recv          (data_recv                  ),
    .data_scsucceed     (data_scsucceed             ),
    .data_rdata         (data_rdata                 ),
    .data_exception     (data_exception && !data_cancel_ex2),
    .data_excode        (data_excode                ),
    .data_badvaddr      (data_badvaddr              ),
    .data_data_ok       (data_data_ok               ),

    .read_result        (ex2_lsu_res                ),
    .lsu_res_valid      (lsu_res_valid              ),

	.exception			(exception				    ),
    .change             (change                     ),
    .badvaddr           (badvaddr_ex2               ),
    .badvaddr_valid     (badvaddr_ex2_valid         )
);

assign data_cancel_ex2 = (bru_cancel_ex2 & ((!ex2_bru_port[1] & !bru_ignore_ex2) || ((ex2_port1_src == `EX_LSU) && ex2_port1_valid && ex2_bru_port[1]))) || wb_cancel;

//bru
reg first_trial;

wire port0_branch_valid = ex2_port0_src == `EX_BRU && ex2_port0_valid;
wire port1_branch_valid = ex2_port1_src == `EX_BRU && ex2_port1_valid;
wire branch_valid       = port0_branch_valid || port1_branch_valid || ex2_bru_port[0];
wire port0_cancel_allow = (ex2_port0_src == `EX_BRU && ex2_port0_valid) && (ex2_port0_type || ex2_bru_delay);
wire port1_cancel_allow = (ex2_port1_src == `EX_BRU && ex2_port1_valid) && (ex2_port1_type || ex2_bru_delay);
wire port2_cancel_allow = ex2_bru_port[0]                               && (ex2_port2_type || ex2_bru_delay);
wire cancel_allow       = (port0_cancel_allow || port1_cancel_allow || port2_cancel_allow) && first_trial;
assign bru_port_ex2     = port1_branch_valid;// || ex2_bru_port[1];
wire [31:0] ex2_bru_inst= port0_branch_valid ? ex2_port0_inst : ex2_port1_inst;
wire [`GRLEN-1:0] bru_a = ex2_bru_a_lsu_fw ? ex2_lsu_fw_data : ex2_bru_a;
wire [`GRLEN-1:0] bru_b = ex2_bru_b_lsu_fw ? ex2_lsu_fw_data : ex2_bru_b;

wire port0_cancel = (ex2_port0_src == `EX_BRU) && ex2_port0_valid && bru_cancel_ex2; // used to differ compact branch with branch in WB

always @(posedge clk) begin
    if(ex2_allow_in) first_trial <= 1'b1;
    else first_trial <= 1'b0;
end

branch bru_s2(
    .branch_valid (branch_valid     ),
    .branch_a     (bru_a            ),
    .branch_b     (bru_b            ),
    .branch_op    (ex2_bru_op       ),
    .branch_pc    (ex2_bru_pc       ),
    .branch_inst  (ex2_bru_inst     ),
    .branch_taken (ex2_bru_br_taken ),
    .branch_target(ex2_bru_br_target),
    .branch_offset(ex2_bru_offset   ),
    .cancel_allow (cancel_allow     ),
    // pc interface
    .bru_cancel   (bru_cancel_ex2   ),
    .bru_target   (bru_target_ex2   ),
    .bru_valid    (bru_valid_ex2    ),
    .bru_taken    (bru_taken_ex2    ),
    .bru_link_pc  (bru_link_pc_ex2  ),
    .bru_pc       (bru_pc_ex2       )
);

assign bru_hint_ex2 = ex2_bru_hint;
assign bru_sign_ex2 = ex2_bru_offset[`GRLEN-1];
assign bru_brop_ex2 = ex2_bru_brop && branch_valid && cancel_allow;
assign bru_jrop_ex2 = ex2_bru_jrop && branch_valid && cancel_allow;
assign bru_jrra_ex2 = ex2_bru_jrra && branch_valid && cancel_allow;
assign bru_link_ex2 = ex2_bru_link && branch_valid && cancel_allow;

assign bru_ignore_ex2 = ex2_bru_port[2];
assign bru_cancel_all_ex2 = bru_cancel_ex2 && ex2_bru_port[0] && !ex2_bru_port[1] && !ex2_bru_port[2];

//mul
// wire [31:0] mul_lo_w,mul_hi_w;
// wire [31:0] mul_lo_wu,mul_hi_wu;
// wire [63:0] mul_lo,mul_hi;
// wire [63:0] mul_lo_u,mul_hi_u;

// wire ex2_mul_valid = (((ex2_port0_src == `EX_MUL) && ex2_port0_valid) ||
//                      ((ex2_port1_src == `EX_MUL) && ex2_port1_valid)) ;

// assign {mul_hi,mul_lo} = $signed(ex2_mdu_a) * $signed(ex2_mdu_b);
// assign {mul_hi_wu,mul_lo_wu} = ex2_mdu_a[31:0] * ex2_mdu_b[31:0];
// assign {mul_hi_w,mul_lo_w} = $signed(ex2_mdu_a[31:0]) * $signed(ex2_mdu_b[31:0]);
// assign {mul_hi_u,mul_lo_u} = ex2_mdu_a * ex2_mdu_b;

// assign ex2_mul_res = ex2_mdu_op == `LSOC1K_MDU_MUL_W ? {{32{mul_lo[31]}},mul_lo[31:0]} :
//                    ex2_mdu_op == `LSOC1K_MDU_MULH_WU ? {{32{mul_hi_wu[31]}},mul_hi_wu} :
//                    ex2_mdu_op == `LSOC1K_MDU_MULH_W ? {{32{mul_hi_w[31]}},mul_hi_w} :
//                    ex2_mdu_op == `LSOC1K_MDU_MULH_D ? mul_hi :
//                    ex2_mdu_op == `LSOC1K_MDU_MULH_DU ? mul_hi_u :
//                    ex2_mdu_op == `LSOC1K_MDU_MULW_D_W ? {mul_hi_w,mul_lo_w} :
//                    ex2_mdu_op == `LSOC1K_MDU_MULW_D_WU ? {mul_hi_wu,mul_lo_wu} :
//                    mul_lo;

//mdu
wire ex2_mul_valid = (((ex2_port0_src == `EX_MUL) && ex2_port0_valid) ||
                     ((ex2_port1_src == `EX_MUL) && ex2_port1_valid)) ;

wire ex2_div_valid = (((ex2_port0_src == `EX_DIV) && ex2_port0_valid) ||
                     ((ex2_port1_src == `EX_DIV) && ex2_port1_valid)) ;

// wire [31:0] div_w,mod_w,div_wu,mod_wu;
// assign div_w  = $signed(ex2_mdu_a[31:0]) / $signed(ex2_mdu_b[31:0]);
// assign mod_w  = $signed(ex2_mdu_a[31:0]) % $signed(ex2_mdu_b[31:0]);
// assign div_wu = ex2_mdu_a[31:0] / ex2_mdu_b[31:0];
// assign mod_wu = ex2_mdu_a[31:0] % ex2_mdu_b[31:0];
`ifdef LA64
wire [63:0] div_d,mod_d,div_du,mod_du;

assign div_d  = $signed(ex2_mdu_a) / $signed(ex2_mdu_b);
assign mod_d  = $signed(ex2_mdu_a) % $signed(ex2_mdu_b);
assign div_du = ex2_mdu_a / ex2_mdu_b;
assign mod_du = ex2_mdu_a % ex2_mdu_b;

assign ex2_div_res = ex2_mdu_op == `LSOC1K_MDU_DIV_W  ? {{32{div_w[31]}},div_w}   :
                     ex2_mdu_op == `LSOC1K_MDU_MOD_W  ? {{32{mod_w[31]}},mod_w}   :
                     ex2_mdu_op == `LSOC1K_MDU_DIV_WU ? {{32{div_wu[31]}},div_wu} :
                     ex2_mdu_op == `LSOC1K_MDU_MOD_WU ? {{32{mod_wu[31]}},mod_wu} :
                     ex2_mdu_op == `LSOC1K_MDU_DIV_D  ? div_d                     :
                     ex2_mdu_op == `LSOC1K_MDU_MOD_D  ? mod_d                     :
                     ex2_mdu_op == `LSOC1K_MDU_DIV_DU ? div_du                    :
                     ex2_mdu_op == `LSOC1K_MDU_MOD_DU ? mod_du                    :
                                                        64'd0                     ;
// `elsif LA32
// assign ex2_div_res = ex2_mdu_op == `LSOC1K_MDU_DIV_W  ? div_w   :
//                      ex2_mdu_op == `LSOC1K_MDU_MOD_W  ? mod_w   :
//                      ex2_mdu_op == `LSOC1K_MDU_DIV_WU ? div_wu  :
//                      ex2_mdu_op == `LSOC1K_MDU_MOD_WU ? mod_wu  :
//                                                         32'd0   ;
`endif

//none0
assign  ex2_none0_valid   = (ex2_port0_src == `EX_NONE0) && (ex2_port0_valid);
always @(posedge clk) begin
    if(ex2_allow_in) begin
        wb_port0_csr_addr   <= ex2_none0_csr_addr;
        wb_port0_csr_result <= ex2_none0_csr_result;
        wb_none0_op         <= ex2_none0_op;
        wb_none0_info       <= ex2_none0_info;
    end
end

//none1
assign  ex2_none1_valid   = (ex2_port1_src == `EX_NONE1) && (ex2_port1_valid);
always @(posedge clk) begin
    if(ex2_allow_in) begin
        wb_port1_csr_addr   <= ex2_none1_csr_addr;
        wb_port1_csr_result <= ex2_none1_csr_result;
        wb_none1_op         <= ex2_none1_op;
        wb_none1_info       <= ex2_none1_info;
    end
end

//////basic
assign allow_in_temp = wb_allow_in && change;
assign ex2_allow_in  = allow_in_temp;  ////TODO: MAY WAIT FOR DEBUG

always @(posedge clk) begin
    if (rst) begin
        wb_port0_rf_target <= 5'd0;
        wb_port0_rf_wen    <= 1'd0;
        wb_port1_rf_target <= 5'd0;
        wb_port1_rf_wen    <= 1'd0;
    
        wb_bru_link        <= 1'b0;
        wb_bru_brop        <= 1'b0;
        wb_bru_jrop        <= 1'b0;
        wb_bru_jrra        <= 1'b0;
        wb_bru_valid       <= 1'b0;
    end
    else if(ex2_allow_in) begin  //TODO!!!!!!!!!
        wb_port0_src       <= ex2_port0_src      ;
        wb_port0_inst      <= ex2_port0_inst     ;
        wb_port0_pc        <= ex2_port0_pc       ;
        wb_port0_rf_target <= ex2_port0_rf_target;
        wb_port0_rf_wen    <= ex2_port0_rf_wen   ;

        wb_port1_src       <= ex2_port1_src      ;
        wb_port1_inst      <= ex2_port1_inst     ;
        wb_port1_pc        <= ex2_port1_pc       ;
        wb_port1_rf_target <= ex2_port1_rf_target;
        wb_port1_rf_wen    <= ex2_port1_rf_wen   ;
        
        wb_bru_link        <= ex2_bru_link                ;
        wb_bru_br_taken    <= bru_taken_ex2               ;
        wb_bru_brop        <= ex2_bru_brop && branch_valid;
        wb_bru_jrop        <= ex2_bru_jrop && branch_valid;
        wb_bru_jrra        <= ex2_bru_jrra && branch_valid;
        wb_bru_port        <= ex2_bru_port                ;
        wb_bru_valid       <= ex2_bru_valid               ;
        wb_bru_hint        <= ex2_bru_hint                ;
        wb_bru_pc          <= ex2_bru_pc                  ;
        wb_bru_link_pc     <= bru_link_pc_ex2             ;
    end
    else begin
        wb_bru_link        <= 1'd0;
        wb_bru_brop        <= 1'd0;
        wb_bru_jrop        <= 1'd0;
        wb_bru_jrra        <= 1'd0;
    end
end

always @(posedge clk) begin
    if (rst || exception || eret || wb_cancel || bru_cancel_all_ex2) begin
        wb_port0_valid  <= 1'd0;
        wb_port1_valid  <= 1'd0;
    end
    else if(ex2_allow_in) begin
        wb_port0_valid  <= ex2_port0_valid && !bru_cancel_all_ex2;
        wb_port1_valid  <= ex2_port1_valid && !(port0_cancel || (bru_cancel_ex2 && ex2_bru_port[0] && !bru_ignore_ex2)) && !bru_cancel_all_ex2;
    end  
    else begin
        wb_port0_valid  <= 1'b0;
        wb_port1_valid  <= 1'b0;
    end

    if (rst || exception || eret || wb_cancel) wb_port2_valid  <= 1'b0;
    else if(ex2_allow_in) wb_port2_valid  <= ex2_bru_port[0];
    else wb_port2_valid  <= 1'b0;
end

//result
wire port0_change;
wire port0_alu_change  = (ex2_port0_src == `EX_ALU0  ) && ex2_alu0_valid;
wire port0_lsu_change  = (ex2_port0_src == `EX_LSU   ) && lsu_res_valid;
wire port0_bru_change  = (ex2_port0_src == `EX_BRU   ) && ex2_bru_valid;
wire port0_none_change = (ex2_port0_src == `EX_NONE0 ) && ex2_none0_valid;
wire port0_div_change  = (ex2_port0_src == `EX_DIV   ) && ex2_div_valid;// && (div_complete || div_completed);
wire port0_mul_change  = (ex2_port0_src == `EX_MUL   ) && ex2_mul_valid && ex2_mul_ready;

wire port1_change;
wire port1_alu_change  = (ex2_port1_src == `EX_ALU1  ) && ex2_alu1_valid;
wire port1_lsu_change  = (ex2_port1_src == `EX_LSU   ) && lsu_res_valid;
wire port1_bru_change  = (ex2_port1_src == `EX_BRU   ) && ex2_bru_valid;
wire port1_none_change = (ex2_port1_src == `EX_NONE1 ) && ex2_none1_valid;
wire port1_div_change  = (ex2_port1_src == `EX_DIV   ) && ex2_div_valid;// && (div_complete || div_completed);
wire port1_mul_change  = (ex2_port1_src == `EX_MUL   ) && ex2_mul_valid && ex2_mul_ready;

always @(posedge clk) begin
    if(port0_change) wb_port0_rf_res_lsu <= port0_lsu_change;

    if(port1_change) wb_port1_rf_res_lsu <= port1_lsu_change;

    if(data_data_ok) wb_lsu_res <= ex2_lsu_res;
end

assign port0_change = port0_alu_change || port0_lsu_change || port0_bru_change || port0_none_change || port0_div_change || port0_mul_change || !ex2_port0_valid;
assign port1_change = port1_alu_change || port1_lsu_change || port1_bru_change || port1_none_change || port1_div_change || port1_mul_change || !ex2_port1_valid;

assign change = port0_change && port1_change;

wire [`GRLEN-1:0] port0_res_input = ({`GRLEN{port0_alu_change  }} & ex2_alu0_res     ) |
                                    ({`GRLEN{port0_bru_change  }} & ex2_bru_link_pc  ) |
                                    ({`GRLEN{port0_none_change }} & ex2_none0_result ) |
                                    ({`GRLEN{port0_div_change  }} & ex2_div_res      ) |
                                    ({`GRLEN{port0_mul_change  }} & ex2_mul_res      ) ;

wire [`GRLEN-1:0] port1_res_input = ({`GRLEN{port1_alu_change  }} & ex2_alu1_res     ) |
                                    ({`GRLEN{port1_bru_change  }} & ex2_bru_link_pc  ) |
                                    ({`GRLEN{port1_none_change }} & ex2_none1_result ) |
                                    ({`GRLEN{port1_div_change  }} & ex2_div_res      ) |
                                    ({`GRLEN{port1_mul_change  }} & ex2_mul_res      ) ;


always @(posedge clk) begin
    if (port0_change) begin
        wb_port0_rf_result <= port0_res_input;
    end
end

always @(posedge clk) begin
    if (port1_change) begin
        wb_port1_rf_result <= port1_res_input;
    end
end

//exception
assign port0_ale     = port0_lsu_change  && ex2_lsu_ale;
assign port0_adem    = port0_lsu_change  && (ex2_lsu_adem || data_excode == `EXC_ADEM);
assign port0_int     = 1'b0;//port0_none_change && none0_i_int;
wire   port0_lsu     = port0_lsu_change && data_exception;

assign port0_exception = 
    ex2_port0_exception
    ||  port0_ale
    ||  port0_adem
    ||  port0_int
    ||  port0_lsu;
    
assign port1_ale     = port1_lsu_change && ex2_lsu_ale;
assign port1_adem    = port1_lsu_change && (ex2_lsu_adem || data_excode == `EXC_ADEM);
assign port1_int     = 1'b0;
wire   port1_lsu     = port1_lsu_change && data_exception;

assign port1_exception = 
    ex2_port1_exception
    ||  port1_ale
    ||  port1_adem
    ||  port1_int
    ||  port1_lsu;

assign port0_exccode = 
    ex2_port0_exception ? ex2_port0_exccode :
        port0_ale       ? `EXC_ALE          :
        port0_adem      ? `EXC_ADEM         :
        port0_int       ? `EXC_INT          :
        port0_lsu       ? data_excode       :
                          0                 ;
assign port1_exccode = 
    ex2_port1_exception ? ex2_port1_exccode : 
        port1_ale       ? `EXC_ALE          :
        port1_adem      ? `EXC_ADEM         :
        port1_int       ? `EXC_INT          :
        port1_lsu       ? data_excode       :
                          0                 ;

always @(posedge clk) begin
    //exception
    if (port0_change) 
    begin
        wb_port0_exception <= port0_exception;
        wb_port0_exccode   <= port0_exccode  ;
        wb_port0_eret      <= ex2_none0_info[`LSOC1K_CSR_EXCPT] == `LSOC1K_CSR_ERET;
        wb_port0_esubcode  <= port0_adem;
    end
end

always @(posedge clk) begin
    //exception
    if (port1_change)
    begin
        wb_port1_exception <= port1_exception;
        wb_port1_exccode   <= port1_exccode  ;
        wb_port1_eret      <= ex2_none1_info[`LSOC1K_CSR_EXCPT] == `LSOC1K_CSR_ERET;
        wb_port1_esubcode  <= port1_adem;
    end
end

// ll sc
always @(posedge clk) begin
    if(rst)
    begin
        wb_port0_ll <= 1'b0;
        wb_port0_sc <= 1'b0;
    end
    else if (port0_change) 
    begin
        wb_port0_ll <= ex2_port0_ll;
        wb_port0_sc <= ex2_port0_sc;
    end
end

always @(posedge clk) begin
    if(rst)
    begin
        wb_port1_ll <= 1'b0;
        wb_port1_sc <= 1'b0;
    end
    else if (port1_change) 
    begin
        wb_port1_ll <= ex2_port1_ll;
        wb_port1_sc <= ex2_port1_sc;
    end
end

// stall counter
reg [31:0] ex2_stall_cnt;
reg [31:0] ex2_stall_lsu_cnt;
reg [31:0] ex2_stall_div_cnt;
wire stall_happen = !ex2_allow_in && wb_allow_in;
wire stall_lsu    = stall_happen && (((ex2_port0_src == `EX_LSU) && ex2_port0_valid && !port0_lsu_change) || ((ex2_port1_src == `EX_LSU) && ex2_port1_valid) && !port1_lsu_change);
wire stall_div    = stall_happen && (((ex2_port0_src == `EX_DIV) && ex2_port0_valid && !port0_div_change) || ((ex2_port1_src == `EX_DIV) && ex2_port1_valid && !port1_div_change));

always @(posedge clk) begin
    if (rst)                ex2_stall_cnt <= 32'd0;
    else if (stall_happen)  ex2_stall_cnt <= ex2_stall_cnt + 32'd1;
end

always @(posedge clk) begin
    if (rst)             ex2_stall_lsu_cnt <= 32'd0;
    else if (stall_lsu)  ex2_stall_lsu_cnt <= ex2_stall_lsu_cnt + 32'd1;
end

always @(posedge clk) begin
    if (rst)             ex2_stall_div_cnt <= 32'd0;
    else if (stall_div)  ex2_stall_div_cnt <= ex2_stall_div_cnt + 32'd1;
end

endmodule
