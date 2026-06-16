import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def word_to_bytes(word):
    return [
        word & 0xFF,
        (word >> 8) & 0xFF,
        (word >> 16) & 0xFF,
        (word >> 24) & 0xFF,
    ]


def enc_lui(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | 0x37


def enc_addi(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (0 << 12) | ((rd & 0x1F) << 7) | 0x13


def enc_sw(rs2, rs1, imm):
    imm12 = imm & 0xFFF
    imm_11_5 = (imm12 >> 5) & 0x7F
    imm_4_0 = imm12 & 0x1F

    return (
        (imm_11_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | (2 << 12)
        | (imm_4_0 << 7)
        | 0x23
    )


def enc_jal(rd, offset):
    # RISC-V JAL immediate encoding.
    # offset is signed byte offset, must be 2-byte aligned.
    imm = offset & 0x1FFFFF

    bit20 = (imm >> 20) & 0x1
    bits10_1 = (imm >> 1) & 0x3FF
    bit11 = (imm >> 11) & 0x1
    bits19_12 = (imm >> 12) & 0xFF

    return (
        (bit20 << 31)
        | (bits19_12 << 12)
        | (bit11 << 20)
        | (bits10_1 << 21)
        | ((rd & 0x1F) << 7)
        | 0x6F
    )


async def write_byte(dut, addr, data):
    dut.ui_in.value = ((addr & 0x7F) << 1) | 1
    dut.uio_in.value = data & 0xFF
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = ((addr & 0x7F) << 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start RV32E JAL test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    words = [
        enc_addi(4, 0, 0x11),      # PC 0x00: x4 = 0x11
        enc_jal(1, 8),             # PC 0x04: x1 = 0x08, jump to PC 0x0C
        enc_addi(4, 0, 0x0FF),     # PC 0x08: must be skipped
        enc_addi(4, 1, 0x4D),      # PC 0x0C: x4 = x1 + 0x4D = 0x55

        enc_lui(2, 0x10000),       # x2 = 0x1000_0000
        enc_sw(4, 2, 0x00),        # GPIO output = x4

        0x00100073,                # EBREAK
    ]

    program = []
    for word in words:
        program += word_to_bytes(word)

    dut._log.info("Reset and program SRAM")
    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)

    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E

    await ClockCycles(dut.clk, 5)

    dut._log.info("Release reset and execute JAL program")
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 120)

    observed = int(dut.uo_out.value)
    dut._log.info(f"uo_out = 0x{observed:02x}")

    assert observed == 0x55, f"Expected uo_out=0x55, got 0x{observed:02x}"
