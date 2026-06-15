#!/usr/bin/env python3
from pathlib import Path
import re
import sys

if len(sys.argv) != 3:
    print("Usage: tools/check_gl_model_fallbacks.py <gate_level_netlist.v> <simple_gl_model.v>")
    sys.exit(1)

netlist = Path(sys.argv[1])
model = Path(sys.argv[2])

net_txt = netlist.read_text(errors="ignore")
mod_txt = model.read_text(errors="ignore")

used = sorted(set(re.findall(
    r"\b(gf180mcu_fd_sc_mcu7t5v0__[A-Za-z0-9_]+)\s+[A-Za-z0-9_]+\s*\(",
    net_txt
)))

problem = []

for cell in used:
    m = re.search(
        r"module\s+" + re.escape(cell) + r"\s*\(.*?\);\n(.*?)endmodule",
        mod_txt,
        re.S,
    )

    if not m:
        problem.append((cell, "missing module"))
        continue

    body = m.group(1)

    # Physical-only cells are allowed to be empty.
    base = cell.split("__", 1)[1]
    if base.startswith(("fill", "endcap", "decap")) or base == "filltie":
        continue

    # Flag suspicious fallback-only cells.
    has_assign_or_always = ("assign" in body) or ("always" in body)
    only_zero_assign = bool(re.search(r"assign\s+\w+\s*=\s*1'b0\s*;", body)) and body.count("assign") == 1

    if not has_assign_or_always:
        problem.append((cell, "empty functional model"))
    elif only_zero_assign:
        problem.append((cell, "single zero fallback"))

if problem:
    print("Suspicious GL cell models used by the netlist:")
    for cell, reason in problem:
        print(f"  {cell}: {reason}")
    sys.exit(1)

print(f"No obvious fallback-only used cells detected. Used cells: {len(used)}")
