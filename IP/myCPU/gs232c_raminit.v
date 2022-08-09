module gs232c_raminit#(
    parameter n = 6 
)(
    input  wire           clock,
    input  wire           reset,
    output reg  [n - 1:0] index,
    output reg            valid 
);
wire ok;
assign ok =  &index;
always@(posedge clock)
begin
    if(reset)
    begin
        index<=0;
    end
    else
    if(valid)
    begin
        index<=index + 1;
    end
end
always@(posedge clock)
begin
    if(reset)
    begin
        valid<=1'h1;
    end
    else
    if(ok)
    begin
        valid<=1'h0;
    end
end
endmodule // gs232c_raminit
