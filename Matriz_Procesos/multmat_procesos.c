#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <limits.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>

static double get_time_ms(void) {
    LARGE_INTEGER freq, count;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&count);
    return (double)count.QuadPart / (double)freq.QuadPart * 1000.0;
}

/*
 * Estrategia en Windows:
 *   - El proceso padre crea un archivo mapeado en memoria (shared memory)
 *     que contiene A, B y C.
 *   - Lanza N procesos hijo pasandoles el nombre del mapping,
 *     el tamanio de la matriz, y el rango de filas a calcular.
 *   - Cada hijo abre el mapping, calcula sus filas de C, y termina.
 *   - El padre espera a todos los hijos y lee C.
 */

#define SHM_NAME_PREFIX "MultMatShm_"

/* Estructura que se coloca al inicio de la memoria compartida */
typedef struct {
    int n;
    int max_val;
    /* Seguido de: int A[n*n], int B[n*n], long long C[n*n] */
} shm_header_t;

static size_t shm_total_size(int n) {
    return sizeof(shm_header_t)
         + (size_t)n * n * sizeof(int)       /* A */
         + (size_t)n * n * sizeof(int)       /* B */
         + (size_t)n * n * sizeof(long long); /* C */
}

static int* shm_A(void *base, int n) {
    (void)n;
    return (int*)((char*)base + sizeof(shm_header_t));
}
static int* shm_B(void *base, int n) {
    return (int*)((char*)base + sizeof(shm_header_t) + (size_t)n * n * sizeof(int));
}
static long long* shm_C(void *base, int n) {
    return (long long*)((char*)base + sizeof(shm_header_t)
           + (size_t)n * n * sizeof(int)
           + (size_t)n * n * sizeof(int));
}

static void fill_random(int *m, int n, int max_val) {
    for (int i = 0; i < n * n; i++) {
        m[i] = rand() % (max_val + 1);
    }
}

static void multiply_rows(const int *A, const int *B, long long *C,
                           int n, int row_start, int row_end) {
    for (int i = row_start; i < row_end; i++) {
        for (int j = 0; j < n; j++) {
            long long sum = 0;
            for (int k = 0; k < n; k++) {
                sum += (long long)A[i*n + k] * (long long)B[j*n + k];
            }
            C[i*n + j] = sum;
        }
    }
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

static void usage(const char *prog) {
    fprintf(stderr, "Uso: %s <N> [num_procesos] [seed] [max_val]\n", prog);
    fprintf(stderr, "  N            : tamanio de la matriz (entero > 0)\n");
    fprintf(stderr, "  num_procesos : (opcional) numero de procesos hijo (default: 4)\n");
    fprintf(stderr, "  seed         : (opcional) semilla para aleatorios (default: time(NULL))\n");
    fprintf(stderr, "  max_val      : (opcional) valores en rango [0, max_val] (default: 9)\n");
}

/* ---- Modo hijo: recibe  --child <shm_name> <row_start> <row_end> ---- */
static int child_main(const char *shm_name, int row_start, int row_end) {
    HANDLE hMap = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, shm_name);
    if (!hMap) {
        fprintf(stderr, "Hijo: no se pudo abrir el mapping '%s' (err=%lu).\n",
                shm_name, GetLastError());
        return 1;
    }

    /* Necesitamos saber n para calcular el tamanio; lo leemos del header primero */
    shm_header_t *hdr = (shm_header_t*)MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(shm_header_t));
    if (!hdr) {
        fprintf(stderr, "Hijo: MapViewOfFile header fallo (err=%lu).\n", GetLastError());
        CloseHandle(hMap);
        return 1;
    }
    int n = hdr->n;
    UnmapViewOfFile(hdr);

    size_t total = shm_total_size(n);
    void *base = MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, total);
    if (!base) {
        fprintf(stderr, "Hijo: MapViewOfFile fallo (err=%lu).\n", GetLastError());
        CloseHandle(hMap);
        return 1;
    }

    int *A = shm_A(base, n);
    int *B = shm_B(base, n);
    long long *C = shm_C(base, n);

    multiply_rows(A, B, C, n, row_start, row_end);

    UnmapViewOfFile(base);
    CloseHandle(hMap);
    return 0;
}

