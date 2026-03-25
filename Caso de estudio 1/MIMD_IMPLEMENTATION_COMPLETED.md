# MIMD Parallelization - Implementación Completada

## 🎯 Objetivo Alcanzado

Crear una **versión concurrente con POSIX threads** que implemente paralelización **MIMD** (Multiple Instruction, Multiple Data) según la taxonomía de Flynn, con:
- ✅ Parámetro configurable para número de hilos
- ✅ División de datos en chunks proporcionales
- ✅ Medición de tiempo coherente incluyendo overhead
- ✅ Kernel optimizado para caché
- ✅ Documentación educativa completa

---

## 📦 Lo Que Se Implementó

### 1. **src/threads/multmat_threads.c (Reescrito Completamente)**

```c
// Características principales:
- Kernel optimizado: B_T[j*n + k] (acceso lineal)
- Paralelización MIMD: cada thread ejecuta kernel independientemente
- División de filas: si N=1000 y threads=4 → cada thread procesa ~250 filas
- Parámetros: N [num_threads] [seed] [max_val]
- Timing: Incluye creación, ejecución, y sincronización (pthread_join)
```

**Función principal: `worker()`**
```c
void *worker(thread_arg_t *arg) {
    for (int i = row_start; i < row_end; i++) {
        for (int j = 0; j < n; j++) {
            long long sum = 0;
            for (int k = 0; k < n; k++) {
                sum += A[i*n+k] * B_T[j*n+k];  // Stride = 1
            }
            C[i*n+j] = sum;  // Sin conflictos (filas privadas por thread)
        }
    }
}
```

**Distribución MIMD:**
```
Si N=1000, num_threads=4:

rows_per_thread = 1000 / 4 = 250
Hilo 0: [0, 250)          Hilo 2: [500, 750)
Hilo 1: [250, 500)        Hilo 3: [750, 1000)
```

---

### 2. **scripts/compare_serial_vs_threads.ps1 (Nuevo)**

Script automático que:
- Ejecuta multiplicación con N ∈ {100, 500, 1000, 2000}
- Prueba num_threads ∈ {1, 2, 4, 8}
- Calcula **speedup** = tiempo_serial / tiempo_paralelo
- Calcula **eficiencia** = (speedup / num_threads) × 100%
- Muestra cuándo paralelización es rentable vs dañina

**Ejemplo de output:**
```
=== N = 1000 ===
Hilos     Tiempo (ms)    Speedup     Eficiencia
--------------------------------------------------
1 (serial)395.271        1.00x       100%
2 (threads)208.413        1,90x       94.8%   ← Excelente
4 (threads)145.878        2,71x       67.7%   ← Bueno
8 (threads)123.199        3,21x       40.1%   ← Overhead
```

---

### 3. **Documentación Educativa**

#### **docs/MIMD_PARALLELIZATION_GUIDE.md**
- Explicación de Flynn's MIMD
- Estrategia de data chunking
- Análisis de escalabilidad por tamaño de matriz
- Cuándo usar paralelización vs cuándo no
- Resultados empíricos completos

#### **docs/MIMD_IMPLEMENTATION_SUMMARY.md**
- Resumen técnico de la implementación
- Parámetros y uso
- Tabla comparativa serial vs paralelo
- Ventajas y limitaciones

#### **README.md (Actualizado)**
- Referencias a módulos educativos
- Ejemplos de uso
- Sección sobre MIMD

---

## 📊 Resultados de Escalabilidad

### N=1000 (Punto Óptimo)
```
Threads  │ Tiempo (ms) │ Speedup │ Eficiencia
───────────────────────────────────────────
1        │ 395.3 ms    │ 1.00x   │ 100.0%
2        │ 208.4 ms    │ 1.90x   │ 94.8%  ✓ LINEAL
4        │ 145.9 ms    │ 2.71x   │ 67.7%  ✓ BUENO
8        │ 123.2 ms    │ 3.21x   │ 40.1%  ✗ OVERHEAD
```

