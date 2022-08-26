#pragma once

#include "Vsimu_top.h"
#include "Vsimu_top___024root.h"
#include <cstring>
class CpuTool
{
public:
    typedef Vsimu_top Vtop;
    Vtop* top;
    static const int status_cause     = 0xff;
    static const int status_trace_err    = 0x700;
    static const int status_trace_err_rf = 0x100;
    static const int status_trace_err_pc = 0x200;
    static const int status_perf_err     = 0x400;
    
    static const int status_exit         = 0x1f000;
    static const int status_call_finish  = 0x1000;
    static const int status_uart_exit    = 0x2000;
    static const int status_test_end     = 0x4000;
    static const int status_time_limit   = 0x8000;
    static const int status_test_wait    = 0x10000;
    
    static const int status_unhandled = 0x60000;
    static const int status_unhandled_ex_code = 0x20000;
    static const int status_unhandled_syscall = 0x40000;
    
    static int simu_quiet;
    static int simu_user;
    static int simu_dev;
    static int simu_wait;
    static int simu_bus_delay;
    static int simu_bus_delay_random_seed;

	static int save_bp_time;
	static int restore_bp_time;
	const static char* ram_save_bp_file;
	const static char* top_save_bp_file;
	const static char* ram_restore_bp_file;
	const static char* top_restore_bp_file;
    
    static int time_limit;
    static int time_check;
    
    static int dump_pc_trace;
    static int dump_rf_trace;
    static int rf_trace_no_repeat;
    static int comp_pc_trace;
    static int comp_rf_trace;
    static int dump_delay;
    static int dump_trace;
    const static char* ram_file;
    const static char* rand_path;
    const static char* result_flag_path;
    const static char* pc_trace_ifile;
    const static char* pc_trace_ofile;
    const static char* rf_trace_ifile;
    const static char* rf_trace_ofile;
    const static char* simu_trace_file;
    const static char* uart_output_file;
    const static char* golden_trace_file;
    CpuTool(Vtop* top){this->top = top;}
    void parse_args(int argc, char** argv, char** env){
        #define PARSE_FLAG(val,label) if(strcmp(argv[i],label)==0){val = i+1>=argc || strcmp(argv[i+1],"0")!=0;}
        #define PARSE_STR(val,label) if(i+1<argc && strcmp(argv[i],label)==0){val = argv[i+1];}
        #define PARSE_INT(val,label) if(i+1<argc && strcmp(argv[i],label)==0){sscanf(argv[i+1],"%d",&val);}
        for(int i=1;i<argc;i+=1){
            PARSE_FLAG(simu_quiet,"--simu-quiet" )
            PARSE_FLAG(simu_user ,"--simu-user")
            PARSE_FLAG(simu_dev  ,"--simu-dev"   )
            PARSE_FLAG(simu_wait ,"--simu-wait"  )
            PARSE_FLAG(simu_bus_delay ,"--simu-bus-delay")
            PARSE_INT(simu_bus_delay_random_seed, "--simu-bus-delay-random-seed")
            
            PARSE_INT (time_limit,"--time-limit")
            PARSE_FLAG(time_check,"--time-check")

			PARSE_INT(save_bp_time,"--save-bp-time")
			PARSE_STR(ram_save_bp_file,"--ram-save-bp-file")
			PARSE_STR(top_save_bp_file,"--top-save-bp-file")
			PARSE_INT(restore_bp_time,"--restore-bp-time")
			PARSE_STR(ram_restore_bp_file,"--ram-restore-bp-file")
			PARSE_STR(top_restore_bp_file,"--top-restore-bp-file")
            
            PARSE_FLAG(dump_pc_trace,"--dump-pc-trace")
            PARSE_FLAG(dump_rf_trace,"--dump-rf-trace")
            PARSE_FLAG(comp_pc_trace,"--comp-pc-trace")
            PARSE_FLAG(comp_rf_trace,"--comp-rf-trace")

            PARSE_INT (dump_delay,"--dump-delay")
            PARSE_INT (dump_trace,"--dump-trace")
            
            PARSE_FLAG(rf_trace_no_repeat,"--rf-trace-no-repeat")
            
            PARSE_STR (ram_file,"--ram")
            PARSE_STR (rand_path,"--rand-path")
            PARSE_STR (result_flag_path, "--result-flag-path")
            
            PARSE_STR (pc_trace_ofile,"--pc-trace-o")
            PARSE_STR (rf_trace_ofile,"--rf-trace-o")
            PARSE_STR (pc_trace_ifile,"--pc-trace-i")
            PARSE_STR (rf_trace_ifile,"--rf-trace-i")

            PARSE_STR (simu_trace_file,"--simu_trace")
            PARSE_STR (uart_output_file, "--uart_output")
            PARSE_STR (golden_trace_file,"--golden_trace")
        }
        #undef PARSE_INT
        #undef PARSE_STR
        #undef PARSE_FLAG
    }
};
int endswith(const char* s,const char* suffix){
    int n = strlen(s);
    int m = strlen(suffix);
    if(n<m)return 0;
    else return strcmp(s+n-m,suffix)==0;
}
int CpuTool::simu_quiet = 0;
int CpuTool::simu_user = 0;
int CpuTool::simu_dev  = 1;
int CpuTool::simu_wait = 0;
int CpuTool::simu_bus_delay = 0;
int CpuTool::simu_bus_delay_random_seed = 0x5500ff;

int CpuTool::time_limit = 30000;
int CpuTool::time_check = 0;

int CpuTool::save_bp_time = 0;
int CpuTool::restore_bp_time = 0;

int CpuTool::dump_pc_trace = 0;
int CpuTool::dump_rf_trace = 0;
int CpuTool::comp_pc_trace = 0;
int CpuTool::comp_rf_trace = 0;

int CpuTool::dump_delay = 0;
int CpuTool::dump_trace = 0;

int CpuTool::rf_trace_no_repeat = 0;

const char ram_file_default[] = "ram.dat";
const char rand_path_default[] = "RES/res2020_mulh_0/";
const char result_flag_path_default[] = "RES/result_flag.txt";
const char simu_trace_file_default[] = "./simu_trace.txt";
const char golden_trace_file_default[] = "./golden_trace.txt";
const char uart_output_file_default[] = "./uart_output.txt";
const char null_file[] = " ";
const char* CpuTool::ram_file = ram_file_default;
const char* CpuTool::rand_path = rand_path_default;
const char* CpuTool::result_flag_path = result_flag_path_default;
const char* CpuTool::simu_trace_file = simu_trace_file_default;
const char* CpuTool::uart_output_file = uart_output_file_default;
const char* CpuTool::golden_trace_file = golden_trace_file_default;
const char* CpuTool::ram_save_bp_file = null_file;
const char* CpuTool::top_save_bp_file = null_file;
const char* CpuTool::ram_restore_bp_file = null_file;
const char* CpuTool::top_restore_bp_file = null_file;

const char pc_trace_ifile_default[] = "pc_trace.gz";
const char pc_trace_ofile_default[] = "logs/pc_trace.gz";
const char rf_trace_ifile_default[] = "rf_trace.txt";
const char rf_trace_ofile_default[] = "logs/rf_trace.txt";

const char* CpuTool::pc_trace_ifile = pc_trace_ifile_default;
const char* CpuTool::pc_trace_ofile = pc_trace_ofile_default;
const char* CpuTool::rf_trace_ifile = rf_trace_ifile_default;
const char* CpuTool::rf_trace_ofile = rf_trace_ofile_default;
