# Multiplicación de Matrices en C

Comparativa de rendimiento de multiplicación de matrices cuadradas $N \times N$ usando tres estrategias de paralelismo en C, con scripts de compilación y benchmarking en PowerShell.

## Implementaciones

| Carpeta | Descripción | Paralelismo |
|---|---|---|
| `Matriz_Serial/` | Versión de referencia | Ninguno |
| `Matriz_Threads/` | Hilos POSIX (`pthread`) | Múltiples hilos (por filas) |
| `Matriz_Procesos/` | Procesos Win32 + memoria compartida | Múltiples procesos (por filas) |

Todas las versiones generan matrices aleatorias, miden los tiempos de **llenado**, **multiplicación** y **total** en milisegundos, e imprimen los resultados en consola.

## Requisitos

- **GCC** (MinGW-w64 o similar para Windows)
- **PowerShell 5.1** o superior
- Sistema operativo **Windows** (la versión de procesos usa la API Win32 para memoria compartida)

## Uso

### Ejecución individual

Cada carpeta tiene su propio `run.ps1` que compila y corre pruebas con $N \in \{100, 500, 1000\}$.

```powershell
# Serial
cd Matriz_Serial
.\run.ps1

# Threads (4 hilos por defecto)
cd Matriz_Threads
.\run.ps1

# Procesos (4 procesos por defecto)
cd Matriz_Procesos
.\run.ps1
```

También se puede correr el ejecutable directamente:

```powershell
# Serial
.\multmat_serial.exe <N> [seed] [max_val]

# Threads
.\multmat_threads.exe <N> [num_threads] [seed] [max_val]

# Procesos
.\multmat_procesos.exe <N> [num_procs] [seed] [max_val]
```

### Benchmarking completo

El script `comparar.ps1` en la raíz compila todas las versiones, ejecuta pruebas con $N \in \{100, 500, 1000, 2000\}$, distintas cantidades de hilos/procesos y todos los niveles de optimización de GCC (`-O0` a `-Os`), y muestra tablas de speedup con gráficas ASCII.

```powershell
.\comparar.ps1
```

## Parámetros de los ejecutables

| Parámetro | Descripción | Default |
|---|---|---|
| `N` | Tamaño de la matriz (obligatorio) | — |
| `num_threads` / `num_procs` | Número de hilos o procesos | 4 |
| `seed` | Semilla para números aleatorios | `time(NULL)` |
| `max_val` | Valor máximo de los elementos | 9 |

## Estructura del proyecto

```
Mult-Mat/
├── comparar.ps1              # Benchmark completo con tablas y speedup
├── multmat.c                 # Fuente raíz exploratoria
├── run.ps1                   # Script raíz
├── Matriz_Serial/
│   ├── multmat_serial.c
│   └── run.ps1
├── Matriz_Threads/
│   ├── multmat_threads.c
│   └── run.ps1
└── Matriz_Procesos/
    ├── multmat_procesos.c
    └── run.ps1
```
