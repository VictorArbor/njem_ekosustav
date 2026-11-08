#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

typedef uint64_t njm_mid_t;

// Hardversko čitanje AArch64 sistemskog brojača ciklusa
static inline uint64_t AARCH64_Citaj_CNTVCT(void) {
    uint64_t val;
    asm volatile("mrs %0, cntvct_el0" : "=r" (val));
    return val;
}

// Nativna Laloglosator konverzija (3-11 fonema u 64 bita)
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
    char linija[256];
    njm_mid_t mid_reg = 0;
    char ulazna_rijec[32] = "morfologija";
    char izlazna_rijec[32] = {0};
    
    uint64_t t_start = 0, t_enc = 0, t_dec = 0;

    // Interpretacija Lalator skripte vođene BNF-LSBU uzorcima
    while (fgets(linija, sizeof(linija), stdin)) {
        if (strstr(linija, "pmu_start")) {
            t_start = AARCH64_Citaj_CNTVCT();
        } 
        else if (strstr(linija, "enc")) {
            uint64_t t0 = AARCH64_Citaj_CNTVCT();
            for(int i=0; i<10000; i++) {
                mid_reg = LALOGLOSATOR_ENC(ulazna_rijec);
                asm volatile("" : : "r"(mid_reg) : "memory");
            }
            uint64_t t1 = AARCH64_Citaj_CNTVCT();
            t_enc = (t1 - t0);
        } 
        else if (strstr(linija, "dec")) {
            uint64_t t0 = AARCH64_Citaj_CNTVCT();
            for(int i=0; i<10000; i++) {
                LALOGLOSATOR_DEC(mid_reg, izlazna_rijec);
                asm volatile("" : : "g"(izlazna_rijec) : "memory");
            }
            uint64_t t1 = AARCH64_Citaj_CNTVCT();
            t_dec = (t1 - t0);
        }
        else if (strstr(linija, "wrt 1,")) {
            char* tekst = strchr(linija, '"');
            if (tekst) {
                tekst++;
                char* kraj = strrchr(tekst, '"');
                if (kraj) *kraj = '\0';
                
                // Dekodiranje escape sekvenci \n
                for (char* p = tekst; *p; p++) {
                    if (*p == '\\' && *(p+1) == 'n') {
                        putchar('\n');
                        p++;
                    } else {
                        putchar(*p);
                    }
                }
            }
        }
        else if (strstr(linija, "wrt_num r3")) {
            printf("%.3f", (double)t_enc / 10000.0);
        }
        else if (strstr(linija, "wrt_num r4")) {
            printf("%.3f", (double)t_dec / 10000.0);
        }
    }
    return 0;
}
