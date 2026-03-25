#define _GNU_SOURCE
#include <math.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

typedef struct {
    int n;
    int max_iter;
    int workers;
    double tol;
    double h2;
    int stop;
    int iters_done;
    pthread_barrier_t barrier;
    double *u;
    double *u_next;
    double *f;
    double *local_max;
} shared_t;

static double now_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static void child_loop(shared_t *sh, int id) {
    int chunk = sh->n / sh->workers;
    int rem = sh->n % sh->workers;
    int start = 1 + id * chunk + (id < rem ? id : rem);
    int len = chunk + (id < rem ? 1 : 0);
    int end = start + len - 1;

    for (int iter = 1; iter <= sh->max_iter; ++iter) {
        double local = 0.0;

        for (int i = start; i <= end; ++i) {
            sh->u_next[i] = 0.5 * (sh->u[i - 1] + sh->u[i + 1] + sh->h2 * sh->f[i]);
            double d = fabs(sh->u_next[i] - sh->u[i]);
            if (d > local) {
                local = d;
            }
        }

        sh->local_max[id] = local;

        pthread_barrier_wait(&sh->barrier);
        pthread_barrier_wait(&sh->barrier);

        if (sh->stop) {
            break;
        }
    }

    _exit(0);
}

int main(int argc, char **argv) {
    if (argc < 5) {
        fprintf(stderr, "Uso: %s <N> <max_iter> <tol> <procesos>\n", argv[0]);
        return 1;
    }

    int n = atoi(argv[1]);
    int max_iter = atoi(argv[2]);
    double tol = atof(argv[3]);
    int workers = atoi(argv[4]);

    if (n < 3 || max_iter <= 0 || tol <= 0.0 || workers <= 0) {
        fprintf(stderr, "Parametros invalidos.\n");
        return 1;
    }

    shared_t *sh = mmap(NULL, sizeof(shared_t), PROT_READ | PROT_WRITE,
                        MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (sh == MAP_FAILED) {
        perror("mmap shared_t");
        return 1;
    }

    size_t sz = (size_t)(n + 2) * sizeof(double);
    sh->u = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    sh->u_next = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    sh->f = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    sh->local_max = mmap(NULL, (size_t)workers * sizeof(double), PROT_READ | PROT_WRITE,
                         MAP_SHARED | MAP_ANONYMOUS, -1, 0);

    if (sh->u == MAP_FAILED || sh->u_next == MAP_FAILED || sh->f == MAP_FAILED ||
        sh->local_max == MAP_FAILED) {
        perror("mmap arrays");
        return 1;
    }

    sh->n = n;
    sh->max_iter = max_iter;
    sh->workers = workers;
    sh->tol = tol;
    sh->stop = 0;
    sh->iters_done = 0;

    double h = 1.0 / (double)(n + 1);
    sh->h2 = h * h;

    for (int i = 0; i < n + 2; ++i) {
        sh->u[i] = 0.0;
        sh->u_next[i] = 0.0;
        sh->f[i] = (i == 0 || i == n + 1) ? 0.0 : 1.0;
    }

    pthread_barrierattr_t attr;
    pthread_barrierattr_init(&attr);
    pthread_barrierattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
    pthread_barrier_init(&sh->barrier, &attr, (unsigned int)(workers + 1));
    pthread_barrierattr_destroy(&attr);

    pid_t *pids = (pid_t *)calloc((size_t)workers, sizeof(pid_t));
    if (!pids) {
        fprintf(stderr, "Error reservando memoria para pids.\n");
        return 1;
    }

    for (int w = 0; w < workers; ++w) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork");
            sh->stop = 1;
            break;
        } else if (pid == 0) {
            child_loop(sh, w);
        } else {
            pids[w] = pid;
        }
    }

    double t0 = now_seconds();

    for (int iter = 1; iter <= max_iter; ++iter) {
        pthread_barrier_wait(&sh->barrier);

        double global = 0.0;
        for (int w = 0; w < workers; ++w) {
            if (sh->local_max[w] > global) {
                global = sh->local_max[w];
            }
        }

        double *tmp = sh->u;
        sh->u = sh->u_next;
        sh->u_next = tmp;

        sh->iters_done = iter;
        if (global < tol) {
            sh->stop = 1;
        }

        pthread_barrier_wait(&sh->barrier);

        if (sh->stop) {
            break;
        }
    }

    double t1 = now_seconds();

    for (int w = 0; w < workers; ++w) {
        if (pids[w] > 0) {
            waitpid(pids[w], NULL, 0);
        }
    }

    double final_residual = 0.0;
    for (int w = 0; w < workers; ++w) {
        if (sh->local_max[w] > final_residual) {
            final_residual = sh->local_max[w];
        }
    }

    printf("Metodo: procesos (fork + shared memory)\n");
    printf("N=%d max_iter=%d tol=%g procesos=%d\n", n, max_iter, tol, workers);
    printf("Iteraciones=%d\n", sh->iters_done);
    printf("Residual_inf=%e\n", final_residual);
    printf("Tiempo_s=%f\n", t1 - t0);
    printf("u[mid]=%.10f\n", sh->u[n / 2]);

    pthread_barrier_destroy(&sh->barrier);
    munmap(sh->u, sz);
    munmap(sh->u_next, sz);
    munmap(sh->f, sz);
    munmap(sh->local_max, (size_t)workers * sizeof(double));
    munmap(sh, sizeof(shared_t));
    free(pids);
    return 0;
}
