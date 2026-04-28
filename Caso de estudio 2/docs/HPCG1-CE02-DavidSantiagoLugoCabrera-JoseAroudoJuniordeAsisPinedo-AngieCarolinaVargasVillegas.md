# HPCG1-CE02 - David Santiago Lugo Cabrera - Jose Aroudo Junior de Asis Pinedo - Angie Carolina Vargas Villegas

## Multiplicacion de Matrices en C con Serial y OpenMP

**Integrantes**

- David Santiago Lugo Cabrera
- Jose Aroudo Junior de Asis Pinedo
- Angie Carolina Vargas Villegas

---

## 1. Objetivo de la actividad

El objetivo de esta entrega fue analizar e informar el comportamiento de la **multiplicacion de matrices** en C, incluyendo:

- implementacion base serial,
- implementacion concurrente con OpenMP,
- caracterizacion de CPU y memoria,
- benchmark de desempeno,
- comparacion de resultados en dos equipos,
- y preparacion del documento final para sustentacion.

En esta version se reportan la base serial en [src/serial/multmat_serial.c](../src/serial/multmat_serial.c) y la version concurrente en [src/openmp/multmat_openmp.c](../src/openmp/multmat_openmp.c).

## 2. Descripcion de la implementacion

La base serial realiza la multiplicacion de dos matrices cuadradas `N x N` generadas aleatoriamente. El flujo general es:

1. reservar memoria para `A`, `B` y `C`,
2. llenar `A` y `B` con valores aleatorios,
3. ejecutar el kernel serial de multiplicacion,
4. imprimir tiempos de llenado, multiplicacion y total.

La version OpenMP conserva el mismo resultado numerico, pero divide el trabajo por filas entre hilos. Antes de multiplicar, transpone `B` para mejorar la localidad espacial del acceso.

La medida principal del programa es el tiempo de multiplicacion, porque ese tramo concentra la mayor parte del costo computacional.

## 3. Caracterizacion de CPU

### 3.1 Complejidad algoritmica

El kernel serial usa tres bucles anidados:

- `i` recorre las filas de `A`,
- `j` recorre las columnas de `B`,
- `k` recorre la suma producto.

Eso produce una complejidad de **$O(N^3)$** en tiempo.

### 3.2 Perfil CPU

El consumo de CPU está dominado por:

- operaciones enteras en el bucle interno,
- multiplicaciones y sumas acumuladas en `long long`,
- accesos repetidos a memoria dentro del kernel.

En la practica, el tiempo de CPU crece de forma cubica con el tamanio de la matriz, por lo que los casos pequenos sirven como linea base y los casos medianos/grandes muestran mejor la carga real del procesador.

### 3.3 Perfilado de CPU medido en esta maquina

El benchmark ejecutado en esta maquina con 10 corridas por configuracion arrojo estos tiempos promedio de multiplicacion:

| Configuracion | N=100 | N=500 | N=1000 | N=2000 |
|---|---:|---:|---:|---:|
| Serial | 0.459 ms | 53.411 ms | 413.872 ms | 3443.264 ms |
| OpenMP-4 | 1.350 ms | 17.160 ms | 122.030 ms | 964.856 ms |
| OpenMP-8 | 1.284 ms | 12.869 ms | 84.176 ms | 636.942 ms |

Interpretacion:

- Para `N=100`, la sobrecarga de OpenMP supera el beneficio.
- Desde `N=500`, OpenMP empieza a mostrar ventaja clara.
- En `N=1000` y `N=2000`, la version de 8 hilos es la mas rapida de esta maquina.

### 3.3 Medicion usada en el informe

El programa ya reporta el tiempo de multiplicacion en milisegundos. Para el informe se toman las corridas almacenadas en:

- [benchmark_summary.csv](./benchmark_summary.csv)

## 4. Caracterizacion de memoria

### 4.1 Uso de memoria por estructura

La implementacion serial reserva tres arreglos principales:

- `A`: `N x N` enteros,
- `B`: `N x N` enteros,
- `C`: `N x N` valores `long long`.

### 4.2 Formula de memoria

Si un `int` ocupa 4 bytes y un `long long` ocupa 8 bytes, el uso aproximado es:

$$
M(N) = 4N^2 + 4N^2 + 8N^2 = 16N^2 \text{ bytes}
$$

Esto equivale, aproximadamente, a:

- `N=100`: 160000 bytes, unos 0.15 MiB,
- `N=500`: 4000000 bytes, unos 3.81 MiB,
- `N=1000`: 16000000 bytes, unos 15.26 MiB,
- `N=2000`: 64000000 bytes, unos 61.04 MiB.

### 4.3 Interpretacion

La memoria crece de forma cuadratica con `N`, mientras que el tiempo crece de forma cubica. Por eso, en este problema el cuello principal termina siendo CPU y no solo capacidad de almacenamiento.

