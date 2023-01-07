#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"

.data

var1:	.word	0x0000005a

.text
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
    addi.w    $r2, $r0, 0x1      # r2 is used to compare with the r6 result


    addi.w    $r3, $r0, 0x1      # r3 = 0x1
    addi.w    $r4, $r0, 0x1      # r4 = 0x1
    sltu       $r6, $r3, $r4      # r6 should be 0
    beq       $r2, $r6, error    # if r6 == 1 goto error

    
    addi.w    $r3, $r0, 0x1      # r3 = 0x1
    addi.w    $r4, $r0, 0x2      # r4 = 0x2
    sltu       $r6, $r3, $r4      # r6 should be 1
    beq       $r0, $r6, error    # if r6 == 0 goto error
	

    addi.w    $r3, $r0, -0x1     # r3 = ffffffff
    addi.w    $r4, $r0, 0x2      # r4 = 0x2
    sltu       $r6, $r3, $r4      # r6 should be 0  (ffffffff < 2)
    bne       $r0, $r6, error    # if r6 == 0 goto error


    addi.w    $r3, $r0, -0x2     # r3 = fffffffe
    addi.w    $r4, $r0, -0x1     # r4 = ffffffff
    sltu       $r6, $r3, $r4      # r6 should be 1 (fffffffe < ffffffff)
    bne       $r2, $r6, error    # if r6 != 1 goto error


    addi.w    $r3, $r0, -0x5     # r3 = fffffffb
    addi.w    $r4, $r0, -0x5     # r4 = fffffffb
    sltu       $r6, $r3, $r4      # r6 should be 0
    bne       $r0, $r6, error    # if r6 != 0 goto error


    addi.w    $r3, $r0, 0x0     # r3 = 0x0
    addi.w    $r4, $r0, 0x0     # r4 = 0x0
    sltu       $r6, $r3, $r4      # r6 should be 0
    bne       $r0, $r6, error    # if r6 != 0 goto error

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
