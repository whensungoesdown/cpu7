module gs232c_inst_queue(
    input  wire         clock          ,
    //synopsys sync_set_reset "reset"
    input  wire         reset          ,
    output wire         pc_go          ,
    input  wire         raminit_valid  ,
    // group fe
    input  wire [31 :0] fe_cur         ,
    output wire         fe_go          ,
    input  wire [15 :0] fe_hint        ,
    input  wire         fe_is_seq      ,
    input  wire [29 :0] fe_seq         ,
    input  wire [29 :0] fe_target      ,
    input  wire         fe_valid       ,
    output wire         iq_cancel      ,
    output wire         iq_go          ,
    // group inst
    input  wire         inst_addr_ok   ,
    output wire         inst_cancel    ,
    input  wire [1  :0] inst_count     ,
    input  wire         inst_ex        ,
    input  wire [5  :0] inst_exccode   ,
    input  wire [127:0] inst_rdata     ,
    output wire         inst_req       ,
    input  wire         inst_uncache   ,
    input  wire         inst_valid     ,
    // group o
    input  wire [2  :0] o_allow        ,
    output wire         o_port0_ex     ,
    output wire [5  :0] o_port0_exccode,
    output wire [4  :0] o_port0_hint   ,
    output wire [31 :0] o_port0_inst   ,
    output wire [31 :0] o_port0_pc     ,
    output wire         o_port0_taken  ,
    output wire [29 :0] o_port0_target ,
    output wire         o_port1_ex     ,
    output wire [5  :0] o_port1_exccode,
    output wire [4  :0] o_port1_hint   ,
    output wire [31 :0] o_port1_inst   ,
    output wire [31 :0] o_port1_pc     ,
    output wire         o_port1_taken  ,
    output wire [29 :0] o_port1_target ,
    output wire         o_port2_ex     ,
    output wire [5  :0] o_port2_exccode,
    output wire [4  :0] o_port2_hint   ,
    output wire [31 :0] o_port2_inst   ,
    output wire [31 :0] o_port2_pc     ,
    output wire         o_port2_taken  ,
    output wire [29 :0] o_port2_target ,
    output wire [2  :0] o_valid        ,
    // group pr
    output wire [29 :0] pr_base        ,
    output wire         pr_brop        ,
    output wire [3  :0] pr_brops       ,
    output wire [3  :0] pr_brops_raw   ,
    output wire         pr_cancel      ,
    output wire [1  :0] pr_dofs        ,
    output wire [15 :0] pr_hint        ,
    output wire         pr_jrop        ,
    output wire         pr_jrra        ,
    output wire         pr_link        ,
    output wire [29 :0] pr_link_pc     ,
    output wire [31 :0] pr_pc          ,
    output wire         pr_taken       ,
    output wire [3  :0] pr_takens      ,
    output wire [31 :0] pr_target      ,
    output wire         pr_valid       ,
    input  wire         br_cancel      ,
    input  wire         wb_cancel      ,
    input  wire [29 :0] ra             ,
    input  wire [3  :0] bht_hint       ,
    input  wire [3  :0] bht_taken      ,
    output wire [3  :0] jtb_jrops      ,
    input  wire [29 :0] jtb_target     ,
    output wire         buf_cancel      
);
// group judge
reg  [1  :0] judge_count               ;
reg          judge_ex                  ;
reg  [15 :0] judge_hint                ;
reg  [127:0] judge_inst                ;
reg          judge_is_seq              ;
reg  [31 :0] judge_pc                  ;
wire [31 :0] judge_pc_a1               ;
wire [31 :0] judge_pc_a2               ;
reg  [29 :0] judge_seq                 ;
wire [29 :0] judge_target              ;
reg          judge_uncache             ;
reg          judge_valid               ;
// group o
wire [2  :0] o_go                      ;
wire [29 :0] o_port0_target_q          ;
wire [29 :0] o_port1_target_q          ;
wire [29 :0] o_port2_target_q          ;
wire [29 :0] o_q_target                ;
wire [1  :0] count                     ;
reg  [5  :0] ex_code                   ;
reg          ex_ever                   ;
// group buf
wire [116:0] buf_data                  ;
wire [1  :0] buf_full                  ;
wire         buf_p_empty               ;
wire [1  :0] buf_p_full                ;
reg  [4  :0] buf_p_head                ;
wire [4  :0] buf_p_head_add1           ;
wire [4  :0] buf_p_head_add2           ;
wire [4  :0] buf_p_head_add3           ;
wire [4  :0] buf_p_head_next           ;
wire [3  :0] buf_p_i_valid             ;
wire         buf_p_push                ;
wire [116:0] buf_p_read                ;
wire [4  :0] buf_p_tail                ;
wire [2  :0] buf_p_valid               ;
wire [29 :0] buf_pc_consumed           ;
wire [29 :0] buf_pc_consumed_next      ;
wire [2  :0] buf_pc_consumed_next_lo   ;
reg  [29 :0] buf_pc_consumed_saved     ;
reg  [2  :0] buf_pc_consumed_valid     ;
wire [2  :0] buf_pc_consumed_valid_next;
wire         buf_pc_dual               ;
wire         buf_pc_empty              ;
wire         buf_pc_filled             ;
wire [1  :0] buf_pc_full               ;
reg  [2  :0] buf_pc_head               ;
wire [2  :0] buf_pc_head_inc1          ;
wire [2  :0] buf_pc_head_inc2          ;
wire [2  :0] buf_pc_head_next          ;
wire [2  :0] buf_pc_head_o1            ;
wire [2  :0] buf_pc_head_o2            ;
wire [2  :0] buf_pc_head_o3            ;
reg          buf_pc_jumped             ;
wire         buf_pc_more               ;
wire [95 :0] buf_pc_read               ;
wire [31 :0] buf_pc_sel0               ;
wire [31 :0] buf_pc_sel0_a0            ;
wire [31 :0] buf_pc_sel0_a1            ;
wire [31 :0] buf_pc_sel0_a2            ;
wire [31 :0] buf_pc_sel1               ;
wire [31 :0] buf_pc_sel1_a1            ;
wire         buf_pc_single             ;
reg  [2  :0] buf_pc_tail               ;
wire         buf_pc_tail_inc           ;
wire [2  :0] buf_pc_tail_inc1          ;
wire [155:0] buf_w_data                ;
wire         buf_w_go                  ;
wire [29 :0] buf_w_target              ;
reg          buf_w_valid               ;
wire [19 :0] hint                      ;
wire [1  :0] hint_blck0                ;
wire [1  :0] hint_blck1                ;
wire [1  :0] hint_blck2                ;
wire [1  :0] hint_blck3                ;
// Declaring RAM
reg  [31:0] buf_pc[3:0];
assign pc_go            = inst_req && inst_addr_ok;
assign fe_go            = inst_valid;
assign iq_cancel        = pr_cancel || br_cancel || wb_cancel;
assign iq_go            = buf_w_valid && !buf_full[0];
assign inst_cancel      = reset || pr_cancel || br_cancel || wb_cancel;
assign inst_req         = (!buf_full[1] || !fe_valid) && !buf_full[0] && !(buf_w_valid && judge_uncache) && !raminit_valid && !ex_ever;
assign judge_pc_a1      = {judge_pc[31:5],judge_pc[4:2] + 3'h1,judge_pc[1:0]};
assign judge_pc_a2      = {judge_pc[31:5],judge_pc[4:3] + 2'h1,judge_pc[2:0]};
assign judge_target     = fe_target;
// group o
assign o_go             = o_valid & o_allow;
assign o_port0_ex       = buf_data[1];
assign o_port0_exccode  = ex_code;
assign o_port0_hint     = buf_data[38:34];
assign o_port0_inst     = buf_data[33:2 ];
assign o_port0_pc       = buf_p_empty ? judge_pc : buf_pc_sel0_a0;
assign o_port0_taken    = buf_data[0];
assign o_port0_target   = buf_p_empty ? buf_w_target : o_port0_target_q;
assign o_port0_target_q = buf_pc_single ? o_q_target : buf_pc_read[63:34];
assign o_port1_ex       = buf_data[40];
assign o_port1_exccode  = ex_code;
assign o_port1_hint     = buf_data[77:73];
assign o_port1_inst     = buf_data[72:41];
assign o_port1_pc       = {32{buf_p_empty}} & judge_pc_a1
                        | {32{!buf_p_empty &&  buf_p_read[0]}} & buf_pc_sel1   
                        | {32{!buf_p_empty && !buf_p_read[0]}} & buf_pc_sel0_a1;
assign o_port1_taken    = buf_data[39];
assign o_port1_target   = buf_p_empty ? buf_w_target : o_port1_target_q;
assign o_port1_target_q = {30{buf_p_read[0] && !buf_pc_more || !buf_p_read[0] && !buf_pc_filled}} & o_q_target
                        | {30{ buf_p_read[0] && buf_pc_more  }} & buf_pc_read[95:66]
                        | {30{!buf_p_read[0] && buf_pc_filled}} & buf_pc_read[63:34];
assign o_port2_ex      = buf_data[79];
assign o_port2_exccode = ex_code;
assign o_port2_hint    = buf_data[116:112];
assign o_port2_inst    = buf_data[111:80 ];
assign o_port2_pc      = {32{buf_p_empty}} & judge_pc_a2
                       | {32{!buf_p_empty && !buf_p_read[0] && !buf_p_read[39]}} & buf_pc_sel0_a2
                       | {32{!buf_p_empty &&  buf_p_read[0] && !buf_p_read[39]}} & buf_pc_sel1_a1
                       | {32{!buf_p_empty && !buf_p_read[0] &&  buf_p_read[39]}} & buf_pc_sel1   ;
assign o_port2_taken    = buf_data[78];
assign o_port2_target   = buf_p_empty ? buf_w_target : o_port2_target_q;
assign o_port2_target_q = {30{(buf_p_read[0] || buf_p_read[39]) && !buf_pc_more || !(buf_p_read[0] || buf_p_read[39]) && !buf_pc_filled}}
                              & o_q_target
                        | {30{ (buf_p_read[0] || buf_p_read[39]) && buf_pc_more  }} & buf_pc_read[95:66]
                        | {30{!(buf_p_read[0] || buf_p_read[39]) && buf_pc_filled}} & buf_pc_read[63:34];
assign o_q_target      = buf_w_valid ? judge_pc     [31:2] : fe_target  ;
assign o_valid         = buf_p_empty ? buf_p_i_valid[2 :0] : buf_p_valid;
// group buf
assign buf_cancel      = br_cancel || wb_cancel;
assign buf_data        = buf_p_empty ? buf_w_data[116:0] : buf_p_read;
assign buf_full        = buf_p_full | buf_pc_full;
assign buf_p_empty     = buf_p_head == buf_p_tail;
assign buf_p_head_add1 = buf_p_head + 5'h01;
assign buf_p_head_add2 = buf_p_head + 5'h02;
assign buf_p_head_add3 = buf_p_head + 5'h03;
assign buf_p_head_next = {5{buf_cancel && !reset}} & buf_p_head
                       | {5{!o_go[1] && !buf_cancel && !reset}} & buf_p_head_add1
                       | {5{o_go[1] && !o_go[2] && !buf_cancel && !reset}} & buf_p_head_add2
                       | {5{o_go[2] && !buf_cancel && !reset}} & buf_p_head_add3;
assign buf_p_i_valid        = {{3{buf_p_push}} & { &count,count[1], |count},buf_p_push};
assign buf_p_push           = buf_w_valid && !buf_full[0];
assign buf_p_valid    [  0] = buf_p_head != buf_p_tail;
assign buf_p_valid    [  1] = buf_p_head != buf_p_tail && buf_p_head_add1 != buf_p_tail;
assign buf_p_valid    [  2] = buf_p_head != buf_p_tail && buf_p_head_add1 != buf_p_tail && buf_p_head_add2 != buf_p_tail && !(buf_p_read[0] && buf_p_read[39]);
assign buf_pc_consumed[1:0] = {2{buf_pc_consumed_valid[0] && !buf_pc_empty}} & buf_pc_consumed_saved[1:0]
                            | {2{!buf_pc_empty}} & buf_pc_consumed_valid[2:1];
assign buf_pc_consumed        [29:2] = {28{buf_pc_consumed_valid[0] && !buf_pc_empty}} & buf_pc_consumed_saved[29:2];
assign buf_pc_consumed_next   [1 :0] = buf_pc_consumed_next_lo[1:0];
assign buf_pc_consumed_next   [29:2] = buf_pc_consumed_next_lo[2] ? buf_pc_consumed[29:2] + 28'h0000001 : buf_pc_consumed[29:2];
assign buf_pc_consumed_next_lo       = {3{!o_go[1]}} & {1'b0,buf_pc_consumed[1:0]} + 3'h1
                                     | {3{o_go[1] && !o_go[2]}} & {1'b0,buf_pc_consumed[1:0]} + 3'h2
                                     | {3{o_go[2]}} & {1'b0,buf_pc_consumed[1:0]} + 3'h3;
assign buf_pc_consumed_valid_next[0] = !(o_port0_taken || o_port1_taken && o_go[1] || o_port2_taken && o_go[2] || reset || buf_cancel);
assign buf_pc_consumed_valid_next[1] = o_go[2] && o_port1_taken && !o_port2_taken && !reset && !buf_cancel
                                    || o_go[1] && o_port0_taken && !o_port1_taken && !reset && !buf_cancel && !o_go[2];
assign buf_pc_consumed_valid_next[2] = o_go[2] && o_port0_taken && !o_port1_taken && !reset && !buf_cancel && !o_port2_taken;
assign buf_pc_dual                   = buf_pc_head_inc2 == buf_pc_tail;
assign buf_pc_empty                  = buf_pc_head      == buf_pc_tail;
assign buf_pc_filled                 = buf_pc_full[0] || buf_pc_full[1] || buf_pc_dual;
assign buf_pc_full               [0] = buf_pc_head[2] ^ buf_pc_tail     [2] && buf_pc_head[1:0] == buf_pc_tail     [1:0];
assign buf_pc_full               [1] = buf_pc_head[2] ^ buf_pc_tail_inc1[2] && buf_pc_head[1:0] == buf_pc_tail_inc1[1:0];
assign buf_pc_head_inc1              = buf_pc_head + 3'h1;
assign buf_pc_head_inc2              = buf_pc_head + 3'h2;
assign buf_pc_head_next              = {3{buf_cancel && !reset}} & buf_pc_head
                                     | {3{!o_go[1] && !buf_cancel && !reset}} & buf_pc_head_o1
                                     | {3{o_go[1] && !o_go[2] && !buf_cancel && !reset}} & buf_pc_head_o2
                                     | {3{o_go[2] && !buf_cancel && !reset}} & buf_pc_head_o3;
assign buf_pc_head_o1 = buf_pc_head + {2'b00,o_port0_taken};
assign buf_pc_head_o2 = buf_pc_head + {1'b0,o_port0_taken && o_port1_taken,o_port0_taken ^ o_port1_taken};
assign buf_pc_head_o3 = buf_pc_head
                      + {1'b0
                            ,o_port0_taken && o_port1_taken || o_port1_taken && o_port2_taken || o_port2_taken && o_port0_taken
                            ,o_port0_taken ^ o_port1_taken ^ o_port2_taken};
assign buf_pc_more      = buf_pc_full[0] || buf_pc_full[1];
assign buf_pc_sel0      = buf_pc_read[31:0];
assign buf_pc_sel0_a0   = buf_pc_sel0 + {buf_pc_consumed,2'b00};
assign buf_pc_sel0_a1   = buf_pc_sel0 + {buf_pc_consumed,2'b00} + 32'h00000004;
assign buf_pc_sel0_a2   = buf_pc_sel0 + {buf_pc_consumed,2'b00} + 32'h00000008;
assign buf_pc_sel1      = buf_pc_read[63:32];
assign buf_pc_sel1_a1   = buf_pc_read[63:32] + 32'h00000004;
assign buf_pc_single    = buf_pc_head_inc1 == buf_pc_tail;
assign buf_pc_tail_inc  = buf_pc_jumped && buf_w_go;
assign buf_pc_tail_inc1 = buf_pc_tail + 3'h1;
assign buf_w_data       = {hint[19:15]
                          ,judge_inst[127:96]
                          ,judge_ex
                          ,pr_takens[3]
                          ,hint      [14:10]
                          ,judge_inst[95:64]
                          ,judge_ex
                          ,pr_takens[2]
                          ,hint      [9 :5 ]
                          ,judge_inst[63:32]
                          ,judge_ex
                          ,pr_takens[1]
                          ,hint      [4 :0]
                          ,judge_inst[31:0]
                          ,judge_ex
                          ,pr_takens[0]};
assign buf_w_go            = buf_w_valid && !buf_full[0];
assign buf_w_target        = pr_cancel ? pr_target[31:2] : fe_target;
assign hint        [1 :0 ] = 2'b00;
assign hint        [3 :2 ] = hint_blck0;
assign hint        [6 :5 ] = 2'b01;
assign hint        [8 :7 ] = hint_blck1;
assign hint        [11:10] = 2'b10;
assign hint        [13:12] = hint_blck2;
assign hint        [16:15] = 2'b11;
assign hint        [18:17] = hint_blck3;
assign hint        [   4 ] = bht_hint[0];
assign hint        [   9 ] = bht_hint[1];
assign hint        [   14] = bht_hint[2];
assign hint        [   19] = bht_hint[3];
assign hint_blck0          = 2'h0;
assign hint_blck1          = {1'h0,pr_brops_raw[0]};
assign hint_blck2          = {pr_brops_raw[0] && pr_brops_raw[1], ^pr_brops_raw[1:0]};
assign hint_blck3          = { &pr_brops_raw[1:0] || pr_brops_raw[2] &&  |pr_brops_raw[1:0], ^pr_brops_raw[2:0]};
// Writing Registers
always@(posedge clock)
begin
    if(inst_valid)
    begin
        judge_count  <=inst_count  ;
        judge_ex     <=inst_ex     ;
        judge_hint   <=fe_hint     ;
        judge_inst   <=inst_rdata  ;
        judge_is_seq <=fe_is_seq   ;
        judge_pc     <=fe_cur      ;
        judge_seq    <=fe_seq      ;
        judge_uncache<=inst_uncache;
    end
end
always@(posedge clock)
begin
    if(reset || buf_cancel)
    begin
        judge_valid<=1'h0;
    end
    else
    if(inst_valid)
    begin
        judge_valid<=!pr_cancel;
    end
    else
    if(judge_valid)
    begin
        judge_valid<=1'h0;
    end
end
always@(posedge clock)
begin
    if(inst_ex && !ex_ever)
    begin
        ex_code<=inst_exccode;
    end
end
always@(posedge clock)
begin
    if(reset || buf_cancel)
    begin
        ex_ever<=1'h0;
    end
    else
    if(inst_ex && inst_valid && !iq_cancel)
    begin
        ex_ever<=1'h1;
    end
end
always@(posedge clock)
begin
    if(o_go[0] || reset)
    begin
        buf_p_head<=buf_p_head_next;
    end
end
always@(posedge clock)
begin
    if(buf_pc_tail_inc)
    begin
        buf_pc[buf_pc_tail[1:0]]<=judge_pc;
    end
end
always@(posedge clock)
begin
    if(o_go[0])
    begin
        buf_pc_consumed_saved<=buf_pc_consumed_next;
    end
end
always@(posedge clock)
begin
    if(o_go[0] || reset || buf_cancel)
    begin
        buf_pc_consumed_valid<=buf_pc_consumed_valid_next;
    end
end
always@(posedge clock)
begin
    if(o_go[0] || reset)
    begin
        buf_pc_head<=buf_pc_head_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        buf_pc_jumped<=1'h1;
    end
    else
    if(buf_cancel)
    begin
        buf_pc_jumped<=1'h1;
    end
    else
    if(buf_w_go)
    begin
        buf_pc_jumped<=pr_taken;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        buf_pc_tail<=3'h0;
    end
    else
    if(buf_cancel)
    begin
        buf_pc_tail<=buf_pc_head;
    end
    else
    if(buf_pc_tail_inc)
    begin
        buf_pc_tail<=buf_pc_tail_inc1;
    end
end
always@(posedge clock)
begin
    if(reset || buf_cancel)
    begin
        buf_w_valid<=1'h0;
    end
    else
    if(inst_valid)
    begin
        buf_w_valid<=!pr_cancel;
    end
    else
    if(!buf_full[0])
    begin
        buf_w_valid<=1'h0;
    end
end
// Instancing Sub-Modules
gs232c_inst_judge inst_judge
(
    .i_seq       (judge_seq    ),// I, 30 
    .i_is_seq    (judge_is_seq ),// I, 1  
    .i_target    (judge_target ),// I, 30 
    .i_inst      (judge_inst   ),// I, 128
    .i_count     (judge_count  ),// I, 2  
    .i_valid     (judge_valid  ),// I, 1  
    .i_uncache   (judge_uncache),// I, 1  
    .i_pc        (judge_pc     ),// I, 32 
    .i_hint      (judge_hint   ),// I, 16 
    .pr_cancel   (pr_cancel    ),// O, 1  
    .pr_target   (pr_target    ),// O, 32 
    .pr_brop     (pr_brop      ),// O, 1  
    .pr_jrop     (pr_jrop      ),// O, 1  
    .pr_jrra     (pr_jrra      ),// O, 1  
    .pr_link     (pr_link      ),// O, 1  
    .pr_taken    (pr_taken     ),// O, 1  
    .pr_link_pc  (pr_link_pc   ),// O, 30 
    .pr_pc       (pr_pc        ),// O, 32 
    .pr_valid    (pr_valid     ),// O, 1  
    .pr_dofs     (pr_dofs      ),// O, 2  
    .pr_base     (pr_base      ),// O, 30 
    .pr_brops    (pr_brops     ),// O, 4  
    .pr_brops_raw(pr_brops_raw ),// O, 4  
    .pr_takens   (pr_takens    ),// O, 4  
    .pr_hint     (pr_hint      ),// O, 16 
    .bht_taken   (bht_taken    ),// I, 4  
    .jtb_jrops   (jtb_jrops    ),// O, 4  
    .jtb_target  (jtb_target   ),// I, 30 
    .ra          (ra           ),// I, 30 
    .count       (count        ),// O, 2  
    .clock       (clock        ),// I, 1  
    .reset       (reset        ) // I, 1  
);
gs232c_inst_queue_p
#(
    .w(39),
    .n(2 ),
    .m(3 ) 
)
buf_p
(
    .clock   (clock        ),// I, 1               
    .reset   (reset        ),// I, 1               
    .cancel  (buf_cancel   ),// I, 1               
    .head    (buf_p_head   ),// I, n + 32'h00000003
    .tail    (buf_p_tail   ),// O, n + 32'h00000003
    .tail_inc(count        ),// I, 2               
    .push    (buf_p_push   ),// I, 1               
    .i_valid (buf_p_i_valid),// I, 4               
    .i_data  (buf_w_data   ),// I, w << 2          
    .full    (buf_p_full   ),// O, 2               
    .o_data  (buf_p_read   ) // O, w * m           
);
gs232c_sel_k_words_n_m
#(
    .n       (2   ),
    .k       (3   ),
    .w       (32  ),
    .circular(1'b1) 
)
buf_pc_sel
(
    .i({buf_pc[3],buf_pc[2],buf_pc[1],buf_pc[0]}),// I, w << n
    .s(buf_pc_head[1:0]                         ),// I, n     
    .o(buf_pc_read                              ) // O, w * k 
);
endmodule // gs232c_inst_queue
