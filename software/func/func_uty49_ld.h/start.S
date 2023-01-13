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

# currently, no support for address misalign exception

    lu12i.w $r6, 0x1c000
    addi.w  $r6, $r6, 0x1c       
    ld.h    $r5, $r6, 0x2           # should read the 0xff00 word, and extend it to 0xffffff00
    addi.w  $r3, $r0, -0x1
    addi.w  $r3, $r3, -0xff
    bne     $r3, $r5, error

    ld.h $r5, $r6, 0x0              # should read the 0x005a word
error:

