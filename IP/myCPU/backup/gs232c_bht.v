module gs232c_bht(
    input  wire        clock         ,
    input  wire        reset         ,
    input  wire [31:0] bt_pc         ,
    input  wire        pc_go         ,
    input  wire        iq_go         ,
    // group br
    input  wire        br_brop       ,
    input  wire        br_cancel     ,
    input  wire [4 :0] br_hint       ,
    input  wire [31:0] br_pc         ,
    input  wire        br_sign       ,
    input  wire        br_taken      ,
    input  wire [31:0] br_target     ,
    input  wire        pr_cancel     ,
    input  wire        buf_cancel    ,
    output wire [3 :0] o_hint        ,
    output wire [3 :0] o_taken       ,
    input  wire [7 :0] raminit_index ,
    input  wire        raminit_valid ,
    // group b
    output wire [5 :0] tbl_cnt0_hi_a ,
    output wire        tbl_cnt0_hi_ce,
    output wire        tbl_cnt0_hi_en,
    input  wire [7 :0] tbl_cnt0_hi_rd,
    output wire [7 :0] tbl_cnt0_hi_wd,
    output wire [7 :0] tbl_cnt0_hi_we,
    output wire [5 :0] tbl_cnt0_lo_a ,
    output wire        tbl_cnt0_lo_ce,
    output wire        tbl_cnt0_lo_en,
    input  wire [7 :0] tbl_cnt0_lo_rd,
    output wire [7 :0] tbl_cnt0_lo_wd,
    output wire [7 :0] tbl_cnt0_lo_we,
    output wire [7 :0] tbl_cnt1_hi_a ,
    output wire        tbl_cnt1_hi_ce,
    output wire        tbl_cnt1_hi_en,
    input  wire [3 :0] tbl_cnt1_hi_rd,
    output wire [3 :0] tbl_cnt1_hi_wd,
    output wire [3 :0] tbl_cnt1_hi_we,
    output wire [7 :0] tbl_cnt1_lo_a ,
    output wire        tbl_cnt1_lo_ce,
    output wire        tbl_cnt1_lo_en,
    input  wire [3 :0] tbl_cnt1_lo_rd,
    output wire [3 :0] tbl_cnt1_lo_wd,
    output wire [3 :0] tbl_cnt1_lo_we,
    output wire [7 :0] tbl_tag1_a    ,
    output wire        tbl_tag1_ce   ,
    output wire        tbl_tag1_en   ,
    input  wire [31:0] tbl_tag1_rd   ,
    output wire [31:0] tbl_tag1_wd   ,
    output wire [31:0] tbl_tag1_we   ,
    input  wire [24:0] bhr_br        ,
    input  wire [20:0] bhr_bt         
);
// group br
wire [1 :0] br_hint_blck        ;
wire [1 :0] br_hint_dofs        ;
wire [3 :0] br_hint_dofs_dec    ;
wire        br_hint_index       ;
wire        br_mark             ;
// group b
wire        berr                ;
wire [7 :0] buf_next            ;
wire [7 :0] buf_read            ;
wire        corr                ;
reg         modify              ;
reg  [7 :0] modify_cmp1         ;
wire        modify_cnt0_hi      ;
wire        modify_cnt0_lo      ;
wire        modify_cnt1_hi      ;
wire        modify_cnt1_lo      ;
reg  [1 :0] modify_dofs         ;
wire [3 :0] modify_dofs_dec     ;
wire        modify_hit1         ;
reg  [5 :0] modify_idx0         ;
reg  [7 :0] modify_idx1         ;
reg         modify_index        ;
reg         modify_mark         ;
reg  [2 :0] modify_offs         ;
wire [7 :0] modify_offs_dec     ;
wire [7 :0] pred_conf0          ;
wire [3 :0] pred_conf1          ;
wire [3 :0] pred_hit1           ;
wire [3 :0] pred_hit1_fw        ;
reg         ptr_r               ;
reg         ptr_w               ;
reg         read                ;
reg  [7 :0] read_cmp1           ;
reg  [5 :0] read_idx0           ;
reg  [7 :0] read_idx1           ;
reg  [2 :0] read_offs           ;
wire        req                 ;
wire [7 :0] req_h_cmp1          ;
wire [5 :0] req_h_idx0          ;
wire [7 :0] req_h_idx1          ;
wire [2 :0] req_h_offs          ;
wire [7 :0] req_h_offs_dec      ;
wire [7 :0] req_t_cmp1          ;
wire [5 :0] req_t_idx0          ;
wire [7 :0] req_t_idx1          ;
wire [2 :0] req_t_offs          ;
wire        state_b             ;
wire [7 :0] state_b_cmp1        ;
wire [29:0] state_b_dyna        ;
wire [5 :0] state_b_idx0        ;
wire [7 :0] state_b_idx1        ;
wire [2 :0] state_b_offs        ;
wire        state_c             ;
wire        state_i             ;
wire        state_m             ;
wire        state_p             ;
wire [7 :0] state_p_cmp1        ;
wire [5 :0] state_p_idx0        ;
wire [7 :0] state_p_idx1        ;
wire [2 :0] state_p_offs        ;
wire        state_w             ;
wire [7 :0] state_w_cmp1        ;
wire [5 :0] state_w_idx0        ;
wire [7 :0] state_w_idx1        ;
wire [2 :0] state_w_offs        ;
wire [7 :0] tbl_cnt0_hi_rd_fw   ;
wire [3 :0] tbl_cnt0_hi_rd_sel_o;
wire        tbl_cnt0_lo_rd_sel  ;
wire [3 :0] tbl_cnt1_hi_rd_fw   ;
wire        tbl_cnt1_lo_rd_sel  ;
wire [20:0] bhr_br_next         ;
wire [23:0] bhr_br_pred         ;
// Declaring RAM
reg  [7:0] buf_data[1:0];
assign br_hint_blck             = br_hint[3:2];
assign br_hint_dofs             = br_hint[1:0];
assign br_hint_index            = br_hint[4];
assign br_mark                  = br_taken ^ br_sign;
assign o_hint                   = buf_read[7:4];
assign o_taken                  = buf_read[3:0];
assign berr                     = br_brop && br_cancel;
assign buf_next          [3 :0] = tbl_cnt1_hi_rd_fw & pred_hit1_fw | tbl_cnt0_hi_rd_sel_o & ~pred_hit1_fw;
assign buf_next          [7 :4] = pred_hit1_fw;
assign buf_read                 = buf_data[ptr_r];
assign corr                     = br_brop && !br_cancel;
assign modify_cnt0_hi           = tbl_cnt0_lo_rd_sel;
assign modify_cnt0_lo           = br_mark && !modify || !tbl_cnt0_lo_rd_sel && modify || 1'h0;
assign modify_cnt1_hi           = tbl_cnt1_lo_rd_sel && modify_index || modify_mark && !modify_index;
assign modify_cnt1_lo           = br_mark && !modify || !tbl_cnt1_lo_rd_sel && modify && modify_index || !modify_mark && modify && !modify_index;
assign modify_hit1              = modify_cmp1 == read_cmp1;
assign pred_conf0               = {8{modify && modify_idx0 == read_idx0 && !modify_index}} & modify_offs_dec;
assign pred_conf1               = {4{modify && modify_idx1 == read_idx1}} & modify_dofs_dec;
assign pred_hit1         [   0] = tbl_tag1_rd[7 :0 ] == read_cmp1;
assign pred_hit1         [   1] = tbl_tag1_rd[15:8 ] == read_cmp1;
assign pred_hit1         [   2] = tbl_tag1_rd[23:16] == read_cmp1;
assign pred_hit1         [   3] = tbl_tag1_rd[31:24] == read_cmp1;
assign pred_hit1_fw             = {4{modify_hit1}} & pred_conf1 | pred_hit1 & ~pred_conf1;
assign req                      = state_w || pc_go && !modify && !pr_cancel && !buf_cancel;
assign req_h_cmp1               = {8{state_b}} & state_b_cmp1 | {8{state_m}} & modify_cmp1 | 8'h00;
assign req_h_idx0               = {6{state_b}} & state_b_idx0 | {6{state_m}} & modify_idx0 | {6{state_i}} & raminit_index[5:0];
assign req_h_idx1               = {8{state_b}} & state_b_idx1 | {8{state_m}} & modify_idx1 | {8{state_i}} & raminit_index;
assign req_h_offs               = {3{state_b}} & state_b_offs | {3{state_m}} & modify_offs | 3'h0;
assign req_t_cmp1               = {8{state_p}} & state_p_cmp1 | {8{state_w}} & state_w_cmp1 | {8{state_m}} & modify_cmp1 | 8'h00;
assign req_t_idx0               = {6{state_p}} & state_p_idx0 | {6{state_w}} & state_w_idx0 | {6{state_m}} & modify_idx0 | {6{state_i}} & raminit_index[5:0];
assign req_t_idx1               = {8{state_p}} & state_p_idx1 | {8{state_w}} & state_w_idx1 | {8{state_m}} & modify_idx1 | {8{state_i}} & raminit_index;
assign req_t_offs               = {3{state_p}} & state_p_offs | {3{state_w}} & state_w_offs | {3{state_m}} & modify_offs | 3'h0;
assign state_b                  = br_brop && !raminit_valid;
assign state_b_cmp1             = bhr_br_pred[7:0] ^ bhr_br_pred[15:8] ^ {bhr_br_pred[20:18],bhr_br_pred[20:16]};
assign state_b_dyna      [2 :0] = br_pc[4:2] + ~{1'h0,br_hint_dofs} + 3'h1;
assign state_b_dyna      [29:3] = br_pc[31:5];
assign state_b_idx0             = br_pc[10:5];
assign state_b_idx1             = state_b_dyna[7:0] ^ bhr_br_pred[7:0] ^ bhr_br_pred[13:6] ^ bhr_br_pred[20:13];
assign state_b_offs             = br_pc[4:2];
assign state_c                  = corr && !raminit_valid;
assign state_i                  = raminit_valid;
assign state_m                  = modify && !raminit_valid;
assign state_p                  = !berr && !modify && !raminit_valid;
assign state_p_cmp1             = bhr_bt[7:0] ^ bhr_bt[15:8] ^ {bhr_bt[20:18],bhr_bt[20:16]};
assign state_p_idx0             = bt_pc[10:5];
assign state_p_idx1             = bt_pc[9:2] ^ bhr_bt[7:0] ^ bhr_bt[13:6] ^ bhr_bt[20:13];
assign state_p_offs             = bt_pc[4:2];
assign state_w                  = berr && !raminit_valid;
assign state_w_cmp1             = bhr_br_next[7:0] ^ bhr_br_next[15:8] ^ {bhr_br_next[20:18],bhr_br_next[20:16]};
assign state_w_idx0             = br_target[10:5];
assign state_w_idx1             = br_target[9:2] ^ bhr_br_next[7:0] ^ bhr_br_next[13:6] ^ bhr_br_next[20:13];
assign state_w_offs             = br_target[4:2];
assign tbl_cnt0_hi_a            = req_t_idx0;
assign tbl_cnt0_hi_ce           = pc_go || raminit_valid || modify && !modify_index;
assign tbl_cnt0_hi_en           = pc_go || raminit_valid || modify && !modify_index;
assign tbl_cnt0_hi_rd_fw        = {8{modify_cnt0_hi}} & pred_conf0 | tbl_cnt0_hi_rd & ~pred_conf0;
assign tbl_cnt0_hi_wd           = {8{modify_cnt0_hi && !state_i}};
assign tbl_cnt0_hi_we           = {8{state_m}} & modify_offs_dec | {8{state_i}};
assign tbl_cnt0_lo_a            = req_h_idx0;
assign tbl_cnt0_lo_ce           = state_b && !br_hint_index || modify && !modify_index || state_i;
assign tbl_cnt0_lo_en           = state_b && !br_hint_index || modify && !modify_index || state_i;
assign tbl_cnt0_lo_rd_sel       = tbl_cnt0_lo_rd[modify_offs];
assign tbl_cnt0_lo_wd           = {8{modify_cnt0_lo && !state_i}};
assign tbl_cnt0_lo_we           = {8{state_c || state_m}} & req_h_offs_dec | {8{state_i}};
assign tbl_cnt1_hi_a            = req_t_idx1;
assign tbl_cnt1_hi_ce           = pc_go || raminit_valid || modify && modify_index;
assign tbl_cnt1_hi_en           = pc_go || raminit_valid || modify && modify_index;
assign tbl_cnt1_hi_rd_fw        = {4{modify_cnt1_hi}} & pred_conf1 | tbl_cnt1_hi_rd & ~pred_conf1;
assign tbl_cnt1_hi_wd           = {4{modify_cnt1_hi && !state_i}};
assign tbl_cnt1_hi_we           = {4{state_m}} & modify_dofs_dec | {4{state_i}};
assign tbl_cnt1_lo_a            = req_h_idx1;
assign tbl_cnt1_lo_ce           = state_b && br_hint_index || state_m && modify_index || state_i;
assign tbl_cnt1_lo_en           = state_b && br_hint_index || state_m && modify_index || state_i;
assign tbl_cnt1_lo_rd_sel       = tbl_cnt1_lo_rd[modify_dofs];
assign tbl_cnt1_lo_wd           = {4{modify_cnt1_lo && !state_i}};
assign tbl_cnt1_lo_we           = {4{state_c}} & br_hint_dofs_dec | {4{state_m}} & modify_dofs_dec | {4{state_i}};
assign tbl_tag1_a               = req_t_idx1;
assign tbl_tag1_ce              = pc_go || raminit_valid || modify && !modify_index;
assign tbl_tag1_en              = pc_go || raminit_valid || modify && !modify_index;
assign tbl_tag1_wd              = {4{{8{!state_i}} & modify_cmp1}};
assign tbl_tag1_we              = {{8{modify_dofs_dec[3] && modify}}
                                      ,{8{modify_dofs_dec[2] && modify}}
                                      ,{8{modify_dofs_dec[1] && modify}}
                                      ,{8{modify_dofs_dec[0] && modify}}}
                                | {32{state_i}};
assign bhr_br_next = bhr_br[20:0];
assign bhr_br_pred = bhr_br[24:1] >> br_hint_blck;
// Writing Registers
always@(posedge clock)
begin
    if(read)
    begin
        buf_data[ptr_w]<=buf_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        modify<=1'h0;
    end
    else
    if(berr)
    begin
        modify<=1'h1;
    end
    else
    begin
        modify<=1'h0;
    end
end
always@(posedge clock)
begin
    if(berr)
    begin
        modify_cmp1 <=state_b_cmp1 ;
        modify_dofs <=br_hint_dofs ;
        modify_idx0 <=state_b_idx0 ;
        modify_idx1 <=state_b_idx1 ;
        modify_index<=br_hint_index;
        modify_mark <=br_mark      ;
        modify_offs <=state_b_offs ;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        ptr_r<=1'h0;
    end
    else
    if(iq_go)
    begin
        ptr_r<=!ptr_r;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        ptr_w<=1'h0;
    end
    else
    if(buf_cancel)
    begin
        ptr_w<=ptr_r ^ iq_go;
    end
    else
    if(pr_cancel)
    begin
        ptr_w<=!ptr_r;
    end
    else
    if(read)
    begin
        ptr_w<=!ptr_w;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        read<=1'h0;
    end
    else
    if(req)
    begin
        read<=1'h1;
    end
    else
    if(read)
    begin
        read<=1'h0;
    end
end
always@(posedge clock)
begin
    if(req)
    begin
        read_cmp1<=req_t_cmp1;
        read_idx0<=req_t_idx0;
        read_idx1<=req_t_idx1;
        read_offs<=req_t_offs;
    end
end
// Instancing Sub-Modules
gs232c_decoder_n_m
#(
    .n(2)
)
br_hint_dofs_decoder
(
    .i(br_hint_dofs    ),// I, n     
    .o(br_hint_dofs_dec) // O, 1 << n
);
gs232c_decoder_n_m
#(
    .n(2)
)
modify_dofs_decoder
(
    .i(modify_dofs    ),// I, n     
    .o(modify_dofs_dec) // O, 1 << n
);
gs232c_decoder_n_m
#(
    .n(3)
)
modify_offs_decoder
(
    .i(modify_offs    ),// I, n     
    .o(modify_offs_dec) // O, 1 << n
);
gs232c_decoder_n_m
#(
    .n(3)
)
req_h_offs_decoder
(
    .i(req_h_offs    ),// I, n     
    .o(req_h_offs_dec) // O, 1 << n
);
gs232c_sel_k_words_n_m
#(
    .n       (3   ),
    .k       (4   ),
    .w       (1   ),
    .circular(1'b0) 
)
tbl_cnt0_hi_rd_sel
(
    .i(tbl_cnt0_hi_rd_fw   ),// I, w << n
    .s(read_offs           ),// I, n     
    .o(tbl_cnt0_hi_rd_sel_o) // O, w * k 
);
endmodule // gs232c_bht
