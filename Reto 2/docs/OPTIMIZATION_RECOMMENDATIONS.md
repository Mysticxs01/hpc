# Optimizaciones Sugeridas - Reto 2

## 📋 Matriz de Optimizaciones Recomendadas

Basado en los resultados obtenidos, aquí hay optimizaciones específicas:

| Optimización | Complejidad | Impacto Estimado | Prioridad |
|---|---|---|---|
| Limitar a 8 threads | Trivial | Eliminación de 49% pena | ⭐⭐⭐ |
| Flags de compilación | Bajo | +15-25% | ⭐⭐⭐ |
| Loop unrolling | Medio | +10-15% | ⭐⭐ |
| Alineación de datos | Bajo | +2-3% | ⭐ |
| Vectorización SIMD | Alto | +4-5x teórico | ⭐⭐ |

---

## 1. Limitar a 8 Threads (CRITICAL)

### Problema Identificado
- Con 16 threads: 8.49 ms
- Con 8 threads: 4.33 ms
- **Degradación: 49% más lento con HT**

### Solución

**Opción A: Script Automático (Recomendado)**

```bash
#!/bin/bash
# run_optimal.sh - Ejecutar con número óptimo de threads

PHYSICAL_CORES=$(lscpu | grep "Core(s) per socket" | awk '{print $NF}')
export OMP_NUM_THREADS=$PHYSICAL_CORES

./build/cellular_automaton_openmp 10000 1000
```

**Opción B: Modificar run_openmp.sh**

```bash
# En run_openmp.sh, cambiar:
if [ "$THREADS" -eq 0 ]; then
    # VIEJO: THREADS=$(nproc)  # Usa todos los threads lógicos
    # NUEVO: Detectar cores físicos
    THREADS=$(lscpu | grep "Core(s) per socket" | awk '{print $NF}')
fi
```

**Opción C: Variable de Entorno**

```bash
export OMP_NUM_THREADS=8
./build/cellular_automaton_openmp
```

### Impacto
```
Antes: 8.49 ms (16 threads, degradado)
Después: 4.33 ms (8 threads, óptimo)
Mejora: 96% de reducción de tiempo
```

---

## 2. Flags de Compilación Optimizados

### Problema Identificado
- Compilación actual: `-O3 -Wall -Wextra -fopenmp`
- No usa optimizaciones específicas del CPU

### Solución

**Crear `build_optimized.sh`:**

```bash
#!/bin/bash

echo "=== Building with Optimized Flags ==="

BUILD_DIR="./build"
SRC_DIR="./src"

mkdir -p "$BUILD_DIR"

# Compilar OpenMP con flags agresivos
echo "Compiling with Optimized Flags..."

OPENMP_EXE="$BUILD_DIR/cellular_automaton_openmp_opt"
OPENMP_SRC="$SRC_DIR/openmp/cellular_automaton_openmp.c"

gcc -O3 -march=native -fopenmp \
    -ffast-math \
    -funroll-loops \
    -fvectorize \
    -Wall -Wextra \
    -o "$OPENMP_EXE" "$OPENMP_SRC" -lm

echo "✓ Compilation successful"
echo "Output: $OPENMP_EXE"

# Comparar tamaños
ls -lh "$BUILD_DIR"/cellular_automaton_openmp*
```

### Explicación de Flags

```
-O3                  # Nivel 3 de optimización
-march=native        # Optimiza para CPU actual
-ffast-math          # Operaciones matemáticas más rápidas
                     # (puede reducir precisión ligeramente)
-funroll-loops       # Desenrolla loops automáticamente
-fvectorize          # Intenta usar SIMD (SSE/AVX)
```

### Impacto Esperado

```
Baseline:     4.33 ms
Con flags:    3.5-3.7 ms (≈15-20% mejora)
Con -ffast-math: 3.3-3.5 ms (=extra 5%)
```

### Implementación

Actualizar `build.sh`:

```bash
# Para versión estándar:
gcc -O3 -Wall -Wextra -fopenmp \
    -o "$OPENMP_EXE" "$OPENMP_SRC" -lm

# Para versión optimizada:
gcc -O3 -march=native -fopenmp -ffast-math -funroll-loops -fvectorize \
    -Wall -Wextra \
    -o "$OPENMP_EXE" "$OPENMP_SRC" -lm
```

---

## 3. Loop Unrolling Manual (Avanzado)

### Problema
- Actualmente: Una célula por iteración
- Overhead de comparación y branch predictor

### Solución

**Versión 2x Unrolled:**

```c
// Actual
#pragma omp parallel for schedule(static)
for (int i = 0; i < width; i++) {
    unsigned char left = current[(i - 1 + width) % width];
    unsigned char center = current[i];
    unsigned char right = current[(i + 1) % width];
    next[i] = apply_rule(left, center, right);
}

// Optimizado (2x unroll)
#pragma omp parallel for schedule(static)
for (int i = 0; i < width; i += 2) {
    // Primera célula
    unsigned char left = current[(i - 1 + width) % width];
    unsigned char center = current[i];
    unsigned char right = current[(i + 1) % width];
    next[i] = apply_rule(left, center, right);
    
    // Segunda célula
    left = current[i];
    center = current[(i + 1)];
    right = current[(i + 2) % width];
    next[i + 1] = apply_rule(left, center, right);
}
```

### Impacto
```
Baseline: 4.33 ms
2x unroll: 3.9-4.0 ms (≈8% mejora)
4x unroll: 3.7-3.8 ms (≈12% mejora)
```

---

