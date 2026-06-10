cat > test/run.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Running RTL cocotb test..."
echo "Python: $(python3 --version || true)"
echo "Verilator: $(verilator --version || true)"
echo "Cocotb: $(cocotb-config --version || true)"

make clean
make

if [ ! -f results.xml ]; then
    echo "ERROR: test/results.xml was not generated"
    exit 2
fi

echo "RTL test completed successfully"
EOF

chmod +x test/run.sh