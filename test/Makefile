# Tiny Tapeout / GF180 cocotb test Makefile

SIM ?= icarus
FST ?= -fst

TOPLEVEL_LANG ?= verilog

SRC_DIR = $(PWD)/../src

PROJECT_SOURCES = \
	top/tt_um_kluterirv_rv32e_core.v \
	core/irv_regfile.v \
	core/irv_alu.v \
	core/irv_decoder.v \
	soc/irv_peripheral_bus.v \
	peripherals/gpio0.v \
	peripherals/uart0.v \
	peripherals/i2c0.v \
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

# Gate-level netlist copied by the Tiny Tapeout workflow.
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

# Simple GF180 standard-cell models for Icarus GL simulation.
VERILOG_SOURCES += $(PWD)/models/gf180/gf180mcu_fd_sc_mcu7t5v0_simple_gl.v

# SRAM macro behavioral model.
VERILOG_SOURCES += $(SRC_DIR)/macro_blackboxes/gf180mcu_fd_ip_sram__sram64x8m8wm1_blackbox.v

endif

# Allow includes from src/
COMPILE_ARGS += -I$(SRC_DIR)

# Testbench wrapper
VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb

# Python cocotb module: test/test.py
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim
