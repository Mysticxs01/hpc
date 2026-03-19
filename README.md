# Multiplicación de Matrices en C - Benchmarking de Paralelismo

Comparativa de rendimiento de multiplicación de matrices cuadradas $N \times N$ usando tres estrategias de paralelismo en C, con scripts de compilación y benchmarking en PowerShell.

## 📋 Contenido del Proyecto

| Componente | Descripción |
|---|---|
| **src/** | Código fuente de las tres implementaciones |
| **scripts/** | Scripts complementarios para compilación y ejecución |
| **build/** | Binarios compilados (generados automáticamente) |
| **docs/** | Documentación detallada |

## 🎯 Implementaciones

| Carpeta | Descripción | Paralelismo | Características |
|---|---|---|---|
| `src/serial/` | Versión de referencia | Ninguno | Línea base para comparación |
| `src/serial/` (optimized) | **Versión cache-optimizada** | Ninguno | **Kernel optimizado para localidad espacial** |
### Estrategia de Paralelización: MIMD (Flynn's Taxonomy)

La versión paralela implementa **MIMD** (Multiple Instruction, Multiple Data):
- **Múltiples instrucciones**: Cada hilo ejecuta el kernel de multiplicación independientemente
- **Múltiples datos**: Las filas de la matriz se dividen en chunks proporcionales entre hilos
- **División de datos**: Si N=1000 y num_threads=4, cada hilo computa ~250 filas

**Ejemplo de distribución:**
```
Hilo 0: filas [0, 250)
Hilo 1: filas [250, 500)
Hilo 2: filas [500, 750)
Hilo 3: filas [750, 1000)
```

Cada hilo computa `C[i*n+j]` para sus filas asignadas, accediendo a A y B_T en lectura (sin conflictos).
| `src/processes/` | Procesos Win32 + memoria compartida | Múltiples procesos | Distribuye por filas entre procesos |

Todas las versiones generan matrices aleatorias, miden los tiempos de **llenado**, **multiplicación** y **total** en milisegundos.

### � Comparación Serial vs Paralelo (MIMD)

Ejecutar comparativa:
```powershell
.\scripts\compare_serial_vs_threads.ps1
```

Muestra speedup y escalabilidad para N={100, 500, 1000, 2000} con 1, 2, 4, 8 hilos.

### �📚 Módulo Educativo: Optimización de Caché

Se incluye un **módulo pedagógico** que demuestra optimización de kernel manteniendo el algoritmo igual:

- [`src/serial/multmat_serial.c`](src/serial/multmat_serial.c): Kernel original con acceso a memoria saltado
- [`src/serial/multmat_serial_optimized.c`](src/serial/multmat_serial_optimized.c): Kernel optimizado con acceso lineal a caché
- Guía completa: [`docs/CACHE_OPTIMIZATION_GUIDE.md`](docs/CACHE_OPTIMIZATION_GUIDE.md)

**Impacto observado**: ~10% de mejora en matrices de tamaño medio (N=1000)

## 📦 Requisitos

- **GCC** (MinGW-w64 para Windows, o GCC nativo en Linux/macOS)
- **PowerShell 5.1** o superior
- **Windows** (para la versión de procesos que usa Win32 API)

## 🚀 Uso Rápido

### Compilar y ejecutar individual

```powershell
# Serial
.\scripts\run_serial.ps1

# Threads (4 hilos por defecto)
.\scripts\run_threads.ps1

# Procesos (4 procesos por defecto)
.\scripts\run_processes.ps1
```

### Solo compilar

```powershell
.\scripts\build.ps1
```

Esto genera los ejecutables en la carpeta `build/`.

### Benchmarking completo

```powershell
.\scripts\benchmark.ps1
```

Compila todas las versiones, ejecuta pruebas con $N \in \{100, 500, 1000, 2000\}$, distintas cantidades de hilos/procesos, todos los niveles de optimización de GCC (`-O0` a `-Os`), y muestra tablas y gráficas ASCII de speedup.

## 🎛️ Parámetros de los Ejecutables

| Parámetro | Descripción | Default |
|---|---|---|
| `N` | Tamaño de la matriz (obligatorio) | — |
| `num_threads` / `num_procs` | Número de hilos o procesos | 4 |
| `seed` | Semilla para números aleatorios | `time(NULL)` |
| `max_val` | Valor máximo de los elementos | 9 |

### Ejemplos

```powershell
# Ejecutable serial con N=1000
.\build\multmat_serial.exe 1000

# Threads con 8 hilos
.\build\multmat_threads.exe 1000 8

# Procesos con 4 procesos
.\build\multmat_procesos.exe 1000 4
```

## 📁 Estructura de Directorios

```
Mult-Mat/
├── README.md                # Este archivo
├── .gitignore              # Excluye binarios del control de versiones
│
├── docs/                   # 📚 Documentación
│   ├── README.md           # Puerto del README original
│   ├── CACHE_OPTIMIZATION_ANALYSIS.md
│   ├── CACHE_OPTIMIZATION_GUIDE.md           # ⭐ Guía cache optimization
│   └── MIMD_PARALLELIZATION_GUIDE.md         # ⭐ Guía paralelización threads
│
├── src/                    # 💻 Código fuente
│   ├── serial/
│   │   ├── multmat_serial.c            # Kernel original
│   │   └── multmat_serial_optimized.c  # ⭐ Kernel optimizado (cache-friendly)
│   ├── threads/
│   │   └── multmat_threads.c           # ⭐ Paralelo MIMD (optimizado)
│   └── processes/
│       └── multmat_procesos.c
│
├── scripts/                # 🛠️ Scripts de compilación y ejecución
│   ├── build.ps1           # Compilar todas las versiones
│   ├── run_serial.ps1      # Ejecutar versión serial
│   ├── run_threads.ps1     # Ejecutar versión threads
│   ├── run_processes.ps1   # Ejecutar versión procesos
│   ├── benchmark.ps1       # Benchmark completo con comparativas
│   ├── compare_cache_optimization.ps1  # ⭐ Comparación kernels (original vs optimizado)
│   └── compare_serial_vs_threads.ps1   # ⭐ Comparación serial vs paralelo MIMD
│
└── build/                  # 🔨 Binarios compilados (generados)
    ├── multmat_serial.exe
    ├── multmat_threads.exe
    ├── multmat_procesos.exe
    └── multmat_serial_[O0-Os].exe
```

## 🏃 Ejemplos de Uso

### 1. Compilar y ejecutar versión paralela con threads

```powershell
cd scripts
.\build.ps1           # Compila todo
cd ..

# Serial (baseline)
.\build\multmat_serial.exe 1000

# Paralelo con 4 hilos
.\build\multmat_threads.exe 1000 4

# Paralelo con 8 hilos
.\build\multmat_threads.exe 1000 8
```

### 2. Comparación automática: Serial vs Paralelo

```powershell
.\scripts\compare_serial_vs_threads.ps1
```

Muestra speedup y escalabilidad MIMD para N={100, 500, 1000, 2000} con 1-8 threads.

### 3. Ejecutar benchmarking completo (con procesos)

```powershell
cd scripts
.\benchmark.ps1
# Muestra tablas con tiempos y gráficas ASCII de speedup
```

### 3. Ejecutar directamente un binario compilado

```powershell
.\build\multmat_threads.exe 500 4  # N=500, 4 hilos
```

## 📊 Interpretación de Resultados

El output de cada programa indica:
- **Tiempo de llenado**: Generación de matrices aleatorias
- **Tiempo de multiplicación**: El kernel de cálculo
- **Tiempo total**: Suma de ambos

### Ejemplo de Output

```
=== Multiplicacion Serial de Matrices 1000x1000 ===
Tiempo de llenado:               12.345 ms
Tiempo de multiplicacion:      1234.567 ms
Tiempo total:                  1246.912 ms
```

## 🔍 Notas Técnicas

### Serial vs. Threads vs. Procesos

- **Serial**: Línea base de rendimiento puro del CPU
- **Threads**: Comparten memoria, menos overhead de sincronización
- **Procesos**: Memoria aislada, más overhead pero mejor aislamiento

### Cache Optimization (Módulo Educativo)

El proyecto incluye un ejemplo real de cómo optimizar el **kernel de multiplicación** manteniendo el algoritmo igual:

**Técnica**: Cambiar indexación de matriz B para acceso lineal en lugar de saltado

```c
// Original (cache-unfriendly): B[j + k*n] - stride = n
sum += A[i*n + k] * B[j + k*n];

// Optimizado (cache-friendly): B_T[j*n + k] - stride = 1
sum += A[i*n + k] * B_T[j*n + k];
```

**Resultados observados:**
- N=100: -9% (overhead)
- N=500: +4% (beneficio pequeño)
- **N=1000: +10% (beneficio significativo)** ✓
- N=2000: -2% (varianza)

Ejecutar comparación:
```powershell
.\scripts\compare_cache_optimization.ps1
```

Ver documentación completa: [`docs/CACHE_OPTIMIZATION_GUIDE.md`](docs/CACHE_OPTIMIZATION_GUIDE.md)

### Paralelización MIMD (Multiple Instruction, Multiple Data)

La versión con threads implementa paralelización **MIMD** con división de datos por filas:

**Estrategia:**
- Cada hilo ejecuta el kernel optimizado sobre un subset de filas
- Si N=1000 y threads=4, cada hilo computa ~250 filas
- Acceso a A y B_T es compartido (lectura, sin conflictos)
- Sincronización con `pthread_join()` al final

**Escalabilidad:**
- N=1000, 4 threads: **2.71x speedup** (67.7% eficiencia)
- N=2000, 4 threads: **3.80x speedup** (95.1% eficiencia)
- N=100, 4 threads: **0.71x** (overhead rechaza paralelización)

**Conclusión:**
- ✓ Excelente para matrices N > 500 en máquinas 4+ cores
- ✗ No recomendado para matrices pequeñas (N < 300)

Ejecutar comparación automática:
```powershell
.\scripts\compare_serial_vs_threads.ps1
```

Guía detallada: [`docs/MIMD_PARALLELIZATION_GUIDE.md`](docs/MIMD_PARALLELIZATION_GUIDE.md)

### Niveles de Optimización GCC

El script `benchmark.ps1` compila con:
- `-O0`: Sin optimización (útil para profiling)
- `-O1`, `-O2`: Optimización progresiva (velocidad)
- `-O3`: Optimización agresiva
- `-Os`: Optimizar por tamaño

## ✅ Buenas Prácticas Aplicadas

- ✅ Separación clara de código, scripts y documentación
- ✅ Estructura modular y fácil de mantener
- ✅ Scripts parametrizables y reutilizables
- ✅ .gitignore para excluir binarios
- ✅ Documentación centralizada y accesible
- ✅ Nombres descriptivos en directorios y archivos

## 📝 Contribuciones y Mejoras

El proyecto está organizado para facilitar:
- ✅ **[COMPLETADO]** Análisis de comportamiento de caché (ver módulo educativo `CACHE_OPTIMIZATION_GUIDE.md`)
- ✅ **[COMPLETADO]** Paralelización MIMD con POSIX Threads (ver `MIMD_PARALLELIZATION_GUIDE.md`)
- Agregar nuevas implementaciones (ej: GPU/CUDA, SIMD/AVX, OpenMP)
- Comparar diferentes tamaños de matriz
- Analizar diferentes números de workers
- Profundo análisis de patrones de acceso a memoria
- Extensión a otros tipos de kernels numéricos
- Benchmarking en diferentes arquitecturas (ARM, x86_64, etc.)

## 📄 Licencia

Ver documentación específica si aplica.

---

**Última actualización**: Marzo 2026
