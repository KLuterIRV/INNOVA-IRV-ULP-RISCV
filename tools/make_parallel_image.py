#!/usr/bin/env python3
"""
Create a 256-byte parallel boot image for the INNOVA IRV TinyTapeout core.

Input:
    Text file with one 32-bit RV32 instruction per line, in hexadecimal.

Example input:
    10000137
    00100213
    02412023
    10500073

Output:
    Raw 256-byte binary image, little-endian per 32-bit instruction.

Usage:
    python3 tools/make_parallel_image.py program.hex program_128b.bin

Notes:
    - Maximum program size is 64 RV32 instructions.
    - The output is always exactly 256 bytes.
    - Empty lines and comments starting with # are ignored.
"""

from __future__ import annotations

import argparse
from pathlib import Path

IMAGE_SIZE_BYTES = 256
MAX_WORDS = IMAGE_SIZE_BYTES // 4


def parse_hex_words(path: Path) -> list[int]:
    words: list[int] = []
    for line_number, raw_line in enumerate(path.read_text().splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "#" in line:
            line = line.split("#", 1)[0].strip()
        if line.lower().startswith("0x"):
            line = line[2:]
        line = line.replace("_", "")
        if not line:
            continue
        if len(line) > 8:
            raise ValueError(f"{path}:{line_number}: instruction has more than 8 hex digits: {raw_line!r}")
        try:
            word = int(line, 16)
        except ValueError as exc:
            raise ValueError(f"{path}:{line_number}: invalid hexadecimal instruction: {raw_line!r}") from exc
        if word < 0 or word > 0xFFFFFFFF:
            raise ValueError(f"{path}:{line_number}: instruction outside 32-bit range: {raw_line!r}")
        words.append(word)
    if len(words) > MAX_WORDS:
        raise ValueError(f"Program too large: {len(words)} words. Maximum is {MAX_WORDS} words / {IMAGE_SIZE_BYTES} bytes.")
    return words


def words_to_image(words: list[int]) -> bytes:
    image = bytearray()
    for word in words:
        image += word.to_bytes(4, byteorder="little", signed=False)
    while len(image) < IMAGE_SIZE_BYTES:
        image.append(0x00)
    if len(image) != IMAGE_SIZE_BYTES:
        raise RuntimeError("Internal error: image size mismatch")
    return bytes(image)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a 256-byte parallel boot image for INNOVA IRV.")
    parser.add_argument("input_hex", type=Path, help="Input text file with 32-bit hex instructions")
    parser.add_argument("output_bin", type=Path, help="Output raw 256-byte boot image")
    parser.add_argument("--dump", action="store_true", help="Print address/data byte table")
    args = parser.parse_args()
    words = parse_hex_words(args.input_hex)
    image = words_to_image(words)
    args.output_bin.parent.mkdir(parents=True, exist_ok=True)
    args.output_bin.write_bytes(image)
    print(f"Input words : {len(words)}")
    print(f"Output image: {args.output_bin}")
    print(f"Output size : {len(image)} bytes")
    if args.dump:
        for addr, byte in enumerate(image):
            print(f"0x{addr:02X}: 0x{byte:02X}")


if __name__ == "__main__":
    main()
