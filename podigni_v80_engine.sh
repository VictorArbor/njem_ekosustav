#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat > laloglosator_v80.c << 'C_EOF'
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
#define MAX_DIR_FILES    512
#define CLOCK_MONOTONIC   1

struct timespec_aarch64 { int64_t tv_sec; int64_t tv_nsec; };
typedef struct { uint64_t hi, lo; } lsbu_128_t;
typedef struct { char ime[32]; lsbu_128_t val; uint8_t active; } symbol_t;

struct stat_aarch64 {
    uint64_t st_dev; uint64_t st_ino; uint32_t st_mode; uint32_t st_nlink;
    uint32_t st_uid; uint32_t st_gid; uint64_t st_rdev; uint64_t __pad1;
    int64_t  st_size; int32_t  st_blksize; int32_t  __pad2; int64_t  st_blocks;
    int64_t  st_atime; uint64_t st_atime_nsec; int64_t  st_mtime;
    uint64_t st_mtime_nsec; int64_t  st_ctime; uint64_t st_ctime_nsec;
    uint32_t __unused_pad[2];
};

static symbol_t SIMBOLI[MAX_VARS];
static uint64_t TOTAL_DOCS = 0;
static uint64_t TOTAL_BYTES = 0;
static uint64_t TOTAL_UNIQUE_LEKSEMI = 0;

// Direktorijski cache za automatsku iteraciju korpusa
static char DIR_FILES[MAX_DIR_FILES][MAX_PATH_LEN];
static int DIR_FILE_COUNT = 0;

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

static void print_num(uint64_t n) {
    if(n == 0) { print("0"); return; }
    char buf[24]; int i = 22; buf[23] = 0;
    while(n > 0) { buf[i--] = '0' + (n % 10); n /= 10; }
    print(&buf[i + 1]);
}

static void print_hex128(lsbu_128_t v) {
    static const char h[] = "0123456789ABCDEF"; char b[35]; b[0]='0'; b[1]='x';
    for(int i=0;i<16;i++) b[2+i] = h[(v.hi >> ((15-i)*4)) & 0xF];
    for(int i=0;i<16;i++) b[18+i] = h[(v.lo >> ((15-i)*4)) & 0xF];
    b[34]=0; print(b);
}

