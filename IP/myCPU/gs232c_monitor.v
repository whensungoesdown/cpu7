module gs232c_monitor(
    input  wire        clock          ,
    input  wire        reset          ,
    // group pr
    input  wire [29:0] pr_base        ,
    input  wire        pr_brop        ,
    input  wire [3 :0] pr_brops       ,
    input  wire [3 :0] pr_brops_raw   ,
    input  wire        pr_cancel      ,
    input  wire [1 :0] pr_dofs        ,
    input  wire [15:0] pr_hint        ,
    input  wire        pr_jrop        ,
    input  wire        pr_jrra        ,
    input  wire        pr_link        ,
    input  wire [29:0] pr_link_pc     ,
    input  wire [31:0] pr_pc          ,
    input  wire        pr_taken       ,
    input  wire [3 :0] pr_takens      ,
    input  wire [31:0] pr_target      ,
    input  wire        pr_valid       ,
    // group br
    input  wire        br_brop        ,
    input  wire        br_cancel      ,
    input  wire [4 :0] br_hint        ,
    input  wire        br_jrop        ,
    input  wire        br_jrra        ,
    input  wire        br_link        ,
    input  wire [29:0] br_link_pc     ,
    input  wire [31:0] br_pc          ,
    input  wire        br_sign        ,
    input  wire        br_taken       ,
    input  wire [31:0] br_target      ,
    // group wb
    input  wire        wb_brop        ,
    input  wire        wb_cancel      ,
    input  wire        wb_jrop        ,
    input  wire        wb_jrra        ,
    input  wire        wb_link        ,
    input  wire [29:0] wb_link_pc     ,
    input  wire [31:0] wb_pc          ,
    input  wire        wb_taken       ,
    input  wire [31:0] wb_target      ,
    // group o
    input  wire [2 :0] o_allow        ,
    input  wire        o_port0_ex     ,
    input  wire [5 :0] o_port0_exccode,
    input  wire [4 :0] o_port0_hint   ,
    input  wire [31:0] o_port0_inst   ,
    input  wire [31:0] o_port0_pc     ,
    input  wire        o_port0_taken  ,
    input  wire [29:0] o_port0_target ,
    input  wire        o_port1_ex     ,
    input  wire [5 :0] o_port1_exccode,
    input  wire [4 :0] o_port1_hint   ,
    input  wire [31:0] o_port1_inst   ,
    input  wire [31:0] o_port1_pc     ,
    input  wire        o_port1_taken  ,
    input  wire [29:0] o_port1_target ,
    input  wire        o_port2_ex     ,
    input  wire [5 :0] o_port2_exccode,
    input  wire [4 :0] o_port2_hint   ,
    input  wire [31:0] o_port2_inst   ,
    input  wire [31:0] o_port2_pc     ,
    input  wire        o_port2_taken  ,
    input  wire [29:0] o_port2_target ,
    input  wire [2 :0] o_valid         
);
wire        pr_ball                ;
wire        pr_none                ;
wire        br_ball                ;
wire        wb_ball                ;
// group perf
reg  [31:0] perf_br_ball_cnt       ;
reg  [31:0] perf_br_ball_cnt_rec   ;
reg  [31:0] perf_br_ball_err       ;
reg  [31:0] perf_br_ball_pth       ;
wire [31:0] perf_br_ball_pth_next  ;
reg  [31:0] perf_br_brop_cnt       ;
reg  [31:0] perf_br_brop_cnt_rec   ;
reg  [31:0] perf_br_brop_err       ;
reg  [31:0] perf_br_brop_pth       ;
wire [31:0] perf_br_brop_pth_next  ;
reg  [31:0] perf_br_jrop_cnt       ;
reg  [31:0] perf_br_jrop_cnt_rec   ;
reg  [31:0] perf_br_jrop_err       ;
reg  [31:0] perf_br_jrop_pth       ;
wire [31:0] perf_br_jrop_pth_next  ;
reg  [31:0] perf_br_jrra_cnt       ;
reg  [31:0] perf_br_jrra_cnt_rec   ;
reg  [31:0] perf_br_jrra_err       ;
reg  [31:0] perf_br_jrra_pth       ;
wire [31:0] perf_br_jrra_pth_next  ;
wire [2 :0] perf_iq_be             ;
reg  [31:0] perf_iq_be_cnt0        ;
reg  [31:0] perf_iq_be_cnt1        ;
reg  [31:0] perf_iq_be_cnt2        ;
wire [2 :0] perf_iq_fe             ;
reg  [31:0] perf_iq_fe_cnt0        ;
reg  [31:0] perf_iq_fe_cnt1        ;
reg  [31:0] perf_iq_fe_cnt2        ;
wire [3 :0] perf_iq_go             ;
reg  [31:0] perf_iq_go_cnt0        ;
reg  [31:0] perf_iq_go_cnt1        ;
reg  [31:0] perf_iq_go_cnt2        ;
reg  [31:0] perf_iq_go_cnt3        ;
reg  [31:0] perf_pr_ball_cnt       ;
reg  [31:0] perf_pr_ball_err       ;
reg  [31:0] perf_pr_brop_cnt       ;
reg  [31:0] perf_pr_brop_err       ;
reg  [31:0] perf_pr_jrop_cnt       ;
reg  [31:0] perf_pr_jrop_err       ;
reg  [31:0] perf_pr_jrra_cnt       ;
reg  [31:0] perf_pr_jrra_err       ;
reg  [31:0] perf_pr_none_cnt       ;
reg  [31:0] perf_pr_none_err       ;
reg  [31:0] perf_wb_ball_cnt       ;
wire [31:0] perf_wb_ball_cnt_next  ;
reg  [31:0] perf_wb_ball_pth       ;
wire [31:0] perf_wb_ball_pth_next  ;
reg  [31:0] perf_wb_brop_cnt       ;
wire [31:0] perf_wb_brop_cnt_next  ;
reg  [31:0] perf_wb_brop_pth       ;
wire [31:0] perf_wb_brop_pth_next  ;
reg  [31:0] perf_wb_jrop_cnt       ;
wire [31:0] perf_wb_jrop_cnt_next  ;
reg  [31:0] perf_wb_jrop_pth       ;
wire [31:0] perf_wb_jrop_pth_next  ;
reg  [31:0] perf_wb_jrra_cnt       ;
wire [31:0] perf_wb_jrra_cnt_next  ;
reg  [31:0] perf_wb_jrra_pth       ;
wire [31:0] perf_wb_jrra_pth_next  ;
// group asrt
reg         asrt_br_cancel_one     ;
reg         asrt_br_cancel_one_last;
wire        asrt_br_cnt_onehot     ;
reg         asrt_pr_cancel_one     ;
reg         asrt_pr_cancel_one_last;
wire        asrt_wb_cnt_onehot     ;
assign pr_ball               = pr_brop || pr_jrop || pr_jrra;
assign pr_none               = pr_valid && !(pr_brop || pr_jrop || pr_jrra);
assign br_ball               = br_brop || br_jrop || br_jrra;
assign wb_ball               = wb_brop || wb_jrop || wb_jrra;
// group perf
assign perf_br_ball_pth_next = br_ball ? {perf_br_ball_pth[30:0],1'b0} ^ {32{perf_br_ball_pth[31]}} & 32'h0017beaf ^ br_pc : perf_br_ball_pth;
assign perf_br_brop_pth_next = br_brop ? {perf_br_brop_pth[30:0],1'b0} ^ {32{perf_br_brop_pth[31]}} & 32'h0017beaf ^ br_pc : perf_br_brop_pth;
assign perf_br_jrop_pth_next = br_jrop ? {perf_br_jrop_pth[30:0],1'b0} ^ {32{perf_br_jrop_pth[31]}} & 32'h0017beaf ^ br_pc : perf_br_jrop_pth;
assign perf_br_jrra_pth_next = br_jrra ? {perf_br_jrra_pth[30:0],1'b0} ^ {32{perf_br_jrra_pth[31]}} & 32'h0017beaf ^ br_pc : perf_br_jrra_pth;
assign perf_iq_be            = {o_valid[1:0] & o_allow[1:0],1'b1} & o_valid & ~o_allow;
assign perf_iq_fe            = {o_valid[1:0] & o_allow[1:0],1'b1} & o_allow & ~o_valid;
assign perf_iq_go            = {o_valid & o_allow,1'b1} & {1'b1,~o_valid | ~o_allow};
assign perf_wb_ball_cnt_next = wb_ball ? perf_wb_ball_cnt + 32'h00000001 : perf_wb_ball_cnt;
assign perf_wb_ball_pth_next = wb_ball ? {perf_wb_ball_pth[30:0],1'b0} ^ {32{perf_wb_ball_pth[31]}} & 32'h0017beaf ^ wb_pc : perf_wb_ball_pth;
assign perf_wb_brop_cnt_next = wb_brop ? perf_wb_brop_cnt + 32'h00000001 : perf_wb_brop_cnt;
assign perf_wb_brop_pth_next = wb_brop ? {perf_wb_brop_pth[30:0],1'b0} ^ {32{perf_wb_brop_pth[31]}} & 32'h0017beaf ^ wb_pc : perf_wb_brop_pth;
assign perf_wb_jrop_cnt_next = wb_jrop ? perf_wb_jrop_cnt + 32'h00000001 : perf_wb_jrop_cnt;
assign perf_wb_jrop_pth_next = wb_jrop ? {perf_wb_jrop_pth[30:0],1'b0} ^ {32{perf_wb_jrop_pth[31]}} & 32'h0017beaf ^ wb_pc : perf_wb_jrop_pth;
assign perf_wb_jrra_cnt_next = wb_jrra ? perf_wb_jrra_cnt + 32'h00000001 : perf_wb_jrra_cnt;
assign perf_wb_jrra_pth_next = wb_jrra ? {perf_wb_jrra_pth[30:0],1'b0} ^ {32{perf_wb_jrra_pth[31]}} & 32'h0017beaf ^ wb_pc : perf_wb_jrra_pth;
assign asrt_br_cnt_onehot    = perf_br_ball_cnt == perf_br_brop_cnt + perf_br_jrop_cnt + perf_br_jrra_cnt;
assign asrt_wb_cnt_onehot    = perf_wb_ball_cnt == perf_wb_brop_cnt + perf_wb_jrop_cnt + perf_wb_jrra_cnt;
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_ball_cnt<=32'h00000000;
        perf_br_ball_err<=32'h00000000;
    end
    else
    if(br_ball)
    begin
        perf_br_ball_cnt<=perf_br_ball_cnt + 32'h00000001;
        perf_br_ball_err<=br_cancel ? perf_br_ball_err + 32'h00000001 : perf_br_ball_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_ball_cnt_rec<=32'h00000000;
        perf_br_ball_pth    <=32'h00000000;
    end
    else
    if(wb_cancel)
    begin
        perf_br_ball_cnt_rec<=perf_wb_brop_cnt_next;
        perf_br_ball_pth    <=perf_wb_brop_pth_next;
    end
    else
    if(br_ball)
    begin
        perf_br_ball_cnt_rec<=perf_br_ball_cnt_rec + 32'h00000001;
        perf_br_ball_pth<=perf_br_ball_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_brop_cnt<=32'h00000000;
        perf_br_brop_err<=32'h00000000;
    end
    else
    if(br_brop)
    begin
        perf_br_brop_cnt<=perf_br_brop_cnt + 32'h00000001;
        perf_br_brop_err<=br_cancel ? perf_br_brop_err + 32'h00000001 : perf_br_brop_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_brop_cnt_rec<=32'h00000000;
        perf_br_brop_pth    <=32'h00000000;
    end
    else
    if(wb_cancel)
    begin
        perf_br_brop_cnt_rec<=perf_wb_brop_cnt_next;
        perf_br_brop_pth    <=perf_wb_brop_pth_next;
    end
    else
    if(br_brop)
    begin
        perf_br_brop_cnt_rec<=perf_br_brop_cnt_rec + 32'h00000001;
        perf_br_brop_pth<=perf_br_brop_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_jrop_cnt<=32'h00000000;
        perf_br_jrop_err<=32'h00000000;
    end
    else
    if(br_jrop)
    begin
        perf_br_jrop_cnt<=perf_br_jrop_cnt + 32'h00000001;
        perf_br_jrop_err<=br_cancel ? perf_br_jrop_err + 32'h00000001 : perf_br_jrop_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_jrop_cnt_rec<=32'h00000000;
        perf_br_jrop_pth    <=32'h00000000;
    end
    else
    if(wb_cancel)
    begin
        perf_br_jrop_cnt_rec<=perf_wb_brop_cnt_next;
        perf_br_jrop_pth    <=perf_wb_brop_pth_next;
    end
    else
    if(br_jrop)
    begin
        perf_br_jrop_cnt_rec<=perf_br_jrop_cnt_rec + 32'h00000001;
        perf_br_jrop_pth<=perf_br_jrop_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_jrra_cnt<=32'h00000000;
        perf_br_jrra_err<=32'h00000000;
    end
    else
    if(br_jrra)
    begin
        perf_br_jrra_cnt<=perf_br_jrra_cnt + 32'h00000001;
        perf_br_jrra_err<=br_cancel ? perf_br_jrra_err + 32'h00000001 : perf_br_jrra_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_br_jrra_cnt_rec<=32'h00000000;
        perf_br_jrra_pth    <=32'h00000000;
    end
    else
    if(wb_cancel)
    begin
        perf_br_jrra_cnt_rec<=perf_wb_brop_cnt_next;
        perf_br_jrra_pth    <=perf_wb_brop_pth_next;
    end
    else
    if(br_jrra)
    begin
        perf_br_jrra_cnt_rec<=perf_br_jrra_cnt_rec + 32'h00000001;
        perf_br_jrra_pth<=perf_br_jrra_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_be_cnt0<=32'h00000000;
    end
    else
    if(perf_iq_be[0])
    begin
        perf_iq_be_cnt0<=perf_iq_be_cnt0 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_be_cnt1<=32'h00000000;
    end
    else
    if(perf_iq_be[1])
    begin
        perf_iq_be_cnt1<=perf_iq_be_cnt1 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_be_cnt2<=32'h00000000;
    end
    else
    if(perf_iq_be[2])
    begin
        perf_iq_be_cnt2<=perf_iq_be_cnt2 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_fe_cnt0<=32'h00000000;
    end
    else
    if(perf_iq_fe[0])
    begin
        perf_iq_fe_cnt0<=perf_iq_fe_cnt0 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_fe_cnt1<=32'h00000000;
    end
    else
    if(perf_iq_fe[1])
    begin
        perf_iq_fe_cnt1<=perf_iq_fe_cnt1 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_fe_cnt2<=32'h00000000;
    end
    else
    if(perf_iq_fe[2])
    begin
        perf_iq_fe_cnt2<=perf_iq_fe_cnt2 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_go_cnt0<=32'h00000000;
    end
    else
    if(perf_iq_go[0])
    begin
        perf_iq_go_cnt0<=perf_iq_go_cnt0 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_go_cnt1<=32'h00000000;
    end
    else
    if(perf_iq_go[1])
    begin
        perf_iq_go_cnt1<=perf_iq_go_cnt1 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_go_cnt2<=32'h00000000;
    end
    else
    if(perf_iq_go[2])
    begin
        perf_iq_go_cnt2<=perf_iq_go_cnt2 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_iq_go_cnt3<=32'h00000000;
    end
    else
    if(perf_iq_go[3])
    begin
        perf_iq_go_cnt3<=perf_iq_go_cnt3 + 32'h00000001;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_pr_ball_cnt<=32'h00000000;
        perf_pr_ball_err<=32'h00000000;
    end
    else
    if(pr_ball)
    begin
        perf_pr_ball_cnt<=perf_pr_ball_cnt + 32'h00000001;
        perf_pr_ball_err<=pr_cancel ? perf_pr_ball_err + 32'h00000001 : perf_pr_ball_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_pr_brop_cnt<=32'h00000000;
        perf_pr_brop_err<=32'h00000000;
    end
    else
    if(pr_brop)
    begin
        perf_pr_brop_cnt<=perf_pr_brop_cnt + 32'h00000001;
        perf_pr_brop_err<=pr_cancel ? perf_pr_brop_err + 32'h00000001 : perf_pr_brop_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_pr_jrop_cnt<=32'h00000000;
        perf_pr_jrop_err<=32'h00000000;
    end
    else
    if(pr_jrop)
    begin
        perf_pr_jrop_cnt<=perf_pr_jrop_cnt + 32'h00000001;
        perf_pr_jrop_err<=pr_cancel ? perf_pr_jrop_err + 32'h00000001 : perf_pr_jrop_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_pr_jrra_cnt<=32'h00000000;
        perf_pr_jrra_err<=32'h00000000;
    end
    else
    if(pr_jrra)
    begin
        perf_pr_jrra_cnt<=perf_pr_jrra_cnt + 32'h00000001;
        perf_pr_jrra_err<=pr_cancel ? perf_pr_jrra_err + 32'h00000001 : perf_pr_jrra_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_pr_none_cnt<=32'h00000000;
        perf_pr_none_err<=32'h00000000;
    end
    else
    if(pr_none)
    begin
        perf_pr_none_cnt<=perf_pr_none_cnt + 32'h00000001;
        perf_pr_none_err<=pr_cancel ? perf_pr_none_err + 32'h00000001 : perf_pr_none_err;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_wb_ball_cnt<=32'h00000000;
        perf_wb_ball_pth<=32'h00000000;
    end
    else
    if(wb_ball)
    begin
        perf_wb_ball_cnt<=perf_wb_ball_cnt_next;
        perf_wb_ball_pth<=perf_wb_ball_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_wb_brop_cnt<=32'h00000000;
        perf_wb_brop_pth<=32'h00000000;
    end
    else
    if(wb_brop)
    begin
        perf_wb_brop_cnt<=perf_wb_brop_cnt_next;
        perf_wb_brop_pth<=perf_wb_brop_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_wb_jrop_cnt<=32'h00000000;
        perf_wb_jrop_pth<=32'h00000000;
    end
    else
    if(wb_jrop)
    begin
        perf_wb_jrop_cnt<=perf_wb_jrop_cnt_next;
        perf_wb_jrop_pth<=perf_wb_jrop_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        perf_wb_jrra_cnt<=32'h00000000;
        perf_wb_jrra_pth<=32'h00000000;
    end
    else
    if(wb_jrra)
    begin
        perf_wb_jrra_cnt<=perf_wb_jrra_cnt_next;
        perf_wb_jrra_pth<=perf_wb_jrra_pth_next;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        asrt_br_cancel_one<=1'h1;
    end
    else
    if(br_cancel)
    begin
        asrt_br_cancel_one<=asrt_br_cancel_one && !asrt_br_cancel_one_last;
    end
end
always@(posedge clock)
begin
    asrt_br_cancel_one_last<=br_cancel;
end
always@(posedge clock)
begin
    if(reset)
    begin
        asrt_pr_cancel_one<=1'h1;
    end
    else
    if(pr_cancel)
    begin
        asrt_pr_cancel_one<=asrt_pr_cancel_one && !asrt_pr_cancel_one_last;
    end
end
always@(posedge clock)
begin
    asrt_pr_cancel_one_last<=pr_cancel;
end
endmodule // gs232c_monitor
