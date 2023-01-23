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

    addi.w     $r3, $r0, 0x3      # r3 = 3
again:
    addi.w     $r5, $r0, 0xa
    
    beq        $r0, $r0, success

    csrrd      $r5, 0x0           # read crmd

    nop
    nop
    nop
    nop
    nop
    nop

success:
    addi.w     $r5, $r5, 0x30     # r5 = 0x3a
error:
    addi.w     $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20

    addi.w     $r3, $r3, -0x1
    bne        $r3, $r0, again
