#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <linux/perf_event.h>

// -----------------------------------------------------------------------------
// 1. NJM LALOGLOSATOR (Nativno fonetsko pakiranje u 64-bitni MID registar)
// -----------------------------------------------------------------------------

typedef uint64_t njm_mid_t;

// Nativni LALOGLOSATOR: Pretvara riječ (3 do 11 fonema) u 64-bitni MID
__attribute__((weak)) njm_mid_t LALOGLOSATOR_Rijec_U_MID(const char* rijec) {
    njm_mid_t mid = 0;
    size_t len = 0;
    
    while (rijec[len] != '\0' && len < 11) {
        // Fonetsko mapiranje: 5 bitova po znak (1..31)
        uint64_t fonem_kod = (uint64_t)(rijec[len] & 0x1F);
        mid |= (fonem_kod << (len * 5));
        len++;
    }
    
    // Spremanje duljine fonema u gornjih 5 bitova (bitovi 59..63)
    return mid | (((njm_mid_t)len) << 59);
}

// Nativni LALOGLOSATOR: Rekonstruira izvornu riječ iz 64-bitnog MID registra
__attribute__((weak)) void LALOGLOSATOR_MID_U_Rijec(njm_mid_t mid, char* izlaz_rijec) {
    size_t len = (size_t)((mid >> 59) & 0x1F);
    
    for (size_t i = 0; i < len && i < 11; i++) {
        uint8_t kod = (uint8_t)((mid >> (i * 5)) & 0x1F);
        // Obratna fonetska restauracija u ASCII
        izlaz_rijec[i] = kod ? (char)(kod + 'a' - 1) : 'a';
    }
    izlaz_rijec[len] = '\0';
}

// -----------------------------------------------------------------------------
// 2. DISKRETNI KALKULATOR HARDVERSKIH TAKTOVA (ARMv8 PMU / CNTVCT)
// -----------------------------------------------------------------------------

static int perf_fd_ciklusi = -1;

static long pokreni_perf_event(uint32_t tip, uint64_t konfig) {
    struct perf_event_attr pe;
    memset(&pe, 0, sizeof(struct perf_event_attr));
    pe.type = tip;
    pe.size = sizeof(struct perf_event_attr);
    pe.config = konfig;
    pe.disabled = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;
    return syscall(__NR_perf_event_open, &pe, 0, -1, -1, 0);
}

static void DISKRETNI_KALKULATOR_Inicijalizacija(void) {
    perf_fd_ciklusi = pokreni_perf_event(PERF_TYPE_HARDWARE, PERF_COUNT_HW_CPU_CYCLES);
}

static inline uint64_t AARCH64_Citaj_Taktove_Izravno(void) {
    uint64_t val;
    asm volatile("mrs %0, cntvct_el0" : "=r" (val));
    return val;
}

static inline uint64_t DISKRETNI_KALKULATOR_Citaj_Cikluse(void) {
    if (perf_fd_ciklusi != -1) {
        uint64_t ciklusi;
        if (read(perf_fd_ciklusi, &ciklusi, sizeof(ciklusi)) > 0) {
            return ciklusi;
        }
    }
    return AARCH64_Citaj_Taktove_Izravno();
}

// -----------------------------------------------------------------------------
// 3. NJM GENERATOR BINARNIH UZORAKA (Baza hrvatskih riječi po fonemima)
// -----------------------------------------------------------------------------

typedef struct {
    char rijec[16];
    uint8_t duljina_fonema;
} NJM_TestniUzorak;

static NJM_TestniUzorak NJM_GENERATOR_Stvori_Uzorke(size_t indeks) {
    static const char* baza_rijeci[] = {
        "oko",         // 3 fonema
        "voda",        // 4 fonema
        "trava",       // 5 fonema
        "zemlja",      // 6 fonema
        "svemir",      // 6 fonema
        "prijatelj",   // 9 fonema
        "morfologija", // 11 fonema
        "metabolizam"  // 11 fonema
    };
    size_t n = sizeof(baza_rijeci) / sizeof(baza_rijeci[0]);
    NJM_TestniUzorak uzorak;
    strncpy(uzorak.rijec, baza_rijeci[indeks % n], sizeof(uzorak.rijec));
    uzorak.duljina_fonema = strlen(uzorak.rijec);
    return uzorak;
}

static int usporedi_u64(const void* a, const void* b) {
    uint64_t arg1 = *(const uint64_t*)a;
    uint64_t arg2 = *(const uint64_t*)b;
    if (arg1 < arg2) return -1;
    if (arg1 > arg2) return 1;
    return 0;
}

// -----------------------------------------------------------------------------
// 4. MAIN BENCHMARK LOOP
// -----------------------------------------------------------------------------

#define BROJ_PONAVLJANJA 100000
#define TRAJNOST_CACHE_ZAGRIJAVANJA 5000

