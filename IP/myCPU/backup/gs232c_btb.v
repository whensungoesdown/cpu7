module gs232c_btb(
    input  wire        clock        ,
    input  wire        reset        ,
    input  wire [7 :0] raminit_index,
    input  wire        raminit_valid,
    input  wire        iq_cancel    ,
    input  wire        iq_go        ,
    // group bt
    output wire        bt_brop      ,
    output wire [3 :0] bt_brops     ,
    output wire        bt_cancel    ,
    output wire [15:0] bt_hint      ,
    output wire        bt_jrop      ,
    input  wire [31:0] bt_pc        ,
    output wire [31:0] bt_target    ,
    // group pr
    input  wire [29:0] pr_base      ,
    input  wire        pr_brop      ,
    input  wire [3 :0] pr_brops     ,
    input  wire [3 :0] pr_brops_raw ,
    input  wire        pr_cancel    ,
    input  wire [1 :0] pr_dofs      ,
    input  wire [15:0] pr_hint      ,
    input  wire        pr_jrop      ,
    input  wire        pr_jrra      ,
    input  wire        pr_link      ,
    input  wire [29:0] pr_link_pc   ,
    input  wire [31:0] pr_pc        ,
    input  wire        pr_taken     ,
    input  wire [3 :0] pr_takens    ,
    input  wire [31:0] pr_target    ,
    input  wire        pr_valid     ,
    input  wire [29:0] ra            
);
// group pr
wire [3 :0] pr_brops_err      ;
wire        pr_hint_brop      ;
wire [3 :0] pr_hint_brops_raw ;
wire [1 :0] pr_hint_cnt       ;
wire [1 :0] pr_hint_cnt_next  ;
wire [1 :0] pr_hint_dofs      ;
wire [2 :0] pr_hint_index     ;
wire        pr_hint_jrop      ;
wire        pr_hint_jrra      ;
wire        pr_hint_link      ;
wire        pr_hint_valid     ;
// group tbl
wire [3 :0] tbl_brops         ;
wire [9 :0] tbl_brops_waddr   ;
wire [3 :0] tbl_brops_wdata   ;
wire [3 :0] tbl_brops_wmask   ;
reg  [2 :0] tbl_index         ;
wire [29:0] tbl_ra            ;
wire        tbl_read_brop     ;
wire [3 :0] tbl_read_brops_raw;
wire [7 :0] tbl_read_cmp      ;
wire        tbl_read_cmp_exist;
wire [2 :0] tbl_read_cmp_first;
wire [1 :0] tbl_read_cnt      ;
wire [1 :0] tbl_read_dofs     ;
wire [2 :0] tbl_read_index    ;
wire        tbl_read_jrop     ;
wire        tbl_read_jrra     ;
wire        tbl_read_link     ;
wire [35:0] tbl_read_res      ;
wire [29:0] tbl_read_target   ;
wire        tbl_read_valid    ;
wire [1 :0] tbl_write_cnt     ;
wire        tbl_write_cnt_we  ;
wire [2 :0] tbl_write_index   ;
wire [35:0] tbl_write_res     ;
wire        tbl_write_res_we  ;
wire [29:0] tbl_write_tag     ;
wire        tbl_write_tag_we  ;
// Declaring RAMs
reg  [1 :0] tbl_cnt[7:0];
reg  [35:0] tbl_res[7:0];
reg  [29:0] tbl_tag[7:0];
// group bt
assign bt_brop      = tbl_read_cnt[1] && tbl_read_brop;
assign bt_brops [0] = tbl_brops[0];
assign bt_brops [1] = tbl_brops[1] && ( |tbl_read_dofs || !bt_cancel);
assign bt_brops [2] = tbl_brops[2] && (tbl_read_dofs[1] || !bt_cancel);
assign bt_brops [3] = tbl_brops[3] && ( &tbl_read_dofs || !bt_cancel);
assign bt_cancel    = tbl_read_valid && (tbl_read_cnt[1] || !tbl_read_brop);
assign bt_hint      = {tbl_read_brop
                      ,tbl_read_jrop     
                      ,tbl_read_dofs     
                      ,tbl_read_link     
                      ,tbl_read_jrra     
                      ,tbl_read_brops_raw
                      ,tbl_read_index    
                      ,tbl_read_cnt      
                      ,tbl_read_valid};
