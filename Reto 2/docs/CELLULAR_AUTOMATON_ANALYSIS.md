# Análisis de Cellular Automaton (CA)

## 1. Introducción a los Autómatas Celulares

Un **Autómata Celular** es un modelo computacional discreto, estudiad o en computabilidad, matemáticas y física teórica. Se compone de:

- **Grilla (Grid)**: Una malla regular (usualmente unidimensional o bidimensional) dividida en células
- **Estados**: Cada célula puede estar en uno de varios estados (típicamente binario: vivo/muerto)
- **Vecindario (Neighborhood)**: Conjunto de células que influyen en el estado futuro de una célula
- **Función de Transición**: Regla que determina el estado futuro basado en los estados actuales de la célula y sus vecinos

### Características Fundamentales

1. **Discretización**: Tanto el espacio como el tiempo son discretos
2. **Determinismo**: La evolución es completamente determinista (dada una configuración inicial)
3. **Sincronismo**: Todas las células evolucionan simultáneamente
4. **Localidad**: El nuevo estado depende solo del estado local (célula y vecinos)

## 2. Implementación: Regla 110 de Wolfram

### Descripción de la Regla 110

La **Regla 110** es una de las más conocidas por Stephen Wolfram. Es un autómata celular elemental (1D) donde:

- Cada célula observa su vecindario: (izquierda, centro, derecha)
- Basado en estos 3 bits (8 posibles configuraciones), determina el nuevo estado
- La regla se define mediante 8 bits que codifican el mapeo para cada configuración

### Mapeo de la Regla 110

```
Configuración (LCR) → Nuevo Estado
111              → 0
110              → 1
101              → 1
100              → 0
011              → 1
010              → 1
001              → 1
000              → 0
```

Representación binaria: `01101110` = 110 en decimal

### Pseudocódigo del Algoritmo Serial

```
Inicializar grilla con condición inicial (célula central activa)
Para cada generación:
    Para cada célula i en la grilla:
        left ← grilla[i-1]  (con condición periódica)
        center ← grilla[i]
        right ← grilla[i+1] (con condición periódica)
        neighborhood ← (left << 2) | (center << 1) | right
        grilla_nueva[i] ← (regla >> neighborhood) & 1
    Intercambiar grilla_actual con grilla_nueva
```

## 3. Complejidad Computacional

### Análisis de Complejidad

- **Espacio**: O(W) donde W es el ancho de la grilla
- **Tiempo**: O(W × G) donde:
  - W = ancho de la grilla
  - G = número de generaciones
  - Cada generación requiere revisar todas las W células

### Operaciones por Iteración

Por cada generación y cada célula se realiza:
1. Lectura de 3 valores (izquierda, centro, derecha)
2. Una operación bit-shift
3. Una operación AND
4. Una operación bit-shift (para la regla)
5. Una operación AND
6. Una escritura

Total: ~6 operaciones simples por célula

## 4. Características de Memoria

### Patrones de Acceso

```
Lectura:
  current[i-1]  → Acceso secuencial con retraso de 1 (buena localidad)
  current[i]    → Acceso secuencial
  current[i+1]  → Acceso secuencial adelantado 1

Escritura:
  next[i]       → Acceso secuencial (buena localidad de escritura)
```

### Localidad Espacial

- **Excelente localidad temporal**: Los mismos datos se leen múltiples veces
- **Excelente localidad espacial**: Los accesos son completamente secuenciales
- **Predecible**: Los patrones de acceso son perfectamente predecibles (beneficia prefetching)

### Utilización de Caché

- El working set es pequeño (todas las células caben fácilmente en L1/L2)
- Los mismos datos se reutilizan en cada generación
- Excelente candidato para optimización de caché

## 5. Configuración Inicial

En la implementación actual:
```
Grilla: [0, 0, ..., 0, 1, 0, ..., 0, 0]
          ← W/2 - 1 → ↑ → ← W/2 + 1 →
                     célula central
```

Esta configuración simple (single seed) es interesante porque:
- Produce patrones complejos que evolucionan desde un punto inicial
- Es determinista y reproducible
- Permite observar la propagación de información

## 6. Condiciones de Frontera

Se utilizan **condiciones periódicas** (toroidal):
```
current[(i - 1 + width) % width]  // Vecino izquierdo con wrap-around
current[(i + 1) % width]           // Vecino derecho con wrap-around
```

Ventajas:
- No hay efectos de borde
- Mantiene la simetría
- Más realista para sistemas cíclicos

## 7. Datos Esperados de Comportamiento

La Regla 110 es **conocida por ser Turing-completa**, lo que significa:
- Puede simular cualquier máquina de Turing
- Produce patrones complejos y no triviales
- Combina estructuras estables, periódicas y caóticas

### Comportamiento Esperado

Después de las primeras generaciones, típicamente se observan:
1. **Estructuras estables**: Patrones que no cambian
2. **Estructuras periódicas**: Patrones que se repiten
3. **Estructuras móviles**: Patrones que se propagan a través de la grilla
4. **Patrones caóticos**: Regiones de aparente aleatoriedad

## 8. Métricas de Desempeño

### Throughput

```
Throughput = (width × generations) / tiempo_total [células/segundo]
```

Para nuestras implementaciones:
- Benchmark: 10,000 células × 1,000 generaciones = 10 millones de células

### Speedup

```
Speedup = Tiempo_Serial / Tiempo_Paralelo
```

Speedup ideal (lineal): Threads disponibles

### Eficiencia

```
Eficiencia = Speedup / Threads
```

Rango: 0 a 1, donde 1 es óptimo

## 9. Oportunidades de Optimización

### A Nivel de CPU

1. **Unrolling de loops**: Procesar múltiples células por iteración
2. **SIMD (SSE/AVX)**: Paralelización a nivel de instrucción
3. **Caché blocking**: Organizar datos para máxima localidad
4. **Prefetching manual**: Indicar al CPU qué datos prefetcher

### A Nivel de Memoria

1. **Alineación de datos**: Asegurar datos alineados a 64 bytes (línea de caché)
2. **Páginas enormes (Huge Pages)**: Reducir misses de TLB
3. **NUMA awareness**: Considerar localidad NUMA en sistemas multi-socket
4. **Pool de memoria**: Preasignar y reutilizar memoria

### A Nivel de Compilador

1. **Optimización -O3**: Habilitación completa de optimizaciones
2. **Vectorización automática**: Permitir al compilador vectorizar loops
3. **Inline**: Funciones pequeñas inlining automático
4. **Profile-guided optimization (PGO)**: Optimización basada en profiling

## 10. Referencias

- Wolfram, S. "A New Kind of Science" (2002)
- Rule 110 Cellular Automaton: https://mathworld.wolfram.com/Rule110.html
- Cook, M. (2004). "Universality in Elementary Cellular Automata"

---

**Nota**: Este documento proporciona el contexto teórico para el Reto 2. Para detalles de implementación, ver `PARALLELIZATION_ANALYSIS.md` y `PERFORMANCE_ANALYSIS.md`.
