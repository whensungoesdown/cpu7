# cpu7

## Pipeline

Single issue, in order, 5-stage pipeline

_f _d _e _m _w


## Modules

`````c

                                                               +-----------------------------------+                               
                                                               | EXU                  +-------+    |
                                                               |     +-----------+    |       |    |
                                                               |     |           |    |  alu  |    |
                +--------------------------------------+       |     | ecl & byp |    +-------+    |
                |IFU                                   |       |     |           |    +-------+    |
 +--------+     |       +----------+   +------+        |       |     +-----------+    |  bru  |    |
 |        | - - | - - - |          |   |      |        |       |     +---------+      |       |    |
 | icache |     |       | ifu_fdp  |   |decode|  ...   | >  >  |     |         |      +-------+    |
 |        | - - | - - - |          |   |      |        |       |     | regfile |      +-------+    |
 +--------+     |       +----------+   +------+        |       |     |         |      |       |    |
                |                                      |       |     +-------- +      |  mul  |    |
                |                                      |       |                      +-------+    |
                +--------------------------------------+       |  +-----------+       +-------+    |          
                                                               |  |           |       |  div  |    |
                                                               |  |    lsu    |       |       |    |
                                                               |  |           |       +-------+    |
                                                               |  +------------                    |
                                                               +----|------|-----------------------+
                                                                    |      |
                                                                  +-----------+
                                                                  |           |
                                                                  |   dcache  |
                                                                  |           |
                                                                  +-----------+
`````

CHIPLAB is the star point of this CPU7 project.

Datapath and control logic are rewritten.

Functional modules such as ALU, BRU, MUL, DIV are mostly reused.

The ICACHE and DCACHE remains for now, but TLB was removed since there is only one machine mode in the current implementation.          


## Design Details

### exu_ifu_stall_req

This signal stalls the IFU from fetching next instruction and the pc_f remains.

When executing a load instruction, the pipeline need to be stalled until it retrives data.


Todo:

`````verilog
assign fdp_dec_valid = inst_valid & ~exu_ifu_stall_req & ~br_taken;
`````

exu_ifu_stall_req should contains br_taken.

It should also contains the stall request from the mul and div.