assign bt_jrop               = tbl_read_jrop;
assign bt_target             = {tbl_read_jrra ? tbl_ra : tbl_read_target,2'b00};
// group pr
assign pr_brops_err          = {4{pr_valid}} & (pr_brops_raw ^ pr_hint_brops_raw);
assign pr_hint_brop          = pr_hint[15];
assign pr_hint_brops_raw     = pr_hint[9:6];
assign pr_hint_cnt           = pr_hint[2:1];
assign pr_hint_cnt_next      = {2{pr_hint_cnt[1] ^ pr_taken}} & {pr_hint_cnt[0],!pr_hint_cnt[0]} | {2{pr_taken && pr_hint_cnt[1]}};
assign pr_hint_dofs          = pr_hint[13:12];
assign pr_hint_index         = pr_hint[5 :3 ];
assign pr_hint_jrop          = pr_hint[14];
assign pr_hint_jrra          = pr_hint[10];
assign pr_hint_link          = pr_hint[11];
assign pr_hint_valid         = pr_hint[0 ];
// group tbl
assign tbl_brops_waddr       = raminit_valid ? {raminit_index,2'b00} : pr_pc[11:2];
assign tbl_brops_wdata       = {4{!raminit_valid}} & pr_brops_raw;
assign tbl_brops_wmask       = pr_brops_err | {4{raminit_valid}};
assign tbl_ra                = pr_link ? pr_link_pc : ra;
assign tbl_read_brop         = tbl_read_res[35];
assign tbl_read_brops_raw    = tbl_brops;
assign tbl_read_cmp      [0] = tbl_tag[0] == bt_pc[31:2];
assign tbl_read_cmp      [1] = tbl_tag[1] == bt_pc[31:2];
assign tbl_read_cmp      [2] = tbl_tag[2] == bt_pc[31:2];
assign tbl_read_cmp      [3] = tbl_tag[3] == bt_pc[31:2];
assign tbl_read_cmp      [4] = tbl_tag[4] == bt_pc[31:2];
assign tbl_read_cmp      [5] = tbl_tag[5] == bt_pc[31:2];
assign tbl_read_cmp      [6] = tbl_tag[6] == bt_pc[31:2];
assign tbl_read_cmp      [7] = tbl_tag[7] == bt_pc[31:2];
assign tbl_read_cmp_exist    =  |tbl_read_cmp;
assign tbl_read_cnt          = {2{tbl_read_cmp[0]}} & tbl_cnt[0]
                             | {2{tbl_read_cmp[1]}} & tbl_cnt[1]
                             | {2{tbl_read_cmp[2]}} & tbl_cnt[2]
                             | {2{tbl_read_cmp[3]}} & tbl_cnt[3]
                             | {2{tbl_read_cmp[4]}} & tbl_cnt[4]
                             | {2{tbl_read_cmp[5]}} & tbl_cnt[5]
                             | {2{tbl_read_cmp[6]}} & tbl_cnt[6]
                             | {2{tbl_read_cmp[7]}} & tbl_cnt[7];
assign tbl_read_dofs  = tbl_read_res[33:32];
assign tbl_read_index = tbl_read_cmp_first;
assign tbl_read_jrop  = tbl_read_res[34];
assign tbl_read_jrra  = tbl_read_res[30];
assign tbl_read_link  = tbl_read_res[31];
assign tbl_read_res   = {36{tbl_read_cmp[0]}} & tbl_res[0]
                      | {36{tbl_read_cmp[1]}} & tbl_res[1]
                      | {36{tbl_read_cmp[2]}} & tbl_res[2]
                      | {36{tbl_read_cmp[3]}} & tbl_res[3]
                      | {36{tbl_read_cmp[4]}} & tbl_res[4]
                      | {36{tbl_read_cmp[5]}} & tbl_res[5]
                      | {36{tbl_read_cmp[6]}} & tbl_res[6]
                      | {36{tbl_read_cmp[7]}} & tbl_res[7];
assign tbl_read_target  = tbl_read_res[29:0];
assign tbl_read_valid   = tbl_read_cmp_exist;
assign tbl_write_cnt    = {2{pr_hint_valid && !raminit_valid}} & pr_hint_cnt_next | {2{!pr_hint_valid && !raminit_valid}} & {pr_taken,!pr_brop};
assign tbl_write_cnt_we = raminit_valid || pr_valid && pr_hint_valid || pr_cancel;
assign tbl_write_index  = raminit_valid ? raminit_index[2:0] : 
                          pr_hint_valid ? pr_hint_index : tbl_index;
assign tbl_write_res    = {pr_brop,pr_jrop,pr_dofs,pr_link,pr_jrra,pr_target[31:2]};
assign tbl_write_res_we = raminit_valid || pr_cancel && pr_taken;
assign tbl_write_tag    = raminit_valid ? {raminit_index,22'h000000} : pr_pc[31:2];
assign tbl_write_tag_we = raminit_valid || pr_cancel && pr_taken && !pr_hint_valid;
always@(posedge clock)
begin
    if(tbl_write_cnt_we)
    begin
        tbl_cnt[tbl_write_index]<=tbl_write_cnt;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        tbl_index<=3'h0;
    end
    else
    if(tbl_write_tag_we)
    begin
        tbl_index<=tbl_index + 3'h1;
    end
end
always@(posedge clock)
begin
    if(tbl_write_res_we)
    begin
        tbl_res[tbl_write_index]<=tbl_write_res;
    end
end
always@(posedge clock)
begin
    if(tbl_write_tag_we)
    begin
        tbl_tag[tbl_write_index]<=tbl_write_tag;
    end
end
gs232c_btb_bitmap tbl_brops_bitmap
(
    .clock(clock          ),// I, 1 
    .reset(reset          ),// I, 1 
    .raddr(bt_pc[11:2]    ),// I, 10
    .rdata(tbl_brops      ),// O, 4 
    .waddr(tbl_brops_waddr),// I, 10
    .wmask(tbl_brops_wmask),// I, 4 
    .wdata(tbl_brops_wdata) // I, 4 
);
gs232c_enc_first_n_m
#(
    .n(3)
)
tbl_read_cmp_enc
(
    .i(tbl_read_cmp      ),// I, 1 << n
    .o(tbl_read_cmp_first) // O, n     
);
endmodule // gs232c_btb
