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

    # r7 is used to compare with the result register r6

    addi.w    $r3, $r0, 0x1      # r3 = 0x1
    ori       $r6, $r3, 0x1      # r6 should be 1 (0x1 OR 0x1) 
    addi.w    $r7, $r0, 0x1
    bne       $r7, $r6, error     

    
    addi.w    $r3, $r0, 0x7ff    # r3 = 0x7ff
    ori       $r6, $r3, 0x7ff    # r6 should be 7ff (0x7ff OR 0x7ff) 
    addi.w    $r7, $r0, 0x7ff
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, 0x55    # r3 = 0x55  (01010101)
    ori       $r6, $r3, 0xaa    # r6 should be ff (01010101 OR 10101010) 
    addi.w    $r7, $r0, 0xff
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, -0x1    # r3 = 0xffffffff
    ori       $r6, $r3, 0x7ff   # r6 should be ffffffff (ffffffff OR 7ff) 
    addi.w    $r7, $r0, -0x1
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, 0x0     # r3 = 0x0
    ori       $r6, $r3, 0x0     # r6 should be 0 (0 OR 0) 
    addi.w    $r7, $r0, 0x0
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, -0x1    # r3 = -0x1
    ori       $r6, $r3, 0x0     # r6 should be ffffffff (ffffffff or 0) 
    addi.w    $r7, $r0, -0x1
    bne       $r7, $r6, error     

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
