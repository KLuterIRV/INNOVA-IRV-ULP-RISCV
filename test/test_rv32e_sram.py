import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock


async def tick(dut, n=1):
    for _ in range(n):
        await RisingEdge(dut.clk)


async def write_byte(dut, addr, data):
    """
    Programming mode:
      rst_n = 0
      ui_in[0]   = write enable
      ui_in[7:1] = byte address
      uio_in     = byte data
    """
    dut.ui_in.value = ((addr & 0x7F) << 1) | 1
    dut.uio_in.value = data & 0xFF
    await tick(dut, 1)

    # Deassert write enable after write
    dut.ui_in.value = ((addr & 0x7F) << 1)
    await tick(dut, 1)


@cocotb.test()
async def test_minimal_program_writes_0x55(dut):
    """
    Program:
        addi x1, x0, 0x55
        lui  x2, 0x10000
        sw   x1, 0(x2)
        ebreak

    Expected:
        uo_out = 0x55
    """

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await tick(dut, 5)

    # Little-endian program bytes
    program = [
        0x93, 0x00, 0x50, 0x05,  # 0x05500093 addi x1, x0, 0x55
        0x37, 0x01, 0x00, 0x10,  # 0x10000137 lui  x2, 0x10000
        0x23, 0x20, 0x11, 0x00,  # 0x00112023 sw   x1, 0(x2)
        0x73, 0x00, 0x10, 0x00,  # 0x00100073 ebreak
    ]

    for addr, byte in enumerate(program):
        await write_byte(dut, addr, byte)

    # Stop programming
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await tick(dut, 3)

    # Release reset: core starts from PC=0
    dut.rst_n.value = 1

    # Wait enough cycles:
    # Each instruction takes roughly:
    #   S_ADDR_LO -> S_CAP_LO -> S_CAP_HI -> S_EXEC
    # plus SRAM sync latency margin.
    for _ in range(80):
        await RisingEdge(dut.clk)

    assert int(dut.uo_out.value) == 0x55, (
        f"Expected uo_out=0x55, got 0x{int(dut.uo_out.value):02x}"
    )