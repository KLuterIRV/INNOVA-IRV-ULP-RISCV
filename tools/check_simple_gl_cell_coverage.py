#!/usr/bin/env python3
from pathlib import Path
import re
import sys

if len(sys.argv) != 3:
    print("Usage: tools/check_simple_gl_cell_coverage.py <gate_netlist.v> <simple_gl_model.v>")
    sys.exit(1)

netlist = Path(sys.argv[1])
model = Path(sys.argv[2])

net_txt = netlist.read_text(errors="ignore")
mod_txt = model.read_text(errors="ignore")

used = set(re.findall(r"\b(gf180mcu_fd_sc_mcu7t5v0__[A-Za-z0-9_]+)\s+[A-Za-z0-9_]+\s*\(", net_txt))
defined = set(re.findall(r"\bmodule\s+(gf180mcu_fd_sc_mcu7t5v0__[A-Za-z0-9_]+)\s*\(", mod_txt))

missing = sorted(used - defined)

if missing:
    print("Missing GL models:")
    for m in missing:
        print("  " + m)
    sys.exit(1)

print(f"All used GF180 cells have a model. Count: {len(used)}")
