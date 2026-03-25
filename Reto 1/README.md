# Reto 1 - Jacobi Iterativo para Poisson 1D

Este directorio contiene una solucion base para el reto:

1. Analisis del algoritmo de Jacobi Iterativo para la ecuacion de Poisson 1D.
2. Implementacion serial en C.
3. Implementaciones paralelas de bajo nivel con threads (`pthread`) y procesos (`fork`).
4. Estructura para analisis de desempeno.

## Estructura

- `src/serial/jacobi_serial.c`: version serial.
- `src/threads/jacobi_threads.c`: version paralela con hilos POSIX.
- `src/processes/jacobi_processes.c`: version paralela con `fork` y memoria compartida.
- `scripts/build.ps1`: compilacion rapida.
- `scripts/run_examples.ps1`: ejecucion de ejemplos.
- `docs/HPCG2-Reto1-DavidSantiagoLugoCabrera-JoseAroudoJuniordeAsisPinedo-AngieCarolinaVargasVillegas.md`: documento base del informe.

## Modelo matematico

Se resuelve el problema:

- `-u''(x) = f(x)`, con `x in (0,1)`
- `u(0) = 0`, `u(1) = 0`

Usando diferencias finitas con paso `h = 1/(N+1)`, para nodos internos `i=1..N`:

`u_i^{k+1} = 0.5 * (u_{i-1}^k + u_{i+1}^k + h^2 f_i)`

## Compilacion

> En Windows, el script compila `serial` y `threads` (si tienes `gcc` + `pthread`).
> La version `fork` (`processes`) requiere Linux/WSL por uso de `mmap` y sincronizacion POSIX entre procesos.

Desde `Reto 1`:

```powershell
./scripts/build.ps1
```

## Ejecucion

```powershell
./scripts/run_examples.ps1
```

O manualmente:

```bash
./build/jacobi_serial 100000 10000 1e-6
./build/jacobi_threads 100000 10000 1e-6 8
./build/jacobi_processes 100000 10000 1e-6 8
```

Parametros:

1. `N`: numero de puntos internos.
2. `max_iter`: iteraciones maximas.
3. `tol`: tolerancia de convergencia (norma infinito del cambio).
4. `workers`: numero de hilos/procesos (solo versiones paralelas).
