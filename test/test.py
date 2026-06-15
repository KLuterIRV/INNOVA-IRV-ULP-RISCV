import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


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


def set_uio_inputs(dut, scl, sda):
    # uio_in[1] = UART RX idle high
    # uio_in[2] = I2C SCL input
    # uio_in[3] = I2C SDA input
    value = 0x02
    if scl:
        value |= 0x04
    if sda:
        value |= 0x08
    dut.uio_in.value = value


def get_i2c_lines(dut, slave_ack_low):
    uio_oe = int(dut.uio_oe.value) if dut.uio_oe.value.is_resolvable else 0

    # Open-drain bus model:
    # OE high means master drives the line low.
    # OE low means line is pulled high unless slave drives ACK low.
    scl = 0 if (uio_oe & 0x04) else 1

    if uio_oe & 0x08:
        sda = 0
    else:
        sda = 0 if slave_ack_low else 1

    return scl, sda


async def capture_i2c_write_transactions(dut, expected_bytes):
    """
    Robust I2C slave emulator:
      - Waits for START.
      - Captures exactly 8 bits on SCL rising edges.
      - Pulls SDA low for ACK.
      - Waits for STOP.
      - Repeats for the next transaction.
    """

    dut._log.info("I2C slave emulator waiting for independent write transactions")

    captured = []
    state = "WAIT_START"
    bits = []
    slave_ack_low = False

    prev_scl = 1
    prev_sda = 1

    set_uio_inputs(dut, 1, 1)

    for _ in range(2000):
        await RisingEdge(dut.clk)

        scl, sda = get_i2c_lines(dut, slave_ack_low)
        set_uio_inputs(dut, scl, sda)

        start_seen = (prev_sda == 1 and sda == 0 and scl == 1)
        stop_seen = (prev_sda == 0 and sda == 1 and scl == 1)
        scl_rise = (prev_scl == 0 and scl == 1)
        scl_fall = (prev_scl == 1 and scl == 0)

        if state == "WAIT_START":
            if start_seen:
                dut._log.info("I2C START detected")
                bits = []
                state = "CAPTURE_BYTE"

        elif state == "CAPTURE_BYTE":
            if scl_rise:
                bits.append(sda)

                if len(bits) == 8:
                    byte = 0
                    for bit in bits:
                        byte = (byte << 1) | bit

                    captured.append(byte)
                    dut._log.info(f"I2C captured byte {len(captured)} = 0x{byte:02x}")

                    expected = expected_bytes[len(captured) - 1]
                    assert byte == expected, (
                        f"Expected byte {len(captured)} = 0x{expected:02x}, got 0x{byte:02x}"
                    )

                    slave_ack_low = True
                    state = "ACK"

        elif state == "ACK":
            # Hold ACK low while SCL is high, release after falling edge.
            if scl_fall:
                slave_ack_low = False
                state = "WAIT_STOP"

        elif state == "WAIT_STOP":
            if stop_seen:
                dut._log.info("I2C STOP detected")

                if len(captured) == len(expected_bytes):
                    set_uio_inputs(dut, 1, 1)
                    dut._log.info("All expected I2C write transactions captured")
                    return

                state = "WAIT_START"

        prev_scl = scl
        prev_sda = sda

    raise AssertionError(f"I2C timeout, captured={captured}")


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start RV32E I2C0 automatic stall test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    set_uio_inputs(dut, 1, 1)
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    # Program:
    #   x2 = 0x1000_0000
    #   I2C0_DIV = 0
    #
    #   DATA = 0x80
    #   CTRL = START + WRITE + STOP
    #
    #   DATA = 0x12
    #   CTRL = START + WRITE + STOP
    #
    # The second CTRL must stall until the first transaction completes.
    words = [
        enc_lui(2, 0x10000),

        enc_addi(4, 0, 0x00),
        enc_sw(4, 2, 0x1C),        # I2C0_DIV = 0

        enc_addi(4, 0, 0x080),
        enc_sw(4, 2, 0x14),        # I2C0_DATA = 0x80

        enc_addi(4, 0, 0x07),      # START + WRITE + STOP
        enc_sw(4, 2, 0x10),        # I2C0_CTRL

        enc_addi(4, 0, 0x012),
        enc_sw(4, 2, 0x14),        # I2C0_DATA = 0x12

        enc_addi(4, 0, 0x07),      # START + WRITE + STOP
        enc_sw(4, 2, 0x10),        # I2C0_CTRL, should stall if I2C busy
    ]

    for _ in range(12):
        words.append(enc_addi(0, 0, 0))

    words += [
        enc_lw(4, 2, 0x18),        # I2C0_STATUS
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
    set_uio_inputs(dut, 1, 1)

    await ClockCycles(dut.clk, 5)

    dut._log.info("Release reset and execute I2C stall program")
    dut.rst_n.value = 1

    await capture_i2c_write_transactions(dut, [0x80, 0x12])

    await ClockCycles(dut.clk, 80)

    observed_status = int(dut.uo_out.value)
    dut._log.info(f"I2C0 status via uo_out = 0x{observed_status:02x}")

    # Expected status after ACKed write:
    # bit0 busy      = 0
    # bit1 done      = 1
    # bit2 ack_error = 0
    # bit3 rx_valid  = 0
    # bit4 scl_in    = 1
    # bit5 sda_in    = 1
    expected = 0x32

    assert observed_status == expected, (
        f"Expected I2C0 status 0x{expected:02x}, got 0x{observed_status:02x}"
    )