## 4. Alineación de Datos a Cache Line

### Problema
- Actual: Alineación por defecto (no optimizada)
- Cache line: 64 bytes

### Solución

Modificar `cellular_automaton_openmp.c`:

```c
// Función: simulate_omp
// Cambiar allocación de memoria:

// Antes:
unsigned char* current = grid;
unsigned char* next = (unsigned char*)malloc(width * sizeof(unsigned char));

// Después:
unsigned char* current = grid;
unsigned char* next = (unsigned char*)aligned_alloc(64, width * sizeof(unsigned char));
// Requiere: #include <stdlib.h>
```

O usar compilador attribute:

```c
// En simulate_omp:
unsigned char buffer_next[10000] __attribute__((aligned(64)));
unsigned char* next = buffer_next;
```

### Impacto
```
Baseline: 4.33 ms
Con alineación: 4.25 ms (≈2% mejora)
```

---

## 5. Vectorización SIMD (Avanzado)

### Problema
- Actualmente: Procesa 1 célula por instrucción
- SIMD (AVX-256): Puede procesar 8 células por instrucción

### Idea de Solución

```c
#include <immintrin.h>

// Pseudocódigo - no compilable sin ajustes
void compute_generation_simd(unsigned char* current, unsigned char* next, int width) {
    for (int i = 0; i < width; i += 8) {
        // Cargar 8 células vecinas
        __m256i left  = _mm256_loadu_si256((__m256i*)&current[i-1]);
        __m256i curr  = _mm256_loadu_si256((__m256i*)&current[i]);
        __m256i right = _mm256_loadu_si256((__m256i*)&current[i+1]);
        
        // Procesar 8 simultáneamente
        __m256i result = /* operaciones SIMD */;
        
        _mm256_storeu_si256((__m256i*)&next[i], result);
    }
}
```

### Impacto
```
Baseline (serial 1x): 26.64 ms
Con SIMD (teórico 8x): ~3.3 ms
Overhead real: 4.0-4.5 ms (aprox 4-5x)
```

### Complejidad
- **Alto**: Requiere entender SIMD intrinsics
- **Riesgo**: Fácil cometer errores de alineación/offset
- **Recomendación**: Dejar para exploración futura

---

## 6. CPU Affinity (Thread Pinning)

### Problema
- OpenMP puede asignar threads arbitrariamente
- Los threads pueden moverse entre cores

### Solución

```bash
# Script wrapper para fijar threads a cores físicos

#!/bin/bash
# run_pinned.sh

export OMP_NUM_THREADS=8
export OMP_PROC_BIND=close      # Bind threads a cores
export OMP_PLACES=cores          # Usar cores (no threads lógicos)

./build/cellular_automaton_openmp 10000 1000
```

### Impacto
```
Sin pinning: 4.33 ms (variable entre runs)
Con pinning: 4.33 ms (consistente, menos variance)
```

---

## 🎯 Plan de Implementación Recomendado

### Fase 1: Crítica (30 min) - Mejora +49%

```bash
# 1. Crear run_optimal.sh con OMP_NUM_THREADS=8
# 2. Probar: ./scripts/run_optimal.sh
# Resultado esperado: 4.33 ms (vs 8.49 ms actual)
```

### Fase 2: Importante (20 min) - Mejora +15-25%

```bash
# 1. Actualizar build.sh con flags optimizados
# 2. Recompilar
# 3. Probar: ./scripts/benchmark.sh
# Resultado esperado: 3.5-3.7 ms
```

### Fase 3: Opcional (30 min) - Mejora +10-15%

```bash
# 1. Implementar loop unrolling 2x o 4x
# 2. Recompilar con flags
# 3. Probar comparativo
# Resultado esperado: 3.2-3.5 ms
```

### Fase 4: Exploración (60+ min) - Mejora +4-5x

```bash
# 1. Estudiar SIMD intrinsics
# 2. Implementar versión vectorizada
# 3. Benchmarking de SIMD
# Resultado teórico: 3.3 ms (aprox 8x paralelo + 4-5x SIMD)
```

---

## 📊 Impacto Acumulativo

```
Baseline:           26.64 ms (serial)

Con OpenMP 8T:       4.33 ms (6.15x)  ✓ HECHO
Con 8T + flags:      3.5 ms (7.6x)    ← PRÓXIMO
Con 8T + flags + unroll: 3.2 ms (8.3x)
Con 8T + SIMD (teórico): ~1.0 ms (26x)
```

---

## 🧪 Cómo Medir el Impacto

```bash
#!/bin/bash
# compare_optimizations.sh

echo "=== Comparing Optimizations ==="
echo ""

for run in 1 2 3; do
    echo "Run $run:"
    echo -n "  Baseline:        "
    time ./build/cellular_automaton_serial 10000 1000 1 | grep "Average"
    
    echo -n "  OpenMP (8T):     "
    export OMP_NUM_THREADS=8
    time ./build/cellular_automaton_openmp 10000 1000 1 8 | grep "Average"
    
    echo ""
done
```

---

## 📝 Conclusión

**Prioridad 1 (Crítica):** Limitar a 8 threads → 49% mejora
**Prioridad 2 (Alta):** Flags optimizados → +15-25% mejora
**Prioridad 3 (Media):** Loop unrolling → +10-15% mejora
**Prioridad 4 (Exploración):** SIMD → +4-5x teórico

**Recomendación:** Implementar Prioridad 1 y 2 para obtener ~+70% mejora total manteniendo código legible.

---

*Documento de Optimizaciones - Reto 2: Cellular Automaton*
