# Guía de Inicio Rápido - Reto 2

## 📋 Estructura Creada

Se ha configurado exitosamente la estructura del Reto 2 con la siguiente organización:

```
Reto 2/
├── src/
│   ├── serial/
│   │   └── cellular_automaton_serial.c (≈200 líneas)
│   └── openmp/
│       └── cellular_automaton_openmp.c (≈220 líneas)
├── scripts/
│   ├── build.ps1          - Compilar ambas versiones
│   ├── run_serial.ps1     - Ejecutar versión serial
│   ├── run_openmp.ps1     - Ejecutar versión OpenMP
│   ├── profile.ps1        - Profiling comparativo
│   └── benchmark.ps1      - Benchmarking completo
├── docs/
│   ├── README.md (este archivo)
│   ├── CELLULAR_AUTOMATON_ANALYSIS.md
│   ├── PARALLELIZATION_ANALYSIS.md
│   └── PERFORMANCE_ANALYSIS.md
└── build/
    └── (Contiene ejecutables después de compilar)
```

---

## 🚀 Primeros Pasos

### 1. Compilar el Código

```powershell
cd "Reto 2"
./scripts/build.ps1
```

Esto generará dos ejecutables en la carpeta `build/`:
- `cellular_automaton_serial`
- `cellular_automaton_openmp`

### 2. Ejecutar Versión Serial

```powershell
./scripts/run_serial.ps1
```

Salida esperada:
```
=== Cellular Automaton (Serial) ===
Grid Width: 10000
Generations: 1000
Number of Runs: 10
====================================

Run 1/10... Done (0.0524 s)
Run 2/10... Done (0.0522 s)
...
=== Results ===
Average Time: 0.0523 s
...
Throughput: 1.911 B cells/s
```

### 3. Ejecutar Versión OpenMP

```powershell
./scripts/run_openmp.ps1
```

Este script automáticamente:
- Detecta el número de CPUs disponibles
- Configura OpenMP para usar todos los threads
- Ejecuta la versión paralelizada

### 4. Comparar Desempeño

```powershell
./scripts/benchmark.ps1
```

Genera un reporte comparativo en `benchmark_output.txt`

### 5. Profiling Detallado

```powershell
./scripts/profile.ps1
```

Genera análisis con diferentes números de threads en `profile_output.txt`

---

## 📊 Documentación Disponible

### 1. [CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md)
**Contiene:**
- ✅ Introducción a Autómatas Celulares
- ✅ Explicación detallada de la Regla 110
- ✅ Análisis de complejidad (O(W×G))
- ✅ Patrones de acceso a memoria
- ✅ Características esperadas del algoritmo

**Objetivo:** Entender QUÉ es el algoritmo y cómo funciona

---

### 2. [PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md)
**Contiene:**
- ✅ Análisis de dependencias de datos
- ✅ Opciones de scheduling (static, dynamic, guided)
- ✅ Estrategia elegida y justificación
- ✅ Análisis de escalabilidad (Ley de Amdahl)
- ✅ Comparación de enfoques
- ✅ Predicciones teóricas de speedup

**Objetivo:** Entender CÓMO se paraleliza y POR QUÉ

---

### 3. [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)
**Contiene:**
- ✅ Metodología de análisis de desempeño
- ✅ Resultados esperados (serial vs paralelo)
- ✅ Análisis de sincronización (overhead < 1%)
- ✅ Análisis de caché y memory hierarchy
- ✅ False sharing analysis
- ✅ Oportunidades de optimización (15-25% mejora)
- ✅ Estrategia de profiling
- ✅ Matriz de decisión de optimización

**Objetivo:** Entender CUÁL es el desempeño esperado y CÓMO optimizar

---

## 💡 Puntos Clave del Reto

### Objetivo 1: Análisis del Algoritmo ✅ COMPLETADO
- Documentación teórica: [CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md)
- Código referenciado con comentarios

### Objetivo 2: Implementación Serial ✅ COMPLETADO
- Archivo: [src/serial/cellular_automaton_serial.c](src/serial/cellular_automaton_serial.c)
- ~200 líneas de código limpio y comentado
- Utiliza `clock()` para timing
- Realiza 10 runs para estadísticas

### Objetivo 3: Análisis de Paralelización ✅ COMPLETADO
- Documento: [PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md)
- Análisis detallado de opciones
- Justificación de decisiones
- Predicciones teóricas

### Objetivo 4: Implementación Paralelizada ✅ COMPLETADO
- Archivo: [src/openmp/cellular_automaton_openmp.c](src/openmp/cellular_automaton_openmp.c)
- Paralelización con OpenMP
- Utiliza `omp_get_wtime()` para timing
- Mismo patrón de ejecución que serial

---

## 📈 Ejecución Recomendada

### Fase 1: Validación Básica (15 min)
```powershell
./scripts/build.ps1
./scripts/run_serial.ps1
./scripts/run_openmp.ps1
```

