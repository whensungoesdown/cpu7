#pragma once
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h>
#include <verilated_threads.h>
#include <verilated_save.h>
#include "common.h"
#include "ram.h"
#include "time_limit.h"
#include "rand64.h"
#include "uart.h"
#ifndef RAND_TEST
#include "golden_trace.h"
#endif
class CpuTestbench:CpuTool
{
public:
    CpuRam* ram;
    CpuTimeLimit* time_limit;
    Rand64* rand64; 
    UARTSIM* uart;
    unsigned int uart_config;
    #ifdef DUMP_VCD
    VerilatedVcdC	*m_trace; 
    #endif 
    #ifdef DUMP_FST 
    VerilatedFstC	*m_trace;
    #endif
    #ifndef RAND_TEST
    GoldenTrace *golden_trace;
    #endif 
    unsigned long dump_next_start;
	unsigned long tail_base;
	char break_once = 0;
    
	void save_model(vluint64_t main_time, const char* top_filename) {
        #ifndef RAND_TEST
		VerilatedSave os;
		os.open(top_filename);
		os << main_time;
		os << *top;
		printf("save top model break point %ldns to %s\n", main_time, top_filename);
        #endif
	}

	void restore_model(vluint64_t* main_time, const char* top_filename) {
        #ifndef RAND_TEST
		VerilatedRestore os;
		os.open(top_filename);
		os >> *main_time;
		os >> *top;
		printf("restore top model break point %ldns from %s\n", *main_time, top_filename);
        #endif
	}

