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

    lu12i.w   $r3, 0x10000       # r3 = 0x10000000
    addi.w    $r4, $r0, 0x2      # r4 = 0x2
    srl.w     $r6, $r3, $r4      # r6 should be 0x04000000
    lu12i.w   $r7, 0x4000
    bne       $r6, $r7, error

    lu12i.w   $r3, 0x10000       # r3 = 0x10000000
    addi.w    $r4, $r0, 0x0      # r4 = 0x0
    srl.w     $r6, $r3, $r4      # r6 should be identical to r3 (0x10000000)
    lu12i.w   $r7, 0x10000
    bne       $r6, $r7, error

    lu12i.w   $r3, 0x7ffff
    addi.w    $r3, $r3, 0x7ff
    addi.w    $r3, $r3, 0x7ff
    addi.w    $r3, $r3, 0x2      # r3 = 0x80000000
    addi.w    $r4, $r0, 31       # r4 = 31 (0x1F)
    srl.w     $r6, $r3, $r4      # r6 should be (0x1)
    addi.w    $r7, $r0, 0x1      # r7 = 0x1
    bne       $r6, $r7, error

    lu12i.w   $r3, 0x7ffff
    addi.w    $r3, $r3, 0x7ff
    addi.w    $r3, $r3, 0x7ff
    addi.w    $r3, $r3, 0x2      # r3 = 0x80000000
    addi.w    $r4, $r0, 32       # r4 = 32 (0x20)
    srl.w     $r6, $r3, $r4      # r6 should be identical to r3 because only rk[0:4] take effects
    lu12i.w   $r7, 0x7ffff
    addi.w    $r7, $r7, 0x7ff
    addi.w    $r7, $r7, 0x7ff
    addi.w    $r7, $r7, 0x2      # r7 = 0x80000000
    bne       $r6, $r7, error

    lu12i.w   $r3, 0x10000       # r3 = 0x10000000
    addi.w    $r4, $r0, 0x22     # r4 = 34 (0x22)
    srl.w     $r6, $r3, $r4      # r6 should be 0x04000000  because only rk[0:4] take effects
    lu12i.w   $r7, 0x4000
    bne       $r6, $r7, error

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