### 4.4 Perfilado de memoria en esta maquina

El consumo teorico estimado para las estructuras del programa es:

| N | Memoria estimada |
|---|---:|
| 100 | 160000 bytes (~0.15 MiB) |
| 500 | 4000000 bytes (~3.81 MiB) |
| 1000 | 16000000 bytes (~15.26 MiB) |
| 2000 | 64000000 bytes (~61.04 MiB) |

En la practica, el consumo real del proceso depende del runtime, pero este calculo permite dimensionar el crecimiento del problema y justificar por que el benchmark de `N=2000` ya presiona con mas fuerza el subsistema de memoria.

## 5. Perfilado real de CPU y memoria

El perfilado se realizo ejecutando el binario y muestreando el proceso mientras corria. Se midieron estos indicadores:

- `Wall_s`: tiempo total real de ejecucion,
- `CPU_s`: tiempo acumulado de CPU del proceso,
- `PeakWorkingSet_MB`: pico de memoria residente,
- `PeakPrivateMemory_MB`: pico de memoria privada,
- `CPU_to_Wall`: relacion entre CPU y tiempo real, util para ver el uso efectivo de multiples nucleos.

Los datos provinieron de [profile_summary.csv](./profile_summary.csv).

### 5.1 Perfilado de la base serial

| N | Wall_s | CPU_s | Peak Working Set (MB) | Peak Private Memory (MB) | CPU/Wall |
|---|---:|---:|---:|---:|---:|
| 100 | 0.037696 | 0.000000 | 3.02 | 0.44 | 0.00 |
| 500 | 0.091642 | 0.046875 | 6.61 | 4.36 | 0.51 |
| 1000 | 0.464862 | 0.437500 | 18.86 | 15.82 | 0.94 |
| 2000 | 3.597797 | 3.515625 | 64.94 | 61.69 | 0.98 |

### 5.2 Perfilado de OpenMP con 4 hilos

| N | Wall_s | CPU_s | Peak Working Set (MB) | Peak Private Memory (MB) | CPU/Wall |
|---|---:|---:|---:|---:|---:|
| 100 | 0.039136 | 0.000000 | 3.02 | 0.44 | 0.00 |
| 500 | 0.056573 | 0.062500 | 8.91 | 5.78 | 1.10 |
| 1000 | 0.178938 | 0.468750 | 23.89 | 20.13 | 2.62 |
| 2000 | 1.056642 | 3.750000 | 81.19 | 77.48 | 3.55 |

### 5.3 Perfilado de OpenMP con 8 hilos

| N | Wall_s | CPU_s | Peak Working Set (MB) | Peak Private Memory (MB) | CPU/Wall |
|---|---:|---:|---:|---:|---:|
| 100 | 0.039834 | 0.000000 | 3.02 | 0.44 | 0.00 |
| 500 | 0.057444 | 0.125000 | 8.90 | 5.91 | 2.18 |
| 1000 | 0.146524 | 0.703125 | 24.02 | 20.27 | 4.80 |
| 2000 | 0.767008 | 5.109375 | 81.09 | 77.71 | 6.66 |

### 5.4 Lectura del perfilado

- La memoria privada pico sube con el tamanio de la matriz, como era esperable por la formula `16N^2`.
- La version serial usa aproximadamente un nucleo completo cuando `N` es grande, porque `CPU_s` y `Wall_s` casi coinciden.
- OpenMP aumenta `CPU_s` porque varios hilos consumen CPU en paralelo; por eso la razon `CPU/Wall` crece con el numero de hilos.
- El mayor pico de memoria aparece en `N=2000`, con alrededor de `61.69 MB` en serial y `77.71 MB` en OpenMP-8.

## 6. Metodologia de benchmark

Para conservar comparabilidad se empleo la misma estrategia en todas las corridas:

- mismos ejecutables serial y OpenMP,
- mismos tamanos de matriz,
- 10 corridas por configuracion,
- compilacion con optimizacion de compilador `-O2` como base y `-fopenmp` para la version paralela.

Los tamanos evaluados fueron:

- `N = 100`
- `N = 500`
- `N = 1000`
- `N = 2000`

## 7. Resultados del benchmark en la primera maquina

Los resultados siguientes provienen del resumen almacenado en [benchmark_summary.csv](./benchmark_summary.csv).

### 7.1 Serial

| N | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) |
|---|---:|---:|---:|---:|
| 100 | 0.459 | 0.013 | 0.442 | 0.485 |
| 500 | 53.411 | 1.057 | 51.357 | 54.818 |
| 1000 | 413.872 | 4.352 | 410.173 | 426.033 |
| 2000 | 3443.264 | 24.931 | 3408.558 | 3482.634 |

