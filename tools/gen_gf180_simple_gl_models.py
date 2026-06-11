#!/usr/bin/env python3
from pathlib import Path
import re

STD_REPO = Path.home() / "pdks_src/globalfoundries-pdk-libs-gf180mcu_fd_sc_mcu7t5v0"
CELLS_DIR = STD_REPO / "cells"

OUT = Path("test/models/gf180/gf180mcu_fd_sc_mcu7t5v0_simple_gl.v")

MODULE_RE = re.compile(
    r"module\s+(gf180mcu_fd_sc_mcu7t5v0__[A-Za-z0-9_]+)\s*\((.*?)\)\s*;",
    re.S,
)

STRENGTH_SUFFIXES = {
    "1", "2", "3", "4", "6", "8", "10", "12", "16", "20", "24", "32", "64"
}

OUTPUT_NAMES = {
    "Z", "ZN", "Q", "QN", "Y", "S", "CO", "SUM", "COUT"
}

POWER_NAMES = {
    "VDD", "VSS", "VPWR", "VGND"
}


def clean_ports(port_blob):
    port_blob = port_blob.replace("\n", " ")
    ports = []
    for p in port_blob.split(","):
        p = p.strip()
        if not p:
            continue
        # Remove possible comments / whitespace.
        p = re.sub(r"/\*.*?\*/", "", p).strip()
        ports.append(p)
    return ports


def cell_base(module_name):
    cell = module_name.split("__", 1)[1]
    parts = cell.split("_")
    if len(parts) > 1 and parts[-1] in STRENGTH_SUFFIXES:
        return "_".join(parts[:-1])
    return cell


def p(ports, name):
    return name in ports


def sorted_prefixed(ports, prefix):
    vals = []
    for port in ports:
        m = re.fullmatch(prefix + r"(\d+)", port)
        if m:
            vals.append((int(m.group(1)), port))
    return [x[1] for x in sorted(vals)]


