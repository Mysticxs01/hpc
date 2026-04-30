# Índice de Documentación - Reto 2: Cellular Automaton

## 🎯 Inicio Rápido

**Nuevo en el proyecto?** Comienza aquí:

1. [QUICK_START.md](QUICK_START.md) - Guía de 5 minutos para compilar y ejecutar
2. [README.md](README.md) - Descripción del proyecto y estructura

---

## 📚 Documentación Teórica

### 1. [CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md)
**Objetivo:** Entender QUÉ es Cellular Automaton y cómo funciona

**Secciones:**
- Introducción a Autómatas Celulares
- Regla 110 de Wolfram (mapeo de estados)
- Complejidad computacional: O(W × G)
- Patrones de acceso a memoria
- Características esperadas del algoritmo
- Oportunidades de optimización

**Tiempo de lectura:** 20-30 minutos

---

### 2. [PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md)
**Objetivo:** Entender CÓMO se paraleliza con OpenMP y POR QUÉ

**Secciones:**
- Análisis de dependencias (loop exterior vs interior)
- Opciones de scheduling: static, dynamic, guided
- Justificación de static scheduling
- Análisis de clauses OpenMP
- Sincronización y barreras
- Ley de Amdahl y predicciones teóricas
- Comparación de enfoques

**Tiempo de lectura:** 30-40 minutos

---

### 3. [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)
**Objetivo:** Entender CUÁL es el desempeño esperado teóricamente

**Secciones:**
- Metodología de análisis
- Resultados esperados (serial vs paralelo)
- Análisis de comunicación y sincronización
- Memory hierarchy y caché
- False sharing analysis
- Oportunidades de optimización
- Estrategia de profiling

**Tiempo de lectura:** 30-40 minutos

---

## 🔬 Documentación Experimental

### 4. [RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md)
**Objetivo:** VER los resultados reales obtenidos

**Contenido:**
- Benchmark comparativo (serial vs OpenMP)
- Profiling detallado (5 configuraciones)
- Escalabilidad observada
- Análisis de Hyperthreading
- Verificación contra predicciones teóricas
- Gráfico de escalabilidad
- Lecciones aprendidas

**Tiempo de lectura:** 20-30 minutos

**Hallazgo clave:** Speedup 6.15x con 8 threads, degradación con Hyperthreading

---

### 5. [OPTIMIZATION_RECOMMENDATIONS.md](docs/OPTIMIZATION_RECOMMENDATIONS.md)
**Objetivo:** Cómo mejorar el desempeño paso a paso

**Optimizaciones recomendadas:**
1. Limitar a 8 threads (crítica) → -49% degradación
2. Flags de compilación (-march=native) → +15-25%
3. Loop unrolling → +10-15%
4. Alineación de datos → +2-3%
5. Vectorización SIMD → +4-5x teórico

**Tiempo de lectura:** 20-30 minutos

---

### 6. [CONCLUSIONS.md](CONCLUSIONS.md)
**Objetivo:** Resumen integral de hallazgos

**Incluye:**
- Resumen ejecutivo de resultados
- Checklist de objetivos completados
- Causas de desempeño (análisis profundo)
- Verificación de predicciones teóricas
- Lecciones aprendidas
- Recomendaciones finales

**Tiempo de lectura:** 15-20 minutos

---

## 💻 Código Fuente

### Versión Serial
**Archivo:** [src/serial/cellular_automaton_serial.c](src/serial/cellular_automaton_serial.c)

```bash
gcc -O3 -o build/cellular_automaton_serial src/serial/cellular_automaton_serial.c -lm
./build/cellular_automaton_serial 10000 1000 10
```

**Líneas de código:** ~200
**Baseline de desempeño:** 26.64 ms

---

### Versión Paralelizada
**Archivo:** [src/openmp/cellular_automaton_openmp.c](src/openmp/cellular_automaton_openmp.c)

```bash
gcc -O3 -fopenmp -o build/cellular_automaton_openmp src/openmp/cellular_automaton_openmp.c -lm
export OMP_NUM_THREADS=8
./build/cellular_automaton_openmp 10000 1000 10 8
```

**Líneas de código:** ~220
**Desempeño óptimo (8T):** 4.33 ms
**Speedup:** 6.15x

---

## 🛠️ Scripts de Automatización

### Linux/macOS (Bash)

| Script | Propósito | Uso |
|--------|-----------|-----|
| [scripts/build.sh](scripts/build.sh) | Compilar ambas versiones | `./scripts/build.sh` |
| [scripts/run_serial.sh](scripts/run_serial.sh) | Ejecutar versión serial | `./scripts/run_serial.sh 10000 1000 10` |
| [scripts/run_openmp.sh](scripts/run_openmp.sh) | Ejecutar versión OpenMP | `./scripts/run_openmp.sh 10000 1000 10 8` |
| [scripts/profile.sh](scripts/profile.sh) | Profiling multi-config | `./scripts/profile.sh 10000 1000 5` |
| [scripts/benchmark.sh](scripts/benchmark.sh) | Benchmark comparativo | `./scripts/benchmark.sh 10000 1000 10` |

---

## 📊 Resultados

### Archivos Generados

| Archivo | Contenido |
|---------|-----------|
| benchmark_output.txt | Comparación serial vs OpenMP (10 runs) |
| profile_output.txt | Profiling con múltiples thread counts |
| build/profile_summary.csv | Datos CSV para análisis |

