#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: OPTIMIZACIJA DO TEORIJSKOG MINIMUMA    "
echo "═══════════════════════════════════════════════════════════════"

# 1. GENERIRANJE ULTRALAKOG 36-BAJTNOG ARTEFAKTA (BSTBIN v2)
cat > generiraj_v2.py << 'PY_EOF'
import struct

# A. 16 Bajtova V0 MID ulaza za "vrabac"
v0_init = bytes.fromhex("060000002B000000000000003F262E00")

# B. 4 Bajta CODE_SIZE (16 B NEON koda = 4 instrukcije)
code_size = struct.pack("<I", 16)

# C. 16 Bajtova ČISTOG NEON METABOLIZMA
code_blob = bytes.fromhex(
    "001C214E"  # vps (VAND V0, V0, V1)
    "421C236E"  # vss (VEOR V0, V1, V2)
    "001CA04E"  # vus (VORR V0, V0, V0)
    "C0035FD6"  # ret (AArch64 povratak iz JIT-a)
)

bstbin_v2 = v0_init + code_size + code_blob

with open("bst_core_v2.bin", "wb") as f:
    f.write(bstbin_v2)

print(f"[OK] Generiran bst_core_v2.bin dimenzije točno {len(bstbin_v2)} bajtova!")
PY_EOF
python3 generiraj_v2.py

# 2. IZGRADNJA ULTRA-BRZOG BARE-METAL LOADERA (BEZ WARNINGA I SA STABILNIM RET-OM)
cat > bst_loader_v2.c << 'C_EOF'
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

// Dinamička veličina niza postavljenog na točno 36 Bajtova (Nema warninga)
static const uint8_t BSTBIN_V2[36] __attribute__((aligned(16))) = {
    0x06, 0x00, 0x00, 0x00, 0x2B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x26, 0x2E, 0x00, // V0_INIT (16 B)
    0x10, 0x00, 0x00, 0x00,                                                                         // CODE_SIZE (4 B)
    0x00, 0x1C, 0x21, 0x4E, 0x42, 0x1C, 0x23, 0x6E, 0x00, 0x1C, 0xA0, 0x4E, 0xC0, 0x03, 0x5F, 0xD6  // CODE_BLOB (16 B s RET)
};

void _start(void) {
    uint32_t code_size = *(uint32_t *)&BSTBIN_V2[16];

    // Alokacija 4096 bajtova (poravnatih sa stranicom memorije za mprotect)
    long code_addr = sys_call(SYS_mmap, 0, 4096, 0x3, 0x22, -1, 0);

    uint8_t *src = (uint8_t *)&BSTBIN_V2[20];
    uint8_t *dst = (uint8_t *)code_addr;
    for (uint32_t i = 0; i < code_size; i++) dst[i] = src[i];

    sys_call(SYS_mprotect, code_addr, 4096, 0x5, 0, 0, 0);

    // IZRAVAN SKOK NA NEON SILICIJ U O(1) TAKTU (BLR X6)
    register long x0 __asm__("x0") = (long)&BSTBIN_V2[0];
    register long x6 __asm__("x6") = code_addr;
    __asm__ volatile("blr x6" : "+r"(x0) : "r"(x6));

    // Brza sistemska potvrda bez I/O latencije
    sys_call(SYS_write, 1, (long)"\n⚡ [OK] BSTBIN v2 (36 B) USPEŠNO IZVRŠEN BEZ WARNINGA I BEZ I/O LATENCIJE!\n", 76, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

# Prevođenje bez libc-a
clang -O3 -nostdlib -static bst_loader_v2.c -o bst_loader_v2
strip --strip-all bst_loader_v2

echo -e "\n[3] Veličine stvorenih artefakata u njm_2_ekosustav_01:"
ls -lh bst_loader_v2 bst_core_v2.bin

echo -e "\n[4] Heksadecimalni prikaz 36-bajtne strukture bst_core_v2.bin:"
hexdump -C bst_core_v2.bin

echo -e "\n[5] LANSIRANJE IN-MEMORY ULTRA-BRZOG CIKLUSA:"
echo "═══════════════════════════════════════════════════════════════"
./bst_loader_v2
echo "═══════════════════════════════════════════════════════════════"

rm -f generiraj_v2.py
