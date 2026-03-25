#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    int id;
    int n;
    int num_threads;
    int max_iter;
    double tol;
    double h2;
    double *u;
    double *u_next;
    double *f;
    double *local_max;
    int *stop;
    int *iters_done;
    pthread_barrier_t *barrier;
} worker_args_t;

static double now_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static void *worker(void *arg) {
    worker_args_t *a = (worker_args_t *)arg;

    int chunk = a->n / a->num_threads;
    int rem = a->n % a->num_threads;

    int start = 1 + a->id * chunk + (a->id < rem ? a->id : rem);
    int len = chunk + (a->id < rem ? 1 : 0);
    int end = start + len - 1;

    for (int iter = 1; iter <= a->max_iter; ++iter) {
        double local = 0.0;

        for (int i = start; i <= end; ++i) {
            a->u_next[i] = 0.5 * (a->u[i - 1] + a->u[i + 1] + a->h2 * a->f[i]);
            double d = fabs(a->u_next[i] - a->u[i]);
            if (d > local) {
                local = d;
            }
        }

        a->local_max[a->id] = local;
        pthread_barrier_wait(a->barrier);

        if (a->id == 0) {
            double global = 0.0;
            for (int t = 0; t < a->num_threads; ++t) {
                if (a->local_max[t] > global) {
                    global = a->local_max[t];
                }
            }

            double *tmp = a->u;
            a->u = a->u_next;
            a->u_next = tmp;

            for (int t = 1; t < a->num_threads; ++t) {
                a[t].u = a->u;
                a[t].u_next = a->u_next;
            }

            *(a->iters_done) = iter;
            if (global < a->tol) {
                *(a->stop) = 1;
            }
        }

        pthread_barrier_wait(a->barrier);

        if (*(a->stop)) {
            break;
        }
    }

    return NULL;
}

int main(int argc, char **argv) {
    if (argc < 5) {
        fprintf(stderr, "Uso: %s <N> <max_iter> <tol> <threads>\n", argv[0]);
        return 1;
    }

    int n = atoi(argv[1]);
    int max_iter = atoi(argv[2]);
    double tol = atof(argv[3]);
    int num_threads = atoi(argv[4]);

    if (n < 3 || max_iter <= 0 || tol <= 0.0 || num_threads <= 0) {
        fprintf(stderr, "Parametros invalidos.\n");
        return 1;
    }

    size_t sz = (size_t)(n + 2);
    double *u = (double *)calloc(sz, sizeof(double));
    double *u_next = (double *)calloc(sz, sizeof(double));
    double *f = (double *)calloc(sz, sizeof(double));
    double *local_max = (double *)calloc((size_t)num_threads, sizeof(double));

    pthread_t *threads = (pthread_t *)calloc((size_t)num_threads, sizeof(pthread_t));
    worker_args_t *args = (worker_args_t *)calloc((size_t)num_threads, sizeof(worker_args_t));

    if (!u || !u_next || !f || !local_max || !threads || !args) {
        fprintf(stderr, "Error reservando memoria.\n");
        free(u);
        free(u_next);
        free(f);
        free(local_max);
        free(threads);
        free(args);
        return 1;
    }

    for (int i = 1; i <= n; ++i) {
        f[i] = 1.0;
    }

    double h = 1.0 / (double)(n + 1);
    double h2 = h * h;

    int stop = 0;
    int iters_done = 0;
    pthread_barrier_t barrier;
    pthread_barrier_init(&barrier, NULL, (unsigned int)num_threads);

    for (int t = 0; t < num_threads; ++t) {
        args[t].id = t;
        args[t].n = n;
        args[t].num_threads = num_threads;
        args[t].max_iter = max_iter;
        args[t].tol = tol;
        args[t].h2 = h2;
        args[t].u = u;
        args[t].u_next = u_next;
        args[t].f = f;
        args[t].local_max = local_max;
        args[t].stop = &stop;
        args[t].iters_done = &iters_done;
        args[t].barrier = &barrier;
    }

    double t0 = now_seconds();

    for (int t = 0; t < num_threads; ++t) {
        pthread_create(&threads[t], NULL, worker, &args[t]);
    }

    for (int t = 0; t < num_threads; ++t) {
        pthread_join(threads[t], NULL);
    }

    double t1 = now_seconds();

    double final_residual = 0.0;
    for (int t = 0; t < num_threads; ++t) {
        if (local_max[t] > final_residual) {
            final_residual = local_max[t];
        }
    }

    printf("Metodo: threads (pthread)\n");
    printf("N=%d max_iter=%d tol=%g threads=%d\n", n, max_iter, tol, num_threads);
    printf("Iteraciones=%d\n", iters_done);
    printf("Residual_inf=%e\n", final_residual);
    printf("Tiempo_s=%f\n", t1 - t0);
    printf("u[mid]=%.10f\n", args[0].u[n / 2]);

    pthread_barrier_destroy(&barrier);
    free(u);
    free(u_next);
    free(f);
    free(local_max);
    free(threads);
    free(args);
    return 0;
}
