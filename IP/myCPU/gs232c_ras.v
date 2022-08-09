module gs232c_ras(
    input  wire        clock        ,
    input  wire        reset        ,
    input  wire        raminit_valid,
    input  wire        pr_jrra      ,
    input  wire        pr_link      ,
    input  wire [29:0] pr_link_pc   ,
    input  wire        br_cancel    ,
    input  wire        br_jrra      ,
    input  wire        br_link      ,
    input  wire [29:0] br_link_pc   ,
    input  wire        wb_cancel    ,
    input  wire        wb_jrra      ,
    input  wire        wb_link      ,
    input  wire [29:0] wb_link_pc   ,
    output wire [29:0] ra            
);
// group pr
wire        pr_hit        ;
reg  [3 :0] pr_index      ;
wire [3 :0] pr_index_next ;
wire [3 :0] pr_index_recov;
reg         pr_index_valid;
wire        pr_index_we   ;
wire [31:0] pr_rdata      ;
wire [29:0] pr_res        ;
wire        pr_reset      ;
wire        pr_stack_we   ;
wire [1 :0] pr_stack_wtag ;
reg  [3 :0] pr_valid      ;
// group br
wire        br_hit        ;
reg  [3 :0] br_index      ;
wire [3 :0] br_index_next ;
wire [3 :0] br_index_recov;
reg         br_index_valid;
wire        br_index_we   ;
wire [32:0] br_rdata      ;
wire [29:0] br_res        ;
wire        br_reset      ;
wire        br_stack_we   ;
wire [2 :0] br_stack_wtag ;
reg  [1 :0] br_valid      ;
// group wb
reg  [3 :0] wb_index      ;
wire [3 :0] wb_index_next ;
wire        wb_index_we   ;
wire [29:0] wb_stack_wdata;
wire        wb_stack_we   ;
// Declaring RAMs
reg  [31:0] pr_stack[3 :0];
reg  [32:0] br_stack[1 :0];
reg  [29:0] wb_stack[15:0];
// group pr
assign pr_hit         = pr_valid[pr_index[1:0]] && pr_rdata[31:30] == pr_index[3:2];
assign pr_index_next  = pr_jrra ? pr_index + 4'hf : pr_index + 4'h1;
assign pr_index_recov = br_index_valid ? br_index : wb_index;
assign pr_index_we    = pr_link || pr_jrra;
assign pr_rdata       = pr_stack[pr_index[1:0]];
assign pr_res         = pr_rdata[29:0];
assign pr_reset       = reset || br_cancel || wb_cancel;
assign pr_stack_we    = pr_link;
assign pr_stack_wtag  =  &pr_index[1:0] ? pr_index[3:2] + 2'h1 : pr_index[3:2];
// group br
assign br_hit         = br_valid[pr_index[0]] && br_rdata[32:30] == pr_index[3:1];
assign br_index_next  = br_jrra ? br_index + 4'hf : br_index + 4'h1;
assign br_index_recov = wb_index;
assign br_index_we    = br_link || br_jrra;
assign br_rdata       = br_stack[pr_index[0]];
assign br_res         = br_rdata[29:0];
assign br_reset       = reset || wb_cancel;
assign br_stack_we    = br_link;
assign br_stack_wtag  = br_index[0] ? br_index[3:1] + 3'h1 : br_index[3:1];
assign wb_index_next  = wb_jrra ? wb_index + 4'hf : wb_index + 4'h1;
assign wb_index_we    = wb_link || wb_jrra || raminit_valid;
assign wb_stack_wdata = {30{!raminit_valid}} & wb_link_pc;
assign wb_stack_we    = wb_link || raminit_valid;
assign ra             = pr_hit ? pr_res : 
                        br_hit ? br_res : wb_stack[pr_index];
always@(posedge clock)
begin
    if(!pr_index_valid)
    begin
        pr_index<=pr_index_recov;
    end
    else
    if(pr_index_we)
    begin
        pr_index<=pr_index_next;
    end
end
always@(posedge clock)
begin
    if(pr_reset)
    begin
        pr_index_valid<=1'h0;
    end
    else
    begin
        pr_index_valid<=1'h1;
    end
end
always@(posedge clock)
begin
    if(pr_stack_we)
    begin
        pr_stack[pr_index[1:0] + 2'h1]<={pr_stack_wtag,pr_link_pc};
    end
end
always@(posedge clock)
begin
    if(pr_reset)
    begin
        pr_valid<=4'h0;
    end
    else
    if(pr_stack_we)
    begin
        pr_valid[pr_index[1:0] + 2'h1]<=1'h1;
    end
end
always@(posedge clock)
begin
    if(!br_index_valid)
    begin
        br_index<=br_index_recov;
    end
    else
    if(br_index_we)
    begin
        br_index<=br_index_next;
    end
end
always@(posedge clock)
begin
    if(br_reset)
    begin
        br_index_valid<=1'h0;
    end
    else
    begin
        br_index_valid<=1'h1;
    end
end
always@(posedge clock)
begin
    if(br_stack_we)
    begin
        br_stack[!br_index[0]]<={br_stack_wtag,br_link_pc};
    end
end
always@(posedge clock)
begin
    if(br_reset)
    begin
        br_valid<=2'h0;
    end
    else
    if(br_stack_we)
    begin
        br_valid[!br_index[0]]<=1'h1;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        wb_index<=4'h0;
    end
    else
    if(wb_index_we)
    begin
        wb_index<=wb_index_next;
    end
end
always@(posedge clock)
begin
    if(wb_stack_we)
    begin
        wb_stack[wb_index + 4'h1]<=wb_stack_wdata;
    end
end
endmodule // gs232c_ras
