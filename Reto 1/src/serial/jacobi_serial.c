#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double now_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

int main(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "Uso: %s <N> <max_iter> <tol>\n", argv[0]);
        return 1;
    }

    int n = atoi(argv[1]);
    int max_iter = atoi(argv[2]);
    double tol = atof(argv[3]);

    if (n < 3 || max_iter <= 0 || tol <= 0.0) {
        fprintf(stderr, "Parametros invalidos. N>=3, max_iter>0, tol>0.\n");
        return 1;
    }

    size_t sz = (size_t)(n + 2);
    double *u = (double *)calloc(sz, sizeof(double));
    double *u_next = (double *)calloc(sz, sizeof(double));
    double *f = (double *)calloc(sz, sizeof(double));

    if (!u || !u_next || !f) {
        fprintf(stderr, "Error reservando memoria.\n");
        free(u);
        free(u_next);
        free(f);
        return 1;
    }

    for (int i = 1; i <= n; ++i) {
        f[i] = 1.0;
    }

    double h = 1.0 / (double)(n + 1);
    double h2 = h * h;

    int iter = 0;
    double max_diff = 0.0;
    double t0 = now_seconds();

    for (iter = 1; iter <= max_iter; ++iter) {
        max_diff = 0.0;

        for (int i = 1; i <= n; ++i) {
            u_next[i] = 0.5 * (u[i - 1] + u[i + 1] + h2 * f[i]);
            double diff = fabs(u_next[i] - u[i]);
            if (diff > max_diff) {
                max_diff = diff;
            }
        }

        double *tmp = u;
        u = u_next;
        u_next = tmp;

        if (max_diff < tol) {
            break;
        }
    }

    double t1 = now_seconds();

    printf("Metodo: serial\n");
    printf("N=%d max_iter=%d tol=%g\n", n, max_iter, tol);
    printf("Iteraciones=%d\n", iter);
    printf("Residual_inf=%e\n", max_diff);
    printf("Tiempo_s=%f\n", t1 - t0);
    printf("u[mid]=%.10f\n", u[n / 2]);

    free(u);
    free(u_next);
    free(f);
    return 0;
}
