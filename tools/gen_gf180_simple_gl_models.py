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

DECL_RE = re.compile(
    r"\b(input|output|inout)\b\s+(?:wire\s+|reg\s+|logic\s+)?(?:\[[^\]]+\]\s*)?([^;]+);",
    re.S,
)

STRENGTH_SUFFIXES = {
    "1", "2", "3", "4", "6", "8", "10", "12", "16", "20", "24", "32", "64"
}


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    return text


def clean_ports(port_blob):
    port_blob = strip_comments(port_blob)
    port_blob = port_blob.replace("\n", " ")
    ports = []
    for p in port_blob.split(","):
        p = p.strip()
        if p:
            ports.append(p)
    return ports


def clean_decl_names(names_blob):
    names_blob = names_blob.replace("\n", " ")
    out = []
    for item in names_blob.split(","):
        item = item.strip()
        if not item:
            continue
        # Remove possible initialization or attributes.
        item = item.split("=")[0].strip()
        item = item.split()[-1].strip()
        if item:
            out.append(item)
    return out


def parse_directions(text):
    text_no_comments = strip_comments(text)
    dirs = {}

    for kind, names_blob in DECL_RE.findall(text_no_comments):
        for name in clean_decl_names(names_blob):
            dirs[name] = kind

    return dirs


def add_well_ports_if_needed(ports, dirs):
    # Match OpenLane/Tiny Tapeout powered netlists.
    # Some GF180 behavioral.pp cells expose VDD/VSS only, while the
    # generated netlist connects VDD/VNW/VPW/VSS.
    if "VDD" in ports and "VSS" in ports:
        insert_at = ports.index("VSS")

        if "VNW" not in ports:
            ports.insert(insert_at, "VNW")
            insert_at += 1

        if "VPW" not in ports:
            ports.insert(insert_at, "VPW")

        dirs["VNW"] = "input"
        dirs["VPW"] = "input"

    return ports, dirs


def cell_base(module_name):
    cell = module_name.split("__", 1)[1]
    parts = cell.split("_")

    if len(parts) > 1 and parts[-1] in STRENGTH_SUFFIXES:
        return "_".join(parts[:-1])

    return cell


def has(ports, name):
    return name in ports


def output_names(ports, dirs):
    return [x for x in ports if dirs.get(x) == "output"]


def input_names(ports, dirs):
    return [x for x in ports if dirs.get(x) == "input"]


def first_existing(items, names):
    for n in names:
        if n in items:
            return n
    return None


def gate_inputs(ports, dirs, n):
    return [f"A{i}" for i in range(1, n + 1) if dirs.get(f"A{i}") == "input"]


def write_assign(out, target, expr):
    if target:
        out.write(f"  assign {target} = {expr};\n")


