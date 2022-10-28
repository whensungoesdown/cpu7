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
