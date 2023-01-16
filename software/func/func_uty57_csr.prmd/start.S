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
    addi.w     $r3, $r0, -0x1    # r3 = 0xFFFFFFFF
    csrwr      $r3, 0x1          # CSR PRMD 
    csrrd      $r5, 0x1          # should read out 0x7  1 pie  11 pplv
    addi.w     $r5, $r5, 0x53
