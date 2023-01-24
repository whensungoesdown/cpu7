#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"


##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc

.data

var1:	.word	0x00000033

.text
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
    addi.w     $r4, $r0, -0x1
    csrwr      $r4, 0x0          # crmd
    lu12i.w    $r3, 0x1c000
    addi.w     $r3, $r3, 0x50    # 1c000050 eentry: address
    csrwr      $r3, 0xc          # CSR eentry 

    lu12i.w    $r6, 0x1c000
    addi.w     $r6, $r6, 0x58    # 1c000058 .data
    addi.w     $r7, $r0, 0xcc
# rd is the data to be stored
    st.h       $r7, $r6, 0x1     # cause address misalign exception
    ld.h       $r6, $r6, 0x0

    addi.w     $r5, $r5, 0xa     # return from exception handler, r5 should be 0x50 if success

loop:                            # program ends here
    beq        $r0, $r0, loop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

eentry:
    csrrd      $r8, 0x0          # crmd, should be zero after exception raised
    bne        $r0, $r8, error
    csrrd      $r8, 0x1          # prmd, should read out 0x7 (pie, pplv)
    addi.w     $r9, $r0, 0x7
    bne        $r9, $r8, error
    csrrd      $r8, 0x6          # era (eret)
    lu12i.w    $r9, 0x1c000
    addi.w     $r9, $r9, 0x20    # st where it causes ale
    bne        $r9, $r8, error

    addi.w     $r9, $r9, 0x4     # skip the falting instruction st
    csrwr      $r9, 0x6          # era

success:
    addi.w     $r5, $r0, 0x30     # r5 = 0x30
error:
    addi.w     $r5, $r5, 0x20     # r5 = 0x50 if go through success, otherwise 0x20

    ertn                          # return from exception                      
