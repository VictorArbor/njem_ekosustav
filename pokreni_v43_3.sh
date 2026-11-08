#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cat << 'C_EOF' > laloglosator_v43_3.c
// ═════════════════════════════════════════════════════════════════════════
//  NJM-OS :: LALOGLOSATOR v43.3 — DIRECT MEMORY FS ENGINE
// ═════════════════════════════════════════════════════════════════════════

#include <stdint.h>
#include <sys/mman.h>

#define SYS_read         63
#define SYS_write        64
#define SYS_exit         93
#define SYS_openat       56
#define SYS_close        57
#define SYS_mmap         222

#define AT_FDCWD        -100

#define MAX_TOKENS       16
#define EXEC_MEM_SIZE    65536

typedef uint32_t mid_t;

#define MID_UNKNOWN     0x0000
#define MID_SAB         0x0008
#define MID_NVE         0x0009
#define MID_UJB         0x000A
#define MID_MNO         0x000C
#define MID_SSB         0x0017
#define MID_MKM         0x0018
#define MID_PIR         0x001B

#define MID_OPN         0x0020
#define MID_WRT         0x0021
#define MID_RDL         0x0022
#define MID_CLS         0x0023

#pragma pack(push, 1)
typedef struct {
    unsigned char e_ident[16];
    uint16_t      e_type;
    uint16_t      e_machine;
    uint32_t      e_version;
    uint64_t      e_entry;
    uint64_t      e_phoff;
    uint64_t      e_shoff;
    uint32_t      e_flags;
    uint16_t      e_ehsize;
    uint16_t      e_phentsize;
    uint16_t      e_phnum;
    uint16_t      e_shentsize;
    uint16_t      e_shnum;
    uint16_t      e_shstrndx;
} Elf64_Ehdr;

typedef struct {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
} Elf64_Phdr;
#pragma pack(pop)

__attribute__((no_builtin("strlen")))
static unsigned long sys_strlen(const char *s) {
    unsigned long l = 0; while (s[l]) l++; return l;
}

static long sys_call(long n, long a, long b, long c, long d, long e, long f) {
    register long x8 __asm__("x8") = n, x0 __asm__("x0") = a, x1 __asm__("x1") = b;
    register long x2 __asm__("x2") = c, x3 __asm__("x3") = d, x4 __asm__("x4") = e, x5 __asm__("x5") = f;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5));
    return x0;
}

static void print(const char *s) { sys_call(SYS_write, 1, (long)s, sys_strlen(s), 0, 0, 0); }

static void print_pad(const char *s, int width) {
    print(s);
    int len = sys_strlen(s);
    while (len < width) { print(" "); len++; }
}

static void print_num(uint64_t n) {
    if (n == 0) { print("0"); return; }
    char buf[24]; int i = 22; buf[23] = 0;
    while (n > 0) { buf[i--] = '0' + (n % 10); n /= 10; }
    print(&buf[i + 1]);
}

static void print_hex32(uint32_t val) {
    const char hex[] = "0123456789ABCDEF";
    char buf[11]; buf[0] = '0'; buf[1] = 'x'; buf[10] = 0;
    for (int i = 9; i >= 2; i--) { buf[i] = hex[val & 0xF]; val >>= 4; }
    print(buf);
}

static void print_hex64(uint64_t val) {
    const char hex[] = "0123456789ABCDEF";
    char buf[19]; buf[0] = '0'; buf[1] = 'x'; buf[18] = 0;
    for (int i = 17; i >= 2; i--) { buf[i] = hex[val & 0xF]; val >>= 4; }
    print(buf);
}

static int str_eq(const char *a, const char *b) {
    int i = 0; while (a[i] && b[i]) { if (a[i] != b[i]) return 0; i++; }
    return a[i] == b[i];
}