### Fase 2: Benchmarking (20 min)
```powershell
./scripts/benchmark.ps1
```

### Fase 3: Profiling Detallado (30 min)
```powershell
./scripts/profile.ps1
```

### Fase 4: Análisis de Resultados (60 min)
- Revisar `benchmark_output.txt`
- Revisar `profile_output.txt`
- Calcular speedup y eficiencia
- Comparar con predicciones teóricas

### Fase 5: Optimización (Opcional - 120 min)
- Aplicar sugerencias de [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)
- Recompilar con flags adicionales
- Comparar resultados

---

## 🔍 Qué Esperar

### Versión Serial
- Tiempo esperado: 50-150 ms (depende de CPU)
- Throughput: 600 Mcells/s - 2 Gcells/s

### Versión OpenMP (Quad-Core)
- Speedup esperado: 3.5-3.8x
- Eficiencia: 87-95%

### Versión OpenMP (Octa-Core)
- Speedup esperado: 7.2-7.8x
- Eficiencia: 90-97%

---

## 🛠️ Customización de Ejecución

### Cambiar Tamaño de Grilla
```powershell
./scripts/run_serial.ps1 -Width 20000 -Generations 1000 -Runs 10
./scripts/run_openmp.ps1 -Width 20000 -Generations 1000 -Runs 10
```

### Cambiar Número de Threads
```powershell
./scripts/run_openmp.ps1 -Threads 2
./scripts/run_openmp.ps1 -Threads 4
./scripts/run_openmp.ps1 -Threads 8
```

### Compilar con Optimización Extra
Editar `scripts/build.ps1` y cambiar:
```powershell
# De:
gcc -O3 -Wall -Wextra -o $openmpExe $openmpSrc -lm

# A:
gcc -O3 -march=native -Wall -Wextra -fopenmp -ffast-math \
    -funroll-loops -o $openmpExe $openmpSrc -lm
```

---

## 📝 Archivo de Resultados

Se generan automáticamente:
- `benchmark_output.txt` - Comparativo serial vs OpenMP
- `profile_output.txt` - Profiling con múltiples configuraciones
- `build/profile_summary.csv` - Datos en formato CSV

---

## ❓ Preguntas Comunes

### P: ¿Qué es la Regla 110?
**R:** Es un autómata celular de Wolfram que determina si una célula vive o muere basado en su vecindario. Ver [CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md)

### P: ¿Por qué se usa static scheduling en OpenMP?
**R:** Porque todas las iteraciones tienen igual costo y la localidad de caché es crítica. Ver [PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md)

### P: ¿Cuál es el overhead de OpenMP?
**R:** Menos del 1% del tiempo de cómputo. Ver [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)

### P: ¿Hay race conditions?
**R:** No. Cada thread escribe a índices diferentes sin overlap. Ver análisis de false sharing en [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)

---

## 🎯 Tiempo Estimado

| Fase | Tiempo |
|------|--------|
| Compilación | 2 min |
| Ejecución Serial | 2 min |
| Ejecución OpenMP | 2 min |
| Benchmarking | 10 min |
| Profiling Detallado | 30 min |
| Análisis de Resultados | 60 min |
| Optimización (opcional) | 120 min |
| **Total** | **≈ 8 horas** |

---

## 📚 Estructura de Aprendizaje Recomendada

1. **Leer README.md** (5 min)
2. **Leer CELLULAR_AUTOMATON_ANALYSIS.md** (30 min)
3. **Compilar y ejecutar básico** (5 min)
4. **Leer PARALLELIZATION_ANALYSIS.md** (30 min)
5. **Ejecutar profiling** (30 min)
6. **Leer PERFORMANCE_ANALYSIS.md** (30 min)
7. **Analizar resultados y escribir conclusiones** (60 min)
8. **Optimizar (opcional)** (120 min)

---

## ✅ Checklist de Completitud

- [ ] Código serial compilado y funcionando
- [ ] Código OpenMP compilado y funcionando
- [ ] Benchmarking ejecutado (serial vs OpenMP)
- [ ] Profiling con múltiples thread counts
- [ ] Speedup calculado y comparado con predicciones
- [ ] Análisis de resultados escrito
- [ ] Conclusiones documentadas
- [ ] (Opcional) Optimizaciones aplicadas

---

## 🤝 Próximos Pasos

1. Ejecutar `./scripts/build.ps1` para compilar
2. Ejecutar `./scripts/benchmark.ps1` para comparación rápida
3. Revisar `benchmark_output.txt` para resultados
4. Leer documentación teórica en orden sugerido
5. Ejecutar `./scripts/profile.ps1` para análisis profundo
6. Escribir conclusiones basadas en datos reales

---

**Éxito en el Reto 2! 🚀**

Para dudas sobre el código, ver comentarios en los archivos .c
Para dudas sobre el análisis, ver documentación en docs/