int main(int argc, char **argv) {
    /* ---------- Modo hijo ---------- */
    if (argc >= 5 && strcmp(argv[1], "--child") == 0) {
        int rs, re;
        if (!parse_int(argv[3], &rs) || !parse_int(argv[4], &re)) {
            fprintf(stderr, "Hijo: argumentos invalidos.\n");
            return 1;
        }
        return child_main(argv[2], rs, re);
    }

    /* ---------- Modo padre ---------- */
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

    int num_procs = 4;
    int seed = (int)time(NULL);
    int max_val = 9;

    if (argc >= 3) {
        if (!parse_int(argv[2], &num_procs) || num_procs <= 0) {
            fprintf(stderr, "Error: num_procesos debe ser un entero > 0.\n");
            usage(argv[0]);
            return 1;
        }
    }
    if (argc >= 4) {
        if (!parse_int(argv[3], &seed)) {
            fprintf(stderr, "Error: seed invalida.\n");
            usage(argv[0]);
            return 1;
        }
    }
    if (argc >= 5) {
        if (!parse_int(argv[4], &max_val) || max_val < 0) {
            fprintf(stderr, "Error: max_val invalido (debe ser >= 0).\n");
            usage(argv[0]);
            return 1;
        }
    }

    if (num_procs > n) num_procs = n;

    srand((unsigned)seed);

    /* ---- Crear memoria compartida ---- */
    char shm_name[128];
    snprintf(shm_name, sizeof(shm_name), "%s%lu", SHM_NAME_PREFIX, (unsigned long)GetCurrentProcessId());

    size_t total = shm_total_size(n);
    HANDLE hMap = CreateFileMappingA(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
                                     (DWORD)(total >> 32), (DWORD)(total & 0xFFFFFFFF),
                                     shm_name);
    if (!hMap) {
        fprintf(stderr, "Error: CreateFileMapping fallo (err=%lu).\n", GetLastError());
        return 1;
    }

    void *base = MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, total);
    if (!base) {
        fprintf(stderr, "Error: MapViewOfFile fallo (err=%lu).\n", GetLastError());
        CloseHandle(hMap);
        return 1;
    }

    shm_header_t *hdr = (shm_header_t*)base;
    hdr->n = n;
    hdr->max_val = max_val;

    int *A  = shm_A(base, n);
    int *B  = shm_B(base, n);
    /* long long *C = shm_C(base, n);  -- lo leemos despues */

    /* ---------- Llenar matrices ---------- */
    double t0 = get_time_ms();
    fill_random(A, n, max_val);
    fill_random(B, n, max_val);
    double t1 = get_time_ms();

    /* ---------- Lanzar procesos hijo ---------- */
    HANDLE *procs = (HANDLE*)malloc(num_procs * sizeof(HANDLE));
    PROCESS_INFORMATION *pi = (PROCESS_INFORMATION*)malloc(num_procs * sizeof(PROCESS_INFORMATION));

    if (!procs || !pi) {
        fprintf(stderr, "Error: malloc fallo.\n");
        UnmapViewOfFile(base);
        CloseHandle(hMap);
        return 1;
    }

    /* Obtener ruta del ejecutable actual */
    char exe_path[MAX_PATH];
    GetModuleFileNameA(NULL, exe_path, MAX_PATH);

    int rows_per = n / num_procs;
    int extra    = n % num_procs;

    double t2 = get_time_ms();

    int current_row = 0;
    for (int p = 0; p < num_procs; p++) {
        int rstart = current_row;
        int rend   = current_row + rows_per + (p < extra ? 1 : 0);
        current_row = rend;

        char cmd[512];
        snprintf(cmd, sizeof(cmd), "\"%s\" --child %s %d %d", exe_path, shm_name, rstart, rend);

        STARTUPINFOA si;
        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        ZeroMemory(&pi[p], sizeof(pi[p]));

        if (!CreateProcessA(NULL, cmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi[p])) {
            fprintf(stderr, "Error: CreateProcess fallo para proceso %d (err=%lu).\n", p, GetLastError());
            /* Esperar los que ya se lanzaron */
            for (int q = 0; q < p; q++) {
                WaitForSingleObject(pi[q].hProcess, INFINITE);
                CloseHandle(pi[q].hProcess);
                CloseHandle(pi[q].hThread);
            }
            UnmapViewOfFile(base);
            CloseHandle(hMap);
            free(procs); free(pi);
            return 1;
        }
        procs[p] = pi[p].hProcess;
    }

    /* ---------- Esperar a todos los hijos ---------- */
    WaitForMultipleObjects(num_procs, procs, TRUE, INFINITE);

    double t3 = get_time_ms();

    for (int p = 0; p < num_procs; p++) {
        CloseHandle(pi[p].hProcess);
        CloseHandle(pi[p].hThread);
    }

    printf("=== Multiplicacion Paralela con Procesos %dx%d | %d procesos ===\n", n, n, num_procs);
    printf("Tiempo de llenado:        %10.3f ms\n", t1 - t0);
    printf("Tiempo de multiplicacion: %10.3f ms\n", t3 - t2);
    printf("Tiempo total:             %10.3f ms\n", (t1 - t0) + (t3 - t2));

    UnmapViewOfFile(base);
    CloseHandle(hMap);
    free(procs);
    free(pi);
    return 0;
}

