import gdstk

SRC = "third_party/gf180mcu_fd_ip_sram/cells/gf180mcu_fd_ip_sram__sram64x8m8wm1/gf180mcu_fd_ip_sram__sram64x8m8wm1.gds"
DST = "third_party/gf180mcu_fd_ip_sram/cells/gf180mcu_fd_ip_sram__sram64x8m8wm1/gf180mcu_fd_ip_sram__sram64x8m8wm1_flat.gds"
TOP = "gf180mcu_fd_ip_sram__sram64x8m8wm1"

lib = gdstk.read_gds(SRC)
cells = {cell.name: cell for cell in lib.cells}

if TOP not in cells:
    raise RuntimeError(f"Top cell {TOP} not found. Available cells: {list(cells.keys())}")

top = cells[TOP].copy(TOP)

# Flatten all referenced geometry into the top cell.
top.flatten(apply_repetitions=True)

# Create a new library containing only the flattened macro top cell.
new_lib = gdstk.Library(unit=lib.unit, precision=lib.precision)
new_lib.add(top)
new_lib.write_gds(DST)

# Verify result.
check = gdstk.read_gds(DST)
print("Wrote:", DST)
print("Flattened SRAM GDS top cells:")
for c in check.top_level():
    print(" -", c.name, "bbox=", c.bounding_box(), "refs=", len(c.references))