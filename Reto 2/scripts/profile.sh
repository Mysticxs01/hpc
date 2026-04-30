#!/bin/bash

# Profiling script for Cellular Automaton implementations
# Realiza análisis de desempeño con diferentes configuraciones

WIDTH=${1:-10000}
GENERATIONS=${2:-1000}
RUNS=${3:-3}

echo "=== Profiling Cellular Automaton ==="

SERIAL_EXE="./build/cellular_automaton_serial"
OPENMP_EXE="./build/cellular_automaton_openmp"
OUTPUT_FILE="./profile_output.txt"
CSV_FILE="./build/profile_summary.csv"

if [ ! -f "$SERIAL_EXE" ] || [ ! -f "$OPENMP_EXE" ]; then
    echo "Error: Executables not found. Run './scripts/build.sh' first."
    exit 1
fi

echo "Testing configurations:"
echo "  Grid Width: $WIDTH"
echo "  Generations: $GENERATIONS"
echo "  Runs per configuration: $RUNS"
echo ""

# Initialize output files
{
    echo "Cellular Automaton Profiling Results"
    echo "Generated: $(date)"
    echo ""
} > "$OUTPUT_FILE"

# CSV Header
echo "Configuration,Version,Threads,AvgTime(s),MinTime(s),MaxTime(s),Throughput(Gcells/s)" > "$CSV_FILE"

# Profile Serial Version
echo "1. Profiling Serial Version..."
{
    echo "=== SERIAL VERSION ==="
    echo "Grid Width: $WIDTH, Generations: $GENERATIONS, Runs: $RUNS"
    echo ""
} >> "$OUTPUT_FILE"

"$SERIAL_EXE" "$WIDTH" "$GENERATIONS" "$RUNS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "✓ Serial profiling complete"

# Profile OpenMP with different thread counts
MAX_THREADS=$(nproc)

# Generate thread count array (1, 2, 4, 8, ... up to MAX_THREADS)
THREAD_COUNTS=()
for ((t=1; t<=MAX_THREADS; t*=2)); do
    if [ $t -le $MAX_THREADS ]; then
        THREAD_COUNTS+=($t)
    fi
done

# Add MAX_THREADS if not already present
if [[ ! " ${THREAD_COUNTS[@]} " =~ " ${MAX_THREADS} " ]]; then
    THREAD_COUNTS+=($MAX_THREADS)
fi

CONFIG_NUM=2
for THREADS in "${THREAD_COUNTS[@]}"; do
    echo "$CONFIG_NUM. Profiling OpenMP with $THREADS thread(s)..."
    {
        echo "=== OPENMP VERSION (Threads: $THREADS) ==="
        echo "Grid Width: $WIDTH, Generations: $GENERATIONS, Runs: $RUNS, Threads: $THREADS"
        echo ""
    } >> "$OUTPUT_FILE"
    
    export OMP_NUM_THREADS="$THREADS"
    "$OPENMP_EXE" "$WIDTH" "$GENERATIONS" "$RUNS" "$THREADS" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "✓ OpenMP profiling ($THREADS threads) complete"
    
    ((CONFIG_NUM++))
done

echo ""
echo "=== Profiling Complete ==="
echo "Results saved to: $OUTPUT_FILE"
echo "CSV summary saved to: $CSV_FILE"
echo ""
echo "To analyze the results:"
echo "  cat $OUTPUT_FILE"
echo "  cat $CSV_FILE"
