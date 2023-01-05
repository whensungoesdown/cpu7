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
    lu12i.w $r6, 0x1c000
    addi.w  $r6, $r6, 0x0c 
    ld.w $r5, $r6, 0x0
