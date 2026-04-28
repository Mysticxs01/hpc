#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <limits.h>

#include <omp.h>

#ifdef _WIN32
#include <windows.h>
static double get_time_ms(void) {
    LARGE_INTEGER freq, count;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&count);
    return (double)count.QuadPart / (double)freq.QuadPart * 1000.0;
}
#else
static double get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}
#endif

static int parse_int(const char *s, int *out) {
    errno = 0;
    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0') return 0;
    if (v < INT_MIN || v > INT_MAX) return 0;
    *out = (int)v;
    return 1;
}

static int *alloc_matrix(int n) {
    return (int *)malloc((size_t)n * (size_t)n * sizeof(int));
}

static long long *alloc_result(int n) {
    return (long long *)malloc((size_t)n * (size_t)n * sizeof(long long));
}

static void fill_random(int *m, int n, int max_val) {
    for (int i = 0; i < n * n; i++) {
        m[i] = rand() % (max_val + 1);
    }
}

static void transpose(const int *B, int *B_T, int n) {
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            B_T[j * n + i] = B[i * n + j];
        }
    }
}

static void multiply_omp(const int *A, const int *B_T, long long *C, int n, int num_threads) {
    #pragma omp parallel for schedule(static) num_threads(num_threads)
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            long long sum = 0;
            for (int k = 0; k < n; k++) {
                sum += (long long)A[i * n + k] * (long long)B_T[j * n + k];
            }
            C[i * n + j] = sum;
        }
    }
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <N> [threads] [seed] [max_val]\n", argv[0]);
        return 1;
    }

    int n = 0;
    if (!parse_int(argv[1], &n) || n <= 0) {
        fprintf(stderr, "Error: N debe ser un entero > 0.\n");
        return 1;
    }

    int num_threads = 4;
    int seed = (int)time(NULL);
    int max_val = 9;
    if (argc >= 3 && !parse_int(argv[2], &num_threads)) {
        fprintf(stderr, "Error: threads invalido.\n");
        return 1;
    }
    if (argc >= 4 && !parse_int(argv[3], &seed)) {
        fprintf(stderr, "Error: seed invalida.\n");
        return 1;
    }
    if (argc >= 5 && (!parse_int(argv[4], &max_val) || max_val < 0)) {
        fprintf(stderr, "Error: max_val invalido.\n");
        return 1;
    }
    if (num_threads <= 0) {
        fprintf(stderr, "Error: threads debe ser > 0.\n");
        return 1;
    }

    srand((unsigned)seed);

    int *A = alloc_matrix(n);
    int *B = alloc_matrix(n);
    int *B_T = alloc_matrix(n);
    long long *C = alloc_result(n);
    if (!A || !B || !B_T || !C) {
        fprintf(stderr, "Error: no se pudo asignar memoria para %dx%d.\n", n, n);
        free(A);
        free(B);
        free(B_T);
        free(C);
        return 1;
    }

    double t0 = get_time_ms();
    fill_random(A, n, max_val);
    fill_random(B, n, max_val);
    double t1 = get_time_ms();

    double t2 = get_time_ms();
    transpose(B, B_T, n);
    multiply_omp(A, B_T, C, n, num_threads);
    double t3 = get_time_ms();

    printf("=== Multiplicacion OpenMP de Matrices %dx%d ===\n", n, n);
    printf("Hilos:                    %10d\n", num_threads);
    printf("Tiempo de llenado:        %10.3f ms\n", t1 - t0);
    printf("Tiempo de multiplicacion: %10.3f ms\n", t3 - t2);
    printf("Tiempo total:             %10.3f ms\n", (t1 - t0) + (t3 - t2));

    free(A);
    free(B);
    free(B_T);
    free(C);
    return 0;
}