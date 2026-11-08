/* ============================================================
   S6-FR Korak 4b: TEST A (MHD Rezonancija SO(3)^3)
   - Rotacija sinkronizirana s Alfvenovom frekvencijom m=1 moda
   - Eksplicitni Coriolisov balans
   Autor: suradnja (Kolega + DeepSeek + Gemini)
   ============================================================ */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <complex.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#undef I
#define I _Complex_I

#define SO3_ENABLED true

typedef struct {
    double S, Phi_frac, K_S6, c_nat, nu_S6, M_234, R_vakuola;
} S6_Vector;

static S6_Vector init_s6_vector(void) {
    const double S_val      = 234.0;
    const double phi        = 0.5849625007211562;
    const double k_s6       = 1.0 + (M_PI / 7.0) * (phi / S_val);
    const double phi_golden = (1.0 + sqrt(5.0)) / 2.0;
    const double phi_inv    = 1.0 / phi_golden;
    const double c          = S_val * (1.0 - (phi*phi)/(2.0*M_PI)) * phi_inv / sqrt(k_s6);
    S6_Vector v = {S_val, phi, k_s6, c, 14.28e9, 234.0, 0.49};
    return v;
}

#define N 256
#define NSTEPS 20000
#define SAVE_EVERY 2000

typedef struct {
    double B_r[N], B_th[N], B_z[N];
    double v_r[N], v_th[N], v_z[N];
    double phi[N];
} State;

static inline int imod(int i) { return (i + N) % N; }

static void dphi(const double *f, double *df, double dphi_step) {
    for (int i = 0; i < N; ++i) {
        df[i] = (f[imod(i+1)] - f[imod(i-1)]) / (2.0 * dphi_step);
    }
}

static double m1_amplitude(const double *f, const double *phi) {
    double complex sum = 0.0;
    for (int i = 0; i < N; ++i) {
        sum += f[i] * cexp(-I * phi[i]);
    }
    sum /= (double)N;
    return 2.0 * cabs(sum);
}

static double calculate_total_energy(const State *s) {
    double energy = 0.0;
    for (int i = 0; i < N; ++i) {
        double B2 = s->B_r[i]*s->B_r[i] + s->B_th[i]*s->B_th[i] + s->B_z[i]*s->B_z[i];
        double v2 = s->v_r[i]*s->v_r[i] + s->v_th[i]*s->v_th[i] + s->v_z[i]*s->v_z[i];
        energy += (B2 + v2);
    }
    return energy / (double)N;
}

