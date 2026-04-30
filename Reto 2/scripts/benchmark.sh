#!/bin/bash

# Benchmark script - Comprehensive performance comparison
# Compara desempeño entre versiones serial y OpenMP

WIDTH=${1:-10000}
GENERATIONS=${2:-1000}
RUNS=${3:-10}

echo "=== Comprehensive Benchmark ==="

SERIAL_EXE="./build/cellular_automaton_serial"
OPENMP_EXE="./build/cellular_automaton_openmp"
OUTPUT_FILE="./benchmark_output.txt"

if [ ! -f "$SERIAL_EXE" ] || [ ! -f "$OPENMP_EXE" ]; then
    echo "Error: Executables not found. Run './scripts/build.sh' first."
    exit 1
fi

echo "Benchmark Configuration:"
echo "  Grid Width: $WIDTH"
echo "  Generations: $GENERATIONS"
echo "  Runs: $RUNS"
echo ""

# Initialize output file
{
    echo "CELLULAR AUTOMATON BENCHMARK REPORT"
    echo "========================================"
    echo "Generated: $(date)"
    echo "Configuration:"
    echo "  Grid Width: $WIDTH"
    echo "  Generations: $GENERATIONS"
    echo "  Runs per Version: $RUNS"
    echo ""
} > "$OUTPUT_FILE"

# Serial Benchmark
echo "Running Serial Benchmark..."
{
    echo "SERIAL VERSION RESULTS:"
    echo "------------------------"
} >> "$OUTPUT_FILE"

"$SERIAL_EXE" "$WIDTH" "$GENERATIONS" "$RUNS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "✓ Serial benchmark complete"

# OpenMP Benchmark
echo "Running OpenMP Benchmark..."
MAX_THREADS=$(nproc)
{
    echo "OPENMP VERSION RESULTS (Threads: $MAX_THREADS):"
    echo "------------------------"
} >> "$OUTPUT_FILE"

export OMP_NUM_THREADS="$MAX_THREADS"
"$OPENMP_EXE" "$WIDTH" "$GENERATIONS" "$RUNS" "$MAX_THREADS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "✓ OpenMP benchmark complete"

# Print summary to console
echo ""
echo "=== BENCHMARK SUMMARY ==="
echo ""
echo "Serial Version:"
grep -E "Average Time|Throughput" "$OUTPUT_FILE" | head -2
echo ""
echo "OpenMP Version ($MAX_THREADS threads):"
grep -E "Average Time|Throughput" "$OUTPUT_FILE" | tail -2
echo ""

echo "Results saved to: $OUTPUT_FILE"
