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

    addi.w    $r3, $r0, -0x1
    bge       $r0, $r3, next

next:
    addi.w    $r3, $r0, 0x2
    addi.w    $r4, $r0, 0x3
    bge       $r3, $r4, error

    addi.w    $r3, $r0, 0x2
    addi.w    $r4, $r0, 0x1
    bge       $r3, $r4, next2
    beq       $r0, $r0, error
next2:

    addi.w    $r3, $r0, -0x1
    addi.w    $r4, $r0, -0x2
    bge       $r3, $r4, success

    addi.w    $r5, $r0, 0xff     # r5 = 0xff

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
