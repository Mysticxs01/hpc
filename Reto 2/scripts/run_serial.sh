#!/bin/bash

# Run serial version of Cellular Automaton
# Ejecuta la versión secuencial del algoritmo

WIDTH=${1:-10000}
GENERATIONS=${2:-1000}
RUNS=${3:-10}

echo "=== Running Cellular Automaton (Serial) ==="

SERIAL_EXE="./build/cellular_automaton_serial"

if [ ! -f "$SERIAL_EXE" ]; then
    echo "Error: Executable not found. Run './scripts/build.sh' first."
    exit 1
fi

echo "Parameters:"
echo "  Grid Width: $WIDTH"
echo "  Generations: $GENERATIONS"
echo "  Number of Runs: $RUNS"
echo ""

"$SERIAL_EXE" "$WIDTH" "$GENERATIONS" "$RUNS"
