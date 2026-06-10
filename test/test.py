# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def write_byte(dut, addr, data):
    """
    Programming mode:
      rst_n = 0
      ui_in[0]   = write enable
      ui_in[7:1] = byte address
      uio_in     = byte data
    """
    dut.ui_in.value = ((addr & 0x7F) << 1) | 1
    dut.uio_in.value = data & 0xFF
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = ((addr & 0x7F) << 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start RV32E SRAM boot test")

    # Keep the template clock style.
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset / programming mode
    dut._log.info("Reset and program SRAM")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    # Program:
    #   addi x1, x0, 0x55      0x05500093
    #   lui  x2, 0x10000       0x10000137
    #   sw   x1, 0(x2)         0x00112023
    #   ebreak                 0x00100073
    #
    # Expected:
    #   memory-mapped store writes 0x55 to uo_out.
    #
    # Little-endian byte order.
    program = [
        0x93, 0x00, 0x50, 0x05,
        0x37, 0x01, 0x00, 0x10,
        0x23, 0x20, 0x11, 0x00,
        0x73, 0x00, 0x10, 0x00,
    ]

    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)

    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 5)

    # Run mode
    dut._log.info("Release reset and execute program")
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 120)

    observed = int(dut.uo_out.value)
    dut._log.info(f"uo_out = 0x{observed:02x}")

    assert observed == 0x55, f"Expected uo_out=0x55, got 0x{observed:02x}"