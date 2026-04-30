# Reto 2: Cellular Automaton - Análisis, Implementación y Paralelización con OpenMP

## Objetivos

1. **Análisis de Cellular Automaton**: Comprender el algoritmo y su comportamiento dinámico
2. **Implementación Serial**: Desarrollar versión secuencial del algoritmo
3. **Análisis de Paralelización**: Estudiar opciones de paralelización con OpenMP
4. **Optimización y Profiling**: Realizar análisis de desempeño a nivel de CPU y memoria

## Requisitos de Tiempo
- Dedicación estimada: **8 horas totales**
- Inclusión de profiling y optimización a nivel de CPU y memoria

## Estructura del Proyecto

```
Reto 2/
├── src/
│   ├── serial/
│   │   └── cellular_automaton_serial.c      # Versión secuencial del algoritmo
│   └── openmp/
│       └── cellular_automaton_openmp.c      # Versión paralelizada con OpenMP
├── scripts/
│   ├── build.ps1                            # Compilación
│   ├── run_serial.ps1                       # Ejecución versión serial
│   ├── run_openmp.ps1                       # Ejecución versión OpenMP
│   ├── profile.ps1                          # Profiling de desempeño
│   └── benchmark.ps1                        # Benchmarking comparativo
├── docs/
│   ├── CELLULAR_AUTOMATON_ANALYSIS.md       # Análisis del algoritmo CA
│   ├── PARALLELIZATION_ANALYSIS.md          # Análisis de opciones de paralelización
│   ├── PERFORMANCE_ANALYSIS.md              # Análisis de resultados y optimización
│   └── profile_summary.csv                  # Resultados del profiling
├── build/
│   ├── cellular_automaton_serial            # Ejecutable versión serial
│   └── cellular_automaton_openmp            # Ejecutable versión OpenMP
└── benchmark_output.txt                     # Resultados de benchmarking

```

## Fases de Desarrollo

### Fase 1: Análisis
- Revisar documentación de Cellular Automaton
- Comprender patrones y reglas de evolución
- Identificar características del algoritmo

### Fase 2: Implementación Serial
- Implementar versión secuencial
- Validar correctitud del algoritmo
- Establecer baseline de desempeño

### Fase 3: Análisis de Paralelización
- Identificar dependencias de datos
- Evaluar estrategias de paralelización con OpenMP
- Determinar mejores opciones de distribución

### Fase 4: Implementación Paralelizada
- Implementar versión con OpenMP
- Comparar desempeño con serial
- Realizar optimización de CPU y memoria

## Cómo Usar

### En Linux/macOS (Recomendado)

```bash
# Compilar
./scripts/build.sh

# Ejecutar Versión Serial
./scripts/run_serial.sh

# Ejecutar Versión OpenMP (con threads automáticos)
./scripts/run_openmp.sh

# Realizar Profiling con múltiples configuraciones
./scripts/profile.sh

# Ejecutar Benchmarking completo
./scripts/benchmark.sh
```

### En Windows (PowerShell)

```powershell
# Compilar
./scripts/build.ps1

# Ejecutar Versión Serial
./scripts/run_serial.ps1

# Ejecutar Versión OpenMP
./scripts/run_openmp.ps1

# Realizar Profiling
./scripts/profile.ps1

# Ejecutar Benchmarking
./scripts/benchmark.ps1
```

### Personalizar Ejecución

```bash
# Cambiar tamaño de grilla y generaciones
./scripts/run_serial.sh 20000 2000 10

# Especificar número de threads
./scripts/run_openmp.sh 10000 1000 10 4

# Profiling con parámetros personalizados
./scripts/profile.sh 10000 1000 5
```

## Documentación

- **[CELLULAR_AUTOMATON_ANALYSIS.md](docs/CELLULAR_AUTOMATON_ANALYSIS.md)**: Análisis detallado del algoritmo
- **[PARALLELIZATION_ANALYSIS.md](docs/PARALLELIZATION_ANALYSIS.md)**: Opciones y análisis de paralelización
- **[PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)**: Análisis teórico de desempeño
- **[OPTIMIZATION_RECOMMENDATIONS.md](docs/OPTIMIZATION_RECOMMENDATIONS.md)**: Sugerencias prácticas de optimización

## Resultados Obtenidos

- **[RESULTS_ANALYSIS.md](RESULTS_ANALYSIS.md)**: Análisis completo de benchmarking y profiling
- **benchmark_output.txt**: Resultados de ejecución comparativa
- **profile_output.txt**: Profiling detallado con múltiples configuraciones

## Resultados Esperados

Al finalizar el reto, se esperan:
1. Implementación funcional del algoritmo CA en versión serial y paralelizada
2. Análisis comparativo de desempeño
3. Identificación de patrones de escalabilidad
4. Documentación de optimizaciones aplicadas a CPU y memoria
5. Conclusiones sobre la efectividad de la paralelización
