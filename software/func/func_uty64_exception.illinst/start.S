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
    
    beq        $r0, $r0, program
	
eentry:

    addi.w     $r5, $r0, 0x5a     # r5 = 0x5a

loop:                             # never return from exception handler
    beq        $r0, $r0, loop

    ertn                          # return from exception                      

program:

    lu12i.w    $r3, 0x1c000
    addi.w     $r3, $r3, 0x4     # 1c000004 eentry: address
    csrwr      $r3, 0xc          # CSR eentry 

# data section will be right here. Next, 0x00000033 will be executed as an instruction and it is an illegal instruction
#   .word 0x00000033

