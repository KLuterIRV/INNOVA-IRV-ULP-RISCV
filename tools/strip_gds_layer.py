#!/usr/bin/env python3
import sys
import gdstk


def main():
    if len(sys.argv) != 5:
        print("Usage: strip_gds_layer.py <input.gds> <output.gds> <layer> <texttype>")
        sys.exit(1)

    in_gds = sys.argv[1]
    out_gds = sys.argv[2]
    bad_layer = int(sys.argv[3])
    bad_texttype = int(sys.argv[4])

    lib = gdstk.read_gds(in_gds)

    removed_labels = 0

    for cell in lib.cells:
        labels_to_remove = []

        for label in cell.labels:
            if label.layer == bad_layer and label.texttype == bad_texttype:
                labels_to_remove.append(label)
                removed_labels += 1

        if labels_to_remove:
            cell.remove(*labels_to_remove)

    lib.write_gds(out_gds)

    print(f"Input:  {in_gds}")
    print(f"Output: {out_gds}")
    print(f"Removed labels on layer/texttype ({bad_layer}, {bad_texttype}): {removed_labels}")


if __name__ == "__main__":
    main()