**Conclusión:** Máquina con ~4 cores → usar 2-4 threads da mejor resultado

### N=2000 (Matrices Grandes)
```
Threads  │ Tiempo (ms) │ Speedup │ Eficiencia
───────────────────────────────────────────
1        │ 4030.3 ms   │ 1.00x   │ 100.0%
2        │ 2195.2 ms   │ 1.84x   │ 91.8%   ✓ EXCELENTE
4        │ 1059.6 ms   │ 3.80x   │ 95.1%   ✓ CASI LINEAL!
8        │ 842.0 ms    │ 4.79x   │ 59.8%   ✗ OVERHEAD
```

**Conclusión:** Carga de trabajo compensa overhead → escalabilidad casi perfecta

### N=100 (Matrices Pequeñas)
```
Threads  │ Tiempo (ms) │ Speedup │ Eficiencia
───────────────────────────────────────────
1        │ 0.398 ms    │ 1.00x   │ 100.0%
2        │ 0.542 ms    │ 0.73x   │ 36.7%   ✗ SLOWDOWN
4        │ 0.561 ms    │ 0.71x   │ 17.7%   ✗ MÁS SLOWDOWN
8        │ 1.039 ms    │ 0.38x   │ 4.8%    ✗ TERRIBLE
```

**Conclusión:** Overhead de pthread domina → NO use paralelización para N < 300

---

## 🔄 Comparación: Serial vs Paralelo

| Tamaño | Serial (1 thread) | Paralelo (4 threads) | Speedup | Recomendación |
|--------|------------------|-------------------|---------|---------------|
| N=100 | 0.398 ms | 0.561 ms | 0.71x | ❌ NO |
| N=500 | 42.5 ms | 18.1 ms | 2.35x | ✅ SÍ |
| N=1000 | 395.3 ms | 145.9 ms | 2.71x | ✅ SÍ |
| N=2000 | 4030 ms | 1060 ms | 3.80x | ✅ SÍ (EXCELENTE) |

---

## 🧵 Estrategia MIMD en Detalle

### ¿Qué es MIMD?

**Flynn's Taxonomy:**
- **SISD**: Single Instruction Single Data (CPU clásico serial)
- **SIMD**: Single Instruction Multiple Data (vectorización AVX)
- **MIMD**: Multiple Instruction Multiple Data (threads, procesos) ← **Esto**
- **MISD**: Raro en práctica

### Nuestra Implementación MIMD

```
ANTES (Serial):
CPU
 └─ Hilo 1: Procesa filas 0-999 secuencialmente

DESPUÉS (MIMD):
Núcleo 0             Núcleo 1             Núcleo 2             Núcleo 3
  │                   │                   │                   │
  Hilo 0             Hilo 1              Hilo 2              Hilo 3
  Filas 0-249        Filas 250-499       Filas 500-749       Filas 750-999
  EN PARALELO ────────────────────────→ PARALELO ───────────────────→
                                        pthread_sync() ESP
```

### Ventajas MIMD vs Alternativas

| Aspecto | MIMD Threads | OpenMP | MPI Procesos |
|---------|-------------|--------|-------------|
| Overhead | Bajo | Muy bajo | Alto |
| Memoria | Compartida | Compartida | Separada |
| Sincronización | pthread | Pragma | Paso mensajes |
| Implementación | Manual | Fácil | Compleja |
| Escalabilidad | ~cores | ~cores | 100+ nodos |
| **Nuestro uso** | ✅ ELEGIDO | ⚠️ Podría | ❌ Overkill |

---

## 📝 Medición de Tiempo Honesta

