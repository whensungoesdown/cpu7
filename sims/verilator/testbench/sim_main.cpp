#include <verilated.h>

#include "testbench.h" 

#include <stdio.h>
#include <sys/time.h>


// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
double sc_time_stamp() {return main_time;}

void init_verilator(int argc, char** argv, char** env){
    if (0 && argc && argv && env) {}
    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs
    Verilated::debug(0);
    
    // Randomization reset policy
    // May be overridden by commandArgs
    Verilated::randReset(RESET_VAL);

    //if INIT_VAL is 2, set random seed
    Verilated::randSeed(RESET_SEED);

    // Verilator must compute traced signals
    Verilated::traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");
}



int main(int argc, char** argv, char** env) {
    int testcase_status;

    init_verilator(argc,argv,env);
    CpuTestbench* tb = new CpuTestbench(argc,argv,env,&main_time); 

    struct timeval start, end;
    gettimeofday(&start, NULL);

    tb->simulate(main_time, &testcase_status); 

    gettimeofday(&end, NULL);
    long long total_time = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_usec - start.tv_usec); 
    printf("total time is %lld us\n", total_time);

    if (0 == testcase_status)
    {
	    printf("\033[0;32m");
	    printf("Test case passed!\n");
	    printf("**************************************************\n");	           
	    printf("*                                                *\n");
	    printf("*      * * *       *        * * *     * * *      *\n");
	    printf("*      *    *     * *      *         *           *\n");
	    printf("*      * * *     *   *      * * *     * * *      *\n");
	    printf("*      *        * * * *          *         *     *\n");
	    printf("*      *       *       *    * * *     * * *      *\n");
	    printf("*                                                *\n");
	    printf("**************************************************\n");	           
	    printf("\n");
	    printf("\033[0m");

	    delete tb;
	    exit(0);
    }
    else
    {
	    printf("\033[0;31m");
	    printf("Test case failed!\n");
	    printf("**************************************************\n");	           
	    printf("*                                                *\n");
	    printf("*      * * *       *         ***      *          *\n");
	    printf("*      *          * *         *       *          *\n");
	    printf("*      * * *     *   *        *       *          *\n");
	    printf("*      *        * * * *       *       *          *\n");
	    printf("*      *       *       *     ***      * * *      *\n");
	    printf("*                                                *\n");
	    printf("**************************************************\n");	           
	    printf("\n");
	    printf("\033[0m");

	    delete tb;
	    exit(-1);
    }

}
