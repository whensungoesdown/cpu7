module gs232c_enc_first_n_m#(
    parameter n = 2 
)(
    input  wire [(1 << n) - 1:0] i,
    output wire [n        - 1:0] o 
);
generate
if(n==3)
begin:n3
    assign o[2] = ~|i[3:0];
    assign o[1] = ((|i[3:2]) || (~|i[5:4])) && (~|i[1:0]);
    assign o[0] = (|i[3:0])?(i[1] || !i[2]) && !i[0]:(i[5] || !i[6]) && !i[4];
end
else
if(n==2)
begin:n2
    assign o[0] = (i[1] || !i[2]) && !i[0];
    assign o[1] = ~|i[1:0];
end
else
if(n==1)
begin:n1
    assign o[0] = !i[0];
end
endgenerate
endmodule // gs232c_enc_first_n_m
