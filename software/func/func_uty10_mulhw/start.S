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
	lu12i.w  $r3, 0x1c000            # r3 = 1c000000
	addi.w   $r4, $r0, 0x6aa         # r4 = 6AA
	mulh.wu  $r5, $r3, $r4           # r5 = BA
	addi.w   $r5, $r5, -0x60          # r5 = 5A
