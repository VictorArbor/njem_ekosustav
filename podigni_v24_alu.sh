#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat > laloglosator_v24.c << 'C_EOF'
#include <stdint.h>
#include <termios.h>

#define SYS_read          63
#define SYS_write         64
#define SYS_openat        56
#define SYS_close         57
#define SYS_exit          93
#define SYS_ioctl         29
#define SYS_getdents64    61
#define SYS_fstatat       79
#define SYS_clock_gettime 113

#define AT_FDCWD         -100
#define O_RDONLY          0
#define O_WRONLY          1
#define O_CREAT           64
#define O_TRUNC           512
#define O_APPEND          1024

#define MAX_VARS          64
#define MAX_PATH_LEN     128
#define CLOCK_MONOTONIC   1

struct timespec_aarch64 { int64_t tv_sec; int64_t tv_nsec; };
typedef struct { uint64_t hi, lo; } lsbu_128_t;
typedef struct { char ime[32]; lsbu_128_t val; uint8_t active; } symbol_t;

static symbol_t SIMBOLI[MAX_VARS];

__attribute__((no_builtin("memcpy")))
void *memcpy(void *dest, const void *src, unsigned long n) {
    char *d = (char *)dest; const char *s = (const char *)src;
    while (n--) *d++ = *s++; return dest;
}

__attribute__((no_builtin("memset")))
void *memset(void *s, int c, unsigned long n) {
    unsigned char *p = (unsigned char *)s;
    while (n--) *p++ = (unsigned char)c; return s;
}

__attribute__((no_builtin("strlen")))
unsigned long strlen(const char *s) {
    unsigned long l = 0; while (s[l]) l++; return l;
}

static long sys_call(long n, long a, long b, long c, long d, long e, long f) {
    register long x8 __asm__("x8") = n, x0 __asm__("x0") = a, x1 __asm__("x1") = b;
    register long x2 __asm__("x2") = c, x3 __asm__("x3") = d, x4 __asm__("x4") = e, x5 __asm__("x5") = f;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5));
    return x0;
}

static void print(const char *s) { sys_call(SYS_write, 1, (long)s, strlen(s), 0, 0, 0); }

static void print_hex128(lsbu_128_t v) {
    static const char h[] = "0123456789ABCDEF"; char b[35]; b[0]='0'; b[1]='x';
    for(int i=0;i<16;i++) b[2+i] = h[(v.hi >> ((15-i)*4)) & 0xF];
    for(int i=0;i<16;i++) b[18+i] = h[(v.lo >> ((15-i)*4)) & 0xF];
    b[34]=0; print(b);
}

static int streq(const char *a, const char *b) {
    while(*a && *b) { if(*a != *b) return 0; a++; b++; } return *a == *b;
}

static lsbu_128_t* put_var(const char *name) {
    for(int i=0;i<MAX_VARS;i++) if(SIMBOLI[i].active && streq(SIMBOLI[i].ime, name)) return &SIMBOLI[i].val;
    for(int i=0;i<MAX_VARS;i++) if(!SIMBOLI[i].active) {
        int j=0; while(name[j] && j<31) { SIMBOLI[i].ime[j]=name[j]; j++; }
        SIMBOLI[i].ime[j]=0; SIMBOLI[i].active=1; return &SIMBOLI[i].val;
    }
    return &SIMBOLI[0].val;
}

static lsbu_128_t get_var(const char *name) {
    for(int i=0;i<MAX_VARS;i++) if(SIMBOLI[i].active && streq(SIMBOLI[i].ime, name)) return SIMBOLI[i].val;
    lsbu_128_t z = {0,0}; return z;
}

static void render_header(void) {
    print("\033[2J\033[H");
    print("╔═══════════════════════════════════════════════════════════════╗\n");
    print("║  NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR v24.0 (NATATIVE ALU MUL)  ║\n");
    print("║  PUNOPRAVNI ARITMETIČKI OPERATOR (*) U JEZGRI                 ║\n");
    print("╚═══════════════════════════════════════════════════════════════╝\n\n");
}

