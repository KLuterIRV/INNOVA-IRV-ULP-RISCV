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


def get_i2c_lines_from_master(dut, ack_drive_low):
    uio_oe = int(dut.uio_oe.value) if dut.uio_oe.value.is_resolvable else 0

    # Open-drain model:
    # If master enables OE on the line, it drives low.
    # If master releases the line, external pull-up makes it high,
    # except when the emulated slave drives ACK low on SDA.
    scl = 0 if (uio_oe & 0x04) else 1

    if uio_oe & 0x08:
        sda = 0
    else:
        sda = 0 if ack_drive_low else 1

    return scl, sda


async def emulate_i2c_ack_slave(dut, expected_byte):
    dut._log.info("I2C slave emulator waiting for START")

    captured = []
    started = False
    ack_drive_low = False
    ack_seen = False

    prev_scl = 1
    prev_sda = 1

    set_uio_inputs(dut, 1, 1)

    for _ in range(400):
        await RisingEdge(dut.clk)

        scl, sda = get_i2c_lines_from_master(dut, ack_drive_low)
        set_uio_inputs(dut, scl, sda)

        # START condition: SDA falls while SCL is high.
        if not started and prev_sda == 1 and sda == 0 and scl == 1:
            started = True
            captured = []
            dut._log.info("I2C START detected")

        # Sample data on SCL rising edge after START.
        if started and prev_scl == 0 and scl == 1:
            if len(captured) < 8:
                captured.append(sda)
                if len(captured) == 8:
                    byte = 0
                    for bit in captured:
                        byte = (byte << 1) | bit

                    dut._log.info(f"I2C captured byte = 0x{byte:02x}")
                    assert byte == expected_byte, (
                        f"Expected I2C byte 0x{expected_byte:02x}, got 0x{byte:02x}"
                    )

                    # Pull SDA low for ACK bit.
                    ack_drive_low = True
            else:
                # ACK rising edge happened while slave is pulling SDA low.
                ack_seen = True

        # Release ACK after SCL falls again.
        if ack_drive_low and prev_scl == 1 and scl == 0 and len(captured) == 8:
            ack_drive_low = False

        prev_scl = scl
        prev_sda = sda

        if ack_seen:
            # Keep bus released after ACK.
            set_uio_inputs(dut, 1, 1)
            dut._log.info("I2C ACK completed")
            return

    raise AssertionError("I2C slave emulator timeout")


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start RV32E I2C0 INA3221-like address ACK test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    set_uio_inputs(dut, 1, 1)
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    # INA3221 commonly uses 7-bit address 0x40 depending on A0 strap.
    # Address byte for write transaction is 0x40 << 1 = 0x80.
    words = [
        enc_lui(2, 0x10000),       # x2 = 0x1000_0000

        enc_addi(4, 0, 0x00),      # x4 = 0
        enc_sw(4, 2, 0x1C),        # I2C0_DIV = 0, fastest simulation

        enc_addi(4, 0, 0x080),     # x4 = 0x80
        enc_sw(4, 2, 0x14),        # I2C0_DATA = 0x80

        enc_addi(4, 0, 0x07),      # START + STOP + WRITE_BYTE
        enc_sw(4, 2, 0x10),        # I2C0_CTRL = 0x07
    ]

    # Wait for I2C byte engine to complete.
    for _ in range(10):
        words.append(enc_addi(0, 0, 0))

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
    set_uio_inputs(dut, 1, 1)

    await ClockCycles(dut.clk, 5)

    dut._log.info("Release reset and execute I2C test program")
    dut.rst_n.value = 1

    # Emulate INA3221-like ACK on address byte 0x80.
    await emulate_i2c_ack_slave(dut, expected_byte=0x80)

    await ClockCycles(dut.clk, 80)

    observed_status = int(dut.uo_out.value)
    observed_oe = int(dut.uio_oe.value)
    observed_out = int(dut.uio_out.value)

    dut._log.info(f"I2C0 status via uo_out = 0x{observed_status:02x}")
    dut._log.info(f"uio_oe  = 0x{observed_oe:02x}")
    dut._log.info(f"uio_out = 0x{observed_out:02x}")

    # Expected status after ACKed write:
    # bit0 busy      = 0
    # bit1 done      = 1
    # bit2 ack_error = 0 because slave ACKed
    # bit3 rx_valid  = 0
    # bit4 scl_in    = 1
    # bit5 sda_in    = 1
    expected = 0x32

    assert observed_status == expected, (
        f"Expected I2C0 status 0x{expected:02x}, got 0x{observed_status:02x}"
    )