static mid_t resolve_mid(const char *word) {
    if (str_eq(word, "sab")) return MID_SAB;
    if (str_eq(word, "mno")) return MID_MNO;
    if (str_eq(word, "nve")) return MID_NVE;
    if (str_eq(word, "ujb")) return MID_UJB;
    if (str_eq(word, "ssb")) return MID_SSB;
    if (str_eq(word, "mkm")) return MID_MKM;
    if (str_eq(word, "pir")) return MID_PIR;

    if (str_eq(word, "opn")) return MID_OPN;
    if (str_eq(word, "wrt")) return MID_WRT;
    if (str_eq(word, "rdl")) return MID_RDL;
    if (str_eq(word, "cls")) return MID_CLS;
    return MID_UNKNOWN;
}

static uint8_t parse_reg(const char *tok) {
    if (!tok || !tok[0]) return 0;
    int i = (tok[0] == 'r' || tok[0] == 'x' || tok[0] == 'q' || tok[0] == 'v') ? 1 : 0;
    uint8_t val = 0;
    while (tok[i] >= '0' && tok[i] <= '9') { val = val * 10 + (tok[i] - '0'); i++; }
    return val;
}

static int32_t parse_imm(const char *tok) {
    if (!tok || !tok[0]) return 0;
    if (tok[0] == '0' && (tok[1] == 'x' || tok[1] == 'X')) {
        int32_t val = 0; int i = 2;
        while (tok[i]) {
            char c = tok[i];
            int digit = (c >= '0' && c <= '9') ? c - '0' :
                        (c >= 'a' && c <= 'f') ? c - 'a' + 10 :
                        (c >= 'A' && c <= 'F') ? c - 'A' + 10 : 0;
            val = (val << 4) | digit; i++;
        }
        return val;
    }
    int32_t val = 0; int i = 0;
    while (tok[i] >= '0' && tok[i] <= '9') { val = val * 10 + (tok[i] - '0'); i++; }
    return val;
}

static void emit_mid_sequence(mid_t mid, char tokens[MAX_TOKENS][32], int num_tok,
                              uint32_t *jit_ram, int *pc) {
    (void)num_tok;

    if (mid == MID_SAB) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]), rm = parse_reg(tokens[3]);
        jit_ram[(*pc)++] = 0x8B000000 | (rm << 16) | (rn << 5) | rd;
    }
    else if (mid == MID_MNO) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]), rm = parse_reg(tokens[3]);
        jit_ram[(*pc)++] = 0x9B007C00 | (rm << 16) | (rn << 5) | rd;
    }
    else if (mid == MID_NVE) {
        uint8_t rd = parse_reg(tokens[1]);
        int32_t imm = parse_imm(tokens[2]);
        jit_ram[(*pc)++] = 0xD2800000 | ((imm & 0xFFFF) << 5) | rd;
    }
    else if (mid == MID_MKM) {
        uint8_t rd = parse_reg(tokens[1]);
        // MOV Xd, SP (čisto uzimanje pokazivača)
        jit_ram[(*pc)++] = 0x910003E0 | rd;
    }
    else if (mid == MID_SSB) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]);
        int32_t imm = parse_imm(tokens[3]);
        jit_ram[(*pc)++] = 0x39000000 | ((imm & 0xFFF) << 10) | (rn << 5) | rd;
    }
    else if (mid == MID_UJB) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]);
        int32_t imm = parse_imm(tokens[3]);
        jit_ram[(*pc)++] = 0x39400000 | ((imm & 0xFFF) << 10) | (rn << 5) | rd;
    }
    else if (mid == MID_PIR) {
        jit_ram[(*pc)++] = 0xD65F03C0;   // RET
    }
    else if (mid == MID_OPN) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]), rm = parse_reg(tokens[3]);
        int32_t mode = parse_imm(tokens[4]);

        jit_ram[(*pc)++] = 0x92800C60;                       // MOVN X0, #99 (AT_FDCWD = -100)
        jit_ram[(*pc)++] = 0xAA0003E1 | (rn << 5);           // MOV X1, Xn
        jit_ram[(*pc)++] = 0xAA0003E2 | (rm << 5);           // MOV X2, Xm
        jit_ram[(*pc)++] = 0xD2800003 | ((mode & 0xFFFF) << 5); // MOVZ X3, #mode
        jit_ram[(*pc)++] = 0xD2800708;                       // MOV X8, #56 (SYS_openat)
        jit_ram[(*pc)++] = 0xD4000001;                       // SVC #0
        jit_ram[(*pc)++] = 0xAA0003E0 | rd;                  // MOV Xd, X0
    }
    else if (mid == MID_WRT) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]), rm = parse_reg(tokens[3]);

        jit_ram[(*pc)++] = 0xAA0003E0 | (rd << 5);   // MOV X0, Xd
        jit_ram[(*pc)++] = 0xAA0003E1 | (rn << 5);   // MOV X1, Xn
        jit_ram[(*pc)++] = 0xAA0003E2 | (rm << 5);   // MOV X2, Xm
        jit_ram[(*pc)++] = 0xD2800808;               // MOV X8, #64 (SYS_write)
        jit_ram[(*pc)++] = 0xD4000001;               // SVC #0
    }
    else if (mid == MID_RDL) {
        uint8_t rd = parse_reg(tokens[1]), rn = parse_reg(tokens[2]), rm = parse_reg(tokens[3]);

        jit_ram[(*pc)++] = 0xAA0003E0 | (rd << 5);   // MOV X0, Xd
        jit_ram[(*pc)++] = 0xAA0003E1 | (rn << 5);   // MOV X1, Xn
        jit_ram[(*pc)++] = 0xAA0003E2 | (rm << 5);   // MOV X2, Xm
        jit_ram[(*pc)++] = 0xD2800FE8;               // MOV X8, #63 (SYS_read)
        jit_ram[(*pc)++] = 0xD4000001;               // SVC #0
    }
    else if (mid == MID_CLS) {
        uint8_t rd = parse_reg(tokens[1]);
        jit_ram[(*pc)++] = 0xAA0003E0 | (rd << 5);   // MOV X0, Xd
        jit_ram[(*pc)++] = 0xD2800728;               // MOV X8, #57 (SYS_close)
        jit_ram[(*pc)++] = 0xD4000001;               // SVC #0
    }
}

