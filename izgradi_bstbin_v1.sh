#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: IZGRADNJA BSTBIN v1 MIKROKERNELA (48 B)"
echo "═══════════════════════════════════════════════════════════════"

# 1. IZRADNJA BARE-METAL LOADERA BEZ LIBC-A (SYSCALL-ONLY)
cat > bst_loader.c << 'C_EOF'
#include <stdint.h>

#define SYS_read     63
#define SYS_write    64
#define SYS_openat   56
#define SYS_close    57
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

void _start(void) {
    // 1. openat(AT_FDCWD, "bst_core.bin", O_RDONLY, 0)
    long fd = sys_call(SYS_openat, -100, (long)"bst_core.bin", 0, 0, 0, 0);
    if (fd < 0) sys_call(SYS_exit, 1, 0, 0, 0, 0, 0);

    // 2. Pročitaj 48 bajtova BSTBIN v1 zaglavlja + koda
    uint8_t buffer[48];
    sys_call(SYS_read, fd, (long)buffer, 48, 0, 0, 0);
    sys_call(SYS_close, fd, 0, 0, 0, 0, 0);

    uint32_t code_size = *(uint32_t *)&buffer[0x10]; // 24 B

    // 3. mmap RW memorije za AArch64 SIMD kodni blob
    long code_addr = sys_call(SYS_mmap, 0, code_size, 0x3, 0x22, -1, 0);

    // 4. Kopiranje 24 bajta CODE_BLOB-a (offset 0x18) u mmap memoriju
    uint8_t *src = &buffer[0x18];
    uint8_t *dst = (uint8_t *)code_addr;
    for (uint32_t i = 0; i < code_size; i++) dst[i] = src[i];

    // 5. mprotect na RX (PROT_READ | PROT_EXEC)
    sys_call(SYS_mprotect, code_addr, code_size, 0x5, 0, 0, 0);

    // 6. Pokretanje koda na siliciju preko BLR X6
    register long x0 __asm__("x0") = (long)&buffer[0]; // V0_INIT pointer
    register long x6 __asm__("x6") = code_addr;
    __asm__ volatile("blr x6" : "+r"(x0) : "r"(x6));

    // 7. Ispis verifikacijske potvrde i izlaz
    sys_call(SYS_write, 1, (long)"\n[OK] BSTBIN v1 uspješno izvršen na AArch64 siliciju!\n", 53, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

# Prevođenje bez libc-a (-nostdlib -static)
clang -O3 -nostdlib -static bst_loader.c -o bst_loader
strip --strip-all bst_loader

# 2. GENERIRANJE KANONSKOG 48-BAJTNOG BSTBIN v1 ARTEFAKTA (bst_core.bin)
# Layout:
# 0x00-0x0F (16 B): V0_INIT (vrabac MID)
# 0x10-0x13 (4 B) : CODE_SIZE (24 B = 0x18)
# 0x14-0x17 (4 B) : FLAGS (0x03)
# 0x18-0x2F (24 B): CODE_BLOB (vps, vss, vrs, vus, vss_tr, ooi/ret)
cat > generiraj_bin.py << 'PY_EOF'
import struct

v0_init = bytes.fromhex("060000002B000000000000003F262E00") # 16 B
code_size = struct.pack("<I", 24)                            # 4 B
flags = struct.pack("<I", 3)                                  # 4 B

code_blob = bytes.fromhex(
    "001C214E"  # vps
    "421C236E"  # vss
    "841C654E"  # vrs
    "001CA04E"  # vus
    "261C216E"  # vss (transformacija)
    "C0033FD6"  # ooi (ret / blr)
)                                                           # 24 B

bstbin = v0_init + code_size + flags + code_blob

with open("bst_core.bin", "wb") as f:
    f.write(bstbin)

print(f"[OK] Generiran bst_core.bin veličine točno {len(bstbin)} bajtova.")
PY_EOF

python3 generiraj_bin.py

echo -e "\n[3] Provjera dimenzija stvorenih artefakata u njm_2_ekosustav_01:"
ls -lh bst_loader bst_core.bin

echo -e "\n[4] Heksadecimalni pregled 48-bajtne strukture bst_core.bin:"
hexdump -C bst_core.bin

echo -e "\n[5] LANSIRANJE BARE-METAL BIKROKERNELA (BEZ LIBC-A):"
echo "═══════════════════════════════════════════════════════════════"
./bst_loader
echo "═══════════════════════════════════════════════════════════════"

rm -f generiraj_bin.py bst_loader.c