#else /* ---- POSIX (Linux / macOS) ---- */

#include <sys/mman.h>
#include <sys/wait.h>
#include <unistd.h>

static double get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

static void fill_random(int *m, int n, int max_val) {
    for (int i = 0; i < n * n; i++) {
        m[i] = rand() % (max_val + 1);
    }
}

static void multiply_rows(const int *A, const int *B, long long *C,
                           int n, int row_start, int row_end) {
    for (int i = row_start; i < row_end; i++) {
        for (int j = 0; j < n; j++) {
            long long sum = 0;
            for (int k = 0; k < n; k++) {
                sum += (long long)A[i*n + k] * (long long)B[j*n + k];
            }
            C[i*n + j] = sum;
        }
    }
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

static void usage(const char *prog) {
    fprintf(stderr, "Uso: %s <N> [num_procesos] [seed] [max_val]\n", prog);
    fprintf(stderr, "  N            : tamanio de la matriz (entero > 0)\n");
    fprintf(stderr, "  num_procesos : (opcional) numero de procesos hijo (default: 4)\n");
    fprintf(stderr, "  seed         : (opcional) semilla para aleatorios (default: time(NULL))\n");
    fprintf(stderr, "  max_val      : (opcional) valores en rango [0, max_val] (default: 9)\n");
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(argv[0]); return 1; }

    int n = 0;
    if (!parse_int(argv[1], &n) || n <= 0) {
        fprintf(stderr, "Error: N debe ser un entero > 0.\n");
        usage(argv[0]);
        return 1;
    }
    int num_procs = 4, seed = (int)time(NULL), max_val = 9;
    if (argc >= 3 && (!parse_int(argv[2], &num_procs) || num_procs <= 0)) {
        fprintf(stderr, "Error: num_procesos invalido.\n"); return 1;
    }
    if (argc >= 4 && !parse_int(argv[3], &seed)) {
        fprintf(stderr, "Error: seed invalida.\n"); return 1;
    }
    if (argc >= 5 && (!parse_int(argv[4], &max_val) || max_val < 0)) {
        fprintf(stderr, "Error: max_val invalido.\n"); return 1;
    }
    if (num_procs > n) num_procs = n;

    srand((unsigned)seed);

    size_t mat_ints = (size_t)n * n;
    size_t shm_size = mat_ints * sizeof(int) * 2 + mat_ints * sizeof(long long);

    void *shm = mmap(NULL, shm_size, PROT_READ | PROT_WRITE,
                      MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (shm == MAP_FAILED) { perror("mmap"); return 1; }

    int *A = (int*)shm;
    int *B = A + mat_ints;
    long long *C = (long long*)(B + mat_ints);

    double t0 = get_time_ms();
    fill_random(A, n, max_val);
    fill_random(B, n, max_val);
    double t1 = get_time_ms();

    int rows_per = n / num_procs;
    int extra    = n % num_procs;

    double t2 = get_time_ms();
    int current_row = 0;
    for (int p = 0; p < num_procs; p++) {
        int rs = current_row;
        int re = current_row + rows_per + (p < extra ? 1 : 0);
        current_row = re;

        pid_t pid = fork();
        if (pid == 0) {
            multiply_rows(A, B, C, n, rs, re);
            _exit(0);
        } else if (pid < 0) {
            perror("fork"); return 1;
        }
    }
    for (int p = 0; p < num_procs; p++) wait(NULL);
    double t3 = get_time_ms();

    printf("=== Multiplicacion Paralela con Procesos %dx%d | %d procesos ===\n", n, n, num_procs);
    printf("Tiempo de llenado:        %10.3f ms\n", t1 - t0);
    printf("Tiempo de multiplicacion: %10.3f ms\n", t3 - t2);
    printf("Tiempo total:             %10.3f ms\n", (t1 - t0) + (t3 - t2));

    munmap(shm, shm_size);
    return 0;
}
#endif
