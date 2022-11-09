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
	lu12i.w $r6, 0x1c000
	addi.w $r5, $r0, 0x0a
	addi.w $r5, $r5, 0x10
	addi.w $r5, $r5, 0x10
	jirl   $r1, $r6, 0x18    # it should jump to skip and r1 should be 1c000014
	addi.w $r5, $r5, 0x80
skip:
	addi.w $r5, $r5, 0x10
	addi.w $r5, $r5, 0x10
	addi.w $r5, $r5, 0x10
