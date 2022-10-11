u@unamed:~/prjs/cpu7/sims/verilator/run_func$ ./configure.sh -run func/func_uty0 --disable-trace-comp

u@unamed:~/prjs/cpu7/sims/verilator/run_func$ gtkwave log/func/func_uty0_log/simu_trace.vcd

u@unamed:~/prjs/cpu7/sims/verilator/run_func$ vim obj/func/func_uty0_obj/obj/test.s


make clean_all后，要在run_func目录下mkdir log
