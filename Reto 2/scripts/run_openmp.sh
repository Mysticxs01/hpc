#!/bin/bash

# Run OpenMP parallelized version of Cellular Automaton
# Ejecuta la versión paralelizada con OpenMP del algoritmo

WIDTH=${1:-10000}
GENERATIONS=${2:-1000}
RUNS=${3:-10}
THREADS=${4:-0}

echo "=== Running Cellular Automaton (OpenMP) ==="

OPENMP_EXE="./build/cellular_automaton_openmp"

if [ ! -f "$OPENMP_EXE" ]; then
    echo "Error: Executable not found. Run './scripts/build.sh' first."
    exit 1
fi

# Determine number of threads
if [ "$THREADS" -eq 0 ]; then
    THREADS=$(nproc)
fi

echo "Parameters:"
echo "  Grid Width: $WIDTH"
echo "  Generations: $GENERATIONS"
echo "  Number of Runs: $RUNS"
echo "  Number of Threads: $THREADS"
echo ""

# Set OpenMP environment variable
export OMP_NUM_THREADS="$THREADS"

"$OPENMP_EXE" "$WIDTH" "$GENERATIONS" "$RUNS" "$THREADS"
