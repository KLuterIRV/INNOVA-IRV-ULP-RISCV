# Minimal RV32E SoC with UART Loader

This project implements a minimal RV32E-based microcontroller for Tiny Tapeout.

## Features

- Simplified RV32E CPU core
- 16 x 32-bit register file
- Internal instruction memory, programmable through UART
- Internal data memory and memory-mapped peripherals
- UART RX program loader
- UART TX output
- Shared 8-bit GPIO / seven-segment output
- Configurable seven-segment mode:
  - GPIO mode
  - HEX mode
  - ASCII mode
  - RAW segment mode
- `ebreak`-based halt/debug signal

## Pinout

| Pin | Function |
|---|---|
| `ui_in[0]` | Boot mode enable |
| `ui_in[1]` | UART RX |
| `uo_out[7:0]` | GPIO output or seven-segment output |
| `uio_out[0]` | UART TX |
| `uio_out[1]` | Core halted debug |
| `uio_out[2]` | Loader done debug |
| `uio_out[3]` | Loader error debug |

## UART loader protocol

The loader is enabled when `boot_mode = 1`.

Protocol:

```text
0x55
N_WORDS
WORD0 byte0
WORD0 byte1
WORD0 byte2
WORD0 byte3
...