int main(void) {
    printf("=========================================================\n");
    printf("  NJM LALOGLOSATOR: DISKRETNO MJERENJE AARCH64 TAKTOVA  \n");
    printf("=========================================================\n\n");

    DISKRETNI_KALKULATOR_Inicijalizacija();

    if (perf_fd_ciklusi != -1) {
        printf("👉 Status brojača: [HARDVERSKI PMU PERF AKTIVAN]\n");
    } else {
        printf("👉 Status brojača: [AARCH64 CNTVCT_EL0 HARDVERSKI BROJAČ]\n");
    }

    uint64_t* ciklusi_enc = malloc(BROJ_PONAVLJANJA * sizeof(uint64_t));
    uint64_t* ciklusi_dec = malloc(BROJ_PONAVLJANJA * sizeof(uint64_t));

    // Mjerenje režije prazne petlje
    uint64_t start_ov = DISKRETNI_KALKULATOR_Citaj_Cikluse();
    for (volatile int i = 0; i < BROJ_PONAVLJANJA; i++) {
        asm volatile("");
    }
    uint64_t stop_ov = DISKRETNI_KALKULATOR_Citaj_Cikluse();
    uint64_t rezijski_taktovi = (stop_ov - start_ov) / BROJ_PONAVLJANJA;

    printf("🔧 Režijski utrošak prazne petlje: %lu taktova\n\n", rezijski_taktovi);

    for (size_t test_idx = 0; test_idx < 8; test_idx++) {
        NJM_TestniUzorak uzorak = NJM_GENERATOR_Stvori_Uzorke(test_idx);
        char rekonstruirana_rijec[16] = {0};
        njm_mid_t izracunati_mid = 0;

        // A. CACHE WARM-UP
        for (int w = 0; w < TRAJNOST_CACHE_ZAGRIJAVANJA; w++) {
            izracunati_mid = LALOGLOSATOR_Rijec_U_MID(uzorak.rijec);
            LALOGLOSATOR_MID_U_Rijec(izracunati_mid, rekonstruirana_rijec);
        }

        // B. VERIFIKACIJA REVERZIBILNOSTI
        if (strcmp(uzorak.rijec, rekonstruirana_rijec) != 0) {
            printf("❌ [GREŠKA REVERZIBILNOSTI]: '%s' != '%s'\n", uzorak.rijec, rekonstruirana_rijec);
            continue;
        }

        // C. MJERENJE ENKODIRANJA (Riječ -> MID)
        if (perf_fd_ciklusi != -1) {
            ioctl(perf_fd_ciklusi, PERF_EVENT_IOC_RESET, 0);
            ioctl(perf_fd_ciklusi, PERF_EVENT_IOC_ENABLE, 0);
        }

        for (int i = 0; i < BROJ_PONAVLJANJA; i++) {
            uint64_t t0 = DISKRETNI_KALKULATOR_Citaj_Cikluse();
            izracunati_mid = LALOGLOSATOR_Rijec_U_MID(uzorak.rijec);
            uint64_t t1 = DISKRETNI_KALKULATOR_Citaj_Cikluse();
            asm volatile("" : : "r"(izracunati_mid) : "memory");
            ciklusi_enc[i] = (t1 > t0) ? (t1 - t0) : 0;
        }

        // D. MJERENJE DEKODIRANJA (MID -> Riječ)
        for (int i = 0; i < BROJ_PONAVLJANJA; i++) {
            uint64_t t0 = DISKRETNI_KALKULATOR_Citaj_Cikluse();
            LALOGLOSATOR_MID_U_Rijec(izracunati_mid, rekonstruirana_rijec);
            uint64_t t1 = DISKRETNI_KALKULATOR_Citaj_Cikluse();
            asm volatile("" : : "g"(rekonstruirana_rijec) : "memory");
            ciklusi_dec[i] = (t1 > t0) ? (t1 - t0) : 0;
        }

        if (perf_fd_ciklusi != -1) {
            ioctl(perf_fd_ciklusi, PERF_EVENT_IOC_DISABLE, 0);
        }

        qsort(ciklusi_enc, BROJ_PONAVLJANJA, sizeof(uint64_t), usporedi_u64);
        qsort(ciklusi_dec, BROJ_PONAVLJANJA, sizeof(uint64_t), usporedi_u64);

        uint64_t enc_min = ciklusi_enc[0] > rezijski_taktovi ? ciklusi_enc[0] - rezijski_taktovi : ciklusi_enc[0];
        uint64_t enc_med = ciklusi_enc[BROJ_PONAVLJANJA / 2];
        uint64_t enc_max = ciklusi_enc[BROJ_PONAVLJANJA - 1];

        uint64_t dec_min = ciklusi_dec[0] > rezijski_taktovi ? ciklusi_dec[0] - rezijski_taktovi : ciklusi_dec[0];
        uint64_t dec_med = ciklusi_dec[BROJ_PONAVLJANJA / 2];
        uint64_t dec_max = ciklusi_dec[BROJ_PONAVLJANJA - 1];

        printf("---------------------------------------------------------\n");
        printf("🔤 UZORAK: '%s' (%u fonema) | MID: 0x%016LX\n", 
               uzorak.rijec, uzorak.duljina_fonema, (unsigned long long)izracunati_mid);
        printf("   ✅ REVERZIBILNOST [DEC(ENC(w)) == w]: POTVRĐENA\n");
        printf("   ⚡ Riječ -> MID (ENC) | MIN: %2lu | MEDIJAN: %2lu | MAX: %4lu taktova\n", 
               enc_min, enc_med, enc_max);
        printf("   ⚡ MID -> Riječ (DEC) | MIN: %2lu | MEDIJAN: %2lu | MAX: %4lu taktova\n", 
               dec_min, dec_med, dec_max);
    }

    printf("=========================================================\n");
    printf("  MJERENJE ZAVRŠENO | NJM LALOGLOSATOR VERIFICIRAN\n");
    printf("=========================================================\n");

    free(ciklusi_enc);
    free(ciklusi_dec);
    return 0;
}
