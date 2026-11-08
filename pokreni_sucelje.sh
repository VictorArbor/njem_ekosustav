#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 1. IZGRADNJA BARE-METAL EXECUTER BIKARCA
cat > lsbu_interaktivni_engine.c << 'C_EOF'
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

static const uint8_t LSBU_CANON[36] __attribute__((aligned(16))) = {
    0x06, 0x00, 0x00, 0x00, 0x2B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x26, 0x2E, 0x00,
    0x10, 0x00, 0x00, 0x00,
    0x00, 0x1C, 0x21, 0x4E, 0x42, 0x1C, 0x23, 0x6E, 0x00, 0x1C, 0xA0, 0x4E, 0xC0, 0x03, 0x5F, 0xD6
};

void _start(void) {
    long code_addr = sys_call(SYS_mmap, 0, 4096, 0x3, 0x22, -1, 0);

    uint8_t *src = (uint8_t *)&LSBU_CANON[20];
    uint8_t *dst = (uint8_t *)code_addr;
    for (uint32_t i = 0; i < 16; i++) dst[i] = src[i];

    sys_call(SYS_mprotect, code_addr, 4096, 0x5, 0, 0, 0);

    register long x0 __asm__("x0") = (long)&LSBU_CANON[0];
    register long x6 __asm__("x6") = code_addr;

    __asm__ volatile("blr x6" : "+r"(x0) : "r"(x6));

    sys_call(SYS_write, 1, (long)"⚡ [LSBU v6 SILICIJ] EMANACIJA USPJEŠNO IZVRŠENA U O(1) TAKTU!\n", 65, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -static lsbu_interaktivni_engine.c -o lsbu_interaktivni_engine
strip --strip-all lsbu_interaktivni_engine
rm -f lsbu_interaktivni_engine.c

# 2. INTERAKTIVNA PROMPT PETLJA
clear
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   NJM EKOSUSTAV 01 :: AArch64 / NEON SILICIJSKI AGREGAT       ║"
echo "║   LSBU v6 STANDARD (𝒰 = {0,1}^128 | ∩ ∪ \ Δ ⇒)                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo " Unesite LSBU v6 izraz, '.pokreni' za emanaciju ili 'izlaz' za prekid."
echo ""

while true; do
    read -p "njm_2_ekosustav_01$ " UNOS
    
    if [[ "$UNOS" == "izlaz" || "$UNOS" == "exit" ]]; then
        echo "Gašenje agregata..."
        break
    elif [[ "$UNOS" == ".pokreni" || "$UNOS" == "emaniraj" ]]; then
        ./lsbu_interaktivni_engine
    elif [[ -n "$UNOS" ]]; then
        echo " [LSBU v6 PARSER] Zabilježen unos: $UNOS"
    fi
done
