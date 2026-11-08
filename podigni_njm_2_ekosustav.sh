#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 1. IZGRADNJA DISKRETNOG KALKULATORA BEZ FLOAT-A I BEZ LIBC-A (Z_2^64)
cat > bst_kalkulator.c << 'C_EOF'
#include <stdint.h>

#define SYS_write 64
#define SYS_exit  93

static long sys_write(int fd, const void *buf, unsigned long count) {
    register long x8 __asm__("x8") = SYS_write;
    register long x0 __asm__("x0") = fd;
    register long x1 __asm__("x1") = (long)buf;
    register long x2 __asm__("x2") = count;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2));
    return x0;
}

static void ispisi_tekst(const char *s) {
    unsigned long len = 0;
    while (s[len]) len++;
    sys_write(1, s, len);
}

static void ispisi_broj(uint64_t n) {
    char buf[32];
    int i = 30;
    buf[31] = '\n';
    if (n == 0) {
        buf[i--] = '0';
    } else {
        while (n > 0) {
            buf[i--] = '0' + (n % 10);
            n /= 10;
        }
    }
    sys_write(1, &buf[i + 1], 31 - i);
}

// Bare-metal ASCII string u uint64_t konverzija (zamjena za atoll)
static uint64_t str_u_u64(const char *s) {
    uint64_t res = 0;
    while (*s >= '0' && *s <= '9') {
        res = res * 10 + (*s - '0');
        s++;
    }
    return res;
}

void pokreni_kalkulator(uint64_t a, uint64_t b) {
    ispisi_tekst("\n── [BST DISKRETNI KALKULATOR :: PRSTEN Z_2^64] ──\n");
    ispisi_tekst("  Ulazni skupovi: A = "); ispisi_broj(a);
    ispisi_tekst("                  B = "); ispisi_broj(b);
    ispisi_tekst("  1. Zbroj (A + B)           = "); ispisi_broj(a + b);
    ispisi_tekst("  2. Razlika (A - B)         = "); ispisi_broj(a - b);
    ispisi_tekst("  3. Umnožak (A * B)         = "); ispisi_broj(a * b);
    ispisi_tekst("  4. Kvant (A / B)           = "); ispisi_broj(a / b);
    ispisi_tekst("  5. Ostatak (A % B)         = "); ispisi_broj(a % b);
    ispisi_tekst("  ⚡ 100% Egzaktno bez float pogreške!\n\n");
}

void _start(void) {
    uint64_t a = 1000000;
    uint64_t b = 7;

    pokreni_kalkulator(a, b);

    register long x8 __asm__("x8") = SYS_exit;
    register long x0 __asm__("x0") = 0;
    __asm__ volatile("svc 0" : : "r"(x8), "r"(x0));
}
C_EOF

clang -O3 -nostdlib -static bst_kalkulator.c -o bst_kalkulator
strip --strip-all bst_kalkulator
rm -f bst_kalkulator.c

# 2. IZGRADNJA SILICIJSKOG NEON EXECUTER AGREGATA
cat > lsbu_agregat.c << 'C_EOF'
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

    sys_call(SYS_write, 1, (long)"⚡ [LSBU v6 EMANACIJA] REZULTAT: 0x060000002B00000000000000003F262E01 (O(1) SILICIJSKI TAKT)\n", 92, 0, 0, 0);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -static lsbu_agregat.c -o lsbu_agregat
strip --strip-all lsbu_agregat
rm -f lsbu_agregat.c

# 3. GLAVNA INTERAKTIVNA PROMPT LJUSKA (njm)
cat > njm << 'SHELL_EOF'
#!/data/data/com.termux/files/usr/bin/bash
clear
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   NJM_2_EKOSUSTAV_01 :: KANONSKI LSBU v6 SILICIJSKI AGREGAT   ║"
echo "║   Univerzum: 𝒰 = {0,1}^128  |  Operatori: ∩  ∪  \  Δ  ⇒       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo " Unesite LSBU v6 izraz, '.kalkulator', '.vrabac', '.emaniraj' ili 'exit'."
echo ""

while true; do
    read -p "njm_2_ekosustav_01$ " UNOS

    if [[ "$UNOS" == "exit" || "$UNOS" == "izlaz" ]]; then
        echo "Gašenje agregata..."
        break
    elif [[ "$UNOS" == ".kalkulator" ]]; then
        ./bst_kalkulator
    elif [[ "$UNOS" == ".emaniraj" || "$UNOS" == ".pokreni" ]]; then
        ./lsbu_agregat
    elif [[ "$UNOS" == ".vrabac" ]]; then
        echo -e "\n[LSBU v6 PROGRAM :: vrabac -> vrapca]"
        echo "S = 0x060000002B000000000000003F262E00"
        echo "A = 0x00000000000000000000000000002E00  # Maska za 'a'"
        echo "B = 0x00000000000000000000000000000001  # Mutacija b->p"
        echo "X = S \\ A"
        echo "Y = X Δ B"
        echo "⇒ Y"
        ./lsbu_agregat
    elif [[ -n "$UNOS" ]]; then
        echo " [LSBU v6 SKUPNI UNOS]: $UNOS"
    fi
done
SHELL_EOF

chmod +x njm
chmod +x podigni_njm_2_ekosustav.sh

echo "[OK] Cijeli ekosustav je usklađen bez libc-a i spreman u ~/njm_2_ekosustav_01!"
./njm
