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


    addi.w    $r3, $r0, 0x0      # nothing, just try not let b as the first instruction

    b         func

    beq       $r0, $r0, exit


func:
    addi.w    $r5, $r0, 0x3a     # r5 = 0x3a
    addi.w    $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20
    jirl      $r0, $r1, 0        # ret

exit:
