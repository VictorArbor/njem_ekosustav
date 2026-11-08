#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>

typedef uint64_t njm_mid_t;

// Pokazivači na funkcije unutar tvog LALOGLOSATOR binarca (libnjm_morf.so)
typedef njm_mid_t (*Laloglosator_Enc_Fn)(const char*);
typedef void (*Laloglosator_Dec_Fn)(njm_mid_t, char*);

static inline uint64_t AARCH64_Takt(void) {
    uint64_t val;
    asm volatile("mrs %0, cntvct_el0" : "=r" (val));
    return val;
}

int main(void) {
    printf("=========================================================\n");
    printf("  NJM LALOGLOSATOR: VEZA NA NATIVNI 'libnjm_morf.so'    \n");
    printf("=========================================================\n\n");

    // 1. Učitavanje tvojih binarnih modula
    void* handle = dlopen("./libnjm_morf.so", RTLD_LAZY);
    if (!handle) {
        // Pokušaj učitavanja iz matične home mape ako nije u trenutnoj
        handle = dlopen("/data/data/com.termux/files/home/libnjm_morf.so", RTLD_LAZY);
    }

    if (!handle) {
        printf("⚠️ Nije pronađen 'libnjm_morf.so'! Provjeri putanju do biblioteke.\n");
        printf("   Detalji greške: %s\n", dlerror());
        return 1;
    }

    // 2. Veza na točne simbole LALOGLOSATOR-a
    Laloglosator_Enc_Fn LALOGLOSATOR_Rijec_U_MID = (Laloglosator_Enc_Fn)dlsym(handle, "LALOGLOSATOR_Rijec_U_MID");
    Laloglosator_Dec_Fn LALOGLOSATOR_MID_U_Rijec = (Laloglosator_Dec_Fn)dlsym(handle, "LALOGLOSATOR_MID_U_Rijec");

    if (!LALOGLOSATOR_Rijec_U_MID || !LALOGLOSATOR_MID_U_Rijec) {
        printf("⚠️ Simboli Laloglosatora nisu pronađeni u .so datoteci.\n");
        printf("   Učitani simboli moraju odgovarati nazivima funkcija u C23/AArch64 binarcu.\n");
        dlclose(handle);
        return 1;
    }

    printf("✅ 'libnjm_morf.so' USPJEŠNO POVEZAN S LALOGLOSATOROM!\n\n");

    const char* testne_rijeci[] = {"oko", "voda", "trava", "zemlja", "svemir", "prijatelj", "morfologija", "metabolizam"};
    size_t broj_rijeci = sizeof(testne_rijeci) / sizeof(testne_rijeci[0]);

    for (size_t k = 0; k < broj_rijeci; k++) {
        const char* ulaz = testne_rijeci[k];
        char izlaz[32] = {0};

        // Toplo pokretanje (Cache warm-up)
        njm_mid_t mid = LALOGLOSATOR_Rijec_U_MID(ulaz);
        LALOGLOSATOR_MID_U_Rijec(mid, izlaz);

        // Provjera točnosti i reverzibilnosti tvoje binarne logike
        int tocano = (strcmp(ulaz, izlaz) == 0);

        // Mjerenje 1000 iteracija u bloku radi izbjegavanja granica rezolucije CNTVCT brojača
        uint64_t t0 = AARCH64_Takt();
        for (int i = 0; i < 10000; i++) {
            mid = LALOGLOSATOR_Rijec_U_MID(ulaz);
            asm volatile("" : : "r"(mid) : "memory");
        }
        uint64_t t1 = AARCH64_Takt();

        uint64_t t2 = AARCH64_Takt();
        for (int i = 0; i < 10000; i++) {
            LALOGLOSATOR_MID_U_Rijec(mid, izlaz);
            asm volatile("" : : "g"(izlaz) : "memory");
        }
        uint64_t t3 = AARCH64_Takt();

        double enc_taktova_po_pozivu = (double)(t1 - t0) / 10000.0;
        double dec_taktova_po_pozivu = (double)(t3 - t2) / 10000.0;

        printf("---------------------------------------------------------\n");
        printf("🔤 UZORAK: '%s' | MID: 0x%016LX\n", ulaz, (unsigned long long)mid);
        printf("   STATUS REVERZIBILNOSTI: %s\n", tocano ? "✅ PROŠAO (DEC(ENC(w)) == w)" : "❌ NIJE PROŠAO");
        printf("   ⚡ RIJEČ -> MID (Nativni Binarac) : %.3f ciklusa brojača\n", enc_taktova_po_pozivu);
        printf("   ⚡ MID -> RIJEČ (Nativni Binarac) : %.3f ciklusa brojača\n", dec_taktova_po_pozivu);
    }

    printf("=========================================================\n");
    dlclose(handle);
    return 0;
}
