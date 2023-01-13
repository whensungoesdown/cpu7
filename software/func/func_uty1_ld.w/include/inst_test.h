// file name: inst_test.h
#include "cpu_cde.h"

#define TEST_LU12I_W(in_a, ref_base) \
    lu12i.w   a0, ref_base&0x80000?ref_base-0x100000:ref_base; \
    lu12i.w   t0, in_a&0x80000?in_a-0x100000:in_a;  \
    NOP4; \
    add.w  a0, a0, t1; \
    add.w  t1, t1, t2; \
    NOP4; \
    bne   t0, a0, inst_error; \
    nop

/* 2 */
#define TEST_ADD_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    add.w v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 3 */
#define TEST_ADDI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    addi.w v0, t0, in_b&0x800?in_b-0x1000:in_b; \
    NOP4; \
    bne   v0, v1, inst_error; \
    nop

/* 4 */
#define TEST_BEQ(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    b 2000f; \
    nop; \
1000:; \
    LI (v0, back_flag); \
    beq t1, t0, 3000f; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
2000:; \
    LI (t0, in_a); \
    LI (t1, in_b); \
    NOP4; \
    beq t0, t1, 1000b; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
3000:; \
    LI (v1, front_flag); \
4000:; \
    LI (s5, b_flag_ref); \
    LI (s6, f_flag_ref); \
    NOP4 ; \
    bne v0, s5, inst_error; \
    nop; \
    bne v1, s6, inst_error; \
    nop

/* 5 */
#define TEST_BNE(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    b 2000f; \
    nop; \
1000:; \
    LI (v0, back_flag); \
    bne t1, t0, 3000f; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
2000:; \
    LI (t0, in_a); \
    LI (t1, in_b); \
    NOP4; \
    bne t0, t1, 1000b; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
3000:; \
    LI (v1, front_flag); \
4000:; \
    LI (s5, b_flag_ref); \
    LI (s6, f_flag_ref); \
    NOP4 ; \
    bne v0, s5, inst_error; \
    nop; \
    bne v1, s6, inst_error; \
    nop

/* 6 */
#define TEST_LD_W(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (v1, ref); \
    st.w t1, t0, offset_align; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -8; \
    NOP4; \
    st.w a0, a0, offset_align; \
    st.w a1, a1, offset_align; \
    ld.w v0, t0, offset; \
    ld.w a2, a0, offset_align; \
    ld.w a0, a1, offset_align; \
    ld.w a2, a1, offset_align; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 7 */
#define TEST_OR(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    or v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 8 */
#define TEST_SLT(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    slt v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 11 */
#define TEST_SLLI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    slli.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 12 */
#define TEST_ST_W(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (v1, ref); \
    st.w t1, t0, offset; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -4; \
    NOP4; \
    st.w a0, a0, offset; \
    st.w a1, a1, offset; \
    ld.w v0, t0, offset_align; \
    ld.w a2, a0, offset; \
    ld.w a0, a1, offset; \
    ld.w a2, a1, offset; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 14 */
#define TEST_BL(back_flag, front_flag, b_flag_ref, f_flag_ref) \
    add.w s7, zero, $r1; \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    bl 2000f; \
    nop; \
1000:; \
    NOP4; \
    add.w a1, ra, zero; \
    LI (v0, back_flag); \
1001:; \
    bl 3000f; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
2000:; \
    NOP4; \
    add.w a0, ra, zero; \
    bl 1000b; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
3000:; \
    NOP4; \
    add.w a2, ra, zero; \
    LI (v1, front_flag); \
4000:; \
    NOP4; \
    add.w $r1, zero, s7; \
    LI (t5, b_flag_ref); \
    LI (t4, f_flag_ref); \
    bne v0, t5, inst_error; \
    nop; \
    addi.w a2, a2, 0x28; \
    bne v1, t4, inst_error; \
    nop; \
    NOP4; \
    bne a2, a1, inst_error; \
    nop

/* --------------------- */
#define TEST_B(back_flag, front_flag, b_flag_ref, f_flag_ref) \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    b 2000f; \
    nop; \
1000:; \
    NOP4; \
    LI (v0, back_flag); \
1001:; \
    b 3000f; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
2000:; \
    NOP4; \
    b 1000b; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
3000:; \
    NOP4; \
    LI (v1, front_flag); \
4000:; \
    NOP4; \
    LI (t5, b_flag_ref); \
    LI (t4, f_flag_ref); \
    bne v0, t5, inst_error; \
    nop; \
    nop; \
    bne v1, t4, inst_error; \
    nop
  

/* 15 */
#define TEST_JIRL(back_flag, front_flag, b_flag_ref, f_flag_ref) \
    add.w s7, zero, $r1; \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    bl 1f; \
    nop;    \
1:  ;       \
    nop;    \
    nop;    \
    nop;    \
    addi.w t0, $r1, 7*4; \
    addi.w t1, $r1, 22*4; \
    b 2000f; \
    nop; \
1000:; \
    LI (v0, back_flag); \
    jirl zero, t1, 0; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
2000:; \
    jirl zero, t0, 0; \
    nop; \
    b 4000f; \
    nop; \
    nop; \
3000:; \
    LI (v1, front_flag); \
4000:; \
    LI (s5, b_flag_ref); \
    LI (s6, f_flag_ref); \
    add.w $r1, zero, s7; \
    bne v0, s5, inst_error; \
    nop; \
    bne v1, s6, inst_error; \
    nop

/* 24 */
#define TEST_SUB_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    sub.w v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 25 */
#define TEST_SLTU(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    sltu v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 26 */
#define TEST_AND(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    and v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 28 */
#define TEST_NOR(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    nor v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 30 */
#define TEST_XOR(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    xor v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 33 */
#define TEST_SRAI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    srai.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop

/* 35 */
#define TEST_SRLI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    srli.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, inst_error; \
    nop
