#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"


##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc

.data

#var1:	.word	0x00000033

.text
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
	addi.w $r5, $r0, 0x0a
	addi.w $r5, $r5, 0x10
	addi.w $r5, $r5, 0x10
	addi.w $r6, $r0, 0x2a
	beq    $r5, $r6, skip
	addi.w $r5, $r5, 0x80
skip:
	addi.w $r5, $r5, 0x10
	addi.w $r5, $r5, 0x10
	addi.w $r5, $r5, 0x10
