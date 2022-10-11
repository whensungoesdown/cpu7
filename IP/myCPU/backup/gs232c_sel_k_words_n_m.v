module gs232c_sel_k_words_n_m#(
    parameter n        = 4   ,
    parameter k        = 4   ,
    parameter w        = 32  ,
    parameter circular = 1'b0 
)(
    input  wire [(w << n) - 1:0] i,                      
    input  wire [n        - 1:0] s,                      
    output wire [w * k    - 1:0] o // unconnected, at bit
);
generate
if(n==4)
begin:n4
    wire [k*w-w-1:0]tail;
    if(circular)
    begin:c1
        assign tail = i[k*w-w-1:0];
    end
    else
    begin:c0
        assign tail = {k*w-w{1'b0}};
    end
    wire [w*k+7*w-1:0]lv1 = s[3] ? {tail,i[16*w-1:8*w]} : i[w*k+7*w-1:0];
    wire [w*k+3*w-1:0]lv2 = s[2] ? lv1[w*k+7*w-1:4*w] : lv1[w*k+3*w-1:0];
    wire [w*k+  w-1:0]lv3 = s[1] ? lv2[w*k+3*w-1:2*w] : lv2[w*k+  w-1:0];
    assign o = s[0] ? lv3[w*k+w-1:w] : lv3[w*k-1:0];
end
else
if(n==3)
begin:n3
    wire [k*w-w-1:0]tail;
    if(circular)
    begin:c1
        assign tail = i[k*w-w-1:0];
    end
    else
    begin:c0
        assign tail = {k*w-w{1'b0}};
    end
    wire [w*k+3*w-1:0]lv1 = s[2] ? {tail,i[8*w-1:4*w]} : i[w*k+3*w-1:0];
    wire [w*k+  w-1:0]lv2 = s[1] ? lv1[w*k+3*w-1:2*w] : lv1[w*k+  w-1:0];
    assign o = s[0] ? lv2[w*k+w-1:w] : lv2[w*k-1:0];
end
else
if(n==2)
begin:n2
    if(circular)
    begin:c1
        if(k==1)
        begin:k1
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & i[  w+:w*k]
                     | {w*k{s==2'b10}} & i[2*w+:w*k]
                     | {w*k{s==2'b11}} & i[3*w+:w*k];
        end
        else
        if(k==2)
        begin:k2
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & i[  w+:w*k]
                     | {w*k{s==2'b10}} & i[2*w+:w*k]
                     | {w*k{s==2'b11}} & {i[0+:w],i[(w<<n)-1:3*w]};
        end
        else
        if(k==3)
        begin:k3
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & i[  w+:w*k]
                     | {w*k{s==2'b10}} & {i[0+:  w],i[(w<<n)-1:2*w]}
                     | {w*k{s==2'b11}} & {i[0+:2*w],i[(w<<n)-1:3*w]};
        end
        else
        if(k==4)
        begin:k4
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & {i[0+:  w],i[(w<<n)-1:  w]}
                     | {w*k{s==2'b10}} & {i[0+:2*w],i[(w<<n)-1:2*w]}
                     | {w*k{s==2'b11}} & {i[0+:3*w],i[(w<<n)-1:3*w]};
        end
    end
    else
    begin:c0
        if(k==1)
        begin:k1
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & i[  w+:w*k]
                     | {w*k{s==2'b10}} & i[2*w+:w*k]
                     | {w*k{s==2'b11}} & i[3*w+:w*k];
        end
        else
        if(k==2)
        begin:k2
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & i[  w+:w*k]
                     | {w*k{s==2'b10}} & i[2*w+:w*k]
                     | {w*k{s==2'b11}} & {{  w{1'b0}},i[(w<<n)-1:3*w]};
        end
        else
        if(k==3)
        begin:k3
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & i[  w+:w*k]
                     | {w*k{s==2'b10}} & {{  w{1'b0}},i[(w<<n)-1:2*w]}
                     | {w*k{s==2'b11}} & {{2*w{1'b0}},i[(w<<n)-1:3*w]};
        end
        else
        if(k==4)
        begin:k4
            assign o = {w*k{s==2'b00}} & i[  0+:w*k]
                     | {w*k{s==2'b01}} & {{  w{1'b0}},i[(w<<n)-1:  w]}
                     | {w*k{s==2'b10}} & {{2*w{1'b0}},i[(w<<n)-1:2*w]}
                     | {w*k{s==2'b11}} & {{3*w{1'b0}},i[(w<<n)-1:3*w]};
        end
    end
end
else
if(n==1)
begin:n1
    if(circular)
    begin:c1
        assign o = s[0] ? {i[w-1:0],i[k*w-1:w]} : i[k*w-1:0];
    end
    else
    begin:c0
        assign o = s[0] ? {{w{1'b0}},i[k*w-1:w]} : i[k*w-1:0];
    end
end
endgenerate
endmodule // gs232c_sel_k_words_n_m
