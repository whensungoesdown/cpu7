###################################################################
# Project Configuration: 
# 
# Specify the name of the design (project), the Quartus II Settings
# File (.qsf), and the list of source files used.
###################################################################

PROJECT = soc_top
SOURCE_FILES =  ../../IP/myCPU/alu.v \
                ../../IP/myCPU/atom_alu.v \
                ../../IP/myCPU/branch.v \
                ../../IP/myCPU/cache_interface.v \
                ../../IP/myCPU/cache.vh \
                ../../IP/myCPU/common.vh \
                ../../IP/myCPU/core_top.v \
                ../../IP/myCPU/cpu7_csr_byplog.v \
                ../../IP/myCPU/cpu7_csr.v \
                ../../IP/myCPU/cpu7_exu_eclbyplog_rs1.v \
                ../../IP/myCPU/cpu7_exu_eclbyplog.v \
                ../../IP/myCPU/cpu7_exu_ecl.v \
                ../../IP/myCPU/cpu7_exu.v \
                ../../IP/myCPU/cpu7_ifu_dec.v \
                ../../IP/myCPU/cpu7_ifu_fdp.v \
                ../../IP/myCPU/cpu7_ifu_imd.v \
                ../../IP/myCPU/cpu7_ifu_incr30.v \
                ../../IP/myCPU/cpu7_ifu.v \
                ../../IP/myCPU/cpu7_lsu.v \
                ../../IP/myCPU/cpu7.v \
                ../../IP/myCPU/dcache.v \
                ../../IP/myCPU/decoded.vh \
                ../../IP/myCPU/decoder.v \
                ../../IP/myCPU/frontend_rams.vh \
                ../../IP/myCPU/icache.v \
                ../../IP/myCPU/lru_unit.v \
                ../../IP/myCPU/mul32x32.v \
                ../../IP/myCPU/mul64x64.v \
                ../../IP/myCPU/mycpu_top.v \
                ../../IP/myCPU/prefetch_d.v \
                ../../IP/myCPU/ram_wrapper.v \
                ../../IP/myCPU/reg_file.v \
                ../../IP/myCPU/swrvr_clib.v \
                ../../IP/myCPU/swrvr_dlib.v \
                ../../IP/myCPU/tlb_defines.vh \
		../../chip/soc_demo/sim/soc_top.v


SOURCE_FILES_PARAMETER = $(addprefix --source=, $(SOURCE_FILES))
ASSIGNMENT_FILES = soc_top.qpf soc_top.qsf 


FAMILY = "Cyclone IV E"
PART = EP4CE6E22C8
BOARD = c4e6e10pins
###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
###################################################################

all: smart.log $(PROJECT).asm.rpt $(PROJECT).sta.rpt 

clean:
	rm -rf *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof db

map: smart.log $(PROJECT).map.rpt
fit: smart.log $(PROJECT).fit.rpt
asm: smart.log $(PROJECT).asm.rpt
sta: smart.log $(PROJECT).sta.rpt
smart: smart.log

###################################################################
# Executable Configuration
###################################################################

# Quartus 19.1 Prime lite doesn't support CycloneII
# To compile, put CycloneIV here
#MAP_ARGS = --family=CycloneII $(SOURCE_FILES_PARAMETER)
#FIT_ARGS = --part=EP2C5T144C8i
MAP_ARGS = --family=$(FAMILY) $(SOURCE_FILES_PARAMETER)
FIT_ARGS = --part=$(PART)
ASM_ARGS =
STA_ARGS =

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

$(PROJECT).map.rpt: map.chg $(SOURCE_FILES) 
	quartus_map $(MAP_ARGS) $(PROJECT)
	$(STAMP) fit.chg

$(PROJECT).fit.rpt: fit.chg $(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) asm.chg
	$(STAMP) sta.chg

$(PROJECT).asm.rpt: asm.chg $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: sta.chg $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT) 

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	quartus_sh --prepare $(PROJECT)
	-cat $(BOARD) >> $(PROJECT).qsf

map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg
