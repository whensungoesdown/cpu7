module gs232c_jhr(
    input  wire        clock     ,
    input  wire        reset     ,
    output wire [29:0] hr_last_br,
    output wire [29:0] hr_last_pr,
    output wire [63:0] hr_path_br,
    output wire [63:0] hr_path_bt,
    input  wire        pc_go     ,
    input  wire        bt_jrop   ,
    input  wire [31:0] bt_target ,
    input  wire        pr_cancel ,
    input  wire        pr_jrop   ,
    input  wire [31:0] pr_target ,
    input  wire        br_cancel ,
    input  wire        br_jrop   ,
    input  wire [31:0] br_target ,
    input  wire        wb_cancel ,
    input  wire        wb_jrop    
);
reg  [79:0] bt_path        ;
wire        bt_reset       ;
// group pr
reg  [29:0] pr_last        ;
wire [29:0] pr_last_next   ;
wire        pr_last_reset  ;
wire [63:0] pr_path        ;
reg  [1 :0] pr_path_ptr    ;
wire        pr_path_ptr_dec;
wire        pr_path_ptr_inc;
// group br
reg  [29:0] br_last        ;
wire [29:0] br_last_next   ;
reg  [79:0] br_path        ;
wire [63:0] br_path_next   ;
wire        br_reset       ;
wire [63:0] wb_path        ;
reg  [1 :0] wb_path_ptr    ;
wire        wb_path_ptr_dec;
wire        wb_path_ptr_inc;
wire        jrop           ;
assign hr_last_br      = br_last;
assign hr_last_pr      = pr_last;
assign hr_path_br      = br_path[63:0];
assign hr_path_bt      = bt_path[63:0];
assign bt_reset        = reset || wb_cancel || br_cancel || pr_cancel;
// group pr
assign pr_last_next    = pr_jrop ? pr_target[31:2] : pr_last;
assign pr_last_reset   = br_cancel || wb_cancel;
assign pr_path         = {64{wb_path_ptr == 2'h0}} & br_path[63:0] | {64{pr_jrop ? wb_path_ptr == 2'h0 : wb_path_ptr == 2'h1}} & br_path[71:8];
assign pr_path_ptr_dec = pr_jrop && !bt_jrop;
assign pr_path_ptr_inc = bt_jrop && !pr_jrop;
assign br_last_next    = br_jrop ? br_target[31:2] : br_last;
assign br_path_next    = br_jrop ? {br_path[55:0],br_target[9:2]} : br_path[63:0];
assign br_reset        = reset || wb_cancel;
assign wb_path         = {64{wb_path_ptr == 2'h0}} & br_path[63:0] | {64{wb_jrop ? wb_path_ptr == 2'h0 : wb_path_ptr == 2'h1}} & br_path[71:8];
assign wb_path_ptr_dec = wb_jrop && !br_jrop;
assign wb_path_ptr_inc = br_jrop && !wb_jrop;
assign jrop            = bt_jrop &&  pc_go  ;
always@(posedge clock)
begin
    if(reset)
    begin
        bt_path<=80'h00000000000000000000;
    end
    else
    if(wb_cancel)
    begin
        bt_path<={16'h0000,wb_path};
    end
    else
    if(br_cancel)
    begin
        bt_path<={16'h0000,br_path_next};
    end
    else
    if(pr_cancel)
    begin
        bt_path<={16'h0000,pr_path};
    end
    else
    if(jrop)
    begin
        bt_path<={bt_path[71:0],bt_target[9:2]};
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        pr_last<=30'h00000000;
    end
    else
    if(pr_last_reset)
    begin
        pr_last<=br_last_next;
    end
    else
    if(pr_jrop)
    begin
        pr_last<=pr_target[31:2];
    end
end
always@(posedge clock)
begin
    if(bt_reset)
    begin
        pr_path_ptr<=2'h0;
    end
    else
    if(pr_path_ptr_inc)
    begin
        pr_path_ptr<=pr_path_ptr + 2'h1;
    end
    else
    if(pr_path_ptr_dec)
    begin
        pr_path_ptr<=pr_path_ptr + 2'h3;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        br_last<=30'h00000000;
    end
    else
    if(br_jrop)
    begin
        br_last<=br_target[31:2];
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        br_path<=80'h00000000000000000000;
    end
    else
    if(wb_cancel)
    begin
        br_path<={16'h0000,wb_path};
    end
    else
    if(br_jrop)
    begin
        br_path<={br_path[71:0],br_target[9:2]};
    end
end
always@(posedge clock)
begin
    if(br_reset)
    begin
        wb_path_ptr<=2'h0;
    end
    else
    if(wb_path_ptr_inc)
    begin
        wb_path_ptr<=wb_path_ptr + 2'h1;
    end
    else
    if(wb_path_ptr_dec)
    begin
        wb_path_ptr<=wb_path_ptr + 2'h3;
    end
end
endmodule // gs232c_jhr
