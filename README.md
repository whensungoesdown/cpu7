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


## Build and Test

Test cases for each instruction are put at software/func.

`````shell
u@unamed:~/prjs/cpu7/software/func$ tree -L 1
.
├── func_uty0
├── func_uty10_mulhw
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

`u@unamed:~/prjs/cpu7/sims/verilator/run_func$ ./configure.sh -run func/func_uty10_mulhw --disable-trace-comp`

Cleanup last build. (`make clean` will clean all, including verilator generated files.)

`u@unamed:~/prjs/cpu7/sims/verilator/run_func$ movetotrash ./obj/func/`

Only compile the testcase program.

`u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make soft_compile`

Run the simulation.

`u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make simulation_run_func`
 
##### Or Simply

`````shell
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ movetotrash ./obj/func/
u@unamed:~/prjs/cpu7/sims/verilator/run_func$ make
`````

### Run all the tests

`u@unamed:~/prjs/cpu7/sims/verilator/run_func$ ./run_all_tests.sh`

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
