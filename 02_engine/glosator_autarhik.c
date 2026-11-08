#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>

// AArch64 JIT Opkod Generator
typedef struct {
    uint32_t* kod;
    size_t pos;
} jit_t;

static inline void emit(jit_t* j, uint32_t opkod) {
    j->kod[j->pos++] = opkod;
}

// MRS X0, CNTVCT_EL0 -> 0xD53Be020
static inline void emit_mrs_cntvct(jit_t* j, int reg) {
    emit(j, 0xD53BE020 | (reg & 0x1F));
}

int main(void) {
    // Alokacija izvršne memorije bez eksternih toolchainova (mmap RX)
    size_t size = 4096;
    uint32_t* mem = mmap(NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mem == MAP_FAILED) return 1;

    jit_t j = { .kod = mem, .pos = 0 };

    char linija[256];
    uint64_t t_start = 0, t_enc = 0, t_dec = 0;

    // Čitanje hrvatskih mnemonika iz standardnog ulaza (.njm)
    while (fgets(linija, sizeof(linija), stdin)) {
        if (linija[0] == '#' || linija[0] == '\n') continue;

        char cmd[64], arg1[64];
        int parsed = sscanf(linija, "%s %s", cmd, arg1);

        if (strcmp(cmd, "wrt") == 0) {
            char* str = strchr(linija, '"');
            if (str) {
                str++;
                char* end = strrchr(str, '"');
                if (end) *end = '\0';
                // Odmah ispisujemo leksički tekst
                for (char* p = str; *p; p++) {
                    if (*p == '\\' && *(p+1) == 'n') { putchar('\n'); p++; }
                    else putchar(*p);
                }
            }
        }
        else if (strcmp(cmd, "pmu_start") == 0) {
            asm volatile("mrs %0, cntvct_el0" : "=r"(t_start));
        }
        else if (strcmp(cmd, "lsbu_mra") == 0) {
            // Simulacija nativnog LSBU MRA izvođenja (100.000 prolaza)
            volatile uint64_t x0 = 0x060000002B000000ULL;
            for (int i = 0; i < 100000; i++) {
                uint64_t ctrl = x0 >> 48;
                (void)ctrl;
            }
        }
        else if (strcmp(cmd, "lsbu_ubfx") == 0) {
            // Simulacija 1-taktnog UBFX dohvata (100.000 prolaza)
            volatile uint64_t x0 = 0x060000002B000000ULL;
            for (int i = 0; i < 100000; i++) {
                uint64_t ctrl = (x0 >> 48) & 0xFFFF;
                uint64_t mp = ctrl >> 11;
                uint64_t fu = ctrl & 0x7FF;
                (void)mp; (void)fu;
            }
        }
        else if (strcmp(cmd, "pmu_stop") == 0) {
            uint64_t t_stop;
            asm volatile("mrs %0, cntvct_el0" : "=r"(t_stop));
            if (strcmp(arg1, "r3") == 0) t_enc = t_stop - t_start;
            if (strcmp(arg1, "r4") == 0) t_dec = t_stop - t_start;
        }
        else if (strcmp(cmd, "wrt_num") == 0) {
            if (strcmp(arg1, "r3") == 0) printf("%llu", (unsigned long long)t_enc);
            if (strcmp(arg1, "r4") == 0) printf("%llu", (unsigned long long)t_dec);
        }
        else if (strcmp(cmd, "pir") == 0) {
            break;
        }
    }

    munmap(mem, size);
    return 0;
}
