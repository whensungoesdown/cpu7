module gs232c_pipe_pc(
    input  wire        clock    ,
    input  wire        reset    ,
    input  wire        bt_cancel,
    input  wire [15:0] bt_hint  ,
    output wire [31:0] bt_pc    ,
    input  wire [31:0] bt_target,
    input  wire        pr_cancel,
    input  wire [31:0] pr_target,
    input  wire        br_cancel,
    input  wire [31:0] br_target,
    input  wire        wb_cancel,
    input  wire [31:0] wb_target,
    input  wire        pc_go    ,
    input  wire [31:0] pc_init  ,
    // group fe
    output reg  [31:0] fe_cur   ,
    input  wire        fe_go    ,
    output reg  [15:0] fe_hint  ,
    output reg         fe_is_seq,
    output reg  [29:0] fe_seq   ,
    output wire [29:0] fe_target,
    output reg         fe_valid ,
    input  wire        iq_cancel,
    output wire [31:0] inst_addr 
);
reg  [31:0] pc_cur    ;
wire [31:0] pc_next   ;
wire        pc_next_en;
wire [29:0] pc_seq    ;
assign bt_pc   = pc_cur;
assign pc_next = wb_cancel ? wb_target : 
                 br_cancel ? br_target : 
                 pr_cancel ? pr_target : 
                 bt_cancel ? bt_target : {pc_seq,2'h0};
assign pc_next_en = pc_go || pr_cancel || br_cancel || wb_cancel;
assign pc_seq     = pc_cur[4:2] >= 3'h4 ? {pc_cur[31:5] + 27'h0000001,3'h0} : {pc_cur[31:5],pc_cur[4:2] + 3'h4};
assign fe_target  = fe_valid ? fe_cur[31:2] : pc_cur[31:2];
assign inst_addr  = pc_cur;
always@(posedge clock)
begin
    if(reset)
    begin
        pc_cur<=pc_init;
    end
    else
    if(pc_next_en)
    begin
        pc_cur<=pc_next;
    end
end
always@(posedge clock)
begin
    if(pc_go)
    begin
        fe_cur   <= pc_cur   ;
        fe_hint  <= bt_hint  ;
        fe_is_seq<=!bt_cancel;
        fe_seq   <= pc_seq   ;
    end
end
always@(posedge clock)
begin
    if(iq_cancel || reset)
    begin
        fe_valid<=1'h0;
    end
    else
    if(pc_go)
    begin
        fe_valid<=1'h1;
    end
    else
    if(fe_go)
    begin
        fe_valid<=1'h0;
    end
end
endmodule // gs232c_pipe_pc
