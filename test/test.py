import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, FallingEdge


def is_gate_level_sim(dut):
    """Return True when running TinyTapeout gate-level simulation.

    UART RX is an asynchronous input. The full RX/IRQ-RX behavioural tests are
    kept in RTL, while GLS focuses on synchronous paths and stable peripheral
    tests. This avoids X-pessimistic failures caused by async testbench stimulus
    in gate-level simulation.
    """
    if os.getenv("GATES", "").lower() == "yes":
        return True

    if os.getenv("GL_TEST", "").lower() in ("1", "true", "yes"):
        return True

    try:
        _ = dut.user_project.VPWR
        return True
    except Exception:
        return False


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


def enc_auipc(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | 0x17


def enc_addi(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b000 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )



def enc_slt(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b010, funct7=0b0000000)


def enc_sltu(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b011, funct7=0b0000000)


def enc_sll(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b001, funct7=0b0000000)


def enc_srl(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b101, funct7=0b0000000)


def enc_sra(rd, rs1, rs2):
    return enc_rtype(rd, rs1, rs2, funct3=0b101, funct7=0b0100000)

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



def enc_slti(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b010 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_sltiu(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b011 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_slli(rd, rs1, shamt):
    return (
        (0b0000000 << 25)
        | ((shamt & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b001 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_srli(rd, rs1, shamt):
    return (
        (0b0000000 << 25)
        | ((shamt & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b101 << 12)
        | ((rd & 0x1F) << 7)
        | 0x13
    )


def enc_srai(rd, rs1, shamt):
    return (
        (0b0100000 << 25)
        | ((shamt & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b101 << 12)
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



def enc_lb(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b000 << 12)
        | ((rd & 0x1F) << 7)
        | 0x03
    )


def enc_lh(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b001 << 12)
        | ((rd & 0x1F) << 7)
        | 0x03
    )


def enc_lbu(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b100 << 12)
        | ((rd & 0x1F) << 7)
        | 0x03
    )


def enc_lhu(rd, rs1, imm):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | (0b101 << 12)
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



def enc_store(rs2, rs1, imm, funct3):
    imm12 = imm & 0xFFF
    imm_11_5 = (imm12 >> 5) & 0x7F
    imm_4_0 = imm12 & 0x1F

    return (
        (imm_11_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | (imm_4_0 << 7)
        | 0x23
    )


def enc_sb(rs2, rs1, imm):
    return enc_store(rs2, rs1, imm, funct3=0b000)


def enc_sh(rs2, rs1, imm):
    return enc_store(rs2, rs1, imm, funct3=0b001)

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



def enc_blt(rs1, rs2, offset):
    return enc_branch(rs1, rs2, offset, funct3=0b100)


def enc_bge(rs1, rs2, offset):
    return enc_branch(rs1, rs2, offset, funct3=0b101)


def enc_bltu(rs1, rs2, offset):
    return enc_branch(rs1, rs2, offset, funct3=0b110)


def enc_bgeu(rs1, rs2, offset):
    return enc_branch(rs1, rs2, offset, funct3=0b111)

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
WFI = 0x10500073


# -----------------------------------------------------------------------------
# Common testbench helpers
# -----------------------------------------------------------------------------

async def start_clock(dut):
    if not hasattr(dut, "_irv_clock_started"):
        clock = Clock(dut.clk, 10, unit="us")
        cocotb.start_soon(clock.start())
        dut._irv_clock_started = True


async def write_byte(dut, addr, data):
    # 256-byte boot protocol:
    # phase A: latch addr[7] while boot_we=0
    # phase B: write data while boot_we=1
    addr = addr & 0xFF

    dut.ui_in.value = ((addr & 0x7F) << 1)
    dut.uio_in.value = (addr >> 7) & 0x01
    await ClockCycles(dut.clk, 1)

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

    assert len(program) <= 256, f"Program too large for 256-byte SRAM: {len(program)} bytes"

    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)


async def release_reset_safe(dut):
    """Release reset away from the active clock edge.

    RTL simulation tolerates reset release immediately after ClockCycles(),
    but gate-level simulation can produce X values if reset deassertion is
    aligned with the active clock edge. The design samples on clk rising edge,
    so reset is released on the falling edge plus a small delay.
    """
    await FallingEdge(dut.clk)
    await Timer(1, unit="ns")
    dut.rst_n.value = 1


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

    await release_reset_safe(dut)

    await ClockCycles(dut.clk, cycles)

    # Gate-level simulation is X-pessimistic if outputs are sampled
    # immediately after the active clock edge. Sample on the falling edge,
    # half a clock cycle after sequential state has updated.
    await FallingEdge(dut.clk)
    await Timer(1, unit="ns")

    try:
        observed = int(dut.uo_out.value)
    except ValueError:
        dut._log.warning(f"{name}: raw uo_out contains X/Z: {dut.uo_out.value}")
        raise

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
    # UART RX is asynchronous to the DUT, but for GLS we must avoid changing
    # the input near the DUT sampling edge. The UART receiver samples on the
    # rising edge of clk, so the testbench changes uio_in on the falling edge.
    async def drive_uio_midcycle(v):
        await FallingEdge(dut.clk)
        await Timer(1, unit="ns")
        dut.uio_in.value = v

    await ClockCycles(dut.clk, start_delay)

    await drive_uio_midcycle(0x0E)      # idle high
    await ClockCycles(dut.clk, clks_per_bit)

    await drive_uio_midcycle(0x0C)      # start bit, UART RX low on uio_in[1]
    await ClockCycles(dut.clk, clks_per_bit)

    for bit_index in range(8):
        bit = (value >> bit_index) & 0x1
        await drive_uio_midcycle(0x0E if bit else 0x0C)
        await ClockCycles(dut.clk, clks_per_bit)

    await drive_uio_midcycle(0x0E)      # stop/idle high
    await ClockCycles(dut.clk, clks_per_bit * 2)


async def drive_uart_rx_two_bytes(dut, value_a, value_b):
    await drive_uart_rx_byte(dut, value_a, start_delay=8)
    await drive_uart_rx_byte(dut, value_b, start_delay=4)




# -----------------------------------------------------------------------------
# I2C dynamic slave helpers
# -----------------------------------------------------------------------------

def i2c_uio_value(sda=1):
    # uio_in[1] = UART RX idle high
    # uio_in[2] = I2C SCL input high
    # uio_in[3] = I2C SDA input provided by test slave
    return 0x06 | ((sda & 0x1) << 3)


async def set_i2c_slave_sda_midcycle(dut, bit):
    # Change SDA away from the DUT sampling edge.
    await FallingEdge(dut.clk)
    await Timer(1, unit="ns")
    dut.uio_in.value = i2c_uio_value(sda=bit)


async def wait_i2c_scl_oe(dut, expected, timeout_cycles=3000):
    # uio_oe[2] is the I2C SCL open-drain output enable.
    # 1 = master drives SCL low
    # 0 = master releases SCL high
    for _ in range(timeout_cycles):
        try:
            oe = int(dut.uio_oe.value)
        except ValueError:
            await ClockCycles(dut.clk, 1)
            continue

        if ((oe >> 2) & 0x1) == expected:
            return

        await ClockCycles(dut.clk, 1)

    raise AssertionError(f"Timed out waiting for I2C SCL OE={expected}")


async def drive_i2c_read_byte(dut, value):
    # Simple cocotb I2C read slave.
    #
    # It waits for each SCL-low phase before the master samples a read bit,
    # drives SDA to the requested value, then waits for SCL release.
    #
    # This helper is intended for RTL functional testing. GLS keeps simpler
    # static ACK/NACK I2C tests.
    await set_i2c_slave_sda_midcycle(dut, 1)

    for bit_index in range(7, -1, -1):
        bit = (value >> bit_index) & 0x1

        # Master pulls SCL low before sampling this bit.
        await wait_i2c_scl_oe(dut, 1)
        await set_i2c_slave_sda_midcycle(dut, bit)

        # Master releases SCL high and samples sda_in.
        await wait_i2c_scl_oe(dut, 0)

    # Release SDA after byte transfer.
    await set_i2c_slave_sda_midcycle(dut, 1)


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



async def subtest_core_slt_sltu(dut):
    # Validate signed and unsigned less-than operations.
    #
    # x1 = -1 / 0xFFFF_FFFF
    # x2 =  1
    # x7 accumulates one bit per correctly behaving comparison.
    #
    # Expected GPIO = 0x1F:
    #   bit 0: SLT   (-1 < 1 signed)       -> true
    #   bit 1: SLTU  (0xffffffff < 1)      -> false, false is expected
    #   bit 2: SLTI  (-1 < 0 signed)       -> true
    #   bit 3: SLTIU (1 < 2 unsigned)      -> true
    #   bit 4: SLTIU (0xffffffff < 1)      -> false, false is expected

    words = [
        enc_addi(1, 0, -1),         # x1 = -1 / 0xffffffff
        enc_addi(2, 0, 1),          # x2 = 1
        enc_addi(7, 0, 0),          # x7 = accumulator

        enc_slt(3, 1, 2),           # true
        enc_beq(3, 0, 8),
        enc_ori(7, 7, 0x01),

        enc_sltu(3, 1, 2),          # false expected
        enc_bne(3, 0, 8),
        enc_ori(7, 7, 0x02),

        enc_slti(3, 1, 0),          # true
        enc_beq(3, 0, 8),
        enc_ori(7, 7, 0x04),

        enc_sltiu(3, 2, 2),         # true
        enc_beq(3, 0, 8),
        enc_ori(7, 7, 0x08),

        enc_sltiu(3, 1, 1),         # false expected
        enc_bne(3, 0, 8),
        enc_ori(7, 7, 0x10),

        enc_lui(8, 0x10000),        # x8 = MMIO base
        enc_sw(7, 8, 0x00),         # GPIO = accumulated result
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="CORE SLT/SLTU/SLTI/SLTIU",
        words=words,
        expected_gpio=0x1F,
        cycles=340,
    )


async def subtest_core_compare_branches(dut):
    # Validate BLT/BGE/BLTU/BGEU.
    #
    # x1 = -1 / 0xffffffff
    # x2 =  1
    # x7 accumulates a bit for each branch behaving correctly.
    #
    # Expected GPIO = 0x3F:
    #   bit 0: BLT  signed true       (-1 < 1)
    #   bit 1: BGE  signed true       (1 >= -1)
    #   bit 2: BLTU unsigned false    (0xffffffff < 1 is false)
    #   bit 3: BGEU unsigned true     (0xffffffff >= 1)
    #   bit 4: BGE  signed false      (-1 >= 1 is false)
    #   bit 5: BLTU unsigned true     (1 < 0xffffffff)

    words = [
        enc_addi(1, 0, -1),         # x1 = -1 / 0xffffffff
        enc_addi(2, 0, 1),          # x2 = 1
        enc_addi(7, 0, 0),          # accumulator

        # True branch helper:
        #   branch +8 -> execute ORI
        #   JAL +8    -> skip ORI if branch not taken

        enc_blt(1, 2, 8),           # signed true
        enc_jal(0, 8),
        enc_ori(7, 7, 0x01),

        enc_bge(2, 1, 8),           # signed true
        enc_jal(0, 8),
        enc_ori(7, 7, 0x02),

        # False expected:
        #   if branch is not taken, ORI executes.
        #   if branch is incorrectly taken, ORI is skipped.
        enc_bltu(1, 2, 8),          # unsigned false expected
        enc_ori(7, 7, 0x04),

        enc_bgeu(1, 2, 8),          # unsigned true
        enc_jal(0, 8),
        enc_ori(7, 7, 0x08),

        enc_bge(1, 2, 8),           # signed false expected
        enc_ori(7, 7, 0x10),

        enc_bltu(2, 1, 8),          # unsigned true
        enc_jal(0, 8),
        enc_ori(7, 7, 0x20),

        enc_lui(8, 0x10000),
        enc_sw(7, 8, 0x00),
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="CORE BLT/BGE/BLTU/BGEU",
        words=words,
        expected_gpio=0x3F,
        cycles=420,
    )


async def subtest_core_shift_immediates(dut):
    # Validate SLLI/SRLI/SRAI.
    #
    # x7 accumulates one bit per correct result.
    # Expected GPIO = 0x07.

    words = [
        enc_addi(7, 0, 0),          # accumulator

        enc_addi(1, 0, 1),
        enc_slli(3, 1, 5),          # 1 << 5 = 32
        enc_addi(4, 0, 32),
        enc_beq(3, 4, 8),
        enc_jal(0, 8),
        enc_ori(7, 7, 0x01),

        enc_addi(1, 0, 64),
        enc_srli(3, 1, 3),          # 64 >> 3 = 8
        enc_addi(4, 0, 8),
        enc_beq(3, 4, 8),
        enc_jal(0, 8),
        enc_ori(7, 7, 0x02),

        enc_addi(1, 0, -16),
        enc_srai(3, 1, 2),          # -16 >>> 2 arithmetic = -4
        enc_addi(4, 0, -4),
        enc_beq(3, 4, 8),
        enc_jal(0, 8),
        enc_ori(7, 7, 0x04),

        enc_lui(8, 0x10000),
        enc_sw(7, 8, 0x00),
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="CORE SLLI/SRLI/SRAI",
        words=words,
        expected_gpio=0x07,
        cycles=420,
    )


async def subtest_core_shift_registers(dut):
    # Validate R-type SLL/SRL/SRA.
    #
    # x7 accumulates one bit per correct result.
    # Expected GPIO = 0x07.

    words = [
        enc_addi(7, 0, 0),          # accumulator

        enc_addi(1, 0, 1),
        enc_addi(2, 0, 5),
        enc_sll(3, 1, 2),           # 1 << 5 = 32
        enc_addi(4, 0, 32),
        enc_beq(3, 4, 8),
        enc_jal(0, 8),
        enc_ori(7, 7, 0x01),

        enc_addi(1, 0, 64),
        enc_addi(2, 0, 3),
        enc_srl(3, 1, 2),           # 64 >> 3 = 8
        enc_addi(4, 0, 8),
        enc_beq(3, 4, 8),
        enc_jal(0, 8),
        enc_ori(7, 7, 0x02),

        enc_addi(1, 0, -16),
        enc_addi(2, 0, 2),
        enc_sra(3, 1, 2),           # -16 >>> 2 arithmetic = -4
        enc_addi(4, 0, -4),
        enc_beq(3, 4, 8),
        enc_jal(0, 8),
        enc_ori(7, 7, 0x04),

        enc_lui(8, 0x10000),
        enc_sw(7, 8, 0x00),
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="CORE SLL/SRL/SRA",
        words=words,
        expected_gpio=0x07,
        cycles=460,
    )


async def subtest_core_auipc(dut):
    # Validate AUIPC without adding a new hardware adder.
    #
    # PC map:
    #   0x00: AUIPC x2, 0x10000 -> x2 = 0x1000_0000, MMIO base
    #   0x04: NOP
    #   0x08: AUIPC x4, 0       -> x4 = 0x0000_0008
    #   0x0C: ADDI  x4, x4, 0x2A -> x4 = 0x32
    #
    # GPIO should receive 0x32.

    words = [
        enc_auipc(2, 0x10000),      # x2 = MMIO base because PC=0 here
        enc_nop(),
        enc_auipc(4, 0x00000),      # x4 = current PC = 0x08
        enc_addi(4, 4, 0x2A),       # x4 = 0x32
        enc_sw(4, 2, 0x00),         # GPIO = 0x32
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="CORE AUIPC",
        words=words,
        expected_gpio=0x32,
        cycles=220,
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
    await release_reset_safe(dut)

    observed = await read_uart_tx_byte(dut, clks_per_bit=8, timeout_cycles=1000)
    dut._log.info(f"UART TX byte = 0x{observed:02x}")

    assert observed == 0xA5, f"Expected UART TX byte 0xA5, got 0x{observed:02x}"


async def subtest_uart_rx_data_status_clear(dut):
    words = [
        enc_lui(2, 0x10000),       # x2 = MMIO base

        # Poll UART status until rx_valid is set.
        # STATUS bit 1 = rx_valid.
        enc_lw(4, 2, 0x08),        # loop: x4 = UART STATUS
        enc_andi(4, 4, 0x02),      # isolate rx_valid
        enc_beq(4, 0, -8),         # if not valid, repeat status poll

        enc_lw(4, 2, 0x0C),        # read RX data, also clears valid
        enc_sw(4, 2, 0x00),        # GPIO = received byte
        EBREAK,
    ]

    assert len(words) < 32

    await run_program_and_check_gpio(
        dut,
        name="UART RX data read",
        words=words,
        expected_gpio=0x5A,
        cycles=520,
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



async def subtest_irq_wfi_uart_rx(dut):
    # Program layout:
    #   PC 0x00: setup base + WFI
    #   PC 0x40: interrupt handler
    #
    # IRQ source:
    #   UART RX valid wakes the core from WFI.
    #
    # Handler:
    #   read UART RX data and write it to GPIO.

    words = [
        enc_lui(2, 0x10000),        # PC 0x00: x2 = 0x1000_0000
        enc_addi(4, 0, 0x01),       # enable UART RX valid IRQ
        enc_sw(4, 2, 0x24),         # IRQ_ENABLE = 0x01
        WFI,                        # sleep until UART RX IRQ
    ]

    # Fill until PC 0x40. PC 0x40 is instruction index 16.
    while len(words) < 16:
        words.append(enc_nop())

    words += [
        enc_lw(4, 2, 0x0C),         # PC 0x40: x4 = UART RX data
        enc_sw(4, 2, 0x00),         # GPIO = x4
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="IRQ WFI wake on UART RX",
        words=words,
        expected_gpio=0xA6,
        cycles=360,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_byte(dut, 0xA6, start_delay=40),
    )




async def subtest_irq_status_uart_rx(dut):
    # Program layout:
    #   PC 0x00: setup base + WFI
    #   PC 0x40: interrupt handler
    #
    # Handler reads IRQ_STATUS at 0x1000_0020 and checks bit 0 = UART RX valid.

    words = [
        enc_lui(2, 0x10000),        # x2 = MMIO base
        enc_addi(4, 0, 0x01),       # enable UART RX valid IRQ
        enc_sw(4, 2, 0x24),         # IRQ_ENABLE = 0x01
        WFI,
    ]

    while len(words) < 16:
        words.append(enc_nop())

    words += [
        enc_lw(4, 2, 0x20),         # x4 = IRQ_STATUS
        enc_andi(4, 4, 0x01),       # isolate UART RX valid
        enc_sw(4, 2, 0x00),         # GPIO = 0x01
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="IRQ STATUS UART RX valid",
        words=words,
        expected_gpio=0x01,
        cycles=360,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_byte(dut, 0x55, start_delay=40),
    )




async def subtest_irq_enable_masks_uart_rx(dut):
    # IRQ_ENABLE = 0. UART RX valid occurs, but core must remain asleep.
    # If it incorrectly wakes, handler writes 0xAA to GPIO.
    # Expected GPIO remains 0x00.

    words = [
        enc_lui(2, 0x10000),        # x2 = MMIO base
        enc_addi(4, 0, 0x00),       # disable all IRQs
        enc_sw(4, 2, 0x24),         # IRQ_ENABLE = 0
        WFI,
    ]

    while len(words) < 16:
        words.append(enc_nop())

    words += [
        enc_addi(4, 0, 0xAA),       # should not execute
        enc_sw(4, 2, 0x00),
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="IRQ ENABLE masks UART RX",
        words=words,
        expected_gpio=0x00,
        cycles=360,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_byte(dut, 0x55, start_delay=40),
    )




async def subtest_irq_return_uart_rx(dut):
    # IRQ return test:
    #
    # Main program:
    #   enable UART RX IRQ
    #   WFI
    #   after return, write 0xC3 to GPIO
    #
    # IRQ handler at 0x40:
    #   read UART RX data to clear rx_valid
    #   return with JALR x0, x1, 0

    words = [
        enc_lui(2, 0x10000),        # x2 = MMIO base
        enc_addi(4, 0, 0x01),       # enable UART RX valid IRQ
        enc_sw(4, 2, 0x24),         # IRQ_ENABLE = 0x01
        WFI,                        # sleep until UART RX IRQ

        enc_addi(5, 0, 0xC3),       # executed after IRQ return
        enc_sw(5, 2, 0x00),         # GPIO = 0xC3
        EBREAK,
    ]

    while len(words) < 16:
        words.append(enc_nop())

    words += [
        enc_lw(4, 2, 0x0C),         # read UART RX data, clears rx_valid
        enc_jalr(0, 1, 0),          # return to x1 = WFI_PC + 4
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="IRQ return from UART RX handler",
        words=words,
        expected_gpio=0xC3,
        cycles=420,
        run_uio_in=0x0E,
        concurrent_task=drive_uart_rx_byte(dut, 0x33, start_delay=40),
    )




async def subtest_irq_i2c_done(dut):
    # I2C done IRQ test:
    #
    # Main program:
    #   enable IRQ bit 2 = I2C done
    #   start one I2C write transaction
    #   enter WFI
    #
    # IRQ handler at 0x40:
    #   read IRQ_STATUS
    #   isolate bit 2
    #   write GPIO = 0x04
    #
    # This test is GLS-friendly because it does not use asynchronous UART RX
    # stimulus. The I2C ACK/NACK input is held constant.

    words = [
        enc_lui(2, 0x10000),        # x2 = MMIO base

        enc_addi(4, 0, 0x04),       # enable I2C done IRQ
        enc_sw(4, 2, 0x24),         # IRQ_ENABLE = 0x04

        enc_addi(4, 0, 1),
        enc_sw(4, 2, 0x1C),         # I2C DIV = 1

        enc_addi(4, 0, 0x80),
        enc_sw(4, 2, 0x14),         # I2C DATA = 0x80

        enc_addi(4, 0, 0x07),
        enc_sw(4, 2, 0x10),         # I2C CTRL = START + STOP + WRITE

        WFI,                        # sleep until I2C done IRQ
    ]

    # IRQ vector at PC 0x40, instruction index 16.
    while len(words) < 16:
        words.append(enc_nop())

    words += [
        enc_lw(4, 2, 0x20),         # IRQ_STATUS
        enc_andi(4, 4, 0x04),       # isolate I2C done IRQ bit
        enc_sw(4, 2, 0x00),         # GPIO = 0x04
        EBREAK,
    ]

    assert len(words) <= 32

    await run_program_and_check_gpio(
        dut,
        name="IRQ I2C done wake",
        words=words,
        expected_gpio=0x04,
        cycles=560,
        # RX high, SCL high, SDA low -> ACK.
        run_uio_in=0x06,
    )



async def subtest_core_high_program_memory(dut):
    # Validate 256-byte program SRAM path.
    #
    # PC 0x00:
    #   JAL x0, +0x80
    #
    # PC 0x80:
    #   GPIO = 0x7E
    #
    # This checks:
    #   - boot address bit 7
    #   - PC_WIDTH=8 execution
    #   - fetch from upper half of program memory

    words = [
        enc_jal(0, 0x80),
    ]

    while len(words) < 32:
        words.append(enc_nop())

    words += [
        enc_lui(2, 0x10000),
        enc_addi(4, 0, 0x7E),
        enc_sw(4, 2, 0x00),
        EBREAK,
    ]

    assert len(words) <= 64

    await run_program_and_check_gpio(
        dut,
        name="CORE high program memory PC 0x80",
        words=words,
        expected_gpio=0x7E,
        cycles=300,
    )


async def subtest_uart_printf_ok(dut):
    # Validate a small printf-like UART TX sequence.
    #
    # Firmware sends:
    #   "OK\n"

    words = [
        enc_lui(2, 0x10000),

        enc_addi(4, 0, ord("O")),
        enc_sw(4, 2, 0x04),
        enc_lw(5, 2, 0x08),
        enc_andi(5, 5, 0x01),
        enc_bne(5, 0, -8),

        enc_addi(4, 0, ord("K")),
        enc_sw(4, 2, 0x04),
        enc_lw(5, 2, 0x08),
        enc_andi(5, 5, 0x01),
        enc_bne(5, 0, -8),

        enc_addi(4, 0, 0x0A),
        enc_sw(4, 2, 0x04),

        EBREAK,
    ]

    assert len(words) <= 64

    dut._log.info("========== UART printf OK ==========")

    await reset_and_program(dut, words, run_uio_in=0x0E)
    await release_reset_safe(dut)

    expected = [ord("O"), ord("K"), 0x0A]
    observed = []

    for _ in expected:
        observed.append(await read_uart_tx_byte(dut, clks_per_bit=8, timeout_cycles=2500))

    dut._log.info("UART printf bytes = " + " ".join(f"0x{x:02x}" for x in observed))
    assert observed == expected, f"Expected UART bytes {expected}, got {observed}"


async def subtest_i2c_read_byte(dut):
    # Validate I2C READ_BYTE engine using a simple dynamic cocotb slave.
    #
    # The fake slave returns 0xA5. Firmware reads I2C DATA and writes it to GPIO.

    words = [
        enc_lui(2, 0x10000),

        enc_addi(4, 0, 1),
        enc_sw(4, 2, 0x1C),         # I2C DIV = 1

        enc_addi(4, 0, 0x0B),
        enc_sw(4, 2, 0x10),         # CTRL = START + STOP + READ

    ] + wait_loop_program(count_reg=1, count=36) + [
        enc_lw(4, 2, 0x14),         # I2C DATA
        enc_sw(4, 2, 0x00),         # GPIO = read byte
        EBREAK,
    ]

    assert len(words) <= 64

    await run_program_and_check_gpio(
        dut,
        name="I2C READ byte",
        words=words,
        expected_gpio=0xA5,
        cycles=700,
        run_uio_in=0x0E,
        concurrent_task=drive_i2c_read_byte(dut, 0xA5),
    )


async def subtest_system_i2c_to_uart(dut):
    # Functional system path:
    #
    #   fake I2C sensor -> I2C DATA -> CPU -> UART TX
    #
    # The fake sensor returns 0x5A. Firmware sends that byte through UART.

    words = [
        enc_lui(2, 0x10000),

        enc_addi(4, 0, 1),
        enc_sw(4, 2, 0x1C),         # I2C DIV = 1

        enc_addi(4, 0, 0x0B),
        enc_sw(4, 2, 0x10),         # CTRL = START + STOP + READ

    ] + wait_loop_program(count_reg=1, count=36) + [
        enc_lw(4, 2, 0x14),         # x4 = I2C DATA
        enc_sw(4, 2, 0x04),         # UART TX = x4
        EBREAK,
    ]

    assert len(words) <= 64

    dut._log.info("========== SYSTEM I2C read to UART TX ==========")

    await reset_and_program(dut, words, run_uio_in=0x0E)

    cocotb.start_soon(drive_i2c_read_byte(dut, 0x5A))

    await release_reset_safe(dut)

    observed = await read_uart_tx_byte(dut, clks_per_bit=8, timeout_cycles=3500)

    dut._log.info(f"SYSTEM I2C->UART byte = 0x{observed:02x}")
    assert observed == 0x5A, f"Expected UART byte 0x5A from I2C path, got 0x{observed:02x}"

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

    gls = is_gate_level_sim(dut)

    await subtest_core_alu_and_mmio(dut)
    await subtest_core_slt_sltu(dut)
    await subtest_core_compare_branches(dut)
    await subtest_core_shift_immediates(dut)
    await subtest_core_shift_registers(dut)
    await subtest_core_auipc(dut)
    await subtest_core_high_program_memory(dut)
    await subtest_core_branch_jump_regfile(dut)
    await subtest_uart_tx(dut)
    await subtest_uart_printf_ok(dut)

    if gls:
        dut._log.info("GLS mode: skipping asynchronous UART RX subtests; covered in RTL")
    else:
        await subtest_uart_rx_data_status_clear(dut)
        await subtest_uart_rx_overrun(dut)

    await subtest_i2c_write_ack(dut)
    await subtest_i2c_write_nack(dut)
    await subtest_irq_i2c_done(dut)

    if gls:
        dut._log.info("GLS mode: skipping dynamic I2C slave system tests; covered in RTL")
    else:
        await subtest_i2c_read_byte(dut)
        await subtest_system_i2c_to_uart(dut)

    if gls:
        dut._log.info("GLS mode: skipping UART-RX-driven IRQ subtests; covered in RTL")
    else:
        await subtest_irq_wfi_uart_rx(dut)
        await subtest_irq_status_uart_rx(dut)
        await subtest_irq_enable_masks_uart_rx(dut)
        await subtest_irq_return_uart_rx(dut)

    dut._log.info("All split regression subtests passed")

