#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <limits.h>

static void usage(const char *prog) {
    fprintf(stderr, "Uso: %s <N> [seed] [max_val]\n", prog);
    fprintf(stderr, "  N       : tamaño de la matriz (entero > 0)\n");
    fprintf(stderr, "  seed    : (opcional) semilla para aleatorios (default: time(NULL))\n");
    fprintf(stderr, "  max_val : (opcional) valores en rango [0, max_val] (default: 9)\n");
}

static int parse_int(const char *s, int *out) {
    errno = 0;
    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0') return 0;
    if (v < INT_MIN || v > INT_MAX) return 0;
    *out = (int)v;
    return 1;
}

static int* alloc_matrix(int n) {
    size_t count = (size_t)n * (size_t)n;
    int *m = (int*)malloc(count * sizeof(int));
    return m;
}

static void fill_random(int *m, int n, int max_val) {
    for (int i = 0; i < n * n; i++) {
        m[i] = rand() % (max_val + 1); // [0..max_val]
    }
}

static void multiply(const int *A, const int *B, long long *C, int n) {
    // C = A * B^T (B ya se considera transpuesta para acceso fila x fila).
    // Usamos long long para reducir riesgo de overflow al acumular.
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            long long sum = 0;
            for (int k = 0; k < n; k++) {
                sum += (long long)A[i*n + k] * (long long)B[j*n + k];
            }
            C[i*n + j] = sum;
        }
    }
}

static void print_matrix_int(const int *m, int n, const char *name) {
    printf("%s:\n", name);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            printf("%4d ", m[i*n + j]);
        }
        printf("\n");
    }
    printf("\n");
}

static void print_matrix_ll(const long long *m, int n, const char *name) {
    printf("%s:\n", name);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            printf("%6lld ", m[i*n + j]);
        }
        printf("\n");
    }
    printf("\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
        usage(argv[0]);
        return 1;
    }

    int n = 0;
    if (!parse_int(argv[1], &n) || n <= 0) {
        fprintf(stderr, "Error: N debe ser un entero > 0.\n");
        usage(argv[0]);
        return 1;
    }

    int seed = (int)time(NULL);
    int max_val = 9;

    if (argc >= 3) {
        if (!parse_int(argv[2], &seed)) {
            fprintf(stderr, "Error: seed inválida.\n");
            usage(argv[0]);
            return 1;
        }
    }
    if (argc >= 4) {
        if (!parse_int(argv[3], &max_val) || max_val < 0) {
            fprintf(stderr, "Error: max_val inválido (debe ser >= 0).\n");
            usage(argv[0]);
            return 1;
        }
    }

    srand((unsigned)seed);

    int *A = alloc_matrix(n);
    int *B = alloc_matrix(n);
    long long *C = (long long*)malloc((size_t)n * (size_t)n * sizeof(long long));

    if (!A || !B || !C) {
        fprintf(stderr, "Error: no se pudo asignar memoria para matrices de %dx%d.\n", n, n);
        free(A); free(B); free(C);
        return 1;
    }

    fill_random(A, n, max_val);
    fill_random(B, n, max_val);

    multiply(A, B, C, n);

    free(A);
    free(B);
    free(C);
    return 0;
}