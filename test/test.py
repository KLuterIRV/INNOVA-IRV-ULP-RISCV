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


def enc_lw(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b010 << 12)
        | ((rd & 0x1F) << 7)
        | 0x03
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


def enc_jalr(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b000 << 12)
        | ((rd & 0x1F) << 7)
        | 0x67
    )


def enc_nop():
    return enc_addi(0, 0, 0)


EBREAK = 0x00100073


# -----------------------------------------------------------------------------
# Common testbench helpers
# -----------------------------------------------------------------------------

async def start_clock(dut):
    if not hasattr(dut, "_irv_clock_started"):
        clock = Clock(dut.clk, 10, unit="us")
        cocotb.start_soon(clock.start())
        dut._irv_clock_started = True


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


async def reset_and_program(dut, words, run_uio_in=0x0E):
    await start_clock(dut)

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 8)

    await program_sram(dut, words)

    dut.ui_in.value = 0
    dut.uio_in.value = run_uio_in

    await ClockCycles(dut.clk, 5)


async def run_program_and_check_gpio(
    dut,
    name,
    words,
    expected_gpio,
    cycles=220,
    run_uio_in=0x0E,
    concurrent_task=None,
):
    dut._log.info(f"========== {name} ==========")

    await reset_and_program(dut, words, run_uio_in=run_uio_in)

    if concurrent_task is not None:
        cocotb.start_soon(concurrent_task)

    dut.rst_n.value = 1

    await ClockCycles(dut.clk, cycles)

    observed = int(dut.uo_out.value)
    dut._log.info(f"{name}: uo_out = 0x{observed:02x}")

    assert observed == expected_gpio, (
        f"{name}: expected uo_out=0x{expected_gpio:02x}, got 0x{observed:02x}"
    )


def write_gpio_program(value_reg):
    return [
        enc_lui(2, 0x10000),
        enc_sw(value_reg, 2, 0x00),
        EBREAK,
    ]


def wait_loop_program(count_reg=1, count=20):
    # x<count_reg> = count
    # loop:
    #   addi x<count_reg>, x<count_reg>, -1
    #   bne  x<count_reg>, x0, loop
    return [
        enc_addi(count_reg, 0, count),
        enc_addi(count_reg, count_reg, -1),
        enc_bne(count_reg, 0, -4),
    ]


# -----------------------------------------------------------------------------
# UART helpers
# -----------------------------------------------------------------------------

