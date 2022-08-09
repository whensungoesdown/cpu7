`include "common.vh"
`include "decoded.vh"

`ifdef LA64

// ALU module
module alu(
  input [`GRLEN-1:0] a,
  input [`GRLEN-1:0] b,
  input double_word,
  input [`LSOC1K_ALU_CODE_BIT-1:0] alu_op,
  input [`GRLEN-1:0] c,
  output [`GRLEN-1:0] Result
);

  // alu_op decoder
  wire alu_lu32i      = alu_op == `LSOC1K_ALU_LU32I;
  wire alu_lu12i      = alu_op == `LSOC1K_ALU_LU12I;
  wire alu_lu52i      = alu_op == `LSOC1K_ALU_LU52I;
  wire alu_add        = alu_op == `LSOC1K_ALU_ADD  ;
  wire alu_pcalau     = alu_op == `LSOC1K_ALU_PCALAU;
  wire alu_sub        = alu_op == `LSOC1K_ALU_SUB  ;
  wire alu_and        = alu_op == `LSOC1K_ALU_AND  ;
  wire alu_andn       = alu_op == `LSOC1K_ALU_ANDN ;
  wire alu_or         = alu_op == `LSOC1K_ALU_OR   ;
  wire alu_orn        = alu_op == `LSOC1K_ALU_ORN  ;
  wire alu_xor        = alu_op == `LSOC1K_ALU_XOR  ;
  wire alu_nor        = alu_op == `LSOC1K_ALU_NOR  ;
  wire alu_slt        = alu_op == `LSOC1K_ALU_SLT  ;
  wire alu_sltu       = alu_op == `LSOC1K_ALU_SLTU ;
  wire alu_sll        = alu_op == `LSOC1K_ALU_SLL  ;
  wire alu_srl        = alu_op == `LSOC1K_ALU_SRL  ;
  wire alu_sra        = alu_op == `LSOC1K_ALU_SRA  ;
  wire alu_align      = alu_op == `LSOC1K_ALU_ALIGN;
  wire alu_rot        = alu_op == `LSOC1K_ALU_ROT  ;
  wire alu_lead_count = alu_op == `LSOC1K_ALU_COUNT_L;
  wire alu_tail_count = alu_op == `LSOC1K_ALU_COUNT_T;
  wire alu_bitswap    = alu_op == `LSOC1K_ALU_BITSWAP;
  wire alu_bitrev     = alu_op == `LSOC1K_ALU_BITREV;
  wire alu_ext        = alu_op == `LSOC1K_ALU_EXT  ;
  wire alu_seb        = alu_op == `LSOC1K_ALU_SEB  ;
  wire alu_seh        = alu_op == `LSOC1K_ALU_SEH  ;
  wire alu_wsbh       = alu_op == `LSOC1K_ALU_WSBH ;
  wire alu_selnez     = alu_op == `LSOC1K_ALU_SELNEZ;
  wire alu_seleqz     = alu_op == `LSOC1K_ALU_SELEQZ;
  wire alu_lsa        = alu_op == `LSOC1K_ALU_LSA || alu_op == `LSOC1K_ALU_LSAU;
  wire alu_lsau       = alu_op == `LSOC1K_ALU_LSAU ;
  wire alu_ins        = alu_op == `LSOC1K_ALU_INS  ;
  wire alu_dshd       = alu_op == `LSOC1K_ALU_DSHD ;
  wire alu_revb       = alu_op == `LSOC1K_ALU_REVB ;

  // lui res
  wire [63:0] lu32i_res = {b[63:32],a[31:0]};
  wire [63:0] lu52i_res = {b[63:52],a[51:0]};
  wire [63:0] lu12i_res = b;

  // invert b for subtractions (sub & slt)
  wire invb = alu_sub | alu_slt | alu_sltu;
  // select addend according to invb
  wire [63:0] addend = invb ? (~b) : b;

  // carryout flag for addition
  wire cf;
  // result for addition and subtraction
  wire [63:0] add_sub_res_d;
  wire [63:0] add_sub_res_w;
  wire [63:0] add_sub_res_wu;
  wire [63:0] add_sub_res;
  // for lsa
  wire [2:0] offset = {1'd0,c[1:0]} + 3'd1;
  wire [63:0] a_processed = alu_lsa ? (a << offset) : a;
  // do addition (invb as carryin in subtraction)
  assign {cf, add_sub_res_d} = a_processed + addend + {63'd0,invb};
  assign add_sub_res_wu = {32'b0,add_sub_res_d[31:0]};
  assign add_sub_res_w = {{32{add_sub_res_d[31]}},add_sub_res_d[31:0]};
  assign add_sub_res = double_word ? add_sub_res_d : add_sub_res_w;
  // calculate overflow flag
  wire of = a[63] ^ addend[63] ^ cf ^ add_sub_res_d[63];
  // do and operation
  wire [63:0] and_res = a & b;
  // do andn operation
  wire [63:0] andn_res = a & (~b);
  // do or operation
  wire [63:0] or_res = a | b;
  // do or operation
  wire [63:0] orn_res = a | (~b);
  // do xor operation
  wire [63:0] xor_res = a ^ b;
  // do nor operation
  wire [63:0] nor_res = ~or_res;
  // set slt/sltu result according to subtraction result
  wire [63:0] slt_res = (add_sub_res_d[63] ^ of) ? 1 : 0;
  wire [63:0] sltu_res = (!cf) ? 1 : 0;
  // do sll operation
  wire [31:0] sll_w_temp = a[31:0] << b[4:0];
  wire [63:0] sll_w_res = {{32{sll_w_temp[31]}},sll_w_temp};
  wire [63:0] sll_d_res = a << b[5:0];
  wire [63:0] sll_res = double_word ? sll_d_res : sll_w_res;
  // do srl&sra operation
  wire [95:0] sr_w_temp = {{64{alu_sra&a[31]}}, a[31:0]} >> b[4:0];
  wire [63:0] sr_w_res = {{32{sr_w_temp[31]}},sr_w_temp[31:0]};
  wire [127:0] sr_d_temp = {{64{alu_sra&a[63]}}, a} >> b[5:0];
  wire [63:0] sr_d_res = sr_d_temp[63:0];
  wire [63:0] sr_res = double_word ? sr_d_res : sr_w_res;
  // do align operation
  wire [4:0] align_b_w ={5{c[1:0] == 2'd0}} & 5'd0  |
                        {5{c[1:0] == 2'd1}} & 5'd8  |
                        {5{c[1:0] == 2'd2}} & 5'd16 |
                        {5{c[1:0] == 2'd3}} & 5'd24 ;

  wire [5:0] align_a_w ={6{c[1:0] == 2'd0}} & 6'd32 |
                        {6{c[1:0] == 2'd1}} & 6'd24 |
                        {6{c[1:0] == 2'd2}} & 6'd16 |
                        {6{c[1:0] == 2'd3}} & 6'd8  ;

  wire [5:0] align_b_d ={6{c[2:0] == 3'd0}} & 6'd0  |
                        {6{c[2:0] == 3'd1}} & 6'd8  |
                        {6{c[2:0] == 3'd2}} & 6'd16 |
                        {6{c[2:0] == 3'd3}} & 6'd24 |
                        {6{c[2:0] == 3'd4}} & 6'd32 |
                        {6{c[2:0] == 3'd5}} & 6'd40 |
                        {6{c[2:0] == 3'd6}} & 6'd48 |
                        {6{c[2:0] == 3'd7}} & 6'd56 ;

  wire [6:0] align_a_d ={7{c[2:0] == 3'd0}} & 7'd64 |
                        {7{c[2:0] == 3'd1}} & 7'd56 |
                        {7{c[2:0] == 3'd2}} & 7'd48 |
                        {7{c[2:0] == 3'd3}} & 7'd40 |
                        {7{c[2:0] == 3'd4}} & 7'd32 |
                        {7{c[2:0] == 3'd5}} & 7'd24 |
                        {7{c[2:0] == 3'd6}} & 7'd16 |
                        {7{c[2:0] == 3'd7}} & 7'd8  ;
  wire [31:0] align_a_w_res = a[31:0] >> align_a_w;
  wire [31:0] align_b_w_res = b[31:0] << align_b_w;
  wire [31:0] align_w_res = align_a_w_res | align_b_w_res;
  wire [63:0] align_a_d_res = a >> align_a_d;
  wire [63:0] align_b_d_res = b << align_b_d;
  wire [63:0] align_d_res = align_a_d_res | align_b_d_res;
  wire [63:0] align_res = double_word ? align_d_res : {{32{align_w_res[31]}},align_w_res};
  // rotate
  wire [63:0] rot_cover  = a;
  wire [5:0]  rot_num = alu_ext ? c[5:0] : b[5:0];
  wire [31:0] rotate_w_res= {32{rot_num[4:0] ==  5'd0}} & {                  a[31: 0]} 
                          | {32{rot_num[4:0] ==  5'd1}} & {rot_cover[ 0: 0], a[31: 1]} 
                          | {32{rot_num[4:0] ==  5'd2}} & {rot_cover[ 1: 0], a[31: 2]} 
                          | {32{rot_num[4:0] ==  5'd3}} & {rot_cover[ 2: 0], a[31: 3]} 
                          | {32{rot_num[4:0] ==  5'd4}} & {rot_cover[ 3: 0], a[31: 4]} 
                          | {32{rot_num[4:0] ==  5'd5}} & {rot_cover[ 4: 0], a[31: 5]} 
                          | {32{rot_num[4:0] ==  5'd6}} & {rot_cover[ 5: 0], a[31: 6]} 
                          | {32{rot_num[4:0] ==  5'd7}} & {rot_cover[ 6: 0], a[31: 7]} 
                          | {32{rot_num[4:0] ==  5'd8}} & {rot_cover[ 7: 0], a[31: 8]} 
                          | {32{rot_num[4:0] ==  5'd9}} & {rot_cover[ 8: 0], a[31: 9]} 
                          | {32{rot_num[4:0] == 5'd10}} & {rot_cover[ 9: 0], a[31:10]} 
                          | {32{rot_num[4:0] == 5'd11}} & {rot_cover[10: 0], a[31:11]} 
                          | {32{rot_num[4:0] == 5'd12}} & {rot_cover[11: 0], a[31:12]} 
                          | {32{rot_num[4:0] == 5'd13}} & {rot_cover[12: 0], a[31:13]} 
                          | {32{rot_num[4:0] == 5'd14}} & {rot_cover[13: 0], a[31:14]} 
                          | {32{rot_num[4:0] == 5'd15}} & {rot_cover[14: 0], a[31:15]} 
                          | {32{rot_num[4:0] == 5'd16}} & {rot_cover[15: 0], a[31:16]} 
                          | {32{rot_num[4:0] == 5'd17}} & {rot_cover[16: 0], a[31:17]} 
                          | {32{rot_num[4:0] == 5'd18}} & {rot_cover[17: 0], a[31:18]} 
                          | {32{rot_num[4:0] == 5'd19}} & {rot_cover[18: 0], a[31:19]} 
                          | {32{rot_num[4:0] == 5'd20}} & {rot_cover[19: 0], a[31:20]} 
                          | {32{rot_num[4:0] == 5'd21}} & {rot_cover[20: 0], a[31:21]} 
                          | {32{rot_num[4:0] == 5'd22}} & {rot_cover[21: 0], a[31:22]} 
                          | {32{rot_num[4:0] == 5'd23}} & {rot_cover[22: 0], a[31:23]} 
                          | {32{rot_num[4:0] == 5'd24}} & {rot_cover[23: 0], a[31:24]} 
                          | {32{rot_num[4:0] == 5'd25}} & {rot_cover[24: 0], a[31:25]} 
                          | {32{rot_num[4:0] == 5'd26}} & {rot_cover[25: 0], a[31:26]} 
                          | {32{rot_num[4:0] == 5'd27}} & {rot_cover[26: 0], a[31:27]} 
                          | {32{rot_num[4:0] == 5'd28}} & {rot_cover[27: 0], a[31:28]} 
                          | {32{rot_num[4:0] == 5'd29}} & {rot_cover[28: 0], a[31:29]} 
                          | {32{rot_num[4:0] == 5'd30}} & {rot_cover[29: 0], a[31:30]} 
                          | {32{rot_num[4:0] == 5'd31}} & {rot_cover[30: 0], a[31:31]} ;
  
  wire [63:0] rotate_d_res= {64{rot_num ==  6'd0}} & {                  a[63: 0]} 
                          | {64{rot_num ==  6'd1}} & {rot_cover[ 0: 0], a[63: 1]} 
                          | {64{rot_num ==  6'd2}} & {rot_cover[ 1: 0], a[63: 2]} 
                          | {64{rot_num ==  6'd3}} & {rot_cover[ 2: 0], a[63: 3]} 
                          | {64{rot_num ==  6'd4}} & {rot_cover[ 3: 0], a[63: 4]} 
                          | {64{rot_num ==  6'd5}} & {rot_cover[ 4: 0], a[63: 5]} 
                          | {64{rot_num ==  6'd6}} & {rot_cover[ 5: 0], a[63: 6]} 
                          | {64{rot_num ==  6'd7}} & {rot_cover[ 6: 0], a[63: 7]} 
                          | {64{rot_num ==  6'd8}} & {rot_cover[ 7: 0], a[63: 8]} 
                          | {64{rot_num ==  6'd9}} & {rot_cover[ 8: 0], a[63: 9]} 
                          | {64{rot_num == 6'd10}} & {rot_cover[ 9: 0], a[63:10]} 
                          | {64{rot_num == 6'd11}} & {rot_cover[10: 0], a[63:11]} 
                          | {64{rot_num == 6'd12}} & {rot_cover[11: 0], a[63:12]} 
                          | {64{rot_num == 6'd13}} & {rot_cover[12: 0], a[63:13]} 
                          | {64{rot_num == 6'd14}} & {rot_cover[13: 0], a[63:14]} 
                          | {64{rot_num == 6'd15}} & {rot_cover[14: 0], a[63:15]} 
                          | {64{rot_num == 6'd16}} & {rot_cover[15: 0], a[63:16]} 
                          | {64{rot_num == 6'd17}} & {rot_cover[16: 0], a[63:17]} 
                          | {64{rot_num == 6'd18}} & {rot_cover[17: 0], a[63:18]} 
                          | {64{rot_num == 6'd19}} & {rot_cover[18: 0], a[63:19]} 
                          | {64{rot_num == 6'd20}} & {rot_cover[19: 0], a[63:20]} 
                          | {64{rot_num == 6'd21}} & {rot_cover[20: 0], a[63:21]} 
                          | {64{rot_num == 6'd22}} & {rot_cover[21: 0], a[63:22]} 
                          | {64{rot_num == 6'd23}} & {rot_cover[22: 0], a[63:23]} 
                          | {64{rot_num == 6'd24}} & {rot_cover[23: 0], a[63:24]} 
                          | {64{rot_num == 6'd25}} & {rot_cover[24: 0], a[63:25]} 
                          | {64{rot_num == 6'd26}} & {rot_cover[25: 0], a[63:26]} 
                          | {64{rot_num == 6'd27}} & {rot_cover[26: 0], a[63:27]} 
                          | {64{rot_num == 6'd28}} & {rot_cover[27: 0], a[63:28]} 
                          | {64{rot_num == 6'd29}} & {rot_cover[28: 0], a[63:29]} 
                          | {64{rot_num == 6'd30}} & {rot_cover[29: 0], a[63:30]} 
                          | {64{rot_num == 6'd31}} & {rot_cover[30: 0], a[63:31]} 
                          | {64{rot_num == 6'd32}} & {rot_cover[31: 0], a[63:32]} 
                          | {64{rot_num == 6'd33}} & {rot_cover[32: 0], a[63:33]} 
                          | {64{rot_num == 6'd34}} & {rot_cover[33: 0], a[63:34]} 
                          | {64{rot_num == 6'd35}} & {rot_cover[34: 0], a[63:35]} 
                          | {64{rot_num == 6'd36}} & {rot_cover[35: 0], a[63:36]} 
                          | {64{rot_num == 6'd37}} & {rot_cover[36: 0], a[63:37]} 
                          | {64{rot_num == 6'd38}} & {rot_cover[37: 0], a[63:38]} 
                          | {64{rot_num == 6'd39}} & {rot_cover[38: 0], a[63:39]} 
                          | {64{rot_num == 6'd40}} & {rot_cover[39: 0], a[63:40]} 
                          | {64{rot_num == 6'd41}} & {rot_cover[40: 0], a[63:41]} 
                          | {64{rot_num == 6'd42}} & {rot_cover[41: 0], a[63:42]} 
                          | {64{rot_num == 6'd43}} & {rot_cover[42: 0], a[63:43]} 
                          | {64{rot_num == 6'd44}} & {rot_cover[43: 0], a[63:44]} 
                          | {64{rot_num == 6'd45}} & {rot_cover[44: 0], a[63:45]} 
                          | {64{rot_num == 6'd46}} & {rot_cover[45: 0], a[63:46]} 
                          | {64{rot_num == 6'd47}} & {rot_cover[46: 0], a[63:47]} 
                          | {64{rot_num == 6'd48}} & {rot_cover[47: 0], a[63:48]} 
                          | {64{rot_num == 6'd49}} & {rot_cover[48: 0], a[63:49]} 
                          | {64{rot_num == 6'd50}} & {rot_cover[49: 0], a[63:50]} 
                          | {64{rot_num == 6'd51}} & {rot_cover[50: 0], a[63:51]} 
                          | {64{rot_num == 6'd52}} & {rot_cover[51: 0], a[63:52]} 
                          | {64{rot_num == 6'd53}} & {rot_cover[52: 0], a[63:53]} 
                          | {64{rot_num == 6'd54}} & {rot_cover[53: 0], a[63:54]} 
                          | {64{rot_num == 6'd55}} & {rot_cover[54: 0], a[63:55]} 
                          | {64{rot_num == 6'd56}} & {rot_cover[55: 0], a[63:56]} 
                          | {64{rot_num == 6'd57}} & {rot_cover[56: 0], a[63:57]} 
                          | {64{rot_num == 6'd58}} & {rot_cover[57: 0], a[63:58]} 
                          | {64{rot_num == 6'd59}} & {rot_cover[58: 0], a[63:59]} 
                          | {64{rot_num == 6'd60}} & {rot_cover[59: 0], a[63:60]} 
                          | {64{rot_num == 6'd61}} & {rot_cover[60: 0], a[63:61]} 
                          | {64{rot_num == 6'd62}} & {rot_cover[61: 0], a[63:62]} 
                          | {64{rot_num == 6'd63}} & {rot_cover[62: 0], a[63:63]};

  wire [63:0] rotate_res = double_word ? rotate_d_res : {{32{rotate_w_res[31]}},rotate_w_res};

// ext
  wire [63:0] zero_one_w = {32'd0,32'hffffffff};
  wire [4:0] ext_shift_w = c[10:6] + 5'd1 + ~c[4:0] + 5'd1;
  wire [63:0] zero_one_ext_processed_w = zero_one_w << ext_shift_w;
  wire [31:0] zero_one_part_w = zero_one_ext_processed_w[63:32];
  wire [31:0] ext_res_w = zero_one_part_w & rotate_w_res;
  
  wire [127:0] zero_one_d = {64'd0,64'hffffffffffffffff};
  wire [5:0] ext_shift_d = c[11:6] + 6'd1 + ~c[5:0] + 6'd1;
  wire [127:0] zero_one_ext_processed_d = zero_one_d << ext_shift_d;
  wire [63:0] zero_one_part_d = zero_one_ext_processed_d[127:64];
  wire [63:0] ext_res_d = zero_one_part_d & rotate_d_res;

  wire [63:0] ext_res = double_word ? ext_res_d : {{32{ext_res_w[31]}},ext_res_w};
// insert 
  wire [63:0] zero_one_ins_processed_w = zero_one_w << c[4:0];
  wire [31:0] ins_right_part_w = b[31:0] & zero_one_ins_processed_w[63:32];

  wire [63:0] one_zero_w = {32'hffffffff,32'd0};
  wire [63:0] one_zero_ins_processed_w = one_zero_w << (c[10:6] + 5'd1);
  wire [31:0] ins_left_part_w  = b[31:0] & one_zero_ins_processed_w[63:32];

  wire [31:0] ins_middle_part_w= (a[31:0] << c[4:0]) & ~one_zero_ins_processed_w[63:32];

  wire [31:0] ins_res_w_temp = ins_left_part_w | ins_middle_part_w | ins_right_part_w;
  wire [63:0] ins_res_w = {{32{ins_res_w_temp[31]}},ins_res_w_temp};


  wire [127:0] zero_one_ins_processed_d = zero_one_d << c[5:0];
  wire [63:0] ins_right_part_d = b & zero_one_ins_processed_d[127:64];

  wire [127:0] one_zero_d = {64'hffffffffffffffff,64'd0};
  wire [127:0] one_zero_ins_processed_d = one_zero_d << (c[12:6] + 6'd1);
  wire [63:0] ins_left_part_d  = b & one_zero_ins_processed_d[127:64];

  wire [63:0] ins_middle_part_d= (a << c[5:0]) & ~one_zero_ins_processed_d[127:64];

  wire [63:0] ins_res_d = ins_left_part_d | ins_middle_part_d | ins_right_part_d;

  wire [63:0] ins_res = double_word ? ins_res_d : ins_res_w;

//count
wire [ 5:0] count_lead_w_res;
wire [ 5:0] count_tail_w_res;
wire [ 6:0] count_lead_d_res;
wire        count_one_zero = c[0];
wire [63:0] bitreverse = { a[ 0], a[ 1], a[ 2], a[ 3], a[ 4], a[ 5], a[ 6], a[ 7],
                           a[ 8], a[ 9], a[10], a[11], a[12], a[13], a[14], a[15],
                           a[16], a[17], a[18], a[19], a[20], a[21], a[22], a[23],
                           a[24], a[25], a[26], a[27], a[28], a[29], a[30], a[31],
                           a[32], a[33], a[34], a[35], a[36], a[37], a[38], a[39],
                           a[40], a[41], a[42], a[43], a[44], a[45], a[46], a[47],
                           a[48], a[49], a[50], a[51], a[52], a[53], a[54], a[55],
                           a[56], a[57], a[58], a[59], a[60], a[61], a[62], a[63]};

wire [63:0] bitrev_res = double_word ? bitreverse : {{32{bitreverse[63]}},bitreverse[63:32]};

wire [63:0] counter_input = alu_tail_count ? bitreverse : a;
leading_counter_64 LSOC1k_leading_counter_64 (counter_input, count_one_zero, count_lead_d_res, count_tail_w_res,count_lead_w_res);
wire [63:0] count_lead_res = double_word ? {57'd0,count_lead_d_res} : {58'd0,count_lead_w_res};
// wire [63:0] count_tail_res = double_word ? {57'd0,count_lead_d_res} : {58'd0,count_tail_w_res};
wire [63:0] count_tail_res = double_word ? {57'd0,count_lead_d_res} : {58'd0,count_tail_w_res};
//bit swap
wire [63:0] bitswap   = { a[56], a[57], a[58], a[59], a[60], a[61], a[62], a[63],   
                          a[48], a[49], a[50], a[51], a[52], a[53], a[54], a[55],   
                          a[40], a[41], a[42], a[43], a[44], a[45], a[46], a[47],   
                          a[32], a[33], a[34], a[35], a[36], a[37], a[38], a[39],
                          a[24], a[25], a[26], a[27], a[28], a[29], a[30], a[31],   
                          a[16], a[17], a[18], a[19], a[20], a[21], a[22], a[23],   
                          a[ 8], a[ 9], a[10], a[11], a[12], a[13], a[14], a[15],   
                          a[ 0], a[ 1], a[ 2], a[ 3], a[ 4], a[ 5], a[ 6], a[ 7] };
wire [63:0] bitswap_res = double_word ? bitswap : {{32{bitswap[31]}},bitswap[31:0]};
//word swap
wire [63:0] wordswap_within_halfwords = {a[55:48],a[63:56],a[39:32],a[47:40],a[23:16],a[31:24],a[7:0],a[15:8]};
wire [63:0] wsbh_res = double_word ? wordswap_within_halfwords : {{32{wordswap_within_halfwords[31]}},wordswap_within_halfwords[31:0]};
wire [63:0] dshd_res = double_word ? {a[15:0],a[31:16],a[47:32],a[63:48]} : {a[47:32],a[63:48],a[15:0],a[31:16]};
//revb
wire [63:0] revb_2w  = {a[39:32],a[47:40],a[55:48],a[63:56],a[7:0],a[15:8],a[23:16],a[31:24]};
wire [63:0] revb_d   = {a[7:0],a[15:8],a[23:16],a[31:24],a[39:32],a[47:40],a[55:48],a[63:56]};
wire [63:0] revb_res = double_word ? revb_d : revb_2w;
//sign-extend
wire [63:0] seb_res = {{56{a[ 7]}},a[7:0]};
wire [63:0] seh_res = {{48{a[15]}},a[15:0]};
//select
wire [63:0] seleqz_res = (b != 64'd0) ? 64'd0 : a;
wire [63:0] selnez_res = (b != 64'd0) ? a : 64'd0;
// result muxer
wire [63:0] res =
    {64{alu_lsau}} & add_sub_res_wu |
    {64{alu_lu32i}} & lu32i_res |
    {64{alu_lu12i}} & lu12i_res |
    {64{alu_lu52i}} & lu52i_res |
    {64{alu_and}} & and_res |
    {64{alu_andn}} & andn_res |
    {64{alu_or}} & or_res |
    {64{alu_orn}} & orn_res |
    {64{alu_xor}} & xor_res |
    {64{alu_nor}} & nor_res |
    {64{alu_add || (alu_lsa && !alu_lsau)}} & add_sub_res |
    {64{alu_pcalau}} & add_sub_res & 64'hfffffffffffff000 |
    {64{alu_sub}} & add_sub_res |
    {64{alu_slt}} & slt_res |
    {64{alu_sltu}} & sltu_res |
    {64{alu_sll}} & sll_res |
    {64{alu_srl}} & sr_res |
    {64{alu_sra}} & sr_res |
    {64{alu_align}} & align_res |
    {64{alu_rot}} & rotate_res |
    {64{alu_lead_count}} & count_lead_res |
    {64{alu_tail_count}} & count_tail_res |
    {64{alu_bitswap}} & bitswap_res |
    {64{alu_bitrev}} & bitrev_res |
    {64{alu_revb}} & revb_res |
    {64{alu_ext}} & ext_res |
    {64{alu_ins}} & ins_res |
    {64{alu_seb}} & seb_res |
    {64{alu_seh}} & seh_res |
    {64{alu_wsbh}} & wsbh_res |
    {64{alu_dshd}} & dshd_res |
    {64{alu_seleqz}} & seleqz_res |
    {64{alu_selnez}} & selnez_res ;
  // set zero flag
  wire zf = (res == 0);
  // output results
  assign Result = res;
  
endmodule

module leading_counter_4(
	input  [ 3:0] in_number,
	input         zero_one,
	output [ 2:0] count
);
wire [ 3:0] number = zero_one ? in_number : ~in_number;

assign count = number[3] & number[2] & number[1] & number[0] ? 3'd4 :
				       number[3] & number[2] & number[1]             ? 3'd3 :
				       number[3] & number[2]                         ? 3'd2 :
				       number[3]                                     ? 3'd1 :
															                                 3'd0 ;
endmodule

module leading_counter_8(
	input  [ 7:0] in_number,
	input         zero_one,
	output [ 3:0] count
);
wire [ 2:0] count_high;
wire [ 2:0] count_low;
leading_counter_4 hi (in_number[7:4], zero_one, count_high);
leading_counter_4 lo (in_number[3:0], zero_one, count_low);
assign count = count_high == 3'd4 ? count_high+count_low : {1'd0,count_high};
endmodule

module leading_counter_16(
	input  [15:0] in_number,
	input         zero_one,
	output [ 4:0] count
);
wire [ 3:0] count_high;
wire [ 3:0] count_low;
leading_counter_8 hi (in_number[15:8], zero_one, count_high);
leading_counter_8 lo (in_number[ 7:0], zero_one, count_low);
assign count = count_high == 4'd8 ? count_high+count_low : {1'd0,count_high};
endmodule

module leading_counter_32(
	input  [31:0] in_number,
	input         zero_one,
	output [ 5:0] count
);
wire [ 4:0] count_high;
wire [ 4:0] count_low;
leading_counter_16 hi (in_number[31:16], zero_one, count_high);
leading_counter_16 lo (in_number[15: 0], zero_one, count_low);
assign count = count_high == 5'd16 ? count_high+count_low : {1'd0,count_high};
endmodule

module leading_counter_64(
	input  [63:0] in_number,
	input         zero_one,
	output [ 6:0] count,
	output [ 5:0] count_high,
  output [ 5:0] count_low
);
leading_counter_32 hi (in_number[63:32], zero_one, count_high);
leading_counter_32 lo (in_number[31: 0], zero_one, count_low);
assign count = count_high == 6'd32 ? count_high+count_low : {1'd0,count_high};
endmodule
`elsif LA32
// ALU module
module alu(
  input [`GRLEN-1:0] a,
  input [`GRLEN-1:0] b,
  input double_word,
  input [`LSOC1K_ALU_CODE_BIT-1:0] alu_op,
  input [`GRLEN-1:0] c,
  output [`GRLEN-1:0] Result
);

  // alu_op decoder
  wire alu_lu32i      = alu_op == `LSOC1K_ALU_LU32I;
  wire alu_lu12i      = alu_op == `LSOC1K_ALU_LU12I;
  wire alu_lu52i      = alu_op == `LSOC1K_ALU_LU52I;
  wire alu_add        = alu_op == `LSOC1K_ALU_ADD  ;
  wire alu_pcalau     = alu_op == `LSOC1K_ALU_PCALAU;
  wire alu_sub        = alu_op == `LSOC1K_ALU_SUB  ;
  wire alu_and        = alu_op == `LSOC1K_ALU_AND  ;
  wire alu_andn       = alu_op == `LSOC1K_ALU_ANDN ;
  wire alu_or         = alu_op == `LSOC1K_ALU_OR   ;
  wire alu_orn        = alu_op == `LSOC1K_ALU_ORN  ;
  wire alu_xor        = alu_op == `LSOC1K_ALU_XOR  ;
  wire alu_nor        = alu_op == `LSOC1K_ALU_NOR  ;
  wire alu_slt        = alu_op == `LSOC1K_ALU_SLT  ;
  wire alu_sltu       = alu_op == `LSOC1K_ALU_SLTU ;
  wire alu_sll        = alu_op == `LSOC1K_ALU_SLL  ;
  wire alu_srl        = alu_op == `LSOC1K_ALU_SRL  ;
  wire alu_sra        = alu_op == `LSOC1K_ALU_SRA  ;
  wire alu_align      = alu_op == `LSOC1K_ALU_ALIGN;
  wire alu_rot        = alu_op == `LSOC1K_ALU_ROT  ;
  wire alu_lead_count = alu_op == `LSOC1K_ALU_COUNT_L;
  wire alu_tail_count = alu_op == `LSOC1K_ALU_COUNT_T;
  wire alu_bitswap    = alu_op == `LSOC1K_ALU_BITSWAP;
  wire alu_bitrev     = alu_op == `LSOC1K_ALU_BITREV;
  wire alu_ext        = alu_op == `LSOC1K_ALU_EXT  ;
  wire alu_seb        = alu_op == `LSOC1K_ALU_SEB  ;
  wire alu_seh        = alu_op == `LSOC1K_ALU_SEH  ;
  wire alu_wsbh       = alu_op == `LSOC1K_ALU_WSBH ;
  wire alu_selnez     = alu_op == `LSOC1K_ALU_SELNEZ;
  wire alu_seleqz     = alu_op == `LSOC1K_ALU_SELEQZ;
  wire alu_lsa        = alu_op == `LSOC1K_ALU_LSA || alu_op == `LSOC1K_ALU_LSAU;
  wire alu_lsau       = alu_op == `LSOC1K_ALU_LSAU ;
  wire alu_ins        = alu_op == `LSOC1K_ALU_INS  ;
  wire alu_dshd       = alu_op == `LSOC1K_ALU_DSHD ;
  wire alu_revb       = alu_op == `LSOC1K_ALU_REVB ;

  // lui res
  wire [31:0] lu32i_res = a[31:0];
  // wire [63:0] lu52i_res = {b[63:52],a[51:0]};
  wire [31:0] lu12i_res = b;

  // invert b for subtractions (sub & slt)
  wire invb = alu_sub | alu_slt | alu_sltu;
  // select addend according to invb
  wire [31:0] addend = invb ? (~b) : b;

  // carryout flag for addition
  wire cf;
  // result for addition and subtraction
  wire [31:0] add_sub_res_d;
  wire [31:0] add_sub_res_w;
  wire [31:0] add_sub_res_wu;
  wire [31:0] add_sub_res;
  // for lsa
  wire [2:0] offset = {1'd0,c[1:0]} + 3'd1;
  wire [31:0] a_processed = alu_lsa ? (a << offset) : a;
  // do addition (invb as carryin in subtraction)
  assign {cf, add_sub_res_d} = a_processed + addend + {31'd0,invb};
  assign add_sub_res_wu = add_sub_res_d;
  assign add_sub_res_w = add_sub_res_d;
  assign add_sub_res = add_sub_res_w;
  // calculate overflow flag
  wire of = a[31] ^ addend[31] ^ cf ^ add_sub_res_d[31];
  // do and operation
  wire [31:0] and_res = a & b;
  // do andn operation
  wire [31:0] andn_res = a & (~b);
  // do or operation
  wire [31:0] or_res = a | b;
  // do or operation
  wire [31:0] orn_res = a | (~b);
  // do xor operation
  wire [31:0] xor_res = a ^ b;
  // do nor operation
  wire [31:0] nor_res = ~or_res;
  // set slt/sltu result according to subtraction result
  wire [31:0] slt_res = (add_sub_res_d[31] ^ of) ? 1 : 0;
  wire [31:0] sltu_res = (!cf) ? 1 : 0;
  // do sll operation
  wire [31:0] sll_w_res = a[31:0] << b[4:0];
  wire [31:0] sll_res = sll_w_res;
  // do srl&sra operation
  wire [95:0] sr_w_temp = {{64{alu_sra&a[31]}}, a[31:0]} >> b[4:0];
  wire [31:0] sr_w_res = sr_w_temp[31:0];
  wire [31:0] sr_res = sr_w_res;
  // do align operation
  wire [4:0] align_b_w ={5{c[1:0] == 2'd0}} & 5'd0  |
                        {5{c[1:0] == 2'd1}} & 5'd8  |
                        {5{c[1:0] == 2'd2}} & 5'd16 |
                        {5{c[1:0] == 2'd3}} & 5'd24 ;

  wire [5:0] align_a_w ={6{c[1:0] == 2'd0}} & 6'd32 |
                        {6{c[1:0] == 2'd1}} & 6'd24 |
                        {6{c[1:0] == 2'd2}} & 6'd16 |
                        {6{c[1:0] == 2'd3}} & 6'd8  ;

  wire [31:0] align_a_w_res = a[31:0] >> align_a_w;
  wire [31:0] align_b_w_res = b[31:0] << align_b_w;
  wire [31:0] align_w_res = align_a_w_res | align_b_w_res;
  wire [31:0] align_res = align_w_res;
  // rotate
  wire [31:0] rot_cover  = a;
  wire [5:0]  rot_num = alu_ext ? c[5:0] : b[5:0];
  wire [31:0] rotate_w_res= {32{rot_num[4:0] ==  5'd0}} & {                  a[31: 0]} 
                          | {32{rot_num[4:0] ==  5'd1}} & {rot_cover[ 0: 0], a[31: 1]} 
                          | {32{rot_num[4:0] ==  5'd2}} & {rot_cover[ 1: 0], a[31: 2]} 
                          | {32{rot_num[4:0] ==  5'd3}} & {rot_cover[ 2: 0], a[31: 3]} 
                          | {32{rot_num[4:0] ==  5'd4}} & {rot_cover[ 3: 0], a[31: 4]} 
                          | {32{rot_num[4:0] ==  5'd5}} & {rot_cover[ 4: 0], a[31: 5]} 
                          | {32{rot_num[4:0] ==  5'd6}} & {rot_cover[ 5: 0], a[31: 6]} 
                          | {32{rot_num[4:0] ==  5'd7}} & {rot_cover[ 6: 0], a[31: 7]} 
                          | {32{rot_num[4:0] ==  5'd8}} & {rot_cover[ 7: 0], a[31: 8]} 
                          | {32{rot_num[4:0] ==  5'd9}} & {rot_cover[ 8: 0], a[31: 9]} 
                          | {32{rot_num[4:0] == 5'd10}} & {rot_cover[ 9: 0], a[31:10]} 
                          | {32{rot_num[4:0] == 5'd11}} & {rot_cover[10: 0], a[31:11]} 
                          | {32{rot_num[4:0] == 5'd12}} & {rot_cover[11: 0], a[31:12]} 
                          | {32{rot_num[4:0] == 5'd13}} & {rot_cover[12: 0], a[31:13]} 
                          | {32{rot_num[4:0] == 5'd14}} & {rot_cover[13: 0], a[31:14]} 
                          | {32{rot_num[4:0] == 5'd15}} & {rot_cover[14: 0], a[31:15]} 
                          | {32{rot_num[4:0] == 5'd16}} & {rot_cover[15: 0], a[31:16]} 
                          | {32{rot_num[4:0] == 5'd17}} & {rot_cover[16: 0], a[31:17]} 
                          | {32{rot_num[4:0] == 5'd18}} & {rot_cover[17: 0], a[31:18]} 
                          | {32{rot_num[4:0] == 5'd19}} & {rot_cover[18: 0], a[31:19]} 
                          | {32{rot_num[4:0] == 5'd20}} & {rot_cover[19: 0], a[31:20]} 
                          | {32{rot_num[4:0] == 5'd21}} & {rot_cover[20: 0], a[31:21]} 
                          | {32{rot_num[4:0] == 5'd22}} & {rot_cover[21: 0], a[31:22]} 
                          | {32{rot_num[4:0] == 5'd23}} & {rot_cover[22: 0], a[31:23]} 
                          | {32{rot_num[4:0] == 5'd24}} & {rot_cover[23: 0], a[31:24]} 
                          | {32{rot_num[4:0] == 5'd25}} & {rot_cover[24: 0], a[31:25]} 
                          | {32{rot_num[4:0] == 5'd26}} & {rot_cover[25: 0], a[31:26]} 
                          | {32{rot_num[4:0] == 5'd27}} & {rot_cover[26: 0], a[31:27]} 
                          | {32{rot_num[4:0] == 5'd28}} & {rot_cover[27: 0], a[31:28]} 
                          | {32{rot_num[4:0] == 5'd29}} & {rot_cover[28: 0], a[31:29]} 
                          | {32{rot_num[4:0] == 5'd30}} & {rot_cover[29: 0], a[31:30]} 
                          | {32{rot_num[4:0] == 5'd31}} & {rot_cover[30: 0], a[31:31]} ;
  
  wire [31:0] rotate_res = rotate_w_res;

// ext
  wire [63:0] zero_one_w = {32'd0,32'hffffffff};
  wire [4:0] ext_shift_w = c[10:6] + 5'd1 + ~c[4:0] + 5'd1;
  wire [63:0] zero_one_ext_processed_w = zero_one_w << ext_shift_w;
  wire [31:0] zero_one_part_w = zero_one_ext_processed_w[63:32];
  wire [31:0] ext_res_w = zero_one_part_w & rotate_w_res;

  wire [31:0] ext_res = ext_res_w;
// insert 
  wire [63:0] zero_one_ins_processed_w = zero_one_w << c[4:0];
  wire [31:0] ins_right_part_w = b[31:0] & zero_one_ins_processed_w[63:32];

  wire [63:0] one_zero_w = {32'hffffffff,32'd0};
  wire [63:0] one_zero_ins_processed_w = one_zero_w << (c[10:6] + 5'd1);
  wire [31:0] ins_left_part_w  = b[31:0] & one_zero_ins_processed_w[63:32];

  wire [31:0] ins_middle_part_w= (a[31:0] << c[4:0]) & ~one_zero_ins_processed_w[63:32];

  wire [31:0] ins_res_w_temp = ins_left_part_w | ins_middle_part_w | ins_right_part_w;
  wire [31:0] ins_res_w = ins_res_w_temp;

  wire [31:0] ins_res = ins_res_w;

//count
wire [ 4:0] count_lead_w_res;
wire [ 4:0] count_tail_w_res;
wire [ 5:0] count_lead_d_res;
wire        count_one_zero = c[0];
wire [31:0] bitreverse = { a[ 0], a[ 1], a[ 2], a[ 3], a[ 4], a[ 5], a[ 6], a[ 7],
                           a[ 8], a[ 9], a[10], a[11], a[12], a[13], a[14], a[15],
                           a[16], a[17], a[18], a[19], a[20], a[21], a[22], a[23],
                           a[24], a[25], a[26], a[27], a[28], a[29], a[30], a[31]};

wire [31:0] bitrev_res = bitreverse;

wire [31:0] counter_input = alu_tail_count ? bitreverse : a;
leading_counter_32 LSOC1k_leading_counter_32 (counter_input, count_one_zero, count_lead_d_res, count_tail_w_res,count_lead_w_res);
wire [31:0] count_lead_res = {27'd0,count_lead_w_res};
wire [31:0] count_tail_res = {27'd0,count_tail_w_res};
//bit swap
wire [31:0] bitswap   = { a[24], a[25], a[26], a[27], a[28], a[29], a[30], a[31],   
                          a[16], a[17], a[18], a[19], a[20], a[21], a[22], a[23],   
                          a[ 8], a[ 9], a[10], a[11], a[12], a[13], a[14], a[15],   
                          a[ 0], a[ 1], a[ 2], a[ 3], a[ 4], a[ 5], a[ 6], a[ 7] };
wire [31:0] bitswap_res = bitswap;
//word swap
wire [31:0] wordswap_within_halfwords = {a[23:16],a[31:24],a[7:0],a[15:8]};
wire [31:0] wsbh_res = wordswap_within_halfwords;
wire [31:0] dshd_res = {a[15:0],a[31:16]};
//revb
wire [31:0] revb_2w  = {a[7:0],a[15:8],a[23:16],a[31:24]};
wire [31:0] revb_res = revb_2w;
//sign-extend
wire [31:0] seb_res = {{24{a[ 7]}},a[7:0]};
wire [31:0] seh_res = {{16{a[15]}},a[15:0]};
//select
wire [31:0] seleqz_res = (b != 32'd0) ? 32'd0 : a;
wire [31:0] selnez_res = (b != 32'd0) ? a : 32'd0;
// result muxer
wire [31:0] res =
    {32{alu_lsau}} & add_sub_res_wu |
    {32{alu_lu32i}} & lu32i_res |
    {32{alu_lu12i}} & lu12i_res |
    {32{alu_and}} & and_res |
    {32{alu_andn}} & andn_res |
    {32{alu_or}} & or_res |
    {32{alu_orn}} & orn_res |
    {32{alu_xor}} & xor_res |
    {32{alu_nor}} & nor_res |
    {32{alu_add || (alu_lsa && !alu_lsau)}} & add_sub_res |
    {32{alu_pcalau}} & add_sub_res & 32'hfffff000 |
    {32{alu_sub}} & add_sub_res |
    {32{alu_slt}} & slt_res |
    {32{alu_sltu}} & sltu_res |
    {32{alu_sll}} & sll_res |
    {32{alu_srl}} & sr_res |
    {32{alu_sra}} & sr_res |
    {32{alu_align}} & align_res |
    {32{alu_rot}} & rotate_res |
    {32{alu_lead_count}} & count_lead_res |
    {32{alu_tail_count}} & count_tail_res |
    {32{alu_bitswap}} & bitswap_res |
    {32{alu_bitrev}} & bitrev_res |
    {32{alu_revb}} & revb_res |
    {32{alu_ext}} & ext_res |
    {32{alu_ins}} & ins_res |
    {32{alu_seb}} & seb_res |
    {32{alu_seh}} & seh_res |
    {32{alu_wsbh}} & wsbh_res |
    {32{alu_dshd}} & dshd_res |
    {32{alu_seleqz}} & seleqz_res |
    {32{alu_selnez}} & selnez_res ;
  // set zero flag
  wire zf = (res == 0);
  // output results
  assign Result = res;
  
endmodule

module leading_counter_4(
	input  [ 3:0] in_number,
	input         zero_one,
	output [ 2:0] count
);
wire [ 3:0] number = zero_one ? in_number : ~in_number;

assign count = number[3] & number[2] & number[1] & number[0] ? 3'd4 :
				       number[3] & number[2] & number[1]             ? 3'd3 :
				       number[3] & number[2]                         ? 3'd2 :
				       number[3]                                     ? 3'd1 :
															                                 3'd0 ;
endmodule

module leading_counter_8(
	input  [ 7:0] in_number,
	input         zero_one,
	output [ 3:0] count
);
wire [ 2:0] count_high;
wire [ 2:0] count_low;
leading_counter_4 hi (in_number[7:4], zero_one, count_high);
leading_counter_4 lo (in_number[3:0], zero_one, count_low);
assign count = count_high == 3'd4 ? count_high+count_low : {1'd0,count_high};
endmodule

module leading_counter_16(
	input  [15:0] in_number,
	input         zero_one,
	output [ 4:0] count
);
wire [ 3:0] count_high;
wire [ 3:0] count_low;
leading_counter_8 hi (in_number[15:8], zero_one, count_high);
leading_counter_8 lo (in_number[ 7:0], zero_one, count_low);
assign count = count_high == 4'd8 ? count_high+count_low : {1'd0,count_high};
endmodule

module leading_counter_32(
	input  [31:0] in_number,
	input         zero_one,
	output [ 5:0] count,
  output [ 4:0] count_high,
  output [ 4:0] count_low
);

leading_counter_16 hi (in_number[31:16], zero_one, count_high);
leading_counter_16 lo (in_number[15: 0], zero_one, count_low);
assign count = count_high == 5'd16 ? count_high+count_low : {1'd0,count_high};
endmodule

`endif

