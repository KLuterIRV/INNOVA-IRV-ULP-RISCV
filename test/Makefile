TOPLEVEL_LANG = verilog
SIM ?= verilator

TOPLEVEL = tt_um_kluterirv_rv32e_core
MODULE = test_rv32e_sram

PWD := $(shell pwd)

VERILOG_SOURCES = \
	$(PWD)/../src/tt_um_kluterirv_rv32e_core.v \
	$(PWD)/../src/macro_blackboxes/gf180mcu_fd_ip_sram__sram64x8m8wm1_blackbox.v

# Use EXTRA_ARGS instead of COMPILE_ARGS for better compatibility
# with older cocotb/verilator Makefile flows.
EXTRA_ARGS += -DSIM
EXTRA_ARGS += -Wno-fatal
EXTRA_ARGS += -Wno-UNOPTFLAT
EXTRA_ARGS += -Wno-UNUSED
EXTRA_ARGS += -Wno-WIDTH
EXTRA_ARGS += -Wno-DECLFILENAME

# Generate waveform artifact if the TT workflow uploads it.
EXTRA_ARGS += --trace

# Keep build output inside test/
SIM_BUILD = sim_build

include $(shell cocotb-config --makefiles)/Makefile.sim