/*
 * Cellular Automaton - OpenMP Parallelized Implementation
 * 
 * Implementación paralelizada con OpenMP del algoritmo de Autómata Celular
 * Utiliza la regla 110 de Wolfram como ejemplo
 * 
 * Compilación: gcc -O3 -fopenmp -o cellular_automaton_openmp cellular_automaton_openmp.c -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <omp.h>

#define GRID_WIDTH 10000
#define NUM_GENERATIONS 1000
#define NUM_RUNS 10

/* Estructura para almacenar estadísticas de tiempo */
typedef struct {
    double initialization_time;
    double computation_time;
    double total_time;
} TimingStats;

/* 
 * Función: apply_rule
 * Aplica la regla del autómata celular (Regla 110 de Wolfram)
 * 
 * La regla 110 funciona de la siguiente manera:
 * - Observa el estado actual de una célula y sus dos vecinos
 * - Basado en estos 3 bits, determina el nuevo estado
 * 
 * Regla 110 en binario: 01101110
 * Mapeo de entradas (111->0, 110->1, 101->1, 100->0, 011->1, 010->1, 001->1, 000->0)
 */
unsigned char apply_rule(unsigned char left, unsigned char center, unsigned char right) {
    unsigned char neighborhood = (left << 2) | (center << 1) | right;
    unsigned char rule = 110;  /* Regla 110 de Wolfram */
    
    return (rule >> neighborhood) & 1;
}

/*
 * Función: initialize_grid
 * Inicializa la grilla del autómata celular
 * Establece una configuración inicial (célula central activada)
 */
void initialize_grid(unsigned char* grid, int width) {
    memset(grid, 0, width * sizeof(unsigned char));
    grid[width / 2] = 1;  /* Célula central activada */
}

/*
 * Función: compute_generation_omp
 * Calcula la siguiente generación del autómata celular con OpenMP
 * Aplica condiciones de frontera periódicas (toroidal)
 * 
 * Estrategia de Paralelización:
 * - Se paraleliza el loop principal sobre cada célula
 * - Cada thread procesa múltiples células independientemente
 * - Uso de schedule(static) para mejor localidad de datos
 * - Barrera implícita al final del pragma omp parallel for
 */
void compute_generation_omp(unsigned char* current, unsigned char* next, int width) {
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
}

/*
 * Función: count_alive_cells_omp
 * Cuenta el número de células vivas en una generación (versión paralela)
 */
long count_alive_cells_omp(unsigned char* grid, int width) {
    long count = 0;
    
    #pragma omp parallel for \
        reduction(+:count) \
        schedule(static)
    for (int i = 0; i < width; i++) {
        if (grid[i]) count++;
    }
    
    return count;
}

/*
 * Función: simulate_omp
 * Ejecuta la simulación del autómata celular con paralelización OpenMP
 */
TimingStats simulate_omp(unsigned char* grid, int width, int generations) {
    TimingStats stats = {0, 0, 0};
    
    unsigned char* current = grid;
    unsigned char* next = (unsigned char*)malloc(width * sizeof(unsigned char));
    
    if (!next) {
        fprintf(stderr, "Error: No se pudo asignar memoria para 'next'\n");
        stats.total_time = -1;
        return stats;
    }
    
    double start_init = omp_get_wtime();
    initialize_grid(current, width);
    stats.initialization_time = omp_get_wtime() - start_init;
    
    double start_compute = omp_get_wtime();
    for (int gen = 0; gen < generations; gen++) {
        compute_generation_omp(current, next, width);
        
        /* Intercambiar punteros para siguiente iteración */
        unsigned char* temp = current;
        current = next;
        next = temp;
    }
    stats.computation_time = omp_get_wtime() - start_compute;
    stats.total_time = stats.initialization_time + stats.computation_time;
    
    free(next);
    return stats;
}

/*
 * Función: main
 * Punto de entrada del programa
 */
int main(int argc, char* argv[]) {
    int width = GRID_WIDTH;
    int generations = NUM_GENERATIONS;
    int num_runs = NUM_RUNS;
    int num_threads = omp_get_max_threads();
    
    /* Parsear argumentos de línea de comandos */
    if (argc > 1) width = atoi(argv[1]);
    if (argc > 2) generations = atoi(argv[2]);
    if (argc > 3) num_runs = atoi(argv[3]);
    if (argc > 4) num_threads = atoi(argv[4]);
    
    omp_set_num_threads(num_threads);
    
    printf("=== Cellular Automaton (OpenMP Parallelized) ===\n");
    printf("Grid Width: %d\n", width);
    printf("Generations: %d\n", generations);
    printf("Number of Runs: %d\n", num_runs);
    printf("Number of Threads: %d\n", num_threads);
    printf("=================================================\n\n");
    
    /* Allocar memoria para la grilla */
    unsigned char* grid = (unsigned char*)malloc(width * sizeof(unsigned char));
    if (!grid) {
        fprintf(stderr, "Error: No se pudo asignar memoria para la grilla\n");
        return 1;
    }
    
    /* Ejecutar múltiples runs para obtener estadísticas */
    TimingStats* all_stats = (TimingStats*)malloc(num_runs * sizeof(TimingStats));
    if (!all_stats) {
        fprintf(stderr, "Error: No se pudo asignar memoria para estadísticas\n");
        free(grid);
        return 1;
    }
    
    double total_time_all_runs = 0;
    
    for (int run = 0; run < num_runs; run++) {
        printf("Run %d/%d... ", run + 1, num_runs);
        fflush(stdout);
        
        all_stats[run] = simulate_omp(grid, width, generations);
        total_time_all_runs += all_stats[run].total_time;
        
        printf("Done (%.4f s)\n", all_stats[run].total_time);
    }
    
    /* Calcular estadísticas */
    double avg_time = total_time_all_runs / num_runs;
    double min_time = all_stats[0].total_time;
    double max_time = all_stats[0].total_time;
    
    for (int i = 1; i < num_runs; i++) {
        if (all_stats[i].total_time < min_time) min_time = all_stats[i].total_time;
        if (all_stats[i].total_time > max_time) max_time = all_stats[i].total_time;
    }
    
    /* Imprimir resultados */
    printf("\n=== Results ===\n");
    printf("Average Time: %.6f s\n", avg_time);
    printf("Min Time: %.6f s\n", min_time);
    printf("Max Time: %.6f s\n", max_time);
    printf("Total Time (All Runs): %.6f s\n", total_time_all_runs);
    
    /* Calcular throughput */
    long total_cells = (long)width * generations;
    double throughput = total_cells / (avg_time * 1e9);
    printf("Throughput: %.4f B cells/s\n", throughput);
    
    /* Libertar memoria */
    free(grid);
    free(all_stats);
    
    return 0;
}
