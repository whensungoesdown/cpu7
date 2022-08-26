#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"


##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
    addi.w t0, t0, 1
    addi.w t0, t0, 2
    addi.w t0, t0, 3
    addi.w t0, t0, 4
    addi.w t0, t0, 5

    bne t0, zero, testbranch
    addi.w t0, t0, 1
    addi.w t0, t0, 1

testbranch:
    addi.w t1, t1, 0x10
    addi.w t1, t1, 0x10
    addi.w t1, t1, 0x10

    addi.w $r5, $r0, 0x5a
