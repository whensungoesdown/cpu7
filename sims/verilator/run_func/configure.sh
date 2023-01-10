#!/bin/bash 

usage(){
echo "Usage: configure [option]" 
echo "Standard options:"
echo "  --help                	print this message
     "
echo "  --run software        	set software list(use ',' select multiple softwares)
                        	Available software: func/func_lab3 func/func_lab4 
                        	func/func_lab6 func/func_lab7 func/func_lab8 func/func_lab9 
                        	func/func_lab14 func/func_lab16 func/func_advance 
                                my_program dhrystone coremark linux

     " 
echo "  --disable-trace-comp  	disable trace compare in simulation(default: enable)
     " 
echo "  --disable-simu-trace  	disable print inst info to simu_trace.txt(default: enable)
	 "
echo "  --disable-read-miss   	disable read miss check. when core read uninited mem address, 
                        	\"read miss 0x*\" info will be output to terminal(default: enable)
     " 
echo "  --disable-clk-time    	disable print [*ns] info in simu_trace.txt(default: enable)

     " 
echo "  --output-pc-info      	output pc info to terminal(default, can only output one info)
     "
echo "  --output-uart-info		output uart info to terminal 

     " 
echo "  --threads num         	run simulation in num threads(default: disable multithread) 

     "
echo "  --reset-val value     	initialize variables that are not otherwise initialized
                        	val=0 reset to zeros; val=1 reset to all-ones; val=2 randomize 
                        	(default: 0)
     "
echo "  --reset-random-seed value	set random seed when reset in random mode  

     "
echo "  --dump-vcd            	vcd waveform(default: enable)
     "
echo "  --dump-fst            	fst waveform

     "  
echo "  --slice-waveform      	slice waveform with waveform-slice-size ns(default: disable)
     " 
echo "  --waveform-slice-size size	waveform slice clock size(default: 10000)
     "
echo "  --slice-simu-trace    	slice simu_trace.txt with trace-slice-size ns(default: disable)
	 " 
echo "  --trace-slice-size size	simu trace slice clock size(default: 100000)     
	 "
echo "  --tail-waveform       	tail waveform with waveform-tail-size ns(default: disable)
	 "
echo "  --waveform-tail-size size	waveform tail clock size(default: 10000)
	 "
echo "  --tail-simu-trace		tail simu_trace.txt with trace-tail-size ns(default: disable)
	 "
echo "  --trace-tail-size size	simu trace tail clock size(default: 100000)
	 "
} 

THREAD=1
TRACE_COMP=y
RUN_FUNC=n
RUN_C=n 
OUTPUT_PC_INFO=y
OUTPUT_UART_INFO=n
READ_MISS_CHECK=y
RESET_VAL=0 
RESET_SEED=1997
PRINT_CLK_TIME=y 
DUMP_VCD=y 
DUMP_FST=n 
SLICE_WAVEFORM=n 
WAVEFORM_SLICE_SIZE=10000 
SLICE_SIMU_TRACE=n
TRACE_SLICE_SIZE=100000
SIMU_TRACE=y 
TAIL_WAVEFORM=n
WAVEFORM_TAIL_SIZE=10000
TAIL_SIMU_TRACE=n
TRACE_TAIL_SIZE=100000
CONFIG_LOG="./configure.sh"

#get opt 
TEMP=`getopt -o h -a -l run:,threads:,reset-val:,reset-random-seed:,waveform-slice-size:,trace-slice-size:,waveform-tail-size:,trace-tail-size:,disable-trace-comp,help,output-pc-info,output-uart-info,disable-read-miss,disable-clk-time,dump-vcd,dump-fst,slice-waveform,disable-simu-trace,slice-simu-trace,tail-waveform,tail-simu-trace -n "$0" -- "$@"`  

if [ $? != 0 ]
then 
    echo "Terminating......" >&2
    exit 1 
fi 

eval set -- "$TEMP" 