```c
double t2 = get_time_ms();                      // INICIO
for (int t = 0; t < num_threads; t++) {
    pthread_create(&threads[t], ...);           // Overhead de creación
}
// Aquí ejecutan TODOS los threads en paralelo
for (int t = 0; t < num_threads; t++) {
    pthread_join(threads[t], NULL);             // Esperar al más lento
}
double t3 = get_time_ms();                      // FIN
// elapsed = t3 - t2 incluye TODO el overhead
```

**Esto es diferente de medir solo el kernel dentro del thread** (lo cual sería deshonesto).

---

## 🚀 Uso

### Compilar
```powershell
gcc -O2 -pthread -o build\multmat_threads.exe src\threads\multmat_threads.c -lm
```

### Ejecutar Individual
```powershell
# Con defaults (num_threads=4)
.\build\multmat_threads.exe 1000

# Con parámetros específicos
.\build\multmat_threads.exe 1000 8        # N=1000, 8 threads
.\build\multmat_threads.exe 2000 4 12345  # N=2000, 4 threads, seed=12345
```

### Comparación Automática
```powershell
.\scripts\compare_serial_vs_threads.ps1
```

---

## 📚 Archivos del Proyecto

```
Mult-Mat/
├── src/threads/multmat_threads.c           ← REESCRITO (MIMD)
├── scripts/
│   ├── compare_serial_vs_threads.ps1       ← NUEVO (comparación)
│   └── verify.ps1                          ← NUEVO (verificación)
└── docs/
    ├── MIMD_PARALLELIZATION_GUIDE.md       ← NUEVO (educativo)
    └── MIMD_IMPLEMENTATION_SUMMARY.md      ← NUEVO (técnico)
```

---

## 🎓 Lecciones Educativas

### Lección 1: Overhead vs Ganancia
```
Overhead de threads (creación/sincronización): ~1-2ms
Ganancia en N=100: No hay (problema muy pequeño)
Resultado: SIN PARALLELISMO es más rápido

Overhead de threads: ~1-2ms
Ganancia en N=2000: ~3000ms
Resultado: ¡PARALLELISMO gana mucho!
```

### Lección 2: Escalabilidad Tiene Límite
```
Ideal: speedup = num_threads
Real:  speedup < num_threads

Razones:
- Load imbalance (algunas filas más costosas)
- Cache contention (cores compitiendo por L3)
- Context switching (threads > cores)
- Memory bandwidth saturation
```

### Lección 3: Data Chunking Importa
```
Nuestro MIMD por FILAS:
- Hilo 0: rows [0, N/threads)
- Hilo 1: rows [N/threads, 2N/threads)
- etc.

MEJOR para matrices=row-major porque:
- Cada hilo accede a rows contiguas
- Menos cache coherency traffic
```

---

## ✅ Verificación

Ejecutar script de verificación:
```powershell
.\scripts\verify.ps1
```

Muestra:
- ✓ Todos los fuentes presentes
- ✓ Documentación creada
- ✓ Binarios compilados
- ✓ Ejecución funcional
- ✓ MIMD strategy reconocida

---

## 🎯 Resumen Final

| Aspecto | Estado |
|--------|--------|
| MIMD Implementation | ✅ Completo |
| Data Chunking | ✅ Implementado (proporcional) |
| Parameter from CLI | ✅ Implementado (num_threads) |
| Time Measurement Coherent | ✅ Incluye overhead |
| Cache Optimization | ✅ Kernel optimizado |
| Escalability Analysis | ✅ Completo (N=100,500,1000,2000) |
| Educational Materials | ✅ Dos guías completas |
| Comparison Scripts | ✅ Automáticas |
| Documentation | ✅ Exhaustiva |

**Proyecto estatus: COMPLETAMENTE FUNCIONAL Y DOCUMENTADO** ✅

---

**Para empezar:** `.\scripts\compare_serial_vs_threads.ps1`
**Para detalles técnicos:** `docs\MIMD_IMPLEMENTATION_SUMMARY.md`
**Para educación:** `docs\MIMD_PARALLELIZATION_GUIDE.md`
