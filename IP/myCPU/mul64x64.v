module mul64x64(
    input           clk,
    input           rstn,

    input           mul_validin,
    input           ex2_allowin,
    output          mul_validout,
    input           ex1_readygo,
    input           ex2_readygo,

    input    [63:0] opa,
    input    [63:0] opb,
    input           mul_signed,
    input           mul64,
    input           mul_hi,
    input           mul_short,

    output   [63:0] mul_res_out,
    output          mul_ready
);

// Pipeline signals
reg  s1_valid;
reg  s2_valid;
wire s1_complete;
wire mul_allowin;

// Acc control signals
wire now_A,now_B,now_C,now_D;
reg  last_A,last_BC,last_D;
reg  mul_short_lock;
reg  mul_signed_lock;
reg  mul_hi_lock;

wire a_high_nonzero,b_high_nonzero;
wire need_A;
reg  need_B,need_C,need_D;
wire need_B_nxt,need_C_nxt,need_D_nxt;

//00 calculate A
//01 calculate B
//10 calculate C
//11 calcultae D
// A a_lu * b_lu
// B a_h  * b_lu
// C a_lu * b_h
// D a_h  * b_h
// Calculation signals
reg  [63:0] opa_lock,opb_lock;
reg  [65:0] result_buffer;
wire [65:0] result_buffer_nxt;
wire [65:0] result_buffer_nxt_before_shift;
wire [65:0] result_buffer_nxt_src1;
wire [65:0] result_buffer_nxt_src2;
wire [65:0] result_buffer_nxt_src3;
wire [65:0] result_buffer_nxt_s;
/* verilator lint_off UNUSED */
wire [65:0] result_buffer_nxt_c;
/* verilator lint_on  UNUSED */
wire        result_buffer_wen;
wire [32:0] opa_nxt,opb_nxt;
wire opa_sign,opb_sign;
wire mul33_en;
/* verilator lint_off UNUSED */
reg  [65:0] mul33_res_u;
reg  [65:0] mul33_res_v;
wire [65:0] mul33_res_u_nxt;
wire [65:0] mul33_res_v_nxt;
/* verilator lint_on  UNUSED */

always @(posedge clk)
begin
    if (!rstn)
    begin
        s1_valid <= 1'b0;
    end
    else if (mul_allowin)
    begin
        s1_valid <= mul_validin&&mul64;
    end
    else if (ex2_allowin&&ex1_readygo&&s1_complete)
    begin
        s1_valid <= 1'b0;
    end
end

always @(posedge clk)
begin
    if (!rstn)
    begin
        s2_valid <= 1'b0;
    end
    else if (mul_allowin)
    begin
        s2_valid <= !mul64&&mul_validin;
    end
    else if (ex2_allowin&&ex1_readygo&&s1_complete)
    begin
        s2_valid <= 1'b1;
    end
    else if (ex2_readygo)
    begin
        s2_valid <= 1'b0;
    end
end

always @(posedge clk)
begin
    if (!rstn)
    begin
        last_A  <= 1'b0;
        last_BC <= 1'b0;
        last_D  <= 1'b0;
    end
    else
    begin
        last_A  <= now_A;
        last_BC <= now_B || now_C;
        last_D  <= now_D;

    end
end


always @(posedge clk)
begin
    if (!rstn)
    begin
        opa_lock <= 64'b0;
        opb_lock <= 64'b0;
        mul_signed_lock <= 1'b0;
        mul_hi_lock <= 1'b0;
        mul_short_lock <= 1'b0;
    end
    else if (mul_allowin&&mul_validin)
    begin
        opa_lock <= opa;
        opb_lock <= opb;
        mul_signed_lock <= mul_signed;
        mul_hi_lock <= mul_hi;
        mul_short_lock <= mul_short;
    end
end

always @(posedge clk)
begin
    if (!rstn)
    begin
        result_buffer <= 66'b0;
    end
    else if (result_buffer_wen)
    begin
        result_buffer <= result_buffer_nxt;
    end
end



always @(posedge clk)
begin
    if (!rstn)
    begin
        need_B <= 1'b0;
        need_C <= 1'b0;
        need_D <= 1'b0;
    end
    else if (mul_allowin&&mul_validin)
    begin
        need_B <= a_high_nonzero&&mul64;
        need_C <= b_high_nonzero&&mul64;
        need_D <= mul_hi&&mul64;
    end
    else
    begin
        need_B <= need_B_nxt;
        need_C <= need_C_nxt;
        need_D <= need_D_nxt;
    end
