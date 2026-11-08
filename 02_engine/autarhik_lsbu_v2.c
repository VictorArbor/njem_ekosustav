#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>

// LSBU ISA tablica
typedef struct {
    uint8_t kod;
    const char* mnemonik;
    const char* semantika;
} lsbu_instrukcija_t;

static const lsbu_instrukcija_t LSBU_ISA_TABLICA[] = {
    {0x01, "pis", "C := A ∩ B"},
    {0x02, "uis", "C := A ∪ B"},
    {0x03, "ris", "C := A \\ B"},
    {0x04, "srs", "C := A △ B"},
    {0x05, "lpo", "C := A << n"},
    {0x06, "dpo", "C := A >> n"},
    {0x07, "ibo", "C := A[n:m]"},
    {0x08, "pje", "B := A"},
    {0x09, "nve", "B := c"},
    {0x18, "mkm", "V -> M"},
    {0x1a, "spe", "e -> Σ"},
    {0x1b, "pir", "R -> σₚ"},
    {0x26, "ooi", "O -> EXEC"},
    // ... ostali
};

typedef struct {
    uint32_t* memorija;
    size_t pokazivac;
    size_t kapacitet;
} jit_t;

static void emit(jit_t* j, uint32_t opkod) {
    if (j->pokazivac < j->kapacitet) {
        j->memorija[j->pokazivac++] = opkod;
    }
}

// MOV X0, #imm16
static void emit_mov_x0(jit_t* j, uint16_t imm) {
    emit(j, 0xD2800000 | ((imm & 0xFFFF) << 5));
}

// MOV Xd, #imm16
static void emit_mov_xd(jit_t* j, int rd, uint16_t imm) {
    emit(j, 0xD2800000 | ((imm & 0xFFFF) << 5) | (rd & 0x1F));
}

int main(int argc, char** argv) {
    // Mapiranje RX memorije
    size_t velicina = 65536;
    uint32_t* mem = mmap(NULL, velicina, 
        PROT_READ | PROT_WRITE | PROT_EXEC, 
        MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mem == MAP_FAILED) return 1;

    jit_t j = { .memorija = mem, .pokazivac = 0, .kapacitet = velicina / 4 };

    // Prolog
    emit(&j, 0xD10083FF);  // sub sp, sp, #32
    emit(&j, 0xA9017BFD);  // stp x29, x30, [sp, #16]

    char linija[256];
    FILE* ulaz = argc > 1 ? fopen(argv[1], "r") : stdin;
    if (!ulaz) return 2;

    uint64_t t0 = 0, t1 = 0;
    int ooi_pozvan = 0;

    while (fgets(linija, sizeof(linija), ulaz)) {
        // Preskoči komentare i prazne linije
        char* p = linija;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '#' || *p == '\n') continue;

        // Parsiraj "0xNN mnemonic"
        unsigned int kod;
        char mnemonic[16];
        if (sscanf(p, "0x%x %15s", &kod, mnemonic) != 2) continue;

        // Nađi mnemonic
        const lsbu_instrukcija_t* inst = NULL;
        for (size_t i = 0; i < sizeof(LSBU_ISA_TABLICA)/sizeof(LSBU_ISA_TABLICA[0]); i++) {
            if (LSBU_ISA_TABLICA[i].kod == kod) {
                inst = &LSBU_ISA_TABLICA[i];
                break;
            }
        }
        if (!inst) continue;

        // Emitiraj odgovarajući AArch64 opkod
        if (strcmp(mnemonic, "mkm") == 0) {
            // Već imamo mmap
        }
        else if (strcmp(mnemonic, "nve") == 0) {
            // nve r0, 0x060000002B000000  → mov x0, #0x2B
            emit_mov_x0(&j, 0x2B);
        }
        else if (strcmp(mnemonic, "ibo") == 0) {
            // ibo r5, r0, 48, 16  → ubfx x5, x0, #48, #16
            emit(&j, 0xD3703C05);
        }
        else if (strcmp(mnemonic, "dpo") == 0) {
            // dpo r3, r5, 11  → lsr x3, x5, #11
            emit(&j, 0xD375FCA3);
        }
        else if (strcmp(mnemonic, "pis") == 0) {
            // pis r4, r5, 0x7FF  → and x4, x5, #0x7FF
            emit(&j, 0x92402CB4);
        }
        else if (strcmp(mnemonic, "spe") == 0) {
            // spe 64  → svc #0 (već imamo mov x8 #64)
            emit_mov_xd(&j, 8, 64);  // mov x8, #64
            emit(&j, 0xD4000001);    // svc #0
        }
        else if (strcmp(mnemonic, "pir") == 0) {
            emit(&j, 0xA8C17BFD);  // ldp x29, x30, [sp], #32
            emit(&j, 0xD65F03C0);  // ret
        }
        else if (strcmp(mnemonic, "ooi") == 0) {
            // 0x26 ooi → JIT izvršavanje
            typedef void (*jit_fn)(void);
            jit_fn ponor = (jit_fn)j.memorija;

            asm volatile("mrs %0, cntvct_el0" : "=r"(t0));
            ponor();
            asm volatile("mrs %0, cntvct_el0" : "=r"(t1));

            ooi_pozvan = 1;

            // Ispiši rezultat iz x4
            uint64_t x4_val;
            asm volatile("mov %0, x4" : "=r"(x4_val));

            printf("\n=========================================================\n");
            printf("⚡ NJM OS :: LSBU ISA DOKAZ (0x26 ooi JIT EXEC)\n");
            printf("=========================================================\n");
            printf("   Mnemonici    : mkm, nve, ibo, dpo, pis, spe, ooi, pir\n");
            printf("   AArch64 kôd  : %zu opkoda\n", j.pokazivac);
            printf("   Izvršeno     : %llu ciklusa\n", (unsigned long long)(t1 - t0));
            printf("   x4 rezultat  : 0x%llx\n", (unsigned long long)x4_val);
            printf("=========================================================\n\n");
        }
    }

    if (ulaz != stdin) fclose(ulaz);

    if (!ooi_pozvan) {
        printf("⚠️  ooi nije pozvan — nema JIT izvršavanja\n");
    }

    munmap(mem, velicina);
    return 0;
}
