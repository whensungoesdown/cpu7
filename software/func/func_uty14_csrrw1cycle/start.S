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
	addi.w $r3, $r0, 0x2
	addi.w $r4, $r0, 0x0
again:
	addi.w $r4, $r4, 0x1

	addi.w   $r6, $r0, -1            # r6 = ffffffff
	csrwr    $r6, 0x0                # only crmd.ie (bit 2) can be set
	csrrd    $r5, 0x0                # crmd
	addi.w   $r5, $r5, 0x53     
	nop
	nop

	bne    $r3, $r4, again