async def read_uart_tx_byte(dut, clks_per_bit=8, timeout_cycles=900):
    for _ in range(timeout_cycles):
        if int(dut.uio_out.value) & 0x1:
            break
        await ClockCycles(dut.clk, 1)
    else:
        raise AssertionError("UART TX did not reach idle high before capture")

    prev = int(dut.uio_out.value) & 0x1

    for _ in range(timeout_cycles):
        await ClockCycles(dut.clk, 1)
        cur = int(dut.uio_out.value) & 0x1

        if prev == 1 and cur == 0:
            break

        prev = cur
    else:
        raise AssertionError("UART TX start bit was not detected")

    await ClockCycles(dut.clk, clks_per_bit + (clks_per_bit // 2))

    value = 0

    for bit_index in range(8):
        bit_value = int(dut.uio_out.value) & 0x1
        value |= bit_value << bit_index
        await ClockCycles(dut.clk, clks_per_bit)

    stop_bit = int(dut.uio_out.value) & 0x1
    assert stop_bit == 1, "UART TX stop bit was not high"

    return value


async def drive_uart_rx_byte(dut, value, clks_per_bit=8, start_delay=8):
    await ClockCycles(dut.clk, start_delay)

    dut.uio_in.value = 0x0E
    await ClockCycles(dut.clk, clks_per_bit)

    dut.uio_in.value = 0x0C
    await ClockCycles(dut.clk, clks_per_bit)

    for bit_index in range(8):
        bit = (value >> bit_index) & 0x1
        dut.uio_in.value = 0x0E if bit else 0x0C
        await ClockCycles(dut.clk, clks_per_bit)

    dut.uio_in.value = 0x0E
    await ClockCycles(dut.clk, clks_per_bit * 2)


async def drive_uart_rx_two_bytes(dut, value_a, value_b):
    await drive_uart_rx_byte(dut, value_a, start_delay=8)
    await drive_uart_rx_byte(dut, value_b, start_delay=4)


# -----------------------------------------------------------------------------
# Core tests
# -----------------------------------------------------------------------------

async def subtest_core_alu_and_mmio(dut):
    words = [
        enc_addi(1, 0, 0x55),
        enc_xori(1, 1, 0x0F),
        enc_ori(1, 1, 0x80),
        enc_andi(4, 1, 0x0FF),
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="CORE OP-IMM and GPIO MMIO",
        words=words,
        expected_gpio=0xDA,
        cycles=180,
    )

    words = [
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
        name="CORE R-type ALU",
        words=words,
        expected_gpio=0x3C,
        cycles=240,
    )


async def subtest_core_branch_jump_regfile(dut):
    words = [
        enc_addi(1, 0, 5),
        enc_addi(2, 0, 5),
        enc_beq(1, 2, 8),
        enc_addi(4, 0, 0xEE),
        enc_addi(4, 0, 0x33),

        enc_addi(1, 0, 1),
        enc_addi(2, 0, 2),
        enc_bne(1, 2, 8),
        enc_addi(4, 0, 0xEF),
        enc_addi(4, 0, 0x44),
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="CORE BEQ/BNE",
        words=words,
        expected_gpio=0x44,
        cycles=280,
    )

    words = [
        enc_addi(4, 0, 0x11),
        enc_jal(1, 8),
        enc_addi(4, 0, 0xFF),
        enc_addi(4, 1, 0x4D),
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="CORE JAL",
        words=words,
        expected_gpio=0x55,
        cycles=220,
    )

    words = [
        enc_addi(5, 0, 0x12),
        enc_addi(6, 0, 0x34),
        enc_add(7, 5, 6),
        enc_xor(8, 7, 5),
    ] + write_gpio_program(8)

    await run_program_and_check_gpio(
        dut,
        name="CORE REGFILE x5-x8",
        words=words,
        expected_gpio=0x54,
        cycles=240,
    )

    words = [
        enc_addi(5, 0, 0x10),
        enc_jalr(1, 5, 0),
        enc_addi(4, 0, 0xEE),
        enc_addi(4, 0, 0xEF),
        enc_addi(4, 1, 0x66),
    ] + write_gpio_program(4)

    await run_program_and_check_gpio(
        dut,
        name="CORE JALR",
        words=words,
        expected_gpio=0x6E,
        cycles=260,
    )


# -----------------------------------------------------------------------------
# UART tests
# -----------------------------------------------------------------------------

async def subtest_uart_tx(dut):
    words = [
        enc_lui(2, 0x10000),
        enc_addi(4, 0, 0x0A5),
        enc_sw(4, 2, 0x04),
        EBREAK,
    ]

    await reset_and_program(dut, words, run_uio_in=0x0E)
    dut.rst_n.value = 1

    observed = await read_uart_tx_byte(dut, clks_per_bit=8, timeout_cycles=1000)
    dut._log.info(f"UART TX byte = 0x{observed:02x}")

    assert observed == 0xA5, f"Expected UART TX byte 0xA5, got 0x{observed:02x}"


async def subtest_uart_rx_data_status_clear(dut):
    words = [
        enc_lui(2, 0x10000),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_nop(),
        enc_lw(4, 2, 0x0C),    # read RX data, also clears valid
        enc_sw(4, 2, 0x00),    # GPIO = received byte
        EBREAK,
    ]

    # 32 words exactly = 128 bytes.
    assert len(words) == 32

    await run_program_and_check_gpio(
        dut,
        name="UART RX data read",
        words=words,
        expected_gpio=0x5A,
        cycles=380,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_byte(dut, 0x5A, start_delay=8),
    )

    words = [
        enc_lui(2, 0x10000),
    ] + [enc_nop() for _ in range(26)] + [
        enc_lw(3, 2, 0x0C),    # read RX data, clears valid
        enc_lw(4, 2, 0x08),    # read status
        enc_andi(4, 4, 0x02),  # isolate rx_valid
        enc_sw(4, 2, 0x00),
        EBREAK,
    ]

    assert len(words) == 32

    await run_program_and_check_gpio(
        dut,
        name="UART RX read-clear valid bit",
        words=words,
        expected_gpio=0x00,
        cycles=400,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_byte(dut, 0x77, start_delay=8),
    )


async def subtest_uart_rx_overrun(dut):
    words = [
        enc_lui(2, 0x10000),
    ] + wait_loop_program(count_reg=1, count=32) + [
        enc_lw(4, 2, 0x08),
        enc_andi(4, 4, 0x06),  # rx_valid | rx_overrun
        enc_sw(4, 2, 0x00),
        EBREAK,
    ]

    assert len(words) < 32

    await run_program_and_check_gpio(
        dut,
        name="UART RX overrun",
        words=words,
        expected_gpio=0x06,
        cycles=520,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_two_bytes(dut, 0x11, 0x22),
    )


# -----------------------------------------------------------------------------
# I2C tests
# -----------------------------------------------------------------------------

async def subtest_i2c_write_ack(dut):
    words = [
        enc_lui(2, 0x10000),
        enc_addi(4, 0, 1),
        enc_sw(4, 2, 0x1C),    # DIV = 1
        enc_addi(4, 0, 0x80),
        enc_sw(4, 2, 0x14),    # DATA = 0x80
        enc_addi(4, 0, 0x07),
        enc_sw(4, 2, 0x10),    # START + STOP + WRITE
    ] + wait_loop_program(count_reg=1, count=24) + [
        enc_lw(4, 2, 0x18),    # STATUS
        enc_andi(4, 4, 0x17),  # busy/done/ack_error/scl_in
        enc_sw(4, 2, 0x00),
        EBREAK,
    ]

    assert len(words) < 32

    await run_program_and_check_gpio(
        dut,
        name="I2C WRITE byte ACK",
        words=words,
        expected_gpio=0x12,
        cycles=520,
        # RX high, SCL high, SDA low -> ACK.
        run_uio_in=0x06,
    )


async def subtest_i2c_write_nack(dut):
    words = [
        enc_lui(2, 0x10000),
        enc_addi(4, 0, 1),
        enc_sw(4, 2, 0x1C),    # DIV = 1
        enc_addi(4, 0, 0x80),
        enc_sw(4, 2, 0x14),    # DATA = 0x80
        enc_addi(4, 0, 0x07),
        enc_sw(4, 2, 0x10),    # START + STOP + WRITE
    ] + wait_loop_program(count_reg=1, count=24) + [
        enc_lw(4, 2, 0x18),    # STATUS
        enc_andi(4, 4, 0x17),  # busy/done/ack_error/scl_in
        enc_sw(4, 2, 0x00),
        EBREAK,
    ]

    assert len(words) < 32

    await run_program_and_check_gpio(
        dut,
        name="I2C WRITE byte NACK",
        words=words,
        expected_gpio=0x16,
        cycles=520,
        # RX high, SCL high, SDA high -> NACK.
        run_uio_in=0x0E,
    )

# -----------------------------------------------------------------------------
# Single cocotb entry point
# -----------------------------------------------------------------------------
#
# TinyTapeout GL/RTL regression is more robust when all subtests run inside one
# cocotb test. Each subtest explicitly asserts reset, reprograms the 128-byte
# SRAM, releases reset and then checks its result.
#
# This avoids relying on simulator/DUT reinitialization between multiple
# @cocotb.test() functions.

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start INNOVA IRV split regression suite")

    await subtest_core_alu_and_mmio(dut)
    await subtest_core_branch_jump_regfile(dut)
    await subtest_uart_tx(dut)
    await subtest_uart_rx_data_status_clear(dut)
    await subtest_uart_rx_overrun(dut)
    await subtest_i2c_write_ack(dut)
    await subtest_i2c_write_nack(dut)

    dut._log.info("All split regression subtests passed")

