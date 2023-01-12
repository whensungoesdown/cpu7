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

    bl        test

    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10     
    addi.w    $r5, $r0, 0x10
     
test:
    lu12i.w   $r3, 0x1c000
    addi.w    $r3, $r3, 0x4
    bne       $r1, $r3, error

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
