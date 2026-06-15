import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


CLKS_PER_BIT = 8


async def write_byte(dut, addr, data):
    dut.ui_in.value = ((addr & 0x7F) << 1) | 1
    dut.uio_in.value = data & 0xFF
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = ((addr & 0x7F) << 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


def set_uart_rx_pin(dut, bit):
    value = int(dut.uio_in.value) if dut.uio_in.value.is_resolvable else 0

    if bit:
        value |= 0x02      # uio_in[1] = 1
    else:
        value &= ~0x02     # uio_in[1] = 0

    dut.uio_in.value = value


async def uart_rx_send_byte(dut, value):
    # UART frame on uio_in[1]:
    # idle high, start low, 8 data bits LSB first, stop high.

    set_uart_rx_pin(dut, 1)
    await ClockCycles(dut.clk, CLKS_PER_BIT * 3)

    # Start bit
    set_uart_rx_pin(dut, 0)
    await ClockCycles(dut.clk, CLKS_PER_BIT)

    # Data bits
    for i in range(8):
        set_uart_rx_pin(dut, (value >> i) & 1)
        await ClockCycles(dut.clk, CLKS_PER_BIT)

    # Stop bit
    set_uart_rx_pin(dut, 1)
    await ClockCycles(dut.clk, CLKS_PER_BIT)

    # Idle gap
    set_uart_rx_pin(dut, 1)
    await ClockCycles(dut.clk, CLKS_PER_BIT * 3)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start RV32E UART0 RX via LW test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x02  # UART RX idle high on uio_in[1]
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    # Program:
    #   x2 = 0x1000_0000
    #   wait with NOPs while cocotb sends UART byte
    #   x4 = UART0 RX data using LW
    #   GPIO output = x4
    #   UART0 TX sends x4
    #   halt
    program = [
        # lui x2, 0x10000
        0x37, 0x01, 0x00, 0x10,
    ]

    # 27 NOPs. The current SRAM program limit is 128 bytes.
    # Total program size:
    # 1 LUI + 27 NOP + LW + SW GPIO + SW UART + EBREAK = 32 instructions.
    for _ in range(27):
        program += [
            # nop = addi x0, x0, 0
            0x13, 0x00, 0x00, 0x00,
        ]

    program += [
        # lw x4, 12(x2)
        # UART0 RX data register at 0x1000_000C
        0x03, 0x22, 0xc1, 0x00,

        # sw x4, 0(x2)
        # GPIO output register -> uo_out = received byte
        0x23, 0x20, 0x41, 0x00,

        # sw x4, 4(x2)
        # UART0 TX data register -> transmit received byte
        0x23, 0x22, 0x41, 0x00,

        # ebreak
        0x73, 0x00, 0x10, 0x00,
    ]

    assert len(program) == 128, f"Program must be exactly 128 bytes, got {len(program)}"

    dut._log.info("Reset and program SRAM")
    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)

    dut.ui_in.value = 0
    dut.uio_in.value = 0x02

    await ClockCycles(dut.clk, 5)

    dut._log.info("Release reset and send UART RX byte")
    dut.rst_n.value = 1

    # Send byte while CPU executes NOPs.
    await uart_rx_send_byte(dut, 0xA5)

    await ClockCycles(dut.clk, 220)

    observed = int(dut.uo_out.value)
    dut._log.info(f"uo_out = 0x{observed:02x}")

    assert observed == 0xA5, f"Expected uo_out=0xA5, got 0x{observed:02x}"
