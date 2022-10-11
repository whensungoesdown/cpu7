module gs232c_sel_first_field#(
    parameter n = 2 ,
    parameter w = 32 
)(
    input  wire [(w << n) - 1:0] i,                      
    input  wire [(1 << n) - 1:0] s,                      
    output wire [w        - 1:0] o // unconnected, at bit
);
generate
if(n==2)
begin:n2
    assign o = i[4*w-1:3*w] & {w{~|s[2:0]}}
             | i[3*w-1:2*w] & {w{s[2] && (~|s[1:0])}}
             | i[2*w-1:  w] & {w{s[1] && !s[0]}}
             | i[  w-1:  0] & {w{s[0]}};
end
else
if(n==1)
begin:n1
    assign o = s[0] ? i[2*w-1:w] : i[w-1:0];
end
else
if(n==0)
begin:n0
    assign o = i;
end
endgenerate
endmodule // gs232c_sel_first_field