static void emit_elf64_binary(const char *out_filename, uint32_t *opcodes, int opcode_cnt) {
    long fd = sys_call(SYS_openat, AT_FDCWD, (long)out_filename,
                       O_WRONLY | O_CREAT | O_TRUNC, 0755, 0, 0);
    if (fd < 0) {
        print(" ❌ Pogreška pri stvaranju ELF64 datoteke!\n");
        return;
    }

    uint64_t base_vaddr = 0x400000;
    uint64_t code_size = opcode_cnt * 4;

    uint32_t exit_sequence[2] = {
        0xD2800BA8,   // MOV X8, #93 (SYS_exit)
        0xD4000001    // SVC #0
    };

    uint64_t total_code_size = code_size;
    if (opcode_cnt > 0 && opcodes[opcode_cnt - 1] == 0xD65F03C0) {
        total_code_size = (opcode_cnt - 1) * 4 + sizeof(exit_sequence);
    }

    uint64_t header_size = sizeof(Elf64_Ehdr) + sizeof(Elf64_Phdr);
    uint64_t entry_point = base_vaddr + header_size;

    Elf64_Ehdr ehdr = {0};
    ehdr.e_ident[0] = 0x7F; ehdr.e_ident[1] = 'E'; ehdr.e_ident[2] = 'L'; ehdr.e_ident[3] = 'F';
    ehdr.e_ident[4] = 2; ehdr.e_ident[5] = 1; ehdr.e_ident[6] = 1;
    ehdr.e_type = 2; ehdr.e_machine = 183; ehdr.e_version = 1;
    ehdr.e_entry = entry_point;
    ehdr.e_phoff = sizeof(Elf64_Ehdr);
    ehdr.e_ehsize = sizeof(Elf64_Ehdr);
    ehdr.e_phentsize = sizeof(Elf64_Phdr);
    ehdr.e_phnum = 1;

    Elf64_Phdr phdr = {0};
    phdr.p_type = 1; phdr.p_flags = 7; // READ | WRITE | EXECUTE
    phdr.p_offset = 0;
    phdr.p_vaddr = base_vaddr; phdr.p_paddr = base_vaddr;
    phdr.p_filesz = header_size + total_code_size;
    phdr.p_memsz = header_size + total_code_size + 4096; // 4KB Dodatne BSS/Stack memorije
    phdr.p_align = 0x10000;

    sys_call(SYS_write, fd, (long)&ehdr, sizeof(ehdr), 0, 0, 0);
    sys_call(SYS_write, fd, (long)&phdr, sizeof(phdr), 0, 0, 0);

    if (opcode_cnt > 0 && opcodes[opcode_cnt - 1] == 0xD65F03C0) {
        sys_call(SYS_write, fd, (long)opcodes, (opcode_cnt - 1) * 4, 0, 0, 0);
        sys_call(SYS_write, fd, (long)exit_sequence, sizeof(exit_sequence), 0, 0, 0);
    } else {
        sys_call(SYS_write, fd, (long)opcodes, code_size, 0, 0, 0);
    }

    sys_call(SYS_close, fd, 0, 0, 0, 0, 0);

    print(" 🛠️  [EMITTER OK] Samostalni ELF64 v43.3 izvršnik: ");
    print(out_filename);
    print("\n");
}

