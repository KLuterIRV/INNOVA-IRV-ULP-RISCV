# SPDX-FileCopyrightText: © 2024 KLuterIRV
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


# UART configuration used by the RTL.
# RTL uses CLK_FREQ_HZ=60_000_000 and BAUD_RATE=115200.
# CLKS_PER_BIT = round(60_000_000 / 115200) = 521.
CLKS_PER_BIT = 521


def set_uart_rx(dut, bit_value: int, boot_mode: int = 1):
    """
    Drive Tiny Tapeout input pins.

    ui_in[0] = boot_mode
    ui_in[1] = uart0_rx
    """
    value = 0

    if boot_mode:
        value |= 0x01

    if bit_value:
        value |= 0x02

    dut.ui_in.value = value


async def uart_send_bit(dut, bit_value: int):
    """
    Send one UART bit on ui_in[1].

    The UART line must hold the bit value for CLKS_PER_BIT clock cycles.
    """
    set_uart_rx(dut, bit_value, boot_mode=1)
    await ClockCycles(dut.clk, CLKS_PER_BIT)


async def uart_send_byte(dut, data: int):
    """
    Send one UART byte using 8N1 format:
      start bit = 0
      8 data bits, LSB first
      stop bit = 1
    """
    # Start bit
    await uart_send_bit(dut, 0)

    # Data bits, LSB first
    for i in range(8):
        await uart_send_bit(dut, (data >> i) & 1)

    # Stop bit
    await uart_send_bit(dut, 1)


async def uart_send_stream(dut, data):
    """
    Send a sequence of bytes through UART RX.
    """
    for byte in data:
        await uart_send_byte(dut, byte)


@cocotb.test()
async def test_project(dut):
    """
    Test the Minimal RV32E SoC through the Tiny Tapeout wrapper.

    Test sequence:
      1. Enable boot mode.
      2. Send a small program through UART RX.
      3. Wait for loader_done_debug on uio_out[2].
      4. Let the RV32E core execute.
      5. Check that the seven-segment/GPIO output shows ASCII 'H'.

    Expected result:
      uo_out = 0x76
      uio_out[1] = halted_debug
      uio_out[2] = loader_done_debug
    """

    dut._log.info("Starting Minimal RV32E SoC UART loader test")

    # Start clock.
    # The exact simulation period is not critical because UART timing is
    # generated in clock cycles using CLKS_PER_BIT.
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Initial values.
    dut.ena.value = 1
    dut.uio_in.value = 0

    # boot_mode=1, uart0_rx idle high.
    set_uart_rx(dut, 1, boot_mode=1)

    # Reset.
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 20)

    dut._log.info("Sending program through UART loader")

    # Program:
    #   lui   x1, 0x10000       ; x1 = 0x1000_0000
    #   addi  x2, x0, 'H'       ; x2 = 0x48
    #   sw    x2, 4(x1)         ; SEVENSEG_DATA = 'H'
    #   addi  x2, x0, 3         ; enable=1, ascii_mode=1
    #   sw    x2, 8(x1)         ; SEVENSEG_CTRL = 0x03
    #   ebreak
    #
    # Hex:
    #   100000B7
    #   04800113
    #   0020A223
    #   00300113
    #   0020A423
    #   00100073
    #
    # UART loader protocol:
    #   0x55
    #   N_WORDS
    #   words little-endian
    loader_stream = [
        0x55,
        0x06,

        0xB7, 0x00, 0x00, 0x10,
        0x13, 0x01, 0x80, 0x04,
        0x23, 0xA2, 0x20, 0x00,
        0x13, 0x01, 0x30, 0x00,
        0x23, 0xA4, 0x20, 0x00,
        0x73, 0x00, 0x10, 0x00,
    ]

    await uart_send_stream(dut, loader_stream)

    dut._log.info("Waiting for loader_done_debug")

    # uio_out[2] = loader_done_debug
    for _ in range(2000):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x04:
            break
    else:
        raise AssertionError("loader_done_debug was not asserted")

    dut._log.info("Loader finished. Waiting for core execution")

    # Wait for the core to execute the loaded program.
    for _ in range(200):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x02:
            break

    # uio_out[1] = halted_debug
    assert int(dut.uio_out.value) & 0x02, "Core did not halt on ebreak"

    # ASCII 'H' on seven-segment active-high = 0x76.
    assert int(dut.uo_out.value) == 0x76, (
        f"Expected uo_out=0x76 for 'H', got 0x{int(dut.uo_out.value):02X}"
    )

    dut._log.info("TEST PASS: UART loader programmed RV32E core and displayed 'H'")