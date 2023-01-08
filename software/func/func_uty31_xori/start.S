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
    xori      $r6, $r3, 0x1      # r6 should be 0 (0x1 XOR 0x1) 
    addi.w    $r7, $r0, 0x0
    bne       $r7, $r6, error     

    
    addi.w    $r3, $r0, 0x7ff    # r3 = 0x7ff
    xori      $r6, $r3, 0x7ff    # r6 should be 0 (0x7ff XOR 0x7ff) 
    addi.w    $r7, $r0, 0x0
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, 0x55    # r3 = 0x55  (01010101)
    xori      $r6, $r3, 0xaa    # r6 should be ff 
    addi.w    $r7, $r0, 0xff
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, -0x1    # r3 = 0xffffffff
    xori      $r6, $r3, 0x7ff   # r6 should be fffff800 (ffffffff XOR 000007ff) 
    addi.w    $r7, $r0, -0x1
    addi.w    $r7, $r7, -0x7ff
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, 0x0     # r3 = 0x0
    xori      $r6, $r3, 0x0     # r6 should be 0
    addi.w    $r7, $r0, 0x0
    bne       $r7, $r6, error     


    addi.w    $r3, $r0, -0x1    # r3 = -0x1
    xori      $r6, $r3, 0x0     # r6 should be ffffffff 
    addi.w    $r7, $r0, -0x1
    bne       $r7, $r6, error     

success:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