while true
do 
    case "$1" in 
        -run|--run)
            RUN_SOFTWARE=$2 
            CONFIG_LOG="$CONFIG_LOG $1 $2"
            shift 2 ;;
        -threads|--threads)
            THREAD=$2 
            CONFIG_LOG="$CONFIG_LOG $1 $2"
            shift 2 ;;
        -reset-val|--reset-val)
            RESET_VAL=$2
            CONFIG_LOG="$CONFIG_LOG $1 $2"
            shift 2 ;; 
        -reset-random-seed|--reset-random-seed)
            RESET_SEED=$2
            CONFIG_LOG="$CONFIG_LOG $1 $2"
            shift 2 ;; 
        -disable-trace-comp|--disable-trace-comp)
            TRACE_COMP=n 
            CONFIG_LOG="$CONFIG_LOG $1"
            shift ;; 
        -disable-simu-trace|--disable-simu-trace)
            SIMU_TRACE=n 
            CONFIG_LOG="$CONFIG_LOG $1"
            shift ;; 
        -output-pc-info|--output-pc-info) 
            OUTPUT_PC_INFO=y
            OUTPUT_UART_INFO=n
            CONFIG_LOG="$CONFIG_LOG $1"
            shift ;;
        -output-uart-info|--output-uart-info) 
            OUTPUT_UART_INFO=y 
            OUTPUT_PC_INFO=n
            CONFIG_LOG="$CONFIG_LOG $1"
            shift ;;
        -disable-read-miss|--disable-read-miss)
            READ_MISS_CHECK=n
            CONFIG_LOG="$CONFIG_LOG $1"
            shift ;;
        -disable-clk-time|--disable-clk-time)
            PRINT_CLK_TIME=n
            CONFIG_LOG="$CONFIG_LOG $1"
            shift ;; 
        -dump-vcd|--dump-vcd)
            DUMP_VCD=y
            DUMP_FST=n 
            CONFIG_LOG="$CONFIG_LOG $1" 
            shift ;;
        -dump-fst|--dump-fst)
            DUMP_VCD=n
            DUMP_FST=y 
            CONFIG_LOG="$CONFIG_LOG $1" 
            shift ;; 
        -slice-waveform|--slice-waveform) 
            SLICE_WAVEFORM=y 
            CONFIG_LOG="$CONFIG_LOG $1" 
            shift ;; 
        -waveform-slice-size|--waveform-slice-size) 
            WAVEFORM_SLICE_SIZE=$2
            CONFIG_LOG="$CONFIG_LOG $1 $2" 
            shift 2 ;;
        -slice-simu-trace|--slice-simu-trace) 
            SLICE_SIMU_TRACE=y 
            CONFIG_LOG="$CONFIG_LOG $1" 
            shift ;; 
        -trace-slice-size|--trace-slice-size) 
            TRACE_SLICE_SIZE=$2
            CONFIG_LOG="$CONFIG_LOG $1 $2" 
            shift 2 ;;
        -tail-waveform|--tail-waveform) 
            TAIL_WAVEFORM=y 
            CONFIG_LOG="$CONFIG_LOG $1" 
            shift ;; 
        -waveform-tail-size|--waveform-tail-size) 
            WAVEFORM_TAIL_SIZE=$2
            CONFIG_LOG="$CONFIG_LOG $1 $2" 
            shift 2 ;;
        -tail-simu-trace|--tail-simu-trace) 
            TAIL_SIMU_TRACE=y 
            CONFIG_LOG="$CONFIG_LOG $1" 
            shift ;; 
        -trace-tail-size|--trace-tail-size) 
            TRACE_TAIL_SIZE=$2
            CONFIG_LOG="$CONFIG_LOG $1 $2" 
            shift 2 ;;
        -h|-help|--help)
            usage 
            exit 0;;
        --|-)
            shift 
            break ;;
        *)
            usage 
            exit 0;;
    esac 
done 

#echo $TRACE_COMP
#echo $RUN_SOFTWARE 

mkdir -p ./obj 
mkdir -p ./log

OLD_IFS="$IFS"
IFS=","
SOFTWARE_LIST=($RUN_SOFTWARE)
IFS="$OLD_IFS"

