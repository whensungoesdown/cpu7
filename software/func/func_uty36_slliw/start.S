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

    addi.w    $r3, $r0, 0x1      # r3 = 0x1
    slli.w    $r6, $r3, 0x2      # r6 should be 32'b100
    addi.w    $r7, $r0, 0x4
    bne       $r6, $r7, error

    addi.w    $r3, $r0, 0x1      # r3 = 0x1
    slli.w    $r6, $r3, 0x0      # r6 should be identical to r3 (0x1)
    addi.w    $r7, $r0, 0x1
    bne       $r6, $r7, error

    addi.w    $r3, $r0, 0x1      # r3 = 0x1
    slli.w    $r6, $r3, 31       # r6 should be identical to r3 (0x1)
    lu12i.w   $r7, 0x7ffff
    addi.w    $r7, $r7, 0x7ff
    addi.w    $r7, $r7, 0x7ff
    addi.w    $r7, $r7, 0x2      # r7 = 0x80000000
    bne       $r6, $r7, error


    # slliw   rd, rj, ui5      32 or 0x22 is overflowed
#    addi.w    $r3, $r0, 0x1      # r3 = 0x1
#    slli.w    $r6, $r3, 32       # r6 should be identical to r3 because only rk[0:4] take effects
#    addi.w    $r7, $r0, 0x1      
#    bne       $r6, $r7, error
#
#    addi.w    $r3, $r0, 0x1      # r3 = 0x1
#    slli.w    $r6, $r3, 0x22     # r6 should be 32'b00  because only rk[0:4] take effects
#    addi.w    $r7, $r0, 0x4      
#    bne       $r6, $r7, error

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
