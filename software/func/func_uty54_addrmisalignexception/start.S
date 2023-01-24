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
    lu12i.w    $r3, 0x1c000
    addi.w     $r3, $r3, 0x50    # 1c000050 eentry: address
    csrwr      $r3, 0xc          # CSR eentry 

    lu12i.w    $r6, 0x1c000
    addi.w     $r6, $r6, 0x58    # 1c000058 .data
    addi.w     $r7, $r0, 0x5a
# rd is the data to be stored
    st.h       $r7, $r6, 0x1     # cause address misalign exception
    ld.h       $r5, $r6, 0x0

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

eentry:
    addi.w     $r5, $r0, 0x20
    addi.w     $r5, $r5, 0x3a

loop:                            # program ends here
    beq        $r0, $r0, loop
