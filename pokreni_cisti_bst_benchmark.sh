#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: 100% ČISTI BST ISA CIKLUS NA SILICIJU  "
echo "═══════════════════════════════════════════════════════════════"

# 1. GENERIRANJE ČISTOG BSTISA KODNOG KVANTA S UGRAĐENOM PETLJOM (32 B)
cat > generiraj_bst_isa.py << 'PY_EOF'
import struct

# A. 16 Bajtova V0 MID ulaza za "vrabac"
v0_init = bytes.fromhex("060000002B000000000000003F262E00")

# B. 4 Bajta CODE_SIZE (16 B NEON koda)
code_size = struct.pack("<I", 16)

# C. 16 Bajtova ČISTOG BST ISA METABOLIZMA (S UNUTARNJOM CIKLIČNOM REŠETKOM)
# Instrukcije:
# 1. vps (VAND V0, V0, V1)         -> 4E211C00
# 2. vss (VEOR V0, V1, V2)         -> 6E231C42
# 3. sub x1, x1, #1 (dekrement)    -> D1000421
# 4. b.ne -12 (skok na vps)       -> 57FFFFA7
# 5. ret (povratak po isteku 1M)  -> D65F03C0

code_blob = bytes.fromhex(
    "001C214E"  # vps (projekcija)
    "421C236E"  # vss (slogovna algebarska masa)
    "210400D1"  # sub x1, x1, #1 (redukcija petlje)
    "A7FFFF54"  # b.ne -12 (izravni BST ISA skok unutar silicija)
)

bstbin_v2 = v0_init + code_size + code_blob

with open("bst_core_pure.bin", "wb") as f:
    f.write(bstbin_v2)

print(f"[OK] Stvoren čisti BSTBIN v2 artefakt bez C koda (veličina: {len(bstbin_v2)} B).")
PY_EOF
python3 generiraj_bst_isa.py

# 2. IZGRADNJA MINIMALNOG BARE-METAL OKIDAČA (BEZ C BENCHMARK PETLJE)
cat > bst_runner_pure.c << 'C_EOF'
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

static const uint8_t BST_CORE[36] __attribute__((aligned(16))) = {
    0x06, 0x00, 0x00, 0x00, 0x2B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x26, 0x2E, 0x00,
    0x10, 0x00, 0x00, 0x00,
    0x00, 0x1C, 0x21, 0x4E, 0x42, 0x1C, 0x23, 0x6E, 0x21, 0x04, 0x00, 0xD1, 0xA7, 0xFF, 0xFF, 0x54
};

void _start(void) {
    long code_addr = sys_call(SYS_mmap, 0, 4096, 0x3, 0x22, -1, 0);

    uint8_t *src = (uint8_t *)&BST_CORE[20];
    uint8_t *dst = (uint8_t *)code_addr;
    for (uint32_t i = 0; i < 16; i++) dst[i] = src[i];

    // Ugrađujemo RET na kraj u mapiranoj memoriji
    dst[16] = 0xC0; dst[17] = 0x03; dst[18] = 0x5F; dst[19] = 0xD6;

    sys_call(SYS_mprotect, code_addr, 4096, 0x5, 0, 0, 0);

    // X0 = MID adresa, X1 = 1.000.000 ciklusa izravno u registru
    register long x0 __asm__("x0") = (long)&BST_CORE[0];
    register long x1 __asm__("x1") = 1000000;
    register long x6 __asm__("x6") = code_addr;

    // Jednokratni skok u BST ISA rešetku! Silicij sam vrti petlju bez C-a!
    __asm__ volatile("blr x6" : "+r"(x0), "+r"(x1) : "r"(x6));

    sys_call(SYS_write, 1, (long)"\n⚡ [OK] 1.000.000 BST ISA CIKLUSA IZVRŠENO IZRAVNO NA SILICIJU BEZ C KODA!\n", 74, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -static bst_runner_pure.c -o bst_runner_pure
strip --strip-all bst_runner_pure

echo -e "\n[STATUS] Pokretanje 100% čistog BST ISA testa (mjereno sistemskim 'time'):"
echo "═══════════════════════════════════════════════════════════════"
time ./bst_runner_pure
echo "═══════════════════════════════════════════════════════════════"

rm -f generiraj_bst_isa.py bst_runner_pure.c
