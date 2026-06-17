# INNOVA IRV Parallel SRAM Bootloader

The INNOVA IRV TinyTapeout design supports an external parallel SRAM programming mode. This allows the internal instruction SRAM to be loaded before the CPU starts executing.

The loader is external to the ASIC. A small microcontroller, FPGA, or GPIO adapter can be used to drive the boot pins.

## Reset modes

The design supports two practical reset flows.

### 1. Normal reset

A normal reset restarts the CPU without modifying SRAM.

External behavior:

1. Hold `rst_n = 0`.
2. Keep `ui_in[0] = 0`.
3. Do not generate SRAM write pulses.
4. Release `rst_n = 1`.

Result:

- SRAM content is preserved.
- CPU restarts from `PC = 0x00000000`.

This is useful when the program has already been loaded and only the CPU must be restarted.

### 2. Program-load reset

A program-load reset writes the internal SRAM while the CPU is held in reset.

During `rst_n = 0`, the boot pins are interpreted as:

| Signal | Direction | Function |
|---|---:|---|
| `clk` | input | Boot write clock |
| `rst_n` | input | Reset, active low |
| `ui_in[0]` | input | Boot write enable |
| `ui_in[7:1]` | input | Boot byte address, 0 to 127 |
| `uio_in[7:0]` | input | Boot byte data |

Write sequence for one byte:

1. Set `ui_in[7:1]` to the target byte address.
2. Set `uio_in[7:0]` to the byte data.
3. Set `ui_in[0] = 1`.
4. Pulse `clk`.
5. Set `ui_in[0] = 0`.

After all bytes are written:

1. Configure the external boot driver pins as inputs or high-Z, especially the shared `uio` pins.
2. Release `rst_n = 1`.
3. The CPU starts execution from `PC = 0x00000000`.

## SRAM size

The internal program SRAM stores:

```text
128 bytes = 32 RV32 instructions
```

The valid boot byte address range is:

```text
0x00 to 0x7F
```

## Instruction byte order

RV32 instructions must be loaded little-endian.

For an instruction word:

```text
instr = 0xAABBCCDD
```

the boot byte order is:

```text
address N+0 -> 0xDD
address N+1 -> 0xCC
address N+2 -> 0xBB
address N+3 -> 0xAA
```

## Recommended external controller

A small external controller can automate the process:

- RP2040 / Raspberry Pi Pico
- STM32
- Arduino
- ESP32
- FTDI GPIO/MPSSE adapter
- Small FPGA board

Recommended external flow:

```text
PC host
  |
  | USB serial
  v
External microcontroller
  |
  | clk, rst_n, ui_in[7:0], uio_in[7:0]
  v
INNOVA IRV ASIC
```

## Important pin-sharing rule

The parallel boot pins are only used during reset/programming.

During execution, the same pins may be reused for runtime peripherals such as UART, I2C, GPIO, or debug.

The external boot controller must release the shared pins after programming:

```text
after programming:
  external MCU GPIOs -> input/high-Z
  release rst_n
```

This avoids contention with the ASIC during normal execution.

## Minimal external loader algorithm

```c
hold_reset_low();

for (addr = 0; addr < 128; addr++) {
    data = receive_program_byte();

    set_boot_address(addr);
    set_boot_data(data);

    set_boot_we(1);
    pulse_clk();
    set_boot_we(0);
}

release_boot_pins_to_high_z();
release_reset_high();
```

## Recommended image format

The recommended program image is a raw binary file of exactly 128 bytes.

If the program is shorter than 128 bytes, unused bytes should be padded with zero.

The helper script `tools/make_parallel_image.py` converts a text hex file containing 32-bit instructions into a 128-byte binary image.
