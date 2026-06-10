SIM ?= icarus
FST ?= -fst

TOPLEVEL_LANG ?= verilog

SRC_DIR = $(PWD)/../src

PROJECT_SOURCES = \
	tt_um_kluterirv_rv32e_core.v \
	macro_blackboxes/gf180mcu_fd_ip_sram__sram64x8m8wm1_blackbox.v

ifneq ($(GATES),yes)

# RTL simulation
SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
COMPILE_ARGS += -DSIM

else

# Gate-level simulation
SIM_BUILD = sim_build/gl
COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DSIM

# Gate-level netlist is copied by the Tiny Tapeout workflow.
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow includes from src/
COMPILE_ARGS += -I$(SRC_DIR)

# Testbench wrapper
VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb

# Python cocotb module: test/test.py
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim