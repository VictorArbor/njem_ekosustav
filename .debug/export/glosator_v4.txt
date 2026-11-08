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

/* ─── SVE EMIT FUNKCIJE ─── */
static void emit_mov_imm(int rd, uint16_t imm) { emit(0xD2800000 | ((imm & 0xFFFF) << 5) | (rd & 0x1F)); }
static void emit_orr(int rd, int rn, int rm)    { emit(0xAA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_eor(int rd, int rn, int rm)    { emit(0xCA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_and(int rd, int rn, int rm)    { emit(0x8A000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_bic(int rd, int rn, int rm)    { emit(0x8A200000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_lsr_imm(int rd, int rn, int imm) { emit(0xD3400000 | ((imm & 0x3F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_lsl_imm(int rd, int rn, int imm) { emit(0xD3400000 | (0x3F << 16) | ((imm & 0x3F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_ubfx(int rd, int rn, int lsb, int width) { emit(0x53000000 | (((width-1) & 0x3F) << 16) | ((lsb & 0x3F) << 10) | ((rn & 0x1F) << 5) | (rd & 0x1F)); }
static void emit_strb(int rt, int rn, int off) { emit(0x39000000 | ((off & 0xFFF) << 10) | ((rn & 0x1F) << 5) | (rt & 0x1F)); }
static void emit_ldrb(int rt, int rn, int off) { emit(0x39400000 | ((off & 0xFFF) << 10) | ((rn & 0x1F) << 5) | (rt & 0x1F)); }
static void emit_cmp(int rn, int rm)            { emit(0xEB00001F | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5)); }
static void emit_cbz(int rt, int off)           { emit(0xB4000000 | ((off & 0x7FFFF) << 5) | (rt & 0x1F)); }
static void emit_cbnz(int rt, int off)          { emit(0xB5000000 | ((off & 0x7FFFF) << 5) | (rt & 0x1F)); }
static void emit_mov_reg(int rd, int rn)        { emit(0xAA0003E0 | ((rn & 0x1F) << 16) | (rd & 0x1F)); }
static void emit_nop(void)                       { emit(0xD503201F); }
static void emit_ret(void)                       { emit(0xD65F03C0); }
static void emit_sub_sp(uint16_t imm)            { emit(0xD10003FF | ((imm & 0xFFF) << 10)); }
static void emit_add_x_sp(int rd)                { emit(0x91000000 | (31 << 5) | (rd & 0x1F)); }


/* ─── 10 NOVIH MNEMONIKA ─── */

/* CBZ Xn, offset — gjn */

/* CBNZ Xn, offset — gnn */

/* B.cond offset — guo (uvjet = 0 za sada) */
static void emit_b_cond(int cond, int off) {
    emit(0x54000000 | ((off & 0x7FFFF) << 5) | (cond & 0xF));
}

/* BL offset — ppo */
static void emit_bl(int off) {
    emit(0x94000000 | (off & 0x3FFFFFF));
}

/* B offset — pio */
static void emit_b(int off) {
    emit(0x14000000 | (off & 0x3FFFFFF));
}

/* RET — pps, pos */

/* DSB SY — bar */
static void emit_bar(void) {
    emit(0xD5033F9F);
}

/* SVC #0 — spe */
static void emit_svc(int sys_num) {
    emit_mov_imm(8, sys_num);
    emit(0xD4000001);
}

/* BLR Xn — ooi */
static void emit_blr(int rn) {
    emit(0xD63F0000 | ((rn & 0x1F) << 5));
}

/* STP XZR, XZR, [Xn] — pkm (simplificirano) */
static void emit_memset(int rn) {
    emit(0xA9007FE0 | ((rn & 0x1F) << 5));
}

/* ─── NASTAVAK ─── */

/* NEON 128-bit V.16B */
static void emit_vand(int vd, int vn, int vm) { emit(0x4E201C00 | ((vm & 0x1F) << 16) | ((vn & 0x1F) << 5) | (vd & 0x1F)); }
static void emit_vorr(int vd, int vn, int vm) { emit(0x4EA01C00 | ((vm & 0x1F) << 16) | ((vn & 0x1F) << 5) | (vd & 0x1F)); }
static void emit_vbic(int vd, int vn, int vm) { emit(0x4E601C00 | ((vm & 0x1F) << 16) | ((vn & 0x1F) << 5) | (vd & 0x1F)); }
static void emit_veor(int vd, int vn, int vm) { emit(0x6E201C00 | ((vm & 0x1F) << 16) | ((vn & 0x1F) << 5) | (vd & 0x1F)); }

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

/* Preskoči "v" ili "r" prefiks */
static int parse_reg(const char *s) {
    while (*s == 'r' || *s == 'v' || *s == 'R' || *s == 'V' || *s == ' ') s++;
    return atoi(s);
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
                    if (*c == '\\' && *(c + 1) == 'n') { *c = '\n'; memmove(c + 1, c + 2, strlen(c + 2) + 1); }
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
        
        /* pje */
        if (strncmp(p, "pje ", 4) == 0) {
            int rd, rn;
            if (sscanf(p + 4, "r%d, r%d", &rd, &rn) == 2) emit_mov_reg(rd, rn);
            continue;
        }
        
        /* Skalarne skupovne */
        if (strncmp(p, "uis ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, r%d", &a,&b,&c)==3) emit_orr(a,b,c); continue; }
        if (strncmp(p, "srs ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, r%d", &a,&b,&c)==3) emit_eor(a,b,c); continue; }
        if (strncmp(p, "pis ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, r%d", &a,&b,&c)==3) emit_and(a,b,c); continue; }
        if (strncmp(p, "ris ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, r%d", &a,&b,&c)==3) emit_bic(a,b,c); continue; }
        
        /* NEON 128-bit */
        if (strncmp(p, "vus ", 4) == 0) { int a,b,c; if (sscanf(p+4, "v%d, v%d, v%d", &a,&b,&c)==3) emit_vorr(a,b,c); continue; }
        if (strncmp(p, "vss ", 4) == 0) { int a,b,c; if (sscanf(p+4, "v%d, v%d, v%d", &a,&b,&c)==3) emit_veor(a,b,c); continue; }
        if (strncmp(p, "vps ", 4) == 0) { int a,b,c; if (sscanf(p+4, "v%d, v%d, v%d", &a,&b,&c)==3) emit_vand(a,b,c); continue; }
        if (strncmp(p, "vrs ", 4) == 0) { int a,b,c; if (sscanf(p+4, "v%d, v%d, v%d", &a,&b,&c)==3) emit_vbic(a,b,c); continue; }
        
        /* Bit manipulacija */
        if (strncmp(p, "dpo ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, %d", &a,&b,&c)==3) emit_lsr_imm(a,b,c); continue; }
        if (strncmp(p, "lpo ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, %d", &a,&b,&c)==3) emit_lsl_imm(a,b,c); continue; }
        if (strncmp(p, "ibo ", 4) == 0) { int a,b,c,d; if (sscanf(p+4, "r%d, r%d, %d, %d", &a,&b,&c,&d)==4) emit_ubfx(a,b,c,d); continue; }
        
        /* Memorija */
        if (strncmp(p, "ssb ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, %d", &a,&b,&c)==3) emit_strb(a,b,c); continue; }
        if (strncmp(p, "ujb ", 4) == 0) { int a,b,c; if (sscanf(p+4, "r%d, r%d, %d", &a,&b,&c)==3) emit_ldrb(a,b,c); continue; }
        
        /* Usporedba i grananje */
        if (strncmp(p, "ume ", 4) == 0) { int a,b; if (sscanf(p+4, "r%d, r%d", &a,&b)==2) emit_cmp(a,b); continue; }
        
        /* NOP, RET */
        if (strncmp(p, "nno", 3) == 0) { emit_nop(); continue; }
        
        /* pir */

        /* Kontrola toka */
        if (strncmp(p, "gjn ", 4) == 0) { int a, b; if (sscanf(p+4, "r%d, %d", &a, &b)==2) emit_cbz(a, b); continue; }
        if (strncmp(p, "gnn ", 4) == 0) { int a, b; if (sscanf(p+4, "r%d, %d", &a, &b)==2) emit_cbnz(a, b); continue; }
        if (strncmp(p, "guo ", 4) == 0) { int a, b; if (sscanf(p+4, "%d, %d", &a, &b)==2) emit_b_cond(a, b); continue; }
        if (strncmp(p, "ppo ", 4) == 0) { int a; if (sscanf(p+4, "%d", &a)==1) emit_bl(a); continue; }
        if (strncmp(p, "pio ", 4) == 0) { int a; if (sscanf(p+4, "%d", &a)==1) emit_b(a); continue; }

        /* RET */
        if (strncmp(p, "pps", 3) == 0) { emit_ret(); continue; }
        if (strncmp(p, "pos", 3) == 0) { emit_ret(); continue; }

        /* Barijera */
        if (strncmp(p, "bar", 3) == 0) { emit_bar(); continue; }

        /* Syscall */
        if (strncmp(p, "spe ", 4) == 0) { int a; if (sscanf(p+4, "%d", &a)==1) emit_svc(a); continue; }

        /* JIT */
        if (strncmp(p, "ooi ", 4) == 0) { int a; if (sscanf(p+4, "r%d", &a)==1) emit_blr(a); continue; }

        /* Memset */
        if (strncmp(p, "pkm ", 4) == 0) { int a; if (sscanf(p+4, "r%d", &a)==1) emit_memset(a); continue; }

        /* pir */
        if (strncmp(p, "pir", 3) == 0) { emit_exit(); break; }
    }
    
    if (jit_pos > 0 && jit_mem[jit_pos - 1] != 0xD4000001) emit_exit();
    
    fprintf(stderr, "[DEBUG] %zu opkoda\n", jit_pos);
    sys_call(226, (long)jit_mem, 16384, 5, 0, 0, 0);
    
    typedef void (*fn_t)(void);
    fn_t fn = (fn_t)jit_mem;
    fn();
    return 0;
}