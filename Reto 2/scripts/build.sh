#!/bin/bash

# Build script for Cellular Automaton implementations
# Compila tanto la versión serial como la versión OpenMP

set -e

echo "=== Building Cellular Automaton ==="

BUILD_DIR="./build"
SRC_DIR="./src"

# Crear directorio build si no existe
mkdir -p "$BUILD_DIR"

# Compilar versión serial
echo ""
echo "Compiling Serial Version..."
SERIAL_EXE="$BUILD_DIR/cellular_automaton_serial"
SERIAL_SRC="$SRC_DIR/serial/cellular_automaton_serial.c"

if gcc -O3 -Wall -Wextra -o "$SERIAL_EXE" "$SERIAL_SRC" -lm; then
    echo "✓ Serial compilation successful"
else
    echo "✗ Serial compilation failed"
    exit 1
fi

# Compilar versión OpenMP
echo ""
echo "Compiling OpenMP Version..."
OPENMP_EXE="$BUILD_DIR/cellular_automaton_openmp"
OPENMP_SRC="$SRC_DIR/openmp/cellular_automaton_openmp.c"

if gcc -O3 -Wall -Wextra -fopenmp -o "$OPENMP_EXE" "$OPENMP_SRC" -lm; then
    echo "✓ OpenMP compilation successful"
else
    echo "✗ OpenMP compilation failed"
    exit 1
fi

echo ""
echo "=== Build Complete ==="
echo "Binaries generated in: $BUILD_DIR"
echo ""
echo "Generated Executables:"
ls -lh "$BUILD_DIR"/ | grep -E "cellular_automaton"
