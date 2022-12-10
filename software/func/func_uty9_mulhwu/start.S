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
	addi.w   $r6, $r0, -0xAA
	addi.w   $r7, $r0, 0x7AA
	mulh.wu  $r5, $r6, $r7      # r5 = 7A9
	addi.w   $r5, $r5, -0x74f

