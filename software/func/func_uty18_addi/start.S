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
	addi.w   $r3, $r0, 0x30          # r3 = 30
	addi.w   $r4, $r3, 0x20          # r4 = 50 
	addi.w   $r5, $r4, 0x0a          # r5 = 5a 
