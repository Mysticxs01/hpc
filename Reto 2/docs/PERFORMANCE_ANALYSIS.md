# Análisis de Desempeño y Optimización

## 1. Metodología de Análisis

### 1.1 Métricas Clave

```
Tiempo Total = Tiempo de Inicialización + Tiempo de Cómputo

Throughput = (width × generations) / tiempo_total [cells/sec]

Speedup = Tiempo_Serial / Tiempo_Paralelo

Eficiencia = Speedup / Número_Threads
```

### 1.2 Configuración de Pruebas

- **Grid Width**: 10,000 células
- **Generaciones**: 1,000
- **Runs**: 10 ejecuciones por configuración (para estadísticas)
- **Métricas Reportadas**: Promedio, Mínimo, Máximo

---

## 2. Resultados Esperados

### 2.1 Versión Serial

**Baseline para comparación:**

```
Tiempo Esperado: 0.05 - 0.15 segundos (depende de CPU)
Throughput Esperado: 670 - 2000 Mcells/s

Operaciones por Segundo:
- 10M de células × 6 operaciones = 60M operaciones
- A ~3 GHz, esperado: 0.02-0.05s (en máquina rápida)
```

**Operaciones en cada generación:**
```
Por célula: 6 operaciones simples (shifts, ands, memoria)
Por generación: 10,000 × 6 = 60,000 operaciones
Total: 1,000 generaciones × 60,000 = 60M operaciones
```

---

### 2.2 Versión OpenMP

#### Quad-Core (4 Threads)

**Predicción:**
```
Speedup Esperado: 3.5 - 3.8x
Eficiencia: 87.5% - 95%

Tiempo Esperado: Serial_Time / 3.7
Ejemplo: 0.1s serial → 0.027s paralelo (aproximadamente)
```

**Análisis:**
- Overhead de OpenMP: ~2-5% por generación
- Localidad de caché perfecta: No degrada con paralelización
- Overhead de barrera: Amortizado sobre 10M operaciones

---

#### Octa-Core (8 Threads)

**Predicción:**
```
Speedup Esperado: 7.2 - 7.8x
Eficiencia: 90% - 97.5%

Tiempo Esperado: Serial_Time / 7.5
Ejemplo: 0.1s serial → 0.013s paralelo
```

**Análisis:**
- Memory bandwidth es factor limitante con 8 threads
- Cachés L1/L2 suficientes para cada thread
- Posible contención en L3 (compartida entre threads)

---

## 3. Análisis de Comunicación y Sincronización

### 3.1 Patrón de Comunicación

**Por Cada Generación:**

```
Sincronización:
  1. Barrera implícita al final del parallel for
  2. Sincronización de memoria
  
Comunicación de Datos:
  - Ninguna entre threads (datos completamente locales)
  - Costo: Solo barrera y coherencia de caché
```

**Efecto en Desempeño:**
- Overhead de barrera: ~10-50 ciclos (muy pequeño)
- Overhead de coherencia: Incluido en el ciclo de caché normal
- Impacto total: < 1% del tiempo de cómputo

---

### 3.2 False Sharing Analysis

**Acceso a Memoria:**

```
Thread 0: escribe next[0-2499]    (100 cache lines)
Thread 1: escribe next[2500-4999]  (100 cache lines)
Thread 2: escribe next[5000-7499]  (100 cache lines)
Thread 3: escribe next[7500-9999]  (100 cache lines)
```

Asumiendo cache line de 64 bytes:
- 1 byte (datos) = 1 célula
- 64 bytes = 64 células por cache line
- Cada thread accede líneas completamente independientes

**Conclusión: CERO False Sharing**

---

## 4. Análisis de Utilización de Caché

### 4.1 Memory Hierarchy

```
Tamaño de Datos:
  Current grid:  10,000 bytes = ~156 cache lines
  Next grid:     10,000 bytes = ~156 cache lines
  Total working: ~20,000 bytes

Caché típica:
  L1: 32-64 KB   ✓ Cabe completamente
  L2: 256-512 KB ✓ Cabe completamente
  L3: 8-16 MB    ✓ Cabe completamente
```

### 4.2 Patrones de Acceso

**Lectura (Current Grid):**
```
Secuencial: current[i-1], current[i], current[i+1]
  - Patrón: Stride-1 (óptimo)
  - Prefetch: Hardware prefetcher es muy efectivo
  - Miss Rate: ~0% después del warmup
```

