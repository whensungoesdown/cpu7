module gs232c_check_pc(
    // same:next is same with target
    output wire        same  ,
    // same_b:next_hi is same with pc_hi-1
    input  wire        same_b,
    // same_c:next_hi is same with pc_hi+1
    input  wire        same_c,
    // same_h:next_hi is same with pc_hi
    input  wire        same_h,
    input  wire [25:0] next  ,
    input  wire [25:0] base  ,
    input  wire [25:0] offs  ,
    output wire        carry ,
    output wire [25:0] target 
);
wire [25:0] c ;
wire [25:0] s ;
wire [26:0] lo;
assign same   = (c[25] ^ offs[25] ? offs[25] ? same_b : same_c : same_h) && s[0] &&  &(s[25:1] ^ c[24:0]);
assign carry  = lo[26];
assign target = lo[25:0];
assign c      = base & offs | base & ~next | offs & ~next;
assign s      = base ^ offs ^ ~next;
assign lo     = {1'b0,base} + {1'b0,offs};
endmodule // gs232c_check_pc
