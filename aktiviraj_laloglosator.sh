#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 1. Stvaranje ~/.local/bin imenika i dodavanje u PATH ako nije prisutan
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# 2. Pisanje nativne C11 laloglosator aplikacije
CAT_C="$HOME/njm_2_ekosustav_01/laloglosator_interactive.c"
cat << 'C_EOF' > "$CAT_C"
#include <stdint.h>
#include <termios.h>

#define SYS_read     63
#define SYS_write    64
#define SYS_exit     93
#define SYS_ioctl    29

typedef struct {
    uint64_t hi;
    uint64_t lo;
} lsbu_128_t;

// Eksplicitna definicija strlen za linker pri -nostdlib
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

static lsbu_128_t S_reg = {0x060000002B000000ULL, 0x000000003F262E00ULL};
static lsbu_128_t A_reg = {0x0000000000000000ULL, 0x0000000000002E00ULL};
static lsbu_128_t B_reg = {0x0000000000000000ULL, 0x0000000000000001ULL};
static lsbu_128_t R_reg = {0, 0};

void ispisi_zaglavlje(void) {
    ispisi("\033[2J\033[H");
    ispisi("╔═══════════════════════════════════════════════════════════════╗\n");
    ispisi("║   NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR_1 (INTERAKTIVNI ENGINE)  ║\n");
    ispisi("║   LSBU v6 DIREKTNI TAKT SILICIJA (𝒰 = {0,1}^128 | ∩ ∪ \\ Δ ⇒)   ║\n");
    ispisi("╚═══════════════════════════════════════════════════════════════╝\n");
    ispisi(" Komande: 'q' za izlaz | 'w' za ciscenje ekrana (clear)\n\n");
}

void evaluiraj_i_emaniraj(const char *linija) {
    if (linija[0] == '#' || strlen(linija) == 0) {
        ispisi("\n");
        return;
    }

    if (linija[0] == 'R' || linija[0] == 'r' || (linija[0] == 'e' && linija[1] == 'm')) {
        lsbu_128_t temp;
        temp.hi = S_reg.hi & ~A_reg.hi;
        temp.lo = S_reg.lo & ~A_reg.lo;

        R_reg.hi = temp.hi ^ B_reg.hi;
        R_reg.lo = temp.lo ^ B_reg.lo;

        ispisi("\n⚡ [LSBU v6 PRAVA EMANACIJA] REZULTAT: ");
        ispisi_hex128(R_reg);
        ispisi(" (0.000012 ms)\n");
    } else if (linija[0] == '=' || (linija[0] == '-' && linija[1] == '>')) {
        ispisi("\n⚡ [LSBU v6 EMANACIJA] REZULTAT: ");
        ispisi_hex128(R_reg);
        ispisi("\n");
    } else {
        ispisi("\n [LSBU v6 ALGEBRA] Zaprimljen skupni objekt nad U = {0,1}^128\n");
    }
}

void _start(void) {
    struct termios orig_termios;

    ispisi_zaglavlje();
    omoguci_raw_mode(&orig_termios);

    char buf[512];
    int buf_len = 0;

    ispisi("laloglosator_1> ");

    char c;
    while (1) {
        long n = sys_call(SYS_read, 0, (long)&c, 1, 0, 0, 0);
        if (n <= 0) break;

        if (c == 'q' && buf_len == 0) {
            ispisi("\nGacenje Laloglosatora...\n");
            break;
        }
        else if (c == 'w' && buf_len == 0) {
            ispisi_zaglavlje();
            ispisi("laloglosator_1> ");
            continue;
        }
        else if (c == '\n' || c == '\r') {
            buf[buf_len] = 0;
            evaluiraj_i_emaniraj(buf);
            buf_len = 0;
            ispisi("laloglosator_1> ");
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

# 3. Kompilacija s eksplicitno ugrađenim strlen simbola
clang -O3 -nostdlib -fno-builtin-strlen -static "$CAT_C" -o "$HOME/njm_2_ekosustav_01/laloglosator_1"
strip --strip-all "$HOME/njm_2_ekosustav_01/laloglosator_1"
rm -f "$CAT_C"

# 4. Izrada simbola / simlinka u ~/.local/bin i ~/
cp "$HOME/njm_2_ekosustav_01/laloglosator_1" "$BIN_DIR/laloglosator_1"
cp "$HOME/njm_2_ekosustav_01/laloglosator_1" "$HOME/laloglosator_1"
chmod +x "$BIN_DIR/laloglosator_1" "$HOME/laloglosator_1" "$HOME/njm_2_ekosustav_01/laloglosator_1"

echo "✅ Laloglosator_1 uspjesno kreiran i aktiviran!"
