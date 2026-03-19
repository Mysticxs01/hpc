# Informe Final de la Actividad

## Portada (para version PDF)

**Titulo:** Implementacion de Concurrencia, Paralelismo y Optimizacion en Multiplicacion de Matrices en C

**Integrantes:**

- Angie Carolina Vargas Villegas
- Jose Aroudo Junior de Asis Pinedo
- David Santiago Lugo Cabrera
- Nombre4 (pendiente de confirmar)

## Contexto de la tarea

La actividad consistio en implementar concurrencia y paralelismo a bajo nivel en C para el problema de multiplicacion de matrices, sin frameworks, usando librerias del lenguaje y del sistema (por ejemplo `pthread`), aplicando ademas tecnicas de optimizacion de CPU y memoria vistas en laboratorio. Tambien se pidio realizar pruebas de desempeno y documentar resultados.

Este informe resume el trabajo ya realizado en el proyecto y presenta los resultados obtenidos de forma clara para entrega y sustentacion.

## Objetivo cumplido

Se cumplio con los tres ejes solicitados:

1. Implementacion de soluciones en C: version serial base, version paralela con hilos (`pthread`) y version paralela con procesos (Win32 + memoria compartida).
2. Aplicacion de optimizaciones: optimizacion de compilacion (`-O0`, `-O1`, `-O2`, `-O3`, `-Os`) y optimizacion de acceso a memoria/cache en la version serial optimizada.
3. Pruebas y comparacion de rendimiento: scripts de compilacion y ejecucion automatica, mas benchmark con tablas y curvas de speedup para distintos tamanos de matriz.

## Que se desarrollo en el proyecto

Componentes principales usados para la actividad:

- `src/serial/multmat_serial.c`
- `src/serial/multmat_serial_optimized.c`
- `src/threads/multmat_threads.c`
- `src/processes/multmat_procesos.c`
- `scripts/benchmark.ps1`
- `scripts/compare_serial_vs_threads.ps1`
- `scripts/compare_cache_optimization.ps1`

Documentacion de soporte:

- `docs/MIMD_PARALLELIZATION_GUIDE.md`
- `docs/CACHE_OPTIMIZATION_GUIDE.md`

## Metodologia de prueba

Se ejecuto el benchmark completo:

```powershell
./scripts/benchmark.ps1
```

Escenarios evaluados:

- Tamanos: `N = 100, 500, 1000, 2000`
- Hilos: `2, 4, 8`
- Procesos: `4`
- Flags de compilacion serial: `-O0`, `-O1`, `-O2`, `-O3`, `-Os`

Se midieron tiempos de llenado, multiplicacion y total. La comparacion principal de rendimiento se hizo con speedup respecto a la referencia serial `-O2`.

## Resultados principales

### Prueba clave: 10 corridas por implementacion (resultado principal)

Para reforzar la validez de los resultados, se ejecutaron **10 corridas** por cada implementacion y por cada tamano de matriz, y se calcularon estadisticas de tiempo de multiplicacion:

- Promedio (ms)
- Desvio estandar (ms)
- Minimo y maximo (ms)
- Speedup promedio vs `Serial -O2`

Configuraciones comparadas en esta prueba:

- `Serial -O2`
- `Threads (4 hilos)`
- `Threads (8 hilos)`
- `Procesos (4 procesos)`

#### Resumen estadistico (10 corridas)

