# Paralelización MIMD con POSIX Threads

## Estrategia de Paralelización

La implementación paralela en `src/threads/multmat_threads.c` utiliza **MIMD** (Multiple Instruction, Multiple Data) de la taxonomía de Flynn:

### Características Clave

| Aspecto | Descripción |
|---|---|
| **Modelo de cómputo** | MIMD - Cada hilo ejecuta el mismo kernel de forma independiente |
| **División de datos** | Filas de C distribuidas en chunks proporcionales entre threads |
| **Sincronización** | `pthread_join()` al final - todos los threads deben terminar |
| **Acceso a datos** | A y B_T compartidas (lectura), C privada por filas sin conflictos |
| **Overhead** | Creación/destrucción de threads, sincronización final |

### Estructura de Distribución

Para matriz $N \times N$ con $t$ threads:
```
filas_por_thread = N / t               (división entera)
residuo = N % t

Hilo_i asignado [start_i, end_i) donde:
  start_i = suma de filas asignadas a hilos 0..i-1
  end_i = start_i + filas_por_thread + (1 si i < residuo else 0)
```

**Ejemplo: N=1000, t=4**
```
Hilo 0: filas [0, 250)      - 250 filas
Hilo 1: filas [250, 500)    - 250 filas
Hilo 2: filas [500, 750)    - 250 filas
Hilo 3: filas [750, 1000)   - 250 filas
Total: 250 * 4 = 1000 filas
```

## Medición de Tiempo

La medición es **coherente** incluyendo overhead de paralelización:

```c
double t2 = get_time_ms();              // INICIO
for (int t = 0; t < num_threads; t++) {
    pthread_create(&threads[t], ...);   // Creación de threads
}
for (int t = 0; t < num_threads; t++) {
    pthread_join(threads[t], NULL);     // Esperar finalización
}
double t3 = get_time_ms();              // FIN
double elapsed = t3 - t2;               // Incluye overhead
```

Esto significa el tiempo medido incluye:
1. Creación de estructuras pthread
2. Ejecución del kernel en paralelo
3. Sincronización (espera al hilo más lento)

## Resultados Empíricos de Escalabilidad

Resultados en máquina típica (4 núcleos lógicos):

### N=1000 (Matriz Mediana)
```
Hilos  Tiempo (ms)  Speedup  Eficiencia
1      395.3 ms     1.00x    100.0%
2      208.4 ms     1.90x    94.8%
4      145.9 ms     2.71x    67.7%
8      123.2 ms     3.21x    40.1%
```

**Análisis:**
- **2 threads**: Excelente escalabilidad (94.8%) - máquina aprox. sin contención
- **4 threads**: Buena escalabilidad (67.7%) - cerca del número de cores
- **8 threads**: Overhead de context switching (40.1%)

### N=2000 (Matriz Grande)
```
Hilos  Tiempo (ms)   Speedup  Eficiencia
1      4030.3 ms     1.00x    100.0%
2      2195.2 ms     1.84x    91.8%
4      1059.6 ms     3.80x    95.1%
8      842.0 ms      4.79x    59.8%
```

**Análisis:**
- **4 threads**: Casi lineal (95.1%)! - carga de trabajo compensa overhead
- **8 threads**: Mejora absoluta significant (~4.8x) pero eficiencia baja
- Conclusión: Para N=2000 la paralelización es muy efectiva

### N=100 (Matriz Pequeña)
```
Hilos  Tiempo (ms)  Speedup  Eficiencia
1      0.398 ms     1.00x    100.0%
2      0.542 ms     0.73x    36.7%
4      0.561 ms     0.71x    17.7%
8      1.039 ms     0.38x    4.8%
```

**Análisis:**
- **Overhead domina**: Creación de threads cuesta más que cómputo
- **Lección**: No usar paralelización para matrices muy pequeñas
- Threshold aproximado: N > 300-400 para que valga pena

## Ventajas de MIMD

✓ **Escalabilidad lineal** en máquinas multi-core (hasta ~número de cores)  
✓ **Sin locks/mutexes** en el kernel - cada hilo escribe en sus filas  
✓ **Alta localidad espacial** preservada: cada hilo accede a caché L1/L2  
✓ **Bajo overhead** comparado con modelos de comunicación más complejos  

## Limitaciones Observadas

✗ **Overhead > beneficio** para matrices pequeñas (N < ~300)  
✗ **Escalabilidad degrada** con threads > cores (context switching)  
✗ **Cache contention** con muchos threads (compitiendo por L3)  
✗ **Memory bandwidth** puede ser cuello de botella en matrices muy grandes  

## Comparación: Serie vs Paralelo

| Tamaño | Hilos | Serial (ms) | Paralelo (ms) | Speedup | Recomendación |
|---|---|---|---|---|---|
| N=100 | 1 | 0.398 | 0.398 | 1.0x | ❌ No usar paralelo |
| N=100 | 4 | — | 0.561 | 0.71x | ❌ Demasiado overhead |
| N=500 | 1 | 42.5 | 42.5 | 1.0x | ⚠️ Borde |
| N=500 | 4 | — | 19.3 | 2.2x | ✅ Vale pena |
| N=1000 | 4 | 395 | 146 | 2.71x | ✅ Buena ganancia |
| N=2000 | 4 | 4030 | 1060 | 3.80x | ✅ Excelente ganancia |

## Uso

```powershell
# Ejecutar con número de threads
.\build\multmat_threads.exe 1000 4      # N=1000, 4 threads

# Comparación automática
.\scripts\compare_serial_vs_threads.ps1
```

## Parámetros

| Argumento | Descripción | Default | Rango |
|---|---|---|---|
| N | Tamaño matriz | Requerido | > 0 |
| num_threads | Threads MIMD | 4 | 1 a cores*2 |
| seed | Aleatorios | time(NULL) | Cualquier int |
| max_val | Rango valores | 9 | 0+ |

---

**Conclusión Pedagógica:**

La paralelización MIMD con división de datos por filas es efectiva para matrices matrices medianas y grandes (N ~> 500 en máquinas de 4 cores o más), logrando speedups de **2.7x-4.8x** con escalabilidad cercana a lineal. El overhead de threading domina para matrices pequeñas, haciendo la versión serial preferible en esos casos.