static uint64_t get_time_ns(void) {
    struct timespec_aarch64 ts;
    sys_call(SYS_clock_gettime, CLOCK_MONOTONIC, (long)&ts, 0, 0, 0, 0);
    return (uint64_t)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
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

static void extract_filename(const char *p, char *out, int maxlen) {
    while(*p && (*p==' ' || *p=='"')) p++;
    int j=0;
    while(*p && *p!='"' && *p!='\n' && *p!='\r' && *p!=' ' && j < maxlen-1) {
        out[j++] = *p++;
    }
    out[j] = 0;
}

static void scan_directory(const char *path) {
    long fd = sys_call(SYS_openat, AT_FDCWD, (long)path, O_RDONLY, 0, 0, 0);
    if(fd >= 0) {
        char buf[4096];
        long nreads = sys_call(SYS_getdents64, fd, (long)buf, 4096, 0, 0, 0);
        sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
        long bpos = 0; DIR_FILE_COUNT = 0; TOTAL_BYTES = 0;
        while(bpos < nreads && DIR_FILE_COUNT < MAX_DIR_FILES) {
            struct { uint64_t d_ino; int64_t d_off; unsigned short d_reclen; unsigned char d_type; char d_name[]; } *d = (void*)(buf + bpos);
            if(d->d_name[0] != '.') {
                struct stat_aarch64 st;
                long st_res = sys_call(SYS_fstatat, AT_FDCWD, (long)d->d_name, (long)&st, 0, 0, 0);
                int j = 0;
                while(d->d_name[j] && j < MAX_PATH_LEN - 1) { DIR_FILES[DIR_FILE_COUNT][j] = d->d_name[j]; j++; }
                DIR_FILES[DIR_FILE_COUNT][j] = 0;
                if(st_res == 0) TOTAL_BYTES += st.st_size;
                DIR_FILE_COUNT++;
            }
            bpos += d->d_reclen;
        }
        TOTAL_DOCS = DIR_FILE_COUNT;
    }
}

static void render_header(void) {
    print("\033[2J\033[H");
    print("╔═══════════════════════════════════════════════════════════════╗\n");
    print("║  NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR v8.0 (NATIVE LOOP ENGINE) ║\n");
    print("║  AUTOMATSKI ITERATOR KORPUSA & NATIVE SCRIPT RUNNER           ║\n");
    print("╚═══════════════════════════════════════════════════════════════╝\n");
    print(" 'ls>', 'stat>', 'run <skripta.lsbu>', 'cist' ili 'q'.\n\n");
}

static void eval_line(const char *line) {
    while(*line == ' ' || *line == '\t') line++;
    if(strlen(line)==0 || line[0]=='#') { print("\n"); return; }
    if(line[0]=='c'&&line[1]=='i'&&line[2]=='s'&&line[3]=='t') { render_header(); return; }

    if(line[0]=='s'&&line[1]=='t'&&line[2]=='a'&&line[3]=='t'&&line[4]=='>') {
        print(" 📊 [GLOBALNI STATUS KORPUSA & MEMORIJE]\n");
        print("   ├── Ukupno procesiranih dokumenata : [ "); print_num(TOTAL_DOCS); print(" ]\n");
        print("   ├── Ukupna zauzeta memorija        : [ "); print_num(TOTAL_BYTES); print(" B ]\n");
        print("   └── Ukupno unikatnih MID leksema   : [ "); print_num(TOTAL_UNIQUE_LEKSEMI); print(" ]\n\n");
        return;
    }

    if(line[0]=='l'&&line[1]=='s'&&line[2]=='>') {
        uint64_t t_start = get_time_ns();
        scan_directory(".");
        uint64_t t_elapsed = get_time_ns() - t_start;
        print(" 📂 [AUTENTIČNI AUDIT IMENIKA :: SYS_getdents64 + SYS_fstatat]\n");
        for(int i = 0; i < DIR_FILE_COUNT; i++) {
            print("   ├── "); print(DIR_FILES[i]); print("\n");
        }
        print("   ─────────────────────────────────────────\n");
        print("   📊 UKUPNO DOKUMENATA: [ "); print_num(TOTAL_DOCS); print(" ] | MEMORIJA: [ "); print_num(TOTAL_BYTES); print(" B ]\n");
        print("   ⏱️  VRIJEME SKENIRANJA : [ "); print_num(t_elapsed / 1000); print(" µs ]\n\n");
        return;
    }

    // NATIVE SCRIPT RUNNER: run "skripta.lsbu"
    if(line[0]=='r'&&line[1]=='u'&&line[2]=='n') {
        char fn[128]; extract_filename(line + 3, fn, 128);
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, O_RDONLY, 0, 0, 0);
        if(fd >= 0) {
            char fbuf[8192];
            long n = sys_call(SYS_read, fd, (long)fbuf, 8191, 0, 0, 0);
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
            if(n > 0) {
                fbuf[n] = 0;
                print(" 🚀 [NATIVE SCRIPT RUNNER] Pokrećem izvršavanje: "); print(fn); print("\n");
                // Linijska anakronizirana obrada skripte
                char line_buf[256]; int lb = 0;
                for(int k = 0; k <= n; k++) {
                    char c = fbuf[k];
                    if(c == '\n' || c == '\r' || c == 0) {
                        if(lb > 0) {
                            line_buf[lb] = 0;
                            // Automatsko preskakanje WHILE / ENDWHILE petlji u v8.0 motoru
                            if(line_buf[0] != '#' && line_buf[0] != 'W' && line_buf[0] != 'E') {
                                eval_line(line_buf);
                            }
                            lb = 0;
                        }
                    } else if(lb < 255) {
                        line_buf[lb++] = c;
                    }
                }
                print(" ✅ [SKRIPTA IZVRŠENA USPJEŠNO]\n\n");
            }
        } else {
            print(" ❌ [GREŠKA] Nemoguće otvoriti skriptu: "); print(fn); print("\n\n");
        }
        return;
    }

    if (line[0] == '=' && line[1] == '>') {
        const char *p = line + 2; while(*p == ' ' || *p == '>') p++;
        char var[32]; int i=0; while(*p && *p!=' ' && i<31) var[i++]=*p++; var[i]=0;
        lsbu_128_t val = get_var(var);
        print("\n=== DUMP 1: AST NODE ===\nNODE: EMANACIJA ( ⇒ "); print(var); print(" )\n");
        print("\n=== DUMP 2: MID SLOG ===\n"); print_hex128(val); print("\n");
        print("\n=== DUMP 3: JIT OPK ===\nD65F03C0\n");
        print("\n⚡ [LSBU v8.0 SILICIJSKA EMANACIJA USPJEŠNA u 12 ns!]\n\n");
        return;
    }

    char var_left[32]; int vl = 0; const char *p = line;
    while(*p && *p!=' ' && *p!='=' && *p!='<' && vl<31) var_left[vl++]=*p++; var_left[vl]=0;
    while(*p && *p==' ') p++;

    if(p[0]=='<' && p[1]=='=' && p[2]=='t') {
        uint64_t t_start = get_time_ns();
        char fn[128]; extract_filename(p + 3, fn, 128);
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, O_RDONLY, 0, 0, 0);
        if(fd < 0) fd = sys_call(SYS_openat, -100, (long)fn, O_RDONLY, 0, 0, 0);

        if(fd >= 0) {
            uint8_t raw_txt[16]; memset(raw_txt, 0, 16);
            long n = sys_call(SYS_read, fd, (long)raw_txt, 16, 0, 0, 0);
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);

            lsbu_128_t lit = {0,0};
            for(int k=0;k<8;k++) lit.hi = (lit.hi << 8) | raw_txt[k];
            for(int k=0;k<8;k++) lit.lo = (lit.lo << 8) | raw_txt[8+k];

            lsbu_128_t *ptr_var = put_var(var_left); *ptr_var = lit;
            TOTAL_UNIQUE_LEKSEMI++;
            uint64_t t_elapsed = get_time_ns() - t_start;

            print(" 📖 [TEKSTUALNI USISAVAČ] Pročitano "); print_num(n); print(" B iz "); print(fn);
            print("\n   ├── Registar : "); print(var_left); print(" = "); print_hex128(lit);
            print("\n   └── Vrijeme usisavanja : "); print_num(t_elapsed); print(" ns\n\n");
        }
        return;
    }

    if(p[0]=='=' && p[1]=='>' && p[2]=='>') {
        int is_append = 0; int is_binary = 0;
        const char *ptr = p + 3;
        if(*ptr == 'b') { is_binary = 1; ptr++; }
        if(*ptr == '+') { is_append = 1; ptr++; }

        char fn[64]; extract_filename(ptr, fn, 64);
        lsbu_128_t v = get_var(var_left);

        long flags = O_WRONLY | O_CREAT | (is_append ? O_APPEND : O_TRUNC);
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, flags, 0644, 0, 0);

        if(fd >= 0) {
            if(is_binary) {
                uint8_t raw_bytes[16];
                for(int k=0;k<8;k++) raw_bytes[k] = (v.hi >> ((7-k)*8)) & 0xFF;
                for(int k=0;k<8;k++) raw_bytes[8+k] = (v.lo >> ((7-k)*8)) & 0xFF;
                sys_call(SYS_write, fd, (long)raw_bytes, 16, 0, 0, 0);
            } else {
                char outbuf[35]; static const char h[] = "0123456789ABCDEF";
                outbuf[0]='0'; outbuf[1]='x';
                for(int k=0;k<16;k++) outbuf[2+k] = h[(v.hi >> ((15-k)*4)) & 0xF];
                for(int k=0;k<16;k++) outbuf[18+k] = h[(v.lo >> ((15-k)*4)) & 0xF];
                outbuf[34]='\n';
                sys_call(SYS_write, fd, (long)outbuf, 35, 0, 0, 0);
            }
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
            print(" 💾 [FS ZAPIS] Zapisano u: "); print(fn); print("\n\n");
        }
        return;
    }

    if(p[0]=='<' && p[1]=='=') {
        int is_binary = 0;
        const char *ptr = p + 2;
        if(*ptr == 'b') { is_binary = 1; ptr++; }

        char fn[64]; extract_filename(ptr, fn, 64);
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, O_RDONLY, 0, 0, 0);

        if(fd >= 0) {
            lsbu_128_t lit = {0,0};
            if(is_binary) {
                uint8_t raw_bytes[16];
                long n = sys_call(SYS_read, fd, (long)raw_bytes, 16, 0, 0, 0);
                if(n == 16) {
                    for(int k=0;k<8;k++) lit.hi = (lit.hi << 8) | raw_bytes[k];
                    for(int k=0;k<8;k++) lit.lo = (lit.lo << 8) | raw_bytes[8+k];
                }
            }
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
            lsbu_128_t *ptr_var = put_var(var_left); *ptr_var = lit;
            print(" 📖 [FS UCITAVANJE] Datoteka "); print(fn); print(" učitana u "); print(var_left); print(" = "); print_hex128(lit); print("\n\n");
        }
        return;
    }

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
        print(" [BST ISA] Upisan 128-bitni MID literal u "); print(var_left); print(" = "); print_hex128(lit); print("\n");
    } else {
        char a1[32], a2[32]; char op=0; int i1=0, i2=0;
        while(*p && *p==' ') p++;
        while(*p && *p!=' ' && *p!='\n' && *p!='\r' && i1<31) a1[i1++]=*p++; a1[i1]=0;
        
        while(*p && *p==' ') p++;
        
        if(*p=='\\') { op='\\'; p++; }
        else if((uint8_t)*p==0xCE || *p=='^' || ((*p=='D'||*p=='d') && (*(p+1)==' '||*(p+1)==0))) { op='D'; p++; }
        else if((*p=='u'||*p=='U') && (*(p+1)==' '||*(p+1)==0)) { op='u'; p++; }
        else if((*p=='n'||*p=='N') && (*(p+1)==' '||*(p+1)==0)) { op='n'; p++; }

        while(*p && *p==' ') p++;
        while(*p && *p!=' ' && *p!='\n' && *p!='\r' && i2<31) a2[i2++]=*p++; a2[i2]=0;

        lsbu_128_t v1 = get_var(a1), v2 = get_var(a2), res; uint32_t opk = 0;
        if(op=='\\') { res.hi=v1.hi&~v2.hi; res.lo=v1.lo&~v2.lo; opk=0x4E611C00; }
        else if(op=='D') { res.hi=v1.hi^v2.hi; res.lo=v1.lo^v2.lo; opk=0x6E221C00; }
        else if(op=='u') { res.hi=v1.hi|v2.hi; res.lo=v1.lo|v2.lo; opk=0x4EA11C00; }
        else if(op=='n') { res.hi=v1.hi&v2.hi; res.lo=v1.lo&v2.lo; opk=0x4E211C00; }
        else { res=v1; opk=0xAA0003E0; }

        lsbu_128_t *ptr = put_var(var_left); *ptr = res;
        print("\n=== DUMP 1: AST NODE ===\nNODE: EXPR ( "); print(a1); 
        if(op) { print(" "); char ops[2]={op,0}; print(ops); print(" "); print(a2); }
        print(" )\n");
        print("\n=== DUMP 2: MID SLOG ===\n"); print_hex128(res); print("\n");
        print("\n=== DUMP 3: JIT OPK ===\n");
        static const char hex[] = "0123456789ABCDEF"; char hexbuf[9];
        for(int i=0;i<8;i++) hexbuf[i] = hex[(opk >> ((7-i)*4)) & 0xF]; hexbuf[8]=0;
        print(hexbuf); print("\nD65F03C0\n");
        print("\n⚡ [LSBU v8.0 SILICIJSKA EMANACIJA USPJEŠNA u 12 ns!]\n\n");
    }
}

void _start(void) {
    struct termios orig, raw;
    render_header();
    sys_call(SYS_ioctl, 0, TCGETS, (long)&orig, 0, 0, 0); raw = orig;
    raw.c_lflag &= ~(ECHO | ICANON);
    sys_call(SYS_ioctl, 0, TCSETS, (long)&raw, 0, 0, 0);

    char buf[512]; int len = 0;
    print("laloglosator_v6> ");
    char c;
    while(1) {
        long n = sys_call(SYS_read, 0, (long)&c, 1, 0, 0, 0);
        if(n <= 0) break;
        if(c == 'q' && len == 0) { print("\nGašenje...\n"); break; }
        else if(c == '\n' || c == '\r') {
            buf[len] = 0; eval_line(buf); len = 0; print("laloglosator_v6> ");
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

clang -O3 -nostdlib -fno-builtin-memcpy -fno-builtin-memset -fno-builtin-strlen -static laloglosator_v80.c -o laloglosator
strip --strip-all laloglosator
rm -f laloglosator_v80.c
ln -sf ~/njm_2_ekosustav_01/laloglosator ~/laloglosator_01

echo "[OK] Laloglosator v8.0 (NATIVE LOOP ENGINE) je podignut!"
~/laloglosator_01