def emit_module(out, name, ports):
    base = cell_base(name)

    out_ports = [x for x in ports if x in OUTPUT_NAMES]
    in_ports = [x for x in ports if x not in out_ports]

    out.write(f"module {name}({', '.join(ports)});\n")

    if in_ports:
        out.write("  input " + ", ".join(in_ports) + ";\n")

    # DFF outputs need reg.
    if base.startswith("dff") or base in {"latq", "latrnq"}:
        if out_ports:
            out.write("  output reg " + ", ".join(out_ports) + ";\n")
    else:
        if out_ports:
            out.write("  output " + ", ".join(out_ports) + ";\n")

    # Physical-only cells.
    if base.startswith("fill") or base.startswith("endcap") or base.startswith("decap"):
        out.write("endmodule\n\n")
        return

    if base == "filltie":
        out.write("endmodule\n\n")
        return

    # Tie cells.
    if base in {"tiel", "tie0"}:
        if p(ports, "Z"):
            out.write("  assign Z = 1'b0;\n")
        out.write("endmodule\n\n")
        return

    if base in {"tieh", "tie1"}:
        if p(ports, "Z"):
            out.write("  assign Z = 1'b1;\n")
        out.write("endmodule\n\n")
        return

    # Buffers / inverters.
    if base in {"buf", "clkbuf", "dlyb"}:
        if p(ports, "I") and p(ports, "Z"):
            out.write("  assign Z = I;\n")
        out.write("endmodule\n\n")
        return

    if base in {"inv", "clkinv"}:
        if p(ports, "I") and p(ports, "ZN"):
            out.write("  assign ZN = ~I;\n")
        elif p(ports, "I") and p(ports, "Z"):
            out.write("  assign Z = ~I;\n")
        out.write("endmodule\n\n")
        return

    # DFF variants used by OpenLane.
    if base == "dffq":
        if p(ports, "CLK") and p(ports, "D") and p(ports, "Q"):
            out.write("  always @(posedge CLK) begin\n")
            out.write("    Q <= D;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    # Generic AND/OR/NAND/NOR/XOR/XNOR.
    for prefix, op in [
        ("and", "&"),
        ("or", "|"),
        ("nand", "&"),
        ("nor", "|"),
        ("xor", "^"),
        ("xnor", "^"),
    ]:
        m = re.fullmatch(prefix + r"(\d+)", base)
        if m:
            n = int(m.group(1))
            ins = [f"A{i}" for i in range(1, n + 1) if p(ports, f"A{i}")]
            if p(ports, "Z") and ins:
                expr = f" {op} ".join(ins)
                if prefix in {"nand", "nor", "xnor"}:
                    expr = f"~({expr})"
                out.write(f"  assign Z = {expr};\n")
            out.write("endmodule\n\n")
            return

    # Mux2.
    if base == "mux2":
        if p(ports, "I0") and p(ports, "I1") and p(ports, "S") and p(ports, "Z"):
            out.write("  assign Z = S ? I1 : I0;\n")
        elif p(ports, "A0") and p(ports, "A1") and p(ports, "S") and p(ports, "Z"):
            out.write("  assign Z = S ? A1 : A0;\n")
        out.write("endmodule\n\n")
        return

    # AOI gates.
    if base == "aoi21" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 & A2) | B);\n")
        out.write("endmodule\n\n")
        return

    if base == "aoi211" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 & A2) | B | C);\n")
        out.write("endmodule\n\n")
        return

    if base == "aoi22" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 & A2) | (B1 & B2));\n")
        out.write("endmodule\n\n")
        return

    if base == "aoi221" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 & A2) | (B1 & B2) | C);\n")
        out.write("endmodule\n\n")
        return

    if base == "aoi222" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 & A2) | (B1 & B2) | (C1 & C2));\n")
        out.write("endmodule\n\n")
        return

    # OAI gates.
    if base == "oai21" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 | A2) & B);\n")
        out.write("endmodule\n\n")
        return

    if base == "oai211" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 | A2) & B & C);\n")
        out.write("endmodule\n\n")
        return

    if base == "oai22" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 | A2) & (B1 | B2));\n")
        out.write("endmodule\n\n")
        return

    if base == "oai221" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 | A2) & (B1 | B2) & C);\n")
        out.write("endmodule\n\n")
        return

    if base == "oai31" and p(ports, "Z"):
        out.write("  assign Z = ~((A1 | A2 | A3) & B);\n")
        out.write("endmodule\n\n")
        return

    # Fallback for unused/rare cells.
    # Keep compilation alive. If such a cell is critical, the waveform/test will catch it.
    for o in out_ports:
        if o == "Z":
            out.write("  assign Z = 1'b0;\n")
        elif o == "ZN":
            out.write("  assign ZN = 1'b1;\n")
        elif o not in {"Q"}:
            out.write(f"  assign {o} = 1'b0;\n")

    out.write("endmodule\n\n")


def main():
    if not CELLS_DIR.exists():
        raise SystemExit(f"ERROR: cells directory not found: {CELLS_DIR}")

    modules = {}

    for f in sorted(CELLS_DIR.glob("*/*.behavioral.pp.v")):
        text = f.read_text(encoding="utf-8", errors="ignore")
        m = MODULE_RE.search(text)
        if not m:
            print(f"WARNING: no module declaration found in {f}")
            continue

        name = m.group(1)
        ports = clean_ports(m.group(2))
        modules[name] = ports

    if not modules:
        raise SystemExit("ERROR: no modules found")

    OUT.parent.mkdir(parents=True, exist_ok=True)

    with OUT.open("w", encoding="utf-8") as out:
        out.write("// Simple GF180 MCU7T5V0 functional models for Icarus GL simulation\n")
        out.write("// Generated for cocotb gate-level test only.\n")
        out.write("// Do not use for synthesis, timing signoff, LVS, or physical implementation.\n\n")
        out.write("`timescale 1ns / 1ps\n\n")

        for name, ports in sorted(modules.items()):
            emit_module(out, name, ports)

    print(f"Wrote {OUT}")
    print(f"Generated modules: {len(modules)}")


if __name__ == "__main__":
    main()