**Escritura (Next Grid):**
```
Secuencial: next[i] = resultado
  - Patrón: Stride-1 (óptimo)
  - Write Combining: Efectivo
  - Miss Rate: ~0%
```

### 4.3 Impacto de Caché en Paralelización

**Con Static Scheduling:**
```
Thread 0 accede: current[0-2499], next[0-2499]
Thread 1 accede: current[2500-4999], next[2500-4999]
...
```

**Ventajas:**
- Cache working set por thread: ~5,000 bytes (cabe en L1)
- Excelente reuso en caché
- Minimiza contención en caché compartida

---

## 5. Análisis de Memory Bandwidth

### 5.1 Demanda de Ancho de Banda

**Por Generación (10,000 células):**

```
Lecturas:
  - current[i-1]: 10,000 bytes
  - current[i]:   10,000 bytes
  - current[i+1]: 10,000 bytes
  Total lecturas: 30,000 bytes

Escrituras:
  - next[i]:      10,000 bytes

Total I/O de Memoria: 40,000 bytes por generación
```

**Para 1,000 generaciones:**
```
Total Memoria: 40,000 × 1,000 = 40 MB
```

### 5.2 Capacidad de Ancho de Banda

**CPU Típica (DDR4):**
```
Ancho de banda: 50-80 GB/s
Para 40 MB:   40 MB / 50 GB/s = 0.8 ms
              40 MB / 80 GB/s = 0.5 ms

Pero con caché efectivo:
  - Datos viven en L1/L2
  - Solo primeras generaciones acceden a memoria principal
  - Después: 100% cache hits
```

**Conclusión: Memory Bandwidth NO es cuello de botella**

---

## 6. Oportunidades de Optimización Identificadas

### 6.1 A Nivel de CPU

#### Optimización 1: Loop Unrolling

```c
// Original
for (int i = 0; i < width; i++) {
    next[i] = apply_rule(current[(i-1+width)%width], current[i], current[(i+1)%width]);
}

// Unrolled 4x
for (int i = 0; i < width; i += 4) {
    next[i]   = apply_rule(..., current[i],   ...);
    next[i+1] = apply_rule(..., current[i+1], ...);
    next[i+2] = apply_rule(..., current[i+2], ...);
    next[i+3] = apply_rule(..., current[i+3], ...);
}
```

**Beneficio:** Aumenta ILP (Instruction Level Parallelism)
**Impacto:** +10-15% de rendimiento

---

#### Optimización 2: Inline de Función

```c
// Current: Función apply_rule (llamada 10M veces)
unsigned char apply_rule(...) { ... }

// Inline: Código expandido en cada llamada
#pragma omp parallel for
for (int i = 0; i < width; i++) {
    unsigned char neighborhood = (left << 2) | (center << 1) | right;
    next[i] = (110 >> neighborhood) & 1;  // Inlined
}
```

**Beneficio:** Elimina overhead de llamada a función
**Impacto:** +5-10% de rendimiento

---

#### Optimización 3: Computación Modular

```c
// Problema: (i-1+width) % width es costoso
// Solución: Precalcular índices
int prev_i = (i - 1 + width) % width;
int next_i = (i + 1) % width;

// O usar condición: si i > 0, usar i-1; si no, usar width-1
```

**Beneficio:** Evita operación módulo (lenta)
**Impacto:** +5% de rendimiento

---

### 6.2 A Nivel de Memoria

#### Optimización 1: Alineación de Datos

```c
// Garantizar alineación a cache line (64 bytes)
unsigned char* grid __attribute__((aligned(64))) = ...;
unsigned char* next __attribute__((aligned(64))) = ...;
```

**Beneficio:** Máxima eficiencia de cache line usage
**Impacto:** +2-3% de rendimiento

---

#### Optimización 2: Localidad Mejorada

```c
// Procesar en bloques para mejorar localidad
int block_size = 1024;  // O(L3 size)
for (int block = 0; block < width; block += block_size) {
    #pragma omp parallel for
    for (int i = block; i < block + block_size; i++) {
        // Proceso localizado
    }
}
```

**Beneficio:** Mejor reuso de L3 entre threads
**Impacto:** Marginal para nuestro tamaño

---