static void eval_line(const char *line) {
    while(*line == ' ' || *line == '\t') line++;
    if(strlen(line)==0 || line[0]=='#') { print("\n"); return; }

    if (line[0] == '=' && line[1] == '>') {
        const char *p = line + 2; while(*p == ' ' || *p == '>') p++;
        char var[32]; int i=0; while(*p && *p!=' ' && i<31) var[i++]=*p++; var[i]=0;
        lsbu_128_t val = get_var(var);
        print("\n=== EMANACIJA ===\n"); print_hex128(val); print("\n\n");
        return;
    }

    char var_left[32]; int vl = 0; const char *p = line;
    while(*p && *p!=' ' && *p!='=' && *p!='<' && vl<31) var_left[vl++]=*p++; var_left[vl]=0;
    while(*p && *p==' ') p++;
    while(*p && (*p==' '||*p=='=')) p++;

    if(*p=='0' && (*(p+1)=='x'||*(p+1)=='X')) {
        lsbu_128_t lit = {0, 0};
        p += 2; char cl[33]; int l=0;
        while(*p && l<32) {
            char c = *p;
            if((c>='0'&&c<='9')||(c>='A'&&c<='F')||(c>='a'&&c<='f')) cl[l++] = c;
            else if(c==' '||c=='\t'||c=='\n'||c=='#') break;
            p++;
        }
        cl[l]=0; int pad=32-l;
        for(int i=0;i<l;i++) {
            uint64_t v = (cl[i]>='0'&&cl[i]<='9')?cl[i]-'0':(cl[i]>='A'&&cl[i]<='F')?cl[i]-'A'+10:cl[i]-'a'+10;
            int pos = pad + i; if(pos<16) lit.hi = (lit.hi<<4)|v; else lit.lo = (lit.lo<<4)|v;
        }
        lsbu_128_t *ptr = put_var(var_left); *ptr = lit;
        print(" [BST ISA] Literal upisan u "); print(var_left); print(" = "); print_hex128(lit); print("\n");
    } else {
        char a1[32], a2[32]; char op=0; int i1=0, i2=0;
        while(*p && *p==' ') p++;
        while(*p && *p!=' ' && *p!='\n' && *p!='\r' && i1<31) a1[i1++]=*p++; a1[i1]=0;
        while(*p && *p==' ') p++;

        if(*p=='\\') { op='\\'; p++; }
        else if(*p=='*') { op='*'; p++; }
        else if((*p=='D'||*p=='d') && (*(p+1)==' '||*(p+1)==0)) { op='D'; p++; }
        else if((*p=='u'||*p=='U') && (*(p+1)==' '||*(p+1)==0)) { op='u'; p++; }
        else if((*p=='n'||*p=='N') && (*(p+1)==' '||*(p+1)==0)) { op='n'; p++; }

        while(*p && *p==' ') p++;
        while(*p && *p!=' ' && *p!='\n' && *p!='\r' && i2<31) a2[i2++]=*p++; a2[i2]=0;

        lsbu_128_t v1 = get_var(a1), v2 = get_var(a2), res;
        
        if(op=='*') {
            // PRAVO ARITMETIČKO MNOŽENJE PREKO __int128 U JADRU
            unsigned __int128 val1 = ((unsigned __int128)v1.hi << 64) | v1.lo;
            unsigned __int128 val2 = ((unsigned __int128)v2.hi << 64) | v2.lo;
            unsigned __int128 r = val1 * val2;
            res.hi = (uint64_t)(r >> 64);
            res.lo = (uint64_t)r;
        } else if(op=='\\') { res.hi=v1.hi&~v2.hi; res.lo=v1.lo&~v2.lo; }
        else if(op=='D') { res.hi=v1.hi^v2.hi; res.lo=v1.lo^v2.lo; }
        else if(op=='u') { res.hi=v1.hi|v2.hi; res.lo=v1.lo|v2.lo; }
        else if(op=='n') { res.hi=v1.hi&v2.hi; res.lo=v1.lo&v2.lo; }
        else { res=v1; }

        lsbu_128_t *ptr = put_var(var_left); *ptr = res;
        print("\n=== ARITMETIČKI REZULTAT ("); print(a1); print(" "); 
        char ops[2]={op?op:'=',0}; print(ops); print(" "); print(a2); print(") ===\n");
        print_hex128(res); print("\n\n");
    }
}

void _start(void) {
    struct termios orig, raw;
    render_header();
    sys_call(SYS_ioctl, 0, TCGETS, (long)&orig, 0, 0, 0); raw = orig;
    raw.c_lflag &= ~(ECHO | ICANON);
    sys_call(SYS_ioctl, 0, TCSETS, (long)&raw, 0, 0, 0);

    char buf[512]; int len = 0;
    print("laloglosator_v24> ");
    char c;
    while(1) {
        long n = sys_call(SYS_read, 0, (long)&c, 1, 0, 0, 0);
        if(n <= 0) break;
        if(c == 'q' && len == 0) { print("\nGašenje...\n"); break; }
        else if(c == '\n' || c == '\r') {
            buf[len] = 0; eval_line(buf); len = 0; print("laloglosator_v24> ");
        } else if((c == 127 || c == 8) && len > 0) {
            len--; print("\b \b");
        } else if(len < 500) {
            buf[len++] = c; char e[2] = {c, 0}; print(e);
        }
    }
    sys_call(SYS_ioctl, 0, TCSETS, (long)&orig, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -fno-builtin-memcpy -fno-builtin-memset -fno-builtin-strlen -static laloglosator_v24.c -o laloglosator
strip --strip-all laloglosator
rm -f laloglosator_v24.c
echo "[OK] Laloglosator v24.0 s ugrađenim množenjem (*) je spreman!"
~/njm_2_ekosustav_01/laloglosator
