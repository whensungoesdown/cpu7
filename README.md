# cpu7

## Pipeline

Single issue, in order, 5-stage pipeline

_f _d _e _m _w


## Modules

`````c

                                                               +----------------------------------------------+                               
                                                               | EXU               +--------+    +-------+    |
                                                               |     +---------+   |        |    |       |    |
                                                               |     |         |   |        |    |  alu  |    |
                +--------------------------------------+       |     |   csr   |   |        |    +-------+    |
                |IFU                                   |       |     |         |   |        |    +-------+    |
 +--------+     |       +----------+   +------+        |       |     +---------+   |        |    |  bru  |    |
 |        | - - | - - - |          |   |      |        |       |     +---------+   |  ecl   |    |       |    |
 | icache |     |       | ifu_fdp  |   |decode|  ...   | >  >  |     |         |   |   &    |    +-------+    |
 |        | - - | - - - |          |   |      |        |       |     | regfile |   |  byp   |    +-------+    |
 +--------+     |       +----------+   +------+        |       |     |         |   |        |    |       |    |
                |                                      |       |     +-------- +   |        |    |  mul  |    |
                |                                      |       |                   |        |    +-------+    |
                +--------------------------------------+       |  +-----------+    |        |    +-------+    |          
                                                               |  |           |    |        |    |  div  |    |
                                                               |  |    lsu    |    |        |    |       |    |
                                                               |  |           |    +--------+    +-------+    |
                                                               |  +------------                               |
                                                               +----|------|----------------------------------+
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

## Progress

### Implemented Instructions

- Integer Arithmetic Instructions

  **ADD.W** **SUB.W** **ADDI.W** **LU12I.W**
	
- Logical Operation Instructions

- Integer Multiplies


## Build and Test

Test cases for each instruction are put at software/func.

`````shell
u@unamed:~/prjs/cpu7/software/func$ tree -L 1
.
├── func_uty0
├── func_uty10_mulhw
├── func_uty11_csrrd
├── func_uty12_csrwr
├── func_uty13_testbyp1cycle
├── func_uty14_csrrw1cycle
├── func_uty15_csrxchg
├── func_uty1_ld
├── func_uty2_ld_2
├── func_uty3_st
├── func_uty4_beq
├── func_uty5_jirl
├── func_uty6_beq_testbyp
├── func_uty7_beq_testbyp1cycle
├── func_uty8_mulw
├── func_uty9_mulhwu
└── test_cache_loop
````` 

### Build cpu7

In directory sims/verilator/run_func: 

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make clean
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make
`````

### Build testcase

Choose a testcae, for example, func_uty10_mulhw.

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ ./configure.sh -run func/func_uty10_mulhw --disable-trace-comp
`````

Cleanup last build. (`make clean` will clean all, including verilator generated files.)

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ movetotrash ./obj/func/
`````

Only compile the testcase program.

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make soft_compile
`````

Run the simulation.

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make simulation_run_func
`````
 
##### Or Simply

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ movetotrash ./obj/func/
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make
`````

### Run all the tests

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ ./run_all_tests.sh
`````

When successful, the ** PASS ** will be displayed.

`````shell
Test case passed!
**************************************************
*                                                *
*      * * *       *        * * *     * * *      *
*      *    *     * *      *         *           *
*      * * *     *   *      * * *     * * *      *
*      *        * * * *          *         *     *
*      *       *       *    * * *     * * *      *
*                                                *
**************************************************

````` 

## Debug

#### View the testcase generated code

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ vim obj/func/func_uty10_mulhw_obj/obj/test.s
`````

#### View the signals 

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ gtkwave log/func/func_uty10_mulhw_log/simu_trace.vcd
`````
