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


def enc_xori(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (4 << 12) | ((rd & 0x1F) << 7) | 0x13


def enc_ori(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (6 << 12) | ((rd & 0x1F) << 7) | 0x13


def enc_andi(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (7 << 12) | ((rd & 0x1F) << 7) | 0x13


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


async def write_byte(dut, addr, data):
    dut.ui_in.value = ((addr & 0x7F) << 1) | 1
    dut.uio_in.value = data & 0xFF
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = ((addr & 0x7F) << 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start RV32E OP-IMM logic test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    words = [
        enc_addi(1, 0, 0x55),      # x1 = 0x55
        enc_ori(3, 1, 0x0A),       # x3 = 0x55 | 0x0A = 0x5F
        enc_xori(3, 3, 0x0F),      # x3 = 0x5F ^ 0x0F = 0x50
        enc_andi(4, 3, 0x0F0),     # x4 = 0x50 & 0xF0 = 0x50

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

    dut._log.info("Release reset and execute OP-IMM logic program")
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 100)

    observed = int(dut.uo_out.value)
    dut._log.info(f"uo_out = 0x{observed:02x}")

    assert observed == 0x50, f"Expected uo_out=0x50, got 0x{observed:02x}"
