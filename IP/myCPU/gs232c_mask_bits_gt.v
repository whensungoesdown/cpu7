module gs232c_mask_bits_gt#(
    parameter n = 4 
)(
    input  wire [n - 1:0] i,
    input  wire [n - 1:0] s,
    output wire [n - 1:0] o 
);
    assign o[0] = i[0];
generate
if(n>=2) begin:n2
    assign o[1] = i[1] && !s[0];
end
if(n>=3) begin:more
    genvar j;
    for(j=2;j<n;j=j+1) begin:iter
        assign o[j] = i[j] && (~|s[j-1:0]);
    end
end
endgenerate
endmodule // gs232c_mask_bits_gt