### 7.2 OpenMP 4 hilos

| N | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) |
|---|---:|---:|---:|---:|
| 100 | 1.350 | 0.061 | 1.254 | 1.466 |
| 500 | 17.160 | 2.043 | 15.156 | 22.761 |
| 1000 | 122.030 | 7.868 | 110.307 | 137.591 |
| 2000 | 964.856 | 23.085 | 929.508 | 1012.020 |

### 7.3 OpenMP 8 hilos

| N | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) |
|---|---:|---:|---:|---:|
| 100 | 1.284 | 0.138 | 1.116 | 1.608 |
| 500 | 12.869 | 0.275 | 12.329 | 13.326 |
| 1000 | 84.176 | 3.381 | 79.919 | 90.101 |
| 2000 | 636.942 | 13.970 | 618.909 | 660.740 |

### 7.4 Speedup vs serial

| N | OpenMP 4h | OpenMP 8h |
|---|---:|---:|
| 100 | 0.34x | 0.36x |
| 500 | 3.11x | 4.15x |
| 1000 | 3.39x | 4.92x |
| 2000 | 3.57x | 5.41x |

### 7.5 Lectura de los resultados

- El crecimiento del tiempo es consistente con la complejidad `O(N^3)`.
- Para `N=100`, la sobrecarga de OpenMP domina y la version serial sigue siendo mejor.
- A partir de `N=500`, OpenMP supera con claridad a la base serial.
- En `N=1000` y `N=2000`, OpenMP con 8 hilos obtiene el mejor resultado de esta maquina.
- La eficiencia mejora cuando el trabajo por hilo es suficiente para amortizar la sobrecarga de sincronizacion y transposicion.

## 8. Benchmark en dos maquinas

La actividad pide comparar en dos equipos. El procedimiento recomendado es el mismo en ambos casos:

1. compilar el programa con [scripts/build.ps1](../scripts/build.ps1),
2. ejecutar [scripts/benchmark.ps1](../scripts/benchmark.ps1),
3. repetir 10 veces por cada tamanio,
4. registrar promedio, desviacion, minimo y maximo,
5. copiar los resultados al mismo formato de tabla.

### 8.1 Maquina 1

Esta seccion corresponde a esta maquina y ya quedo cubierta en la seccion de resultados anterior.

### 8.2 Maquina 2

Completar con el mismo formato despues de ejecutar el benchmark en el segundo equipo.

#### 8.2.1 Serial

| N | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) | Observaciones |
|---|---:|---:|---:|---:|---|
| 100 |  |  |  |  |  |
| 500 |  |  |  |  |  |
| 1000 |  |  |  |  |  |
| 2000 |  |  |  |  |  |

#### 8.2.2 OpenMP 4 hilos

| N | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) | Observaciones |
|---|---:|---:|---:|---:|---|
| 100 |  |  |  |  |  |
| 500 |  |  |  |  |  |
| 1000 |  |  |  |  |  |
| 2000 |  |  |  |  |  |

#### 8.2.3 OpenMP 8 hilos

| N | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) | Observaciones |
|---|---:|---:|---:|---:|---|
| 100 |  |  |  |  |  |
| 500 |  |  |  |  |  |
| 1000 |  |  |  |  |  |
| 2000 |  |  |  |  |  |

### 8.3 Como llenar la segunda maquina

Ejecutar el mismo benchmark en el segundo equipo con la misma semilla, los mismos tamanos y el mismo numero de corridas. Luego copiar los promedios y desvios en las tablas anteriores para permitir comparacion directa.

## 9. Conclusiones

1. La base serial sirve como referencia correcta y estable para medir la ganancia de OpenMP.
2. El comportamiento temporal confirma la complejidad `O(N^3)` del problema.
3. La memoria crece como `16N^2` bytes y justifica por que el problema escala rapidamente en consumo de RAM.
4. En esta maquina, OpenMP no compensa para `N=100`, pero si ofrece mejoras fuertes para `N >= 500`.
5. La mejor configuracion medida aqui fue OpenMP con 8 hilos en `N=2000`, con `636.942 ms` frente a `3443.264 ms` de la base serial.
6. Falta repetir exactamente el mismo procedimiento en la segunda maquina para completar la comparacion de rendimiento.

## 10. Referencia tecnica

- [src/serial/multmat_serial.c](../src/serial/multmat_serial.c)
- [src/openmp/multmat_openmp.c](../src/openmp/multmat_openmp.c)
- [scripts/benchmark.ps1](../scripts/benchmark.ps1)
- [scripts/build.ps1](../scripts/build.ps1)
- [scripts/profile.ps1](../scripts/profile.ps1)
- [build/benchmark_summary.csv](../build/benchmark_summary.csv)
- [profile_summary.csv](./profile_summary.csv)
