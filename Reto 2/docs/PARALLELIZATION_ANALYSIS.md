# Análisis de Estrategias de Paralelización con OpenMP

## 1. Estructura de Paralelización

### Loop Principal - Oportunidad de Paralelización

La estructura fundamental del algoritmo es:

```c
for (int gen = 0; gen < generations; gen++) {
    // Este loop NO es paralelizable (iteraciones secuenciales)
    for (int i = 0; i < width; i++) {
        // Este loop ES paralelizable (iteraciones independientes)
        unsigned char left = current[(i - 1 + width) % width];
        unsigned char center = current[i];
        unsigned char right = current[(i + 1) % width];
        next[i] = apply_rule(left, center, right);
    }
    // Intercambiar punteros
}
```

**Análisis de Dependencias:**
- Loop externo (generaciones): **No paralelizable** - Cada generación depende de la anterior
- Loop interno (células): **Totalmente paralelizable** - El cálculo de `next[i]` es independiente de `next[j]` para i ≠ j

### Estrategia Elegida: Paralelización del Loop Interior

```c
#pragma omp parallel for \
    schedule(static) \
    shared(current, next, width) \
    default(none)
for (int i = 0; i < width; i++) {
    // Cada iteración se asigna a un thread diferente
    unsigned char left = current[(i - 1 + width) % width];
    unsigned char center = current[i];
    unsigned char right = current[(i + 1) % width];
    next[i] = apply_rule(left, center, right);
}
```

**Razones:**
1. Loop interior es completamente independiente
2. No hay escrituras en datos compartidos (cada thread escribe a `next[i]` único)
3. Lecturas de `current` son compartidas pero no modificadas (read-only)
4. La barrera implícita al final sincroniza threads antes de la siguiente generación

## 2. Análisis de Opciones de Scheduling

### Opción 1: Static Scheduling (ELEGIDA)

```c
#pragma omp parallel for schedule(static) \
    shared(current, next, width) default(none)
```

**Ventajas:**
- Overhead mínimo: La asignación es determinística y se calcula una sola vez
- Excelente localidad de datos: Cada thread accede a un rango contiguo
- Predecible: Reproducible entre ejecuciones
- Balanceo perfecto: Con `width` divisible por threads, carga uniforme

**Desventajas:**
- Si `width` no es divisible por threads, hay desbalanceo mínimo

**Fórmula de Asignación:**
```
chunk_size = width / num_threads
thread_i procesa cells: [i × chunk_size, (i+1) × chunk_size)
```

**Ejemplo (width=100, threads=4):**
```
Thread 0: cells 0-24    (25 células)
Thread 1: cells 25-49   (25 células)
Thread 2: cells 50-74   (25 células)
Thread 3: cells 75-99   (25 células)
```

**Análisis de Caché:**
- Cada thread accede a su rango contiguously
- Minimiza false sharing (dados en cache lines diferentes)
- Perfecto para prefetching del hardware

---

### Opción 2: Dynamic Scheduling (No usada, pero analizado)

```c
#pragma omp parallel for schedule(dynamic, chunk_size) \
    shared(current, next, width) default(none)
```

**Ventajas:**
- Mejor balanceo con carga desigual (pero nuestra carga es uniforme)

**Desventajas:**
- Mayor overhead: Necesita sincronización en work-stealing
- Peor localidad: Threads pueden acceder a datos intercalados
- False sharing: Cache lines pueden compartirse entre threads
- Más lento en este caso específico

---

### Opción 3: Guided Scheduling (Análisis teórico)

```c
#pragma omp parallel for schedule(guided) \
    shared(current, next, width) default(none)
```

**Características:**
- Comienza con chunks grandes, decrece dinámicamente
- Compromiso entre static y dynamic

**Para CA:**
- Overhead intermedio
- Innecesario (nuestra carga es predecible)

---

## 3. Análisis de Clauses de Sincronización

### Clause: `shared(current, next, width)`

**Definición Explícita:**
```c
#pragma omp parallel for shared(current, next, width)
```

**Análisis:**
- `current`: Array read-only, seguro compartir entre threads
- `next`: Cada thread escribe a índices diferentes (no overlap)
- `width`: Constante durante la iteración, seguro compartir

**Alternativa - Implícita (evitada):**
```c
#pragma omp parallel for  // Sin explicitar shared
```
Menos seguro y difícil de verificar.

---

### Clause: `default(none)`

**Definición:**
```c
#pragma omp parallel for default(none)
```

**Beneficio:**
- Obliga a declarar explícitamente la visibilidad de cada variable
- Previene errores accidentales de compartición de variables privadas
- Mejora legibilidad y mantenibilidad

**Variables Automáticamente Privadas:**
```c
int i;        // Loop variable - privada automáticamente
```