for software in ${SOFTWARE_LIST[@]} 
do
    case $software in 
        func/func_lab3) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab4) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab6) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab7) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab8) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab9) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab14) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_lab16) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_advance) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty0) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty1_ld) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty2_ld_2) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty3_st) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty4_beq) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty5_jirl) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/test_cache_loop) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty6_beq_testbyp) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty7_beq_testbyp1cycle) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty8_mulw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty9_mulhwu) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty10_mulhw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty11_csrrd) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty12_csrwr) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty13_testbyp1cycle) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty14_csrrw1cycle) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty15_csrxchg) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty16_add) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty17_sub) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty18_addi) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty19_lu12i) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty20_pcaddu12i) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty21_slt) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty22_sltu) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty23_slti) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty24_sltui) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty25_and) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty26_or) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty27_nor) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty28_xor) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty29_andi) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty30_ori) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty31_xori) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty32_nop) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty33_sllw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty34_srlw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty35_sraw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty36_slliw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty37_srliw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty38_sraiw) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        func/func_uty39_beq) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            mkdir -p ./log/func
            ;;
        my_program)
            RUN_FUNC=n 
            RUN_C=y
            mkdir -p ./obj/
            mkdir -p ./log/
            ;;
        dhrystone) 
            RUN_FUNC=n
            RUN_C=y
            mkdir -p ./obj/
            mkdir -p ./log/
            ;;
        coremark) 
            RUN_FUNC=n
            RUN_C=y
            mkdir -p ./obj/
            mkdir -p ./log/
            ;;
        linux) 
            RUN_FUNC=n
            RUN_C=y
            mkdir -p ./obj/
            mkdir -p ./log/
            ;;
        *)
            echo "Software $software unavailable!!" 
            exit
            ;;
    esac 
done

CONFIG_SOFT="./config-software.mak"
CONFIG_LOG_FILE="./config.log"

if [ ! -f "$CONFIG_SOFT" ]; then 
    touch $CONFIG_SOFT 
else 
    rm $CONFIG_SOFT 
    touch $CONFIG_SOFT 
fi 

echo "RUN_SOFTWARE=$RUN_SOFTWARE" >> $CONFIG_SOFT 
echo "TRACE_COMP=$TRACE_COMP" >> $CONFIG_SOFT 
echo "SIMU_TRACE=$SIMU_TRACE" >> $CONFIG_SOFT 
echo "RUN_FUNC=$RUN_FUNC" >> $CONFIG_SOFT 
echo "RUN_C=$RUN_C" >> $CONFIG_SOFT 
echo "OUTPUT_PC_INFO=$OUTPUT_PC_INFO" >> $CONFIG_SOFT 
echo "OUTPUT_UART_INFO=$OUTPUT_UART_INFO" >> $CONFIG_SOFT 
echo "READ_MISS_CHECK=$READ_MISS_CHECK" >> $CONFIG_SOFT 
echo "THREAD=$THREAD" >> $CONFIG_SOFT 
echo "RESET_VAL=$RESET_VAL" >> $CONFIG_SOFT 
echo "RESET_SEED=$RESET_SEED" >> $CONFIG_SOFT
echo "PRINT_CLK_TIME=$PRINT_CLK_TIME" >> $CONFIG_SOFT 
echo "DUMP_VCD=$DUMP_VCD" >> $CONFIG_SOFT 
echo "DUMP_FST=$DUMP_FST" >> $CONFIG_SOFT 
echo "SLICE_WAVEFORM=$SLICE_WAVEFORM" >> $CONFIG_SOFT 
echo "WAVEFORM_SLICE_SIZE=$WAVEFORM_SLICE_SIZE" >> $CONFIG_SOFT
echo "SLICE_SIMU_TRACE=$SLICE_SIMU_TRACE" >> $CONFIG_SOFT
echo "TRACE_SLICE_SIZE=$TRACE_SLICE_SIZE" >> $CONFIG_SOFT
echo "TAIL_WAVEFORM=$TAIL_WAVEFORM" >> $CONFIG_SOFT 
echo "WAVEFORM_TAIL_SIZE=$WAVEFORM_TAIL_SIZE" >> $CONFIG_SOFT
echo "TAIL_SIMU_TRACE=$TAIL_SIMU_TRACE" >> $CONFIG_SOFT
echo "TRACE_TAIL_SIZE=$TRACE_TAIL_SIZE" >> $CONFIG_SOFT

if [ ! -f "$CONFIG_LOG_FILE" ]; then 
    touch $CONFIG_LOG_FILE 
else 
    rm $CONFIG_LOG_FILE 
    touch $CONFIG_LOG_FILE 
fi 

echo "#cpu7 sims configure log" >> $CONFIG_LOG_FILE
echo "#Configured with: $CONFIG_LOG" >> $CONFIG_LOG_FILE