void process_stream(long fd, int is_interactive, const char *out_binary) {
    long addr = sys_call(SYS_mmap, 0, EXEC_MEM_SIZE,
                         PROT_READ | PROT_WRITE | PROT_EXEC,
                         MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    uint32_t *jit_ram = (uint32_t *)addr;
    int jit_pc = 0;

    char line_buf[256]; int line_len = 0;
    char c;

    if (!is_interactive) {
        print("MID        │ MNEMONIK │ TIP       │ OPCODES\n");
        print("───────────┼──────────┼───────────┼─────────\n");
    }

    while (1) {
        long n = sys_call(SYS_read, fd, (long)&c, 1, 0, 0, 0);
        if (n <= 0) break;
        if (c == '\r') continue;

        if (c == '\n') {
            line_buf[line_len] = 0;
            char *p = line_buf;
            while (*p == ' ' || *p == '\t') p++;

            if (*p != 0 && *p != '#') {
                char tokens[MAX_TOKENS][32] = {0};
                int tok_cnt = 0, tok_pos = 0;

                for (int i = 0; p[i] != 0; i++) {
                    char ch = p[i];
                    if (ch == '#') break;

                    if (ch == ' ' || ch == '\t' || ch == ',' || ch == '[') {
                        if (tok_pos > 0) {
                            tokens[tok_cnt][tok_pos] = 0;
                            tok_cnt++; tok_pos = 0;
                        }
                    } else if (ch != ']') {
                        if (tok_pos < 31) tokens[tok_cnt][tok_pos++] = ch;
                    }
                }
                if (tok_pos > 0) {
                    tokens[tok_cnt][tok_pos] = 0;
                    tok_cnt++;
                }

                if (tok_cnt > 0) {
                    mid_t mid = resolve_mid(tokens[0]);
                    if (mid != MID_UNKNOWN) {
                        int start_pc = jit_pc;
                        emit_mid_sequence(mid, tokens, tok_cnt, jit_ram, &jit_pc);

                        if (!is_interactive) {
                            print_hex32(mid); print(" │ ");
                            print_pad(tokens[0], 8); print(" │ ");
                            print_pad("FS/NATIVE", 9); print(" │ ");
                            print_num(jit_pc - start_pc); print(" opcodes\n");
                        }

                        if (mid == MID_PIR) {
                            if (!is_interactive) {
                                print("───────────┴──────────┴───────────┴─────────\n");
                            }
                            if (out_binary) {
                                emit_elf64_binary(out_binary, jit_ram, jit_pc);
                            } else {
                                (void)jit_ram;
                            }
                            jit_pc = 0;
                        }
                    }
                }
            }
            line_len = 0;
        } else if (line_len < 255) {
            line_buf[line_len++] = c;
        }
    }
}

void entry_point(long *sp) {
    print("╔═══════════════════════════════════════════════════════════════╗\n");
    print("║  NJM-OS :: LALOGLOSATOR v43.3 (DIRECT MEMORY FS ENGINE)       ║\n");
    print("╚═══════════════════════════════════════════════════════════════╝\n\n");

    long argc = sp[0];
    const char *in_filename = 0;
    const char *out_filename = 0;

    for (int i = 1; i < argc; i++) {
        const char *arg = (const char *)sp[1 + i];
        if (str_eq(arg, "-o") && (i + 1 < argc)) {
            out_filename = (const char *)sp[1 + i + 1];
            i++;
        } else if (!in_filename) {
            in_filename = arg;
        }
    }

    if (in_filename) {
        long fd = sys_call(SYS_openat, AT_FDCWD, (long)in_filename, O_RDONLY, 0, 0, 0);
        if (fd < 0) {
            print(" ❌ Pogreška pri otvaranju datoteke!\n");
            sys_call(SYS_exit, 1, 0, 0, 0, 0, 0);
        }
        process_stream(fd, 0, out_filename);
        sys_call(SYS_close, fd, 0, 0, 0, 0, 0);
    } else {
        process_stream(0, 1, out_filename);
    }

    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}

__attribute__((naked)) void _start(void) {
    __asm__ volatile(
        "mov x0, sp\n"
        "bl entry_point\n"
    );
}
C_EOF

echo "[1] Kompajliram laloglosator_v43_3.c..."
clang -O3 -march=armv8-a+simd -nostdlib -fno-builtin -static laloglosator_v43_3.c -o $PREFIX/bin/laloglosator
chmod +x $PREFIX/bin/laloglosator
rm -f laloglosator_v43_3.c

cat > test_fsv43_3.njm << 'NJM_EOF'
# Alokacija stoga u r10
mkm r10

# Pisanje naziva "autarhija.txt\0"
nve r2, 97
ssb r2, r10, 0
nve r2, 117
ssb r2, r10, 1
nve r2, 116
ssb r2, r10, 2
nve r2, 97
ssb r2, r10, 3
nve r2, 114
ssb r2, r10, 4
nve r2, 104
ssb r2, r10, 5
nve r2, 105
ssb r2, r10, 6
nve r2, 106
ssb r2, r10, 7
nve r2, 97
ssb r2, r10, 8
nve r2, 46
ssb r2, r10, 9
nve r2, 116
ssb r2, r10, 10
nve r2, 120
ssb r2, r10, 11
nve r2, 116
ssb r2, r10, 12
nve r2, 0
ssb r2, r10, 13

# Pisanje slova 'A' (65) na pomak 32
nve r3, 65
ssb r3, r10, 32

# Otvaranje za zapisivanje (O_WRONLY=1 | O_CREAT=64 | O_TRUNC=512 => 577, mode = 420)
nve r2, 577
opn r1, r10, r2, 420

# Izračun adrese spremnika r4 = r10 + 32
mkm r4
nve r5, 32
sab r4, r4, r5
nve r6, 1
wrt r1, r4, r6

# Zatvaranje
cls r1

# Ponovno otvaranje za čitanje (O_RDONLY = 0)
nve r2, 0
opn r1, r10, r2, 0

# Čitanje u pomak 64 (r4 = r10 + 64)
mkm r4
nve r5, 64
sab r4, r4, r5
nve r6, 1
rdl r1, r4, r6

# Zatvaranje
cls r1

# Dohvaćanje pročitanog znaka u r0 i izlaz
ujb r0, r4, 0
pir
NJM_EOF

echo "[2] Prevodim test_fsv43_3.njm u ELF64..."
laloglosator test_fsv43_3.njm -o test_fsv43_3
chmod +x test_fsv43_3

echo "[3] Pokrećem generirani ELF64 binarac..."
./test_fsv43_3
EXIT_CODE=$?

echo "[4] Exit code procesa = $EXIT_CODE"

if [ -f autarhija.txt ]; then
    echo "✅ Uspeh! Datoteka autarhija.txt je kreirana na disku!"
    echo "Sadržaj: $(cat autarhija.txt)"
else
    echo "❌ Datoteka autarhija.txt nije kreirana."
fi
