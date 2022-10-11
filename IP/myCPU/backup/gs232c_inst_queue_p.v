module gs232c_inst_queue_p#(
    parameter w = 39,
    parameter n = 2 ,
    parameter m = 3  
)(
    input  wire                            clock   ,
    input  wire                            reset   ,
    input  wire                            cancel  ,
    input  wire [(n + 32'h00000003) - 1:0] head    ,
    output reg  [(n + 32'h00000003) - 1:0] tail    ,
    input  wire [1                 :0]     tail_inc,
    input  wire                            push    ,
    input  wire [(w << 2)           - 1:0] i_data  ,
    input  wire [3                 :0]     i_valid ,
    output wire [1                 :0]     full    ,
    output wire [w * m              - 1:0] o_data   
);

reg  [w-1:0]data0[(1<<n)-1:0];
reg  [w-1:0]data1[(1<<n)-1:0];
reg  [w-1:0]data2[(1<<n)-1:0];
reg  [w-1:0]data3[(1<<n)-1:0];
wire [n+2:0]tail_next = tail + {{1+n{1'b0}},tail_inc} + {{2+n{1'b0}},1'b1};
wire we0 = i_valid[0] && tail[1:0]==2'b00
        || i_valid[1] && tail[1:0]==2'b11
        || i_valid[2] && tail[1:0]==2'b10
        || i_valid[3] && tail[1:0]==2'b01;
wire we1 = i_valid[0] && tail[1:0]==2'b01
        || i_valid[1] && tail[1:0]==2'b00
        || i_valid[2] && tail[1:0]==2'b11
        || i_valid[3] && tail[1:0]==2'b10;
wire we2 = i_valid[0] && tail[1:0]==2'b10
        || i_valid[1] && tail[1:0]==2'b01
        || i_valid[2] && tail[1:0]==2'b00
        || i_valid[3] && tail[1:0]==2'b11;
wire we3 = i_valid[0] && tail[1:0]==2'b11
        || i_valid[1] && tail[1:0]==2'b10
        || i_valid[2] && tail[1:0]==2'b01
        || i_valid[3] && tail[1:0]==2'b00;
wire [w-1:0]wdata0 = {w{tail[1:0]==2'b00}} & i_data[  w-1:  0]
                   | {w{tail[1:0]==2'b01}} & i_data[4*w-1:3*w]
                   | {w{tail[1:0]==2'b10}} & i_data[3*w-1:2*w]
                   | {w{tail[1:0]==2'b11}} & i_data[2*w-1:  w];
wire [w-1:0]wdata1 = {w{tail[1:0]==2'b00}} & i_data[2*w-1:  w]
                   | {w{tail[1:0]==2'b01}} & i_data[  w-1:  0]
                   | {w{tail[1:0]==2'b10}} & i_data[4*w-1:3*w]
                   | {w{tail[1:0]==2'b11}} & i_data[3*w-1:2*w];
wire [w-1:0]wdata2 = {w{tail[1:0]==2'b00}} & i_data[3*w-1:2*w]
                   | {w{tail[1:0]==2'b01}} & i_data[2*w-1:  w]
                   | {w{tail[1:0]==2'b10}} & i_data[  w-1:  0]
                   | {w{tail[1:0]==2'b11}} & i_data[4*w-1:3*w];
wire [w-1:0]wdata3 = {w{tail[1:0]==2'b00}} & i_data[4*w-1:3*w]
                   | {w{tail[1:0]==2'b01}} & i_data[3*w-1:2*w]
                   | {w{tail[1:0]==2'b10}} & i_data[2*w-1:  w]
                   | {w{tail[1:0]==2'b11}} & i_data[  w-1:  0];
wire [n-1:0]waddr0 = (|tail[1:0])?tail[n+1:2]+1:tail[n+1:2];
wire [n-1:0]waddr1 =   tail[1]   ?tail[n+1:2]+1:tail[n+1:2];
wire [n-1:0]waddr2 = (&tail[1:0])?tail[n+1:2]+1:tail[n+1:2];
wire [n-1:0]waddr3 = tail[n+1:2];
wire [n-1:0]raddr0 = (|head[1:0])?head[n+1:2]+1:head[n+1:2];
wire [n-1:0]raddr1 =   head[1]   ?head[n+1:2]+1:head[n+1:2];
wire [n-1:0]raddr2 = (&head[1:0])?head[n+1:2]+1:head[n+1:2];
wire [n-1:0]raddr3 = head[n+1:2];
wire [w-1:0]read0  = data0[raddr0];
wire [w-1:0]read1  = data1[raddr1];
wire [w-1:0]read2  = data2[raddr2];
wire [w-1:0]read3  = data3[raddr3];
assign full[0] = tail > head && {1'b0,tail} + 4 > {head[n+2],!head[n+2],head[n+1:0]}
              || tail < head && {1'b1,tail} + 4 > {head[n+2],!head[n+2],head[n+1:0]};
assign full[1] = tail > head && {1'b0,tail} + 8 > {head[n+2],!head[n+2],head[n+1:0]}
              || tail < head && {1'b1,tail} + 8 > {head[n+2],!head[n+2],head[n+1:0]};
assign o_data[  w-1:  0] = {w{head[1:0]==2'b00}} & read0
                         | {w{head[1:0]==2'b01}} & read1
                         | {w{head[1:0]==2'b10}} & read2
                         | {w{head[1:0]==2'b11}} & read3;
generate
if(m>1) begin:m2
    assign o_data[2*w-1:  w] = {w{head[1:0]==2'b00}} & read1
                             | {w{head[1:0]==2'b01}} & read2
                             | {w{head[1:0]==2'b10}} & read3
                             | {w{head[1:0]==2'b11}} & read0;
end
if(m>2) begin:m3
    assign o_data[3*w-1:2*w] = {w{head[1:0]==2'b00}} & read2
                             | {w{head[1:0]==2'b01}} & read3
                             | {w{head[1:0]==2'b10}} & read0
                             | {w{head[1:0]==2'b11}} & read1;
end
endgenerate
always@(posedge clock)
begin
    if(we0) begin
        data0[waddr0] <= wdata0;
    end
    if(we1) begin
        data1[waddr1] <= wdata1;
    end
    if(we2) begin
        data2[waddr2] <= wdata2;
    end
    if(we3) begin
        data3[waddr3] <= wdata3;
    end
end
always@(posedge clock)
begin
    if(reset) begin
        tail <= 0;
    end
    else
    if(cancel) begin
        tail <= head;
    end
    else
    if(push) begin
        tail <= tail_next;
    end
end

endmodule // gs232c_inst_queue_p
