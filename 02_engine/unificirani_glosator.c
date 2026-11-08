#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>

/* ─── Syscall konstante ─── */
#define SYS_write 64
#define SYS_exit  93
#define SYS_mmap  222

static long sys_call(long n, long a, long b, long c, long d, long e, long f) {
    register long x8 __asm__("x8") = n;
    register long x0 __asm__("x0") = a;
    register long x1 __asm__("x1") = b;
    register long x2 __asm__("x2") = c;
    register long x3 __asm__("x3") = d;
    register long x4 __asm__("x4") = e;
    register long x5 __asm__("x5") = f;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5));
    return x0;
}

/* ─── JIT buffer ─── */
static uint32_t *jit_mem = NULL;
static size_t jit_pos = 0;

static void emit(uint32_t opkod) {
    if (jit_mem && jit_pos < 1024) {
        jit_mem[jit_pos++] = opkod;
    }
}

/* ─── MOV Xd, #imm16 ─── */
static void emit_mov_imm(int rd, uint16_t imm) {
    emit(0xD2800000 | ((imm & 0xFFFF) << 5) | (rd & 0x1F));
}

/* ─── ORR Xd, Xn, Xm ─── */
static void emit_orr(int rd, int rn, int rm) {
    emit(0xAA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}

/* ─── EOR Xd, Xn, Xm ─── */
static void emit_eor(int rd, int rn, int rm) {
    emit(0xCA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}

/* ─── SUB SP, SP, #imm ─── */
static void emit_sub_sp(uint16_t imm) {
    emit(0xD10003FF | ((imm & 0xFFF) << 10));
}

/* ─── ADD Xd, SP, #0 ─── */
static void emit_add_x_sp(int rd) {
    emit(0x91000000 | (31 << 5) | (rd & 0x1F));
}

/* ─── Izlaz ─── */
static void emit_exit(void) {
    emit(0xD2800000);  /* MOV X0, #0 */
    emit(0xD2800BA8);  /* MOV X8, #93 */
    emit(0xD4000001);  /* SVC #0 */
}

/* ─── Ispis stringa ─── */
static void ispisi_string(const char *s) {
    long len = 0;
    while (s[len]) len++;
    sys_call(SYS_write, 1, (long)s, len, 0, 0, 0);
}

/* ─── Parsiraj broj ─── */
static int parse_int(const char *s) {
    int v = 0;
    while (*s >= '0' && *s <= '9') v = v * 10 + (*s++ - '0');
    return v;
}

/* ─── Main ─── */
int main(void) {
    /* Alociraj JIT memoriju */
    jit_mem = (uint32_t *)sys_call(SYS_mmap, 0, 8192, 3, 0x22, -1, 0);
    if (!jit_mem || (long)jit_mem < 0) return 1;
    
    /* Prolog */
    emit_sub_sp(512);
    emit_add_x_sp(10);
    
    /* Čitaj .njm liniju po liniju */
    char linija[512];
    while (fgets(linija, sizeof(linija), stdin)) {
        /* Preskoči komentare i prazne */
        char *p = linija;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '#' || *p == '\n' || *p == '\0') continue;
        
        /* mkm r10 — već u prologu */
        if (strncmp(p, "mkm ", 4) == 0) continue;
        
        /* wrt 1, "..." — ispis */
        if (strncmp(p, "wrt ", 4) == 0) {
            char *q1 = strchr(p, '"');
            char *q2 = q1 ? strchr(q1 + 1, '"') : NULL;
            if (q1 && q2) {
                *q2 = '\0';
                /* Konvertiraj \n */
                for (char *c = q1 + 1; *c; c++) {
                    if (*c == '\\' && *(c + 1) == 'n') {
                        *c = '\n';
                        memmove(c + 1, c + 2, strlen(c + 2) + 1);
                    }
                }
                ispisi_string(q1 + 1);
            }
            continue;
        }
        
        /* nve rN, IMM — konstanta */
        if (strncmp(p, "nve ", 4) == 0) {
            int rd, imm;
            if (sscanf(p + 4, "r%d, %d", &rd, &imm) == 2) {
                emit_mov_imm(rd, imm);
            }
            continue;
        }
        
        /* uis rD, rN, rM — ORR */
        if (strncmp(p, "uis ", 4) == 0) {
            int rd, rn, rm;
            if (sscanf(p + 4, "r%d, r%d, r%d", &rd, &rn, &rm) == 3) {
                emit_orr(rd, rn, rm);
            }
            continue;
        }
        
        /* srs rD, rN, rM — EOR */
        if (strncmp(p, "srs ", 4) == 0) {
            int rd, rn, rm;
            if (sscanf(p + 4, "r%d, r%d, r%d", &rd, &rn, &rm) == 3) {
                emit_eor(rd, rn, rm);
            }
            continue;
        }
        
        /* pir — izlaz */
        if (strncmp(p, "pir", 3) == 0) {
            emit_exit();
            break;
        }
    }
    
    /* Provjeri ima li exit na kraju */
    if (jit_pos > 0 && jit_mem[jit_pos - 1] != 0xD4000001) {
        emit_exit();
    }
    
    /* Debug: ispisi generirane opkode */
    fprintf(stderr, "[DEBUG] Generirano %zu opkoda\n", jit_pos);
    for (size_t i = 0; i < jit_pos; i++) {
        fprintf(stderr, "  [%zu] 0x%08X\n", i, jit_mem[i]);
    }
    
    /* mprotect na RX */
    sys_call(226, (long)jit_mem, 8192, 5, 0, 0, 0);  /* mprotect RX */
    
    /* Izvrši */
    typedef void (*fn_t)(void);
    fn_t fn = (fn_t)jit_mem;
    fn();
    
    return 0;
}
