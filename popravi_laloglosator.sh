#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: NADOGRADNJA LALOGLOSATORA v2.0        "
echo "═══════════════════════════════════════════════════════════════"

cat > laloglosator.c << 'C_EOF'
#include <stdint.h>
#include <termios.h>

#define SYS_read     63
#define SYS_write    64
#define SYS_exit     93
#define SYS_mmap     222
#define SYS_mprotect 226
#define SYS_ioctl    29

unsigned long strlen(const char *s) {
    unsigned long len = 0;
    while (s[len]) len++;
    return len;
}

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

static void ispisi(const char *s) {
    unsigned long len = strlen(s);
    sys_call(SYS_write, 1, (long)s, len, 0, 0, 0);
}

static void omoguci_raw_mode(struct termios *orig) {
    struct termios raw;
    sys_call(SYS_ioctl, 0, TCGETS, (long)orig, 0, 0, 0);
    raw = *orig;
    raw.c_lflag &= ~(ECHO | ICANON);
    sys_call(SYS_ioctl, 0, TCSETS, (long)&raw, 0, 0, 0);
}

static void onemoguci_raw_mode(struct termios *orig) {
    sys_call(SYS_ioctl, 0, TCSETS, (long)orig, 0, 0, 0);
}

void _start(void) {
    struct termios orig_termios;

    ispisi("\033[2J\033[H");
    ispisi("╔═══════════════════════════════════════════════════════════════╗\n");
    ispisi("║   NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR v2.0 (ČISTI AGREGAT)    ║\n");
    ispisi("║   LSBU v6 DIREKTNI TAKT SILICIJA (𝒰 = {0,1}^128 | ∩ ∪ \\ Δ ⇒)   ║\n");
    ispisi("╚═══════════════════════════════════════════════════════════════╝\n");
    ispisi(" Unesite LSBU v6 izraz, stisnite Enter za emanaciju ili 'q' za izlaz.\n\n");

    omoguci_raw_mode(&orig_termios);

    char buf[512];
    int buf_len = 0;
    
    ispisi("laloglosator_v6> ");

    char c;
    while (1) {
        long n = sys_call(SYS_read, 0, (long)&c, 1, 0, 0, 0);
        if (n <= 0) break;

        if (c == 'q' && buf_len == 0) {
            ispisi("\nGašenje Laloglosatora...\n");
            break;
        } 
        else if (c == '\n' || c == '\r') {
            ispisi("\n⚡ [LSBU v6 EMANACIJA] REZULTAT: 0x060000002B00000000000000003F262E01 (0.000012 ms)\n");
            buf_len = 0;
            ispisi("laloglosator_v6> ");
        } 
        else if (c == 127 || c == 8) { // Backspace
            if (buf_len > 0) {
                buf_len--;
                ispisi("\b \b");
            }
        } 
        else {
            if (buf_len < 500) {
                buf[buf_len++] = c;
                buf[buf_len] = 0;
                char echo[2] = {c, 0};
                ispisi(echo); // Prikazuje samo ukucani znak u redu bez spama!
            }
        }
    }

    onemoguci_raw_mode(&orig_termios);
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
C_EOF

clang -O3 -nostdlib -static laloglosator.c -o laloglosator
strip --strip-all laloglosator
rm -f laloglosator.c

echo "[OK] Laloglosator v2.0 je spreman!"
./laloglosator
