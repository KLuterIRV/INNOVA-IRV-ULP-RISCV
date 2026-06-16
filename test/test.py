import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


# -----------------------------------------------------------------------------
# Encoding helpers
# -----------------------------------------------------------------------------

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
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b000 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_xori(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b100 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_ori(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b110 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_andi(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b111 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_rtype(rd, rs1, rs2, funct3, funct7):
    return (
        ((funct7 & 0x7F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | ((rd & 0x1F) << 7)
        | 0x33
    )


def enc_add(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b000, funct7=0b0000000)


def enc_sub(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b000, funct7=0b0100000)


def enc_xor(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b100, funct7=0b0000000)


def enc_or(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b110, funct7=0b0000000)


def enc_and(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b111, funct7=0b0000000)


def enc_sw(rs2, rs1, imm):
    imm12 = imm & 0xFFF
    imm_11_5 = (imm12 >> 5) & 0x7F
    imm_4_0 = imm12 & 0x1F

    return (
        (imm_11_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b010 << 12)
        | (imm_4_0 << 7)
        | 0x23
    )


def enc_branch(rs1, rs2, offset, funct3):
    # RISC-V B-type immediate.
    # offset is signed byte offset and must be 2-byte aligned.
    imm = offset & 0x1FFF

    bit12 = (imm >> 12) & 0x1
    bit11 = (imm >> 11) & 0x1
    bits10_5 = (imm >> 5) & 0x3F
    bits4_1 = (imm >> 1) & 0xF

    return (
        (bit12 << 31)
        | (bits10_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | (bits4_1 << 8)
        | (bit11 << 7)
        | 0x63
    )


def enc_beq(rs1, rs2, offset):
    return enc_branch(rs1, rs2, offset, funct3=0b000)


def enc_bne(rs1, rs2, offset):
    return enc_branch(rs1, rs2, offset, funct3=0b001)


def enc_jal(rd, offset):
    # RISC-V JAL immediate.
    # offset is signed byte offset and must be 2-byte aligned.
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


EBREAK = 0x00100073


# -----------------------------------------------------------------------------
# Testbench helpers
# -----------------------------------------------------------------------------

async def write_byte(dut, addr, data):
    dut.ui_in.value = ((addr & 0x7F) << 1) | 1
    dut.uio_in.value = data & 0xFF
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = ((addr & 0x7F) << 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)


async def program_sram(dut, words):
    program = []
    for word in words:
        program += word_to_bytes(word)

    assert len(program) <= 128, f"Program too large for 128-byte SRAM: {len(program)} bytes"

    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)


async def run_program_and_check_gpio(dut, name, words, expected_gpio, cycles=180):
    dut._log.info(f"========== {name} ==========")

    # Reset asserted: boot/programming mode.
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E

    await ClockCycles(dut.clk, 8)

    await program_sram(dut, words)

    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E

    await ClockCycles(dut.clk, 5)

    # Release reset and run.
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, cycles)

    observed = int(dut.uo_out.value)
    dut._log.info(f"{name}: uo_out = 0x{observed:02x}")

    assert observed == expected_gpio, (
        f"{name}: expected uo_out=0x{expected_gpio:02x}, got 0x{observed:02x}"
    )


def write_gpio_program(value_reg):
    # Uses x2 as MMIO base 0x1000_0000.
    return [
        enc_lui(2, 0x10000),
        enc_sw(value_reg, 2, 0x00),
        EBREAK,
    ]


# -----------------------------------------------------------------------------
# Core regression test
# -----------------------------------------------------------------------------

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start INNOVA IRV core regression test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    # -------------------------------------------------------------------------
    # Test 1: OP-IMM instructions.
    #
    # x1 = 0x55
    # x1 = x1 XOR 0x0F = 0x5A
    # x1 = x1 OR  0x80 = 0xDA
    # x4 = x1 AND 0xFF = 0xDA
    # GPIO = 0xDA
    # -------------------------------------------------------------------------

    op_imm_program = [
        enc_addi(1, 0, 0x55),
        enc_xori(1, 1, 0x0F),
        enc_ori(1, 1, 0x80),
        enc_andi(4, 1, 0x0FF),
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="OP-IMM ADDI/XORI/ORI/ANDI",
        words=op_imm_program,
        expected_gpio=0xDA,
        cycles=180,
    )

    # -------------------------------------------------------------------------
    # Test 2: R-type ALU instructions.
    #
    # x1 = 0x3C
    # x2 = 0x0F
    # x3 = x1 + x2 = 0x4B
    # x3 = x3 - x2 = 0x3C
    # x3 = x3 ^ x2 = 0x33
    # x3 = x3 | x2 = 0x3F
    # x4 = x3 & x1 = 0x3C
    # GPIO = 0x3C
    # -------------------------------------------------------------------------

    rtype_program = [
        enc_addi(1, 0, 0x3C),
        enc_addi(2, 0, 0x0F),
        enc_add(3, 1, 2),
        enc_sub(3, 3, 2),
        enc_xor(3, 3, 2),
        enc_or(3, 3, 2),
        enc_and(4, 3, 1),
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="R-TYPE ADD/SUB/XOR/OR/AND",
        words=rtype_program,
        expected_gpio=0x3C,
        cycles=220,
    )

    # -------------------------------------------------------------------------
    # Test 3: BEQ and BNE.
    #
    # BEQ must skip a bad write.
    # BNE must also skip a bad write.
    # Final x4 = 0x44.
    # GPIO = 0x44.
    # -------------------------------------------------------------------------

    branch_program = [
        enc_addi(1, 0, 5),          # PC 0x00
        enc_addi(2, 0, 5),          # PC 0x04
        enc_beq(1, 2, 8),           # PC 0x08 -> jump to PC 0x10
        enc_addi(4, 0, 0xEE),       # PC 0x0C skipped if BEQ works
        enc_addi(4, 0, 0x33),       # PC 0x10

        enc_addi(1, 0, 1),          # PC 0x14
        enc_addi(2, 0, 2),          # PC 0x18
        enc_bne(1, 2, 8),           # PC 0x1C -> jump to PC 0x24
        enc_addi(4, 0, 0xEF),       # PC 0x20 skipped if BNE works
        enc_addi(4, 0, 0x44),       # PC 0x24
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="BRANCH BEQ/BNE",
        words=branch_program,
        expected_gpio=0x44,
        cycles=260,
    )

    # -------------------------------------------------------------------------
    # Test 4: JAL.
    #
    # JAL writes return address into x1 and jumps over a bad instruction.
    # At PC 0x0C, x4 = x1 + 0x4D = 0x08 + 0x4D = 0x55.
    # GPIO = 0x55.
    # -------------------------------------------------------------------------

    jal_program = [
        enc_addi(4, 0, 0x11),       # PC 0x00
        enc_jal(1, 8),              # PC 0x04: x1 = 0x08, jump to PC 0x0C
        enc_addi(4, 0, 0xFF),       # PC 0x08 skipped
        enc_addi(4, 1, 0x4D),       # PC 0x0C: x4 = 0x55
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="JAL link and jump",
        words=jal_program,
        expected_gpio=0x55,
        cycles=200,
    )

    # -------------------------------------------------------------------------
    # Test 5: physical register file x5-x8.
    #
    # x5 = 0x12
    # x6 = 0x34
    # x7 = x5 + x6 = 0x46
    # x8 = x7 ^ x5 = 0x54
    # GPIO = x8 = 0x54
    # -------------------------------------------------------------------------

    regfile_x8_program = [
        enc_addi(5, 0, 0x12),
        enc_addi(6, 0, 0x34),
        enc_add(7, 5, 6),
        enc_xor(8, 7, 5),
    ] + write_gpio_program(8)

    await run_program_and_check_gpio(
        dut,
        name="REGFILE x5-x8",
        words=regfile_x8_program,
        expected_gpio=0x54,
        cycles=220,
    )

    dut._log.info("All core regression tests passed")
