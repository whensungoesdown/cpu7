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
    pcaddu12i $r6, 0x08          # r6 = 0x1c0008000
    lu12i.w   $r7, 0x08          # r7 = 0x000008000
    sub.w     $r6, $r6, $r7      # r6 = 0x1c0000000
    ld.w $r5, $r6, 0x10
