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
    csrrd      $r3, 0x100         # bsec, should be all zero after reset
    bne        $r3, $r0, error

    addi.w     $r3, $r0, -0x1     # r3 = ffffffff
    csrwr      $r3, 0x100         # set bsec.ef to 1
    csrrd      $r6, 0x100         # r6 should read 0x1
    addi.w     $r4, $r0, 0x1
    bne        $r6, $r4, error

# once bsec.ef is set to 1, it can not be reset to 0
    csrwr      $r0, 0x100         # try to clear bsec
    csrrd      $r6, 0x100         # r6 should read 0x1
    bne        $r6, $r4, error

# try again
    csrwr      $r0, 0x100         # try to clear bsec
    csrrd      $r6, 0x100         # r6 should read 0x1
    bne        $r6, $r4, error

success:
    addi.w     $r5, $r0, 0x3a     # r5 = 0x3a
error:
    addi.w     $r5, $r5, 0x20     # r5 = 0x5a if go through success, otherwise 0x20

loop:
    beq        $r0, $r0, loop

