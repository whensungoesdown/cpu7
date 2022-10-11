module gs232c_decoder_n_m#(
    parameter n = 3 
)(
    input  wire [n        - 1:0] i,                      
    output wire [(1 << n) - 1:0] o // unconnected, at bit
);
genvar j;
generate
for(j=0;j<(1<<n);j=j+1)
begin:iter
    assign o[j] = i == j;
end
endgenerate
endmodule // gs232c_decoder_n_m
