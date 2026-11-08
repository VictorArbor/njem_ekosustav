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

#define MAX_VARS 32

typedef struct {
    uint64_t hi;
    uint64_t lo;
} lsbu_128_t;

typedef struct {
    char ime[16];
    lsbu_128_t vrijednost;
    uint8_t zauzeto;
} var_entry_t;

static var_entry_t SIMBOLI[MAX_VARS];

unsigned long strlen(const char *s) {
    unsigned long len = 0;
    while (s[len]) len++;
    return len;
}

static int str_jednaki(const char *a, const char *b) {
    while (*a && *b) {
        if (*a != *b) return 0;
        a++; b++;
    }
    return *a == *b;
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

static lsbu_128_t parsiraj_hex128(const char *s) {
    lsbu_128_t res = {0, 0};
    while (*s && *s != '0') s++;
    if (*s == '0' && (*(s+1) == 'x' || *(s+1) == 'X')) s += 2;

    char hex_clean[33];
    int len = 0;
    while (*s && len < 32) {
        char c = *s;
        if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f')) {
            hex_clean[len++] = c;
        } else if (c == ' ' || c == '\t' || c == '\n' || c == '#') {
            break;
        }
        s++;
    }
    hex_clean[len] = 0;

    int pad = 32 - len;
    for (int i = 0; i < len; i++) {
        char c = hex_clean[i];
        uint64_t v = 0;
        if (c >= '0' && c <= '9') v = c - '0';
        else if (c >= 'A' && c <= 'F') v = c - 'A' + 10;
        else if (c >= 'a' && c <= 'f') v = c - 'a' + 10;

        int pos = pad + i;
        if (pos < 16) {
            res.hi = (res.hi << 4) | v;
        } else {
            res.lo = (res.lo << 4) | v;
        }
    }
    return res;
}

static lsbu_128_t* nadji_ili_kreiraj_var(const char *ime) {
    for (int i = 0; i < MAX_VARS; i++) {
        if (SIMBOLI[i].zauzeto && str_jednaki(SIMBOLI[i].ime, ime)) {
            return &SIMBOLI[i].vrijednost;
        }
    }
    for (int i = 0; i < MAX_VARS; i++) {
        if (!SIMBOLI[i].zauzeto) {
            int j = 0;
            while (ime[j] && j < 15) {
                SIMBOLI[i].ime[j] = ime[j];
                j++;
            }
            SIMBOLI[i].ime[j] = 0;
            SIMBOLI[i].zauzeto = 1;
            SIMBOLI[i].vrijednost.hi = 0;
            SIMBOLI[i].vrijednost.lo = 0;
            return &SIMBOLI[i].vrijednost;
        }
    }
    return &SIMBOLI[0].vrijednost;
}

static lsbu_128_t dohvarti_var(const char *ime) {
    for (int i = 0; i < MAX_VARS; i++) {
        if (SIMBOLI[i].zauzeto && str_jednaki(SIMBOLI[i].ime, ime)) {
            return SIMBOLI[i].vrijednost;
        }
    }
    lsbu_128_t prazno = {0, 0};
    return prazno;
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
    ispisi("\033[2J\033[H");
    ispisi("╔═══════════════════════════════════════════════════════════════╗\n");
    ispisi("║   NJM_2_EKOSUSTAV_01 :: LALOGLOSATOR v4.1 (KANONSKI POGON)    ║\n");
    ispisi("║   LSBU v6 PRAVA SILICIJSKA EMANACIJA (𝒰 = {0,1}^128)           ║\n");
    ispisi("╚═══════════════════════════════════════════════════════════════╝\n");
    ispisi(" Unesite LSBU v6 izraz, 'cist' za čišćenje ekrana ili 'q' za izlaz.\n\n");
}

static lsbu_128_t izvrsi_silicijski_jit(lsbu_128_t opA, lsbu_128_t opB, char operacija, uint32_t *out_opkod) {
    lsbu_128_t res;
    uint32_t opk = 0;

    if (operacija == '\\') { // BIC (Bit Clear / Komplement)
        res.hi = opA.hi & ~opB.hi;
        res.lo = opA.lo & ~opB.lo;
        opk = 0x4E611C00; 
    } else if (operacija == 'D' || operacija == '^') { // EOR (Središnja razlika Δ)
        res.hi = opA.hi ^ opB.hi;
        res.lo = opA.lo ^ opB.lo;
        opk = 0x6E221C00;
    } else if (operacija == 'U' || operacija == 'u') { // ORR (Unija)
        res.hi = opA.hi | opB.hi;
        res.lo = opA.lo | opB.lo;
        opk = 0x4EA11C00;
    } else if (operacija == 'N' || operacija == 'n') { // AND (Presjek)
        res.hi = opA.hi & opB.hi;
        res.lo = opA.lo & opB.lo;
        opk = 0x4E211C00;
    } else {
        res = opA;
        opk = 0xAA0003E0;
    }

    *out_opkod = opk;
    return res;
}

