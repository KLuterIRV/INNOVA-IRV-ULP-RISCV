TOPLEVEL_LANG = verilog
TOPLEVEL = tt_um_kluterirv_rv32e_core
MODULE = test_rv32e_sram

SIM ?= verilator

VERILOG_SOURCES += $(PWD)/../src/tt_um_kluterirv_rv32e_core.v
VERILOG_SOURCES += $(PWD)/../src/macro_blackboxes/gf180mcu_fd_ip_sram__sram64x8m8wm1_blackbox.v

COMPILE_ARGS += -DSIM
COMPILE_ARGS += -Wno-fatal
COMPILE_ARGS += -Wno-UNOPTFLAT
COMPILE_ARGS += -Wno-UNUSED
COMPILE_ARGS += -Wno-WIDTH

include $(shell cocotb-config --makefiles)/Makefile.sim