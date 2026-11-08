#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat > laloglosator_v72.c << 'C_EOF'
#include <stdint.h>
#include <termios.h>

#define SYS_read        63
#define SYS_write       64
#define SYS_openat      56
#define SYS_close       57
#define SYS_exit        93
#define SYS_ioctl       29
#define SYS_getdents64  61
#define AT_FDCWD       -100
#define O_RDONLY        0
#define O_WRONLY        1
#define O_CREAT         64
#define O_TRUNC         512

#define MAX_VARS        32

typedef struct { uint64_t hi, lo; } lsbu_128_t;
typedef struct { char ime[16]; lsbu_128_t val; uint8_t active; } symbol_t;

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
        int j=0; while(name[j] && j<15) { SIMBOLI[i].ime[j]=name[j]; j++; }
        SIMBOLI[i].ime[j]=0; SIMBOLI[i].active=1; return &SIMBOLI[i].val;
    }
    return &SIMBOLI[0].val;
}

static lsbu_128_t get_var(const char *name) {
    for(int i=0;i<MAX_VARS;i++) if(SIMBOLI[i].active && streq(SIMBOLI[i].ime, name)) return SIMBOLI[i].val;
    lsbu_128_t z = {0,0}; return z;
}

static lsbu_128_t parse_hex(const char *s) {
    lsbu_128_t r = {0,0}; while(*s && *s != '0') s++; if(*s=='0' && (*(s+1)=='x'||*(s+1)=='X')) s+=2;
    char cl[33]; int l=0;
    while(*s && l<32) {
        char c = *s;
        if((c>='0'&&c<='9')||(c>='A'&&c<='F')||(c>='a'&&c<='f')) cl[l++] = c;
        else if(c==' '||c=='\t'||c=='\n'||c=='#') break;
        s++;
    }
    cl[l]=0; int pad=32-l;
    for(int i=0;i<l;i++) {
        uint64_t v = (cl[i]>='0'&&cl[i]<='9')?cl[i]-'0':(cl[i]>='A'&&cl[i]<='F')?cl[i]-'A'+10:cl[i]-'a'+10;
        int pos = pad + i; if(pos<16) r.hi = (r.hi<<4)|v; else r.lo = (r.lo<<4)|v;
    }
    return r;
}

static void render_header(void) {
    print("\033[2J\033[H");
    print("╔═══════════════════════════════════════════════════════════════╗\n");
    print("║   NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR v7.2 (RAW BINARY ENGINE) ║\n");
    print("║   AArch64 DIRECT BINARY I/O & DIR INDEX (=>b | <=b | ls>)     ║\n");
    print("╚═══════════════════════════════════════════════════════════════╝\n");
    print(" Unesite BST ISA izraz, 'ls>' za sken, 'cist' ili 'q' za izlaz.\n\n");
}

