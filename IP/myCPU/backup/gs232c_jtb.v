module gs232c_jtb(
    input  wire        clock        ,
    input  wire        reset        ,
    input  wire [31:0] bt_pc        ,
    input  wire        pc_go        ,
    input  wire        iq_go        ,
    input  wire        pr_cancel    ,
    input  wire        buf_cancel   ,
    // group br
    input  wire        br_cancel    ,
    input  wire [4 :0] br_hint      ,
    input  wire        br_jrop      ,
    input  wire [31:0] br_pc        ,
    input  wire [31:0] br_target    ,
    input  wire [3 :0] o_jrops      ,
    output wire [29:0] o_target     ,
    input  wire [7 :0] raminit_index,
    input  wire        raminit_valid,
    input  wire [29:0] jhr_last_br  ,
    input  wire [29:0] jhr_last_pr  ,
    input  wire [63:0] jhr_path_br  ,
    input  wire [63:0] jhr_path_bt   
);
wire [119:0] buf_data      ;
reg  [119:0] buf_data0     ;
reg  [119:0] buf_data1     ;
wire [3  :0] buf_hit       ;
reg  [3  :0] buf_hit0      ;
reg  [3  :0] buf_hit1      ;
wire [159:0] data          ;
wire [3  :0] hit           ;
wire [39 :0] line_wd       ;
wire         line_we       ;
wire         prefer_base   ;
wire         prefer_last   ;
reg          ptr_r         ;
reg          ptr_w         ;
reg  [119:0] read_data     ;
reg  [3  :0] read_hit      ;
reg          read_valid    ;
wire [29 :0] res_data      ;
wire         res_hit       ;
wire         jhr_last_br_eq;
// Declaring RAM
reg  [39:0] line[7:0];
assign o_target          = res_hit ? res_data  : jhr_last_pr;
assign buf_data          = ptr_r   ? buf_data1 : buf_data0  ;
assign buf_hit           = ptr_r   ? buf_hit1  : buf_hit0   ;
assign hit           [0] = data[0  ] && data[9  :1  ] == bt_pc[14:6];
assign hit           [1] = data[40 ] && data[49 :41 ] == bt_pc[14:6];
assign hit           [2] = data[80 ] && data[89 :81 ] == bt_pc[14:6];
assign hit           [3] = data[120] && data[129:121] == bt_pc[14:6];
assign line_wd           = {br_target[31:2],br_pc[13:5],!jhr_last_br_eq};
assign line_we           = br_jrop   &&  br_cancel     ;
assign prefer_base       = br_cancel && !jhr_last_br_eq;
assign prefer_last       = br_cancel &&  jhr_last_br_eq;
assign jhr_last_br_eq    = jhr_last_br == br_target[31:2];
always@(posedge clock)
begin
    if(read_valid)
    begin
        if(ptr_w)
        begin
            buf_data1<=read_data;
            buf_hit1 <=read_hit ;
        end
        else
        begin
            buf_data0<=read_data;
            buf_hit0 <=read_hit ;
        end
    end
end
always@(posedge clock)
begin
    if(raminit_valid)
    begin
        line[raminit_index[2:0]]<=40'h0000000000;
    end
    else
    if(line_we)
    begin
        line[br_pc[4:2]]<=line_wd;
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
    if(read_valid)
    begin
        ptr_w<=!ptr_w;
    end
end
always@(posedge clock)
begin
    if(pc_go)
    begin
        read_data<={data[159:130],data[119:90],data[79:50],data[39:10]};
        read_hit<=hit;
    end
end
always@(posedge clock)
begin
    if(reset || buf_cancel || pr_cancel)
    begin
        read_valid<=1'h0;
    end
    else
    if(pc_go)
    begin
        read_valid<=1'h1;
    end
    else
    begin
        read_valid<=1'h0;
    end
end
gs232c_sel_first_field
#(
    .n(2 ),
    .w(30) 
)
buf_data_sel
(
    .i(buf_data),// I, w << n
    .s(o_jrops ),// I, 1 << n
    .o(res_data) // O, w     
);
gs232c_sel_first_field
#(
    .n(2),
    .w(1) 
)
buf_hit_sel
(
    .i(buf_hit),// I, w << n
    .s(o_jrops),// I, 1 << n
    .o(res_hit) // O, w     
);
gs232c_sel_k_words_n_m
#(
    .n       (3   ),
    .k       (4   ),
    .w       (40  ),
    .circular(1'b0) 
)
sel
(
    .i({line[7],line[6],line[5],line[4],line[3],line[2],line[1],line[0]}),// I, w << n
    .s(bt_pc[4:2]                                                       ),// I, n     
    .o(data                                                             ) // O, w * k 
);
endmodule // gs232c_jtb
