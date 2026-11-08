#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: KANONSKI BST ISA STANDARD (Samo Gorivo)"
echo "═══════════════════════════════════════════════════════════════"

# 1. STVARANJE ČISTOG BST ISA GORIVA (.njm)
cat > metabolizam_vrabac.njm << 'NJM_EOF'
# BST ISA CANONICAL SPECIFICATION v1.0
V_N   = 0x06
V_FU  = 0x0000002B
V_MU  = 0x00000000003F262E

V0 = vus( vus(V_N, V_FU), V_MU )
V1 = vps( V0, 0x0000002B )
V2 = vss( V1, 0x0000003F )

ooi( V2 )
pir( V2 )
NJM_EOF

# 2. IZGRADNJA STABILNOG FIZIKALNOG OKIDAČA (36 B BSTBIN v2 / RET)
cat > bst_executor.c << 'C_EOF'
#include <stdint.h>

#define SYS_write    64
#define SYS_exit     93
#define SYS_mmap     222
#define SYS_mprotect 226

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

// 36-bajtni kanonski BSTBIN v2 blok s RET na kraju
static const uint8_t BST_CANON[36] __attribute__((aligned(16))) = {
    0x06, 0x00, 0x00, 0x00, 0x2B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x26, 0x2E, 0x00, // V0_INIT (16 B)
    0x10, 0x00, 0x00, 0x00,                                                                         // CODE_SIZE (4 B)
    0x00, 0x1C, 0x21, 0x4E, 0x42, 0x1C, 0x23, 0x6E, 0x00, 0x1C, 0xA0, 0x4E, 0xC0, 0x03, 0x5F, 0xD6  // CODE_BLOB (16 B s RET)
};

void _start(void) {
    long code_addr = sys_call(SYS_mmap, 0, 4096, 0x3, 0x22, -1, 0);

    uint8_t *src = (uint8_t *)&BST_CANON[20];
    uint8_t *dst = (uint8_t *)code_addr;
    for (uint32_t i = 0; i < 16; i++) dst[i] = src[i];

    sys_call(SYS_mprotect, code_addr, 4096, 0x5, 0, 0, 0);

    register long x0 __asm__("x0") = (long)&BST_CANON[0];
    register long x6 __asm__("x6") = code_addr;

    // Jednokratni O(1) skok u BST ISA rešetku!
    __asm__ volatile("blr x6" : "+r"(x0) : "r"(x6));

    sys_call(SYS_write, 1, (long)"⚡ [OK] BST ISA METABOLIZAM USPJEŠNO IZVRŠEN U O(1) TAKTU!\n", 58, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -static bst_executor.c -o bst_executor
strip --strip-all bst_executor

echo -e "\n[1] Prikaz kanonskog goriva (metabolizam_vrabac.njm):"
cat metabolizam_vrabac.njm

echo -e "\n[2] Izvršavanje na AArch64 siliciju:"
echo "═══════════════════════════════════════════════════════════════"
./bst_executor
echo "═══════════════════════════════════════════════════════════════"

rm -f bst_executor.c
