#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat > laloglosator_v31_mass.c << 'C_EOF'
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

#define MAX_VARS          128
#define MAX_LEXICON_WORDS 500000
#define MAX_PATH_LEN      1024
#define CLOCK_MONOTONIC    1

struct timespec_aarch64 { int64_t tv_sec; int64_t tv_nsec; };
typedef struct { uint64_t hi, lo; } lsbu_128_t;

static lsbu_128_t MASTER_LEXICON[MAX_LEXICON_WORDS];
static uint64_t LEXICON_COUNT = 0;
static uint64_t TOTAL_DOCS_PROCESSED = 0;
static uint64_t TOTAL_WORDS_EXTRACTED = 0;

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

static uint64_t get_time_ns(void) {
    struct timespec_aarch64 ts;
    sys_call(SYS_clock_gettime, CLOCK_MONOTONIC, (long)&ts, 0, 0, 0, 0);
    return (uint64_t)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

static lsbu_128_t compute_word_mid(const char *w, int len) {
    lsbu_128_t m = {0x574F52444D494430ULL, 0xA5A5A5A5A5A5A5A5ULL};
    for(int i = 0; i < len; i++) {
        uint8_t c = (uint8_t)w[i];
        m.hi = (m.hi << 7) ^ (m.hi >> 5) ^ c;
        m.lo = (m.lo << 11) ^ (m.lo >> 3) ^ (c * 13);
    }
    return m;
}

static void add_to_lexicon(lsbu_128_t mid) {
    for(uint64_t i = 0; i < LEXICON_COUNT; i++) {
        if(MASTER_LEXICON[i].hi == mid.hi && MASTER_LEXICON[i].lo == mid.lo) return;
    }
    if(LEXICON_COUNT < MAX_LEXICON_WORDS) {
        MASTER_LEXICON[LEXICON_COUNT++] = mid;
    }
}

static void extract_and_tokenize_file(const char *filepath) {
    long fd = sys_call(SYS_openat, AT_FDCWD, (long)filepath, O_RDONLY, 0, 0, 0);
    if(fd < 0) return;

    char buf[4096];
    long nread = 0;
    char wbuf[128];
    int wlen = 0;
    int in_xml_tag = 0;

    TOTAL_DOCS_PROCESSED++;

    while((nread = sys_call(SYS_read, fd, (long)buf, 4096, 0, 0, 0)) > 0) {
        for(long i = 0; i < nread; i++) {
            unsigned char c = (unsigned char)buf[i];

            if(c == '<') { in_xml_tag = 1; continue; }
            if(c == '>') { in_xml_tag = 0; continue; }
            if(in_xml_tag) continue;

            if(c > 32) {
                if(wlen < 127) wbuf[wlen++] = c;
            } else {
                if(wlen > 0) {
                    wbuf[wlen] = 0;
                    lsbu_128_t mid = compute_word_mid(wbuf, wlen);
                    TOTAL_WORDS_EXTRACTED++;
                    add_to_lexicon(mid);
                }
                wlen = 0;
            }
        }
    }
    if(wlen > 0) {
        wbuf[wlen] = 0;
        lsbu_128_t mid = compute_word_mid(wbuf, wlen);
        TOTAL_WORDS_EXTRACTED++;
        add_to_lexicon(mid);
    }
    sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
}

// Čišćenje punih putanja uključujući razmake i specijalne znakove
static void extract_full_path(const char *p, char *out, int maxlen) {
    while(*p == ' ' || *p == '\t' || *p == '"') p++;
    int j = 0;
    int in_q = 0;
    while(*p && *p != '\n' && *p != '\r' && j < maxlen - 1) {
        if(*p == '"') { in_q = !in_q; p++; continue; }
        out[j++] = *p++;
    }
    while(j > 0 && (out[j-1] == ' ' || out[j-1] == '\t' || out[j-1] == '"')) j--;
    out[j] = 0;
}

static void save_master_cloud(void) {
    long fd = sys_call(SYS_openat, AT_FDCWD, (long)"mid_master_oblaci.lsbu", O_WRONLY | O_CREAT | O_TRUNC, 0644, 0, 0);
    if(fd >= 0) {
        for(uint64_t i = 0; i < LEXICON_COUNT; i++) {
            uint8_t raw[16];
            for(int k=0;k<8;k++) raw[k] = (MASTER_LEXICON[i].hi >> ((7-k)*8)) & 0xFF;
            for(int k=0;k<8;k++) raw[8+k] = (MASTER_LEXICON[i].lo >> ((7-k)*8)) & 0xFF;
            sys_call(SYS_write, fd, (long)raw, 16, 0, 0, 0);
        }
        sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
    }
}

void _start(void) {
    struct termios orig, raw;
    print("╔═══════════════════════════════════════════════════════════════╗\n");
    print("║  NJM-OS :: LALOGLOSATOR v31.2 (FULL MASS-STORAGE ENGINE)      ║\n");
    print("║  EXYNOS 1280 AUTOMATSKI WORD-MID OBLAK ZA 220.000+ DOKUMENATA ║\n");
    print("╚═══════════════════════════════════════════════════════════════╝\n\n");

    sys_call(SYS_ioctl, 0, TCGETS, (long)&orig, 0, 0, 0); raw = orig;
    raw.c_lflag &= ~(ECHO | ICANON);
    sys_call(SYS_ioctl, 0, TCSETS, (long)&raw, 0, 0, 0);

    char buf[1024]; int len = 0;
    print("laloglosator_v31> ");
    char c;
    while(1) {
        long n = sys_call(SYS_read, 0, (long)&c, 1, 0, 0, 0);
        if(n <= 0) break;
        if(c == 'q' && len == 0) break;
        else if(c == '\n' || c == '\r') {
            buf[len] = 0;
            if(buf[0]=='i'&&buf[1]=='n'&&buf[2]=='g'&&buf[3]=='e'&&buf[4]=='s'&&buf[5]=='t') {
                char fn[MAX_PATH_LEN]; extract_full_path(buf + 6, fn, MAX_PATH_LEN);
                print(" 🚀 [NATIVE INGEST] Usisavam riječi i računam MID iz: "); print(fn); print("\n");
                uint64_t t0 = get_time_ns();
                extract_and_tokenize_file(fn);
                save_master_cloud();
                uint64_t t_elapsed = get_time_ns() - t0;
                print(" ✅ [OK] Riječi: "); print_num(TOTAL_WORDS_EXTRACTED);
                print(" | Unikatni MID leksikon: "); print_num(LEXICON_COUNT);
                print(" | Vrijeme: "); print_num(t_elapsed / 1000); print(" µs\n\n");
            } else if(buf[0]=='s'&&buf[1]=='t'&&buf[2]=='a'&&buf[3]=='t') {
                print(" 📊 [GLOBALNI STATUS OBLAKA]\n");
                print("   ├── Procesirano dokumenata : "); print_num(TOTAL_DOCS_PROCESSED); print("\n");
                print("   ├── Ekstrahirano riječi   : "); print_num(TOTAL_WORDS_EXTRACTED); print("\n");
                print("   └── Unikatnih Word MID-ova : "); print_num(LEXICON_COUNT); print("\n\n");
            }
            len = 0; print("laloglosator_v31> ");
        } else if((c == 127 || c == 8) && len > 0) {
            len--; print("\b \b");
        } else if(len < 1000) {
            buf[len++] = c; char e[2] = {c, 0}; print(e);
        }
    }
    sys_call(SYS_ioctl, 0, TCSETS, (long)&orig, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -fno-builtin-memcpy -fno-builtin-memset -fno-builtin-strlen -static laloglosator_v31_mass.c -o laloglosator
strip --strip-all laloglosator
rm -f laloglosator_v31_mass.c
echo "[OK] Laloglosator v31.2 za masovni ingest je spreman!"
~/njm_2_ekosustav_01/laloglosator
