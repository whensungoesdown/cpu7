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
    addi.w     $r3, $r0, 0x5a    # r3=0x5a
    csrwr      $r3, 0x6          # CSR era 
    csrrd      $r5, 0x6 
