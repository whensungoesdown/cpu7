#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"


##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc

.data

var1:	.word	0xff00005a

.text
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
    lu12i.w $r6, 0x1c000
    addi.w  $r6, $r6, 0x18       
    ld.bu   $r5, $r6, 0x3              # should read the 0xff byte
    addi.w  $r3, $r0, 0xff
    bne     $r3, $r5, error

    ld.bu $r5, $r6, 0x0              # should read the 0x5a byte
error:

