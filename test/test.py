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
    dut._log.info("Start RV32E I2C0 minimal peripheral test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x0E  # UART RX idle high + I2C SCL/SDA pulled high
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    words = [
        enc_lui(2, 0x10000),     # x2 = 0x1000_0000

        enc_lw(4, 2, 0x18),      # x4 = I2C0 status, expect SCL/SDA input high -> 0x03
        enc_sw(4, 2, 0x00),      # GPIO output = status

        enc_addi(4, 0, 0x03),    # x4 = 0x03, drive SCL/SDA low
        enc_sw(4, 2, 0x10),      # I2C0 control = 0x03

        0x00100073,              # ebreak
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

    dut._log.info("Release reset and execute program")
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 120)

    observed_status = int(dut.uo_out.value)
    observed_uio_oe = int(dut.uio_oe.value)
    observed_uio_out = int(dut.uio_out.value)

    dut._log.info(f"uo_out status = 0x{observed_status:02x}")
    dut._log.info(f"uio_oe       = 0x{observed_uio_oe:02x}")
    dut._log.info(f"uio_out      = 0x{observed_uio_out:02x}")

    assert observed_status == 0x03, f"Expected I2C status 0x03, got 0x{observed_status:02x}"

    # uio_oe[2] and uio_oe[3] must be enabled after writing control=0x03.
    assert (observed_uio_oe & 0x0C) == 0x0C, f"Expected I2C OE bits high, got uio_oe=0x{observed_uio_oe:02x}"

    # Open-drain drive-low means output values on SCL/SDA are 0.
    assert (observed_uio_out & 0x0C) == 0x00, f"Expected I2C output bits low, got uio_out=0x{observed_uio_out:02x}"
