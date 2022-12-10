#!/bin/bash

echo -e "\n\n\nTest func_uty0\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty0 --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty1_ld\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty1_ld --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty2_ld_2\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty2_ld_2 --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty3_st\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty3_st --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty4_beq\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty4_beq --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty5_jirl\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty5_jirl --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty6_beq_testbyp\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty6_beq_testbyp --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty7_beq_testbyp1cycle\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty7_beq_testbyp1cycle --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty8_mulw\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty8_mulw --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty9_mulhwu\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty9_mulhwu --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty10_mulhw\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty10_mulhw --disable-trace-comp
make soft_compile
make simulation_run_func