def emit_module(out, name, ports, dirs):
    base = cell_base(name)

    outs = output_names(ports, dirs)
    ins = input_names(ports, dirs)
    inouts = [x for x in ports if dirs.get(x) == "inout"]

    out.write(f"module {name}({', '.join(ports)});\n")

    if ins:
        out.write("  input " + ", ".join(ins) + ";\n")

    if inouts:
        out.write("  inout " + ", ".join(inouts) + ";\n")

    sequential = (
        base.startswith("dff")
        or base.startswith("sdff")
        or base.startswith("lat")
    )

    if outs:
        if sequential:
            out.write("  output reg " + ", ".join(outs) + ";\n")
        else:
            out.write("  output " + ", ".join(outs) + ";\n")

    # ------------------------------------------------------------
    # Physical-only cells
    # ------------------------------------------------------------
    if (
        base.startswith("fill")
        or base.startswith("endcap")
        or base.startswith("decap")
        or base == "filltie"
    ):
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # Tie cells
    # ------------------------------------------------------------
    if base in {"tiel", "tie0"}:
        for o in outs:
            out.write(f"  assign {o} = 1'b0;\n")
        out.write("endmodule\n\n")
        return

    if base in {"tieh", "tie1"}:
        for o in outs:
            out.write(f"  assign {o} = 1'b1;\n")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # Buffers / inverters
    # ------------------------------------------------------------
    if base in {"buf", "clkbuf", "dlyb"}:
        target = first_existing(outs, ["Z", "ZN", "Q"])
        if has(ports, "I") and target:
            if target == "ZN":
                write_assign(out, target, "~I")
            else:
                write_assign(out, target, "I")
        out.write("endmodule\n\n")
        return

    if base in {"inv", "clkinv"}:
        target = first_existing(outs, ["ZN", "Z"])
        if has(ports, "I") and target:
            write_assign(out, target, "~I")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # Adders
    # ------------------------------------------------------------
    if base == "addf":
        if has(ports, "A") and has(ports, "B") and has(ports, "CI"):
            if "S" in outs:
                write_assign(out, "S", "A ^ B ^ CI")
            if "CO" in outs:
                write_assign(out, "CO", "(A & B) | (A & CI) | (B & CI)")
        out.write("endmodule\n\n")
        return

    if base == "addh":
        if has(ports, "A") and has(ports, "B"):
            if "S" in outs:
                write_assign(out, "S", "A ^ B")
            if "CO" in outs:
                write_assign(out, "CO", "A & B")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # DFF variants
    # ------------------------------------------------------------
    if base == "dffq":
        if has(ports, "CLK") and has(ports, "D") and "Q" in outs:
            out.write("  always @(posedge CLK) begin\n")
            out.write("    Q <= D;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    if base == "dffnq":
        if has(ports, "CLKN") and has(ports, "D") and "Q" in outs:
            out.write("  always @(posedge CLKN) begin\n")
            out.write("    Q <= D;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    if base == "dffrnq":
        if has(ports, "CLK") and has(ports, "D") and has(ports, "RN") and "Q" in outs:
            out.write("  always @(posedge CLK or negedge RN) begin\n")
            out.write("    if (!RN) Q <= 1'b0;\n")
            out.write("    else Q <= D;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    if base == "dffsnq":
        if has(ports, "CLK") and has(ports, "D") and has(ports, "SETN") and "Q" in outs:
            out.write("  always @(posedge CLK or negedge SETN) begin\n")
            out.write("    if (!SETN) Q <= 1'b1;\n")
            out.write("    else Q <= D;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    if base == "dffrsnq":
        if (
            has(ports, "CLK")
            and has(ports, "D")
            and has(ports, "RN")
            and has(ports, "SETN")
            and "Q" in outs
        ):
            out.write("  always @(posedge CLK or negedge RN or negedge SETN) begin\n")
            out.write("    if (!RN) Q <= 1'b0;\n")
            out.write("    else if (!SETN) Q <= 1'b1;\n")
            out.write("    else Q <= D;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    if base == "sdffq":
        if has(ports, "CLK") and has(ports, "D") and has(ports, "SE") and has(ports, "SI") and "Q" in outs:
            out.write("  wire _d_mux = SE ? SI : D;\n")
            out.write("  always @(posedge CLK) begin\n")
            out.write("    Q <= _d_mux;\n")
            out.write("  end\n")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # Generic gates
    # ------------------------------------------------------------
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
            args = gate_inputs(ports, dirs, n)
            target = first_existing(outs, ["Z", "ZN", "Y"])

            if args and target:
                expr = f" {op} ".join(args)

                # The logical function follows the cell name, not the
                # output pin name. In GF180 many inverted functions use ZN.
                if prefix in {"nand", "nor", "xnor"}:
                    expr = f"~({expr})"

                write_assign(out, target, expr)

            out.write("endmodule\n\n")
            return

    # ------------------------------------------------------------
    # Muxes
    # ------------------------------------------------------------
    if base == "mux2":
        target = first_existing(outs, ["Z", "Y"])
        if target and has(ports, "S"):
            if has(ports, "I0") and has(ports, "I1"):
                write_assign(out, target, "S ? I1 : I0")
            elif has(ports, "A0") and has(ports, "A1"):
                write_assign(out, target, "S ? A1 : A0")
        out.write("endmodule\n\n")
        return

    if base == "mux4":
        target = first_existing(outs, ["Z", "Y"])
        if (
            target
            and has(ports, "I0")
            and has(ports, "I1")
            and has(ports, "I2")
            and has(ports, "I3")
            and has(ports, "S0")
            and has(ports, "S1")
        ):
            write_assign(out, target, "S1 ? (S0 ? I3 : I2) : (S0 ? I1 : I0)")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # AOI gates
    # ------------------------------------------------------------
    target = first_existing(outs, ["ZN", "Z"])

    if base == "aoi21" and target:
        write_assign(out, target, "~((A1 & A2) | B)")
        out.write("endmodule\n\n")
        return

    if base == "aoi211" and target:
        write_assign(out, target, "~((A1 & A2) | B | C)")
        out.write("endmodule\n\n")
        return

    if base == "aoi22" and target:
        write_assign(out, target, "~((A1 & A2) | (B1 & B2))")
        out.write("endmodule\n\n")
        return

    if base == "aoi221" and target:
        write_assign(out, target, "~((A1 & A2) | (B1 & B2) | C)")
        out.write("endmodule\n\n")
        return

    if base == "aoi222" and target:
        write_assign(out, target, "~((A1 & A2) | (B1 & B2) | (C1 & C2))")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # OAI gates
    # ------------------------------------------------------------
    if base == "oai21" and target:
        write_assign(out, target, "~((A1 | A2) & B)")
        out.write("endmodule\n\n")
        return

    if base == "oai211" and target:
        write_assign(out, target, "~((A1 | A2) & B & C)")
        out.write("endmodule\n\n")
        return

    if base == "oai22" and target:
        write_assign(out, target, "~((A1 | A2) & (B1 | B2))")
        out.write("endmodule\n\n")
        return

    if base == "oai221" and target:
        write_assign(out, target, "~((A1 | A2) & (B1 | B2) & C)")
        out.write("endmodule\n\n")
        return

    if base == "oai31" and target:
        write_assign(out, target, "~((A1 | A2 | A3) & B)")
        out.write("endmodule\n\n")
        return

    # ------------------------------------------------------------
    # Fallback
    # ------------------------------------------------------------
    for o in outs:
        if o == "Q":
            continue
        write_assign(out, o, "1'b0")

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
        dirs = parse_directions(text)

        # Add missing VNW/VPW expected by OpenLane powered netlist.
        ports, dirs = add_well_ports_if_needed(ports, dirs)

        # If a port has no parsed direction, default power/well to input.
        for power_port in ["VDD", "VSS", "VNW", "VPW"]:
            if power_port in ports and power_port not in dirs:
                dirs[power_port] = "input"

        modules[name] = (ports, dirs)

    if not modules:
        raise SystemExit("ERROR: no modules found")

    OUT.parent.mkdir(parents=True, exist_ok=True)

    with OUT.open("w", encoding="utf-8") as out:
        out.write("// Simple GF180 MCU7T5V0 functional models for Icarus GL simulation\n")
        out.write("// Generated from PDK cell declarations with parsed input/output directions.\n")
        out.write("// VNW/VPW are added for OpenLane/TinyTapeout powered netlists.\n")
        out.write("// Do not use for synthesis, timing signoff, LVS, or physical implementation.\n\n")
        out.write("`timescale 1ns / 1ps\n\n")

        for name, (ports, dirs) in sorted(modules.items()):
            emit_module(out, name, ports, dirs)

    print(f"Wrote {OUT}")
    print(f"Generated modules: {len(modules)}")


if __name__ == "__main__":
    main()
