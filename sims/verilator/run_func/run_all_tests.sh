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


echo -e "\n\n\nTest func_uty11_csrrd\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty11_csrrd --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty12_csrwr\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty12_csrwr --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty13_testbyp1cycle\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty13_testbyp1cycle --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty14_csrrw1cycle\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty14_csrrw1cycle --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty15_csrxchg\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty15_csrxchg --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty16_add\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty16_add --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty17_sub\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty17_sub --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty18_addi\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty18_addi --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty19_lu12i\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty19_lu12i --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty20_pcaddu12i\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty20_pcaddu12i --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty21_slt\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty21_slt --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty22_sltu\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty22_sltu --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty23_slti\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty23_slti --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty24_sltui\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty24_sltui --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty25_and\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty25_and --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty26_or\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty26_or --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty27_nor\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty27_nor --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty28_xor\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty28_xor --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty29_andi\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty29_andi --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty30_ori\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty30_ori --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty31_xori\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty31_xori --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty32_nop\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty32_nop --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty33_sllw\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty33_sllw --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty34_srlw\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty34_srlw --disable-trace-comp
make soft_compile
make simulation_run_func


echo -e "\n\n\nTest func_uty35_sraw\n"
movetotrash ./obj/func/
./configure.sh -run func/func_uty35_sraw --disable-trace-comp
make soft_compile
make simulation_run_func