    CpuTestbench(int argc, char** argv, char** env, vluint64_t* main_time):CpuTool(nullptr)
    {
        m_trace = NULL;
        this->parse_args(argc,argv,env);
        rand64 = new Rand64(rand_path, result_flag_path); 
        top  = new Vtop;
		if (restore_bp_time != 0){
			restore_model(main_time, top_restore_bp_file);
			if (restore_bp_time != *main_time) {
				printf("Warning: restore_bp_time is not equal with %s's main_time\n", top_restore_bp_file);
			}
		}
        ram     = new CpuRam(top,rand64,*main_time);
        time_limit = new CpuTimeLimit();
        uart = new UARTSIM(0, uart_output_file); //output to terminal
        //uart->setup(0x000010); //param set 
        //uart->setup(288); //param set
        uart_config = 16;
        uart->setup(uart_config);
        #ifndef RAND_TEST
        golden_trace = new GoldenTrace(top,"./",simu_trace_file,uart_output_file,golden_trace_file);
        #endif
    }
    ~CpuTestbench()
    {
        // Final model cleanup
        top->final();
        //  Coverage analysis (since test passed)
        #if VM_COVERAGE
            Verilated::mkdir("logs");
            VerilatedCov::write("logs/coverage.dat");
        #endif
        // Destroy model
        delete time_limit;time_limit = nullptr;
        delete ram;    ram = nullptr;
        delete top;    top = nullptr;
    }
    // Time passes
    inline int eval(vluint64_t& main_time){
        top->eval();
        char waveform_name[128];
        if(m_trace != NULL){
            #ifdef SLICE_WAVEFORM 
				#ifdef TAIL_WAVEFORM
					if (main_time >= tail_base+WAVEFORM_TAIL_SIZE) {
						tail_base += WAVEFORM_TAIL_SIZE;
					}
                	if(main_time >= dump_next_start) {
                	    close();
                	    dump_next_start += WAVEFORM_SLICE_SIZE; 
                	    #ifdef DUMP_VCD
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", main_time - tail_base, dump_next_start - tail_base);
                	    #endif
                	    #ifdef DUMP_fst
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", main_time - tail_base, dump_next_start - tail_base);
                	    #endif
                	    opentrace(waveform_name);
                	}
				#else
                	if(main_time >= dump_next_start) {
                	    close();
                	    dump_next_start += WAVEFORM_SLICE_SIZE; 
                	    #ifdef DUMP_VCD
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", main_time, dump_next_start);
                	    #endif
                	    #ifdef DUMP_fst
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", main_time, dump_next_start);
                	    #endif
                	    opentrace(waveform_name);
                	}
				#endif
            #endif
			#ifdef TAIL_WAVEFORM
			if (main_time >= tail_base+WAVEFORM_TAIL_SIZE) {
				tail_base += WAVEFORM_TAIL_SIZE;
				close();
                #ifdef DUMP_VCD 
                opentrace("./logs/simu_trace.vcd");
                #endif 
                #ifdef DUMP_FST
                opentrace("./logs/simu_trace.fst"); 
                #endif 
			}
			#endif
            m_trace->dump(main_time);
        }
        else if (main_time >= dump_delay && dump_trace ){  
            #ifdef SLICE_WAVEFORM 
            	#ifdef TAIL_WAVEFORM
                	dump_next_start = dump_delay+WAVEFORM_SLICE_SIZE;
					tail_base = dump_delay;
                	#ifdef DUMP_VCD
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", dump_delay - tail_base, dump_next_start - tail_base);
                	#endif
                	#ifdef DUMP_fst
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", dump_delay - tail_base, dump_next_start - tail_base);
                	#endif
                	opentrace(waveform_name);
				#else
                	dump_next_start = dump_delay+WAVEFORM_SLICE_SIZE;
                	#ifdef DUMP_VCD
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", dump_delay, dump_next_start);
                	#endif
                	#ifdef DUMP_fst
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", dump_delay, dump_next_start);
                	#endif
                	opentrace(waveform_name);
				#endif
			#else
				tail_base = dump_delay;
                #ifdef DUMP_VCD 
                opentrace("./logs/simu_trace.vcd");
                #endif 
                #ifdef DUMP_FST
                opentrace("./logs/simu_trace.fst"); 
                #endif 
            #endif
            printf("Dump Start at %d ns\n",main_time,dump_delay);
            m_trace->dump(main_time);
        }
    
    
    return Verilated::gotFinish();}
    void display_exist_cause(vluint64_t& main_time,int emask){
        if(simu_quiet)return;
        fprintf(stderr,"\n");
        fprintf(stderr,"Terminated at %lu ns.\n",main_time);
        if(emask&status_exit){
            fprintf(stderr,"Test exit.\n");
            if(emask&status_time_limit){
                fprintf(stderr,"Time limit exceeded.\n");
            }
            if(emask&status_test_end){
                fprintf(stderr,"Reached test end PC.\n");
            }
        }
        if(emask&status_trace_err){
            fprintf(stderr,"%s Error(Code:0x%x)\n",
                (emask&status_trace_err_pc)?
                    (emask&status_trace_err_rf)?"Both":"Path":
                    (emask&status_trace_err_rf)?"Data":"Perf"
                ,emask);
        }
        if(emask&status_unhandled){
            fprintf(stderr,"Reached unhandled situation.\n");
        }
    }
    void simulate(vluint64_t& main_time, int* nStatus){
        if(!simu_quiet)fprintf(stderr,"Verilator Simulation Start.\n");
        int emask = status_call_finish;
        vluint8_t& clock = top->aclk;
        vluint8_t& reset = top->aresetn;
        long long clock_total = 0;
        bool uart_div_set = false;
        bool div_reinit = false;
        int p_config;
        unsigned int div_val_1 = 0;
        unsigned int div_val_2 = 0;
        unsigned int div_val_3 = 0;
        static const int reset_valid = 0;
        #define EVAL ((clock=!clock),main_time+=1,this->eval(main_time))
		if (restore_bp_time == 0){
        	reset = reset_valid;
        	clock = 0;
        	top->enable_delay = simu_bus_delay;
        	top->random_seed = simu_bus_delay_random_seed;
            //printf("random seed is %d\n", simu_bus_delay_random_seed);
        	for(int i=0;i<10;i+=1){if(EVAL)break;}
		}
        clock = 0;
        top->enable_delay = simu_bus_delay;
        top->random_seed = simu_bus_delay_random_seed;
        if(!EVAL){
            reset = !reset_valid;
            emask = 0;
            #ifdef RAND_TEST
            int init_error = rand64->init_all();
            if (init_error) {
                printf("RAND TEST INIT FAILED\n");
                return ;
            }
            #endif
            printf("Start\n");
            while(true){
                // Simulate until exit
				if ((main_time <= (save_bp_time+1) && main_time >= (save_bp_time-1)) && (break_once == 0)) {
					if (main_time != save_bp_time) {
						printf("Warning: real break point main time is %ld\n", main_time);
					}
					ram->breakpoint_save(main_time, ram_save_bp_file);
					save_model(main_time, top_save_bp_file);
					printf("save break point over!\n");
					break_once = 1;
				}
                emask|= ram->process(main_time);
                //uart receive
                top->uart_rx = (*uart)(top->uart_tx);
                //uart reconfig
                if(top->uart_enab && top->uart_rw) {
                    switch(top->uart_addr) {
                        case 0: 
                            if(uart_div_set == true) {
                                div_val_1 = top->uart_datai;
                                div_reinit = true;
                            }
                            break;
                        case 1:
                            if(uart_div_set == true) {
                                div_val_2 = top->uart_datai << 8;
                                div_reinit = true;
                            }
                            break;
                        case 2:
                            if(uart_div_set == true) {
                                div_val_3 = top->uart_datai << 16;
                                div_reinit = true;
                            }
                            break;
                        case 3:
                            if(uart_div_set == false && (top->uart_datai & 0x80) == 0x80) {
                                uart_div_set = true;
                            }
                            else if(uart_div_set == true && (top->uart_datai & 0x80) == 0) {
                                if (div_reinit == true) {
                                    uart_config = (uart_config & 0xff000000) | ((div_val_1 + div_val_2 + div_val_3) * 16);
                                    div_reinit = false;
                                }
                                uart_div_set = false;
                            }
                            switch (top->uart_datai & 0x30) {
                                case 0x00: 
                                    p_config = 0x0;
                                    break;
                                case 0x10:
                                    p_config = 0x1;
                                    break;
                                case 0x20:
                                    p_config = 0x3;
                                    break;
                                case 0x30:
                                    p_config = 0x2;
                                    break;
                                default:
                                    p_config = 0x0;
                            }
                            uart_config = (uart_config & 0x00ffffff) | ((3 - (top->uart_datai & 0x3)) << 28) 
                                                                     | ((top->uart_datai & 0x4) << 25)  
                                                                     | ((top->uart_datai & 0x8) << 23)  
                                                                     | (p_config << 24);
                            /*
                            //set bit
                            uart_config = (uart_config & 0x0fffffff) | ((3 - (top->datai & 0x3)) << 28);
                            //set stop
                            uart_config = (uart_config & 0xf7ffffff) | ((top->datai & 0x4) << 25);
                            //set parity
                            uart_config = (uart_config & 0xfbffffff) | ((top->datai & 0x8) << 23);
                            //set fixdp and evenp
                            uart_config = (uart_config & 0xfcffffff) | (p_config << 24);
                            */
                            //debug
                            //printf("uart datai is %x\n", top->uart_datai);
                            //printf("uart config is %x\n", uart_config);
                            uart->setup(uart_config);
                            break;
                    }
                }
                if(EVAL)break;
                emask|= time_limit->process(main_time);
                #ifndef RAND_TEST
                emask|= golden_trace->process(main_time);
                #endif
                if(EVAL)break;
                if(emask)break;
                clock_total += 1;
            }
        }
        printf("total clock is %lld\n", clock_total);

	// uty: test
	printf ("uty: test golden_trace->reg[5]: %llx\n", golden_trace->reg[5]);

	if (0x5a == golden_trace->reg[5])
	{
		*nStatus = 0;
	}
	else
	{
		*nStatus = -1;
	}


        EVAL;
        #undef EVAL
        display_exist_cause(main_time,emask);
        close();
    }

    virtual	void opentrace(const char *wavename) {
		if (!m_trace) { 
            #ifdef DUMP_VCD 
			m_trace = new VerilatedVcdC; 
            #endif 
            #ifdef DUMP_FST 
			m_trace = new VerilatedFstC; 
            #endif
			top->trace(m_trace, 99);
			m_trace->open(wavename);
		}
	}

	// Close a trace file
	virtual void close(void) {
		if (m_trace) {
            m_trace->flush();
			m_trace->close();
			m_trace = NULL;
		}
	}


};