| N | Implementacion | Promedio (ms) | Desvio (ms) | Min (ms) | Max (ms) | Speedup vs Serial (promedio) |
|---|---|---:|---:|---:|---:|---:|
| 100 | Serial -O2 | 0.479 | 0.043 | 0.445 | 0.559 | 1.00x |
| 100 | Threads (4h) | 1.002 | 0.122 | 0.856 | 1.224 | 0.48x |
| 100 | Threads (8h) | 1.054 | 0.056 | 0.999 | 1.203 | 0.45x |
| 100 | Procesos (4p) | 15.051 | 0.486 | 13.990 | 16.000 | 0.03x |
| 500 | Serial -O2 | 52.960 | 1.863 | 51.162 | 57.486 | 1.00x |
| 500 | Threads (4h) | 15.599 | 0.861 | 14.669 | 17.414 | 3.40x |
| 500 | Threads (8h) | 12.485 | 0.727 | 11.318 | 13.515 | 4.24x |
| 500 | Procesos (4p) | 30.658 | 2.570 | 28.429 | 36.421 | 1.73x |
| 1000 | Serial -O2 | 424.679 | 11.964 | 408.409 | 438.456 | 1.00x |
| 1000 | Threads (4h) | 117.669 | 7.505 | 105.497 | 130.888 | 3.61x |
| 1000 | Threads (8h) | 87.048 | 8.411 | 79.614 | 111.036 | 4.88x |
| 1000 | Procesos (4p) | 135.798 | 7.949 | 126.179 | 154.005 | 3.13x |
| 2000 | Serial -O2 | 3440.300 | 13.051 | 3423.483 | 3463.339 | 1.00x |
| 2000 | Threads (4h) | 940.580 | 14.266 | 918.177 | 962.783 | 3.66x |
| 2000 | Threads (8h) | 658.223 | 17.374 | 632.544 | 695.514 | 5.23x |
| 2000 | Procesos (4p) | 957.275 | 25.177 | 913.438 | 1002.661 | 3.59x |

#### Comparacion directa de la prueba de 10 corridas

1. Para `N=100`, la mejor opcion fue serial; el costo de paralelizar no se recupera.
2. Desde `N=500`, `Threads (8h)` fue la opcion con mejor tiempo promedio.
3. En `N=1000`, `Threads (8h)` logro `4.88x`, mientras `Threads (4h)` quedo en `3.61x` y procesos en `3.13x`.
4. En `N=2000`, `Threads (8h)` alcanzo `5.23x`, el mejor resultado sostenido del estudio.
5. Procesos mejoro mucho en cargas grandes, pero en promedio quedo por debajo de threads para este equipo.

Estos resultados de 10 corridas son la base principal para las conclusiones de desempeno del proyecto.

### Tabla resumen de rendimiento (multiplicacion)

| N | Serial -O2 (ms) | Threads 2h (ms) | Threads 4h (ms) | Threads 8h (ms) | Procesos 4p (ms) | Sp 2h | Sp 4h | Sp 8h | Sp Proc |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 100  | 0.457   | 1.015   | 0.916   | 0.955   | 15.266  | 0.45x | 0.50x | 0.48x | 0.03x |
| 500  | 54.302  | 28.017  | 21.793  | 12.889  | 29.153  | 1.94x | 2.49x | 4.21x | 1.86x |
| 1000 | 448.911 | 222.255 | 130.818 | 81.913  | 132.976 | 2.02x | 3.43x | 5.48x | 3.38x |
| 2000 | 3420.236| 1704.767| 936.516 | 650.096 | 926.241 | 2.01x | 3.65x | 5.26x | 3.69x |

### Lectura general de las curvas de speedup

- Para matrices pequenas (`N=100`), el paralelo no conviene: el overhead es mayor que el beneficio.
- Desde `N=500`, la curva cambia y el paralelo mejora claramente.
- En `N=1000` y `N=2000`, la mejora es alta y estable.
- En este entorno, `Threads (8)` fue la mejor opcion en rendimiento absoluto para matrices medianas y grandes.
- `Procesos (4)` queda por debajo de threads en tamanos medios, pero en `N=2000` llega a resultados muy cercanos.

### Mejor estrategia por tamano de problema

| Tamano | Mejor opcion observada | Resultado clave |
|---|---|---|
| `N=100` | Serial (`-O2`) | El paralelo no compensa overhead |
| `N=500` | Threads (`8 hilos`) | `4.21x` de speedup |
| `N=1000` | Threads (`8 hilos`) | `5.48x` de speedup (mejor caso medido) |
| `N=2000` | Threads (`8 hilos`) | `5.26x` de speedup |

