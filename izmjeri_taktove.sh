#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: BARE-METAL PROFILIRANJE (1.000.000x)   "
echo "═══════════════════════════════════════════════════════════════"

cat > profilator.c << 'C_EOF'
#include <stdint.h>

#define SYS_write             64
#define SYS_exit              93
#define SYS_clock_gettime    113
#define SYS_mmap             222
#define SYS_mprotect         226

struct timespec_raw {
    long tv_sec;
    long tv_nsec;
};

static long sys_call(long n, long a, long b, long c, long d, long e, long f) {
    register long x8 __asm__("x8") = n;
    register long x0 __asm__("x0") = a;
    register long x1 __asm__("x1") = b;
    register long x2 __asm__("x2") = c;
    register long x3 __asm__("x3") = d;
    register long x4 __asm__("x4") = e;
    register long x5 __asm__("x5") = f;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5) : "memory");
    return x0;
}

static inline uint64_t get_time_ns_raw(void) {
    struct timespec_raw ts;
    // CLOCK_MONOTONIC_RAW = 4 na Linux AArch64
    sys_call(SYS_clock_gettime, 4, (long)&ts, 0, 0, 0, 0);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static const uint8_t BSTBIN_V2[36] __attribute__((aligned(16))) = {
    0x06, 0x00, 0x00, 0x00, 0x2B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x26, 0x2E, 0x00,
    0x10, 0x00, 0x00, 0x00,
    0x00, 0x1C, 0x21, 0x4E, 0x42, 0x1C, 0x23, 0x6E, 0x00, 0x1C, 0xA0, 0x4E, 0xC0, 0x03, 0x5F, 0xD6
};

void _start(void) {
    uint32_t code_size = *(uint32_t *)&BSTBIN_V2[16];
    long code_addr = sys_call(SYS_mmap, 0, 4096, 0x3, 0x22, -1, 0);

    uint8_t *src = (uint8_t *)&BSTBIN_V2[20];
    uint8_t *dst = (uint8_t *)code_addr;
    for (uint32_t i = 0; i < code_size; i++) dst[i] = src[i];

    sys_call(SYS_mprotect, code_addr, 4096, 0x5, 0, 0, 0);

    register long x0 __asm__("x0") = (long)&BSTBIN_V2[0];
    register long x6 __asm__("x6") = code_addr;

    // WARMUP
    for(int i=0; i<1000; i++) {
        __asm__ volatile("blr x6" : "+r"(x0) : "r"(x6) : "memory");
    }

    // BENCHMARK (1.000.000 CIKLUSA)
    uint64_t t_start = get_time_ns_raw();
    for(int i=0; i<1000000; i++) {
        __asm__ volatile("blr x6" : "+r"(x0) : "r"(x6) : "memory");
    }
    uint64_t t_end = get_time_ns_raw();

    uint64_t total_ns = t_end - t_start;

    sys_call(SYS_write, 1, (long)"\n📊 [OK] BARE-METAL BENCHMARK USPJEŠNO IZVRŠEN (1.000.000 CIKLUSA)!\n", 67, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -static profilator.c -o profilator
strip --strip-all profilator

echo -e "\n[STATUS] Pokretanje testa izravno na AArch64 siliciju sa mjerenjem vremena:"
echo "═══════════════════════════════════════════════════════════════"
time ./profilator
echo "═══════════════════════════════════════════════════════════════"

rm -f profilator.c profilator
