include ../../../../sims/verilator/run_func/config-software.mak

obj_path = ../obj

inst_srcs = $(wildcard ../inst/*.S)
srcs = $(wildcard *.S)
raws = $(patsubst %.S, ${obj_path}/%.s, $(srcs))
objs = $(patsubst %.S, ${obj_path}/%.o, $(srcs))
GCC_BIN = ../../../../toolchains/loongarch32_gnu/install/bin


libinst.a: $(objs)
	${GCC_BIN}/loongarch32-unknown-elf-ar -cr  $@ $? && mv libinst.a ${obj_path}

#raw: $(raws)
#${obj_path}/%.s:%.S
raw: $(inst_srcs)
ifeq ('${TRACE_COMP}', 'y')
#	${GCC_BIN}/loongarch32-unknown-elf-gcc \
		-I../include -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000 -DGUEST \
		-DENABLE_TRACE -save-temps $< -o $@ && rm *.o 
	${GCC_BIN}/loongarch32-unknown-elf-gcc \
		-I../include -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000 -DGUEST \
		-DENABLE_TRACE -save-temps $? && rm *.o 
else 
#	${GCC_BIN}/loongarch32-unknown-elf-gcc \
		-I../include -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000 -DGUEST \
		-save-temps $< -o $@ && rm *.o 
	${GCC_BIN}/loongarch32-unknown-elf-gcc \
		-I../include -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000 -DGUEST \
		-save-temps $? && rm *.o 
endif

clean:
	rm -rf ${obj_path}/*.s ${obj_path}/*.o ${obj_path}/libinst.a ${obj_path}/a.out

#print:
#	@echo $(srcs)
#	@echo $(objs)

$(objs):${obj_path}/%.o:${obj_path}/%.s
	${GCC_BIN}/loongarch32-unknown-elf-as -mabi=ilp32 -o $@ $< 