### Resultado de optimizacion serial (compilador)

La comparacion de `-O0` a `-Os` muestra que:

- `-O0` es claramente la peor opcion.
- `-O2` y `-O3` son las mejores en general, con diferencias pequenas entre ambas.
- La mayor mejora global no viene solo de cambiar flags, sino de paralelizar cuando el problema es suficientemente grande.

## Detalle tecnico clave (resumido)

### Cuando conviene cada optimizacion

- **Optimizacion de compilador (`-O2`/`-O3`)**: conviene siempre; mejora la base serial con costo de implementacion cero.
- **Optimizacion de cache/memoria**: conviene en kernels de alto acceso a memoria (como multiplicacion de matrices), sobre todo en tamanos medianos y grandes.
- **Hilos (`pthread`)**: convienen cuando la carga es suficiente para amortizar overhead (en estos resultados, desde `N=500`).
- **Procesos**: utiles cuando se requiere aislamiento entre workers o modelos multi-proceso; en rendimiento puro suelen necesitar mayor carga para competir.

### Cual optimizacion fue la mejor

- **Mejor mejora global medida**: paralelismo con `8 hilos`.
- Pico de speedup observado: **`5.48x`** en `N=1000`.
- Para `N=2000`, se mantuvo alto con **`5.26x`**.

### Que tecnica aporta mas segun el tipo de mejora

- **Mejora incremental (base del programa):** flags de compilacion + optimizacion de cache.
- **Mejora de mayor impacto en tiempos finales:** paralelismo con hilos en tamanos medianos/grandes.

## Resultado de optimizacion de memoria/cache

Con base en el modulo educativo y la documentacion del proyecto, se verifico que mejorar el patron de acceso a memoria aporta mejora en varios tamanos (especialmente medianos), aunque no siempre de manera uniforme en todos los casos.

En terminos practicos:

- La optimizacion de cache ayuda.
- El paralelismo (hilos/procesos) es el factor que mas impacta en los tiempos para cargas grandes.
- Ambas tecnicas se complementan.

## Comparacion general: Serial vs Hilos vs Procesos

Resumen simple:

- Serial: mejor opcion en matrices muy pequenas.
- Hilos: mejor relacion rendimiento/overhead para la mayoria de casos reales.
- Procesos: utiles y competitivos en cargas grandes, pero con mayor costo inicial.

## Conclusiones para la sustentacion

1. La actividad fue completada en su objetivo tecnico y experimental.
2. Se implemento concurrencia/paralelismo real a bajo nivel en C, sin frameworks.
3. Se aplicaron tecnicas de optimizacion de CPU/memoria y se comprobaron con pruebas.
4. La prueba mas importante del informe (10 corridas por implementacion) confirmo que el mejor desempeno global fue `Threads (8 hilos)` para matrices medianas y grandes.
5. Para matrices pequenas, la version serial sigue siendo preferible por overhead de sincronizacion/arranque.
6. La combinacion de optimizacion de compilador + optimizacion de memoria + paralelismo produce la mejor mejora integral.

## Recomendaciones finales

- Para ejecucion rapida en pruebas chicas: usar serial optimizado.
- Para cargas medianas y grandes: usar version con hilos.
- Para ampliar el trabajo futuro: incluir promedios de varias corridas, afinidad de CPU, y comparativa en otros equipos.

---

## Evidencia de ejecucion

- Script ejecutado: `scripts/benchmark.ps1`
- Fecha de prueba: 2026-03-19
- Este informe consolida esos resultados junto con la documentacion general del proyecto.
- Prueba adicional de 10 corridas: datos crudos en `docs/results_10_runs_raw.csv` y resumen en `docs/results_10_runs_summary.csv`.
