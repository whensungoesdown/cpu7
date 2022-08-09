module gs232c_bhr(
    input  wire        clock    ,
    input  wire        reset    ,
    input  wire        pc_go    ,
    input  wire        bt_brop  ,
    input  wire [3 :0] bt_brops ,
    input  wire        pr_brop  ,
    input  wire [3 :0] pr_brops ,
    input  wire        pr_cancel,
    input  wire        pr_valid ,
    input  wire        br_brop  ,
    input  wire        br_cancel,
    input  wire        br_taken ,
    input  wire        wb_brop  ,
    input  wire        wb_cancel,
    input  wire        wb_taken ,
    output wire [24:0] hr_br    ,
    output wire [20:0] hr_bt     
);
// group bt
reg  [20:0] bt_hr     ;
wire [20:0] bt_hr_next;
wire [20:0] bt_hr_sel ;
wire [20:0] bt_hr_sft1;
wire [20:0] bt_hr_sft2;
wire        bt_reset  ;
// group pr
reg  [20:0] pr_hr     ;
wire [20:0] pr_hr_next;
wire [20:0] pr_hr_sel ;
wire [20:0] pr_hr_sft1;
wire [20:0] pr_hr_sft2;
wire        pr_reset  ;
reg         pr_restore;
reg  [23:0] br_hr     ;
wire [23:0] br_hr_sft ;
reg         br_restore;
reg  [20:0] wb_hr     ;
wire [20:0] wb_hr_sft ;
reg         wb_restore;
// group bt
assign bt_hr_next = {bt_hr_sft2[20:1],bt_brop || bt_hr_sft2[0]};
assign bt_hr_sel  = {21{wb_restore}} & wb_hr | {21{br_restore}} & br_hr[20:0] | {21{pr_restore}} & pr_hr | {21{!bt_reset}} & bt_hr;
assign bt_hr_sft1 = {21{!bt_brops[0] && !bt_brops[1]}} & bt_hr_sel
                  | {{20{bt_brops[0] ^ bt_brops[1]}} & bt_hr_sel[19:0],1'b0}
                  | {{19{bt_brops[0] && bt_brops[1]}} & bt_hr_sel[18:0],2'b00};
assign bt_hr_sft2 = {21{!bt_brops[2] && !bt_brops[3]}} & bt_hr_sft1
                  | {{20{bt_brops[2] ^ bt_brops[3]}} & bt_hr_sft1[19:0],1'b0}
                  | {{19{bt_brops[2] && bt_brops[3]}} & bt_hr_sft1[18:0],2'b00};
assign bt_reset   = wb_restore || br_restore || pr_restore;
// group pr
assign pr_hr_next = {pr_hr_sft2[20:1],pr_brop || pr_hr_sft2[0]};
assign pr_hr_sel  = {21{wb_restore}} & wb_hr | {21{br_restore}} & br_hr[20:0] | {21{!pr_reset}} & pr_hr;
assign pr_hr_sft1 = {21{!pr_brops[0] && !pr_brops[1]}} & pr_hr_sel
                  | {{20{pr_brops[0] ^ pr_brops[1]}} & pr_hr_sel[19:0],1'b0}
                  | {{19{pr_brops[0] && pr_brops[1]}} & pr_hr_sel[18:0],2'b00};
assign pr_hr_sft2 = {21{!pr_brops[2] && !pr_brops[3]}} & pr_hr_sft1
                  | {{20{pr_brops[2] ^ pr_brops[3]}} & pr_hr_sft1[19:0],1'b0}
                  | {{19{pr_brops[2] && pr_brops[3]}} & pr_hr_sft1[18:0],2'b00};
assign pr_reset  = wb_restore || br_restore;
assign br_hr_sft = {br_hr[22:0],br_taken};
assign wb_hr_sft = {wb_hr[19:0],wb_taken};
assign hr_br     = {br_hr,br_taken};
assign hr_bt     = bt_hr_sel;
always@(posedge clock)
begin
    if(pc_go)
    begin
        bt_hr<=bt_hr_next;
    end
    else
    if(bt_reset)
    begin
        bt_hr<=bt_hr_sel;
    end
end
always@(posedge clock)
begin
    if(pr_reset)
    begin
        pr_hr<=pr_hr_sel;
    end
    else
    if(pr_valid)
    begin
        pr_hr<=pr_hr_next;
    end
end
always@(posedge clock)
begin
    if(reset || wb_cancel || br_cancel)
    begin
        pr_restore<=1'h0;
    end
    else
    if(pr_cancel)
    begin
        pr_restore<=1'h1;
    end
    else
    begin
        pr_restore<=1'h0;
    end
end
always@(posedge clock)
begin
    if(wb_restore)
    begin
        br_hr<={3'h0,wb_hr};
    end
    else
    if(br_brop)
    begin
        br_hr<=br_hr_sft;
    end
end
always@(posedge clock)
begin
    if(reset || wb_cancel)
    begin
        br_restore<=1'h0;
    end
    else
    if(br_cancel)
    begin
        br_restore<=1'h1;
    end
    else
    begin
        br_restore<=1'h0;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        wb_hr<=21'h000000;
    end
    else
    if(wb_brop)
    begin
        wb_hr<=wb_hr_sft;
    end
end
always@(posedge clock)
begin
    if(reset || wb_cancel)
    begin
        wb_restore<=1'h1;
    end
    else
    begin
        wb_restore<=1'h0;
    end
end
endmodule // gs232c_bhr
