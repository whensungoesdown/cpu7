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

    addi.w    $r3, $r0, 0x3
    beq       $r0, $r3, error

    addi.w    $r3, $r0, 0x3
    addi.w    $r4, $r0, 0x4
    beq       $r3, $r4, error

    addi.w    $r3, $r0, 0xff
    addi.w    $r4, $r0, 0xff
    beq       $r3, $r4, success


    addi.w    $r5, $r0, 0xff     # r5 = 0xff

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