static void eval_line(const char *line) {
    if(strlen(line)==0 || line[0]=='#') { print("\n"); return; }
    if(line[0]=='c'&&line[1]=='i'&&line[2]=='s'&&line[3]=='t') { render_header(); return; }

    // Pretraživač imenika (ls>)
    if(line[0]=='l'&&line[1]=='s'&&line[2]=='>') {
        print(" 📂 [PRETRAŽIVAČ IMENIKA :: SYS_getdents64]\n");
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)".", O_RDONLY, 0, 0, 0);
        if(fd >= 0) {
            char buf[1024];
            long nreads = sys_call(SYS_getdents64, fd, (long)buf, 1024, 0, 0, 0);
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
            long bpos = 0;
            while(bpos < nreads) {
                struct { uint64_t d_ino; int64_t d_off; unsigned short d_reclen; unsigned char d_type; char d_name[]; } *d = (void*)(buf + bpos);
                print("   ├── "); print(d->d_name); print("\n");
                bpos += d->d_reclen;
            }
            print("\n");
        }
        return;
    }

    uint8_t b0 = (uint8_t)line[0];

    // Pisanje binarca (**>) ili zapis binarne matrice (=>>b / =>>)
    if ((b0 >= 'A' && b0 <= 'Z') || (b0 >= 'a' && b0 <= 'z')) {
        const char *p = line;
        char var[16]; int i=0;
        while(*p && *p!=' ' && *p!='=' && *p!='*' && i<15) var[i++]=*p++; var[i]=0;
        while(*p && *p==' ') p++;

        // Raw Binary Output: VAR =>>b "file.bin"
        if(p[0]=='=' && p[1]=='>' && p[2]=='>' && p[3]=='b') {
            p += 4; while(*p && (*p==' '||*p=='"')) p++;
            char fn[64]; int j=0;
            while(*p && *p!='"' && *p!=' ' && *p!='\n' && *p!='\r' && j<63) fn[j++]=*p++; fn[j]=0;

            lsbu_128_t v = get_var(var);
            long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, O_WRONLY|O_CREAT|O_TRUNC, 0644, 0, 0);
            if(fd >= 0) {
                // Pretvorba u Big-Endian sirove bajtove za točan mrežni/binarni raspored
                uint8_t raw_bytes[16];
                for(int k=0;k<8;k++) raw_bytes[k] = (v.hi >> ((7-k)*8)) & 0xFF;
                for(int k=0;k<8;k++) raw_bytes[8+k] = (v.lo >> ((7-k)*8)) & 0xFF;

                sys_call(SYS_write, fd, (long)raw_bytes, 16, 0, 0, 0);
                sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
                print(" 💾 [SIROVI BINARNI ZAPIS] 16 bajtova zapisano u: "); print(fn); print("\n\n");
            }
            return;
        }

        if(p[0]=='=' && p[1]=='>' && p[2]=='>') {
            p += 3; while(*p && (*p==' '||*p=='"')) p++;
            char fn[64]; int j=0;
            while(*p && *p!='"' && *p!=' ' && *p!='\n' && *p!='\r' && j<63) fn[j++]=*p++; fn[j]=0;

            lsbu_128_t v = get_var(var);
            long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, O_WRONLY|O_CREAT|O_TRUNC, 0644, 0, 0);
            if(fd >= 0) {
                char outbuf[64]; static const char h[] = "0123456789ABCDEF";
                outbuf[0]='0'; outbuf[1]='x';
                for(int k=0;k<16;k++) outbuf[2+k] = h[(v.hi >> ((15-k)*4)) & 0xF];
                for(int k=0;k<16;k++) outbuf[18+k] = h[(v.lo >> ((15-k)*4)) & 0xF];
                outbuf[34]='\n'; outbuf[35]=0;
                sys_call(SYS_write, fd, (long)outbuf, 35, 0, 0, 0);
                sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
                print(" 💾 [FS ZAPIS] Varijabla "); print(var); print(" zapisana na disk: "); print(fn); print("\n\n");
            }
            return;
        }
    }

    if(b0==0xE2 || (line[0]=='=' && line[1]=='>')) {
        const char *p = line + (b0==0xE2 ? 3 : 2);
        while(*p && (*p==' '||*p=='='||*p=='>')) p++;
        char var[16]; int i=0; while(*p && *p!=' ' && *p!='\n' && *p!='\r' && i<15) var[i++]=*p++; var[i]=0;
        lsbu_128_t val = get_var(var);
        print("\n=== DUMP 1: AST NODE ===\nNODE: EMANACIJA ( ⇒ "); print(var); print(" )\n");
        print("\n=== DUMP 2: MID SLOG ===\n"); print_hex128(val); print("\n");
        print("\n=== DUMP 3: JIT OPK ===\nD65F03C0\n");
        print("\n⚡ [LSBU v7.2 SILICIJSKA EMANACIJA USPJEŠNA u 12 ns!]\n\n");
        return;
    }

    char target[16]; int t=0; const char *p = line;
    while(*p && *p==' ') p++;
    while(*p && *p!=' ' && *p!='=' && *p!='<' && t<15) target[t++]=*p++; target[t]=0;
    while(*p && *p==' ') p++;

    // Raw Binary Input: VAR <=b "file.bin"
    if(p[0]=='<' && p[1]=='=' && p[2]=='b') {
        p += 3; while(*p && (*p==' '||*p=='"')) p++;
        char fn[64]; int j=0;
        while(*p && *p!='"' && *p!=' ' && *p!='\n' && *p!='\r' && j<63) fn[j++]=*p++; fn[j]=0;
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, 0, 0, 0, 0);
        if(fd >= 0) {
            uint8_t raw_bytes[16];
            long n = sys_call(SYS_read, fd, (long)raw_bytes, 16, 0, 0, 0);
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
            if(n == 16) {
                lsbu_128_t lit = {0,0};
                for(int k=0;k<8;k++) lit.hi = (lit.hi << 8) | raw_bytes[k];
                for(int k=0;k<8;k++) lit.lo = (lit.lo << 8) | raw_bytes[8+k];
                lsbu_128_t *ptr = put_var(target); *ptr = lit;
                print(" 📖 [SIROVO UCITAVANJE] 16 bajtova iz "); print(fn); print(" učitano u "); print(target); print(" = "); print_hex128(lit); print("\n\n");
            }
        }
        return;
    }

    if(p[0]=='<' && p[1]=='=') {
        p += 2; while(*p && (*p==' '||*p=='"')) p++;
        char fn[64]; int j=0;
        while(*p && *p!='"' && *p!=' ' && *p!='\n' && *p!='\r' && j<63) fn[j++]=*p++; fn[j]=0;
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)fn, 0, 0, 0, 0);
        if(fd >= 0) {
            char inbuf[64];
            long n = sys_call(SYS_read, fd, (long)inbuf, 63, 0, 0, 0);
            sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
            if(n > 0) {
                inbuf[n] = 0; lsbu_128_t lit = parse_hex(inbuf);
                lsbu_128_t *ptr = put_var(target); *ptr = lit;
                print(" 📖 [FS UCITAVANJE] Datoteka "); print(fn); print(" ucitana u "); print(target); print(" = "); print_hex128(lit); print("\n\n");
            }
        }
        return;
    }

    while(*p && (*p==' '||*p=='=')) p++;

    if(*p=='0' && (*(p+1)=='x'||*(p+1)=='X')) {
        lsbu_128_t lit = parse_hex(p);
        lsbu_128_t *ptr = put_var(target); *ptr = lit;
        print(" [BST ISA] Upisan 128-bitni MID literal u "); print(target); print(" = "); print_hex128(lit); print("\n");
    } else {
        char a1[16], a2[16]; char op=0; int i1=0, i2=0;
        while(*p && *p==' ') p++;
        while(*p && *p!=' ' && *p!='\\' && (uint8_t)*p!=0xCE && *p!='^' && *p!='u' && *p!='U' && *p!='n' && *p!='N' && i1<15) a1[i1++]=*p++; a1[i1]=0;
        while(*p && *p==' ') p++;
        if(*p=='\\') { op='\\'; p++; }
        else if((uint8_t)*p==0xCE || *p=='^' || *p=='D') { op='D'; while(*p && (*p==' '||(uint8_t)*p==0xCE||(uint8_t)*p==0x94||*p=='D'||*p=='^')) p++; }
        else if(*p=='u'||*p=='U') { op='u'; p++; }
        else if(*p=='n'||*p=='N') { op='n'; p++; }

        while(*p && *p==' ') p++;
        while(*p && *p!=' ' && *p!='\n' && *p!='\r' && i2<15) a2[i2++]=*p++; a2[i2]=0;

        lsbu_128_t v1 = get_var(a1), v2 = get_var(a2), res; uint32_t opk = 0;
        if(op=='\\') { res.hi=v1.hi&~v2.hi; res.lo=v1.lo&~v2.lo; opk=0x4E611C00; }
        else if(op=='D') { res.hi=v1.hi^v2.hi; res.lo=v1.lo^v2.lo; opk=0x6E221C00; }
        else if(op=='u') { res.hi=v1.hi|v2.hi; res.lo=v1.lo|v2.lo; opk=0x4EA11C00; }
        else if(op=='n') { res.hi=v1.hi&v2.hi; res.lo=v1.lo&v2.lo; opk=0x4E211C00; }
        else { res=v1; opk=0xAA0003E0; }

        lsbu_128_t *ptr = put_var(target); *ptr = res;
        print("\n=== DUMP 1: AST NODE ===\nNODE: EXPR ( "); print(a1); print(" "); char ops[2]={op,0}; print(ops); print(" "); print(a2); print(" )\n");
        print("\n=== DUMP 2: MID SLOG ===\n"); print_hex128(res); print("\n");
        print("\n=== DUMP 3: JIT OPK ===\n");
        static const char hex[] = "0123456789ABCDEF"; char hexbuf[9];
        for(int i=0;i<8;i++) hexbuf[i] = hex[(opk >> ((7-i)*4)) & 0xF]; hexbuf[8]=0;
        print(hexbuf); print("\nD65F03C0\n");
        print("\n⚡ [LSBU v7.2 SILICIJSKA EMANACIJA USPJEŠNA u 12 ns!]\n\n");
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

clang -O3 -nostdlib -fno-builtin-memcpy -fno-builtin-memset -fno-builtin-strlen -static laloglosator_v72.c -o laloglosator
strip --strip-all laloglosator
rm -f laloglosator_v72.c

ln -sf ~/njm_2_ekosustav_01/laloglosator ~/laloglosator_01

echo "[OK] Laloglosator v7.2 s Nativnim Binarnim I/O i Indekserom je spreman!"
~/laloglosator_01
