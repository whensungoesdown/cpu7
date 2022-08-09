module lru_unit
#(
    parameter LRU_BITS = 6,
    parameter WAY_N = 4
)
(
    input  [WAY_N-1:0]      new_way,            //the new way. 2/4 bit.
    input  [WAY_N-1:0]      way_lock,           //just ignore for now. for cache lock. 
                                                //set this to all 1's or 0's
                                                //if need this, should store this info with tag.
    input                   new_wen,            //lru wen
    input                   new_clr,            //just ignore for now. for cache invalidate etc.
                                                //set to 0 @beginning or maybe set 1 for the whole time.
    output [LRU_BITS-1:0]   new_lru,            //lru ram wdata
    output [LRU_BITS-1:0]   new_lru_bit_mask,   //lru ram write mask.
    // lru replace select way
    // this part is not affect by the part above.
    input  [LRU_BITS-1:0]   repl_lru,           //input  lru info
    output [WAY_N   -1:0]   repl_way            //output lru select way
);


wire [LRU_BITS-1:0] lru_wdata_tmp;
wire [LRU_BITS-1:0] lru_wen_tmp;
wire [LRU_BITS-1:0] lru_lock_mask;
wire [LRU_BITS-1:0] lru_lock_mask_tmp;


assign new_lru          = lru_wdata_tmp ^ {LRU_BITS{new_clr}}; // ???
assign new_lru_bit_mask = lru_wen_tmp & ~lru_lock_mask & {LRU_BITS{new_wen}};

generate
if (WAY_N == 4)
begin: u_lru_way_4
    assign lru_wdata_tmp  = {{3{new_way[0]}},{2{new_way[1]}},new_way[2]};
    assign lru_wen_tmp     = {6{new_way[0]}} & 6'b111000 |
                             {6{new_way[1]}} & 6'b100110 |
                             {6{new_way[2]}} & 6'b010101 |
                             {6{new_way[3]}} & 6'b001011;
    assign lru_lock_mask_tmp     = {6{way_lock[0]}} & 6'b111000 |
                                   {6{way_lock[1]}} & 6'b100110 |
                                   {6{way_lock[2]}} & 6'b010101 |
                                   {6{way_lock[3]}} & 6'b001011;
    
    assign lru_lock_mask = ((&way_lock)||new_clr) ? 6'b000000 : lru_lock_mask_tmp;
    
    //replace way select
    
    assign repl_way[0] = !repl_lru[5] && !repl_lru[4] && !repl_lru[3];
    assign repl_way[1] =  repl_lru[5] && !repl_lru[2] && !repl_lru[1];
    assign repl_way[2] =  repl_lru[4] &&  repl_lru[2] && !repl_lru[0];
    assign repl_way[3] = !(!repl_lru[5] && !repl_lru[4] && !repl_lru[3] ||
                            repl_lru[5] && !repl_lru[2] && !repl_lru[1] ||
                            repl_lru[4] &&  repl_lru[2] && !repl_lru[0] );

end
else
begin: u_lru_way_other
    assign lru_wdata_tmp        = new_way[0];
    assign lru_wen_tmp          = |new_way;
    assign lru_lock_mask_tmp    = |way_lock;
    assign lru_lock_mask        = ((&way_lock)||new_clr) ? 1'b0 : lru_lock_mask_tmp;
    
    //replace way select
    assign repl_way[0] = !repl_lru[0];
    assign repl_way[1] =  repl_lru[0];
end
endgenerate


endmodule