### Lectura Rápida de Resultados

```bash
# Ver benchmark
cat benchmark_output.txt | grep -A 2 "Average Time"

# Ver profiling
cat profile_output.txt | tail -20

# Analizar CSV
column -t -s ',' build/profile_summary.csv
```

---

## 🎓 Ruta de Aprendizaje Recomendada

### Opción 1: Pragmática (2-3 horas)
1. Leer [QUICK_START.md](QUICK_START.md)
2. Compilar y ejecutar: `./scripts/build.sh && ./scripts/benchmark.sh`
3. Leer [RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md)
4. Leer [OPTIMIZATION_RECOMMENDATIONS.md](docs/OPTIMIZATION_RECOMMENDATIONS.md)

### Opción 2: Académica (5-7 horas)
1. Leer [CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md)
2. Leer [PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md)
3. Leer código: [cellular_automaton_serial.c](src/serial/cellular_automaton_serial.c)
4. Leer [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)
5. Ejecutar profiling: `./scripts/profile.sh`
6. Leer [RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md)
7. Leer [CONCLUSIONS.md](CONCLUSIONS.md)

### Opción 3: Completa (8+ horas)
- Todas las opciones académicas +
- Estudiar [OPTIMIZATION_RECOMMENDATIONS.md](docs/OPTIMIZATION_RECOMMENDATIONS.md)
- Implementar optimizaciones sugeridas
- Benchmarking iterativo

---

## 🔍 Preguntas Frecuentes

### P: ¿Qué es Cellular Automaton?
→ Ver [CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md) Sección 1-2

### P: ¿Cómo se paraleliza?
→ Ver [PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md) Sección 1-2

### P: ¿Cuáles son los resultados obtenidos?
→ Ver [RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md) o ejecutar `cat benchmark_output.txt`

### P: ¿Por qué degrada con 16 threads?
→ Ver [RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md) Sección 1.2 y [CONCLUSIONS.md](CONCLUSIONS.md)

### P: ¿Cómo optimizar más?
→ Ver [OPTIMIZATION_RECOMMENDATIONS.md](docs/OPTIMIZATION_RECOMMENDATIONS.md)

### P: ¿Qué es Hyperthreading?
→ Ver [RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md) Sección 2 y [CONCLUSIONS.md](CONCLUSIONS.md)

### P: ¿Las predicciones teóricas fueron correctas?
→ Ver [CONCLUSIONS.md](CONCLUSIONS.md) Tabla de Verificación (3.2% error promedio)

---

## 📈 Resumen de Hallazgos

### Performance
```
Serial:           26.64 ms
OpenMP (8T):       4.33 ms
Speedup:           6.15x ✓
Eficiencia:        76.9% ✓
```

### Arquitectura Detectada
```
8 Cores físicos + Hyperthreading (16 threads lógicos)
L1: 32 KB/core, L2: 256 KB/core, L3: 16 MB compartida
```

### Conclusión
```
✓ Paralelización altamente exitosa
✓ Predicciones teóricas 95% acertadas
✓ Hyperthreading introduce 49% degradación en CPU-bound
✓ Static scheduling es decisión óptima
✓ Overhead de sincronización < 1%
```

---

## 🚀 Próximos Pasos

1. **Corto plazo** (30 min):
   - Limitar a 8 threads
   - Recompilar con `-march=native -O3 -ffast-math`
   - Obtener +50-70% mejora

2. **Mediano plazo** (2-3 horas):
   - Implementar loop unrolling 2x o 4x
   - Profiling iterativo
   - Obtener +80-100% mejora acumulativa

3. **Largo plazo** (6-8 horas):
   - Vectorización SIMD (AVX-256)
   - Explorar OpenMP tasks
   - Potencial 4-5x mejora adicional

---

## 📞 Contacto / Dudas

Para dudas sobre:
- **Teoría**: Ver secciones correspondientes en documentación
- **Código**: Ver comentarios en archivos .c
- **Resultados**: Ver RESULTS_ANALYSIS.md o CONCLUSIONS.md
- **Optimización**: Ver OPTIMIZATION_RECOMMENDATIONS.md

---

## 📋 Estructura del Proyecto

```
Reto 2/
├── README.md                          # Descripción general
├── QUICK_START.md                     # Guía de inicio rápido
├── INDEX.md                           # Este archivo
├── RESULTS_ANALYSIS.md                # Análisis experimental
├── CONCLUSIONS.md                     # Conclusiones integrales
│
├── docs/
│   ├── CELLULAR_AUTOMATON_ANALYSIS.md
│   ├── PARALLELIZATION_ANALYSIS.md
│   ├── PERFORMANCE_ANALYSIS.md
│   └── OPTIMIZATION_RECOMMENDATIONS.md
│
├── src/
│   ├── serial/
│   │   └── cellular_automaton_serial.c
│   └── openmp/
│       └── cellular_automaton_openmp.c
│
├── scripts/
│   ├── build.sh
│   ├── run_serial.sh
│   ├── run_openmp.sh
│   ├── profile.sh
│   └── benchmark.sh
│
├── build/
│   ├── cellular_automaton_serial
│   └── cellular_automaton_openmp
│
└── Resultados:
    ├── benchmark_output.txt
    └── profile_output.txt
```

---

**Última actualización:** 29 de Abril de 2026
**Estado:** Completado ✅
**Documentación:** Integral y detallada
