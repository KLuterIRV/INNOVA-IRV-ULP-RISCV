# External Parallel Loader

This folder documents the recommended external microcontroller loader for the INNOVA IRV TinyTapeout core.

The ASIC already supports a parallel SRAM boot interface during reset. The external loader automates that interface using a small microcontroller such as an RP2040, STM32, Arduino, or ESP32.

## Purpose

The external loader avoids adding a UART bootloader FSM inside the ASIC.

Benefits:

- No extra ASIC area.
- No extra ASIC routing pressure.
- Faster program loading.
- Existing UART/I2C pins remain available during normal execution.
- The ASIC can focus on CPU, IRQ, WFI, GPIO, UART, I2C, and ISA support.

## Recommended workflow

```text
program.hex
   |
   v
tools/make_parallel_image.py
   |
   v
program_128b.bin
   |
   v
PC sends 128 bytes over USB serial
   |
   v
external microcontroller
   |
   v
parallel boot pins
   |
   v
ASIC SRAM
```

## Boot pin mapping

During reset/programming:

| ASIC signal | Function |
|---|---|
| `clk` | Boot write clock |
| `rst_n` | Reset, active low |
| `ui_in[0]` | Boot write enable |
| `ui_in[7:1]` | Boot byte address |
| `uio_in[7:0]` | Boot byte data |

## External loader algorithm

```c
hold_reset_low();

for (uint8_t addr = 0; addr < 128; addr++) {
    uint8_t data = receive_byte_from_usb_serial();
    set_ui_in_address(addr);
    set_uio_in_data(data);
    set_boot_we_high();
    pulse_asic_clk();
    set_boot_we_low();
}

set_boot_gpio_pins_to_input_high_z();
release_reset_high();
```

## Normal reset

For a normal reset without modifying SRAM:

```c
set_boot_we_low();
hold_reset_low();
pulse_or_wait_some_cycles();
release_reset_high();
```

## Program-load reset

For a reset that also reloads SRAM:

```c
hold_reset_low();
program_128_bytes();
release_parallel_pins();
release_reset_high();
```

## Pin sharing after boot

The external loader must release shared pins after programming.

During normal execution, the ASIC may use the same physical pins for:

- UART TX/RX
- I2C SCL/SDA
- GPIO/debug

Therefore the external controller should configure unused GPIOs as inputs/high-Z after boot.

## Minimal host-side command

Example host command:

```bash
python3 tools/make_parallel_image.py program.hex build/program_128b.bin
python3 tools/send_parallel_image.py build/program_128b.bin /dev/ttyACM0
```

`send_parallel_image.py` can be added later once a specific microcontroller protocol is selected.
