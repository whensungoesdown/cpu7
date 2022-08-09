module gs232c_inst_judge(
    input  wire         clock       ,
    input  wire         reset       ,
    // group i
    input  wire [1  :0] i_count     ,
    input  wire [15 :0] i_hint      ,
    input  wire [127:0] i_inst      ,
    input  wire         i_is_seq    ,
    input  wire [31 :0] i_pc        ,
    input  wire [29 :0] i_seq       ,
    input  wire [29 :0] i_target    ,
    input  wire         i_uncache   ,
    input  wire         i_valid     ,
    // group pr
    output wire [29 :0] pr_base     ,
    output wire         pr_brop     ,
    output wire [3  :0] pr_brops    ,
    output wire [3  :0] pr_brops_raw,
    output wire         pr_cancel   ,
    output wire [1  :0] pr_dofs     ,
    output wire [15 :0] pr_hint     ,
    output wire         pr_jrop     ,
    output wire         pr_jrra     ,
    output wire         pr_link     ,
    output wire [29 :0] pr_link_pc  ,
    output wire [31 :0] pr_pc       ,
    output wire         pr_taken    ,
    output wire [3  :0] pr_takens   ,
    output wire [31 :0] pr_target   ,
    output wire         pr_valid    ,
    input  wire [3  :0] bht_taken   ,
    output wire [3  :0] jtb_jrops   ,
    input  wire [29 :0] jtb_target  ,
    input  wire [29 :0] ra          ,
    output wire [1  :0] count        
);
localparam sel_n = 2;
// group i
wire        i_hint_brop             ;
wire [3 :0] i_hint_brops            ;
wire [3 :0] i_hint_brops_raw        ;
wire [1 :0] i_hint_cnt              ;
wire [1 :0] i_hint_dofs             ;
wire [2 :0] i_hint_index            ;
wire        i_hint_jrop             ;
wire        i_hint_jrra             ;
wire        i_hint_link             ;
wire        i_hint_valid            ;
wire [3 :0] i_pc_hi                 ;
wire [3 :0] i_pc_hi_borrow          ;
wire        i_pc_hi_borrow_same     ;
wire [3 :0] i_pc_hi_carry           ;
wire        i_pc_hi_carry_same      ;
wire        i_pc_hi_same            ;
wire [2 :0] i_pc_lo0                ;
wire [2 :0] i_pc_lo1                ;
wire [2 :0] i_pc_lo2                ;
wire [2 :0] i_pc_lo3                ;
wire [2 :0] i_pc_lo4                ;
wire        pr_cancel_hint          ;
wire        pr_cancel_path          ;
// group predec
wire [3 :0] predec_bl_b             ;
wire [3 :0] predec_brop             ;
wire [3 :0] predec_jrop             ;
wire [3 :0] predec_jrra             ;
wire [3 :0] predec_link             ;
wire [3 :0] predec_must             ;
wire [25:0] predec_offs0            ;
wire [25:0] predec_offs1            ;
wire [25:0] predec_offs2            ;
wire [25:0] predec_offs3            ;
wire [3 :0] predec_sign             ;
// group sel
wire [29:0] sel_base                ;
wire        sel_brop                ;
wire        sel_bxop                ;
wire        sel_bxop_b              ;
wire        sel_bxop_c              ;
wire [25:0] sel_bxop_offs           ;
wire        sel_bxop_same           ;
wire [29:0] sel_bxop_target         ;
wire        sel_endline             ;
wire        sel_endline_cached      ;
wire        sel_jrop                ;
wire        sel_jrop_same           ;
wire        sel_jrra                ;
wire        sel_jrra_same           ;
wire        sel_link                ;
wire [29:0] sel_link_pc             ;
wire [2 :0] sel_lnlo                ;
wire        sel_lnlo_carry          ;
wire [29:0] sel_seq                 ;
wire [3 :0] sel_taken               ;
wire [3 :0] sel_taken_brop          ;
wire [3 :0] sel_taken_bxop          ;
wire [1 :0] sel_taken_first         ;
wire        sel_taken_valid         ;
// group perf
reg  [31:0] perf_cancel_cnt_anyc    ;
reg  [31:0] perf_cancel_cnt_anyc_hit;
reg  [31:0] perf_cancel_cnt_anyc_mis;
reg  [31:0] perf_cancel_cnt_both    ;
reg  [31:0] perf_cancel_cnt_both_hit;
reg  [31:0] perf_cancel_cnt_both_mis;
reg  [31:0] perf_cancel_cnt_hint    ;
reg  [31:0] perf_cancel_cnt_hint_hit;
reg  [31:0] perf_cancel_cnt_hint_mis;
reg  [31:0] perf_cancel_cnt_path    ;
reg  [31:0] perf_cancel_cnt_path_hit;
reg  [31:0] perf_cancel_cnt_path_mis;
reg  [31:0] perf_valid_cnt          ;
// group i
assign i_hint_brop            = i_hint          [15];
assign i_hint_brops       [0] = i_hint_brops_raw[0 ];
assign i_hint_brops       [1] = i_hint_brops_raw[1] && ( |i_hint_dofs || !(i_hint_valid && i_hint_cnt[1]));
assign i_hint_brops       [2] = i_hint_brops_raw[2] && (i_hint_dofs[1] || !(i_hint_valid && i_hint_cnt[1]));
assign i_hint_brops       [3] = i_hint_brops_raw[3] && ( &i_hint_dofs || !(i_hint_valid && i_hint_cnt[1]));
assign i_hint_brops_raw       = i_hint[9 :6 ];
assign i_hint_cnt             = i_hint[2 :1 ];
assign i_hint_dofs            = i_hint[13:12];
assign i_hint_index           = i_hint[5 :3 ];
assign i_hint_jrop            = i_hint[14];
assign i_hint_jrra            = i_hint[10];
assign i_hint_link            = i_hint[11];
assign i_hint_valid           = i_hint[0 ];
assign i_pc_hi                = i_pc[31:28];
assign i_pc_hi_borrow         = i_pc_hi + 4'hf;
assign i_pc_hi_borrow_same    = i_pc_hi_borrow == i_target[29:26];
assign i_pc_hi_carry          = i_pc_hi + 4'h1;
assign i_pc_hi_carry_same     = i_pc_hi_carry == i_target[29:26];
assign i_pc_hi_same           = i_pc_hi       == i_target[29:26];
assign i_pc_lo0               = i_pc[4:2];
assign i_pc_lo1               = i_pc[4:2] + 3'h1;
assign i_pc_lo2               = i_pc[4:2] + 3'h2;
assign i_pc_lo3               = i_pc[4:2] + 3'h3;
assign i_pc_lo4               = i_pc[4:2] + 3'h4;
// group pr
assign pr_base                = sel_base;
assign pr_brop                = i_valid && sel_brop;
assign pr_brops_raw           = predec_brop;
assign pr_cancel              = pr_cancel_path || pr_cancel_hint;
assign pr_cancel_hint         = i_valid && (i_hint_jrop ^ pr_jrop || i_hint_brop ^ pr_brop || i_hint_brops != pr_brops);
assign pr_cancel_path         = i_valid &&  sel_bxop        && !sel_bxop_same
                             || i_valid &&  sel_jrop        && !sel_jrop_same
                             || i_valid &&  sel_jrra        && !sel_jrra_same
                             || i_valid && !sel_taken_valid && !i_is_seq     
                             || i_valid && i_uncache;
