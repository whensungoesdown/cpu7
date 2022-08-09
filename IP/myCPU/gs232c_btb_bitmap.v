module gs232c_btb_bitmap(
    input  wire       clock,
    input  wire       reset,
    input  wire [9:0] raddr,
    output wire [3:0] rdata,
    input  wire [9:0] waddr,
    input  wire [3:0] wmask,
    input  wire [3:0] wdata 
);
// group data
wire [3  :0] data_read  ;
reg  [255:0] data_tile0 ;
reg  [255:0] data_tile1 ;
reg  [255:0] data_tile2 ;
reg  [255:0] data_tile3 ;
wire [3  :0] data_wdata ;
wire [3  :0] data_wmask ;
// group raddr
wire [2  :0] raddr_mask ;
wire [1  :0] raddr_offs0;
wire [1  :0] raddr_offs1;
wire [1  :0] raddr_offs2;
wire [1  :0] raddr_offs3;
// group waddr
wire [2  :0] waddr_mask ;
wire [1  :0] waddr_offs0;
wire [1  :0] waddr_offs1;
wire [1  :0] waddr_offs2;
wire [1  :0] waddr_offs3;
// group data
assign data_read [0] = data_tile0[{raddr[9:4],raddr_offs0}] && (raddr[3:2] != 2'h3 || !raddr_mask[0]);
assign data_read [1] = data_tile1[{raddr[9:4],raddr_offs1}] && (raddr[3:2] != 2'h3 || !raddr_mask[1]);
assign data_read [2] = data_tile2[{raddr[9:4],raddr_offs2}] && (raddr[3:2] != 2'h3 || !raddr_mask[2]);
assign data_read [3] = data_tile3[{raddr[9:4],raddr_offs3}];
assign data_wdata    = {4{waddr[1:0] == 2'h0}} & wdata
                     | {4{waddr[1:0] == 2'h1}} & {wdata[2:0],wdata[3]}
                     | {4{waddr[1:0] == 2'h2}} & {wdata[1:0],wdata[3:2]}
                     | {4{waddr[1:0] == 2'h3}} & {wdata[0],wdata[3:1]};
assign data_wmask = {4{waddr[1:0] == 2'h0}} & wmask
                  | {4{waddr[1:0] == 2'h1}} & {wmask[2:0],wmask[3]}
                  | {4{waddr[1:0] == 2'h2}} & {wmask[1:0],wmask[3:2]}
                  | {4{waddr[1:0] == 2'h3}} & {wmask[0],wmask[3:1]};
// group raddr
assign raddr_mask  = { &raddr[1:0],raddr[1], |raddr[1:0]};
assign raddr_offs0 = {2{!raddr_mask[0]}} & raddr[3:2] | {2{raddr_mask[0]}} & raddr[3:2] + 2'h1;
assign raddr_offs1 = {2{!raddr_mask[1]}} & raddr[3:2] | {2{raddr_mask[1]}} & raddr[3:2] + 2'h1;
assign raddr_offs2 = {2{!raddr_mask[2]}} & raddr[3:2] | {2{raddr_mask[2]}} & raddr[3:2] + 2'h1;
assign raddr_offs3 = raddr[3:2];
assign rdata       = {4{raddr[1:0] == 2'h0}} & data_read
                   | {4{raddr[1:0] == 2'h1}} & {data_read[0],data_read[3:1]}
                   | {4{raddr[1:0] == 2'h2}} & {data_read[1:0],data_read[3:2]}
                   | {4{raddr[1:0] == 2'h3}} & {data_read[2:0],data_read[3]};
// group waddr
assign waddr_mask  = { &waddr[1:0],waddr[1], |waddr[1:0]};
assign waddr_offs0 = {2{!waddr_mask[0]}} & waddr[3:2] | {2{waddr_mask[0]}} & waddr[3:2] + 2'h1;
assign waddr_offs1 = {2{!waddr_mask[1]}} & waddr[3:2] | {2{waddr_mask[1]}} & waddr[3:2] + 2'h1;
assign waddr_offs2 = {2{!waddr_mask[2]}} & waddr[3:2] | {2{waddr_mask[2]}} & waddr[3:2] + 2'h1;
assign waddr_offs3 = waddr[3:2];
always@(posedge clock)
begin
    if(data_wmask[0])
    begin
        data_tile0[{waddr[9:4],waddr_offs0}]<=data_wdata[0];
    end
end
always@(posedge clock)
begin
    if(data_wmask[1])
    begin
        data_tile1[{waddr[9:4],waddr_offs1}]<=data_wdata[1];
    end
end
always@(posedge clock)
begin
    if(data_wmask[2])
    begin
        data_tile2[{waddr[9:4],waddr_offs2}]<=data_wdata[2];
    end
end
always@(posedge clock)
begin
    if(data_wmask[3])
    begin
        data_tile3[{waddr[9:4],waddr_offs3}]<=data_wdata[3];
    end
end
endmodule // gs232c_btb_bitmap
