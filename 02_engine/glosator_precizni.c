#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef uint64_t njm_mid_t;

// Očitavanje AArch64 sistemske frekvencije brojača (Hz) i stanja (CNTVCT)
static inline uint64_t AARCH64_Frekvencija(void) {
    uint64_t val;
    asm volatile("mrs %0, cntfrq_el0" : "=r" (val));
    return val;
}

static inline uint64_t AARCH64_Citaj_CNTVCT(void) {
    uint64_t val;
    asm volatile("mrs %0, cntvct_el0" : "=r" (val));
    return val;
}

// Nativni LALOGLOSATOR
static inline njm_mid_t LALOGLOSATOR_ENC(const char* rijec) {
    njm_mid_t mid = 0;
    size_t len = 0;
    while (rijec[len] != '\0' && len < 11) {
        mid |= (((njm_mid_t)(rijec[len] & 0x1F)) << (len * 5));
        len++;
    }
    return mid | (((njm_mid_t)len) << 59);
}

static inline void LALOGLOSATOR_DEC(njm_mid_t mid, char* izlaz) {
    size_t len = (mid >> 59) & 0x1F;
    for (size_t i = 0; i < len && i < 11; i++) {
        uint8_t kod = (mid >> (i * 5)) & 0x1F;
        izlaz[i] = kod ? (char)(kod + 'a' - 1) : 'a';
    }
    izlaz[len] = '\0';
}

int main(void) {
    uint64_t frekvencija = AARCH64_Frekvencija(); // Obično 19200000 Hz (19.2 MHz)
    double cpu_ghz = 2.0; // Procijenjena radna frekvencija A53/A51 jezgre u GHz
    
    const char* uzorci[] = {"oko", "voda", "trava", "zemlja", "svemir", "prijatelj", "morfologija", "metabolizam"};
    size_t br_uzoraka = sizeof(uzorci) / sizeof(uzorci[0]);

    printf("=========================================================\n");
    printf("  NJM LALOGLOSATOR :: EGZAKTNO SILIKONSKO MJERENJE      \n");
    printf("  Sistemska frekvencija brojača (CNTFRQ): %.2f MHz     \n", (double)frekvencija / 1e6);
    printf("=========================================================\n\n");

    for (size_t u = 0; u < br_uzoraka; u++) {
        const char* ulaz = uzorci[u];
        char izlaz[32] = {0};
        volatile njm_mid_t mid_reg = 0;

        // 1. Mjerenje ENKODIRANJA (Riječ -> MID)
        uint64_t t0 = AARCH64_Citaj_CNTVCT();
        for (int i = 0; i < 100000; i++) {
            mid_reg = LALOGLOSATOR_ENC(ulaz);
        }
        uint64_t t1 = AARCH64_Citaj_CNTVCT();

        // 2. Mjerenje DEKODIRANJA (MID -> Riječ)
        uint64_t t2 = AARCH64_Citaj_CNTVCT();
        for (int i = 0; i < 100000; i++) {
            LALOGLOSATOR_DEC(mid_reg, izlaz);
        }
        uint64_t t3 = AARCH64_Citaj_CNTVCT();

        // Pretvaranje razlike brojača u nanosekunde i procijenjene CPU cikluse
        double enc_ns = ((double)(t1 - t0) / (double)frekvencija / 100000.0) * 1e9;
        double dec_ns = ((double)(t3 - t2) / (double)frekvencija / 100000.0) * 1e9;

        double enc_cpu_ciklusi = enc_ns * cpu_ghz;
        double dec_cpu_ciklusi = dec_ns * cpu_ghz;

        printf("🔤 UZORAK: '%-11s' | MID: 0x%016LX\n", ulaz, (unsigned long long)mid_reg);
        printf("   ⚡ ENC (Riječ -> MID) : %6.2f ns  (~%5.1f stvarna CPU ciklusa)\n", enc_ns, enc_cpu_ciklusi);
        printf("   ⚡ DEC (MID -> Riječ) : %6.2f ns  (~%5.1f stvarna CPU ciklusa)\n", dec_ns, dec_cpu_ciklusi);
        printf("---------------------------------------------------------\n");
    }

    return 0;
}