assign pr_dofs    = sel_taken_first;
assign pr_hint    = i_hint         ;
assign pr_jrop    = i_valid && sel_jrop;
assign pr_jrra    = i_valid && sel_jrra;
assign pr_link    = i_valid && sel_link;
assign pr_link_pc = sel_link_pc    ;
assign pr_pc      = i_pc           ;
assign pr_taken   = sel_taken_valid;
assign pr_takens  = sel_taken      ;
assign pr_target  = {{30{sel_jrop}} & jtb_target | {30{sel_bxop}} & sel_bxop_target | {30{sel_jrra}} & ra | {30{!sel_taken_valid}} & sel_seq
                    ,2'b00};
assign pr_valid               = i_valid    ;
assign jtb_jrops              = predec_jrop;
assign count                  = sel_taken_valid ? sel_taken_first : i_count;
// group sel
assign sel_base       [29:3 ] = i_pc[31:5];
assign sel_bxop_target[29:26] = {4{sel_bxop_b && !sel_bxop_c}} & i_pc_hi_borrow
                              | {4{sel_bxop_c && !sel_bxop_b}} & i_pc_hi_carry 
                              | {4{!(sel_bxop_b ^ sel_bxop_c)}} & i_pc_hi;
assign sel_endline              = sel_endline_cached && (i_pc[4:2] == 3'h7 || !i_uncache);
assign sel_endline_cached       = i_pc[4:2] >= 3'h4;
assign sel_jrop_same            = i_target == jtb_target;
assign sel_jrra_same            = i_target == ra        ;
assign sel_link_pc              = {sel_lnlo_carry ? i_seq[29:3] : i_pc[31:5],sel_lnlo};
assign sel_lnlo_carry           = sel_lnlo == 3'h0;
assign sel_seq           [2 :0] = i_uncache ? i_pc_lo1 : i_seq[2:0];
assign sel_seq           [29:3] = sel_endline ? i_seq[29:3] : i_pc[31:5];
assign sel_taken                = sel_taken_brop | predec_must;
assign sel_taken_brop           = (bht_taken ^ predec_sign) & predec_brop;
assign sel_taken_bxop           = predec_bl_b | sel_taken_brop;
assign sel_taken_valid          =  |sel_taken;
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_anyc<=32'h00000000;
    end
    else
    if(pr_cancel_hint || pr_cancel_path)
    begin
        perf_cancel_cnt_anyc<=perf_cancel_cnt_anyc + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_anyc_hit<=32'h00000000;
    end
    else
    if((pr_cancel_hint || pr_cancel_path) && pr_hint[0])
    begin
        perf_cancel_cnt_anyc_hit<=perf_cancel_cnt_anyc_hit + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_anyc_mis<=32'h00000000;
    end
    else
    if((pr_cancel_hint || pr_cancel_path) && !pr_hint[0])
    begin
        perf_cancel_cnt_anyc_mis<=perf_cancel_cnt_anyc_mis + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_both<=32'h00000000;
    end
    else
    if(pr_cancel_hint && pr_cancel_path)
    begin
        perf_cancel_cnt_both<=perf_cancel_cnt_both + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_both_hit<=32'h00000000;
    end
    else
    if(pr_cancel_hint && pr_cancel_path && pr_hint[0])
    begin
        perf_cancel_cnt_both_hit<=perf_cancel_cnt_both_hit + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_both_mis<=32'h00000000;
    end
    else
    if(pr_cancel_hint && pr_cancel_path && !pr_hint[0])
    begin
        perf_cancel_cnt_both_mis<=perf_cancel_cnt_both_mis + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_hint<=32'h00000000;
    end
    else
    if(pr_cancel_hint && !pr_cancel_path)
    begin
        perf_cancel_cnt_hint<=perf_cancel_cnt_hint + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_hint_hit<=32'h00000000;
    end
    else
    if(pr_cancel_hint && !pr_cancel_path && pr_hint[0])
    begin
        perf_cancel_cnt_hint_hit<=perf_cancel_cnt_hint_hit + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_hint_mis<=32'h00000000;
    end
    else
    if(pr_cancel_hint && !pr_cancel_path && !pr_hint[0])
    begin
        perf_cancel_cnt_hint_mis<=perf_cancel_cnt_hint_mis + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_path<=32'h00000000;
    end
    else
    if(pr_cancel_path && !pr_cancel_hint)
    begin
        perf_cancel_cnt_path<=perf_cancel_cnt_path + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_path_hit<=32'h00000000;
    end
    else
    if(pr_cancel_path && !pr_cancel_hint && pr_hint[0])
    begin
        perf_cancel_cnt_path_hit<=perf_cancel_cnt_path_hit + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_cancel_cnt_path_mis<=32'h00000000;
    end
    else
    if(pr_cancel_path && !pr_cancel_hint && !pr_hint[0])
    begin
        perf_cancel_cnt_path_mis<=perf_cancel_cnt_path_mis + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_valid_cnt<=32'h00000000;
    end
    else
    if(pr_valid)
    begin
        perf_valid_cnt<=perf_valid_cnt + 32'h00000001;
    end
end
// Instancing Sub-Modules
gs232c_mask_bits_gt
#(
    .n(1 << sel_n)
)
pr_brops_mask
(
    .i(predec_brop),// I, n
    .s(sel_taken  ),// I, n
    .o(pr_brops   ) // O, n
);
gs232c_predecoder predecoder0
(
    .inst       (i_inst[31:0]  ),// I, 32
    .predec_bl_b(predec_bl_b[0]),// O, 1 
    .predec_must(predec_must[0]),// O, 1 
    .predec_brop(predec_brop[0]),// O, 1 
    .predec_jrop(predec_jrop[0]),// O, 1 
    .predec_jrra(predec_jrra[0]),// O, 1 
    .predec_link(predec_link[0]),// O, 1 
    .predec_sign(predec_sign[0]),// O, 1 
    .predec_offs(predec_offs0  ) // O, 26
);
gs232c_predecoder predecoder1
(
    .inst       (i_inst[63:32] ),// I, 32
    .predec_bl_b(predec_bl_b[1]),// O, 1 
    .predec_must(predec_must[1]),// O, 1 
    .predec_brop(predec_brop[1]),// O, 1 
    .predec_jrop(predec_jrop[1]),// O, 1 
    .predec_jrra(predec_jrra[1]),// O, 1 
    .predec_link(predec_link[1]),// O, 1 
    .predec_sign(predec_sign[1]),// O, 1 
    .predec_offs(predec_offs1  ) // O, 26
);
gs232c_predecoder predecoder2
(
    .inst       (i_inst[95:64] ),// I, 32
    .predec_bl_b(predec_bl_b[2]),// O, 1 
    .predec_must(predec_must[2]),// O, 1 
    .predec_brop(predec_brop[2]),// O, 1 
    .predec_jrop(predec_jrop[2]),// O, 1 
    .predec_jrra(predec_jrra[2]),// O, 1 
    .predec_link(predec_link[2]),// O, 1 
    .predec_sign(predec_sign[2]),// O, 1 
    .predec_offs(predec_offs2  ) // O, 26
);
gs232c_predecoder predecoder3
(
    .inst       (i_inst[127:96]),// I, 32
    .predec_bl_b(predec_bl_b[3]),// O, 1 
    .predec_must(predec_must[3]),// O, 1 
    .predec_brop(predec_brop[3]),// O, 1 
    .predec_jrop(predec_jrop[3]),// O, 1 
    .predec_jrra(predec_jrra[3]),// O, 1 
    .predec_link(predec_link[3]),// O, 1 
    .predec_sign(predec_sign[3]),// O, 1 
    .predec_offs(predec_offs3  ) // O, 26
);
gs232c_sel_first_field
#(
    .n(sel_n),
    .w(3    ) 
)
sel_base_sel
(
    .i({i_pc_lo3,i_pc_lo2,i_pc_lo1,i_pc_lo0}),// I, w << n
    .s(sel_taken                            ),// I, 1 << n
    .o(sel_base[2:0]                        ) // O, w     
);
gs232c_selbit_first_masked_included
#(
    .n(sel_n)
)
sel_brop_sel
(
    .i(sel_taken_brop),// I, 1 << n
    .s(sel_taken     ),// I, 1 << n
    .o(sel_brop      ) // O, 1     
);
gs232c_sel_first_field
#(
    .n(sel_n),
    .w(1    ) 
)
sel_bxop_b_sel
(
    .i(predec_sign),// I, w << n
    .s(sel_taken  ),// I, 1 << n
    .o(sel_bxop_b ) // O, w     
);
gs232c_check_pc sel_bxop_check
(
    .same  (sel_bxop_same        ),// O, 1 
    .same_h(i_pc_hi_same         ),// I, 1 
    .same_c(i_pc_hi_carry_same   ),// I, 1 
    .same_b(i_pc_hi_borrow_same  ),// I, 1 
    .next  (i_target[25:0]       ),// I, 26
    .base  (sel_base[25:0]       ),// I, 26
    .offs  (sel_bxop_offs        ),// I, 26
    .carry (sel_bxop_c           ),// O, 1 
    .target(sel_bxop_target[25:0]) // O, 26
);
gs232c_sel_first_field
#(
    .n(sel_n),
    .w(26   ) 
)
sel_bxop_offs_sel
(
    .i({predec_offs3,predec_offs2,predec_offs1,predec_offs0}),// I, w << n
    .s(sel_taken                                            ),// I, 1 << n
    .o(sel_bxop_offs                                        ) // O, w     
);
gs232c_selbit_first_masked_included
#(
    .n(sel_n)
)
sel_bxop_sel
(
    .i(sel_taken_bxop),// I, 1 << n
    .s(sel_taken     ),// I, 1 << n
    .o(sel_bxop      ) // O, 1     
);
gs232c_selbit_first_masked_included
#(
    .n(sel_n)
)
sel_jrop_sel
(
    .i(predec_jrop),// I, 1 << n
    .s(sel_taken  ),// I, 1 << n
    .o(sel_jrop   ) // O, 1     
);
gs232c_selbit_first_masked_included
#(
    .n(sel_n)
)
sel_jrra_sel
(
    .i(predec_jrra),// I, 1 << n
    .s(sel_taken  ),// I, 1 << n
    .o(sel_jrra   ) // O, 1     
);
gs232c_selbit_first_masked_included
#(
    .n(sel_n)
)
sel_link_sel
(
    .i(predec_link),// I, 1 << n
    .s(sel_taken  ),// I, 1 << n
    .o(sel_link   ) // O, 1     
);
gs232c_sel_first_field
#(
    .n(sel_n),
    .w(3    ) 
)
sel_lnlo_sel
(
    .i({i_pc_lo4,i_pc_lo3,i_pc_lo2,i_pc_lo1}),// I, w << n
    .s(predec_link                          ),// I, 1 << n
    .o(sel_lnlo                             ) // O, w     
);
gs232c_enc_first_n_m
#(
    .n(sel_n)
)
sel_taken_enc
(
    .i(sel_taken      ),// I, 1 << n
    .o(sel_taken_first) // O, n     
);
endmodule // gs232c_inst_judge