---

## 4. Otras Consideraciones de Paralelización

### Operación de Conteo (Función no usada actualmente)

```c
#pragma omp parallel for \
    reduction(+:count) \
    schedule(static)
for (int i = 0; i < width; i++) {
    if (grid[i]) count++;
}
```

**Análisis:**
- `reduction(+:count)`: Reduce el contador de todos los threads
- Cada thread tiene su `count` privada inicializada a 0
- Al final, suma todas las copias privadas

---

### Barrera Implícita

```c
#pragma omp parallel for
for (...) { ... }
// BARRERA IMPLÍCITA AQUÍ - Todos los threads se sincronizan
```

**Importancia:**
- Garantiza que todos los threads terminan antes de continuar
- Esencial para mantener corrección entre generaciones
- Se puede eliminar con `nowait` si es apropiado

```c
#pragma omp parallel for nowait  // Sin barrera (INCORRECTO para CA)
```

---

## 5. Análisis de Escalabilidad

### Ley de Amdahl

```
Speedup = 1 / (f_serial + (1 - f_serial) / p)
```

Donde:
- `f_serial` = fracción del código no paralelizable
- `p` = número de procesadores

**Para nuestro CA:**
- Operaciones seriales: inicialización, intercambio de punteros (~1-2% del tiempo)
- Operaciones paralelas: cálculo de generaciones (~98-99%)
- Predicción: Speedup cercano a lineal para números razonables de threads

---

### Ley de Gustafson

Para aplicaciones bien paralelizadas:
```
Speedup = p - (1 - 1/p) × f_serial ≈ p para f_serial pequeño
```

**Implicación:**
- Si aumentamos el tamaño del problema (más células), el speedup se acerca a lineal

---

## 6. Alternativas Consideradas

### Alternativa 1: Paralelización Bidimensional

Si el problema fuera 2D:
```c
#pragma omp parallel for collapse(2) schedule(static)
for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
        // 2D cellular automaton
    }
}
```

**Ventajas:** Más paralelismo disponible
**Para CA 1D:** No aplicable

---

### Alternativa 2: Task Parallelism

```c
#pragma omp parallel
{
    #pragma omp single
    for (int gen = 0; gen < generations; gen++) {
        #pragma omp task
        // Crear tarea para cada generación (incorrecto)
    }
}
```

**Problema:** Las generaciones son seriales, no independientes

---

### Alternativa 3: Paralelización con Caché Blocking

Para problemas más grandes:
```
Dividir la grilla en bloques
Procesar bloques completos en paralelo
Ventaja: Mejor utilización de L3 cache
```

**Para nuestro tamaño:** Innecesario (10K células cabe en L3)

---

## 7. Implementación Detallada

### Directiva OpenMP Utilizada

```c
#pragma omp parallel for \
    schedule(static) \
    shared(current, next, width) \
    default(none)
for (int i = 0; i < width; i++) {
    unsigned char left = current[(i - 1 + width) % width];
    unsigned char center = current[i];
    unsigned char right = current[(i + 1) % width];
    next[i] = apply_rule(left, center, right);
}
```

### Ventajas de esta Estrategia

1. ✅ **Simplicidad**: Directiva única y clara
2. ✅ **Corrección**: Sin race conditions
3. ✅ **Eficiencia**: Mínimo overhead
4. ✅ **Escalabilidad**: Rendimiento cercano a lineal
5. ✅ **Mantenibilidad**: Código legible y auditable

---

## 8. Comparación de Enfoques

| Aspecto | Static | Dynamic | Guided |
|--------|--------|---------|--------|
| Overhead | Muy bajo | Medio-Alto | Bajo |
| Localidad de Caché | Excelente | Pobre | Buena |
| Balanceo de Carga | Perfecto | Perfecto | Bueno |
| Para CA | ⭐⭐⭐ | ⭐ | ⭐⭐ |

---

## 9. Predicciones de Desempeño

Basado en el análisis:

**Para CPU quad-core (4 threads):**
```
Esperado: Speedup ≈ 3.5-3.8x (93-95% de eficiencia)
```

**Para CPU octa-core (8 threads):**
```
Esperado: Speedup ≈ 7.5-7.9x (93-99% de eficiencia)
```

**Limitaciones:**
- Memory bandwidth puede saturarse con muchos threads
- Overhead de OpenMP se amortiza bien para large `width`

---

## Referencias

- OpenMP Architecture Review Board. "OpenMP Application Programming Interface" (4.5)
- Mattson, T., Sanders, B., Massingill, B. "Patterns for Parallel Programming"

---

**Próximo paso:** Ver `PERFORMANCE_ANALYSIS.md` para los resultados esperados y análisis.