### 6.3 A Nivel de Compilador

#### Optimización 1: -O3 con Flags Adicionales

```bash
# Compilación estándar
gcc -O3 -fopenmp -o ca cellular_automaton_openmp.c

# Compilación agresiva
gcc -O3 -march=native -fopenmp -ffast-math \
    -funroll-loops -fvectorize \
    -o ca cellular_automaton_openmp.c
```

**Flags Adicionales:**
- `-march=native`: Optimiza para CPU local
- `-ffast-math`: Operaciones matemáticas más rápidas (con menos precisión)
- `-funroll-loops`: Desenrolla loops automáticamente
- `-fvectorize`: Intenta vectorizar con SIMD

**Impacto:** +15-25% de rendimiento

---

#### Optimización 2: Vectorización Manual (SIMD)

```c
#include <immintrin.h>

// Procesar 8 células en paralelo (AVX)
for (int i = 0; i < width; i += 8) {
    __m256i left  = _mm256_loadu_si256(...);
    __m256i curr  = _mm256_loadu_si256(...);
    __m256i right = _mm256_loadu_si256(...);
    
    // Operaciones vectorizadas
    __m256i result = ...;
    _mm256_storeu_si256(..., result);
}
```

**Beneficio:** Procesa 8 células por instrucción (vs. 1)
**Impacto:** +6-8x teórico, ~4-5x práctico

---

## 7. Estrategia de Profiling

### 7.1 Herramientas Recomendadas

```bash
# Linux: perf
perf stat -e cycles,instructions,cache-references,cache-misses \
    ./build/cellular_automaton_serial

# Linux: Intel VTune
vtune -collect memory-access ./build/cellular_automaton_openmp

# Cross-platform: Custom timing (implementado)
```

### 7.2 Métodos de Profiling Implementados

**1. Timing Manual**
```c
double start = omp_get_wtime();
// Código a medir
double elapsed = omp_get_wtime() - start;
```

**2. Estadísticas Múltiples**
- Min/Max/Avg de tiempo
- Throughput calculado
- Varianza para detectar inconsistencias

---

## 8. Análisis de Resultados

### 8.1 Matriz de Decisión de Optimización

| Optimización | Complejidad | Impacto | Prioridad |
|---|---|---|---|
| -O3 + flags | Bajo | Alto (15-25%) | ⭐⭐⭐ |
| Inline | Bajo | Medio (5-10%) | ⭐⭐ |
| Loop unrolling | Medio | Medio (10-15%) | ⭐⭐ |
| Alineación | Bajo | Bajo (2-3%) | ⭐ |
| Vectorización | Alto | Muy Alto (4-5x) | ⭐⭐⭐ |

---

### 8.2 Conclusiones Esperadas

1. **OpenMP es efectivo**: Speedup cercano a lineal para CA
2. **Memory no es cuello de botella**: Excelente localidad
3. **Sincronización es barata**: Overhead < 1%
4. **Compilador es importante**: Flags correctos son críticos
5. **Vectorización es la clave**: Para máximo rendimiento

---

## 9. Reporte de Resultados

### 9.1 Formato de Reporte

```
CONFIGURACIÓN:
- Grid Width: 10,000
- Generaciones: 1,000
- Runs: 10

RESULTADOS SERIAL:
- Tiempo Promedio: X.XXX s
- Min/Max: X.XXX / Y.YYY s
- Throughput: Z.ZZ Gcells/s

RESULTADOS OPENMP (N threads):
- Tiempo Promedio: X.XXX s
- Min/Max: X.XXX / Y.YYY s
- Throughput: Z.ZZ Gcells/s
- Speedup: N.NN x
- Eficiencia: NN.N%

ANÁLISIS:
- [Observaciones sobre desempeño]
- [Optimizaciones aplicadas]
- [Limitaciones identificadas]
```

---

## 10. Referencias

- Intel. "Intel 64 and IA-32 Architectures Optimization Reference Manual"
- Agner Fog. "Optimizing software in C++" (aplica a C también)
- OpenMP Official Documentation

---

**Nota**: Este documento es un análisis teórico. Los resultados reales dependerán de:
- CPU específica del usuario
- Compilador y versión
- Sistema operativo
- Carga del sistema durante pruebas

Se recomienda ejecutar los scripts de profiling para obtener datos reales.
