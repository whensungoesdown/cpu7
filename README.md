# CPU7

CPU7 is my seventh CPU project. It is still a single-issue pipelined core. The goal is to rewrite the modules following OpenSPARC's coding style.

At the same time, I wanted the process to be LoongArch based, and I was studying [CHIPLAB](https://gitee.com/loongson-edu/chiplab). Therefore  was the starting point of this project. Most of the datapath and control logic modules are rewritten for the core. Decode and functional modules such as ALU, and MUL are reused.


More blogs are kept at:
- https://whensungoesdown.github.io/

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


## LA32 Instructions

### Implemented

- Integer Arithmetic Instructions

`````

  ADD.W SUB.W ADDI.W 

  LU12I.W PCADDU12I 

  SLT[U] SLT[U]I 

  AND OR NOR XOR

  ANDI ORI XORI

  NOP
`````
	
- Bit-Shift Instructions

`````
  SLL.W SRL.W SRA.W SLL.W SRL.W SRA.W

  SLLI.W SRLI.W SRAI.W
`````

- Branch Instructions

`````
  BEQ BNE BLT[U] BGE[U]

  B BL

  JIRL
`````

- Integer Multiply

`````
  MUL.W MULH.W[U]
`````

- Common Memory Access Instructions

`````
  LD.B LD.H LD.W LD.BU LD.HU LD.HU

  ST.B ST.H ST.W
`````

- CSR Access Instructions

`````
  CSRRD CSRWR CSRXCHG
`````
### Implementing...

- Integer Divide Instructions

`````
  DIV.W[U]  MOD.W[U]
`````

- Common Memory Access Instructions

`````
  PRELD
`````

- Atomic Memory Access Instructions

`````
  LL.W SC.W
`````

- Barrier Instructions

`````
  DBAR IBAR
`````

- Floating-point Instructions

- Cache and TLB Instructions

- Misc

`````
  SYSCALL BREAK

  RDCNTV{L/H}.W RDCNTID

  ERTN IDLE
`````

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


`````shell
cd sims/verilator/run_func
make clean
make
`````

### Build testcase

Choose a testcae, for example, func_uty10_mulhw.

`````shell
sims/verilator/run_func$ ./configure.sh -run func/func_uty10_mulhw --disable-trace-comp
`````

Cleanup last build. (`make clean` will clean all, including verilator generated files.)

`````shell
sims/verilator/run_func$ movetotrash ./obj/func/
`````

Partialy compile the testcase program.

`````shell
sims/verilator/run_func$ make soft_compile
`````

Run the simulation.

`````shell
sims/verilator/run_func$ make simulation_run_func
`````
 
##### or Recompile and run the testcase

`````shell
sims/verilator/run_func$ movetotrash ./obj/func/
sims/verilator/run_func$ make
`````

### Run all the tests

`````shell
sims/verilator/run_func$ ./run_all_tests.sh
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
sims/verilator/run_func$ vim obj/func/func_uty10_mulhw_obj/obj/test.s
`````

#### View the signals 

`````shell
sims/verilator/run_func$ gtkwave log/func/func_uty10_mulhw_log/simu_trace.vcd
`````
