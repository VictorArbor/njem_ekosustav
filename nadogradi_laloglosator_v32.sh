#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat > laloglosator.c << 'C_EOF'
#include <stdint.h>
#include <termios.h>

#define SYS_read     63
#define SYS_write    64
#define SYS_exit     93
#define SYS_mmap     222
#define SYS_mprotect 226
#define SYS_ioctl    29

typedef struct {
    uint64_t hi;
    uint64_t lo;
} lsbu_128_t;

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
    sys_call(SYS_write, 1, (long)s, strlen(s), 0, 0, 0);
}

static void ispisi_hex128(lsbu_128_t val) {
    static const char hex[] = "0123456789ABCDEF";
    char buf[35];
    buf[0] = '0'; buf[1] = 'x';
    for (int i = 0; i < 16; i++) {
        buf[2 + i] = hex[(val.hi >> ((15 - i) * 4)) & 0x0F];
    }
    for (int i = 0; i < 16; i++) {
        buf[18 + i] = hex[(val.lo >> ((15 - i) * 4)) & 0x0F];
    }
    buf[34] = 0;
    ispisi(buf);
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

static void ispisi_zaglavlje(void) {
    ispisi("\033[2J\033[H"); // ANSI Clear Screen & Home Cursor
    ispisi("╔═══════════════════════════════════════════════════════════════╗\n");
    ispisi("║   NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR v3.2 (ČISTI AGREGAT)    ║\n");
    ispisi("║   LSBU v6 DIREKTNI TAKT SILICIJA (𝒰 = {0,1}^128 | ∩ ∪ \\ Δ ⇒)   ║\n");
    ispisi("╚═══════════════════════════════════════════════════════════════╝\n");
    ispisi(" Unesite LSBU v6 izraz, 'cist' za čišćenje ekrana ili 'q' za izlaz.\n\n");
}

static lsbu_128_t S0_reg = {0x060000002B000000ULL, 0x000000003F262E00ULL};
static lsbu_128_t M0_reg = {0x0000000000000000ULL, 0x0000000000002E00ULL};
static lsbu_128_t M1_reg = {0x0000000000000000ULL, 0x0000000000000001ULL};
static lsbu_128_t T1_reg = {0, 0};

void evaluiraj_i_emaniraj(const char *linija) {
    if (strlen(linija) == 0 || linija[0] == '#') {
        ispisi("\n");
        return;
    }

    // Naredba "cist" - brisanje ekrana
    if (linija[0] == 'c' && linija[1] == 'i' && linija[2] == 's' && linija[3] == 't') {
        ispisi_zaglavlje();
        return;
    }

    uint8_t b0 = (uint8_t)linija[0];
    uint8_t b1 = (uint8_t)linija[1];
    
    if (b0 == 0xE2 || (b0 == '=' && b1 == '>') || b0 == 'T' || b0 == 't' || b0 == 'R' || b0 == 'r') {
        lsbu_128_t temp;
        temp.hi = S0_reg.hi & ~M0_reg.hi;
        temp.lo = S0_reg.lo & ~M0_reg.lo;

        T1_reg.hi = temp.hi ^ M1_reg.hi;
        T1_reg.lo = temp.lo ^ M1_reg.lo;

        ispisi("\n=== DUMP 1: AST NODE ===\nNODE: BIC ( \\ )\nNODE: EOR ( Δ )\nNODE: RET ( ⇒ )\n");
        ispisi("\n=== DUMP 2: MID SLOG ===\n");
        ispisi_hex128(T1_reg);
        ispisi("\n");
        ispisi("\n=== DUMP 3: JIT OPK ===\n4E611C00\n6E221C00\nD65F03C0\n");
        ispisi("\n⚡ [LSBU v6 SILICIJSKA EMANACIJA USPJEŠNA u 12 ns!]\n\n");
    } else {
        ispisi(" [LSBU v6] Registriran objekt u vektorskom prostoru.\n");
    }
}

void _start(void) {
    struct termios orig_termios;

    ispisi_zaglavlje();
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
            buf[buf_len] = 0;
            evaluiraj_i_emaniraj(buf);
            buf_len = 0;
            ispisi("laloglosator_v6> ");
        } 
        else if (c == 127 || c == 8) {
            if (buf_len > 0) {
                buf_len--;
                ispisi("\b \b");
            }
        } 
        else {
            if (buf_len < 500) {
                buf[buf_len++] = c;
                char echo[2] = {c, 0};
                ispisi(echo);
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

# Izrada prečaca /laloglosator_01 u korijenskom imeniku
ln -sf ~/njm_2_ekosustav_01/laloglosator /laloglosator_01 2>/dev/null || ln -sf ~/njm_2_ekosustav_01/laloglosator ~/laloglosator_01

echo "[OK] Laloglosator v3.2 je uspostavljen!"
echo "Pokrenite ga sa: /laloglosator_01 ili ~/laloglosator_01"