int main(void) {
    const S6_Vector S6 = init_s6_vector();

    puts("============================================================");
    printf("S6-FR Korak 4b: REZONANTNI MHD TEST (SO(3)^3: %s)\n", SO3_ENABLED ? "UKLJUČENA" : "ISKLJUČENA");
    puts("============================================================");

    const double rho0     = 1.0;
    const double mu0      = 4.0 * M_PI * 1e-7;
    const double eta      = 0.0;
    const double v_A      = 1.0;

    /* SINKRONIZACIJA: Kutna brzina usklađena s Alfvenovom frekvencijom m=1 moda */
    const double k_m1     = 2.0 * M_PI / S6.R_vakuola;  /* valni broj m=1 moda */
    const double omega_m1 = v_A * k_m1;                 /* rezonantna frekvencija ≈ 12.82 rad/s */

    const double phi_g    = (1.0 + sqrt(5.0)) / 2.0;
    const double phi_inv  = 1.0 / phi_g;

    /* Rezonantne kutne brzine */
    const double Omega_x  = omega_m1;
    const double Omega_y  = Omega_x * phi_inv;
    const double Omega_z  = Omega_x * phi_inv * phi_inv;

    const double dphi_step = 2.0 * M_PI / (double)N;
    const double dx_min    = S6.R_vakuola * dphi_step;
    const double v_max     = v_A * 2.0;
    const double dt        = 0.3 * dx_min / v_max;

    printf("[SINKRONIZACIJA] m=1 frekvencija omega_m1 = %.4f rad/s\n", omega_m1);
    printf("[REZONANCIJA] Omega_x = %.4f, Omega_y = %.4f, Omega_z = %.4f rad/s\n", Omega_x, Omega_y, Omega_z);

    State s;
    for (int i = 0; i < N; ++i) {
        s.phi[i] = i * dphi_step;
    }
    const double B0 = 1.0;
    for (int i = 0; i < N; ++i) {
        double p = s.phi[i];
        s.B_r[i]  = B0 * cos(2.0 * p);
        s.B_th[i] = 0.0;
        s.B_z[i]  = B0 * sin(2.0 * p);
        s.B_r[i]  += 1e-4 * cos(p);
        s.B_z[i]  += 1e-4 * sin(p);
        s.v_r[i] = s.v_th[i] = s.v_z[i] = 0.0;
    }

    const double init_m1 = m1_amplitude(s.B_r, s.phi);
    const double init_E  = calculate_total_energy(&s);
    printf("[INICIJALNO] m=1 amp = %.6e | E_tot = %.6f\n", init_m1, init_E);

    State ds1;
    for (int step = 0; step < NSTEPS; ++step) {
        const double t = step * dt;

        double dB_r[N], dB_th[N], dB_z[N];
        double dv_r[N], dv_th[N], dv_z[N];
        dphi(s.B_r, dB_r, dphi_step);
        dphi(s.B_th, dB_th, dphi_step);
        dphi(s.B_z, dB_z, dphi_step);
        dphi(s.v_r, dv_r, dphi_step);
        dphi(s.v_th, dv_th, dphi_step);
        dphi(s.v_z, dv_z, dphi_step);

        const double inv_r = 1.0 / S6.R_vakuola;
        for (int i = 0; i < N; ++i) {
            double wxz_p = s.v_r[imod(i+1)]*s.B_th[imod(i+1)] - s.v_th[imod(i+1)]*s.B_r[imod(i+1)];
            double wxz_m = s.v_r[imod(i-1)]*s.B_th[imod(i-1)] - s.v_th[imod(i-1)]*s.B_r[imod(i-1)];
            double wxr_p = s.v_th[imod(i+1)]*s.B_z[imod(i+1)] - s.v_z[imod(i+1)]*s.B_th[imod(i+1)];
            double wxr_m = s.v_th[imod(i-1)]*s.B_z[imod(i-1)] - s.v_z[imod(i-1)]*s.B_th[imod(i-1)];

            double curl_r = (wxz_p - wxz_m) / (2.0 * dphi_step) * inv_r;
            double curl_z = -(wxr_p - wxr_m) / (2.0 * dphi_step) * inv_r;

            double lapB_r = (s.B_r[imod(i+1)] - 2.0*s.B_r[i] + s.B_r[imod(i-1)]) / (dphi_step*dphi_step);
            double lapB_z = (s.B_z[imod(i+1)] - 2.0*s.B_z[i] + s.B_z[imod(i-1)]) / (dphi_step*dphi_step);

            ds1.B_r[i]  = curl_r + eta * lapB_r * inv_r * inv_r;
            ds1.B_z[i]  = curl_z + eta * lapB_z * inv_r * inv_r;

            double conv_r  = s.v_th[i] * dv_r[i]  * inv_r;
            double conv_th = s.v_th[i] * dv_th[i] * inv_r;
            double conv_z  = s.v_th[i] * dv_z[i]  * inv_r;

            double curlB_r  = dB_z[i] * inv_r;
            double curlB_z  = -dB_r[i] * inv_r;
            double JxB_r  = -curlB_z * s.B_th[i];
            double JxB_th =  curlB_z * s.B_r[i] - curlB_r * s.B_z[i];
            double JxB_z  =  curlB_r * s.B_th[i];

            /* Inercijski čimbenici Coriolisove sile na rezonantnoj skali */
            double coriolis_r  = -2.0 * (Omega_y * s.v_z[i] - Omega_z * s.v_th[i]);
            double coriolis_th = -2.0 * (Omega_z * s.v_r[i] - Omega_x * s.v_z[i]);
            double coriolis_z  = -2.0 * (Omega_x * s.v_th[i] - Omega_y * s.v_r[i]);

            ds1.v_r[i]  = -conv_r  + JxB_r  / (mu0 * rho0) + (SO3_ENABLED ? coriolis_r : 0.0);
            ds1.v_th[i] = -conv_th + JxB_th / (mu0 * rho0) + (SO3_ENABLED ? coriolis_th : 0.0);
            ds1.v_z[i]  = -conv_z  + JxB_z  / (mu0 * rho0) + (SO3_ENABLED ? coriolis_z : 0.0);
        }

        for (int i = 0; i < N; ++i) {
            s.B_r[i]  += dt * ds1.B_r[i];
            s.B_z[i]  += dt * ds1.B_z[i];
            s.v_r[i]  += dt * ds1.v_r[i];
            s.v_th[i] += dt * ds1.v_th[i];
            s.v_z[i]  += dt * ds1.v_z[i];
        }

        if (step % SAVE_EVERY == 0) {
            double amp = m1_amplitude(s.B_r, s.phi);
            double E_cur = calculate_total_energy(&s);
            printf("  step %6d | t=%.3e s | m=1 amp = %.6e | E_tot = %.6f\n", step, t, amp, E_cur);
        }
    }

    const double final_m1 = m1_amplitude(s.B_r, s.phi);
    const double final_E  = calculate_total_energy(&s);

    puts("\n============================================================");
    printf("REZULTAT TESTA A (REZONANTNI SO(3)^3: %s)\n", SO3_ENABLED ? "UKLJUČENA" : "ISKLJUČENA");
    puts("============================================================");
    printf("Početna m=1 amplituda: %.6e | E_init: %.6f\n", init_m1, init_E);
    printf("Konačna m=1 amplituda: %.6e | E_fin : %.6f\n", final_m1, final_E);
    printf("Omjer amplituda:       %.6f\n", final_m1 / init_m1);
    printf("Omjer energija:        %.6f\n", final_E / init_E);
    puts("============================================================");

    return 0;
}