end

always@(posedge clk)
begin
    if (!rstn)
    begin
        mul33_res_u <= 66'b0;
        mul33_res_v <= 66'b0;
    end
    else if (mul33_en)
    begin
        mul33_res_u <= mul33_res_u_nxt;
        mul33_res_v <= mul33_res_v_nxt;
    end
end


assign need_A = mul_allowin&&mul_validin;
assign need_B_nxt = 1'b0;
assign need_C_nxt = need_B ? need_C : 1'b0;
assign need_D_nxt = need_B || need_C ? need_D : 1'b0;

mul32x32 mul32x32(
    .a          (opa_nxt),
    .b          (opb_nxt),
    .a_sign     (opa_sign),
    .b_sign     (opb_sign),
    .u          (mul33_res_u_nxt),
    .v          (mul33_res_v_nxt)
);

assign a_high_nonzero = |(opa[63:32]);
assign b_high_nonzero = |(opb[63:32]);

assign opa_nxt = now_B || now_D ? {opa_lock[63]&&mul_signed_lock,opa_lock[63:32]} :
                 now_C ? {1'b0,opa_lock[31:0]} : {mul64 ? 1'b0 : opa[31]&&mul_signed,opa[31:0]};
assign opb_nxt = now_C || now_D ? {opb_lock[63]&&mul_signed_lock,opb_lock[63:32]} :
                 now_B ? {1'b0,opb_lock[31:0]} : {mul64 ? 1'b0 : opb[31]&&mul_signed,opb[31:0]};
assign opa_sign = now_B || now_D ? mul_signed_lock :
                  now_C || mul64 ? 1'b0 :  mul_signed;
assign opb_sign = now_C || now_D ? mul_signed_lock :
                  now_B || mul64 ? 1'b0 : mul_signed;

assign mul33_en  = need_A || need_B || need_C || need_D;
assign mul_allowin = (!s2_valid || s2_valid&&ex2_readygo) && !s1_valid;
assign s1_complete = !need_C&&!need_D|| !need_B&& !(need_C&&need_D);

assign now_A = need_A;
assign now_B = need_B;
assign now_C = !need_B&&need_C;
assign now_D = !need_B&&!need_C&&need_D;

assign result_buffer_wen = last_A || last_BC || last_D;
assign result_buffer_nxt_before_shift = {result_buffer_nxt_s} + {result_buffer_nxt_c[64:0],1'b0};
assign result_buffer_nxt = last_A && mul_short_lock ? mul_hi_lock ? {{34{result_buffer_nxt_before_shift[63]}},result_buffer_nxt_before_shift[63:32]} 
                                                               : {{34{result_buffer_nxt_before_shift[31]}},result_buffer_nxt_before_shift[31: 0]} 
                          :last_A && need_D ? {32'b0,result_buffer_nxt_before_shift[65:32]} : result_buffer_nxt_before_shift[65:0];

assign result_buffer_nxt_src1 = last_BC && !need_D ? {mul33_res_u[33:0],32'b0}
                                                   :  mul33_res_u[65:0];
assign result_buffer_nxt_src2 = last_BC && !need_D ? {mul33_res_v[33:0],32'b0}
                                                   :  mul33_res_v[65:0];
assign result_buffer_nxt_src3 = last_A ? 66'b0 : last_D ?{{32{result_buffer[65]&mul_signed_lock}},result_buffer[65:32]} : result_buffer;


assign result_buffer_nxt_s    = result_buffer_nxt_src1 ^ result_buffer_nxt_src2 ^ result_buffer_nxt_src3;
assign result_buffer_nxt_c    = result_buffer_nxt_src1&result_buffer_nxt_src2 
                               |result_buffer_nxt_src1&result_buffer_nxt_src3
                               |result_buffer_nxt_src2&result_buffer_nxt_src3;

assign mul_res_out  = result_buffer_wen ? result_buffer_nxt[63:0] : result_buffer[63:0];
assign mul_validout = s2_valid;
assign mul_ready = (s1_valid) && s1_complete || s2_valid && !mul64;

endmodule


