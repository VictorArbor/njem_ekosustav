#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>

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

static uint32_t *jit_mem = NULL;
static size_t jit_pos = 0;

static void emit(uint32_t op) {
    if (jit_mem && jit_pos < 4096) jit_mem[jit_pos++] = op;
}

/* AArch64 emit funkcije */
static void emit_mov_imm(int rd, uint16_t imm) {
    emit(0xD2800000 | ((imm & 0xFFFF) << 5) | (rd & 0x1F));
}
static void emit_orr(int rd, int rn, int rm) {
    emit(0xAA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_eor(int rd, int rn, int rm) {
    emit(0xCA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_and(int rd, int rn, int rm) {
    emit(0x8A000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_bic(int rd, int rn, int rm) {
    emit(0x8A200000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_lsr_imm(int rd, int rn, int imm) {
    emit(0xD3400000 | ((imm & 0x3F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_lsl_imm(int rd, int rn, int imm) {
    emit(0xD3400000 | (0x1F << 16) | ((imm & 0x3F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_ubfx(int rd, int rn, int lsb, int width) {
    emit(0x53000000 | (((width-1) & 0x3F) << 16) | (((lsb) & 0x3F) << 10) | ((rn & 0x1F) << 5) | (rd & 0x1F));
}
static void emit_sub_sp(uint16_t imm) {
    emit(0xD10003FF | ((imm & 0xFFF) << 10));
}
static void emit_add_x_sp(int rd) {
    emit(0x91000000 | (31 << 5) | (rd & 0x1F));
}
static void emit_exit(void) {
    emit(0xD2800000);
    emit(0xD2800BA8);
    emit(0xD4000001);
}

static void ispisi_string(const char *s) {
    long len = 0;
    while (s[len]) len++;
    sys_call(SYS_write, 1, (long)s, len, 0, 0, 0);
}

static void ispisi_broj(int n) {
    char buf[16];
    int i = 0, neg = 0;
    if (n < 0) { neg = 1; n = -n; }
    if (n == 0) buf[i++] = '0';
    while (n > 0) { buf[i++] = '0' + (n % 10); n /= 10; }
    if (neg) buf[i++] = '-';
    for (int j = 0; j < i / 2; j++) {
        char t = buf[j]; buf[j] = buf[i-1-j]; buf[i-1-j] = t;
    }
    buf[i] = '\0';
    ispisi_string(buf);
}

static int parse_int(const char *s) {
    int v = 0, neg = 0;
    if (*s == '-') { neg = 1; s++; }
    while (*s >= '0' && *s <= '9') v = v * 10 + (*s++ - '0');
    return neg ? -v : v;
}

int main(void) {
    jit_mem = (uint32_t *)sys_call(SYS_mmap, 0, 16384, 3, 0x22, -1, 0);
    if (!jit_mem || (long)jit_mem < 0) return 1;
    
    emit_sub_sp(512);
    emit_add_x_sp(10);
    
    char linija[512];
    while (fgets(linija, sizeof(linija), stdin)) {
        char *p = linija;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '#' || *p == '\n' || *p == '\0') continue;
        
        /* mkm */
        if (strncmp(p, "mkm", 3) == 0) continue;
        
        /* wrt */
        if (strncmp(p, "wrt ", 4) == 0) {
            char *q1 = strchr(p, '"');
            char *q2 = q1 ? strchr(q1 + 1, '"') : NULL;
            if (q1 && q2) {
                *q2 = '\0';
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
        
        /* nve */
        if (strncmp(p, "nve ", 4) == 0) {
            int rd, imm;
            if (sscanf(p + 4, "r%d, %d", &rd, &imm) == 2) emit_mov_imm(rd, imm);
            continue;
        }
        
        /* uis / ORR */
        if (strncmp(p, "uis ", 4) == 0) {
            int rd, rn, rm;
            if (sscanf(p + 4, "r%d, r%d, r%d", &rd, &rn, &rm) == 3) emit_orr(rd, rn, rm);
            continue;
        }
        
        /* srs / EOR */
        if (strncmp(p, "srs ", 4) == 0) {
            int rd, rn, rm;
            if (sscanf(p + 4, "r%d, r%d, r%d", &rd, &rn, &rm) == 3) emit_eor(rd, rn, rm);
            continue;
        }
        
        /* pis / AND */
        if (strncmp(p, "pis ", 4) == 0) {
            int rd, rn, rm;
            if (sscanf(p + 4, "r%d, r%d, r%d", &rd, &rn, &rm) == 3) emit_and(rd, rn, rm);
            continue;
        }
        
        /* ris / BIC */
        if (strncmp(p, "ris ", 4) == 0) {
            int rd, rn, rm;
            if (sscanf(p + 4, "r%d, r%d, r%d", &rd, &rn, &rm) == 3) emit_bic(rd, rn, rm);
            continue;
        }
        
        /* dpo / LSR */
        if (strncmp(p, "dpo ", 4) == 0) {
            int rd, rn, imm;
            if (sscanf(p + 4, "r%d, r%d, %d", &rd, &rn, &imm) == 3) emit_lsr_imm(rd, rn, imm);
            continue;
        }
        
        /* lpo / LSL */
        if (strncmp(p, "lpo ", 4) == 0) {
            int rd, rn, imm;
            if (sscanf(p + 4, "r%d, r%d, %d", &rd, &rn, &imm) == 3) emit_lsl_imm(rd, rn, imm);
            continue;
        }
        
        /* ibo / UBFX */
        if (strncmp(p, "ibo ", 4) == 0) {
            int rd, rn, lsb, width;
            if (sscanf(p + 4, "r%d, r%d, %d, %d", &rd, &rn, &lsb, &width) == 4) emit_ubfx(rd, rn, lsb, width);
            continue;
        }
        
        /* pir */
        if (strncmp(p, "pir", 3) == 0) {
            emit_exit();
            break;
        }
    }
    
    if (jit_pos > 0 && jit_mem[jit_pos - 1] != 0xD4000001) {
        emit_exit();
    }
    
    fprintf(stderr, "[DEBUG] %zu opkoda\n", jit_pos);
    
    /* W^X: mprotect RX */
    sys_call(226, (long)jit_mem, 16384, 5, 0, 0, 0);
    
    /* Izvrši */
    typedef void (*fn_t)(void);
    fn_t fn = (fn_t)jit_mem;
    fn();
    
    return 0;
}
