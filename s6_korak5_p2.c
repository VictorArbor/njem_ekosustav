/* ============================================================
   S6-FR Korak 5: NEAVISNI MAXWELLOV TEST P2 (Q-FAKTOR)
   - Izračun Q-faktora iz Maxwellovih volumno-površinskih integrala
   - Ikozaedarska rezonantna vakuola s plazmom pod nu_S6 = 14.82 GHz
   - Potpuno neovisan proračun bez uvrštavanja S/P_ret
   Autor: suradnja (Kolega + DeepSeek + Gemini)
   ============================================================ */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int main(void) {
    puts("============================================================");
    puts("S6-FR Korak 5: Verifikacija P2 (Maxwellov Topološki Q-Faktor)");
    puts("============================================================");

    /* 1. FIZIKALNI PARAMETRI VAKUOLE I PLAZME */
    const double eps0         = 8.8541878128e-12;     /* F/m */
    const double mu0          = 4.0 * M_PI * 1e-7;    /* H/m */
    const double R_vakuola    = 0.49;                 /* m */
    const double nu_S6        = 14.8235e9;            /* Hz (izvedena rezonantna frekvencija) */
    const double omega_S6     = 2.0 * M_PI * nu_S6;
    
    /* Parametri plazme u I_h kavezu */
    const double T_plasma     = 13685.0;              /* K */
    const double n_e          = 1.0e20;               /* Gustoća elektrona m^-3 */
    const double e_charge     = 1.602176634e-19;      /* C */
    const double m_e          = 9.1093837015e-31;     /* kg */
    
    /* Vodljivost plazme (Spitzerov model u mikrovalnom režimu) */
    const double nu_e_coll    = 1.0e8;                /* Sudarna frekvencija Hz */
    const double sigma_plasma = (n_e * e_charge * e_charge) / (m_e * nu_e_coll); /* S/m */

    /* 2. GEOMETRIJSKI INTEGRALI IKOZAEDARSKE VAKUOLE (V_vol i S_surf) */
    /* Ikozaedar usipana sfera polumjera R_vakuola */
    const double V_volume     = (4.0 / 3.0) * M_PI * R_vakuola * R_vakuola * R_vakuola;
    const double S_surface    = 4.0 * M_PI * R_vakuola * R_vakuola;

    /* Pretpostavljena polja stacionarnog vala pod I_h modulacijom */
    const double E0           = 1.0e5;                /* V/m */
    const double B0           = E0 / (3.0e8);         /* T */

    /* 3. NEAVISNA INTEGRACIJA ENERGIJE I GUBITAKA */
    /* Pohranjena energija u volumenu: W = Integral( 1/2 eps|E|^2 + 1/2 1/mu|B|^2 ) dV */
    const double W_electric   = 0.5 * eps0 * E0 * E0 * V_volume;
    const double W_magnetic   = 0.5 * (1.0 / mu0) * B0 * B0 * V_volume;
    const double W_pohranjeno = W_electric + W_magnetic;

    /* Volumni gubici u plazmi: P_plasma = Integral( 1/2 sigma |E|^2 ) dV */
    /* Zbog visoke vodljivosti i I_h rešetkastog zaklanjanja efektivni skin-depth popravak */
    const double delta_skin   = sqrt(2.0 / (mu0 * omega_S6 * sigma_plasma));
    const double P_disipacija = 0.5 * sigma_plasma * E0 * E0 * (S_surface * delta_skin);

    /* 4. PRORAČUN TOPOLOŠKOG Q-FAKTORA */
    const double Q_fizički    = (omega_S6 * W_pohranjeno) / P_disipacija;

    printf("[PARAMETRI]  nu_S6 = %.4f GHz | R_vakuola = %.2f m\n", nu_S6 / 1e9, R_vakuola);
    printf("[ENERGIJA]   W_pohranjeno = %.6e J\n", W_pohranjeno);
    printf("[DISIPACIJA] P_disipacija = %.6e W (Skin depth delta = %.3e m)\n", P_disipacija, delta_skin);
    printf("[REZULTAT P2] Neovisno izračunati Q-faktor = %.3f\n", Q_fizički);
    puts("------------------------------------------------------------");

    /* 5. FALSIFIKACIJSKA PROVJERA */
    const double target_min = 22.25;
    const double target_max = 26.25;
    const bool passed = (Q_fizički >= target_min && Q_fizički <= target_max);

    puts("============================================================");
    puts("REZULTAT NEPRISTRANOG TESTA P2 (Q-FAKTOR)");
    puts("============================================================");
    printf("Predviđeni raspon: [%.2f, %.2f]\n", target_min, target_max);
    printf("Izračunata vrijednost Q-faktora: %.3f\n", Q_fizički);

    if (passed) {
        puts("STATUS: PASSED (P2 POTVRĐEN) — Maxwellova integracija daje predviđeni topološki Q-faktor!");
    } else {
        puts("STATUS: FAILED (P2 PAO) — Fizički Q-faktor izlazi iz zadanog raspona.");
    }
    puts("============================================================");

    return 0;
}
