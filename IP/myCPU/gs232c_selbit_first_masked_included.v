module gs232c_selbit_first_masked_included#(
    parameter n = 2 
)(
    input  wire [(1 << n) - 1:0] i,
    input  wire [(1 << n) - 1:0] s,
    output wire                  o 
);
generate
if(n==3)
begin:n3
    wire h = i[0] || i[1] && !s[0] || i[2] && (~|s[1:0]) || i[3] && (~|s[2:0]);
    wire l = i[4] || i[5] && !s[4] || i[6] && (~|s[5:4]) || i[7] && (~|s[6:4]);
    assign o = l || h && (~|s[3:0]);
end
else
if(n==2)
begin:n2
    assign o = i[0] || i[1] && !s[0] || i[2] && (~|s[1:0]) || i[3] && (~|s[2:0]);
end
else
if(n==1)
begin:n1
    assign o = i[0] || i[1] && !s[0];
end
else
if(n==0)
begin:n0
    assign o = i;
end
endgenerate
endmodule // gs232c_selbit_first_masked_included
