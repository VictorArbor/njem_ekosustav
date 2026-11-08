#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef uint64_t njm_mid_t;

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

// Provjera je li fonem VOKAL (3 bita) ili KONSONANT (5 bita)
static inline int Je_Vokal(uint8_t kod) {
    // 1=A, 5=E, 9=I, 15=O, 21=U (stisnuti vokalski prostor)
    return (kod == 1 || kod == 5 || kod == 9 || kod == 15 || kod == 21);
}

// Sigurni UTF-8 i fonemski ekstraktor (dvoslovi + dijakritici)
static inline uint8_t Hrvatski_Fonem_U_Kod(const char** tekst) {
    const unsigned char* p = (const unsigned char*)*tekst;

    if (!*p) return 0;

    // 1. Dvoslovi (lj, nj, dž)
    if ((p[0] == 'l' || p[0] == 'L') && (p[1] == 'j' || p[1] == 'J')) { *tekst += 2; return 27; }
    if ((p[0] == 'n' || p[0] == 'N') && (p[1] == 'j' || p[1] == 'J')) { *tekst += 2; return 28; }
    if ((p[0] == 'd' || p[0] == 'D') && (p[1] == 'z' || p[1] == 'Z')) { *tekst += 2; return 29; }

    // 2. UTF-8 Dijakritici (2-bajtni uzorci: č, ć, đ, š, ž)
    if (p[0] == 0xC4 || p[0] == 0xC5) {
        uint16_t utf = (p[0] << 8) | p[1];
        *tekst += 2;
        switch (utf) {
            case 0xC48D: case 0xC48C: return 4;  // Č / č
            case 0xC487: case 0xC486: return 5;  // Ć / ć
            case 0xC491: case 0xC490: return 8;  // Đ / đ
            case 0xC5A1: case 0xC5A0: return 25; // Š / š
            case 0xC5BE: case 0xC5BD: return 30; // Ž / ž
        }
    }

    // 3. Standardni ASCII fonemi
    uint8_t kod = (uint8_t)(*p & 0x1F);
    *tekst += 1;
    return kod;
}

// LALOGLOSATOR ENC :: Dinamičko pakiranje (Vokal = 3b, Konsonant = 5b)
static inline njm_mid_t LALOGLOSATOR_Fonemski_ENC(const char* rijec, uint16_t* fu_out, uint8_t* mp_out) {
    njm_mid_t mid = 0;
    uint16_t fu = 0;
    size_t fonem_idx = 0;
    uint32_t shift = 0;
    const char* p = rijec;

    while (*p != '\0' && fonem_idx < 16) {
        uint8_t kod = Hrvatski_Fonem_U_Kod(&p);
        if (kod == 0) break;

        if (Je_Vokal(kod)) {
            // Vokal: 3 bita, fu bit = 0
            mid |= ((njm_mid_t)(kod & 0x07) << shift);
            shift += 3;
        } else {
            // Konsonant: 5 bitova, fu bit = 1
            mid |= ((njm_mid_t)(kod & 0x1F) << shift);
            fu |= (1 << fonem_idx);
            shift += 5;
        }
        fonem_idx++;
    }

    *fu_out = fu;
    *mp_out = (uint8_t)fonem_idx;

    // CTRL topologija = m.p (4b) || f.u (11b) na gornjim bitovima [63..49]
    uint64_t ctrl = (((uint64_t)fonem_idx & 0x0F) << 11) | (fu & 0x7FF);
    return (ctrl << 49) | (mid & 0x0001FFFFFFFFFFFFULL);
}

// LALOGLOSATOR DEC :: 1-taktni UBFX CTRL dohvat i razdvajanje
static inline void LALOGLOSATOR_Fonemski_DEC(njm_mid_t mid, char* izlaz) {
    uint64_t ctrl = (mid >> 49) & 0x7FFF; // UBFX simulacija
    size_t len = (ctrl >> 11) & 0x0F;
    uint16_t fu = ctrl & 0x7FF;

    uint32_t shift = 0;
    size_t pos = 0;

    for (size_t i = 0; i < len; i++) {
        int is_konsonant = (fu >> i) & 0x01;
        uint8_t kod = 0;

        if (is_konsonant) {
            kod = (uint8_t)((mid >> shift) & 0x1F);
            shift += 5;
        } else {
            kod = (uint8_t)((mid >> shift) & 0x07);
            shift += 3;
        }

        if (kod == 27) { izlaz[pos++] = 'l'; izlaz[pos++] = 'j'; }
        else if (kod == 28) { izlaz[pos++] = 'n'; izlaz[pos++] = 'j'; }
        else if (kod == 29) { izlaz[pos++] = 'd'; izlaz[pos++] = 'z'; }
        else { izlaz[pos++] = kod ? (char)(kod + 'a' - 1) : 'a'; }
    }
    izlaz[pos] = '\0';
}

int main(void) {
    uint64_t frekvencija = AARCH64_Frekvencija();
    const char* uzorci[] = {"oko", "voda", "trava", "zemlja", "svjetlo", "prijatelj", "morfologija", "kautarhičnostika"};
    size_t br_uzoraka = sizeof(uzorci) / sizeof(uzorci[0]);

    printf("=================================================================================\n");
    printf("  NJM LALOGLOSATOR :: ISPRAVLJENO FONEMSKO MJERENJE (V=3b / K=5b)               \n");
    printf("  CNTFRQ: %.2f MHz | AArch64 Nativna CTRL Topologija                            \n", (double)frekvencija / 1e6);
    printf("=================================================================================\n\n");

    for (size_t u = 0; u < br_uzoraka; u++) {
        const char* ulaz = uzorci[u];
        char izlaz[64] = {0};
        volatile njm_mid_t mid_reg = 0;
        uint16_t fu = 0;
        uint8_t mp = 0;

        uint64_t t0 = AARCH64_Citaj_CNTVCT();
        for (int i = 0; i < 100000; i++) {
            mid_reg = LALOGLOSATOR_Fonemski_ENC(ulaz, &fu, &mp);
        }
        uint64_t t1 = AARCH64_Citaj_CNTVCT();

        uint64_t t2 = AARCH64_Citaj_CNTVCT();
        for (int i = 0; i < 100000; i++) {
            LALOGLOSATOR_Fonemski_DEC(mid_reg, izlaz);
        }
        uint64_t t3 = AARCH64_Citaj_CNTVCT();

        double enc_ns = ((double)(t1 - t0) / (double)frekvencija / 100000.0) * 1e9;
        double dec_ns = ((double)(t3 - t2) / (double)frekvencija / 100000.0) * 1e9;

        printf("🔤 UZORAK: '%-16s' | m.p: %2d | f.u: 0x%03X | MID: 0x%016LX\n",
               ulaz, mp, fu, (unsigned long long)mid_reg);
        printf("   ⚡ FONEMSKO ENC: %6.2f ns\n", enc_ns);
        printf("   ⚡ DIRECT DEC  : %6.2f ns (O(1) UBFX Dohvat) | REKONSTRUKCIJA: '%s'\n", dec_ns, izlaz);
        printf("---------------------------------------------------------------------------------\n");
    }

    return 0;
}