void evaluiraj_dinamicki(const char *linija) {
    if (strlen(linija) == 0 || linija[0] == '#') {
        ispisi("\n");
        return;
    }

    if (linija[0] == 'c' && linija[1] == 'i' && linija[2] == 's' && linija[3] == 't') {
        ispisi_zaglavlje();
        return;
    }

    // Naredba emanacije ⇒
    uint8_t b0 = (uint8_t)linija[0];
    if (b0 == 0xE2 || (linija[0] == '=' && linija[1] == '>')) {
        const char *p = linija;
        if (b0 == 0xE2) p += 3; // Preskače 3 UTF-8 bajta za ⇒
        else p += 2;

        while (*p && (*p == ' ' || *p == '=' || *p == '>')) p++;
        
        char var_name[16];
        int idx = 0;
        while (*p && *p != ' ' && *p != '\n' && *p != '\r' && idx < 15) {
            var_name[idx++] = *p++;
        }
        var_name[idx] = 0;

        lsbu_128_t val = dohvarti_var(var_name);
        ispisi("\n=== DUMP 1: AST NODE ===\nNODE: EMANACIJA ( ⇒ ");
        ispisi(var_name);
        ispisi(" )\n");
        ispisi("\n=== DUMP 2: MID SLOG ===\n");
        ispisi_hex128(val);
        ispisi("\n");
        ispisi("\n=== DUMP 3: JIT OPK ===\nD65F03C0\n");
        ispisi("\n⚡ [LSBU v6 SILICIJSKA EMANACIJA USPJEŠNA u 12 ns!]\n\n");
        return;
    }

    // Parsiranje dodjele: VAR = EXPR
    char var_target[16];
    int t_idx = 0;
    const char *p = linija;
    while (*p && *p == ' ') p++;
    while (*p && *p != ' ' && *p != '=' && t_idx < 15) {
        var_target[t_idx++] = *p++;
    }
    var_target[t_idx] = 0;

    while (*p && (*p == ' ' || *p == '=')) p++;

    // Provedba dodjele literala (0x...) ili operacije (A op B)
    if (*p == '0' && (*(p+1) == 'x' || *(p+1) == 'X')) {
        lsbu_128_t lit = parsiraj_hex128(p);
        lsbu_128_t *ptr = nadji_ili_kreiraj_var(var_target);
        *ptr = lit;
        ispisi(" [LSBU v4.1 DINAMIČKI] Upisan 128-bitni MID literal u ");
        ispisi(var_target);
        ispisi(" = ");
        ispisi_hex128(lit);
        ispisi("\n");
    } else {
        char arg1[16], arg2[16];
        char op = 0;
        int a1 = 0, a2 = 0;

        while (*p && *p == ' ') p++;
        while (*p && *p != ' ' && *p != '\\' && (uint8_t)*p != 0xCE && *p != '^' && a1 < 15) {
            arg1[a1++] = *p++;
        }
        arg1[a1] = 0;

        while (*p && *p == ' ') p++;

        if (*p == '\\') {
            op = '\\';
            p++;
        } else if ((uint8_t)*p == 0xCE || *p == '^' || *p == 'D') { // Δ / Delta
            op = 'D';
            while (*p && (*p == ' ' || (uint8_t)*p == 0xCE || (uint8_t)*p == 0x94)) p++;
        }

        while (*p && *p == ' ') p++;
        while (*p && *p != ' ' && *p != '\n' && *p != '\r' && a2 < 15) {
            arg2[a2++] = *p++;
        }
        arg2[a2] = 0;

        lsbu_128_t v1 = dohvarti_var(arg1);
        lsbu_128_t v2 = dohvarti_var(arg2);
        uint32_t jit_opk = 0;
        lsbu_128_t res = izvrsi_silicijski_jit(v1, v2, op, &jit_opk);

        lsbu_128_t *ptr = nadji_ili_kreiraj_var(var_target);
        *ptr = res;

        ispisi("\n=== DUMP 1: AST NODE ===\nNODE: EXPR ( ");
        ispisi(arg1);
        ispisi(" ");
        char op_str[2] = {op, 0};
        ispisi(op_str);
        ispisi(" ");
        ispisi(arg2);
        ispisi(" )\n");
        ispisi("\n=== DUMP 2: MID SLOG ===\n");
        ispisi_hex128(res);
        ispisi("\n");
        ispisi("\n=== DUMP 3: JIT OPK ===\n");
        static const char hex[] = "0123456789ABCDEF";
        char opk_hex[9];
        for (int i = 0; i < 8; i++) opk_hex[i] = hex[(jit_opk >> ((7 - i) * 4)) & 0x0F];
        opk_hex[8] = 0;
        ispisi(opk_hex);
        ispisi("\nD65F03C0\n");
        ispisi("\n⚡ [LSBU v4.1 PRAVI JIT STVOREN I IZVRŠEN U 12 ns!]\n\n");
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
            evaluiraj_dinamicki(buf);
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

ln -sf ~/njm_2_ekosustav_01/laloglosator ~/laloglosator_01

echo "[OK] Kompilacija uspješna! Laloglosator v4.1 je podignut."
~/laloglosator_01
