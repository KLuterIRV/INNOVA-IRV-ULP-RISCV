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


def enc_lw(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (2 << 12) | ((rd & 0x1F) << 7) | 0x03


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
    dut._log.info("Start RV32E I2C0 byte-engine test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0

    # uio_in:
    # bit 1 = UART RX idle high
    # bit 2 = I2C SCL pulled high
    # bit 3 = I2C SDA pulled high
    dut.uio_in.value = 0x0E
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    words = [
        enc_lui(2, 0x10000),       # x2 = 0x1000_0000

        enc_addi(4, 0, 0x01),      # x4 = 1
        enc_sw(4, 2, 0x1C),        # I2C0_DIV = 1

        enc_addi(4, 0, 0x0A0),     # x4 = 0xA0
        enc_sw(4, 2, 0x14),        # I2C0_DATA = 0xA0

        enc_addi(4, 0, 0x07),      # START + STOP + WRITE
        enc_sw(4, 2, 0x10),        # I2C0_CTRL = 0x07
    ]

    # Wait for I2C engine to complete.
    for _ in range(16):
        words.append(enc_addi(0, 0, 0))  # NOP

    words += [
        enc_lw(4, 2, 0x18),        # x4 = I2C0_STATUS
        enc_sw(4, 2, 0x00),        # GPIO output = status
        0x00100073,                # EBREAK
    ]

    program = []
    for word in words:
        program += word_to_bytes(word)

    assert len(program) <= 128, f"Program too large: {len(program)} bytes"

    dut._log.info("Reset and program SRAM")
    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)

    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E

    await ClockCycles(dut.clk, 5)

    dut._log.info("Release reset and execute program")
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 220)

    observed_status = int(dut.uo_out.value)
    observed_oe = int(dut.uio_oe.value)
    observed_out = int(dut.uio_out.value)

    dut._log.info(f"I2C0 status via uo_out = 0x{observed_status:02x}")
    dut._log.info(f"uio_oe  = 0x{observed_oe:02x}")
    dut._log.info(f"uio_out = 0x{observed_out:02x}")

    # Expected:
    # bit0 busy      = 0
    # bit1 done      = 1
    # bit2 ack_error = 1 because SDA input remains high during ACK
    # bit3 rx_valid  = 0
    # bit4 scl_in    = 1
    # bit5 sda_in    = 1
    expected = 0x36

    assert observed_status == expected, (
        f"Expected I2C0 status 0x{expected:02x}, got 0x{observed_status:02x}"
    )
